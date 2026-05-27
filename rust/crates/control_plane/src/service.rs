use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use anyhow::{Context, anyhow, bail};
use catalog::{CatalogBundle, CatalogValidationReport, Playlist, load_bootstrap, load_catalog_bundle};
use chrono::{Datelike, Duration, NaiveDate, Utc};
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use sqlx::{PgPool, query, query_as, query_scalar};
use tokio::fs;
use tokio::sync::RwLock;
use uuid::Uuid;

use crate::config::AppConfig;
use crate::domain::{
    AssignmentRequest, AssignmentResponse, AssignmentRow, AssignmentSummary, BootstrapApplyResponse,
    CatalogReloadResponse, DashboardResponse, EvidenceRow, EvidenceSummary, LearnerDashboard,
    LearnerDetailResponse, LearnerRow, LearnerSummary, RecordSessionRequest, RecordSessionResponse,
    ReviewItemRow, ReviewItemSummary, ReviewRebuildResponse, SessionDetail, SessionMaterialRow,
    SessionMaterialSummary, SessionRow, SessionSummary, SkillProgressRow, SkillProgressSummary,
    StageProgress, TeamRow, TeamSummary,
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

pub async fn migrate_database(database_url: &str) -> anyhow::Result<()> {
    let pool = PgPoolOptions::new()
        .max_connections(4)
        .connect(database_url)
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

    let seeded_assignment_count = seed_default_assignments_if_missing(state).await?;
    Ok(BootstrapApplyResponse {
        status: "ok".to_string(),
        team_id: bootstrap.team.team_id,
        user_count: bootstrap.users.len(),
        membership_count: bootstrap.memberships.len(),
        learner_count: learner_memberships.len(),
        seeded_assignment_count,
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

    let active_assignment = fetch_active_assignment_for_learner(&state.pool, learner_id).await?;
    let assignment_filter = active_assignment
        .as_ref()
        .map(|assignment| assignment.assignment_id.clone());
    let sessions = fetch_sessions(&state.pool, learner_id, assignment_filter.as_deref()).await?;
    let progress = fetch_progress(&state.pool, learner_id).await?;
    let review_items = fetch_review_items(&state.pool, learner_id).await?;

    Ok(LearnerDetailResponse {
        learner: LearnerSummary {
            learner_id: learner.learner_id,
            display_name: learner.display_name,
            current_age: calculate_age(learner.date_of_birth),
            current_level: learner.current_level,
            notes: learner.notes,
        },
        active_assignment,
        sessions,
        progress,
        review_items,
    })
}

pub async fn create_assignment(
    state: &Arc<AppState>,
    request: AssignmentRequest,
) -> anyhow::Result<AssignmentResponse> {
    let catalog = state.catalog.read().await.clone();
    let assignment = create_assignment_internal(
        state,
        &catalog,
        &request.learner_id,
        &request.playlist_id,
        request.start_date,
    )
    .await?;
    Ok(AssignmentResponse {
        status: "ok".to_string(),
        assignment,
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
        "select session_id, assignment_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
         from session
         where session_id = $1",
    )
    .bind(session_id)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| anyhow!("session '{session_id}' not found"))?;

    let materials = query_as::<_, SessionMaterialRow>(
        "select session_material_id, session_id, title, skill_id, material_id, status
         from session_material
         where session_id = $1
         order by title, skill_id",
    )
    .bind(session_id)
    .fetch_all(&state.pool)
    .await?;

    let now = Utc::now();
    let evidence_id = Uuid::new_v4().to_string();
    let ratio = (request.score / request.max_score).clamp(0.0, 1.0);
    let progress_status = status_from_ratio(ratio);

    query(
        "insert into evidence (evidence_id, session_id, learner_id, score, max_score, duration_minutes, notes, recorded_at)
         values ($1, $2, $3, $4, $5, $6, $7, $8)",
    )
    .bind(&evidence_id)
    .bind(session_id)
    .bind(&session.learner_id)
    .bind(request.score)
    .bind(request.max_score)
    .bind(request.duration_minutes)
    .bind(&request.notes)
    .bind(now)
    .execute(&state.pool)
    .await?;

    let evidence_relative_path = format!("evidence/{}/{}.json", session.learner_id, evidence_id);
    let evidence_full_path = state.config.artifacts_root.join(&evidence_relative_path);
    if let Some(parent) = evidence_full_path.parent() {
        fs::create_dir_all(parent).await?;
    }
    let skill_ids: BTreeSet<_> = materials
        .iter()
        .map(|material| material.skill_id.as_str())
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
            "skill_ids": skill_ids,
            "recorded_at": now,
        }))?,
    )
    .await?;

    query(
        "insert into evidence_artifact (evidence_artifact_id, evidence_id, learner_id, kind, storage_path, summary)
         values ($1, $2, $3, $4, $5, $6)",
    )
    .bind(Uuid::new_v4().to_string())
    .bind(&evidence_id)
    .bind(&session.learner_id)
    .bind("session_notes")
    .bind(&evidence_relative_path)
    .bind(format!("{}: {}", session.title, request.notes))
    .execute(&state.pool)
    .await?;

    query("update session set status = $2, notes = $3, completed_at = $4 where session_id = $1")
        .bind(session_id)
        .bind("completed")
        .bind(&request.notes)
        .bind(now)
        .execute(&state.pool)
        .await?;

    query("update session_material set status = 'completed' where session_id = $1")
        .bind(session_id)
        .execute(&state.pool)
        .await?;

    let mut updated_progress = Vec::new();
    for skill_id in skill_ids {
        let progress_row = upsert_skill_progress(
            &state.pool,
            &session.learner_id,
            skill_id,
            progress_status,
            ratio,
            now,
        )
        .await?;
        updated_progress.push(progress_row_to_summary(progress_row));
    }

    rebuild_review_items_for_learner(&state.pool, &session.learner_id).await?;
    refresh_assignment_progress(&state.pool, &session.learner_id).await?;

    Ok(RecordSessionResponse {
        status: "ok".to_string(),
        evidence: EvidenceSummary {
            evidence_id,
            score: request.score,
            max_score: request.max_score,
            duration_minutes: request.duration_minutes,
            notes: request.notes,
            recorded_at: now,
        },
        updated_progress,
    })
}

