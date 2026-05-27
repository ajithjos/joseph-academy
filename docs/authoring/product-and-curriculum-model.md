# Product And Curriculum Model

Cornerstone is a direct, parent-led or coach-led learning product. It is not a gamified reward system. The point of authored curriculum is to help an adult improve a child's real skills through short, repeated, practical work.

Curriculum in Cornerstone is file-owned in the repository. That curriculum must stay useful in three places at once:

- during authoring and review
- in parent or coach-facing delivery
- in learner progress tracking

## How Authored Curriculum Is Used

Authors need to understand the delivery chain that their work feeds:

1. Adults browse and author curriculum by subject and area.
2. A playlist becomes an assignment for one learner.
3. An assignment schedules sessions.
4. Sessions use real materials.
5. Completed sessions produce evidence.
6. Evidence updates progress at the skill level.

This is why skills, stages, materials, and playlists must stay distinct. If those boundaries blur, the runtime becomes harder to use and learner progress becomes less trustworthy.

## Core Curriculum Objects

Think in this order when authoring:

1. Subject
2. Area
3. Stage
4. Skill
5. Material
6. Playlist

That is the smallest model that still supports planning, delivery, and learner progress.

### Subject

A subject is the top-level domain such as maths or english.

Use a subject when you need a stable navigation or reporting boundary.

### Area

An area is a coherent slice inside a subject.

Examples:

- maths -> arithmetic
- english -> reading

Use areas to keep authoring and browse surfaces manageable.

### Stage

A stage is a parent-facing grouping of skills.

Good stages answer questions like:

- What broad slice of work is this learner in?
- What should a parent or coach expect to see next?
- Which related skills belong together for review?

### Skill

A skill is the smallest unit we track in learner progress.

Good skills are specific enough to practise, assess, and revisit.

### Material

A material is one reusable artifact such as a worksheet, reading passage, prompt sheet, teaching note, or drill card.

Each material should point back to real `skill_ids` and `stage_ids`.

### Playlist

A playlist is an ordered set of sessions that references real materials.

Use playlists for repeatable delivery. Do not hide stage or skill structure inside them.

## Supporting Runtime Context

Authors do not usually edit runtime objects directly, but they should know how the product uses authored curriculum.

- Team: the household or learning group.
- User: one person in the team.
- Learner: a user who receives assignments.
- Assignment: one learner's live use of one playlist over time.
- Session: a scheduled unit of work inside an assignment.
- Evidence: the recorded outcome of a completed session.
- Progress: the learner's current state for each skill, derived from evidence.

## Relationship Model

- A subject contains one or more areas.
- An area contains stages and skills.
- A stage groups a meaningful set of skills.
- A material supports one or more skills and one or more stages.
- A playlist sequences materials into sessions for delivery.
- An assignment instantiates one playlist for one learner.
- A session produces evidence.
- Evidence updates progress.

## Canonical Files

- `content/catalog/subjects.yaml`
- `content/catalog/areas.yaml`
- `content/catalog/skills.yaml`
- `content/catalog/stages.yaml`
- `content/catalog/materials.yaml`
- `content/catalog/playlists.yaml`
- `content/materials/**/*.md`

The control plane loads those files and exposes the same names in its responses.

## Recommended Authoring Order

1. Fill in the [Curriculum slice brief template](./curriculum-slice-brief-template.md).
2. Define the subject, area, and desired learner outcome.
3. Draft the skills for the slice.
4. Group those skills into stages.
5. Plan and write the real materials.
6. Index the materials in `materials.yaml`.
7. Assemble one or more playlists.

## Sizing Guidance

- Start with one subject and one area at a time.
- A stage should be meaningful to a parent, not just to the database.
- A skill should be small enough to practise repeatedly and assess clearly.
- A material should be reusable in more than one playlist when practical.
- A playlist should be short enough to assign confidently and easy to replace if it is not working.

## Naming Rules

- Use the final names everywhere: subject, area, stage, skill, material, playlist.
- Do not reintroduce aliases such as `capability`, `milestone`, `resource`, `program`, `checkpoint`, or `plan template`.
