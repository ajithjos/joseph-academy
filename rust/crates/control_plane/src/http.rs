use std::sync::Arc;

use anyhow::{Error, anyhow};
use axum::extract::{Path, Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

use catalog::LibraryBundle;

use crate::domain::{
    ActivityStartResponse, AssignmentRequest, CompleteActivityRequest,
    CompleteActivityResponse, LibraryDocumentResponse, LibraryDocumentsResponse,
    LibraryReloadResponse, OperationStatusResponse, RecordSessionRequest,
    ReviewRebuildRequest, ViewerLoginRequest, ViewerSessionResponse,
};
use crate::service::{
    AppState, apply_bootstrap, complete_activity_instance, create_assignment,
    fetch_dashboard, fetch_learner_detail, fetch_learner_workspace, fetch_library,
    fetch_library_document, fetch_library_workspace, fetch_viewer_session,
    list_learners, list_library_documents, login_viewer_session,
    rebuild_review_items, record_session, reload_library,
    start_session_material_activity,
};

const VIEWER_USERNAME_HEADER: &str = "x-cornerstone-viewer";

#[derive(Debug)]
pub struct ApiError(pub Error);

#[derive(Debug, Clone, Serialize)]
struct ErrorPayload {
    status: String,
    message: String,
}

#[derive(Debug, Clone, Serialize)]
struct LibraryPayload {
    report: LibraryReloadResponse,
    bundle: LibraryBundle,
}

#[derive(Debug, Clone, Serialize)]
struct ServiceIndexResponse {
    status: String,
    service: String,
    message: String,
    health_url: String,
    api_base_url: String,
    frontend_url: String,
    frontend_preview_mode: String,
    docs_dev_command: String,
}

#[derive(Debug, Default, Deserialize)]
struct ViewerSessionQuery {
    username: Option<String>,
}

#[derive(Debug, Default, Deserialize)]
struct LibraryDocumentQuery {
    route_path: String,
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

fn viewer_username_from_headers(headers: &HeaderMap) -> Result<String, ApiError> {
    let raw_value = headers
        .get(VIEWER_USERNAME_HEADER)
        .ok_or_else(|| ApiError(anyhow!("{VIEWER_USERNAME_HEADER} header is required")))?;
    let username = raw_value
        .to_str()
        .map_err(|_| ApiError(anyhow!("{VIEWER_USERNAME_HEADER} header must be valid UTF-8")))?
        .trim()
        .to_string();
    if username.is_empty() {
        return Err(ApiError(anyhow!(
            "{VIEWER_USERNAME_HEADER} header cannot be empty"
        )));
    }
    Ok(username)
}

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/", get(index))
        .route("/health", get(health))
        .route("/api/v1/library", get(get_library))
        .route("/api/v1/library/workspace", get(get_library_workspace))
        .route("/api/v1/library/reload", post(post_library_reload))
        .route("/api/v1/library/documents", get(get_library_documents))
        .route("/api/v1/library/document", get(get_library_document))
        .route("/api/v1/bootstrap/apply", post(post_bootstrap_apply))
        .route(
            "/api/v1/session",
            get(get_viewer_session)
                .post(post_viewer_session)
                .delete(delete_viewer_session),
        )
        .route("/api/v1/dashboard", get(get_dashboard))
        .route("/api/v1/learners", get(get_learners))
        .route("/api/v1/learners/{learner_id}", get(get_learner_detail))
        .route(
            "/api/v1/learners/{learner_id}/workspace",
            get(get_learner_workspace),
        )
        .route("/api/v1/assignments", post(post_assignment))
        .route("/api/v1/sessions/{session_id}/record", post(post_record_session))
        .route(
            "/api/v1/sessions/{session_id}/materials/{session_material_id}/start",
            post(post_start_session_material_activity),
        )
        .route(
            "/api/v1/activity-instances/{activity_instance_id}/complete",
            post(post_complete_activity_instance),
        )
        .route("/api/v1/review-items/rebuild", post(post_review_rebuild))
        .with_state(state)
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
}

async fn index(State(state): State<Arc<AppState>>) -> Json<ServiceIndexResponse> {
    Json(ServiceIndexResponse {
        status: "ok".to_string(),
        service: "cornerstone control plane".to_string(),
        message: "This port serves the control-plane API and service index for the Flutter app. Developer docs remain available through the standalone docs-site workflow.".to_string(),
        health_url: "/health".to_string(),
        api_base_url: "/api/v1".to_string(),
        frontend_url: state.config.frontend_public_url.clone(),
        frontend_preview_mode: "static-build".to_string(),
        docs_dev_command: "make docs-site-dev".to_string(),
    })
}

async fn health() -> Json<OperationStatusResponse> {
    Json(OperationStatusResponse {
        status: "ok".to_string(),
        message: "cornerstone control plane is healthy".to_string(),
    })
}

async fn get_library(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<LibraryPayload>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    let (bundle, report) = fetch_library(&state, &viewer_username).await?;
    Ok(Json(LibraryPayload { report, bundle }))
}

async fn get_library_workspace(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<crate::domain::LibraryWorkspaceResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(fetch_library_workspace(&state, &viewer_username).await?))
}

