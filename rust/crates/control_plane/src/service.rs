use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use anyhow::{Context, anyhow, bail};
use catalog::{LibraryBundle, LibraryDocument, LibraryValidationReport, Pathway, Playlist, PlaylistSession, load_bootstrap, load_library_content};
use chrono::{Datelike, Duration, NaiveDate, Utc};
use serde_json::{Value as JsonValue, json};
use sqlx::postgres::PgPoolOptions;
use sqlx::{PgPool, query, query_as, query_scalar};
use tokio::fs;
use tokio::sync::RwLock;
use uuid::Uuid;

use crate::config::AppConfig;
use crate::domain::{
    ActivityInstance, ActivityItem, ActivityScoringSummary, ActivityStartResponse,
    ActivitySummary, AssignmentRequest, AssignmentResponse,
    AssignmentRow, AssignmentSummary, BootstrapApplyResponse, CompleteActivityRequest,
    CompleteActivityResponse,
    DashboardResponse, EvidenceRow, EvidenceSummary, HouseholdMemberRow, HouseholdMemberSummary,
    LearnerDashboard, LearnerDetailResponse, LearnerRow, LearnerSummary, LibraryDocumentPayload,
    LibraryDocumentSummary, LibraryReloadResponse, RecordSessionRequest, RecordSessionResponse,
    ReviewItemRow, ReviewItemSummary, ReviewRebuildResponse, SessionDetail, SessionMaterialRow,
    SessionMaterialRuntimeSummary, SessionMaterialSummary, SessionRow, SessionSummary,
    SkillProgressRow, SkillProgressSummary, StageProgress, TeamRow, TeamSummary,
    ViewerSessionResponse,
};
use crate::runtime::{self, GeneratedActivity, ScoredActivity};

static MIGRATOR: sqlx::migrate::Migrator = sqlx::migrate!("./migrations");

#[derive(Clone)]
pub struct AppState {
    pub config: AppConfig,
    pub pool: PgPool,
    pub library: Arc<RwLock<LibraryBundle>>,
    pub library_documents: Arc<RwLock<Vec<LibraryDocument>>>,
    pub library_report: Arc<RwLock<LibraryValidationReport>>,
}

fn role_can_manage_household(role: &str) -> bool {
    matches!(role, "owner" | "parent" | "teacher")
}

fn role_can_open_developer_docs(role: &str) -> bool {
    role == "owner"
}

fn ensure_viewer_can_manage_household(viewer: &HouseholdMemberSummary) -> anyhow::Result<()> {
    if viewer.can_manage_household {
        return Ok(());
    }
    bail!("viewer '{}' cannot manage the household workspace", viewer.username)
}

fn ensure_viewer_can_read_library(viewer: &HouseholdMemberSummary) -> anyhow::Result<()> {
    if viewer.can_read_library {
        return Ok(());
    }
    bail!("viewer '{}' cannot read the planning library", viewer.username)
}

fn ensure_viewer_can_access_learner(
    viewer: &HouseholdMemberSummary,
    learner_id: &str,
) -> anyhow::Result<()> {
    if viewer.can_view_all_learners {
        return Ok(());
    }
    if viewer.learner_id.as_deref() == Some(learner_id) {
        return Ok(());
    }
    bail!(
        "viewer '{}' cannot access learner '{}'",
        viewer.username,
        learner_id
    )
}

async fn resolve_viewer_member(
    state: &Arc<AppState>,
    username: &str,
) -> anyhow::Result<HouseholdMemberSummary> {
    let normalized = username.trim();
    if normalized.is_empty() {
        bail!("viewer username is required")
    }

    let member = query_as::<_, HouseholdMemberRow>(
        "select
            ua.user_id,
            ua.username,
            ua.display_name,
            tm.role,
            ua.current_level,
            coalesce(ua.notes, '') as notes,
            lp.learner_id
         from team_membership tm
         join user_account ua on ua.user_id = tm.user_id
         left join learner_profile lp on lp.user_id = ua.user_id
         where lower(ua.username) = lower($1)
         order by tm.team_id
         limit 1",
    )
    .bind(normalized)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| anyhow!("viewer '{}' not found", normalized))?;

    Ok(member_row_to_summary(member))
}

