# Simple Content Model

This is the smallest useful mental model for authoring Cornerstone curriculum.

If you remember only one rule, remember this:

- author reusable programs statically
- run them dynamically with learner-specific assignments

The authoring model should stay small enough that a parent or operator can still decide what to do tomorrow.

## Static Versus Dynamic

### Static Curriculum Objects

These are repo-owned and reusable:

- program brief
- program
- checkpoints
- skills
- resources
- playlists

### Dynamic Runtime Objects

These belong to the live system:

- learner profile
- assignment
- session
- evidence
- progress record
- review queue

Rule:

- author the curriculum statically
- run, adapt, and review it dynamically

## The Six Authoring Objects

Think in six authoring objects.

### 1. Program Brief

This is the plain-English design input.

It captures:

- who the learner type is
- what outcome is wanted
- how much time is available
- what constraints matter

Examples:

- age-10 learner needs secure arithmetic fundamentals in 15-minute daily sessions
- age-7 learner needs confident early reading with parent-led read-aloud practice
- adult learner needs clearer English pronunciation for work calls

The brief is an input object.
It is not runtime state.

### 2. Program

A program is the reusable curriculum slice for one audience and one outcome.

Examples:

- arithmetic foundations core
- early reading fluency starter
- English pronunciation essentials

If the learner need is broad, the program is where that broad need belongs.
Do not collapse the whole thing into one skill.

### 3. Checkpoint

A checkpoint is the main parent-facing stage inside a program.

Use checkpoints to answer:

- which major area is secure
- which major area still needs work
- which major area should be assigned next

Examples:

- fact fluency to 10
- written addition and subtraction
- short reading fluency
- consonant and vowel sound control

A checkpoint is not a worksheet and not a one-day lesson.
It is a meaningful review point.

### 4. Skill

A skill is the smallest measurable unit that changes what you would assign, repeat, or review.

Good test:

- if this specific split would change tomorrow's practice decision, keep it
- if it would not change tomorrow's practice decision, merge it

Examples:

- recall multiplication facts for 6 to 9
- perform column subtraction with borrowing
- read CVC words aloud accurately
- produce a clear long-a vowel sound

For simple programs, one checkpoint may begin with one matching skill.
That is acceptable.

### 5. Resource

A resource is the actual reusable learning artifact.

Examples:

- worksheet
- drill sheet
- reading passage
- teaching note
- coach script
- checkpoint sheet

One resource can support one skill or a small group of related skills inside one checkpoint.

### 6. Playlist

A playlist is the static ordered session sequence.

It answers:

- what should run on day 1, day 2, and day 3
- which resources should be repeated
- where checks should happen

The runtime assignment is different.
It is the learner-specific instance of that playlist.

## What Should Not Be First-Class

Avoid making these core authoring objects too early:

- achievements or badges
- daily plan variants for one specific learner
- completion events that duplicate evidence
- deep lesson taxonomies below the skill layer
- separate objects for every teaching note and observation style

Most of those are either derived reporting or local runtime detail.

## How Small Should A Skill Be

Split a skill only if the split changes at least one of these:

- the resource you would assign
- the coaching note you would write
- the repetition cadence you would choose
- the checkpoint decision you would make

If it changes none of those, keep it merged.

That is the practical boundary.

Use checkpoints first.
Use skills only where checkpoints are too broad for useful review.

## How Big Should A Checkpoint Be

A checkpoint should be big enough to matter to a parent and small enough to review honestly.

Good checkpoint questions are:

- is this learner secure in this area yet
- do we need another week on this area
- are we ready to move to the next area

If a checkpoint is too small to matter in weekly review, it is probably just a skill.
If a checkpoint is too large to review honestly, split it.

## Default Size For A New Program

For one new home-learning program, start with:

- 1 program brief
- 1 program
- 3 to 5 checkpoints
- 1 to 3 skills per checkpoint unless finer splits are clearly necessary
- 6 to 20 resources
- 1 to 3 playlists

You can always split later after you see real learner evidence.

## What The Catalog Actually Is

The catalog is the repo index for reusable curriculum.

- `content/catalog/capabilities.yaml`: current file for skills
- `content/catalog/milestones.yaml`: current file for checkpoints
- `content/catalog/content_index.yaml`: the index of real resource files
- `content/catalog/plan_templates.yaml`: current file for playlists
- `content/library/**/*.md`: the actual worksheets, notes, passages, prompts, and checks

So the relationship is simple:

- the catalog names and links the reusable curriculum
- the markdown files are the real resources
- the playlists order resources into repeatable sessions
- the runtime system tracks what actually happened for each learner

## Arithmetic Example

Suppose the real goal is:

- the child becomes secure in arithmetic fundamentals, including fact fluency and written operations

That goal is too large for one skill.
Treat it as one program.

### A Good Small Starting Structure

Program:

- arithmetic foundations core

Checkpoints:

- fact fluency to 10
- written addition and subtraction
- written multiplication and division

Skills inside those checkpoints might start as:

- addition facts recall
- subtraction facts recall
- multiplication facts recall
- division facts recall
- column addition with carrying
- column subtraction with borrowing
- 2-digit by 1-digit multiplication
- short division with remainders

Resources might include:

- timed fact drills
- mixed operation practice
- worked examples
- parent checkpoint sheets

Playlists might include:

- a 2-week fact fluency starter
- a 10-session written operations sequence

That is already enough to start authoring and running.

### When To Split Further

Only split when the learner's weak spots would change practice decisions.

Examples:

- if 2, 5, and 10 are secure but 6, 7, and 8 are weak, split multiplication facts into smaller skills
- if written subtraction is strong but carrying in addition is weak, separate those skills
- if division lags far behind multiplication, keep them in separate checkpoints or at least separate skills

So yes, the program can start small.
It does not need twenty finely sliced skills on day one.

## The Smallest Useful Authoring Loop

Use this order:

1. write the program brief in plain English
2. define the program and its checkpoints
3. decide whether each checkpoint needs one skill or several
4. write the real resources
5. index them in `content_index.yaml`
6. assemble one or more playlists that use real resource ids

## Compatibility Notes

- `track` is an old alias for `program`
- `milestone` is an old alias for `checkpoint`
- `capability` is an old alias for `skill`
- `plan template` is an old alias for `playlist`
- `achievement` should remain a derived report, not a core authoring object

## Practical Rule For This Repo

When in doubt, prefer simpler authoring and clearer practice over more taxonomy.

If a skill boundary does not help the parent decide what to do tomorrow, it is probably too fine-grained for the current MVP.

Next documents:

- [Program brief template](./program-brief-template.md)
- [Program authoring brief](./track-authoring-brief.md)
- [Content authoring rules](./ai-content-generation-contract.md)
- [Copy-paste authoring prompts](./repeatable-prompts.md)