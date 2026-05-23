use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use anyhow::{Context, anyhow, bail};
use catalog::{CatalogBundle, CatalogValidationReport, PlanTemplate, load_bootstrap, load_catalog_bundle};
use chrono::{Datelike, Duration, NaiveDate, Utc};
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use sqlx::{PgPool, query, query_as, query_scalar};
use tokio::fs;
use tokio::sync::RwLock;
use uuid::Uuid;

use crate::config::AppConfig;
use crate::domain::{
    AttemptRow, AttemptSummary, BootstrapApplyResponse, CapabilityStateRow, CapabilityStateSummary,
    CatalogReloadResponse, DashboardResponse, LearnerDashboard, LearnerDetailResponse, LearnerRow, LearnerSummary,
    MilestoneProgress, PlanAssignmentRequest, PlanAssignmentResponse, PlanRow, PlanSummary, RecordSessionRequest,
    RecordSessionResponse, ReviewQueueRow, ReviewQueueSummary, ReviewRebuildResponse, SessionActivityRow,
    SessionActivitySummary, SessionDetail, SessionRow, SessionSummary, TeamRow, TeamSummary,
};

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("./migrations");

#[derive(Clone)]
pub struct AppState {
    pub config: AppConfig,
    pub pool: PgPool,
    pub catalog: Arc<RwLock<CatalogBundle>>,
    pub catalog_report: Arc<RwLock<CatalogValidationReport>>,
}

pub async fn initialize_state(config: AppConfig, run_startup_bootstrap: bool) -> anyhow::Result<Arc<AppState>> {
    fs::create_dir_all(&config.artifacts_root)
        .await
        .with_context(|| format!("failed to create {}", config.artifacts_root.display()))?;
    fs::create_dir_all(&config.exports_root)
        .await
        .with_context(|| format!("failed to create {}", config.exports_root.display()))?;

    let (catalog, catalog_report) = load_catalog_bundle(&config.content_root)?;
    let pool = PgPoolOptions::new()
        .max_connections(8)
        .connect(&config.database_url)
        .await
        .context("failed to connect to Postgres")?;
    MIGRATOR.run(&pool).await.context("failed to run database migrations")?;

    let state = Arc::new(AppState {
        config,
        pool,
        catalog: Arc::new(RwLock::new(catalog)),
        catalog_report: Arc::new(RwLock::new(catalog_report)),
    });

    if run_startup_bootstrap && state.config.auto_bootstrap {
        apply_bootstrap(&state).await?;
    }

    Ok(state)
}

pub async fn migrate_database(config: &AppConfig) -> anyhow::Result<()> {
    let pool = PgPoolOptions::new()
        .max_connections(4)
        .connect(&config.database_url)
        .await
        .context("failed to connect to Postgres")?;
    MIGRATOR.run(&pool).await.context("failed to run database migrations")
}

pub async fn reload_catalog(state: &Arc<AppState>) -> anyhow::Result<CatalogReloadResponse> {
    let (catalog, report) = load_catalog_bundle(&state.config.content_root)?;
    {
        let mut catalog_guard = state.catalog.write().await;
        *catalog_guard = catalog;
    }
    {
        let mut report_guard = state.catalog_report.write().await;
        *report_guard = report;
    }
    Ok(catalog_report_response(&*state.catalog_report.read().await))
}

