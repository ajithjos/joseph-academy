#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/lib.sh"

deploy_dev_init
deploy_dev_load_config
deploy_check_docker_prereqs

echo "WARNING: this will stop the Joseph Academy compose stack and delete local Postgres data under $JOSEPH_POSTGRES_DATA_HOST."
printf "Type RESET-JOSEPH-ACADEMY to continue: "
IFS= read -r confirmation
echo

if [[ "$confirmation" != "RESET-JOSEPH-ACADEMY" ]]; then
	echo "Aborted."
	exit 1
fi

docker compose -f "$DEPLOY_DEV_COMPOSE_FILE" down --remove-orphans

[[ -n "$JOSEPH_POSTGRES_DATA_HOST" && "$JOSEPH_POSTGRES_DATA_HOST" != "/" ]] || {
	echo "[deploy/dev] ERROR: refusing to delete invalid Postgres path '$JOSEPH_POSTGRES_DATA_HOST'" >&2
	exit 2
}

mkdir -p "$JOSEPH_POSTGRES_DATA_HOST"
find "$JOSEPH_POSTGRES_DATA_HOST" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
echo "[deploy/dev] Postgres data deleted. Artifact and export directories were left intact."
