# Cornerstone

Cornerstone is a learning control plane for a small household-sized learning team.

This repository now contains an MVP stack with:

- a Rust control-plane API backed by Postgres
- a Flutter web frontend for owner and learner workflows
- a Docusaurus catalog site generated from repo-owned curriculum files
- Docker-based dev and VM-oriented deployment templates

Identity bootstrap lives under `deploy/config/runtime_defaults/identity_bootstrap.yaml`.
Curriculum content stays under `content/`.

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

Use `make docs-site-dev` when you want the developer-flavor docs site that also mirrors the repo `docs/` tree.

## Repo Shape

- `content/`: file-owned curriculum catalogs and content items
- `rust/`: Rust control-plane workspace
- `fe/flutter/apps/cornerstone/`: Flutter web runtime UI
- `docs_site/`: Docusaurus catalog site
- `deploy/`: dev and production deployment workflows
- `docs/`: product and operator documentation
