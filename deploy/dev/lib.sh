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
	value="${value//__CORNERSTONE_DEV_LOCAL_ROOT__/$CORNERSTONE_DEV_LOCAL_ROOT}"
	value="${value//__CORNERSTONE_DEV_DATA_REVISION__/$CORNERSTONE_DEV_DATA_REVISION}"
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

	CORNERSTONE_DEV_LOCAL_ROOT="$(deploy_resolve_tokens "${CORNERSTONE_DEV_LOCAL_ROOT}")"
	CORNERSTONE_DEV_DATA_REVISION="${CORNERSTONE_DEV_DATA_REVISION}"
	CORNERSTONE_WORKSPACE_HOST="$(deploy_resolve_tokens "${CORNERSTONE_WORKSPACE_HOST}")"
	CORNERSTONE_POSTGRES_DATA_HOST="$(deploy_resolve_tokens "${CORNERSTONE_POSTGRES_DATA_HOST}")"
	CORNERSTONE_ARTIFACTS_HOST="$(deploy_resolve_tokens "${CORNERSTONE_ARTIFACTS_HOST}")"
	CORNERSTONE_EXPORTS_HOST="$(deploy_resolve_tokens "${CORNERSTONE_EXPORTS_HOST}")"

	CORNERSTONE_FRONTEND_BUILD_HOST="$DEPLOY_REPO_ROOT/fe/flutter/apps/cornerstone/build/web"
	CORNERSTONE_DOCS_BUILD_HOST="$DEPLOY_REPO_ROOT/docs_site/build/production"
	CORNERSTONE_DATABASE_URL="postgres://${CORNERSTONE_POSTGRES_APP_USER}:${CORNERSTONE_POSTGRES_APP_PASSWORD}@postgres:5432/${CORNERSTONE_POSTGRES_DB}"
	CORNERSTONE_HOST_DATABASE_URL="postgres://${CORNERSTONE_POSTGRES_APP_USER}:${CORNERSTONE_POSTGRES_APP_PASSWORD}@127.0.0.1:${CORNERSTONE_POSTGRES_PORT}/${CORNERSTONE_POSTGRES_DB}"

	export CORNERSTONE_DEV_COMPOSE_PROJECT_NAME
	export CORNERSTONE_WORKSPACE_HOST
	export CORNERSTONE_POSTGRES_PORT
	export CORNERSTONE_CONTROL_PLANE_PORT
	export CORNERSTONE_FRONTEND_PORT
	export CORNERSTONE_DOCS_SITE_PORT
	export CORNERSTONE_POSTGRES_DB
	export CORNERSTONE_POSTGRES_ADMIN_USER
	export CORNERSTONE_POSTGRES_ADMIN_PASSWORD
	export CORNERSTONE_POSTGRES_APP_USER
	export CORNERSTONE_POSTGRES_APP_PASSWORD
	export CORNERSTONE_POSTGRES_DATA_HOST
	export CORNERSTONE_ARTIFACTS_HOST
	export CORNERSTONE_EXPORTS_HOST
	export CORNERSTONE_FRONTEND_BUILD_HOST
	export CORNERSTONE_DOCS_BUILD_HOST
	export CORNERSTONE_DATABASE_URL
	export CORNERSTONE_POSTGRES_IMAGE
	export CORNERSTONE_RUST_IMAGE
	export CORNERSTONE_RUNTIME_IMAGE
	export CORNERSTONE_NGINX_IMAGE
	export CORNERSTONE_COMPOSE_WAIT_TIMEOUT
}

deploy_dev_ensure_dirs() {
	mkdir -p \
		"$CORNERSTONE_POSTGRES_DATA_HOST" \
		"$CORNERSTONE_ARTIFACTS_HOST" \
		"$CORNERSTONE_EXPORTS_HOST"
}

deploy_dev_prepare_static_artifacts() {
	local flutter_build_dir="$DEPLOY_REPO_ROOT/fe/flutter/apps/cornerstone/build/web"
	local embedded_content_dir="$flutter_build_dir/content"

	echo "[deploy/dev] Rendering catalog docs..."
	(
		cd "$DEPLOY_REPO_ROOT" || exit 1
		uv run python scripts/render_catalog_docs.py
	)

	echo "[deploy/dev] Building Docusaurus site..."
	(
		cd "$DEPLOY_REPO_ROOT/docs_site" || exit 1
		npm install
		npm run build:production
	)

	echo "[deploy/dev] Building Flutter web app..."
	(
		cd "$DEPLOY_REPO_ROOT/fe/flutter/apps/cornerstone" || exit 1
		flutter pub get
		flutter build web --release --pwa-strategy=none
	)

	echo "[deploy/dev] Embedding content site under the frontend build..."
	rm -rf "$embedded_content_dir"
	mkdir -p "$embedded_content_dir"
	cp -R "$DEPLOY_REPO_ROOT/docs_site/build/production/." "$embedded_content_dir/"
}
