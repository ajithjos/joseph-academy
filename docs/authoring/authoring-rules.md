# Authoring Rules

These rules apply whether the work is being done by a human author, subject expert, teacher, contractor, LLM, or AI agent.

## Source Of Truth

- Treat `content/library/registry.yaml` and pathway-contained files under `content/library/{subject}/{area}/{pathway}/` as the source of truth for cleaned curriculum slices.
- Reuse existing objects when that is clearly better than creating duplicates.
- Legacy `content/catalog/` and `content/materials/` remain compatibility inputs until runtime migration. Do not design new slices around that older split.

## Required Vocabulary

Use these curriculum names:

- Subject
- Area
- Pathway
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
- Keep subject and area explicit in the registry and pathway frontmatter.
- Track learner progress at the skill level, not at the material level.
- Use pathway as the contained authoring boundary for one whole route.
- Use stages to group related skills in parent-facing language.
- Use stages for learning progression, not for age bands.
- Use materials as reusable teaching or practice artifacts.
- Use playlists as ordered session plans that reference real materials.
- Keep stage, skill, playlist, and material files inside `content/library/{subject_id}/{area_id}/{pathway_id}/`.
- Do not hide curriculum structure inside playlists.
- Do not invent compatibility aliases or parallel schema.
- Do not add a separate pathway YAML file unless the metadata truly no longer fits the pathway document.
- Do not add placeholder materials that will never be used.

## Material Quality Rules

- Materials should be usable in a real session by a parent, teacher, or coach.
- Prefer concrete prompts, examples, checks, and adaptations over abstract guidance.
- Write for repeatable use, not for a one-time demo activity.
- Keep material metadata in the material file itself. Do not duplicate it in a separate material index.
- Make review and recap deliberate when the slice needs them; do not leave reinforcement to chance.

## Validation Rules

- Every active pathway must contain real downstream curriculum, not just a top-level pathway document.
- Every skill must appear in at least one stage, one material, and one playlist session.
- Every stage must be used by at least one material and one playlist.
- Every material file inside a pathway must be used by at least one playlist session unless it is clearly marked as a reference note in the pathway.
- Session materials must match the session skills and stay within the playlist's pathway and stages.
- Entry guidance must point to real playlists.

## Validation Commands

- Run `uv run --with pytest python -m pytest tests/test_pathway_library.py` while iterating on the cleaned pathway tree.
- Run `make rust-catalog-validate` and `make content-validate` if you also touched the legacy compatibility inputs.
- Validate the full in-scope pathway after any slice change.

## Review Checklist

Before accepting authored output, check that:

1. every referenced `skill_id` exists
2. every referenced `stage_id` exists
3. every playlist references real materials
4. subject, area, and pathway ids are consistent across the whole slice
5. every skill, stage, and material has downstream usage and no orphan remains
6. there is no stray markdown outside the owning pathway directory
7. no duplicate object exists for the same teaching job
8. all explicit constraints from the brief are respected