# Content Authoring Rules

This is the ruleset for writing Cornerstone catalog entries and markdown resources.

Use it whether the draft is written by hand or with an LLM.

## What This Authoring Flow Is For

- stay aligned to the Cornerstone product definition
- generate file-owned curriculum, not runtime learner state
- keep every new artifact easy to validate and easy to render in Docusaurus
- produce materials suitable for parent-led delivery to young learners

## Use The Canonical Model

Reason with this vocabulary:

- program
- checkpoint
- skill
- resource
- playlist

Map those to the current repo files like this:

- skills -> `capabilities.yaml`
- checkpoints -> `milestones.yaml`
- playlists -> `plan_templates.yaml`
- resources -> `content_index.yaml` plus `content/library/**/*.md`

## Keep The Model Small

- choose the coarsest skill boundary that still changes practice or review decisions
- start with a small number of skills and split later only when evidence justifies it
- keep checkpoints as the main parent-facing review units
- keep playlists short and operationally useful

## Tone And Stance

- write in plain, direct, practice-first language
- avoid sugary praise, congratulatory filler, or inflated encouragement
- avoid empty lines like amazing work, brilliant job, or excellent effort unless the content genuinely requires that voice
- sound like an honest parent or coach focused on learning, repetition, and accuracy
- stay child-safe without becoming vague or overly soft

## What You May Author

This workflow is only for file-owned artifacts such as:

- skill catalog entries
- checkpoint catalog entries
- playlist catalog entries
- resource index entries
- markdown resources with frontmatter
- supporting author notes for operators

It must not create or pretend to create:

- learner runtime state
- mastery claims for a specific child
- private personal data beyond the bootstrap files
- production deployment secrets

## Metadata Rules

Every generated artifact must include stable identifiers.

- skills use `snake_case` ids in `capabilities.yaml`
- checkpoints use `snake_case` ids in `milestones.yaml`
- playlists use `snake_case` ids in `plan_templates.yaml`
- resources use ids prefixed with `cnt_`

Every generated artifact should declare:

- subject
- recommended age
- recommended level
- short plain-English title
- concise description

Markdown resources must include frontmatter with:

- `id`
- `type`
- `subject`
- `capability_ids`
- `milestone_ids`
- `recommended_age`
- `difficulty`
- `estimated_minutes`

## The File Relationship

- `capabilities.yaml` stores skills
- `milestones.yaml` stores checkpoints that group skill ids
- `content_index.yaml` points to real markdown resources
- `content/library/**/*.md` holds the actual materials
- `plan_templates.yaml` stores playlists that order content into sessions

The catalog is the index.
The markdown files are the real teaching material.

The playlist is static.
Real learner execution remains dynamic in the runtime.

## Pedagogical Guardrails

- pitch content to a real child or learner, not to a curriculum committee
- break large skills into useful measurable units
- prefer short sessions over dense lesson packs
- keep success criteria explicit
- do not overclaim mastery from one worksheet
- assume the coach may need to repeat, pause, or simplify

## Catalog Design Rules

- skills should represent one useful measurable unit for planning and review
- checkpoints should group a small number of related skills into a meaningful review point
- playlists should be executable in short daily sessions
- resources should map to one or more real skills
- playlists should reference real content ids that exist in `content/library`

## Quality Bar For Generated Markdown

- plain language
- child-safe tone
- printable or directly readable
- no decorative filler
- short sections
- easy for a parent to facilitate without extra tooling

## Required Review Pass

Before committing any authored slice, verify:

1. every referenced skill id exists in `capabilities.yaml`
2. every referenced checkpoint id exists in `milestones.yaml`
3. every referenced content id exists in `content_index.yaml`
4. the age and level are coherent
5. the markdown frontmatter matches the catalog metadata
