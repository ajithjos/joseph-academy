use std::sync::Arc;

use anyhow::Error;
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::Serialize;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

use crate::domain::{
    CatalogReloadResponse, OperationStatusResponse, PlanAssignmentRequest, RecordSessionRequest, ReviewRebuildRequest,
};
use crate::service::{
    AppState, apply_bootstrap, assign_plan, fetch_catalog, fetch_dashboard, fetch_learner_detail, list_learners,
    rebuild_review_queue, record_session, reload_catalog,
};

#[derive(Debug)]
pub struct ApiError(pub Error);

#[derive(Debug, Clone, Serialize)]
struct ErrorPayload {
    status: String,
    message: String,
}

#[derive(Debug, Clone, Serialize)]
struct CatalogPayload {
    report: CatalogReloadResponse,
    bundle: ja_catalog::CatalogBundle,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let payload = Json(ErrorPayload {
            status: "error".to_string(),
            message: self.0.to_string(),
        });
        (StatusCode::BAD_REQUEST, payload).into_response()
    }
}

impl From<Error> for ApiError {
    fn from(value: Error) -> Self {
        Self(value)
    }
}

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/api/v1/catalog", get(get_catalog))
        .route("/api/v1/catalog/reload", post(post_catalog_reload))
        .route("/api/v1/bootstrap/apply", post(post_bootstrap_apply))
        .route("/api/v1/dashboard", get(get_dashboard))
        .route("/api/v1/learners", get(get_learners))
        .route("/api/v1/learners/{learner_id}", get(get_learner_detail))
        .route("/api/v1/plan-assignments", post(post_plan_assignment))
        .route("/api/v1/sessions/{session_id}/record", post(post_record_session))
        .route("/api/v1/review/rebuild", post(post_review_rebuild))
        .with_state(state)
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
}

async fn health() -> Json<OperationStatusResponse> {
    Json(OperationStatusResponse {
        status: "ok".to_string(),
        message: "joseph academy control plane is healthy".to_string(),
    })
}

async fn get_catalog(State(state): State<Arc<AppState>>) -> Result<Json<CatalogPayload>, ApiError> {
    let (bundle, report) = fetch_catalog(&state).await;
    Ok(Json(CatalogPayload { report, bundle }))
}

async fn post_catalog_reload(State(state): State<Arc<AppState>>) -> Result<Json<CatalogReloadResponse>, ApiError> {
    Ok(Json(reload_catalog(&state).await?))
}

async fn post_bootstrap_apply(
    State(state): State<Arc<AppState>>,
) -> Result<Json<crate::domain::BootstrapApplyResponse>, ApiError> {
    Ok(Json(apply_bootstrap(&state).await?))
}

async fn get_dashboard(State(state): State<Arc<AppState>>) -> Result<Json<crate::domain::DashboardResponse>, ApiError> {
    Ok(Json(fetch_dashboard(&state).await?))
}

async fn get_learners(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<crate::domain::LearnerSummary>>, ApiError> {
    Ok(Json(list_learners(&state).await?))
}

async fn get_learner_detail(
    Path(learner_id): Path<String>,
    State(state): State<Arc<AppState>>,
) -> Result<Json<crate::domain::LearnerDetailResponse>, ApiError> {
    Ok(Json(fetch_learner_detail(&state, &learner_id).await?))
}

async fn post_plan_assignment(
    State(state): State<Arc<AppState>>,
    Json(request): Json<PlanAssignmentRequest>,
) -> Result<Json<crate::domain::PlanAssignmentResponse>, ApiError> {
    Ok(Json(assign_plan(&state, request).await?))
}

async fn post_record_session(
    Path(session_id): Path<String>,
    State(state): State<Arc<AppState>>,
    Json(request): Json<RecordSessionRequest>,
) -> Result<Json<crate::domain::RecordSessionResponse>, ApiError> {
    Ok(Json(record_session(&state, &session_id, request).await?))
}

async fn post_review_rebuild(
    State(state): State<Arc<AppState>>,
    Json(request): Json<ReviewRebuildRequest>,
) -> Result<Json<crate::domain::ReviewRebuildResponse>, ApiError> {
    Ok(Json(rebuild_review_queue(&state, request.learner_id).await?))
}
