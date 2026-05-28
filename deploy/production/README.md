# Production Template

The production shape is intentionally VM-friendly and close to the dev compose flow.

## Expected Host Workflow

1. Check out the repository on the VM.
2. Build the static artifacts on the host:
   - `uv run python scripts/render_library_docs.py production`
   - `cd docs_site && npm install && npm run build:production`
   - `cd fe/flutter/apps/cornerstone && flutter pub get && flutter build web --release --dart-define=CORNERSTONE_API_BASE_URL=http://YOUR_VM_IP:8788`
3. Copy `deploy/production/templates/.env.template` to `.env` and set the host paths and passwords.
4. Run `docker compose -f deploy/production/templates/docker-compose.yml up -d --build`

## What This Ships

- Postgres
- Rust control plane
- static Flutter web build served by nginx
- static Docusaurus library build served by nginx
