# Local Compose Runbook

## Bring Up (Production-Matching Integrated Compose)

```bash
source sourceme_dev
make install-dev
make control-plane-compose-up
```

`deploy/dev/.env.dev` already carries the tracked local defaults.
Create `deploy/dev/.env` only if you need machine-specific overrides.

If tracked Postgres defaults change incompatibly across commits, the repo rotates
`CORNERSTONE_DEV_DATA_REVISION` to start a fresh local data window. Your older
data under prior revisions stays on disk until you delete it manually.

## URLs

- frontend preview: `http://127.0.0.1:8080`
- control plane API and service index: `http://127.0.0.1:8788`

The control-plane port is not the main Flutter UI port. It serves the Rust API,
`/health`, and a small service index at `/`.

`make control-plane-compose-up` builds production-style static previews for the
Flutter app and serves it from the same frontend host. It does not run
live-reload watchers inside compose.

## Bring Up (Live Frontend Mode)

Use this when you want fast frontend iteration with `flutter run` while keeping
the backend stable in Docker.

```bash
source sourceme_dev
make control-plane-live-frontend-up
make frontend-live-run
```

Live frontend mode runs only Postgres and the Rust control plane in Docker.
Flutter runs separately on `http://127.0.0.1:3000` by default.

`make frontend-live-run` passes
`--dart-define=CORNERSTONE_API_BASE_URL=http://127.0.0.1:8788` so API calls go
to the Docker-hosted backend directly.

For production-matching behavior, continue using
`make control-plane-compose-up`.

`make docs-site-dev` still serves the standalone developer-docs site on
`http://127.0.0.1:3001` when you want to work on Docusaurus directly.

## Common Commands

```bash
make control-plane-compose-down
make control-plane-compose-reset
make control-plane-live-frontend-up
make control-plane-live-frontend-down
make frontend-live-run
make rust-test
make frontend-sanity
make docs-site-build
make docs-site-dev
```

`make control-plane-compose-up` validates the integrated Flutter app and control plane.
`make docs-site-dev` serves the standalone developer docs with the repo `docs/` tree included.
