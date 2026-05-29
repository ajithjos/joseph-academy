# Runtime Program Contract

This is the developer contract for live materials.

It explains exactly:

- where the runtime program lives
- how a material chooses that program
- what input the program receives
- what output it must return
- where to add new runtime programs or new templates

This document is intentionally about code and contracts, not product notes.

## The Two Contracts

Cornerstone has two separate contracts for live materials.

### 1. Authored material contract

The material file declares which approved runtime program to use.

Example:

```yaml
runtime:
  engine_id: arithmetic_fact_fluency.v1
  spec_version: 1
  template_id: mixed_add_sub_to_10
  parameters:
    operations: [addition, subtraction]
    item_forms: [equation, bond_missing]
    question_count: 10
  scoring:
    pass_accuracy: 0.85
    soft_time_limit_seconds: 120
  persistence:
    store_response_log: false
    store_summary: true
```

This does not contain executable code.

It only identifies an approved runtime program and passes configuration into it.

### 2. Runtime program contract

The backend owns the actual executable program.

That program is registered in Rust and must support:

- generation from `MaterialRuntime` plus a seed
- scoring from the generated activity plus learner responses

In the current codebase this contract lives in:

- `rust/crates/control_plane/src/runtime/mod.rs`

The main registration type is `RuntimeProgramRegistration`.

## Runtime ID

Cornerstone now uses an explicit runtime id:

```text
{engine_id}/{template_id}
```

Example:

```text
arithmetic_fact_fluency.v1/mixed_add_sub_to_10
```

That runtime id is:

- the stable identifier for one executable runtime program
- derived from authored content
- used by the backend registry to resolve the correct program
- returned in session runtime summaries and activity instances for debugging and inspection

The code layout should mirror that contract.

For example, the runtime id `arithmetic_fact_fluency.v1/mixed_add_sub_to_10` is implemented under:

- `rust/crates/control_plane/src/runtime/arithmetic_fact_fluency_v1/`
- `rust/crates/control_plane/src/runtime/arithmetic_fact_fluency_v1/mixed_add_sub_to_10.rs`

## Where The Code Lives

The current separation is:

- `rust/crates/control_plane/src/service.rs`: session orchestration, evidence persistence, assignment flow, activity start and complete endpoints
- `rust/crates/control_plane/src/runtime/mod.rs`: runtime registry, runtime id helpers, generated/scored activity contracts, dispatch
- `rust/crates/control_plane/src/runtime/arithmetic_fact_fluency_v1/`: the current arithmetic engine folder, with one file per runtime template plus shared helpers

This means `service.rs` no longer contains the runtime implementation details. It only orchestrates session state and calls the runtime registry.

## The Runtime Program Interface

The backend runtime layer currently works around these explicit types.

### Program registration

Each runtime program is registered as a `RuntimeProgramRegistration` with:

- `runtime_id`
- `engine_id`
- `template_id`
- `generate`
- `score`

### Generate contract

The generate function signature is effectively:

```rust
fn generate(runtime: &MaterialRuntime, seed: u64) -> anyhow::Result<GeneratedActivity>
```

It receives:

- the authored runtime block
- a seed for deterministic item generation

It must return a `GeneratedActivity` containing:

- `runtime_id`
- `engine_id`
- `template_id`
- `instructions`
- `items`
- scoring thresholds
- persistence flags

### Score contract

The score function signature is effectively:

```rust
fn score(generated: &GeneratedActivity, responses: &[ActivityResponseInput]) -> ScoredActivity
```

It receives:

- the already generated activity
- the learner responses

It returns:

- attempted count
- correct count
- item count
- accuracy
- pass or fail
- completion reason
- weak groups
- response log when needed

## Actual Execution Flow

This is the real backend execution path.

### Start flow

1. `start_session_material_activity` loads the current session material.
2. It loads the authored material from the library bundle.
3. It calls `runtime::generate_activity(material, seed)`.
4. `runtime::resolve_program` matches `engine_id` plus `template_id` to a registered runtime program.
5. The selected program's `generate` function runs.
6. The backend returns an `ActivityInstance` with `runtime_id`, items, instructions, and scoring settings.

### Complete flow

1. `complete_activity_instance` parses the activity instance id.
2. It loads the same authored material again.
3. It regenerates the same activity from the stored seed.
4. It calls `runtime::score_activity(...)`.
5. The selected program's `score` function runs.
6. The backend persists evidence and updates learner progress.

The key point is this:

- `service.rs` decides session lifecycle
- the runtime module decides which program runs
- the engine module implements the actual program

## Worked Example

Use this real example.

Material file:

- `content/library/maths/arithmetic/arithmetic-fact-fluency/materials/addition-and-subtraction-facts-to-10-check.md`

That material declares:

- `engine_id: arithmetic_fact_fluency.v1`
- `template_id: mixed_add_sub_to_10`

That resolves to runtime id:

```text
arithmetic_fact_fluency.v1/mixed_add_sub_to_10
```

The runtime registry then dispatches to the registered arithmetic runtime program in:

- `rust/crates/control_plane/src/runtime/arithmetic_fact_fluency_v1/mixed_add_sub_to_10.rs`

Specifically, the program entry is the one whose registration matches:

- `engine_id = arithmetic_fact_fluency.v1`
- `template_id = mixed_add_sub_to_10`

That registration uses:

- `generate_add_sub_to_10_activity`
- `score_integer_activity`

So the content file chooses the program, but the Rust module implements the program.

## How To Add Something New

Use these rules.

### Case 1: Add a new live material using an existing runtime program

Do this when the program already exists and you only need a new material variation.

Steps:

1. Add or edit the material markdown file.
2. Use an already registered `engine_id` and `template_id`.
3. Adjust parameters and scoring.
4. Add the material to a playlist session.
5. Validate content.

No Rust changes are needed.

### Case 2: Add a new template inside an existing engine

Do this when the engine is the same, but you need a new runtime variation.

Steps:

1. Add a new generate function in the engine folder, for example in `runtime/arithmetic_fact_fluency_v1/`.
2. Reuse an existing score function or add a new one if needed.
3. Register the new program in that module's `PROGRAMS` list.
4. Choose a new `template_id`.
5. Author materials that reference that new `template_id`.
6. Add unit tests for registry resolution and deterministic generation.

### Case 3: Add a new engine

Do this when the interaction model or scoring model is genuinely different.

Steps:

1. Create a new engine module under `rust/crates/control_plane/src/runtime/`.
2. Define one or more `RuntimeProgramRegistration` entries.
3. Implement the generate and score functions.
4. Register those programs through `runtime/mod.rs`.
5. Author materials that use the new `engine_id` and `template_id` values.
6. Extend frontend rendering only if the item shape requires it.

## What Content Authors Need To Know

Content authors only need to know:

- which `engine_id` values are supported
- which `template_id` values are supported inside that engine
- which parameter names are accepted
- what the scoring fields mean

For example, `item_forms` is just a parameter name passed into the runtime program. It is not a framework or magic runtime feature.

Content authors do not need to know session persistence internals or every function in the control plane.

## What Developers Need To Know

Developers adding a new runtime program need to know:

- where runtime programs are registered
- the generate and score function contract
- how runtime ids are formed
- how to keep generation deterministic from a seed
- how to test the new program

If a developer is also the content author, they can do both layers of work. But they should still treat them as two separate contracts: authored configuration and executable backend code.