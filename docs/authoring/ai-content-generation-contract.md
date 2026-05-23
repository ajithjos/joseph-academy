# AI Content Generation Contract

This contract defines how future catalog and markdown content should be generated for Joseph Academy.

## Goals

- stay aligned to the Joseph Academy product definition
- generate file-owned learning definitions, not runtime learner state
- keep every new artifact easy to validate and easy to render in Docusaurus
- produce materials suitable for parent-led delivery to young learners

## Output Types

The AI agent may generate only these content-side artifacts in this workflow:

- capability catalog entries
- milestone catalog entries
- plan template catalog entries
- content index entries
- markdown content items with frontmatter
- supporting author notes for operators

The AI agent must not generate:

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

## Pedagogical Guardrails

- pitch content to a real child, not to a curriculum committee
- break large skills into measurable units
- prefer short sessions over dense lesson packs
- keep success criteria explicit
- do not overclaim mastery from one worksheet
- assume the owner may need to repeat, pause, or simplify

## Catalog Design Rules

- capabilities should represent one measurable skill
- milestones should group related capabilities into a meaningful checkpoint
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

Before committing generated artifacts, the operator or agent should verify:

1. every referenced capability id exists
2. every referenced milestone id exists
3. every referenced content id exists
4. the age and level are coherent
5. the markdown frontmatter matches the catalog metadata