pub async fn apply_bootstrap(state: &Arc<AppState>) -> anyhow::Result<BootstrapApplyResponse> {
    let bootstrap = load_bootstrap(&state.config.bootstrap_path)?;
    let learner_memberships: BTreeSet<&str> = bootstrap
        .memberships
        .iter()
        .filter(|membership| membership.role == "learner")
        .map(|membership| membership.user_id.as_str())
        .collect();

    for user in &bootstrap.users {
        if learner_memberships.contains(user.user_id.as_str())
            && (user.date_of_birth.is_none() || user.sex.is_none() || user.current_level.is_none())
        {
            bail!(
                "learner user '{}' must set date_of_birth, sex, and current_level in identity bootstrap",
                user.user_id
            );
        }
    }

    query(
        "insert into team (team_id, display_name, description) values ($1, $2, $3)
         on conflict (team_id) do update set display_name = excluded.display_name, description = excluded.description",
    )
    .bind(&bootstrap.team.team_id)
    .bind(&bootstrap.team.display_name)
    .bind(&bootstrap.team.description)
    .execute(&state.pool)
    .await?;

    for user in &bootstrap.users {
        query(
            "insert into user_account (user_id, username, display_name, date_of_birth, sex, current_level, notes)
             values ($1, $2, $3, $4, $5, $6, $7)
             on conflict (user_id) do update
             set username = excluded.username,
                 display_name = excluded.display_name,
                 date_of_birth = excluded.date_of_birth,
                 sex = excluded.sex,
                 current_level = excluded.current_level,
                 notes = excluded.notes",
        )
        .bind(&user.user_id)
        .bind(&user.username)
        .bind(&user.display_name)
        .bind(user.date_of_birth)
        .bind(&user.sex)
        .bind(&user.current_level)
        .bind(&user.notes)
        .execute(&state.pool)
        .await?;
    }

    for membership in &bootstrap.memberships {
        query(
            "insert into team_membership (team_id, user_id, role) values ($1, $2, $3)
             on conflict (team_id, user_id) do update set role = excluded.role",
        )
        .bind(&membership.team_id)
        .bind(&membership.user_id)
        .bind(&membership.role)
        .execute(&state.pool)
        .await?;
    }

    let seeded_plan_count = seed_default_plans_if_missing(state).await?;
    Ok(BootstrapApplyResponse {
        status: "ok".to_string(),
        team_id: bootstrap.team.team_id,
        user_count: bootstrap.users.len(),
        membership_count: bootstrap.memberships.len(),
        learner_count: learner_memberships.len(),
        seeded_plan_count,
    })
}

pub async fn fetch_catalog(state: &Arc<AppState>) -> (CatalogBundle, CatalogReloadResponse) {
    let bundle = state.catalog.read().await.clone();
    let report = catalog_report_response(&*state.catalog_report.read().await);
    (bundle, report)
}

pub async fn fetch_dashboard(state: &Arc<AppState>) -> anyhow::Result<DashboardResponse> {
    let team = query_as::<_, TeamRow>("select team_id, display_name, description from team order by team_id limit 1")
        .fetch_optional(&state.pool)
        .await?;
    let learners = query_as::<_, LearnerRow>(
        "select learner_id, team_id, user_id, display_name, date_of_birth, sex, current_level, notes
         from learner_profile
         order by display_name",
    )
    .fetch_all(&state.pool)
    .await?;

    let catalog = state.catalog.read().await.clone();
    let learner_dashboards = build_dashboard_cards(state, &catalog, &learners).await?;

    Ok(DashboardResponse {
        team: team.map(|row| TeamSummary {
            team_id: row.team_id,
            display_name: row.display_name,
            description: row.description,
        }),
        catalog: catalog_report_response(&*state.catalog_report.read().await),
        learners: learner_dashboards,
    })
}

pub async fn list_learners(state: &Arc<AppState>) -> anyhow::Result<Vec<LearnerSummary>> {
    let learners = query_as::<_, LearnerRow>(
        "select learner_id, team_id, user_id, display_name, date_of_birth, sex, current_level, notes
         from learner_profile
         order by display_name",
    )
    .fetch_all(&state.pool)
    .await?;

    Ok(learners
        .into_iter()
        .map(|learner| LearnerSummary {
            learner_id: learner.learner_id,
            display_name: learner.display_name,
            current_age: calculate_age(learner.date_of_birth),
            current_level: learner.current_level,
            notes: learner.notes,
        })
        .collect())
}

pub async fn fetch_learner_detail(state: &Arc<AppState>, learner_id: &str) -> anyhow::Result<LearnerDetailResponse> {
    let learner = query_as::<_, LearnerRow>(
        "select learner_id, team_id, user_id, display_name, date_of_birth, sex, current_level, notes
         from learner_profile
         where learner_id = $1",
    )
    .bind(learner_id)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| anyhow!("learner '{learner_id}' not found"))?;

    let active_plan = fetch_active_plan_for_learner(&state.pool, learner_id).await?;
    let plan_filter = active_plan.as_ref().map(|plan| plan.learning_plan_id.clone());
    let sessions = fetch_sessions(&state.pool, learner_id, plan_filter.as_deref()).await?;
    let capability_states = fetch_capability_states(&state.pool, learner_id).await?;
    let review_queue = fetch_review_queue(&state.pool, learner_id).await?;

    Ok(LearnerDetailResponse {
        learner: LearnerSummary {
            learner_id: learner.learner_id,
            display_name: learner.display_name,
            current_age: calculate_age(learner.date_of_birth),
            current_level: learner.current_level,
            notes: learner.notes,
        },
        active_plan,
        sessions,
        capability_states,
        review_queue,
    })
}

