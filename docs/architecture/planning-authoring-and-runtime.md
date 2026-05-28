# Planning, Authoring, And Runtime

This doc separates three concerns that should not be collapsed into one mental model:

1. the whole teaching route a human wants to see
2. the reusable curriculum objects the product tracks and delivers
3. the source files used to maintain those objects in the repo

If those three concerns are blurred, the system feels harder to use than it really is.

## Short Answer

- YAML is practical as a repo source format.
- YAML is not the right primary product surface for parents or curriculum planning.
- Markdown is practical for rich teaching content.
- The current runtime model is mostly right.
- The main missing concept is one optional planning object above playlists.

## The Three Layers

### 1. Planning Layer

This is the human-facing view of the whole route.

Recommended object:

- `pathway`: an ordered route across playlists for one broad outcome or learner profile

Use a pathway when you want to answer questions like:

- What is the whole arithmetic route for this child?
- What comes after this playlist?
- Which playlists belong together as one larger plan?

A pathway is not where progress is tracked. It is the top-level route and navigation object.

For Cornerstone, it is reasonable to treat pathway as part of the canonical product model rather than as a throwaway helper. The important constraint is not optional versus mandatory. The important constraint is responsibility:

- pathway owns route order across playlists
- playlist owns one assignable short plan
- assignment owns one learner's live run of one playlist

Good UI labels for a pathway can be:

- learning plan
- syllabus
- roadmap

But the canonical object name should stay narrow. `pathway` is clearer than vague names such as `program`.

### 2. Curriculum Layer

This is the reusable teaching model.

- Subject: top boundary such as maths
- Area: manageable slice such as arithmetic
- Stage: broad parent-facing grouping
- Skill: smallest tracked learning outcome
- Material: reusable teaching or practice asset
- Playlist: smallest reusable assignable teaching plan

This layer should stay stable because progress, reuse, and reporting depend on it.

## The Two Linked Trees

The easiest way to stop the concepts from blurring is to see that there are really two linked trees, not one.

### Delivery Tree

- pathway
- playlist
- session

This tree answers:

- What is the whole route?
- What short plan comes next?
- What should happen today?

### Learning Tree

- subject
- area
- stage
- skill
- material

This tree answers:

- What domain is this in?
- What broad learning slice is this?
- Which skills matter here?
- Which materials teach or practise those skills?

### How They Connect

They connect like this:

- a pathway orders playlists
- a playlist schedules sessions
- a session uses materials
- materials support skills
- skills belong to stages and areas
- evidence from a completed session updates skill progress

That is why pathway and playlist can feel similar at first glance. Both are planning objects. The difference is level:

- pathway = route across multiple playlists
- playlist = one short assignable plan
- session = one work block inside that plan

So yes, you can think of them as higher plan, lower plan, and daily plan, as long as you do not blur them with skill tracking.

### 3. Runtime Layer

This is the live learner state.

- Learner: the child receiving work
- Assignment: one learner using one playlist over time
- Session: one scheduled work block inside the assignment
- Evidence: the recorded result of completed work
- Progress: the learner's current state for each skill

This layer should stay close to real delivery. It should not be overloaded with long-range curriculum planning.

## Recommended Object Responsibilities

| Object | Purpose | Assigned directly? | Progress tracked directly? |
| --- | --- | --- | --- |
| `pathway` | Show the whole route across multiple playlists | No | No |
| `playlist` | Define one short reusable teaching plan | Yes | Indirectly through sessions and skills |
| `session` | Represent one work block inside an assignment | Scheduled by assignment | Indirectly through evidence |
| `skill` | Define the smallest outcome worth tracking | No | Yes |
| `material` | Provide teaching, practice, review, drill, or checking content | No | No |
| `assignment` | Run one playlist for one learner | Yes, as runtime state | Indirectly through sessions and evidence |

## Where Drills And Exercises Live

Drills and quick checks should not be separate top-level planning objects.

They fit best as kinds of material used inside sessions.

Recommended material kinds:

- teaching_note
- worksheet
- drill
- quick_check

That gives a clean rule:

- pathway, playlist, and session decide sequence
- material kind decides what the learner actually does in that session

For a computer-based drill, the material would describe the drill template or rules. The runtime can then generate random prompts from that material definition, and the evidence from the attempt can update the linked skills.

## What This Means For Your Product Surface

If you want the product to feel obvious, expose the layers separately.

Recommended parent or owner surfaces:

1. Pathway view: the whole route for arithmetic fact fluency
2. Playlist view: one short block such as `Addition facts to 10`
3. Session view: today's teaching or practice block
4. Drill or quick check view: short learner activity tied to a small fact set or skill
5. Progress view: skill-level status and weak spots