pub async fn rebuild_review_items(
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
        rebuild_review_items_for_learner(&state.pool, learner_id).await?;
        refresh_assignment_progress(&state.pool, learner_id).await?;
        let count = query_scalar::<_, i64>(
            "select count(*) from review_item where learner_id = $1 and status = 'pending'",
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
        area_count: report.area_count,
        skill_count: report.skill_count,
        stage_count: report.stage_count,
        playlist_count: report.playlist_count,
        material_count: report.material_count,
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
        let active_assignment = fetch_active_assignment_for_learner(&state.pool, &learner.learner_id).await?;
        let today_session = if let Some(assignment) = &active_assignment {
            fetch_next_session_for_assignment(&state.pool, &assignment.assignment_id).await?
        } else {
            None
        };
        let review_item_count = query_scalar::<_, i64>(
            "select count(*) from review_item where learner_id = $1 and status = 'pending'",
        )
        .bind(&learner.learner_id)
        .fetch_one(&state.pool)
        .await?;
        let progress = fetch_progress(&state.pool, &learner.learner_id).await?;
        let latest_evidence = fetch_latest_evidence_for_learner(&state.pool, &learner.learner_id).await?;
        let (progress_status_counts, stage_progress) =
            summarize_progress(catalog, active_assignment.as_ref(), &progress);

        dashboards.push(LearnerDashboard {
            learner_id: learner.learner_id.clone(),
            display_name: learner.display_name.clone(),
            current_age: calculate_age(learner.date_of_birth),
            current_level: learner.current_level.clone(),
            notes: learner.notes.clone(),
            active_assignment,
            today_session,
            review_item_count,
            progress_status_counts,
            stage_progress,
            latest_evidence,
        });
    }
    Ok(dashboards)
}

fn summarize_progress(
    catalog: &CatalogBundle,
    active_assignment: Option<&AssignmentSummary>,
    progress: &[SkillProgressSummary],
) -> (BTreeMap<String, i64>, Vec<StageProgress>) {
    let mut counts: BTreeMap<String, i64> = BTreeMap::new();
    for state in progress {
        *counts.entry(state.status.clone()).or_insert(0) += 1;
    }

    let Some(active_assignment) = active_assignment else {
        return (counts, Vec::new());
    };
    let Some(playlist) = catalog.playlist(&active_assignment.playlist_id) else {
        return (counts, Vec::new());
    };

    let known_skills: BTreeSet<_> = progress
        .iter()
        .map(|state| state.skill_id.as_str())
        .collect();
    let not_started = playlist
        .skill_ids
        .iter()
        .filter(|skill_id| !known_skills.contains(skill_id.as_str()))
        .count() as i64;
    if not_started > 0 {
        counts.insert("not_started".to_string(), not_started);
    }

    let secure_skills: BTreeSet<_> = progress
        .iter()
        .filter(|state| state.status == "secure")
        .map(|state| state.skill_id.as_str())
        .collect();

    let stage_progress = playlist
        .stage_ids
        .iter()
        .filter_map(|stage_id| {
            let stage = catalog.stages.iter().find(|stage| stage.stage_id == *stage_id)?;
            let completed_skills = stage
                .skill_ids
                .iter()
                .filter(|skill_id| secure_skills.contains(skill_id.as_str()))
                .count();
            Some(StageProgress {
                stage_id: stage.stage_id.clone(),
                title: stage.title.clone(),
                completed_skills,
                total_skills: stage.skill_ids.len(),
            })
        })
        .collect();

    (counts, stage_progress)
}