pub async fn assign_plan(
    state: &Arc<AppState>,
    request: PlanAssignmentRequest,
) -> anyhow::Result<PlanAssignmentResponse> {
    let catalog = state.catalog.read().await.clone();
    let learning_plan = assign_plan_internal(
        state,
        &catalog,
        &request.learner_id,
        &request.plan_template_id,
        request.start_date,
    )
    .await?;
    Ok(PlanAssignmentResponse {
        status: "ok".to_string(),
        learning_plan,
    })
}

pub async fn record_session(
    state: &Arc<AppState>,
    session_id: &str,
    request: RecordSessionRequest,
) -> anyhow::Result<RecordSessionResponse> {
    if request.max_score <= 0.0 {
        bail!("max_score must be greater than zero");
    }
    let session = query_as::<_, SessionRow>(
        "select session_id, learning_plan_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
         from learning_session
         where session_id = $1",
    )
    .bind(session_id)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| anyhow!("session '{session_id}' not found"))?;

    let activities = query_as::<_, SessionActivityRow>(
        "select activity_id, session_id, title, capability_id, content_id, status
         from session_activity
         where session_id = $1
         order by title, capability_id",
    )
    .bind(session_id)
    .fetch_all(&state.pool)
    .await?;

    let now = Utc::now();
    let attempt_id = Uuid::new_v4().to_string();
    let ratio = (request.score / request.max_score).clamp(0.0, 1.0);
    let capability_status = status_from_ratio(ratio);

    query(
        "insert into attempt (attempt_id, session_id, learner_id, score, max_score, duration_minutes, notes, recorded_at)
         values ($1, $2, $3, $4, $5, $6, $7, $8)",
    )
    .bind(&attempt_id)
    .bind(session_id)
    .bind(&session.learner_id)
    .bind(request.score)
    .bind(request.max_score)
    .bind(request.duration_minutes)
    .bind(&request.notes)
    .bind(now)
    .execute(&state.pool)
    .await?;

    let evidence_relative_path = format!("evidence/{}/{}.json", session.learner_id, attempt_id);
    let evidence_full_path = state.config.artifacts_root.join(&evidence_relative_path);
    if let Some(parent) = evidence_full_path.parent() {
        fs::create_dir_all(parent).await?;
    }
    let capability_ids: BTreeSet<_> = activities
        .iter()
        .map(|activity| activity.capability_id.as_str())
        .collect();
    fs::write(
        &evidence_full_path,
        serde_json::to_vec_pretty(&json!({
            "session_id": session.session_id,
            "learner_id": session.learner_id,
            "score": request.score,
            "max_score": request.max_score,
            "score_ratio": ratio,
            "duration_minutes": request.duration_minutes,
            "notes": request.notes,
            "capability_ids": capability_ids,
            "recorded_at": now,
        }))?,
    )
    .await?;

    query(
        "insert into evidence_record (evidence_id, attempt_id, learner_id, kind, storage_path, summary)
         values ($1, $2, $3, $4, $5, $6)",
    )
    .bind(Uuid::new_v4().to_string())
    .bind(&attempt_id)
    .bind(&session.learner_id)
    .bind("session_notes")
    .bind(&evidence_relative_path)
    .bind(format!("{}: {}", session.title, request.notes))
    .execute(&state.pool)
    .await?;

    query("update learning_session set status = $2, notes = $3, completed_at = $4 where session_id = $1")
        .bind(session_id)
        .bind("completed")
        .bind(&request.notes)
        .bind(now)
        .execute(&state.pool)
        .await?;

    query("update session_activity set status = 'completed' where session_id = $1")
        .bind(session_id)
        .execute(&state.pool)
        .await?;

    let mut updated_capabilities = Vec::new();
    for capability_id in capability_ids {
        let state_row = upsert_capability_state(
            &state.pool,
            &session.learner_id,
            capability_id,
            capability_status,
            ratio,
            now,
        )
        .await?;
        updated_capabilities.push(capability_row_to_summary(state_row));
    }

    rebuild_review_queue_for_learner(&state.pool, &session.learner_id).await?;
    refresh_learning_plan_progress(&state.pool, &session.learner_id).await?;

    Ok(RecordSessionResponse {
        status: "ok".to_string(),
        attempt: AttemptSummary {
            attempt_id,
            score: request.score,
            max_score: request.max_score,
            duration_minutes: request.duration_minutes,
            notes: request.notes,
            recorded_at: now,
        },
        updated_capabilities,
    })
}

