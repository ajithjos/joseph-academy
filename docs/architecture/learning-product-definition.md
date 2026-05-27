# Cornerstone Product Definition

Status: **CANONICAL DOMAIN MODEL**
Last updated: 2026-05-27.

## Purpose

This document defines Cornerstone in product terms rather than implementation terms.

It answers:

- what Cornerstone is really for
- which objects are first-class
- which objects are static and reusable
- which objects belong to learner runtime state
- which older terms should stop being treated as canonical

## Product Thesis

Cornerstone is a repeatable learning system for coach-led practice.

The core idea is simple:

- author a reusable learning program once
- run it many times with real learners
- adapt pace, review, and assignment per learner from evidence

In the first deployment, the coach is a parent and the learners are children in one household.
Later, the same model should work for tutors, schools, cohorts, adult learners, sports coaching, music practice, and language learning.

Cornerstone is not primarily:

- a free-form tutor chatbot
- a one-off worksheet dump
- a generic LMS clone
- a content generator inside the runtime app

Cornerstone is primarily:

- a library of reusable learning programs
- a runtime for assigning those programs to learners
- an evidence-driven review loop that decides what to repeat next

## Product Principles

- authored curriculum is static and reusable
- learner progress is dynamic and learner-specific
- progress should be based on evidence, not content consumption alone
- the vocabulary should stay human-meaningful to parents, tutors, and operators
- the model should work for maths, reading, pronunciation, music, sports, and similar skill domains

## The Three Product Layers

### 1. Curriculum Layer

This is the reusable authored system.

It defines:

- what the learner is trying to achieve
- how that journey is broken into checkpoints and skills
- what static resources exist
- which repeatable playlists should be run

This layer is repo-owned.

### 2. Delivery Layer

This is the coach-facing operating layer.

It decides:

- which playlist to assign now
- which resources to run today
- when to repeat, pause, simplify, or advance

This layer mixes static definitions with dynamic judgment.

### 3. Runtime Layer

This is the learner-specific state.

It records:

- who the learner is
- what has been assigned
- what happened in sessions
- what evidence was collected
- which skills and checkpoints are secure, weak, or due for review

This layer belongs in the application database.

## Canonical First-Class Objects

The following should be the stable product vocabulary.

| Object | Layer | Meaning | Example |
| --- | --- | --- | --- |
| Domain | Curriculum | Broad learning area. | Maths, English reading, basketball, guitar |
| Program Brief | Curriculum authoring input | A plain-English design brief for one reusable program. | Age-10 arithmetic foundations |
| Program | Curriculum | A reusable package for one audience and one outcome. | Arithmetic Foundations Core |
| Checkpoint | Curriculum | A parent-facing stage or proficiency checkpoint inside a program. | Fact Fluency to 10 |
| Skill | Curriculum | The smallest measurable skill that changes assignment or review decisions. | Recall multiplication facts for 6 to 9 |
| Resource | Curriculum | One reusable artifact such as a worksheet, prompt, passage, script, or check. | Mixed drill sheet 01 |
| Playlist | Curriculum and delivery | A repeatable ordered session sequence using real resources. | 14-day fact fluency starter |
| Learner Profile | Runtime | The learner's identity, baseline, and constraints. | Ajay, age 10, weak recall speed |
| Assignment | Runtime | A learner-specific instance of a program or playlist. | Ajay assigned fact fluency starter |
| Session | Runtime | One dated run of planned work. | 2026-05-27 evening practice |
| Evidence | Runtime | The recorded result of a session, check, or observation. | 34 correct in 3 minutes, weak on 7s |
| Progress Record | Runtime | Current state for skills and checkpoints. | Multiplication facts weak, addition facts secure |

## Naming Policy

Some existing terms are usable as compatibility aliases, but they should no longer be treated as the main vocabulary.

- use `program`, not `track`, for the reusable curriculum slice
- use `checkpoint` as the human-facing term; the current repo file is still `milestones.yaml`
- use `skill` as the human-facing term; the current repo file is still `capabilities.yaml`
- use `playlist` as the human-facing term; the current repo file is still `plan_templates.yaml`
- use `resource` as the umbrella term; `content item` remains an acceptable implementation alias
- use `target outcome` as a field inside the program brief, not as a separate product object
- treat `achievement` as a derived report or badge, not as a core authored object

This matters because the old set made one term do multiple jobs.

For example:

- `track` sometimes meant an authored curriculum slice
- `track` sometimes meant the learner's current path
- `milestone` sometimes meant a stage and sometimes a completion event
- `plan` sometimes meant a reusable template and sometimes a learner-specific assignment

