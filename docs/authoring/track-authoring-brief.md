# Track Authoring Brief

Attach this file when you want an LLM to derive Cornerstone curriculum content from a target outcome.

If needed, attach [Simple content model](./simple-content-model.md) as supporting context.

## What Cornerstone Is

Cornerstone is a learning control plane.

It separates:

- static curriculum definitions in repo files
- dynamic learner progress in the runtime database

Do not generate runtime learner state.
Do not generate reports about a specific child.
Do generate file-owned curriculum structure and practice material.

## The Static Model To Use

When I give you a target outcome, treat it as a static track-design problem.

Use this structure:

1. target outcome
2. track
3. milestone sub-tracks
4. optional capabilities inside each milestone when finer tracking is actually useful
5. content items
6. static plan template

Interpret those layers like this:

- target outcome: the overall learning result wanted for the child
- track: the repo-owned curriculum slice for that outcome
- milestone: the main parent-facing sub-track such as addition fluency, multiplication fluency, division fluency, fractions basics, or reading fluency
- capability: a finer-grained skill unit only when that split changes what should be assigned, repeated, or reviewed
- content item: the real worksheet, drill, note, passage, or practice page
- static plan template: the suggested order of sessions using those content items

Important rule:

- milestones are the main static checkpoints
- capabilities are secondary and should stay minimal until finer tracking is genuinely useful

In simple tracks, one milestone may begin with exactly one matching capability.
That is acceptable.

## What To Generate

When I describe a target outcome, generate the repo-owned material needed for that track:

- `content/catalog/capabilities.yaml`
- `content/catalog/milestones.yaml`
- `content/catalog/content_index.yaml`
- `content/catalog/plan_templates.yaml`
- markdown files under `content/library/{subject}/...`

Do not generate database rows, learner progress state, or runtime API data.

## Modeling Rules

- start with a small manageable structure
- prefer milestone-level clarity before capability-level detail
- split capabilities only when the split changes the next practice or review decision
- keep milestones concrete and parent-meaningful
- keep plan templates short and operational
- every plan session must point to real content ids
- every content item should support a real milestone and one or more capabilities

As a starting point for a new track, prefer:

- 1 target outcome
- 1 track
- 3 to 6 milestones
- 1 to 2 capabilities per milestone unless a finer split is clearly needed
- 6 to 20 content items depending on length
- 1 static plan template

## Tone And Authoring Stance

Use a calm, direct, practice-first tone.

- do not use sugary praise or filler encouragement
- do not write like a marketing page or a nursery poster
- do not add repeated phrases like well done, amazing, brilliant, or excellent unless there is a specific instructional reason
- write like an honest, capable parent or coach whose goal is real learning progress
- be child-safe, but not soft or vague
- prefer clarity, repetition, and accuracy over entertainment

## Quality Bar For Content

- plain English
- short sections
- explicit instructions
- directly usable by a parent today
- printable or easy to read on screen
- no decorative filler
- no empty motivation language
- no curriculum-theory jargon unless it is operationally necessary

## Id And Metadata Rules

- capability ids use `snake_case`
- milestone ids use `snake_case`
- plan template ids use `snake_case`
- content ids begin with `cnt_`

Every catalog artifact should include:

- subject
- recommended age
- recommended level
- plain-English title
- concise description

Markdown content must include frontmatter with:

- `id`
- `type`
- `subject`
- `capability_ids`
- `milestone_ids`
- `recommended_age`
- `difficulty`
- `estimated_minutes`

## Output Shape

When I provide a target outcome, return the result in this order.

### 1. Track Design Summary

State:

- target outcome
- track title
- milestone list
- capability list grouped under each milestone
- brief explanation of why the capability splits are justified

### 2. Files To Create Or Update

List:

- which catalog files should be updated
- which markdown files should be created under `content/library/...`

### 3. Repo-Ready YAML

Return YAML blocks grouped by target file for:

- capabilities
- milestones
- content index
- plan template

### 4. Markdown Content Files

Return the proposed markdown files in full, one file at a time.

### 5. Short Review Checklist

End with a short checklist confirming:

- ids line up
- references line up
- age and level are coherent
- sessions are practical
- content tone matches the requested stance

## How To Respond To Broad Outcomes

If my target outcome is broad, do not collapse it into one capability.

Instead:

1. treat it as one track
2. derive milestone sub-tracks first
3. decide whether each milestone needs one capability or several
4. keep the structure as small as possible while still being useful for practice and review

## Example Of The Intended Interpretation

If I say:

- I want an age-10 child to become fluent in addition, subtraction, multiplication, and division facts up to 10

Do not treat that as one capability.

Treat it as:

- one track outcome
- milestones such as addition fluency, subtraction fluency, multiplication fluency, and division fluency
- optional finer capabilities inside those milestones only when needed, such as harder table groups or inverse-fact weaknesses