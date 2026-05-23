# Local Compose Runbook

## Bring Up

```bash
source sourceme_dev
make install-dev
make control-plane-compose-up
```

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
```