pub async fn rebuild_review_queue(
    state: &Arc<AppState>,
    learner_id: Option<String>,
) -> anyhow::Result<ReviewRebuildResponse> {
    let learner_ids = if let Some(learner_id) = learner_id {
        vec![learner_id]
    } else {
        query_scalar::<_, String>("select learner_id from learner_profile order by learner_id")
            .fetch_all(&state.pool)
            .await?
    };

    let mut review_item_count = 0usize;
    for learner_id in &learner_ids {
        rebuild_review_queue_for_learner(&state.pool, learner_id).await?;
        refresh_learning_plan_progress(&state.pool, learner_id).await?;
        let count = query_scalar::<_, i64>(
            "select count(*) from review_queue_item where learner_id = $1 and status = 'pending'",
        )
        .bind(learner_id)
        .fetch_one(&state.pool)
        .await?;
        review_item_count += count as usize;
    }

    Ok(ReviewRebuildResponse {
        status: "ok".to_string(),
        learner_ids,
        review_item_count,
    })
}

fn catalog_report_response(report: &CatalogValidationReport) -> CatalogReloadResponse {
    CatalogReloadResponse {
        status: "ok".to_string(),
        subject_count: report.subject_count,
        capability_count: report.capability_count,
        milestone_count: report.milestone_count,
        plan_template_count: report.plan_template_count,
        content_item_count: report.content_item_count,
        loaded_at_utc: report.loaded_at_utc.clone(),
    }
}

async fn build_dashboard_cards(
    state: &Arc<AppState>,
    catalog: &CatalogBundle,
    learners: &[LearnerRow],
) -> anyhow::Result<Vec<LearnerDashboard>> {
    let mut dashboards = Vec::new();
    for learner in learners {
        let active_plan = fetch_active_plan_for_learner(&state.pool, &learner.learner_id).await?;
        let today_session = if let Some(plan) = &active_plan {
            fetch_next_session_for_plan(&state.pool, &plan.learning_plan_id).await?
        } else {
            None
        };
        let review_queue_count = query_scalar::<_, i64>(
            "select count(*) from review_queue_item where learner_id = $1 and status = 'pending'",
        )
        .bind(&learner.learner_id)
        .fetch_one(&state.pool)
        .await?;
        let capability_states = fetch_capability_states(&state.pool, &learner.learner_id).await?;
        let latest_attempt = fetch_latest_attempt_for_learner(&state.pool, &learner.learner_id).await?;
        let (capability_status_counts, milestone_progress) =
            summarize_progress(catalog, active_plan.as_ref(), &capability_states);

        dashboards.push(LearnerDashboard {
            learner_id: learner.learner_id.clone(),
            display_name: learner.display_name.clone(),
            current_age: calculate_age(learner.date_of_birth),
            current_level: learner.current_level.clone(),
            notes: learner.notes.clone(),
            active_plan,
            today_session,
            review_queue_count,
            capability_status_counts,
            milestone_progress,
            latest_attempt,
        });
    }
    Ok(dashboards)
}

fn summarize_progress(
    catalog: &CatalogBundle,
    active_plan: Option<&PlanSummary>,
    capability_states: &[CapabilityStateSummary],
) -> (BTreeMap<String, i64>, Vec<MilestoneProgress>) {
    let mut counts: BTreeMap<String, i64> = BTreeMap::new();
    for state in capability_states {
        *counts.entry(state.status.clone()).or_insert(0) += 1;
    }

    let Some(active_plan) = active_plan else {
        return (counts, Vec::new());
    };
    let Some(plan_template) = catalog.plan_template(&active_plan.plan_template_id) else {
        return (counts, Vec::new());
    };

    let known_capabilities: BTreeSet<_> = capability_states
        .iter()
        .map(|state| state.capability_id.as_str())
        .collect();
    let not_started = plan_template
        .capability_ids
        .iter()
        .filter(|capability_id| !known_capabilities.contains(capability_id.as_str()))
        .count() as i64;
    if not_started > 0 {
        counts.insert("not_started".to_string(), not_started);
    }

    let secure_capabilities: BTreeSet<_> = capability_states
        .iter()
        .filter(|state| state.status == "secure")
        .map(|state| state.capability_id.as_str())
        .collect();

    let milestone_progress = plan_template
        .milestone_ids
        .iter()
        .filter_map(|milestone_id| {
            let milestone = catalog
                .milestones
                .iter()
                .find(|milestone| milestone.milestone_id == *milestone_id)?;
            let completed_capabilities = milestone
                .capability_ids
                .iter()
                .filter(|capability_id| secure_capabilities.contains(capability_id.as_str()))
                .count();
            Some(MilestoneProgress {
                milestone_id: milestone.milestone_id.clone(),
                title: milestone.title.clone(),
                completed_capabilities,
                total_capabilities: milestone.capability_ids.len(),
            })
        })
        .collect();

    (counts, milestone_progress)
}

