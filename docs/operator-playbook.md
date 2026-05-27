# Cornerstone Operating Playbook

This is the shortest path to using Cornerstone without rediscovering the repo each time.

Use it when you are acting as:

- operator or maintainer: you define the teaching model in repo files
- owner or parent: you assign plans, run sessions, and record outcomes
- learner or student: you complete the current session

## What Cornerstone Is

Cornerstone is a learning control plane.

It is not an in-product curriculum generator.

The core rule is:

- repo files define capabilities, milestones, plan templates, and content
- Postgres stores learner-specific runtime state
- Flutter is the runtime UI
- Docusaurus is the browse-only catalog surface

Canonical background documents:

- [Product definition](./architecture/learning-product-definition.md)
- [Simple content model](./authoring/simple-content-model.md)
- [Track authoring brief](./authoring/track-authoring-brief.md)
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
2. assign a plan template
3. run today's session with the child
4. record score, time, and notes
5. check capability states and the review queue
6. repeat, pause, or switch plans

### Learner Or Student

The learner only needs the next session and its linked content item.

In the MVP, the child-facing path is:

1. open the learner surface in the Flutter app
2. follow the current session
3. complete the linked worksheet, note, or activity
4. hand control back to the owner for recording

## Where The Source Of Truth Lives

- household and role bootstrap: `deploy/config/runtime_defaults/identity_bootstrap.yaml`
- subjects, capabilities, milestones, plans, and content index: `content/catalog/`
- actual worksheets, notes, and reading material: `content/library/`
- generated browse docs: `docs_site/docs/generated/` and `docs_site/docs/library/`
- runtime learner state: Postgres, not repo files

## The Repeatable Authoring Loop

Use this whenever you want to create a new track such as age-10 arithmetic fundamentals.

1. Define the target outcome.
   Write one plain-English goal, age, level, and session shape.
   Example: age-10 learner reaches strong fluency in addition, subtraction, multiplication, and division fundamentals through 15-minute daily sessions.

2. Define the milestone sub-tracks.
   This is the main static map of the track.
   For many new tracks, 3 to 6 milestones is enough.

3. Add capabilities only where finer tracking is useful.
   A milestone may begin with one matching capability.
   Split further only when that changes practice or review decisions.

4. Generate or write content items.
   Add markdown files under `content/library/...`.
   Register each file in `content/catalog/content_index.yaml`.

5. Build a static plan template.
   Add an executable short-session plan in `content/catalog/plan_templates.yaml`.
   Every session must point to real `content_ids`.

6. Validate and browse.

```bash
make control-plane-catalog-reload
make docs-site-dev
```

Use the content site to inspect the generated catalog and content pages.

7. Run it with a learner.
   Open the Flutter app, assign the plan, run sessions, and record results.

8. Refine from evidence.
   Adjust content, plans, or capability boundaries based on what the learner actually struggles with.

## Replacing The Current Starter Content

The current maths and English material is starter content.
Treat it as replaceable reference material, not as untouchable system data.

The safest replacement strategy is:

1. add one new coherent slice first
2. validate that slice
3. assign only the new plan templates
4. remove old sample catalog entries and markdown files after nothing depends on them

Avoid deleting everything in one pass, because plan templates, content ids, and milestones cross-reference each other.

If you want a true local restart of runtime state as well as content experimentation:

```bash
make control-plane-compose-reset
make control-plane-compose-up
```

That reset deletes local Postgres data after confirmation.

## LLM Workflow

Use an LLM to generate file-owned definitions, not runtime state.

The mental model lives in [Simple content model](./authoring/simple-content-model.md).
The one-file attachable brief lives in [Track authoring brief](./authoring/track-authoring-brief.md).
The rules live in [Content authoring rules](./authoring/ai-content-generation-contract.md).
The reusable prompts live in [Copy-paste authoring prompts](./authoring/repeatable-prompts.md).

If you want the smallest workable setup, attach the track authoring brief and give the target outcome in your own message.
If the model needs more conceptual context, attach the simple content model as the second file.

Recommended working order for an agent:

1. capabilities
2. milestones
3. content index and markdown files
4. plan template
5. human review and catalog reload

If you want one prompt to start a whole authoring round, use the Track Authoring Round prompt in the repeatable prompts doc.

For a large track, use that prompt to scaffold the whole round first, then use the markdown-item prompt once per content file.

## Minimum Files To Touch For A New Track

- `content/catalog/capabilities.yaml`
- `content/catalog/milestones.yaml`
- `content/catalog/plan_templates.yaml`
- `content/catalog/content_index.yaml`
- one or more markdown files under `content/library/{subject}/...`

## Practical Example

For the goal master the addition, subtraction, multiplication, and division fundamentals at age 10, the repo-first attack is:

1. treat that goal as a track outcome, not as one capability
2. define four milestone sub-tracks: addition, subtraction, multiplication, and division fluency
3. start with one broad capability inside each milestone unless practice needs finer splits
4. write short worksheets, mixed drills, and parent checkpoint notes
5. create a 2-to-4 week static plan template with daily sessions
6. validate, browse, assign, and iterate

The important rule is that Cornerstone is built around authored tracks, not open-ended ad hoc tutoring.
Once the authored track is in the repo, the app becomes the runtime for delivering and measuring it.