pub async fn initialize_state(config: AppConfig, run_startup_bootstrap: bool) -> anyhow::Result<Arc<AppState>> {
    fs::create_dir_all(&config.artifacts_root)
        .await
        .with_context(|| format!("failed to create {}", config.artifacts_root.display()))?;
    fs::create_dir_all(&config.exports_root)
        .await
        .with_context(|| format!("failed to create {}", config.exports_root.display()))?;

    let library_content = load_library_content(&config.content_root)?;
    let pool = PgPoolOptions::new()
        .max_connections(8)
        .connect(&config.database_url)
        .await
        .context("failed to connect to Postgres")?;
    MIGRATOR.run(&pool).await.context("failed to run database migrations")?;

    let state = Arc::new(AppState {
        config,
        pool,
        library: Arc::new(RwLock::new(library_content.bundle)),
        library_documents: Arc::new(RwLock::new(library_content.documents)),
        library_report: Arc::new(RwLock::new(library_content.report)),
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

pub async fn reload_library(
    state: &Arc<AppState>,
    viewer_username: &str,
) -> anyhow::Result<LibraryReloadResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_manage_household(&viewer)?;

    let library_content = load_library_content(&state.config.content_root)?;
    {
        let mut library_guard = state.library.write().await;
        *library_guard = library_content.bundle;
    }
    {
        let mut documents_guard = state.library_documents.write().await;
        *documents_guard = library_content.documents;
    }
    {
        let mut report_guard = state.library_report.write().await;
        *report_guard = library_content.report;
    }
    Ok(library_report_response(&*state.library_report.read().await))
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

pub async fn fetch_library(
    state: &Arc<AppState>,
    viewer_username: &str,
) -> anyhow::Result<(LibraryBundle, LibraryReloadResponse)> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_read_library(&viewer)?;

    let bundle = state.library.read().await.clone();
    let report = library_report_response(&*state.library_report.read().await);
    Ok((bundle, report))
}

pub async fn list_library_documents(
    state: &Arc<AppState>,
    viewer_username: &str,
) -> anyhow::Result<Vec<LibraryDocumentSummary>> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_read_library(&viewer)?;

    Ok(state
        .library_documents
        .read()
        .await
        .iter()
        .map(library_document_summary)
        .collect())
}

pub async fn fetch_library_document(
    state: &Arc<AppState>,
    viewer_username: &str,
    route_path: &str,
) -> anyhow::Result<LibraryDocumentPayload> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_read_library(&viewer)?;

    let normalized = route_path.trim().trim_matches('/');
    if normalized.is_empty() {
        bail!("route_path is required");
    }

    let documents = state.library_documents.read().await;
    let document = documents
        .iter()
        .find(|document| document.route_path == normalized)
        .ok_or_else(|| anyhow!("library document '{}' not found", normalized))?;
    Ok(library_document_payload(document))
}

pub async fn fetch_viewer_session(
    state: &Arc<AppState>,
    username: Option<&str>,
) -> anyhow::Result<ViewerSessionResponse> {
    let team = fetch_team_summary(state).await?;
    let available_users = list_household_members(state).await?;
    let current_user = username.and_then(|value| {
        let normalized = value.trim();
        if normalized.is_empty() {
            return None;
        }
        available_users
            .iter()
            .find(|member| member.username.eq_ignore_ascii_case(normalized))
            .cloned()
    });

    Ok(ViewerSessionResponse {
        status: "ok".to_string(),
        team,
        current_user,
        available_users,
        developer_docs_url: state.config.developer_docs_public_url.clone(),
    })
}

