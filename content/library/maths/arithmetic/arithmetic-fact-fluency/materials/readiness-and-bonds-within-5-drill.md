---
id: readiness_and_bonds_within_5_drill
type: drill
stage_ids:
  - readiness_and_bonds_within_5
skill_ids:
  - count_small_groups_within_5
  - number_bonds_within_5
  - add_and_subtract_within_5
estimated_minutes: 6
runtime:
  engine_id: arithmetic_fact_fluency.v1
  spec_version: 1
  template_id: readiness_within_5
  parameters:
    question_count: 12
    item_forms:
      - count_group
      - bond_missing
      - addition
      - subtraction
  scoring:
    pass_accuracy: 0.8
    soft_time_limit_seconds: 120
  persistence:
    store_response_log: false
    store_summary: true
---

# Readiness And Bonds Within 5 Drill

Use this after the learner has already handled real objects, fingers, or buttons.

The live drill should stay short and calm. It should mix tiny counting, make-5 items, and simple add-or-take-away facts without turning into a long pressured test.

Run one short round, then stop and talk about any misses. If the learner starts guessing or freezing, return to real objects instead of repeating the drill again and again.