---
id: addition_and_subtraction_facts_to_10_check
type: quick_check
stage_ids:
  - addition_and_subtraction_facts_to_10
skill_ids:
  - number_bonds_within_10
  - add_within_10
  - subtract_within_10
estimated_minutes: 5
runtime:
  engine_id: arithmetic_fact_fluency.v1
  spec_version: 1
  template_id: mixed_add_sub_to_10
  parameters:
    question_count: 10
    operations:
      - addition
      - subtraction
    item_forms:
      - equation
      - bond_missing
  scoring:
    pass_accuracy: 0.8
    soft_time_limit_seconds: 90
  persistence:
    store_response_log: false
    store_summary: true
---

# Addition And Subtraction Facts To 10 Check

Keep the check short. Do not coach during the answers.

1. `8 + 2 =`
2. `10 - 6 =`
3. `4 + 5 =`
4. `7 - 3 =`
5. `__ + 1 = 10`
6. `6 + 3 =`
7. `9 - 2 =`
8. `5 + __ = 10`
9. `8 - 5 =`
10. `3 + 6 =`

Passing guide: 8 or more quick correct answers means the learner is ready for facts through 20. If the misses cluster around one or two bonds, repair those first rather than repeating the whole playlist from the start.