async fn seed_default_plans_if_missing(state: &Arc<AppState>) -> anyhow::Result<usize> {
    let learners = query_as::<_, LearnerRow>(
        "select learner_id, team_id, user_id, display_name, date_of_birth, sex, current_level, notes
         from learner_profile
         order by display_name",
    )
    .fetch_all(&state.pool)
    .await?;
    let catalog = state.catalog.read().await.clone();
    let today = Utc::now().date_naive();

    let mut seeded = 0usize;
    for learner in learners {
        let active_count = query_scalar::<_, i64>(
            "select count(*) from learning_plan where learner_id = $1 and status in ('active', 'scheduled')",
        )
        .bind(&learner.learner_id)
        .fetch_one(&state.pool)
        .await?;
        if active_count > 0 {
            continue;
        }
        if let Some(plan_template) = choose_default_plan(&catalog, calculate_age(learner.date_of_birth)) {
            let _ = assign_plan_internal(
                state,
                &catalog,
                &learner.learner_id,
                &plan_template.plan_template_id,
                today,
            )
            .await?;
            seeded += 1;
        }
    }
    Ok(seeded)
}

fn choose_default_plan(catalog: &CatalogBundle, age: i32) -> Option<&PlanTemplate> {
    catalog
        .plan_templates
        .iter()
        .min_by_key(|plan_template| (plan_template.recommended_age as i32 - age).abs())
}

async fn assign_plan_internal(
    state: &Arc<AppState>,
    catalog: &CatalogBundle,
    learner_id: &str,
    plan_template_id: &str,
    start_date: NaiveDate,
) -> anyhow::Result<PlanSummary> {
    let plan_template = catalog
        .plan_template(plan_template_id)
        .cloned()
        .ok_or_else(|| anyhow!("unknown plan template '{plan_template_id}'"))?;

    let end_date = start_date + Duration::days((plan_template.duration_days.saturating_sub(1)) as i64);
    query("update learning_plan set status = 'replaced' where learner_id = $1 and status in ('active', 'scheduled')")
        .bind(learner_id)
        .execute(&state.pool)
        .await?;
    query("update plan_assignment set status = 'replaced' where learner_id = $1 and status in ('active', 'scheduled')")
        .bind(learner_id)
        .execute(&state.pool)
        .await?;

    let plan_assignment_id = Uuid::new_v4().to_string();
    let learning_plan_id = Uuid::new_v4().to_string();
    query(
        "insert into plan_assignment (plan_assignment_id, learner_id, plan_template_id, title, start_date, end_date, status, created_at)
         values ($1, $2, $3, $4, $5, $6, 'active', $7)",
    )
    .bind(&plan_assignment_id)
    .bind(learner_id)
    .bind(&plan_template.plan_template_id)
    .bind(&plan_template.title)
    .bind(start_date)
    .bind(end_date)
    .bind(Utc::now())
    .execute(&state.pool)
    .await?;

    query(
        "insert into learning_plan (learning_plan_id, plan_assignment_id, learner_id, plan_template_id, title, start_date, end_date, status, total_sessions, completed_sessions, created_at)
         values ($1, $2, $3, $4, $5, $6, $7, 'active', $8, 0, $9)",
    )
    .bind(&learning_plan_id)
    .bind(&plan_assignment_id)
    .bind(learner_id)
    .bind(&plan_template.plan_template_id)
    .bind(&plan_template.title)
    .bind(start_date)
    .bind(end_date)
    .bind(plan_template.session_pattern.sessions.len() as i32)
    .bind(Utc::now())
    .execute(&state.pool)
    .await?;

    for session in &plan_template.session_pattern.sessions {
        let scheduled_date = start_date + Duration::days(session.day_offset as i64);
        let session_id = Uuid::new_v4().to_string();
        query(
            "insert into learning_session (session_id, learning_plan_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at)
             values ($1, $2, $3, $4, $5, 'scheduled', $6, '', null)",
        )
        .bind(&session_id)
        .bind(&learning_plan_id)
        .bind(learner_id)
        .bind(&session.title)
        .bind(scheduled_date)
        .bind(session.day_offset)
        .execute(&state.pool)
        .await?;

        for capability_id in &session.capability_ids {
            let content_id = choose_content_for_capability(catalog, session, capability_id).ok_or_else(|| {
                anyhow!(
                    "plan template '{}' has no content for capability '{}'",
                    plan_template_id,
                    capability_id
                )
            })?;
            query(
                "insert into session_activity (activity_id, session_id, title, capability_id, content_id, status)
                 values ($1, $2, $3, $4, $5, 'scheduled')",
            )
            .bind(Uuid::new_v4().to_string())
            .bind(&session_id)
            .bind(format!("{}: {}", session.title, capability_id))
            .bind(capability_id)
            .bind(content_id)
            .execute(&state.pool)
            .await?;
        }
    }

    Ok(PlanSummary {
        learning_plan_id,
        plan_assignment_id,
        plan_template_id: plan_template.plan_template_id,
        title: plan_template.title,
        start_date,
        end_date,
        status: "active".to_string(),
        total_sessions: plan_template.session_pattern.sessions.len() as i32,
        completed_sessions: 0,
        completion_percent: 0,
    })
}

