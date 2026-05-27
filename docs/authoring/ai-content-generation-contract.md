# AI Content Generation Contract

Use this contract when generating Cornerstone curriculum files by hand or with an LLM.

## Scope

This contract is for file-owned curriculum only.

It covers:

- subjects
- areas
- skills
- stages
- materials
- playlists

It does not cover learner runtime state such as assignments, sessions, evidence, or progress.

## Canonical File Map

- `content/catalog/subjects.yaml`
- `content/catalog/areas.yaml`
- `content/catalog/skills.yaml`
- `content/catalog/stages.yaml`
- `content/catalog/materials.yaml`
- `content/catalog/playlists.yaml`
- `content/materials/**/*.md`

## Canonical Object Rules

- Subject and area must be explicit everywhere.
- Skills are the smallest tracked progress unit.
- Stages group related skills into parent-facing slices.
- Materials support real skills and real stages.
- Playlists reference real materials and real skills.

## Required Field Shapes

### `skills.yaml`

Each skill entry must include:

- `skill_id`
- `subject_id`
- `area_id`
- `title`
- `recommended_age`
- `recommended_level`
- `description`
- `success_criteria`

### `stages.yaml`

Each stage entry must include:

- `stage_id`
- `subject_id`
- `area_id`
- `title`
- `recommended_age`
- `recommended_level`
- `description`
- `skill_ids`

### `materials.yaml`

Each material index entry must include:

- `material_id`
- `path`
- `type`
- `subject_id`
- `area_id`
- `skill_ids`
- `stage_ids`
- `recommended_age`
- `difficulty`
- `estimated_minutes`

### Material markdown frontmatter

Each markdown material must include:

- `id`
- `type`
- `subject_id`
- `area_id`
- `skill_ids`
- `stage_ids`
- `recommended_age`
- `difficulty`
- `estimated_minutes`

The frontmatter must match the corresponding `materials.yaml` entry.

### `playlists.yaml`

Each playlist entry must include:

- `playlist_id`
- `title`
- `subject_id`
- `area_id`
- `recommended_age`
- `recommended_level`
- `stage_ids`
- `skill_ids`
- `duration_days`
- `session_pattern`

Each session in `session_pattern.sessions` must include:

- `day_offset`
- `title`
- `skill_ids`
- `material_ids`

## Writing Rules

- Use plain, direct language for young learners and their adults.
- Prefer fewer, stronger skills over many tiny skills.
- Prefer fewer, meaningful stages over many weak stages.
- Do not generate placeholder materials.
- Do not invent file names or ids that are not used.
- Do not reintroduce old aliases such as `capability`, `milestone`, `resource`, or `plan template`.

## Validation Checklist

Before accepting generated output, confirm that:

1. every referenced subject exists
2. every referenced area exists
3. every referenced skill exists
4. every referenced stage exists
5. every referenced material exists
6. every material path exists under `content/materials/`
7. playlist sessions only reference material ids that are present in `materials.yaml`
