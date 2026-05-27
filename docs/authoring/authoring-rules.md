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
- Do not hide curriculum structure inside playlists.
- Do not invent compatibility aliases or parallel schema.
- Do not add placeholder materials that will never be used.

## Material Quality Rules

- Materials should be usable in a real session by a parent, teacher, or coach.
- Prefer concrete prompts, examples, checks, and adaptations over abstract guidance.
- Write for repeatable use, not for a one-time demo activity.
- Keep markdown material frontmatter aligned with the corresponding `materials.yaml` entry.
- Make review and recap deliberate when the slice needs them; do not leave reinforcement to chance.

## Review Checklist

Before accepting authored output, check that:

1. every referenced `skill_id` exists
2. every referenced `stage_id` exists
3. every playlist references real materials
4. every material frontmatter matches the corresponding `materials.yaml` entry
5. subject and area ids are consistent across the whole slice
6. no duplicate object exists for the same teaching job
7. all explicit constraints from the brief are respected