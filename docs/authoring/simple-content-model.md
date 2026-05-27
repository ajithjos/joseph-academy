# Simple Content Model

If you are authoring curriculum in Cornerstone, think in this order:

1. Subject
2. Area
3. Stage
4. Skill
5. Material
6. Playlist

That is the smallest model that still supports planning, delivery, and learner progress.

## Subject

A subject is the top-level domain such as maths or english.

Use a subject when you need a stable top navigation or reporting boundary.

## Area

An area is a coherent slice inside a subject.

Examples:

- maths -> arithmetic
- english -> reading

Use areas to keep authoring and browse surfaces manageable.

## Stage

A stage is a parent-facing grouping of skills.

Good stages answer questions like:

- What broad slice of work is this learner in?
- What should a parent or coach expect to see next?
- Which related skills belong together for review?

## Skill

A skill is the smallest unit we track in learner progress.

Good skills are specific enough to practise, assess, and revisit.

## Material

A material is one reusable artifact such as a worksheet, reading passage, prompt sheet, teaching note, or drill card.

Each material should point back to real `skill_ids` and `stage_ids`.

## Playlist

A playlist is an ordered set of sessions that references real materials.

Use playlists for repeatable delivery. Do not hide stage or skill structure inside them.

## File Map

- `subjects.yaml` stores subjects.
- `areas.yaml` stores areas.
- `skills.yaml` stores skills.
- `stages.yaml` stores stages.
- `materials.yaml` indexes materials.
- `playlists.yaml` stores playlists.
- `content/materials/**/*.md` stores the actual material bodies.

## Recommended Authoring Order

1. Fill in the [Subject-Area brief template](./subject-area-brief-template.md).
2. Draft the skills for one area.
3. Group those skills into stages.
4. Write the real materials.
5. Index the materials in `materials.yaml`.
6. Assemble one or more playlists.

## Sizing Guidance

- Start with one subject and one area at a time.
- A stage should be meaningful to a parent, not just to the database.
- A skill should be small enough to practise repeatedly.
- A material should be reusable in more than one playlist when practical.
- A playlist should be short enough to assign confidently and easy to replace if it is not working.

## Naming Rules

- Use the final names everywhere: subject, area, stage, skill, material, playlist.
- Do not reintroduce `capability`, `milestone`, `resource`, or `plan template`.

## Next Docs

- [Subject-Area brief template](./subject-area-brief-template.md)
- [Curriculum authoring brief](./track-authoring-brief.md)
- [AI content generation contract](./ai-content-generation-contract.md)
- [Repeatable prompts](./repeatable-prompts.md)
