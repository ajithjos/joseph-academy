# Learning Product Definition

Cornerstone uses one stable domain model across authored content, backend APIs, frontend UI, and docs.

## Core Objects

### Curriculum

- Subject: the top-level discipline, such as maths or english.
- Area: a coherent slice inside a subject, such as arithmetic or reading.
- Pathway: the canonical whole-route container inside one subject and area.
- Stage: a parent-facing learning progression step inside a pathway.
- Skill: the smallest unit tracked in learner progress.
- Material: one reusable teaching, practice, drill, or checking artifact.
- Playlist: an ordered set of sessions that uses real materials.

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
- An area contains one or more pathways.
- A pathway contains stages, skills, playlists, materials, and entry guidance.
- A stage groups a meaningful set of skills.
- A material supports one or more skills and one or more stages.
- A playlist sequences materials into sessions for a learner.
- An assignment instantiates one playlist for one learner.
- A session produces evidence.
- Evidence updates progress.

## File Ownership

- `content/library/registry.yaml`
- `content/library/{subject}/{area}/{pathway}/pathway.md`
- `content/library/{subject}/{area}/{pathway}/stages/*.md`
- `content/library/{subject}/{area}/{pathway}/skills/*.md`
- `content/library/{subject}/{area}/{pathway}/playlists/*.md`
- `content/library/{subject}/{area}/{pathway}/materials/*.md`

The pathway directory is the canonical authored source for cleaned curriculum slices.

## Product Rules

- Track learner progress at the skill level, not at the material level.
- Use pathways for the whole route and playlists for the directly assignable block.
- Use stages for learning progression, not for age bands or one-off session events.
- Keep age or school-year guidance on pathways and playlists as entry guidance.
- Keep materials reusable. A playlist should reference materials; it should not contain curriculum data that belongs in skills or stages.
- Keep subject and area visible in authoring and browsing surfaces. They are stable navigation boundaries.

## What We Do Not Model

- No mandatory `program` object.
- No vague planning object that duplicates pathway, playlist, or assignment responsibilities.
- No `capability`, `milestone`, `resource`, or `plan template` aliases.
- No separate progress object for every worksheet or page.

## Operational Notes

- Review queues or reminders can exist as derived runtime helpers.
- They are downstream of progress, not part of the core curriculum model.
- The runtime loader reads directly from `content/library/`.
