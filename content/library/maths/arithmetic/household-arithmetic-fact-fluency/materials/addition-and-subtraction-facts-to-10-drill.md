---
id: addition_and_subtraction_facts_to_10_drill
type: drill
stage_ids:
  - addition_and_subtraction_facts_to_10
skill_ids:
  - number_bonds_within_10
  - add_within_10
  - subtract_within_10
estimated_minutes: 7
runtime:
  engine_id: arithmetic_fact_fluency.v1
  spec_version: 1
  template_id: mixed_add_sub_to_10
  parameters:
    question_count: 14
    operations:
      - addition
      - subtraction
    prompt_forms:
      - equation
      - bond_missing
  scoring:
    pass_accuracy: 0.85
    soft_time_limit_seconds: 150
  persistence:
    store_response_log: false
    store_summary: true
---

# Addition And Subtraction Facts To 10 Drill

Use this once the learner can already say most pairs to 10 and needs mixed live recall.

The app should generate a short mixed run of addition, subtraction, and make-10 prompts so the learner has to recognise the fact family instead of staying inside one narrow pattern.