pub async fn login_viewer_session(
    state: &Arc<AppState>,
    username: &str,
) -> anyhow::Result<ViewerSessionResponse> {
    let normalized = username.trim();
    if normalized.is_empty() {
        bail!("username is required");
    }

    let session = fetch_viewer_session(state, Some(normalized)).await?;
    if session.current_user.is_none() {
        bail!("username '{}' not found", normalized);
    }

    Ok(session)
}

pub async fn fetch_dashboard(
    state: &Arc<AppState>,
    viewer_username: &str,
) -> anyhow::Result<DashboardResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    let team = fetch_team_summary(state).await?;
    let learners = query_as::<_, LearnerRow>(
        "select learner_id, team_id, user_id, display_name, date_of_birth, sex, current_level, notes
         from learner_profile
         order by display_name",
    )
    .fetch_all(&state.pool)
    .await?;

    let library = state.library.read().await.clone();
    let visible_learners = if viewer.can_view_all_learners {
        learners
    } else if let Some(learner_id) = viewer.learner_id.as_deref() {
        learners
            .into_iter()
            .filter(|learner| learner.learner_id == learner_id)
            .collect()
    } else {
        Vec::new()
    };
    let learner_dashboards = build_dashboard_cards(state, &library, &visible_learners).await?;
    let library_report = if viewer.can_read_library {
        Some(library_report_response(&*state.library_report.read().await))
    } else {
        None
    };

    Ok(DashboardResponse {
        team,
        library: library_report,
        learners: learner_dashboards,
    })
}

pub async fn list_learners(
    state: &Arc<AppState>,
    viewer_username: &str,
) -> anyhow::Result<Vec<LearnerSummary>> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    let learners = query_as::<_, LearnerRow>(
        "select learner_id, team_id, user_id, display_name, date_of_birth, sex, current_level, notes
         from learner_profile
         order by display_name",
    )
    .fetch_all(&state.pool)
    .await?;

    Ok(learners
        .into_iter()
        .filter(|learner| viewer.can_view_all_learners || viewer.learner_id.as_deref() == Some(learner.learner_id.as_str()))
        .map(|learner| LearnerSummary {
            learner_id: learner.learner_id,
            display_name: learner.display_name,
            current_age: calculate_age(learner.date_of_birth),
            current_level: learner.current_level,
            notes: learner.notes,
        })
        .collect())
}

pub async fn fetch_learner_detail(
    state: &Arc<AppState>,
    viewer_username: &str,
    learner_id: &str,
) -> anyhow::Result<LearnerDetailResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_access_learner(&viewer, learner_id)?;

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
    let library = state.library.read().await.clone();
    let sessions = fetch_sessions(&state.pool, &library, learner_id, assignment_filter.as_deref()).await?;
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
    viewer_username: &str,
    request: AssignmentRequest,
) -> anyhow::Result<AssignmentResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_manage_household(&viewer)?;

    let library = state.library.read().await.clone();
    let assignment = create_assignment_internal(
        state,
        &library,
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
    viewer_username: &str,
    session_id: &str,
    request: RecordSessionRequest,
) -> anyhow::Result<RecordSessionResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_manage_household(&viewer)?;

    if request.max_score <= 0.0 {
        bail!("max_score must be greater than zero");
    }
    let (session, materials) = load_session_and_material_rows(&state.pool, session_id).await?;
    let notes = request.notes.trim().to_string();
    let artifact_summary = if notes.is_empty() {
        session.title.clone()
    } else {
        format!("{}: {}", session.title, notes)
    };
    let artifact_payload = json!({
        "session_id": session.session_id,
        "learner_id": session.learner_id,
        "score": request.score,
        "max_score": request.max_score,
        "duration_minutes": request.duration_minutes,
        "notes": notes,
        "recording_mode": "manual",
    });

    persist_session_result(
        state,
        &session,
        &materials,
        request.score,
        request.max_score,
        request.duration_minutes,
        notes,
        "session_notes",
        artifact_summary,
        artifact_payload,
    )
    .await
}

