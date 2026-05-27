# Program Authoring Brief

The file name is kept for compatibility, but the canonical term is now `program`, not `track`.

Attach this file when you want an LLM to turn a Cornerstone program brief into repo-owned curriculum assets.

If needed, attach these as supporting context:

- [Program brief template](./program-brief-template.md)
- [Simple content model](./simple-content-model.md)

## What Cornerstone Is

Cornerstone is a repeatable learning system.

It separates:

- static reusable curriculum in repo files
- dynamic learner progress in runtime state

Do not generate runtime learner state.
Do not generate reports about a specific child.
Do generate reusable program structure and practice material.

## The Static Model To Use

When I give you a program brief, treat it as a static program-design problem.

Use this structure:

1. program brief
2. program
3. checkpoints
4. optional skills inside each checkpoint when finer tracking is genuinely useful
5. resources
6. playlists

Interpret those layers like this:

- program brief: the plain-English design input for one learner segment and one outcome
- program: the reusable curriculum slice for that brief
- checkpoint: the main parent-facing stage such as fact fluency, written subtraction, reading fluency, pronunciation clarity, or ball handling basics
- skill: a finer-grained measurable unit only when that split changes what should be assigned, repeated, or reviewed
- resource: the real worksheet, drill, note, passage, prompt, script, or check
- playlist: the repeatable ordered session sequence using those resources

Important rule:

- checkpoints are the main static review units
- skills are secondary and should stay minimal until finer tracking is operationally useful

In simple programs, one checkpoint may begin with exactly one matching skill.
That is acceptable.

## Compatibility With Current Repo Files

Use the canonical vocabulary in reasoning, but map it to the current repo files like this:

- skills -> `content/catalog/capabilities.yaml`
- checkpoints -> `content/catalog/milestones.yaml`
- resources -> `content/catalog/content_index.yaml` plus `content/library/**/*.md`
- playlists -> `content/catalog/plan_templates.yaml`

There is no separate `programs.yaml` yet.
Represent the program coherently through shared titles, ids, descriptions, and linked checkpoints, skills, resources, and playlists.

## What To Generate

When I describe a program brief, generate the repo-owned material needed for that program:

- skill entries for `content/catalog/capabilities.yaml`
- checkpoint entries for `content/catalog/milestones.yaml`
- resource index entries for `content/catalog/content_index.yaml`
- playlist entries for `content/catalog/plan_templates.yaml`
- markdown resources under `content/library/{subject}/...`

Do not generate database rows, learner progress state, or runtime API data.

## Modeling Rules

- start with a small manageable structure
- prefer checkpoint-level clarity before skill-level detail
- split skills only when the split changes the next practice or review decision
- keep checkpoints concrete and parent-meaningful
- keep playlists short and operational
- every playlist session must point to real resource ids
- every resource should support a real checkpoint and one or more skills

As a starting point for a new program, prefer:

- 1 program brief
- 1 program
- 3 to 5 checkpoints
- 1 to 3 skills per checkpoint unless a finer split is clearly needed
- 6 to 20 resources depending on length
- 1 to 3 playlists

## Tone And Authoring Stance

Use a calm, direct, practice-first tone.

- do not use sugary praise or filler encouragement
- do not write like a marketing page or a nursery poster
- do not add repeated phrases like well done, amazing, brilliant, or excellent unless there is a specific instructional reason
- write like an honest, capable parent or coach whose goal is real learning progress
- be child-safe, but not soft or vague
- prefer clarity, repetition, and accuracy over entertainment

## Quality Bar For Resources

- plain English
- short sections
- explicit instructions
- directly usable by a parent today
- printable or easy to read on screen
- no decorative filler
- no empty motivation language
- no curriculum-theory jargon unless it is operationally necessary

## Id And Metadata Rules

- skill ids use `snake_case` in `capabilities.yaml`
- checkpoint ids use `snake_case` in `milestones.yaml`
- playlist ids use `snake_case` in `plan_templates.yaml`
- resource ids begin with `cnt_`

Every catalog artifact should include:

- subject
- recommended age
- recommended level
- plain-English title
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

## Output Shape

When I provide a program brief, return the result in this order.

### 1. Program Design Summary

State:

- the interpreted program brief
- the program title
- the checkpoint list
- the skill list grouped under each checkpoint
- brief reasoning for why the skill splits are justified

### 2. Files To Create Or Update

List:

- which catalog files should be updated
- which markdown resources should be created under `content/library/...`

### 3. Repo-Ready YAML

Return YAML blocks grouped by target file for:

- skills in `capabilities.yaml`
- checkpoints in `milestones.yaml`
- resource index entries in `content_index.yaml`
- playlists in `plan_templates.yaml`

### 4. Markdown Resource Files

Return the proposed markdown files in full, one file at a time.

### 5. Short Review Checklist

End with a short checklist confirming:

- ids line up
- references line up
- age and level are coherent
- sessions are practical
- resource tone matches the requested stance

## How To Respond To Broad Outcomes

If my brief is broad, do not collapse it into one skill.

Instead:

1. treat it as one program
2. derive checkpoints first
3. decide whether each checkpoint needs one skill or several
4. keep the structure as small as possible while still being useful for practice and review

## Example Of The Intended Interpretation

If I say:

- I want an age-10 child to become dependable in addition, subtraction, multiplication, and division fundamentals through short daily practice

Do not treat that as one skill.

Treat it as:

- one program brief
- one program
- checkpoints such as fact fluency, written addition and subtraction, and written multiplication and division
- optional finer skills only where they change practice decisions