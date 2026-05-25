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

- frontend: `http://127.0.0.1:8080`
- control plane: `http://127.0.0.1:8788`
- docs site: `http://127.0.0.1:3001`

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