fn choose_content_for_capability<'a>(
    catalog: &'a CatalogBundle,
    session: &'a catalog::PlanTemplateSession,
    capability_id: &str,
) -> Option<&'a str> {
    for content_id in &session.content_ids {
        let content = catalog.content_items.iter().find(|item| item.id == *content_id)?;
        if content.capability_ids.iter().any(|item| item == capability_id) {
            return Some(content_id.as_str());
        }
    }
    session.content_ids.first().map(String::as_str)
}

async fn fetch_active_plan_for_learner(pool: &PgPool, learner_id: &str) -> anyhow::Result<Option<PlanSummary>> {
    let row = query_as::<_, PlanRow>(
        "select learning_plan_id, plan_assignment_id, learner_id, plan_template_id, title, start_date, end_date, status, total_sessions, completed_sessions
         from learning_plan
         where learner_id = $1 and status in ('active', 'scheduled', 'completed')
         order by case status when 'active' then 0 when 'scheduled' then 1 else 2 end, start_date desc
         limit 1",
    )
    .bind(learner_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(plan_row_to_summary))
}

async fn fetch_next_session_for_plan(pool: &PgPool, learning_plan_id: &str) -> anyhow::Result<Option<SessionSummary>> {
    let row = query_as::<_, SessionRow>(
        "select session_id, learning_plan_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
         from learning_session
         where learning_plan_id = $1 and status <> 'completed'
         order by scheduled_date asc, day_offset asc
         limit 1",
    )
    .bind(learning_plan_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(session_row_to_summary))
}

async fn fetch_sessions(
    pool: &PgPool,
    learner_id: &str,
    learning_plan_id: Option<&str>,
) -> anyhow::Result<Vec<SessionDetail>> {
    let rows = if let Some(learning_plan_id) = learning_plan_id {
        query_as::<_, SessionRow>(
            "select session_id, learning_plan_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
             from learning_session
             where learner_id = $1 and learning_plan_id = $2
             order by scheduled_date asc, day_offset asc",
        )
        .bind(learner_id)
        .bind(learning_plan_id)
        .fetch_all(pool)
        .await?
    } else {
        query_as::<_, SessionRow>(
            "select session_id, learning_plan_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
             from learning_session
             where learner_id = $1
             order by scheduled_date desc, day_offset desc
             limit 10",
        )
        .bind(learner_id)
        .fetch_all(pool)
        .await?
    };

    let mut sessions = Vec::new();
    for row in rows {
        let activities = query_as::<_, SessionActivityRow>(
            "select activity_id, session_id, title, capability_id, content_id, status
             from session_activity
             where session_id = $1
             order by title, capability_id",
        )
        .bind(&row.session_id)
        .fetch_all(pool)
        .await?;
        let latest_attempt = fetch_latest_attempt_for_session(pool, &row.session_id).await?;
        sessions.push(SessionDetail {
            session_id: row.session_id,
            title: row.title,
            scheduled_date: row.scheduled_date,
            status: row.status,
            notes: row.notes,
            activities: activities.into_iter().map(activity_row_to_summary).collect(),
            latest_attempt,
        });
    }
    Ok(sessions)
}