async fn seed_default_assignments_if_missing(state: &Arc<AppState>) -> anyhow::Result<usize> {
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
            "select count(*) from assignment where learner_id = $1 and status in ('active', 'scheduled')",
        )
        .bind(&learner.learner_id)
        .fetch_one(&state.pool)
        .await?;
        if active_count > 0 {
            continue;
        }
        if let Some(playlist) = choose_default_playlist(&catalog, calculate_age(learner.date_of_birth)) {
            let _ = create_assignment_internal(
                state,
                &catalog,
                &learner.learner_id,
                &playlist.playlist_id,
                today,
            )
            .await?;
            seeded += 1;
        }
    }
    Ok(seeded)
}

fn choose_default_playlist(catalog: &CatalogBundle, age: i32) -> Option<&Playlist> {
    catalog
        .playlists
        .iter()
        .min_by_key(|playlist| (playlist.recommended_age as i32 - age).abs())
}

async fn create_assignment_internal(
    state: &Arc<AppState>,
    catalog: &CatalogBundle,
    learner_id: &str,
    playlist_id: &str,
    start_date: NaiveDate,
) -> anyhow::Result<AssignmentSummary> {
    let playlist = catalog
        .playlist(playlist_id)
        .cloned()
        .ok_or_else(|| anyhow!("unknown playlist '{playlist_id}'"))?;

    let end_date = start_date + Duration::days((playlist.duration_days.saturating_sub(1)) as i64);
    query("update assignment set status = 'replaced' where learner_id = $1 and status in ('active', 'scheduled')")
        .bind(learner_id)
        .execute(&state.pool)
        .await?;

    let assignment_id = Uuid::new_v4().to_string();
    query(
        "insert into assignment (assignment_id, learner_id, playlist_id, title, start_date, end_date, status, total_sessions, completed_sessions, created_at)
         values ($1, $2, $3, $4, $5, $6, 'active', $7, 0, $8)",
    )
    .bind(&assignment_id)
    .bind(learner_id)
    .bind(&playlist.playlist_id)
    .bind(&playlist.title)
    .bind(start_date)
    .bind(end_date)
    .bind(playlist.session_pattern.sessions.len() as i32)
    .bind(Utc::now())
    .execute(&state.pool)
    .await?;

    for session in &playlist.session_pattern.sessions {
        let scheduled_date = start_date + Duration::days(session.day_offset as i64);
        let session_id = Uuid::new_v4().to_string();
        query(
            "insert into session (session_id, assignment_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at)
             values ($1, $2, $3, $4, $5, 'scheduled', $6, '', null)",
        )
        .bind(&session_id)
        .bind(&assignment_id)
        .bind(learner_id)
        .bind(&session.title)
        .bind(scheduled_date)
        .bind(session.day_offset)
        .execute(&state.pool)
        .await?;

        for skill_id in &session.skill_ids {
            let material_id = choose_material_for_skill(catalog, session, skill_id).ok_or_else(|| {
                anyhow!(
                    "playlist '{}' has no material for skill '{}'",
                    playlist_id,
                    skill_id
                )
            })?;
            query(
                "insert into session_material (session_material_id, session_id, title, skill_id, material_id, status)
                 values ($1, $2, $3, $4, $5, 'scheduled')",
            )
            .bind(Uuid::new_v4().to_string())
            .bind(&session_id)
            .bind(format!("{}: {}", session.title, skill_id))
            .bind(skill_id)
            .bind(material_id)
            .execute(&state.pool)
            .await?;
        }
    }

    Ok(AssignmentSummary {
        assignment_id,
        playlist_id: playlist.playlist_id,
        title: playlist.title,
        start_date,
        end_date,
        status: "active".to_string(),
        total_sessions: playlist.session_pattern.sessions.len() as i32,
        completed_sessions: 0,
        completion_percent: 0,
    })
}

