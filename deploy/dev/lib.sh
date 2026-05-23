#!/usr/bin/env bash

set -euo pipefail

deploy_repo_root() {
	cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd
}

deploy_source_env_file() {
	local file="$1"
	[[ -f "$file" ]] || return 0
	set -a
	# shellcheck disable=SC1090
	. "$file"
	set +a
}

deploy_require_cmd() {
	local cmd="$1"
	command -v "$cmd" >/dev/null 2>&1 || {
		echo "[deploy/dev] ERROR: required command not found: $cmd" >&2
		exit 2
	}
}

deploy_check_docker_prereqs() {
	deploy_require_cmd docker
	docker compose version >/dev/null 2>&1 || {
		echo "[deploy/dev] ERROR: docker compose is required." >&2
		exit 2
	}
	docker info >/dev/null 2>&1 || {
		echo "[deploy/dev] ERROR: docker daemon is not reachable." >&2
		exit 2
	}
}

deploy_resolve_tokens() {
	local value="$1"
	value="${value//__REPO_ROOT__/$DEPLOY_REPO_ROOT}"
	value="${value//__HOME__/$HOME}"
	value="${value//__JOSEPH_DEV_LOCAL_ROOT__/$JOSEPH_DEV_LOCAL_ROOT}"
	value="${value//__JOSEPH_DEV_DATA_REVISION__/$JOSEPH_DEV_DATA_REVISION}"
	printf '%s' "$value"
}

deploy_dev_init() {
	DEPLOY_REPO_ROOT="$(deploy_repo_root)"
	DEPLOY_DEV_DIR="$DEPLOY_REPO_ROOT/deploy/dev"
	DEPLOY_IMAGE_CONFIG_FILE="$DEPLOY_REPO_ROOT/deploy/config/build/images.lock.env"
	DEPLOY_DEV_DEFAULT_ENV="$DEPLOY_DEV_DIR/.env.dev"
	DEPLOY_DEV_LOCAL_ENV="$DEPLOY_DEV_DIR/.env"
	DEPLOY_DEV_COMPOSE_FILE="$DEPLOY_DEV_DIR/docker-compose.yml"
}

deploy_dev_load_config() {
	deploy_source_env_file "$DEPLOY_IMAGE_CONFIG_FILE"
	deploy_source_env_file "$DEPLOY_DEV_DEFAULT_ENV"
	deploy_source_env_file "$DEPLOY_DEV_LOCAL_ENV"

	JOSEPH_DEV_LOCAL_ROOT="$(deploy_resolve_tokens "${JOSEPH_DEV_LOCAL_ROOT}")"
	JOSEPH_DEV_DATA_REVISION="${JOSEPH_DEV_DATA_REVISION}"
	JOSEPH_WORKSPACE_HOST="$(deploy_resolve_tokens "${JOSEPH_WORKSPACE_HOST}")"
	JOSEPH_POSTGRES_DATA_HOST="$(deploy_resolve_tokens "${JOSEPH_POSTGRES_DATA_HOST}")"
	JOSEPH_ARTIFACTS_HOST="$(deploy_resolve_tokens "${JOSEPH_ARTIFACTS_HOST}")"
	JOSEPH_EXPORTS_HOST="$(deploy_resolve_tokens "${JOSEPH_EXPORTS_HOST}")"

	JOSEPH_FRONTEND_BUILD_HOST="$DEPLOY_REPO_ROOT/fe/flutter/apps/joseph_academy/build/web"
	JOSEPH_DOCS_BUILD_HOST="$DEPLOY_REPO_ROOT/docs_site/build"
	JOSEPH_ACADEMY_DATABASE_URL="postgres://${JOSEPH_POSTGRES_APP_USER}:${JOSEPH_POSTGRES_APP_PASSWORD}@postgres:5432/${JOSEPH_POSTGRES_DB}"
	JOSEPH_HOST_DATABASE_URL="postgres://${JOSEPH_POSTGRES_APP_USER}:${JOSEPH_POSTGRES_APP_PASSWORD}@127.0.0.1:${JOSEPH_POSTGRES_PORT}/${JOSEPH_POSTGRES_DB}"

	export JOSEPH_DEV_COMPOSE_PROJECT_NAME
	export JOSEPH_WORKSPACE_HOST
	export JOSEPH_POSTGRES_PORT
	export JOSEPH_CONTROL_PLANE_PORT
	export JOSEPH_FRONTEND_PORT
	export JOSEPH_DOCS_SITE_PORT
	export JOSEPH_POSTGRES_DB
	export JOSEPH_POSTGRES_ADMIN_USER
	export JOSEPH_POSTGRES_ADMIN_PASSWORD
	export JOSEPH_POSTGRES_APP_USER
	export JOSEPH_POSTGRES_APP_PASSWORD
	export JOSEPH_POSTGRES_DATA_HOST
	export JOSEPH_ARTIFACTS_HOST
	export JOSEPH_EXPORTS_HOST
	export JOSEPH_FRONTEND_BUILD_HOST
	export JOSEPH_DOCS_BUILD_HOST
	export JOSEPH_ACADEMY_DATABASE_URL
	export JOSEPH_POSTGRES_IMAGE
	export JOSEPH_RUST_IMAGE
	export JOSEPH_RUNTIME_IMAGE
	export JOSEPH_NGINX_IMAGE
	export JOSEPH_COMPOSE_WAIT_TIMEOUT
}

deploy_dev_ensure_dirs() {
	mkdir -p \
		"$JOSEPH_POSTGRES_DATA_HOST" \
		"$JOSEPH_ARTIFACTS_HOST" \
		"$JOSEPH_EXPORTS_HOST"
}

deploy_dev_prepare_static_artifacts() {
	echo "[deploy/dev] Rendering catalog docs..."
	(
		cd "$DEPLOY_REPO_ROOT" || exit 1
		uv run python scripts/render_catalog_docs.py
	)

	echo "[deploy/dev] Building Docusaurus site..."
	(
		cd "$DEPLOY_REPO_ROOT/docs_site" || exit 1
		npm install
		npm run build
	)

	echo "[deploy/dev] Building Flutter web app..."
	(
		cd "$DEPLOY_REPO_ROOT/fe/flutter/apps/joseph_academy" || exit 1
		flutter pub get
		flutter build web --release --dart-define=JOSEPH_ACADEMY_API_BASE_URL="http://127.0.0.1:${JOSEPH_CONTROL_PLANE_PORT}"
	)
}
