# Local Compose Runbook

## Bring Up

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
- content site: `http://127.0.0.1:8080/content/`

The control-plane port is not the main Flutter UI port. It serves the Rust API,
`/health`, and a small service index at `/`.

`make control-plane-compose-up` builds production-style static previews for the
Flutter app and generated content site, then serves them from the same frontend
host. It does not run live-reload watchers inside compose.

`make docs-site-dev` still serves the standalone developer-flavor content/docs
site on `http://127.0.0.1:3001` when you want to work on Docusaurus directly.

## Common Commands

```bash
make control-plane-compose-down
make control-plane-compose-reset
make rust-test
make frontend-sanity
make docs-site-build
make docs-site-dev
```

`make control-plane-compose-up` serves the production docs flavor.
`make docs-site-dev` serves the developer docs flavor with the repo `docs/` tree included.