pub async fn start_session_material_activity(
    state: &Arc<AppState>,
    viewer_username: &str,
    session_id: &str,
    session_material_id: &str,
) -> anyhow::Result<ActivityStartResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    let (session, materials) = load_session_and_material_rows(&state.pool, session_id).await?;
    ensure_viewer_can_access_learner(&viewer, &session.learner_id)?;
    if session.status == "completed" {
        bail!("session '{session_id}' is already completed");
    }

    let session_material = materials
        .iter()
        .find(|material| material.session_material_id == session_material_id)
        .ok_or_else(|| anyhow!("session material '{session_material_id}' not found"))?;

    let library = state.library.read().await.clone();
    let material = library
        .material(&session_material.material_id)
        .ok_or_else(|| anyhow!("material '{}' not found in library", session_material.material_id))?;
    let generated = runtime::generate_activity(material, runtime::activity_seed())
        .context("failed to generate activity")?;

    query("update session set status = 'active' where session_id = $1 and status = 'scheduled'")
        .bind(&session.session_id)
        .execute(&state.pool)
        .await?;
    query(
        "update session_material set status = 'active' where session_id = $1 and material_id = $2 and status = 'scheduled'",
    )
    .bind(&session.session_id)
    .bind(&session_material.material_id)
    .execute(&state.pool)
    .await?;

    Ok(ActivityStartResponse {
        status: "ok".to_string(),
        activity: ActivityInstance {
            activity_instance_id: runtime::build_activity_instance_id(
                &session_material.session_material_id,
                generated.seed,
            ),
            session_id: session.session_id,
            session_material_id: session_material.session_material_id.clone(),
            material_id: material.id.clone(),
            material_title: material.title.clone(),
            runtime_id: generated.runtime_id.clone(),
            engine_id: generated.engine_id,
            template_id: generated.template_id,
            instructions: generated.instructions,
            estimated_minutes: material.estimated_minutes,
            scoring: ActivityScoringSummary {
                pass_accuracy: generated.pass_accuracy,
                soft_time_limit_seconds: generated.soft_time_limit_seconds,
            },
            items: generated
                .items
                .into_iter()
                .map(|item| ActivityItem {
                    item_id: item.item_id,
                    content: item.content,
                    response_kind: item.response_kind,
                })
                .collect(),
        },
    })
}

pub async fn complete_activity_instance(
    state: &Arc<AppState>,
    viewer_username: &str,
    activity_instance_id: &str,
    request: CompleteActivityRequest,
) -> anyhow::Result<CompleteActivityResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    let (session_material_id, seed) = runtime::parse_activity_instance_id(activity_instance_id)?;
    let session_material = load_session_material_row(&state.pool, &session_material_id).await?;
    let session = load_session_row(&state.pool, &session_material.session_id).await?;
    ensure_viewer_can_access_learner(&viewer, &session.learner_id)?;
    if session.status == "completed" {
        bail!("session '{}' is already completed", session.session_id);
    }

    let library = state.library.read().await.clone();
    let material = library
        .material(&session_material.material_id)
        .ok_or_else(|| anyhow!("material '{}' not found in library", session_material.material_id))?;
    let generated = runtime::generate_activity(material, seed)
        .context("failed to regenerate activity for scoring")?;
    let scored = runtime::score_activity(material, &generated, &request.responses)
        .context("failed to score activity")?;
    let (_, materials) = load_session_and_material_rows(&state.pool, &session.session_id).await?;

    let notes = build_activity_notes(&material.title, &scored, &request.notes);
    let artifact_summary = format!(
        "{}: {}/{} correct",
        material.title, scored.correct_count, scored.item_count
    );
    let artifact_payload = build_activity_artifact_payload(
        &session,
        &session_material,
        material,
        &generated,
        &scored,
        request.duration_seconds,
    );
    let persisted = persist_session_result(
        state,
        &session,
        &materials,
        scored.correct_count as f64,
        scored.item_count as f64,
        duration_minutes_from_seconds(request.duration_seconds),
        notes,
        "activity_summary",
        artifact_summary,
        artifact_payload,
    )
    .await?;

    Ok(CompleteActivityResponse {
        status: "ok".to_string(),
        evidence: persisted.evidence,
        updated_progress: persisted.updated_progress,
        activity_summary: ActivitySummary {
            attempted_count: scored.attempted_count,
            correct_count: scored.correct_count,
            item_count: scored.item_count,
            accuracy: scored.accuracy,
            passed: scored.passed,
            completion_reason: scored.completion_reason,
            weak_groups: scored.weak_groups,
        },
    })
}

