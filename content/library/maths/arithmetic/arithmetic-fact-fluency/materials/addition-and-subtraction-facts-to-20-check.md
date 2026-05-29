---
id: addition_and_subtraction_facts_to_20_check
type: quick_check
stage_ids:
  - addition_and_subtraction_facts_to_20
skill_ids:
  - number_bonds_within_20
  - add_within_20
  - subtract_within_20
  - missing_number_addition_and_subtraction_within_20
estimated_minutes: 5
runtime:
  engine_id: arithmetic_fact_fluency.v1
  spec_version: 1
  template_id: mixed_add_sub_to_20
  parameters:
    question_count: 10
    operations:
      - addition
      - subtraction
    item_forms:
      - equation
      - bond_missing
      - missing_subtraction
  scoring:
    pass_accuracy: 0.8
    soft_time_limit_seconds: 120
  persistence:
    store_response_log: false
    store_summary: true
---

# Addition And Subtraction Facts To 20 Check

Keep this mixed and brisk. Do not rescue the learner during the answers.

1. `12 + 7 =`
2. `20 - 9 =`
3. `__ + 5 = 20`
4. `14 - 6 =`
5. `9 + 9 =`
6. `17 - 8 =`
7. `13 + 6 =`
8. `20 - __ = 3`
9. `11 + 8 =`
10. `16 - 7 =`

Passing guide: 8 or more quick correct answers means the learner is ready for multiplication foundations. If the learner is accurate but very slow, repeat one more mixed drill before moving on.