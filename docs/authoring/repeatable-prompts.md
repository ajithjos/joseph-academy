# Copy-Paste Authoring Prompts

Copy one prompt, change the factual lines near the top, and send it as-is.

These are written in plain English so you can paste them directly into an LLM without any templating system.

## Prompt 1: Decide The Right Capability Boundaries

```text
I am designing a new Cornerstone practice track.

This is for maths.
The learner is around 10 years old and roughly Year 5.
The outcome I want is secure fluency in addition, subtraction, multiplication, and division facts up to 10.
I want 15-minute daily sessions for about 3 weeks.
I want the simplest useful model, not a big taxonomy.

Please help me decide the right structure.

- Choose the coarsest useful capability boundaries.
- Keep the total number of capabilities small unless there is a clear reason to split further.
- Group the capabilities into at most 3 milestones.
- Explain why each capability split is useful for practice and review.
- Point out anything that is still too broad or too fine-grained.
- End with one final recommendation under these headings:
	- target outcome
	- capabilities
	- milestones

Do not write YAML yet.
Do not write markdown files yet.
```

## Prompt 2: Turn The Agreed Structure Into Repo Files

```text
I am working in the Cornerstone repo.

I already know the target outcome, capabilities, and milestones for this track.
Please turn that structure into repo-ready YAML for:

- capabilities.yaml entries
- milestones.yaml entries
- content_index.yaml entries
- one plan_templates.yaml entry

Rules:

- keep ids simple and consistent
- keep sessions short and parent-led
- every plan session must point to real content ids that you also define
- do not invent runtime data
- return only the YAML blocks, grouped by target file

I will paste the agreed structure below this line.
```

## Prompt 3: Write One Content File

```text
I am creating one Cornerstone content file.

This is a maths worksheet.
The learner is around 10 years old.
It should support multiplication and division fact fluency.
It should take about 12 minutes.
I want something a parent can use today without extra tooling.

Please return one markdown file only.

- include YAML frontmatter with id, type, subject, capability_ids, milestone_ids, recommended_age, difficulty, and estimated_minutes
- keep the tone plain, child-safe, and practice-first
- make it printable or easy to read on screen
- do not add decorative filler
- if this should really be a teaching note instead of a worksheet, say so briefly before the file
```

## Prompt 4: Simplify An Over-Modeled Draft

```text
I think this Cornerstone draft may be over-modeled.

I will paste the current capabilities, milestones, content items, and plan sessions below.

Please simplify it.

- merge anything that does not change practice decisions
- keep only the capability boundaries that change what I would assign, repeat, or review
- aim for the smallest catalog I can comfortably maintain
- preserve clear tracking of weak spots
- give me a plain-English before-and-after recommendation

Do not write final YAML until after you explain the simplification.
```

## Prompt 5: Review A Draft Before Committing It

```text
I have drafted a Cornerstone content slice.

I will paste the capabilities, milestones, content index entries, plan template, and one or more markdown files below.

Please review it before I commit it.

- check that every referenced capability id exists
- check that every referenced milestone id exists
- check that every referenced content id exists
- check that the age and level feel coherent
- check that the markdown frontmatter matches the catalog metadata
- point out anything that feels too vague for actual practice

Return a short list of problems first.
If the draft is sound, say so clearly.
```