async fn persist_session_result(
    state: &Arc<AppState>,
    session: &SessionRow,
    materials: &[SessionMaterialRow],
    score: f64,
    max_score: f64,
    duration_minutes: i32,
    notes: String,
    artifact_kind: &str,
    artifact_summary: String,
    artifact_payload: JsonValue,
) -> anyhow::Result<RecordSessionResponse> {
    if max_score <= 0.0 {
        bail!("max_score must be greater than zero");
    }
    if session.status == "completed" {
        bail!("session '{}' is already completed", session.session_id);
    }

    let now = Utc::now();
    let evidence_id = Uuid::new_v4().to_string();
    let ratio = (score / max_score).clamp(0.0, 1.0);
    let progress_status = status_from_ratio(ratio);

    query(
        "insert into evidence (evidence_id, session_id, learner_id, score, max_score, duration_minutes, notes, recorded_at)
         values ($1, $2, $3, $4, $5, $6, $7, $8)",
    )
    .bind(&evidence_id)
    .bind(&session.session_id)
    .bind(&session.learner_id)
    .bind(score)
    .bind(max_score)
    .bind(duration_minutes)
    .bind(&notes)
    .bind(now)
    .execute(&state.pool)
    .await?;

    let evidence_relative_path = format!("evidence/{}/{}.json", session.learner_id, evidence_id);
    let evidence_full_path = state.config.artifacts_root.join(&evidence_relative_path);
    if let Some(parent) = evidence_full_path.parent() {
        fs::create_dir_all(parent).await?;
    }
    fs::write(
        &evidence_full_path,
        serde_json::to_vec_pretty(&artifact_payload)?,
    )
    .await?;

    query(
        "insert into evidence_artifact (evidence_artifact_id, evidence_id, learner_id, kind, storage_path, summary)
         values ($1, $2, $3, $4, $5, $6)",
    )
    .bind(Uuid::new_v4().to_string())
    .bind(&evidence_id)
    .bind(&session.learner_id)
    .bind(artifact_kind)
    .bind(&evidence_relative_path)
    .bind(&artifact_summary)
    .execute(&state.pool)
    .await?;

    query("update session set status = $2, notes = $3, completed_at = $4 where session_id = $1")
        .bind(&session.session_id)
        .bind("completed")
        .bind(&notes)
        .bind(now)
        .execute(&state.pool)
        .await?;

    query("update session_material set status = 'completed' where session_id = $1")
        .bind(&session.session_id)
        .execute(&state.pool)
        .await?;

    let skill_ids: BTreeSet<_> = materials
        .iter()
        .map(|material| material.skill_id.as_str())
        .collect();
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
            score,
            max_score,
            duration_minutes,
            notes,
            recorded_at: now,
        },
        updated_progress,
    })
}

