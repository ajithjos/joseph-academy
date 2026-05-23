use std::collections::BTreeMap;

use chrono::{DateTime, NaiveDate, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize)]
pub struct OperationStatusResponse {
    pub status: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct CatalogReloadResponse {
    pub status: String,
    pub subject_count: usize,
    pub capability_count: usize,
    pub milestone_count: usize,
    pub plan_template_count: usize,
    pub content_item_count: usize,
    pub loaded_at_utc: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct BootstrapApplyResponse {
    pub status: String,
    pub team_id: String,
    pub user_count: usize,
    pub membership_count: usize,
    pub learner_count: usize,
    pub seeded_plan_count: usize,
}

#[derive(Debug, Clone, Serialize)]
pub struct DashboardResponse {
    pub team: Option<TeamSummary>,
    pub catalog: CatalogReloadResponse,
    pub learners: Vec<LearnerDashboard>,
}

#[derive(Debug, Clone, Serialize)]
pub struct TeamSummary {
    pub team_id: String,
    pub display_name: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct LearnerDashboard {
    pub learner_id: String,
    pub display_name: String,
    pub current_age: i32,
    pub current_level: String,
    pub notes: String,
    pub active_plan: Option<PlanSummary>,
    pub today_session: Option<SessionSummary>,
    pub review_queue_count: i64,
    pub capability_status_counts: BTreeMap<String, i64>,
    pub milestone_progress: Vec<MilestoneProgress>,
    pub latest_attempt: Option<AttemptSummary>,
}

#[derive(Debug, Clone, Serialize)]
pub struct LearnerDetailResponse {
    pub learner: LearnerSummary,
    pub active_plan: Option<PlanSummary>,
    pub sessions: Vec<SessionDetail>,
    pub capability_states: Vec<CapabilityStateSummary>,
    pub review_queue: Vec<ReviewQueueSummary>,
}

#[derive(Debug, Clone, Serialize)]
pub struct LearnerSummary {
    pub learner_id: String,
    pub display_name: String,
    pub current_age: i32,
    pub current_level: String,
    pub notes: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct PlanSummary {
    pub learning_plan_id: String,
    pub plan_assignment_id: String,
    pub plan_template_id: String,
    pub title: String,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub status: String,
    pub total_sessions: i32,
    pub completed_sessions: i32,
    pub completion_percent: i32,
}

#[derive(Debug, Clone, Serialize)]
pub struct SessionSummary {
    pub session_id: String,
    pub title: String,
    pub scheduled_date: NaiveDate,
    pub status: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct SessionDetail {
    pub session_id: String,
    pub title: String,
    pub scheduled_date: NaiveDate,
    pub status: String,
    pub notes: String,
    pub activities: Vec<SessionActivitySummary>,
    pub latest_attempt: Option<AttemptSummary>,
}

#[derive(Debug, Clone, Serialize)]
pub struct SessionActivitySummary {
    pub activity_id: String,
    pub title: String,
    pub capability_id: String,
    pub content_id: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct AttemptSummary {
    pub attempt_id: String,
    pub score: f64,
    pub max_score: f64,
    pub duration_minutes: i32,
    pub notes: String,
    pub recorded_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize)]
pub struct CapabilityStateSummary {
    pub capability_id: String,
    pub status: String,
    pub score_average: f64,
    pub last_score: f64,
    pub total_attempts: i32,
    pub last_attempted_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ReviewQueueSummary {
    pub review_queue_item_id: String,
    pub capability_id: String,
    pub reason: String,
    pub due_date: NaiveDate,
    pub status: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct MilestoneProgress {
    pub milestone_id: String,
    pub title: String,
    pub completed_capabilities: usize,
    pub total_capabilities: usize,
}

#[derive(Debug, Clone, Deserialize)]
pub struct PlanAssignmentRequest {
    pub learner_id: String,
    pub plan_template_id: String,
    pub start_date: NaiveDate,
}

#[derive(Debug, Clone, Serialize)]
pub struct PlanAssignmentResponse {
    pub status: String,
    pub learning_plan: PlanSummary,
}

#[derive(Debug, Clone, Deserialize)]
pub struct RecordSessionRequest {
    pub score: f64,
    pub max_score: f64,
    pub duration_minutes: i32,
    pub notes: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct RecordSessionResponse {
    pub status: String,
    pub attempt: AttemptSummary,
    pub updated_capabilities: Vec<CapabilityStateSummary>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ReviewRebuildRequest {
    pub learner_id: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ReviewRebuildResponse {
    pub status: String,
    pub learner_ids: Vec<String>,
    pub review_item_count: usize,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct TeamRow {
    pub team_id: String,
    pub display_name: String,
    pub description: String,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct LearnerRow {
    pub learner_id: String,
    pub team_id: String,
    pub user_id: String,
    pub display_name: String,
    pub date_of_birth: NaiveDate,
    pub sex: String,
    pub current_level: String,
    pub notes: String,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct PlanRow {
    pub learning_plan_id: String,
    pub plan_assignment_id: String,
    pub learner_id: String,
    pub plan_template_id: String,
    pub title: String,
    pub start_date: NaiveDate,
    pub end_date: NaiveDate,
    pub status: String,
    pub total_sessions: i32,
    pub completed_sessions: i32,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct SessionRow {
    pub session_id: String,
    pub learning_plan_id: String,
    pub learner_id: String,
    pub title: String,
    pub scheduled_date: NaiveDate,
    pub status: String,
    pub day_offset: i32,
    pub notes: String,
    pub completed_at: Option<DateTime<Utc>>,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct SessionActivityRow {
    pub activity_id: String,
    pub session_id: String,
    pub title: String,
    pub capability_id: String,
    pub content_id: String,
    pub status: String,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct AttemptRow {
    pub attempt_id: String,
    pub session_id: String,
    pub learner_id: String,
    pub score: f64,
    pub max_score: f64,
    pub duration_minutes: i32,
    pub notes: String,
    pub recorded_at: DateTime<Utc>,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct CapabilityStateRow {
    pub learner_id: String,
    pub capability_id: String,
    pub status: String,
    pub score_average: f64,
    pub last_score: f64,
    pub total_attempts: i32,
    pub last_attempted_at: Option<DateTime<Utc>>,
}

#[allow(dead_code)]
#[derive(Debug, Clone, FromRow)]
pub struct ReviewQueueRow {
    pub review_queue_item_id: String,
    pub learner_id: String,
    pub capability_id: String,
    pub reason: String,
    pub due_date: NaiveDate,
    pub status: String,
}