async fn fetch_capability_states(pool: &PgPool, learner_id: &str) -> anyhow::Result<Vec<CapabilityStateSummary>> {
    let rows = query_as::<_, CapabilityStateRow>(
        "select learner_id, capability_id, status, score_average, last_score, total_attempts, last_attempted_at
         from learner_capability_state
         where learner_id = $1
         order by capability_id",
    )
    .bind(learner_id)
    .fetch_all(pool)
    .await?;
    Ok(rows.into_iter().map(capability_row_to_summary).collect())
}

async fn fetch_review_queue(pool: &PgPool, learner_id: &str) -> anyhow::Result<Vec<ReviewQueueSummary>> {
    let rows = query_as::<_, ReviewQueueRow>(
        "select review_queue_item_id, learner_id, capability_id, reason, due_date, status
         from review_queue_item
         where learner_id = $1
         order by due_date asc, capability_id asc",
    )
    .bind(learner_id)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(|row| ReviewQueueSummary {
            review_queue_item_id: row.review_queue_item_id,
            capability_id: row.capability_id,
            reason: row.reason,
            due_date: row.due_date,
            status: row.status,
        })
        .collect())
}

async fn fetch_latest_attempt_for_learner(pool: &PgPool, learner_id: &str) -> anyhow::Result<Option<AttemptSummary>> {
    let row = query_as::<_, AttemptRow>(
        "select attempt_id, session_id, learner_id, score, max_score, duration_minutes, notes, recorded_at
         from attempt
         where learner_id = $1
         order by recorded_at desc
         limit 1",
    )
    .bind(learner_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(attempt_row_to_summary))
}

async fn fetch_latest_attempt_for_session(pool: &PgPool, session_id: &str) -> anyhow::Result<Option<AttemptSummary>> {
    let row = query_as::<_, AttemptRow>(
        "select attempt_id, session_id, learner_id, score, max_score, duration_minutes, notes, recorded_at
         from attempt
         where session_id = $1
         order by recorded_at desc
         limit 1",
    )
    .bind(session_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(attempt_row_to_summary))
}

async fn upsert_capability_state(
    pool: &PgPool,
    learner_id: &str,
    capability_id: &str,
    status: &str,
    ratio: f64,
    attempted_at: chrono::DateTime<Utc>,
) -> anyhow::Result<CapabilityStateRow> {
    query_as::<_, CapabilityStateRow>(
        "insert into learner_capability_state
            (learner_id, capability_id, status, score_average, last_score, total_attempts, last_attempted_at)
         values ($1, $2, $3, $4, $4, 1, $5)
         on conflict (learner_id, capability_id) do update
         set status = excluded.status,
             score_average = ((learner_capability_state.score_average * learner_capability_state.total_attempts) + excluded.last_score)
                / (learner_capability_state.total_attempts + 1),
             last_score = excluded.last_score,
             total_attempts = learner_capability_state.total_attempts + 1,
             last_attempted_at = excluded.last_attempted_at
         returning learner_id, capability_id, status, score_average, last_score, total_attempts, last_attempted_at",
    )
    .bind(learner_id)
    .bind(capability_id)
    .bind(status)
    .bind(ratio)
    .bind(attempted_at)
    .fetch_one(pool)
    .await
    .context("failed to update capability state")
}

async fn rebuild_review_queue_for_learner(pool: &PgPool, learner_id: &str) -> anyhow::Result<()> {
    query("delete from review_queue_item where learner_id = $1")
        .bind(learner_id)
        .execute(pool)
        .await?;

    let states = query_as::<_, CapabilityStateRow>(
        "select learner_id, capability_id, status, score_average, last_score, total_attempts, last_attempted_at
         from learner_capability_state
         where learner_id = $1",
    )
    .bind(learner_id)
    .fetch_all(pool)
    .await?;
    let today = Utc::now().date_naive();

    for state in states {
        let Some(reason) = review_reason(&state.status) else {
            continue;
        };
        let due_date = match state.status.as_str() {
            "needs_review" => today + Duration::days(1),
            "introduced" => today + Duration::days(3),
            "practising" => today + Duration::days(2),
            _ => continue,
        };
        query(
            "insert into review_queue_item (review_queue_item_id, learner_id, capability_id, reason, due_date, status, created_at)
             values ($1, $2, $3, $4, $5, 'pending', $6)",
        )
        .bind(Uuid::new_v4().to_string())
        .bind(learner_id)
        .bind(&state.capability_id)
        .bind(reason)
        .bind(due_date)
        .bind(Utc::now())
        .execute(pool)
        .await?;
    }
    Ok(())
}

