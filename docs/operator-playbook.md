# Cornerstone Operating Playbook

This is the shortest path to using Cornerstone without rediscovering the repo each time.

Use it when you are acting as:

- operator or maintainer: you define the teaching model in repo files
- owner or parent: you assign plans, run sessions, and record outcomes
- learner or student: you complete the current session

## What Cornerstone Is

Cornerstone is a repeatable learning control plane.

It is not an in-product curriculum generator.

The core rule is:

- repo files define programs, checkpoints, skills, playlists, and resources
- Postgres stores learner-specific runtime state
- Flutter is the runtime UI
- Docusaurus is the browse-only catalog surface

Compatibility note:

- `skills` currently live in `capabilities.yaml`
- `checkpoints` currently live in `milestones.yaml`
- `playlists` currently live in `plan_templates.yaml`
- `resources` currently live in `content_index.yaml` and `content/library/`

Canonical background documents:

- [Product definition](./architecture/learning-product-definition.md)
- [Simple content model](./authoring/simple-content-model.md)
- [Program brief template](./authoring/program-brief-template.md)
- [Program authoring brief](./authoring/track-authoring-brief.md)
- [Content authoring rules](./authoring/ai-content-generation-contract.md)
- [Copy-paste authoring prompts](./authoring/repeatable-prompts.md)

## Surfaces To Use Right Now

- `http://127.0.0.1:8080`: Flutter runtime for owner and learner workflows
- `http://127.0.0.1:8080/content/`: generated browse-only content site
- `http://127.0.0.1:8788`: Rust API and service index
- `http://127.0.0.1:3001`: developer-flavor docs site with the repo `docs/` tree included

Bring the local stack up with:

```bash
source sourceme_dev
make install-dev
make control-plane-compose-up
```

Use `make docs-site-dev` when you want the developer docs surface instead of only the production-style content site.

## Roles And The Normal Flow

### Operator Or Maintainer

You work in the repo.

Your job is to:

- define or change `content/catalog/*.yaml`
- write or replace `content/library/**/*.md`
- keep `deploy/config/runtime_defaults/identity_bootstrap.yaml` aligned with the household or team
- validate catalogs and reload them into the control plane

This role creates the teaching model.
It does not create learner progress directly.

### Owner Or Parent

You work in the Flutter app.

Your loop is:

1. pick a learner
2. assign a playlist
3. run today's session with the child
4. record score, time, and notes
5. check skill and checkpoint states plus the review queue
6. repeat, pause, or switch playlists

### Learner Or Student

The learner only needs the next session and its linked content item.

In the MVP, the child-facing path is:

1. open the learner surface in the Flutter app
2. follow the current session
3. complete the linked worksheet, note, or activity
4. hand control back to the owner for recording

## Where The Source Of Truth Lives

- household and role bootstrap: `deploy/config/runtime_defaults/identity_bootstrap.yaml`
- subjects, skills, checkpoints, playlists, and resource index: `content/catalog/`
- actual worksheets, notes, and reading material: `content/library/`
- generated browse docs: `docs_site/docs/generated/` and `docs_site/docs/library/`
- runtime learner state: Postgres, not repo files

## The Repeatable Authoring Loop

Use this whenever you want to create a new program such as age-10 arithmetic foundations.

1. Define the program brief.
   Write one plain-English goal, audience, age or level, cadence, and constraints.
   Example: age-10 learner reaches dependable arithmetic fundamentals through 15-minute daily sessions with parent-led practice.

2. Define the checkpoints.
   This is the main static map of the program.
   For many new programs, 3 to 5 checkpoints is enough.

3. Add skills only where finer tracking is useful.
   A checkpoint may begin with one matching skill.
   Split further only when that changes practice or review decisions.

4. Generate or write resources.
   Add markdown files under `content/library/...`.
   Register each file in `content/catalog/content_index.yaml`.

5. Build one or more playlists.
   Add executable short-session sequences in `content/catalog/plan_templates.yaml`.
   Every session must point to real `content_ids`.

6. Validate and browse.

```bash
make control-plane-catalog-reload
make docs-site-dev
```

Use the content site to inspect the generated catalog and content pages.

7. Run it with a learner.
   Open the Flutter app, assign the playlist, run sessions, and record results.

8. Refine from evidence.
   Adjust resources, playlists, or skill boundaries based on what the learner actually struggles with.

## Replacing The Current Starter Content

The current maths and English material is starter content.
Treat it as replaceable reference material, not as untouchable system data.

The safest replacement strategy is:

1. add one new coherent slice first
2. validate that slice
3. assign only the new playlists
4. remove old sample catalog entries and markdown files after nothing depends on them

Avoid deleting everything in one pass, because playlists, content ids, checkpoints, and skills cross-reference each other.

If you want a true local restart of runtime state as well as content experimentation:

```bash
make control-plane-compose-reset
make control-plane-compose-up
```

That reset deletes local Postgres data after confirmation.

## LLM Workflow

Use an LLM to generate file-owned definitions, not runtime state.

The mental model lives in [Simple content model](./authoring/simple-content-model.md).
The fillable author input lives in [Program brief template](./authoring/program-brief-template.md).
The one-file attachable brief lives in [Program authoring brief](./authoring/track-authoring-brief.md).
The rules live in [Content authoring rules](./authoring/ai-content-generation-contract.md).
The reusable prompts live in [Copy-paste authoring prompts](./authoring/repeatable-prompts.md).

If you want the smallest workable setup, fill the program brief template, attach the program authoring brief, and give the filled brief in your own message.
If the model needs more conceptual context, attach the simple content model as the second file.

Recommended working order for an agent:

1. skills
2. checkpoints
3. resource index and markdown files
4. playlists
5. human review and catalog reload

If you want one prompt to start a whole authoring round, start with Prompt 1 in the repeatable prompts doc, then move to Prompt 2 once the structure is agreed.

For a large program, use Prompt 1 to settle the structure first, then use Prompt 3 once per resource file.

## Minimum Files To Touch For A New Program

- `content/catalog/capabilities.yaml`
- `content/catalog/milestones.yaml`
- `content/catalog/plan_templates.yaml`
- `content/catalog/content_index.yaml`
- one or more markdown files under `content/library/{subject}/...`

## Practical Example

For the goal build dependable arithmetic fundamentals at age 10, the repo-first attack is:

1. treat that goal as one program, not as one skill
2. define checkpoints such as fact fluency, written addition and subtraction, and written multiplication and division
3. start with broad skills inside each checkpoint unless practice needs finer splits
4. write short worksheets, mixed drills, and parent checkpoint sheets
5. create one or more 2-to-4 week playlists with daily sessions
6. validate, browse, assign, and iterate

The important rule is that Cornerstone is built around authored programs, not open-ended ad hoc tutoring.
Once the authored program is in the repo, the app becomes the runtime for delivering and measuring it.