That is much clearer than expecting the user to infer the route from raw stages, materials, and playlists.

## YAML And Markdown: What They Are For

The source format is not the product surface.

Use YAML for small structured indexes.
Use Markdown for rich human-readable content.

### YAML Is Good For

- ids
- titles
- references between objects
- small structured fields such as `subject_id`, `skill_ids`, `recommended_age`, and `duration_days`

### Markdown Is Good For

- worksheets
- teaching notes
- prompt sheets
- drill instructions
- review guidance

### YAML Is Not Good For

- long explanations
- whole curriculum planning as prose
- daily authoring by non-technical users without a better editor on top

## Why The Current Repo Feels More Complex Than It Should

Right now, material metadata is duplicated.

- each material markdown file already contains YAML front matter
- the repo also keeps a separate `content/catalog/materials.yaml` index with the same metadata

That duplication is real. It is not just your impression.

The current code validates that those two copies match. That gives safety, but it also adds maintenance overhead.

## Recommended Storage Simplification

For long-term maintainability, the cleaner design is:

1. keep structured catalog files for small objects such as pathway, subject, area, stage, skill, and playlist
2. keep each material in one markdown file with front matter
3. remove the separate `materials.yaml` index once the loader is changed to discover materials directly from markdown

That keeps two source formats, but with a cleaner boundary:

- YAML for short structured objects
- Markdown for rich content objects

That is much easier to maintain than keeping the same material metadata in two places.

## Small Source Examples

The current repo already follows a reasonable split.

Example skill in `skills.yaml`:

```yaml
- skill_id: add_within_10
  subject_id: maths
  area_id: arithmetic
  title: Add within 10
  description: Answer mixed addition facts within 10 accurately.
  success_criteria: Answers 18 out of 20 facts correctly in one short check.
```

Example material in Markdown:

```markdown
---
id: cnt_maths_add_within_10_sheet_01
type: worksheet
subject_id: maths
area_id: arithmetic
skill_ids:
  - add_within_10
stage_ids:
  - addition_and_subtraction_facts_to_10
---

# Add Within 10

1. 4 + 3 =
2. 6 + 2 =
3. 5 + 4 =
```

Example playlist in `playlists.yaml`:

```yaml
- playlist_id: addition_facts_to_10_starter
  title: Addition facts to 10 starter
  subject_id: maths
  area_id: arithmetic
  stage_ids:
    - addition_and_subtraction_facts_to_10
  skill_ids:
    - add_within_10
  duration_days: 4
```

Example proposed pathway above playlists:

```yaml
- pathway_id: arithmetic_fact_fluency_foundation
  title: Arithmetic fact fluency foundation
  playlist_ids:
    - addition_facts_to_10_starter
    - addition_facts_to_20_starter
    - multiplication_foundations_starter
    - multiplication_through_5_starter
    - multiplication_through_10_starter
```

That last object is the missing clarity layer. It is the answer to the whole-plan question.

## Maintainability Guidance

### For Now

- Keep YAML catalogs as the source-of-truth index.
- Keep Markdown materials as the source-of-truth content.
- Keep briefs and planning notes as separate human-facing docs.
- Do not ask the product user to think in raw YAML.

For a small repo, one catalog file per object type is acceptable.

### Later, If The Repo Grows

When the catalog becomes too large to review comfortably, the next maintainability step is not a new teaching model. The next step is a storage refactor.

Typical options:

1. split large catalogs into one file per object
2. keep the same object model but generate the catalogs from a higher-level editor
3. add an admin authoring UI that writes the same canonical YAML and Markdown

Do not do that yet unless the current files are already slowing you down.

## Recommended Architecture Decision

Keep these as they are:

- `pathway`
- `subject`
- `area`
- `stage`
- `skill`
- `material`
- `playlist`
- `assignment`
- `session`
- `evidence`
- `progress`

Do not add several overlapping top-level objects such as:

- `program`
- `subprogram`
- `plan template`
- `curriculum item`
- `milestone plan`

One additional planning object is enough.

## Recommended MVP Methodology

1. Write or revise the pathway first in a human-readable brief.
2. Break that pathway into small playlists.
3. Break each playlist into sessions.
4. Attach real materials, including drills or quick checks, to sessions.
5. Record evidence at session completion.
6. Derive progress at skill level.

That keeps planning, authoring, and runtime connected without turning them into one giant object.

## Recommendation For Cornerstone Right Now

- Do not rewrite the core runtime model.
- Do add a pathway concept at the doc and UI level.
- Do keep YAML and Markdown as the canonical repo formats for now.
- Do make the owner-facing UI show the whole route above the current assignment.
- Do keep `playlist` as the unit of assignment.

This gives you clarity now, maintainability in the repo, and a clean path to a bigger platform later.