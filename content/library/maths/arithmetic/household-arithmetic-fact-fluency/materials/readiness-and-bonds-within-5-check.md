---
id: readiness_and_bonds_within_5_check
type: quick_check
stage_ids:
  - readiness_and_bonds_within_5
skill_ids:
  - count_small_groups_within_5
  - number_bonds_within_5
  - add_and_subtract_within_5
estimated_minutes: 5
runtime:
  engine_id: arithmetic_fact_fluency.v1
  spec_version: 1
  template_id: readiness_within_5
  parameters:
    question_count: 10
    item_forms:
      - count_group
      - bond_missing
      - addition
      - subtraction
  scoring:
    pass_accuracy: 0.8
    soft_time_limit_seconds: 90
  persistence:
    store_response_log: false
    store_summary: true
---

# Readiness And Bonds Within 5 Check

Ask the learner to answer quickly.

1. `2 and __ make 5`
2. `5 - 1 =`
3. `3 + 1 =`
4. `4 and __ make 5`
5. `5 - 3 =`
6. `2 + 2 =`
7. `Show 4 on your fingers`
8. `1 + 4 =`
9. `5 - 4 =`
10. `How many are missing from 5 if you already have 3?`

Passing guide: 8 or more quick correct answers means the learner is ready to move on.