fn choose_material_for_skill<'a>(
    catalog: &'a CatalogBundle,
    session: &'a catalog::PlaylistSession,
    skill_id: &str,
) -> Option<&'a str> {
    for material_id in &session.material_ids {
        let material = catalog.materials.iter().find(|item| item.id == *material_id)?;
        if material.skill_ids.iter().any(|item| item == skill_id) {
            return Some(material_id.as_str());
        }
    }
    session.material_ids.first().map(String::as_str)
}

async fn fetch_active_assignment_for_learner(pool: &PgPool, learner_id: &str) -> anyhow::Result<Option<AssignmentSummary>> {
    let row = query_as::<_, AssignmentRow>(
        "select assignment_id, learner_id, playlist_id, title, start_date, end_date, status, total_sessions, completed_sessions
         from assignment
         where learner_id = $1 and status in ('active', 'scheduled', 'completed')
         order by case status when 'active' then 0 when 'scheduled' then 1 else 2 end, start_date desc
         limit 1",
    )
    .bind(learner_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(assignment_row_to_summary))
}

async fn fetch_next_session_for_assignment(pool: &PgPool, assignment_id: &str) -> anyhow::Result<Option<SessionSummary>> {
    let row = query_as::<_, SessionRow>(
        "select session_id, assignment_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
         from session
         where assignment_id = $1 and status <> 'completed'
         order by scheduled_date asc, day_offset asc
         limit 1",
    )
    .bind(assignment_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(session_row_to_summary))
}

async fn fetch_sessions(
    pool: &PgPool,
    learner_id: &str,
    assignment_id: Option<&str>,
) -> anyhow::Result<Vec<SessionDetail>> {
    let rows = if let Some(assignment_id) = assignment_id {
        query_as::<_, SessionRow>(
            "select session_id, assignment_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
             from session
             where learner_id = $1 and assignment_id = $2
             order by scheduled_date asc, day_offset asc",
        )
        .bind(learner_id)
        .bind(assignment_id)
        .fetch_all(pool)
        .await?
    } else {
        query_as::<_, SessionRow>(
            "select session_id, assignment_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
             from session
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
        let materials = query_as::<_, SessionMaterialRow>(
            "select session_material_id, session_id, title, skill_id, material_id, status
             from session_material
             where session_id = $1
             order by title, skill_id",
        )
        .bind(&row.session_id)
        .fetch_all(pool)
        .await?;
        let latest_evidence = fetch_latest_evidence_for_session(pool, &row.session_id).await?;
        sessions.push(SessionDetail {
            session_id: row.session_id,
            title: row.title,
            scheduled_date: row.scheduled_date,
            status: row.status,
            notes: row.notes,
            materials: materials.into_iter().map(session_material_row_to_summary).collect(),
            latest_evidence,
        });
    }
    Ok(sessions)
}

async fn fetch_progress(pool: &PgPool, learner_id: &str) -> anyhow::Result<Vec<SkillProgressSummary>> {
    let rows = query_as::<_, SkillProgressRow>(
        "select learner_id, skill_id, status, score_average, last_score, total_evidence, last_evidence_at
         from learner_skill_progress
         where learner_id = $1
         order by skill_id",
    )
    .bind(learner_id)
    .fetch_all(pool)
    .await?;
    Ok(rows.into_iter().map(progress_row_to_summary).collect())
}

async fn fetch_review_items(pool: &PgPool, learner_id: &str) -> anyhow::Result<Vec<ReviewItemSummary>> {
    let rows = query_as::<_, ReviewItemRow>(
        "select review_item_id, learner_id, skill_id, reason, due_date, status
         from review_item
         where learner_id = $1
         order by due_date asc, skill_id asc",
    )
    .bind(learner_id)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .map(|row| ReviewItemSummary {
            review_item_id: row.review_item_id,
            skill_id: row.skill_id,
            reason: row.reason,
            due_date: row.due_date,
            status: row.status,
        })
        .collect())
}

async fn fetch_latest_evidence_for_learner(pool: &PgPool, learner_id: &str) -> anyhow::Result<Option<EvidenceSummary>> {
    let row = query_as::<_, EvidenceRow>(
        "select evidence_id, session_id, learner_id, score, max_score, duration_minutes, notes, recorded_at
         from evidence
         where learner_id = $1
         order by recorded_at desc
         limit 1",
    )
    .bind(learner_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(evidence_row_to_summary))
}

async fn fetch_latest_evidence_for_session(pool: &PgPool, session_id: &str) -> anyhow::Result<Option<EvidenceSummary>> {
    let row = query_as::<_, EvidenceRow>(
        "select evidence_id, session_id, learner_id, score, max_score, duration_minutes, notes, recorded_at
         from evidence
         where session_id = $1
         order by recorded_at desc
         limit 1",
    )
    .bind(session_id)
    .fetch_optional(pool)
    .await?;
    Ok(row.map(evidence_row_to_summary))
}

