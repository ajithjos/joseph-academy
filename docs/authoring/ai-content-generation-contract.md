# Content Authoring Rules

This is the ruleset for writing Cornerstone catalog entries and markdown content.

Use it whether the draft is written by hand or with an LLM.

## What This Authoring Flow Is For

- stay aligned to the Cornerstone product definition
- generate file-owned learning definitions, not runtime learner state
- keep every new artifact easy to validate and easy to render in Docusaurus
- produce materials suitable for parent-led delivery to young learners

## Keep The Model Small

- choose the coarsest capability boundary that still changes practice or review decisions
- start with a small number of capabilities and split later only when the evidence justifies it
- keep milestones as the main parent-facing sub-tracks, not as another layer of lesson content
- keep sessions short and operationally useful

## Tone And Stance

- write in plain, direct, practice-first language
- avoid sugary praise, congratulatory filler, or inflated encouragement
- avoid empty lines like amazing work, brilliant job, or excellent effort unless the content genuinely requires that voice
- sound like an honest parent or coach focused on learning, repetition, and accuracy
- stay child-safe without becoming vague or overly soft

## What You May Author

This workflow is only for file-owned artifacts such as:

- capability catalog entries
- milestone catalog entries
- plan template catalog entries
- content index entries
- markdown content items with frontmatter
- supporting author notes for operators

It must not create or pretend to create:

- learner runtime state
- mastery claims for a specific child
- private personal data beyond the bootstrap files
- production deployment secrets

## Metadata Rules

Every generated artifact must include stable identifiers.

- capabilities use `snake_case` capability ids
- milestones use `snake_case` milestone ids
- plan templates use `snake_case` plan template ids
- content items use ids prefixed with `cnt_`

Every generated artifact should declare:

- subject
- recommended age
- recommended level
- short plain-English title
- concise description

Markdown content items must include frontmatter with:

- `id`
- `type`
- `subject`
- `capability_ids`
- `milestone_ids`
- `recommended_age`
- `difficulty`
- `estimated_minutes`

## The File Relationship

- `capabilities.yaml` defines skill units
- `milestones.yaml` groups capability ids
- `content_index.yaml` points to real markdown files
- `content/library/**/*.md` holds the actual materials
- `plan_templates.yaml` orders content into sessions

The catalog is the index.
The markdown files are the real teaching material.

The plan template is static.
Real learner execution remains dynamic in the runtime.

## Pedagogical Guardrails

- pitch content to a real child, not to a curriculum committee
- break large skills into useful measurable units
- prefer short sessions over dense lesson packs
- keep success criteria explicit
- do not overclaim mastery from one worksheet
- assume the owner may need to repeat, pause, or simplify

## Catalog Design Rules

- capabilities should represent one useful measurable skill for planning and review
- milestones should group a small number of related capabilities into a meaningful checkpoint
- plan templates should be executable in short daily sessions
- content items should map to one or more capabilities
- plan templates should reference real content ids that exist in `content/library`

## Quality Bar For Generated Markdown

- plain language
- child-safe tone
- printable or directly readable
- no decorative filler
- short sections
- easy for a parent to facilitate without extra tooling

## Required Review Pass

Before committing any authored slice, verify:

1. every referenced capability id exists
2. every referenced milestone id exists
3. every referenced content id exists
4. the age and level are coherent
5. the markdown frontmatter matches the catalog metadata
