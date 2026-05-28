# Authoring Workflow

Use this workflow whether a human expert is writing curriculum directly or an AI system is drafting changes.

## Gather Inputs First

Before authoring or reviewing a slice, gather:

- this directory
- `content/library/registry.yaml`
- the in-scope pathway directory under `content/library/{subject}/{area}/{pathway}/`
- a filled-in [Curriculum slice brief template](./curriculum-slice-brief-template.md), when available
- explicit constraints about which files may change and which must stay fixed

## Standard Authoring Flow

1. Define the subject, area, learner context, and desired outcome.
2. Review the existing pathway registry and in-scope pathway files before creating anything new.
3. Draft or revise the pathway as the whole route.
4. Draft or revise the skills for the slice.
5. Group those skills into stages that make sense to a parent or coach.
6. Decide what materials are needed for explanation, practice, review, and checking.
7. Write or revise the markdown materials.
8. Assemble or revise one or more playlists.
9. Add or revise entry guidance for age or current readiness.
9. Run the [review checklist](./authoring-rules.md).
10. Run `uv run --with pytest python -m pytest tests/test_pathway_library.py` while iterating on the cleaned tree.
11. Run legacy validation commands only if you changed compatibility files.

These checks should cover the whole in-scope pathway, not only one individual file.

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

1. the exact registry and Markdown files to add or update
2. the exact markdown materials to add or update
3. a short explanation of why the stage and skill boundaries make sense
4. validation notes for cross-references, naming consistency, and reuse choices

The author should produce only the files required for the slice:

- `content/library/registry.yaml`, when subject, area, or pathway registry changes are needed
- `content/library/{subject}/{area}/{pathway}/pathway.md`
- stage, skill, playlist, and material files under that pathway directory

## Repo Validation Commands

Use these from the repo root when you need to validate repository changes:

```bash
uv run --with pytest python -m pytest tests/test_pathway_library.py
make rust-library-validate
make content-validate
uv run python scripts/sync_docs_site_docs.py
cargo test -p catalog --manifest-path rust/Cargo.toml
cargo check -p control_plane --manifest-path rust/Cargo.toml
cd fe/flutter/apps/cornerstone && flutter analyze
```

Use the pathway-library test as the fast structural check for cleaned slices. Use `make rust-library-validate` and `make content-validate` for the broader runtime and docs-sync validation pass.
