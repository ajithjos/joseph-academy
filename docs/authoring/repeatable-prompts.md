# Repeatable Prompts

These prompts are designed for repeated content expansion rounds.

## Capability Catalog Expansion

```text
You are extending the Joseph Academy capability catalog.

Context:
- Product: Joseph Academy learning control plane
- Audience: young learners, initially ages 7 and 10
- Style: parent-led, practical, measurable, short-session friendly

Task:
- Add {N} new capability entries for subject {subject}
- Keep each capability as one measurable learning unit
- Return YAML entries only

Required fields:
- capability_id
- subject
- title
- recommended_age
- recommended_level
- description
- success_criteria
```

## Milestone Generation

```text
Generate milestone catalog entries for Joseph Academy.

Inputs:
- existing capability ids: {capability_ids}
- target age: {age}
- target level: {level}
- subject: {subject}

Task:
- group the capabilities into coherent milestone checkpoints
- return YAML entries only

Required fields:
- milestone_id
- subject
- title
- recommended_age
- recommended_level
- description
- capability_ids
```

## Plan Template Generation

```text
Generate a Joseph Academy plan template.

Inputs:
- milestone ids: {milestone_ids}
- capability ids: {capability_ids}
- content ids: {content_ids}
- duration days: {duration_days}
- session length: {minutes}

Task:
- produce one executable plan template for short daily sessions
- each session must point to real content ids
- return YAML only

Required fields:
- plan_template_id
- title
- recommended_age
- recommended_level
- milestone_ids
- capability_ids
- duration_days
- session_pattern
```

## Markdown Content Item Generation

```text
Write one Joseph Academy markdown content item.

Inputs:
- content id: {content_id}
- type: {type}
- subject: {subject}
- capability ids: {capability_ids}
- milestone ids: {milestone_ids}
- recommended age: {age}
- estimated minutes: {minutes}
- learning goal: {goal}

Task:
- return a single markdown file with YAML frontmatter
- keep the tone child-safe and operationally useful for a parent
- prefer short instructions and directly usable practice material
```
