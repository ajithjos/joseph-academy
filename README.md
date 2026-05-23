# Joseph Academy

Joseph Academy is a learning control plane for a small household-sized learning team.

This repository now contains an MVP stack with:

- a Rust control-plane API backed by Postgres
- a Flutter web frontend for owner and learner workflows
- a Docusaurus catalog site generated from repo-owned curriculum files
- Docker-based dev and VM-oriented deployment templates

## Quickstart

```bash
source sourceme_dev
make install-dev
make control-plane-compose-up
```

Default local URLs:

- frontend: `http://127.0.0.1:8080`
- control plane: `http://127.0.0.1:8788`
- catalog docs: `http://127.0.0.1:3001`

## Repo Shape

- `content/`: file-owned curriculum catalogs, bootstrap identities, and content items
- `rust/`: Rust control-plane workspace
- `fe/flutter/apps/joseph_academy/`: Flutter web runtime UI
- `docs_site/`: Docusaurus catalog site
- `deploy/`: dev and production deployment workflows
- `docs/`: product and operator documentation
