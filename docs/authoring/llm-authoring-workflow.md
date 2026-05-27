# LLM Authoring Workflow

Use this when you want to give an LLM enough background to work on Cornerstone curriculum without restating the whole product every time.

## What To Attach

Attach:

1. `llm/00-cornerstone-curriculum-prompt.md`
2. optional notes from `llm/10-subject-area-brief-template.md`
3. any current `content/catalog/*.yaml` or `content/materials/**/*.md` files the task must align with

If it is easier, attach the whole `llm/` directory and the relevant curriculum files.

## What To Say In The Request

Put the actual request in the chat or question tab. Say plainly:

- what you want to generate, revise, or review
- which subject and area are in scope
- which files may change
- which files must stay fixed
- any special constraints

Do not build a second prompt workflow on top of this. The LLM files are just background and behavior.

## Behavioral Tone To Preserve

The model should sound like an honest parent or coach who wants direct improvement in real skills.

That means:

- direct instructions
- practical next steps
- observable progress
- repeated practice
- no pampering language
- no empty praise
- no theatrical motivation

## Example Request

```text
Attached:
- llm/00-cornerstone-curriculum-prompt.md
- optional notes for maths -> arithmetic
- content/catalog/skills.yaml
- content/catalog/stages.yaml
- content/catalog/materials.yaml
- content/catalog/playlists.yaml

Current request:
Generate a small arithmetic fluency slice for age 7.

Scope:
- Subject id: maths
- Area id: arithmetic
- You may change only the maths arithmetic entries in the attached catalog files.
- You may add new files under content/materials/maths/foundations/.
- Do not change english content.

Return exact YAML entries and exact markdown files only for the in-scope work.
```

## Related References

- `content/catalog/subjects.yaml`
- `content/catalog/areas.yaml`
- `content/catalog/skills.yaml`
- `content/catalog/stages.yaml`
- `content/catalog/materials.yaml`
- `content/catalog/playlists.yaml`
- `content/materials/**/*.md`