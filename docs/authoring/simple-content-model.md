# Simple Content Model

This is the mental model to use when authoring Cornerstone content.

The missing distinction is this:

- the curriculum map is static
- learner progress and day-to-day execution are dynamic

If you remember only one rule, remember this:

- use the coarsest capability boundary that still changes what you would assign, repeat, or review next

That means you do not need the smallest possible academic unit.
You need the smallest useful practice unit.

## Static Versus Dynamic

### Static Curriculum Map

These are repo-owned and should stay stable enough to reason about clearly:

- target outcome
- track
- milestones
- capabilities
- content items
- static plan template

### Dynamic Runtime State

These belong to the live system, not the authored curriculum:

- which learner is active on which track
- what was completed this week
- which items need review
- scores, notes, timing, and evidence
- schedule changes made during real use

Rule:

- author the curriculum statically
- run and adapt it dynamically

## The Six Layers

Think in six layers.

### 1. Target Outcome

This is the human goal.

Examples:

- comfortable with addition, subtraction, multiplication, and division facts up to 10
- able to read short passages aloud with steady fluency

This is not a catalog file by itself.
It is the author's planning goal.

### 2. Track

A track is the static curriculum slice for one outcome.

Examples:

- age-10 arithmetic fluency core
- reading fluency stage 1

There is no separate track file yet.
In practice, the track is represented by its milestones, capabilities, content items, and plan templates.

### 3. Milestone

A milestone is the main static sub-track.

This is the level a parent should usually think in first.

Examples:

- addition fluency
- subtraction fluency
- multiplication fluency
- division fluency

Use it to answer:

- which major sub-track is secure
- which major sub-track still needs work

A milestone is not a worksheet and not a lesson page.
It is a clear checkpoint within the track.

### 4. Capability

A capability is a finer-grained skill unit inside a milestone when that extra detail is useful.

Good test:

- after a short practice or checkpoint, can you say secure, not yet, or needs review?

If yes, it can be a capability.
If no, split it.

But do not split further unless the split changes what you would actually do next.

For simple tracks, one milestone can begin with one matching capability.
That is acceptable.

### 5. Content Item

A content item is the actual practice material.

Examples:

- worksheet
- drill sheet
- reading passage
- teaching note

One content item can support one capability or a small group of related capabilities within a milestone.

### 6. Plan Template

A plan template is the static ordered list of sessions.

It tells the owner what to run on each day.

Each session points to real content items.

The runtime learning plan is different.
It is the live assigned instance of that template for a real learner.

## How Small Should A Capability Be

Use this decision rule.

Split a capability only if the split would change at least one of these:

- the worksheet or activity you would assign
- the review note you would write
- the repetition cadence you would choose

If splitting does not change one of those, keep it together.

That is the practical boundary.

Use milestones first.
Use capabilities only where milestones are still too broad for useful review.

## Default Size For A New Track

For one new home-learning track, start small.

- 1 target outcome
- 1 track
- 3 to 6 milestones
- 1 to 2 capabilities per milestone unless finer splits are clearly useful
- 4 to 12 content items
- 1 plan template

You can always split later after you see real learner data.

## What The Catalog Actually Is

The catalog is not separate teaching content.

It is the repo index that tells the system what exists.

- `content/catalog/capabilities.yaml`: the finer-grained skill list when needed
- `content/catalog/milestones.yaml`: the main track sub-checkpoints
- `content/catalog/content_index.yaml`: the index of real markdown content files
- `content/catalog/plan_templates.yaml`: session sequences
- `content/library/**/*.md`: the actual worksheet, note, passage, or activity text

So the relationship is simple:

- the catalog names and links the static curriculum
- the markdown files are the actual materials
- the static plan template orders the materials into sessions
- the runtime system tracks what actually happened for each learner

## Arithmetic Example

Suppose the real goal is:

- the child becomes comfortable with addition, subtraction, multiplication, and division facts up to 10

That goal is too large for one capability.

Treat it as a target outcome.

### A Good Small Starting Structure

Start with one arithmetic fluency track.

Then use four parent-facing milestones:

- addition fluency
- subtraction fluency
- multiplication fluency up to 10
- division fluency up to 10

Under each milestone, start with one broad matching capability if that is enough:

- addition facts fluency
- subtraction facts fluency
- multiplication tables fluency up to 10
- division facts fluency up to 10

This is already enough to start authoring content and running plans.

### When To Split Further

Only split if the child's weak spots would change practice decisions.

Examples:

- if 2, 5, and 10 are secure but 6, 7, and 8 are weak, split the multiplication capability inside that milestone
- if division is much weaker than multiplication, keep it as its own milestone and capability set
- if addition needs separate carrying or missing-number practice, split the addition capability into smaller units

So yes, it can begin as four milestones and four matching capabilities.
It does not need to start as twenty capabilities.

## The Smallest Useful Authoring Loop

Use this order:

1. write the target outcome in plain English
2. define the track and its milestone sub-tracks
3. decide whether each milestone needs one capability or several
4. write the actual content items
5. index them in `content_index.yaml`
6. assemble one static plan template that uses those content ids

## Practical Rule For This Repo

When in doubt, prefer simpler authoring and clearer practice over more taxonomy.

If a capability boundary does not help the parent decide what to do tomorrow, it is probably too fine-grained for the current MVP.

Next documents:

- [Track authoring brief](./track-authoring-brief.md)
- [Content authoring rules](./ai-content-generation-contract.md)
- [Copy-paste authoring prompts](./repeatable-prompts.md)