async fn refresh_learning_plan_progress(pool: &PgPool, learner_id: &str) -> anyhow::Result<()> {
    let plans = query_as::<_, PlanRow>(
        "select learning_plan_id, plan_assignment_id, learner_id, plan_template_id, title, start_date, end_date, status, total_sessions, completed_sessions
         from learning_plan
         where learner_id = $1",
    )
    .bind(learner_id)
    .fetch_all(pool)
    .await?;
    for plan in plans {
        let completed_sessions = query_scalar::<_, i64>(
            "select count(*) from learning_session where learning_plan_id = $1 and status = 'completed'",
        )
        .bind(&plan.learning_plan_id)
        .fetch_one(pool)
        .await? as i32;
        let next_status = if plan.status == "replaced" {
            "replaced"
        } else if plan.total_sessions > 0 && completed_sessions >= plan.total_sessions {
            "completed"
        } else {
            "active"
        };

        query("update learning_plan set completed_sessions = $2, status = $3 where learning_plan_id = $1")
            .bind(&plan.learning_plan_id)
            .bind(completed_sessions)
            .bind(next_status)
            .execute(pool)
            .await?;
        query("update plan_assignment set status = $2 where plan_assignment_id = $1")
            .bind(&plan.plan_assignment_id)
            .bind(next_status)
            .execute(pool)
            .await?;
    }
    Ok(())
}

fn review_reason(status: &str) -> Option<&'static str> {
    match status {
        "introduced" => Some("New skill needs a short revisit"),
        "practising" => Some("Keep this skill in the active review loop"),
        "needs_review" => Some("Recent performance was weak and should be repeated soon"),
        _ => None,
    }
}

fn calculate_age(date_of_birth: NaiveDate) -> i32 {
    let today = Utc::now().date_naive();
    let mut age = today.year() - date_of_birth.year();
    if (today.month(), today.day()) < (date_of_birth.month(), date_of_birth.day()) {
        age -= 1;
    }
    age
}

fn status_from_ratio(ratio: f64) -> &'static str {
    if ratio >= 0.9 {
        "secure"
    } else if ratio >= 0.75 {
        "practising"
    } else if ratio >= 0.5 {
        "introduced"
    } else {
        "needs_review"
    }
}

fn plan_row_to_summary(row: PlanRow) -> PlanSummary {
    let completion_percent = if row.total_sessions > 0 {
        (row.completed_sessions * 100) / row.total_sessions
    } else {
        0
    };
    PlanSummary {
        learning_plan_id: row.learning_plan_id,
        plan_assignment_id: row.plan_assignment_id,
        plan_template_id: row.plan_template_id,
        title: row.title,
        start_date: row.start_date,
        end_date: row.end_date,
        status: row.status,
        total_sessions: row.total_sessions,
        completed_sessions: row.completed_sessions,
        completion_percent,
    }
}

fn session_row_to_summary(row: SessionRow) -> SessionSummary {
    SessionSummary {
        session_id: row.session_id,
        title: row.title,
        scheduled_date: row.scheduled_date,
        status: row.status,
    }
}

fn activity_row_to_summary(row: SessionActivityRow) -> SessionActivitySummary {
    SessionActivitySummary {
        activity_id: row.activity_id,
        title: row.title,
        capability_id: row.capability_id,
        content_id: row.content_id,
        status: row.status,
    }
}

fn attempt_row_to_summary(row: AttemptRow) -> AttemptSummary {
    AttemptSummary {
        attempt_id: row.attempt_id,
        score: row.score,
        max_score: row.max_score,
        duration_minutes: row.duration_minutes,
        notes: row.notes,
        recorded_at: row.recorded_at,
    }
}

fn capability_row_to_summary(row: CapabilityStateRow) -> CapabilityStateSummary {
    CapabilityStateSummary {
        capability_id: row.capability_id,
        status: row.status,
        score_average: row.score_average,
        last_score: row.last_score,
        total_attempts: row.total_attempts,
        last_attempted_at: row.last_attempted_at,
    }
}
