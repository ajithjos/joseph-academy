# Repeatable Prompts

These prompts are written for the final Cornerstone model: subject, area, stage, skill, material, playlist.

## Prompt 1: Map One Subject Area

I am defining one Cornerstone curriculum slice.

Please return:

- the subject
- the area
- 2 to 5 candidate stages
- the skills that belong inside each stage
- a short explanation of why those stage and skill boundaries are useful

Keep the model small and practical. Do not use old aliases such as capability, milestone, resource, or plan template.

## Prompt 2: Draft Catalog Entries

I already know the subject, area, stages, and skills for this slice.

Please draft repo-ready YAML entries for:

- `skills.yaml`
- `stages.yaml`
- `materials.yaml`
- `playlists.yaml`

Keep ids in `snake_case`. Keep subject and area explicit in every entry. Only reference ids that exist in the input I provide.

## Prompt 3: Write One Material

I am creating one Cornerstone material file.

Please write one markdown file under `content/materials/{subject}/...` with:

- valid YAML frontmatter
- a short, usable learning artifact body
- language suitable for parent-led delivery

The file must align with the provided `skill_ids`, `stage_ids`, and material index entry.

## Prompt 4: Review A Curriculum Slice

I will paste the current skills, stages, materials, playlists, and one or more markdown files below.

Please review them for:

- duplicate or weak skill boundaries
- stages that are too broad or too small
- materials that do not clearly support the named skills
- playlists that reference the wrong materials or hide curriculum structure
- id or cross-reference problems

Return exact fixes, not just general advice.
