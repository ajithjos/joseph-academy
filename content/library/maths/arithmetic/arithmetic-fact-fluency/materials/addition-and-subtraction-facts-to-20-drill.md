---
id: addition_and_subtraction_facts_to_20_drill
type: drill
stage_ids:
  - addition_and_subtraction_facts_to_20
skill_ids:
  - number_bonds_within_20
  - add_within_20
  - subtract_within_20
  - missing_number_addition_and_subtraction_within_20
estimated_minutes: 8
runtime:
  engine_id: arithmetic_fact_fluency.v1
  spec_version: 1
  template_id: mixed_add_sub_to_20
  parameters:
    question_count: 16
    operations:
      - addition
      - subtraction
    item_forms:
      - equation
      - bond_missing
      - missing_subtraction
  scoring:
    pass_accuracy: 0.85
    soft_time_limit_seconds: 180
  persistence:
    store_response_log: false
    store_summary: true
---

# Addition And Subtraction Facts To 20 Drill

Use this when facts to 10 are steady and the learner needs short live practice on teen numbers and missing-number items.

The drill should stay mixed. It should not become a block of only addition or only subtraction because the point is flexible recall under light pressure.

Run the drill after a clear teaching session, not as a substitute for one. Review the misses straight away and group them by pattern: bonds to `20`, bridge-through-`10` facts, or missing-number prompts.