async fn upsert_skill_progress(
    pool: &PgPool,
    learner_id: &str,
    skill_id: &str,
    status: &str,
    ratio: f64,
    recorded_at: chrono::DateTime<Utc>,
) -> anyhow::Result<SkillProgressRow> {
    query_as::<_, SkillProgressRow>(
        "insert into learner_skill_progress
            (learner_id, skill_id, status, score_average, last_score, total_evidence, last_evidence_at)
         values ($1, $2, $3, $4, $4, 1, $5)
         on conflict (learner_id, skill_id) do update
         set status = excluded.status,
             score_average = ((learner_skill_progress.score_average * learner_skill_progress.total_evidence) + excluded.last_score)
                / (learner_skill_progress.total_evidence + 1),
             last_score = excluded.last_score,
             total_evidence = learner_skill_progress.total_evidence + 1,
             last_evidence_at = excluded.last_evidence_at
         returning learner_id, skill_id, status, score_average, last_score, total_evidence, last_evidence_at",
    )
    .bind(learner_id)
    .bind(skill_id)
    .bind(status)
    .bind(ratio)
    .bind(recorded_at)
    .fetch_one(pool)
    .await
    .context("failed to update skill progress")
}

async fn rebuild_review_items_for_learner(pool: &PgPool, learner_id: &str) -> anyhow::Result<()> {
    query("delete from review_item where learner_id = $1")
        .bind(learner_id)
        .execute(pool)
        .await?;

    let states = query_as::<_, SkillProgressRow>(
        "select learner_id, skill_id, status, score_average, last_score, total_evidence, last_evidence_at
         from learner_skill_progress
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
            "insert into review_item (review_item_id, learner_id, skill_id, reason, due_date, status, created_at)
             values ($1, $2, $3, $4, $5, 'pending', $6)",
        )
        .bind(Uuid::new_v4().to_string())
        .bind(learner_id)
        .bind(&state.skill_id)
        .bind(reason)
        .bind(due_date)
        .bind(Utc::now())
        .execute(pool)
        .await?;
    }
    Ok(())
}

async fn refresh_assignment_progress(pool: &PgPool, learner_id: &str) -> anyhow::Result<()> {
    let assignments = query_as::<_, AssignmentRow>(
        "select assignment_id, learner_id, playlist_id, title, start_date, end_date, status, total_sessions, completed_sessions
         from assignment
         where learner_id = $1",
    )
    .bind(learner_id)
    .fetch_all(pool)
    .await?;
    for assignment in assignments {
        let completed_sessions = query_scalar::<_, i64>(
            "select count(*) from session where assignment_id = $1 and status = 'completed'",
        )
        .bind(&assignment.assignment_id)
        .fetch_one(pool)
        .await? as i32;
        let next_status = if assignment.status == "replaced" {
            "replaced"
        } else if assignment.total_sessions > 0 && completed_sessions >= assignment.total_sessions {
            "completed"
        } else {
            "active"
        };

        query("update assignment set completed_sessions = $2, status = $3 where assignment_id = $1")
            .bind(&assignment.assignment_id)
            .bind(completed_sessions)
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

fn assignment_row_to_summary(row: AssignmentRow) -> AssignmentSummary {
    let completion_percent = if row.total_sessions > 0 {
        (row.completed_sessions * 100) / row.total_sessions
    } else {
        0
    };
    AssignmentSummary {
        assignment_id: row.assignment_id,
        playlist_id: row.playlist_id,
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

fn session_material_row_to_summary(row: SessionMaterialRow) -> SessionMaterialSummary {
    SessionMaterialSummary {
        session_material_id: row.session_material_id,
        title: row.title,
        skill_id: row.skill_id,
        material_id: row.material_id,
        status: row.status,
    }
}

fn evidence_row_to_summary(row: EvidenceRow) -> EvidenceSummary {
    EvidenceSummary {
        evidence_id: row.evidence_id,
        score: row.score,
        max_score: row.max_score,
        duration_minutes: row.duration_minutes,
        notes: row.notes,
        recorded_at: row.recorded_at,
    }
}

fn progress_row_to_summary(row: SkillProgressRow) -> SkillProgressSummary {
    SkillProgressSummary {
        skill_id: row.skill_id,
        status: row.status,
        score_average: row.score_average,
        last_score: row.last_score,
        total_evidence: row.total_evidence,
        last_evidence_at: row.last_evidence_at,
    }
}
