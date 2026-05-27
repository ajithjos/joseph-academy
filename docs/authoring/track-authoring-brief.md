# Curriculum Authoring Brief

Attach this brief when you want an LLM to turn a subject-area brief into repo-ready curriculum files.

## Attach These Inputs

- [Subject-Area brief template](./subject-area-brief-template.md) filled in for the slice you want
- [Simple content model](./simple-content-model.md)
- any existing files from `content/catalog/` or `content/materials/` that the new slice must align with

## Expected Outputs

The agent should produce only the files that are required for the slice:

- `content/catalog/skills.yaml`
- `content/catalog/stages.yaml`
- `content/catalog/materials.yaml`
- `content/catalog/playlists.yaml`
- one or more markdown files under `content/materials/{subject}/...`

If the subject or area is new, it may also need updates to:

- `content/catalog/subjects.yaml`
- `content/catalog/areas.yaml`

## Non-Negotiable Rules

- Use the final vocabulary only.
- Keep ids in `snake_case`.
- Keep subject and area explicit in every catalog object.
- Reuse existing skills, stages, or materials when that is clearly better than creating duplicates.
- Do not invent compatibility aliases.
- Do not add placeholder materials that will never be used.

## Output Shape

Ask the agent to return:

1. the exact YAML entries to add or update
2. the exact markdown materials to add or update
3. a short explanation of why the stage and skill boundaries make sense
4. a validation checklist for cross-references

## Validation Checklist

Before accepting the output, check that:

1. every `skill_id` exists
2. every `stage_id` exists
3. every playlist references real materials
4. every material frontmatter matches the corresponding `materials.yaml` entry
5. subject and area ids are consistent across the whole slice