async fn post_library_reload(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<LibraryReloadResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(reload_library(&state, &viewer_username).await?))
}

async fn get_library_documents(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<LibraryDocumentsResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(LibraryDocumentsResponse {
        status: "ok".to_string(),
        documents: list_library_documents(&state, &viewer_username).await?,
    }))
}

async fn get_library_document(
    Query(query): Query<LibraryDocumentQuery>,
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<LibraryDocumentResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(LibraryDocumentResponse {
        status: "ok".to_string(),
        document: fetch_library_document(&state, &viewer_username, &query.route_path).await?,
    }))
}

async fn post_bootstrap_apply(
    State(state): State<Arc<AppState>>,
) -> Result<Json<crate::domain::BootstrapApplyResponse>, ApiError> {
    Ok(Json(apply_bootstrap(&state).await?))
}

async fn get_viewer_session(
    Query(query): Query<ViewerSessionQuery>,
    State(state): State<Arc<AppState>>,
) -> Result<Json<ViewerSessionResponse>, ApiError> {
    Ok(Json(fetch_viewer_session(&state, query.username.as_deref()).await?))
}

async fn post_viewer_session(
    State(state): State<Arc<AppState>>,
    Json(request): Json<ViewerLoginRequest>,
) -> Result<Json<ViewerSessionResponse>, ApiError> {
    Ok(Json(login_viewer_session(&state, &request.username).await?))
}

async fn delete_viewer_session() -> Json<OperationStatusResponse> {
    Json(OperationStatusResponse {
        status: "ok".to_string(),
        message: "logged out".to_string(),
    })
}

async fn get_dashboard(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<crate::domain::DashboardResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(fetch_dashboard(&state, &viewer_username).await?))
}

async fn get_learners(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<crate::domain::LearnerSummary>>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(list_learners(&state, &viewer_username).await?))
}

async fn get_learner_detail(
    Path(learner_id): Path<String>,
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<crate::domain::LearnerDetailResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(fetch_learner_detail(&state, &viewer_username, &learner_id).await?))
}

async fn get_learner_workspace(
    Path(learner_id): Path<String>,
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<crate::domain::LearnerWorkspaceResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(
        fetch_learner_workspace(&state, &viewer_username, &learner_id).await?,
    ))
}

async fn post_assignment(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
    Json(request): Json<AssignmentRequest>,
) -> Result<Json<crate::domain::AssignmentResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(create_assignment(&state, &viewer_username, request).await?))
}

async fn post_record_session(
    Path(session_id): Path<String>,
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
    Json(request): Json<RecordSessionRequest>,
) -> Result<Json<crate::domain::RecordSessionResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(
        record_session(&state, &viewer_username, &session_id, request).await?,
    ))
}

async fn post_start_session_material_activity(
    Path((session_id, session_material_id)): Path<(String, String)>,
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
) -> Result<Json<ActivityStartResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(
        start_session_material_activity(
            &state,
            &viewer_username,
            &session_id,
            &session_material_id,
        )
        .await?,
    ))
}

async fn post_complete_activity_instance(
    Path(activity_instance_id): Path<String>,
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
    Json(request): Json<CompleteActivityRequest>,
) -> Result<Json<CompleteActivityResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(
        complete_activity_instance(&state, &viewer_username, &activity_instance_id, request)
            .await?,
    ))
}

async fn post_review_rebuild(
    headers: HeaderMap,
    State(state): State<Arc<AppState>>,
    Json(request): Json<ReviewRebuildRequest>,
) -> Result<Json<crate::domain::ReviewRebuildResponse>, ApiError> {
    let viewer_username = viewer_username_from_headers(&headers)?;
    Ok(Json(
        rebuild_review_items(&state, &viewer_username, request.learner_id).await?,
    ))
}