The new model removes that ambiguity.

## Object Relationships

- a domain can contain many programs
- a program is authored from one program brief
- a program contains checkpoints, skills, resources, and playlists
- a checkpoint groups skills and defines what "secure enough to move on" means
- a resource supports one or more skills and one or more checkpoints
- a playlist orders resources and checks into repeatable sessions
- an assignment instantiates a playlist or program for one learner
- sessions produce evidence
- evidence updates progress records for skills and checkpoints

## What Lives In Repo Files

Repo files should define reusable curriculum.

That includes:

- domains and subjects
- program briefs or equivalent authoring notes
- checkpoints
- skills
- resources and their indexes
- playlists
- operator notes and review criteria

These artifacts should be created offline, reviewed by a human, and committed to the repo.

## What Lives In Runtime State

The runtime product should own:

- teams, users, and learner profiles
- assignments and dated plans
- sessions and attempts
- evidence and review notes
- current progress state per learner
- parent-facing next actions

The runtime product should not be the source of truth for curriculum generation in the MVP.

That is the main system boundary:

- repo files define what can be taught
- runtime state records what happened for a learner

## Recommended Surfaces

The product should eventually expose four clear surfaces.

### 1. Library Surface

Browse reusable domains, programs, checkpoints, resources, and playlists.

### 2. Coach Surface

Assign playlists, run sessions, record evidence, and decide what to repeat next.

### 3. Learner Surface

Show only today's work, the current resource, and simple completion flow.

### 4. Review Surface

Show weak skills, secure checkpoints, recent evidence, and recommended next actions.

## Example: Age-10 Maths Foundations

The user request that triggered this clarification is a good example.

Do not model the whole need as one capability.
Do not treat every worksheet as a milestone.

Model it as one program.

### Program Brief

- domain: maths
- audience: age-10 learner who is weak on arithmetic fundamentals
- target outcome: secure fact fluency to 10 and dependable written whole-number operations
- cadence: 15-minute daily sessions
- coach: parent-led home practice

### Program

`arithmetic_foundations_core`

### Checkpoints

- fact fluency to 10
- written addition and subtraction
- written multiplication and division
- extension foundations later, such as negatives and fractions

### Skills Under Those Checkpoints

- addition facts recall
- subtraction facts recall
- multiplication facts recall
- division facts recall
- column addition with carrying
- column subtraction with borrowing
- 2-digit by 1-digit multiplication
- short division with remainders

### Resources

- timed facts drill sheets
- mixed inverse-operation drills
- worked-example teaching cards
- parent checkpoint sheets
- short written-operation worksheets

### Playlists

- 14-day fact fluency starter
- 10-day written addition and subtraction
- 10-day written multiplication and division

This same model also works for other domains.

Examples:

- reading: program -> decoding and read-aloud checkpoints -> phonics and fluency skills -> passages and prompts -> daily reading playlist
- pronunciation: program -> vowel accuracy and word stress checkpoints -> sound-production skills -> recording prompts and listening checks -> weekly practice playlist
- basketball: program -> ball handling and finishing checkpoints -> dribbling and footwork skills -> drill cards and coach prompts -> training playlist

## What Should Not Be First-Class Yet

Do not rush these into the core model unless real operating pain proves they are necessary.

- badges or achievements
- detailed standards frameworks
- lesson-level taxonomies deeper than skills
- automatic mastery claims from a single activity
- complex multi-tenant institution objects for the household MVP

These can be added later if they become operationally necessary.

## Compatibility With The Current Repo

The current repo can adopt the new vocabulary without immediate file renames.

- `content/catalog/subjects.yaml` currently represents domains
- `content/catalog/capabilities.yaml` currently stores skills
- `content/catalog/milestones.yaml` currently stores checkpoints
- `content/catalog/content_index.yaml` and `content/library/**/*.md` currently store resources
- `content/catalog/plan_templates.yaml` currently stores playlists

There is no dedicated `programs.yaml` yet.

For now, one program is represented across its checkpoints, skills, resources, and playlists, plus a design brief in docs or operator notes.
If the model holds up in practice, adding a dedicated program catalog later will be justified.

## AI Authoring Workflow

For AI-assisted authoring, the clean sequence should be:

1. fill a program brief
2. ask for a program map with checkpoints and skills
3. generate resources against those skills
4. assemble playlists from real resource ids
5. review the slice as a human
6. assign it to learners and collect evidence
7. refine only where evidence shows weak spots or bad pacing

That workflow keeps the static curriculum reusable and keeps runtime adaptation grounded in real learner evidence.