pub async fn rebuild_review_items(
    state: &Arc<AppState>,
    viewer_username: &str,
    learner_id: Option<String>,
) -> anyhow::Result<ReviewRebuildResponse> {
    let viewer = resolve_viewer_member(state, viewer_username).await?;
    ensure_viewer_can_manage_household(&viewer)?;

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

fn library_report_response(report: &LibraryValidationReport) -> LibraryReloadResponse {
    LibraryReloadResponse {
        status: "ok".to_string(),
        subject_count: report.subject_count,
        area_count: report.area_count,
        pathway_count: report.pathway_count,
        skill_count: report.skill_count,
        stage_count: report.stage_count,
        playlist_count: report.playlist_count,
        material_count: report.material_count,
        loaded_at_utc: report.loaded_at_utc.clone(),
    }
}

fn library_document_summary(document: &LibraryDocument) -> LibraryDocumentSummary {
    LibraryDocumentSummary {
        route_path: document.route_path.clone(),
        source_path: document.source_path.clone(),
        kind: document.kind.clone(),
        document_id: document.document_id.clone(),
        title: document.title.clone(),
        subject_id: document.subject_id.clone(),
        area_id: document.area_id.clone(),
        pathway_id: document.pathway_id.clone(),
        description: document.description.clone(),
    }
}

fn library_document_payload(document: &LibraryDocument) -> LibraryDocumentPayload {
    LibraryDocumentPayload {
        route_path: document.route_path.clone(),
        source_path: document.source_path.clone(),
        kind: document.kind.clone(),
        document_id: document.document_id.clone(),
        title: document.title.clone(),
        subject_id: document.subject_id.clone(),
        area_id: document.area_id.clone(),
        pathway_id: document.pathway_id.clone(),
        description: document.description.clone(),
        body: document.body.clone(),
    }
}

async fn fetch_team_summary(state: &Arc<AppState>) -> anyhow::Result<Option<TeamSummary>> {
    let team = query_as::<_, TeamRow>("select team_id, display_name, description from team order by team_id limit 1")
        .fetch_optional(&state.pool)
        .await?;

    Ok(team.map(|row| TeamSummary {
        team_id: row.team_id,
        display_name: row.display_name,
        description: row.description,
    }))
}

async fn list_household_members(state: &Arc<AppState>) -> anyhow::Result<Vec<HouseholdMemberSummary>> {
    let members = query_as::<_, HouseholdMemberRow>(
        "select
            ua.user_id,
            ua.username,
            ua.display_name,
            tm.role,
            ua.current_level,
            coalesce(ua.notes, '') as notes,
            lp.learner_id
         from team_membership tm
         join user_account ua on ua.user_id = tm.user_id
         left join learner_profile lp on lp.user_id = ua.user_id
         order by case when tm.role = 'owner' then 0 else 1 end, ua.display_name",
    )
    .fetch_all(&state.pool)
    .await?;

    Ok(members.into_iter().map(member_row_to_summary).collect())
}

fn member_row_to_summary(row: HouseholdMemberRow) -> HouseholdMemberSummary {
    let role = row.role.clone();
    let can_manage_household = role_can_manage_household(&role);
    HouseholdMemberSummary {
        user_id: row.user_id,
        username: row.username,
        display_name: row.display_name,
        role,
        current_level: row.current_level,
        notes: row.notes,
        learner_id: row.learner_id,
        can_manage_household,
        can_read_library: can_manage_household,
        can_view_all_learners: can_manage_household,
        can_open_developer_docs: role_can_open_developer_docs(&row.role),
    }
}

async fn build_dashboard_cards(
    state: &Arc<AppState>,
    library: &LibraryBundle,
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
            summarize_progress(library, active_assignment.as_ref(), &progress);

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
    library: &LibraryBundle,
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
    let Some(playlist) = library.playlist(&active_assignment.playlist_id) else {
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
            let stage = library.stages.iter().find(|stage| stage.stage_id == *stage_id)?;
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
    let library = state.library.read().await.clone();
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
        if let Some(playlist) = choose_default_playlist(&library, calculate_age(learner.date_of_birth)) {
            let _ = create_assignment_internal(
                state,
            &library,
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

fn choose_default_playlist(library: &LibraryBundle, age: i32) -> Option<&Playlist> {
    let normalized_age = age.clamp(0, u8::MAX as i32) as u8;

    let pathway_candidate = library
        .pathways
        .iter()
        .min_by_key(|pathway| pathway_age_distance(pathway, normalized_age));
    if let Some(pathway) = pathway_candidate {
        if let Some(playlist_id) = choose_pathway_entry_point(pathway, normalized_age) {
            if let Some(playlist) = library.playlist(playlist_id) {
                return Some(playlist);
            }
        }
    }

    library
        .playlists
        .iter()
        .min_by_key(|playlist| (playlist.recommended_age as i32 - age).abs())
}

fn pathway_age_distance(pathway: &Pathway, age: u8) -> u8 {
    if age < pathway.recommended_age_min {
        pathway.recommended_age_min - age
    } else if age > pathway.recommended_age_max {
        age - pathway.recommended_age_max
    } else {
        0
    }
}

fn choose_pathway_entry_point<'a>(pathway: &'a Pathway, age: u8) -> Option<&'a str> {
    let mut thresholds = pathway
        .entry_points
        .iter()
        .filter_map(|(key, playlist_id)| {
            key.strip_prefix("age_")
                .and_then(|value| value.parse::<u8>().ok())
                .map(|threshold| (threshold, playlist_id.as_str()))
        })
        .collect::<Vec<_>>();
    thresholds.sort_by_key(|(threshold, _)| *threshold);

    thresholds
        .iter()
        .rev()
        .find(|(threshold, _)| age >= *threshold)
        .map(|(_, playlist_id)| *playlist_id)
        .or_else(|| thresholds.first().map(|(_, playlist_id)| *playlist_id))
}

async fn create_assignment_internal(
    state: &Arc<AppState>,
    library: &LibraryBundle,
    learner_id: &str,
    playlist_id: &str,
    start_date: NaiveDate,
) -> anyhow::Result<AssignmentSummary> {
    let playlist = library
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
            let material_id = choose_material_for_skill(library, session, skill_id).ok_or_else(|| {
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
    library: &'a LibraryBundle,
    session: &'a PlaylistSession,
    skill_id: &str,
) -> Option<&'a str> {
    for material_id in &session.material_ids {
        let material = library.materials.iter().find(|item| item.id == *material_id)?;
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
    library: &LibraryBundle,
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
        let material_rows = query_as::<_, SessionMaterialRow>(
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
            materials: build_session_material_summaries(library, material_rows),
            latest_evidence,
        });
    }
    Ok(sessions)
}

fn build_session_material_summaries(
    library: &LibraryBundle,
    rows: Vec<SessionMaterialRow>,
) -> Vec<SessionMaterialSummary> {
    let mut grouped: BTreeMap<String, Vec<SessionMaterialRow>> = BTreeMap::new();
    let mut material_order = Vec::new();
    for row in rows {
        if !grouped.contains_key(&row.material_id) {
            material_order.push(row.material_id.clone());
        }
        grouped.entry(row.material_id.clone()).or_default().push(row);
    }

    let mut summaries = Vec::new();
    for material_id in material_order {
        let Some(group) = grouped.remove(&material_id) else {
            continue;
        };
        let first = &group[0];
        let material = library.material(&material_id);
        let skill_ids = group
            .iter()
            .map(|row| row.skill_id.clone())
            .collect::<BTreeSet<_>>()
            .into_iter()
            .collect();
        let status = if group.iter().all(|row| row.status == "completed") {
            "completed".to_string()
        } else if group.iter().any(|row| row.status == "active") {
            "active".to_string()
        } else {
            first.status.clone()
        };
        summaries.push(SessionMaterialSummary {
            session_material_id: first.session_material_id.clone(),
            title: material
                .map(|item| item.title.clone())
                .unwrap_or_else(|| first.title.clone()),
            material_id: material_id.clone(),
            kind: material
                .map(|item| item.kind.clone())
                .unwrap_or_else(|| "material".to_string()),
            estimated_minutes: material.map(|item| item.estimated_minutes).unwrap_or(0),
            skill_ids,
            status,
            runtime: material.and_then(|item| {
                item.runtime.as_ref().map(|runtime| SessionMaterialRuntimeSummary {
                    runtime_id: runtime::build_runtime_id(&runtime.engine_id, &runtime.template_id),
                    engine_id: runtime.engine_id.clone(),
                    template_id: runtime.template_id.clone(),
                    executable: true,
                })
            }),
        });
    }

    summaries
}

async fn load_session_row(pool: &PgPool, session_id: &str) -> anyhow::Result<SessionRow> {
    query_as::<_, SessionRow>(
        "select session_id, assignment_id, learner_id, title, scheduled_date, status, day_offset, notes, completed_at
         from session
         where session_id = $1",
    )
    .bind(session_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("session '{session_id}' not found"))
}

async fn load_session_material_row(
    pool: &PgPool,
    session_material_id: &str,
) -> anyhow::Result<SessionMaterialRow> {
    query_as::<_, SessionMaterialRow>(
        "select session_material_id, session_id, title, skill_id, material_id, status
         from session_material
         where session_material_id = $1",
    )
    .bind(session_material_id)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("session material '{session_material_id}' not found"))
}

async fn load_session_and_material_rows(
    pool: &PgPool,
    session_id: &str,
) -> anyhow::Result<(SessionRow, Vec<SessionMaterialRow>)> {
    let session = load_session_row(pool, session_id).await?;
    let materials = query_as::<_, SessionMaterialRow>(
        "select session_material_id, session_id, title, skill_id, material_id, status
         from session_material
         where session_id = $1
         order by title, skill_id",
    )
    .bind(session_id)
    .fetch_all(pool)
    .await?;
    Ok((session, materials))
}

fn build_activity_notes(material_title: &str, scored: &ScoredActivity, notes: &str) -> String {
    let automatic = if scored.weak_groups.is_empty() {
        format!(
            "{}: {}/{} correct ({:.0}% accuracy)",
            material_title,
            scored.correct_count,
            scored.item_count,
            scored.accuracy * 100.0,
        )
    } else {
        format!(
            "{}: {}/{} correct ({:.0}% accuracy). Weak groups: {}",
            material_title,
            scored.correct_count,
            scored.item_count,
            scored.accuracy * 100.0,
            scored.weak_groups.join(", "),
        )
    };
    let trimmed = notes.trim();
    if trimmed.is_empty() {
        automatic
    } else {
        format!("{} | {}", trimmed, automatic)
    }
}

fn build_activity_artifact_payload(
    session: &SessionRow,
    session_material: &SessionMaterialRow,
    material: &catalog::MaterialDocument,
    generated: &GeneratedActivity,
    scored: &ScoredActivity,
    duration_seconds: i32,
) -> JsonValue {
    let mut payload = json!({
        "session_id": session.session_id,
        "learner_id": session.learner_id,
        "session_material_id": session_material.session_material_id,
        "material_id": material.id,
        "material_title": material.title,
        "runtime_id": generated.runtime_id,
        "engine_id": generated.engine_id,
        "template_id": generated.template_id,
        "attempted_count": scored.attempted_count,
        "correct_count": scored.correct_count,
        "item_count": scored.item_count,
        "accuracy": scored.accuracy,
        "passed": scored.passed,
        "completion_reason": scored.completion_reason,
        "weak_groups": scored.weak_groups,
        "duration_seconds": duration_seconds.max(0),
        "recording_mode": "activity",
    });
    if generated.store_response_log {
        payload["response_log"] = JsonValue::Array(scored.response_log.clone());
    }
    payload
}

fn duration_minutes_from_seconds(duration_seconds: i32) -> i32 {
    if duration_seconds <= 0 {
        return 0;
    }
    (duration_seconds + 59) / 60
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
