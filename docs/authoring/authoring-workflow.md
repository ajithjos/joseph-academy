# Authoring Workflow

Use this workflow whether a human expert is writing curriculum directly or an AI system is drafting changes.

## Gather Inputs First

Before authoring or reviewing a slice, gather:

- this directory
- the in-scope `content/catalog/*.yaml` files
- the in-scope `content/materials/**/*.md` files
- a filled-in [Curriculum slice brief template](./curriculum-slice-brief-template.md), when available
- explicit constraints about which files may change and which must stay fixed

## Standard Authoring Flow

1. Define the subject, area, learner context, and desired outcome.
2. Review existing ids, stages, skills, materials, and playlists before creating anything new.
3. Draft or revise the skills for the slice.
4. Group those skills into stages that make sense to a parent or coach.
5. Decide what materials are needed for explanation, practice, review, and checking.
6. Write or revise the markdown materials.
7. Update the catalog YAML entries.
8. Assemble or revise one or more playlists.
9. Run the [review checklist](./authoring-rules.md).
10. Run `make rust-catalog-validate` while iterating if you changed structure, references, or material files.
11. Run `make content-validate` before finishing the work.

These checks run against the full content set, not only the touched slice. That is deliberate: orphan detection and cross-reference failures usually show up only when the whole catalog is checked together.

## How To Brief The Author

State the request plainly. Say:

- whether you want generation, revision, or review
- which subject and area are in scope
- which files may change
- which files must stay fixed
- any tone, classroom, family, or accessibility constraints
- whether you want exact file edits or only a proposed plan

If essential slice facts are missing, ask only for those missing facts.

## Expected Deliverables

Good output should include:

1. the exact YAML entries to add or update
2. the exact markdown materials to add or update
3. a short explanation of why the stage and skill boundaries make sense
4. validation notes for cross-references, naming consistency, and reuse choices

The author should produce only the files required for the slice:

- `content/catalog/skills.yaml`
- `content/catalog/stages.yaml`
- `content/catalog/materials.yaml`
- `content/catalog/playlists.yaml`
- one or more markdown files under `content/materials/{subject}/...`

If the subject or area is new, the work may also need updates to:

- `content/catalog/subjects.yaml`
- `content/catalog/areas.yaml`

## Repo Validation Commands

Use these from the repo root when you need to validate repository changes:

```bash
make rust-catalog-validate
make content-validate
uv run python scripts/render_catalog_docs.py developer
cargo test -p catalog --manifest-path rust/Cargo.toml
cargo check -p control_plane --manifest-path rust/Cargo.toml
cd fe/flutter/apps/cornerstone && flutter analyze
```

Use `make rust-catalog-validate` as the fast structural check. Use `make content-validate` as the normal completion check for newly authored or revised content.
