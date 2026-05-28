# Learning Product Definition

Cornerstone uses one stable domain model across catalog files, backend APIs, frontend UI, and docs.

## Core Objects

### Curriculum

- Subject: the top-level discipline, such as maths or english.
- Area: a coherent slice inside a subject, such as arithmetic or reading.
- Stage: a parent-facing progress grouping inside an area.
- Skill: the smallest unit we track in learner progress.
- Material: one reusable teaching or practice artifact.
- Playlist: an ordered set of sessions that uses real materials.

### Optional Planning

- Pathway: an optional planning object above playlists that helps humans see a whole route, without replacing assignments or skill-level progress.

### Runtime

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
- A playlist sequences materials into sessions for a learner.
- A pathway can order multiple playlists into one larger route.
- An assignment instantiates one playlist for one learner.
- A session produces evidence.
- Evidence updates progress.

## File Ownership

- `content/catalog/subjects.yaml`
- `content/catalog/areas.yaml`
- `content/catalog/skills.yaml`
- `content/catalog/stages.yaml`
- `content/catalog/materials.yaml`
- `content/catalog/playlists.yaml`
- `content/materials/**/*.md`

The control plane loads those files and exposes the same names in its JSON responses.

## Product Rules

- Track learner progress at the skill level, not at the material level.
- Use stages for parent-facing review and planning, not for one-off session events.
- Keep materials reusable. A playlist should reference materials; it should not contain curriculum data that belongs in skills or stages.
- Treat playlists as reusable curriculum plans. Treat assignments as learner-specific runtime instances.
- If a larger whole-plan view is needed, add it above playlists as a pathway instead of overloading assignments.
- Keep subject and area visible in authoring and browsing surfaces. They are not optional metadata.

## What We Do Not Model

- No mandatory `program` object.
- No vague planning object that duplicates playlist or assignment responsibilities.
- No `capability`, `milestone`, `resource`, or `plan template` aliases.
- No separate progress object for every worksheet or page.

## Operational Notes

- Review queues or reminders can exist as derived runtime helpers.
- They are downstream of progress, not part of the core curriculum model.
- If a higher-level planning object is introduced, keep it optional and human-facing rather than making it the unit of progress tracking.
