# Authoring Rules

These rules apply whether the work is being done by a human author, subject expert, teacher, contractor, LLM, or AI agent.

## Source Of Truth

- Treat the existing `content/catalog/*.yaml` and `content/materials/**/*.md` files as the source of truth for schema, ids, naming, and established structure.
- Reuse existing objects when that is clearly better than creating duplicates.
- If existing files conflict with this directory, prefer the real repository files and then update the docs if needed.

## Required Vocabulary

Use these curriculum names:

- Subject
- Area
- Stage
- Skill
- Material
- Playlist

Know these runtime names:

- Team
- User
- Learner
- Assignment
- Session
- Evidence
- Progress

Do not reintroduce old aliases such as `capability`, `milestone`, `resource`, `program`, `checkpoint`, or `plan template`.

## Tone And Teaching Stance

- Write in a calm, direct, practice-first tone.
- Sound like an honest adult who wants real improvement, not like a hype system.
- Prefer observable actions, clear checks, and steady repetition.
- Do not use sugary praise, filler encouragement, or theatrical motivation.
- Do not hide weak work behind soft language.

## Curriculum Structure Rules

- Keep ids in `snake_case`.
- Keep subject and area explicit in catalog objects.
- Track learner progress at the skill level, not at the material level.
- Use stages to group related skills in parent-facing language.
- Use materials as reusable teaching or practice artifacts.
- Use playlists as ordered session plans that reference real materials.
- Keep material files under `content/materials/{subject_id}/{area_id}/...` so the tree stays intuitive to browse.
- Do not hide curriculum structure inside playlists.
- Do not invent compatibility aliases or parallel schema.
- Do not add placeholder materials that will never be used.

## Material Quality Rules

- Materials should be usable in a real session by a parent, teacher, or coach.
- Prefer concrete prompts, examples, checks, and adaptations over abstract guidance.
- Write for repeatable use, not for a one-time demo activity.
- Keep markdown material frontmatter aligned with the corresponding `materials.yaml` entry.
- Make review and recap deliberate when the slice needs them; do not leave reinforcement to chance.

## Validation Rules

- Every active subject and area must have downstream curriculum, not just top-level placeholder entries.
- Every skill must appear in at least one stage, one material, and one playlist session.
- Every stage must be used by at least one material and one playlist.
- Every indexed material must be used by at least one playlist session.
- Every markdown file under `content/materials/` must be indexed in `content/catalog/materials.yaml`.
- Session materials must match the session skills and stay within the playlist's subject, area, and stages.

## Validation Commands

- Run `make rust-catalog-validate` while you are iterating on structure, ids, and references.
- Run `make content-validate` before you consider authored content complete. This runs the catalog validator and the docs render tests together.
- Validate the full content set after any slice change. The current checks are cross-reference checks, not slice-scoped checks.

## Review Checklist

Before accepting authored output, check that:

1. every referenced `skill_id` exists
2. every referenced `stage_id` exists
3. every playlist references real materials
4. every material frontmatter matches the corresponding `materials.yaml` entry
5. subject and area ids are consistent across the whole slice
6. every skill, stage, and material has downstream usage and no orphan remains
7. there is no stray markdown under `content/materials/`
8. no duplicate object exists for the same teaching job
9. all explicit constraints from the brief are respected