use std::collections::{BTreeMap, BTreeSet};

use anyhow::bail;
use catalog::MaterialRuntime;
use serde_json::json;

use crate::domain::ActivityResponseInput;

use super::{GeneratedActivity, GeneratedPrompt, RuntimeProgramRegistration, ScoredActivity};

const ENGINE_ID: &str = "arithmetic_fact_fluency.v1";
const ANSWER_KIND_INTEGER: &str = "integer";

const READINESS_WITHIN_5_TEMPLATE_ID: &str = "readiness_within_5";
const MIXED_ADD_SUB_TO_10_TEMPLATE_ID: &str = "mixed_add_sub_to_10";
const MIXED_ADD_SUB_TO_20_TEMPLATE_ID: &str = "mixed_add_sub_to_20";

const READINESS_WITHIN_5_RUNTIME_ID: &str = "arithmetic_fact_fluency.v1/readiness_within_5";
const MIXED_ADD_SUB_TO_10_RUNTIME_ID: &str = "arithmetic_fact_fluency.v1/mixed_add_sub_to_10";
const MIXED_ADD_SUB_TO_20_RUNTIME_ID: &str = "arithmetic_fact_fluency.v1/mixed_add_sub_to_20";

pub const PROGRAMS: &[RuntimeProgramRegistration] = &[
    RuntimeProgramRegistration {
        runtime_id: READINESS_WITHIN_5_RUNTIME_ID,
        engine_id: ENGINE_ID,
        template_id: READINESS_WITHIN_5_TEMPLATE_ID,
        generate: generate_readiness_activity,
        score: score_integer_activity,
    },
    RuntimeProgramRegistration {
        runtime_id: MIXED_ADD_SUB_TO_10_RUNTIME_ID,
        engine_id: ENGINE_ID,
        template_id: MIXED_ADD_SUB_TO_10_TEMPLATE_ID,
        generate: generate_add_sub_to_10_activity,
        score: score_integer_activity,
    },
    RuntimeProgramRegistration {
        runtime_id: MIXED_ADD_SUB_TO_20_RUNTIME_ID,
        engine_id: ENGINE_ID,
        template_id: MIXED_ADD_SUB_TO_20_TEMPLATE_ID,
        generate: generate_add_sub_to_20_activity,
        score: score_integer_activity,
    },
];

#[derive(Debug, Clone)]
struct ActivityRng {
    state: u64,
}

impl ActivityRng {
    fn new(seed: u64) -> Self {
        Self {
            state: if seed == 0 { 1 } else { seed },
        }
    }

    fn next_u32(&mut self) -> u32 {
        self.state = self
            .state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        (self.state >> 32) as u32
    }

    fn index(&mut self, len: usize) -> usize {
        if len <= 1 {
            return 0;
        }
        (self.next_u32() as usize) % len
    }

    fn range_inclusive(&mut self, start: u32, end: u32) -> u32 {
        if start >= end {
            return start;
        }
        start + (self.next_u32() % (end - start + 1))
    }
}

fn generate_readiness_activity(runtime: &MaterialRuntime, seed: u64) -> anyhow::Result<GeneratedActivity> {
    let prompt_count = parameter_usize(runtime, "question_count").unwrap_or(10);
    let mut rng = ActivityRng::new(seed);
    let prompts = generate_readiness_prompts(runtime, prompt_count, &mut rng)?;
    Ok(build_generated_activity(
        runtime,
        seed,
        READINESS_WITHIN_5_RUNTIME_ID,
        activity_instructions(READINESS_WITHIN_5_TEMPLATE_ID),
        prompts,
    ))
}

fn generate_add_sub_to_10_activity(runtime: &MaterialRuntime, seed: u64) -> anyhow::Result<GeneratedActivity> {
    let prompt_count = parameter_usize(runtime, "question_count").unwrap_or(10);
    let mut rng = ActivityRng::new(seed);
    let prompts = generate_add_sub_to_10_prompts(runtime, prompt_count, &mut rng)?;
    Ok(build_generated_activity(
        runtime,
        seed,
        MIXED_ADD_SUB_TO_10_RUNTIME_ID,
        activity_instructions(MIXED_ADD_SUB_TO_10_TEMPLATE_ID),
        prompts,
    ))
}

fn generate_add_sub_to_20_activity(runtime: &MaterialRuntime, seed: u64) -> anyhow::Result<GeneratedActivity> {
    let prompt_count = parameter_usize(runtime, "question_count").unwrap_or(10);
    let mut rng = ActivityRng::new(seed);
    let prompts = generate_add_sub_to_20_prompts(runtime, prompt_count, &mut rng)?;
    Ok(build_generated_activity(
        runtime,
        seed,
        MIXED_ADD_SUB_TO_20_RUNTIME_ID,
        activity_instructions(MIXED_ADD_SUB_TO_20_TEMPLATE_ID),
        prompts,
    ))
}

fn build_generated_activity(
    runtime: &MaterialRuntime,
    seed: u64,
    runtime_id: &str,
    instructions: String,
    prompts: Vec<GeneratedPrompt>,
) -> GeneratedActivity {
    GeneratedActivity {
        seed,
        runtime_id: runtime_id.to_string(),
        engine_id: runtime.engine_id.clone(),
        template_id: runtime.template_id.clone(),
        instructions,
        prompts,
        pass_accuracy: runtime.scoring.as_ref().and_then(|scoring| scoring.pass_accuracy),
        soft_time_limit_seconds: runtime
            .scoring
            .as_ref()
            .and_then(|scoring| scoring.soft_time_limit_seconds),
        store_response_log: runtime
            .persistence
            .as_ref()
            .map(|persistence| persistence.store_response_log)
            .unwrap_or(false),
    }
}

fn activity_instructions(template_id: &str) -> String {
    match template_id {
        READINESS_WITHIN_5_TEMPLATE_ID => {
            "Answer each prompt calmly and say the whole fact if that helps.".to_string()
        }
        MIXED_ADD_SUB_TO_10_TEMPLATE_ID => {
            "Answer each fact in mixed order without counting for every question.".to_string()
        }
        MIXED_ADD_SUB_TO_20_TEMPLATE_ID => {
            "Work through the mixed facts and missing-number prompts without rushing into guesses."
                .to_string()
        }
        _ => "Answer each prompt carefully.".to_string(),
    }
}

fn generate_readiness_prompts(
    runtime: &MaterialRuntime,
    prompt_count: usize,
    rng: &mut ActivityRng,
) -> anyhow::Result<Vec<GeneratedPrompt>> {
    let prompt_forms = parameter_string_list(runtime, "prompt_forms").unwrap_or_else(|| {
        vec![
            "count_group".to_string(),
            "bond_missing".to_string(),
            "addition".to_string(),
            "subtraction".to_string(),
        ]
    });
    generate_unique_prompts(prompt_count, 10, rng, |index, rng| {
        let form = &prompt_forms[rng.index(prompt_forms.len())];
        match form.as_str() {
            "count_group" => {
                let count = rng.range_inclusive(1, 5) as i32;
                let group = std::iter::repeat_n("o", count as usize)
                    .collect::<Vec<_>>()
                    .join(" ");
                integer_prompt(
                    index,
                    format!("Count the group: {group}"),
                    count,
                    "count_small_groups_within_5",
                )
            }
            "bond_missing" => {
                let shown = rng.range_inclusive(1, 4) as i32;
                integer_prompt(
                    index,
                    format!("{shown} and __ make 5"),
                    5 - shown,
                    "number_bonds_within_5",
                )
            }
            "subtraction" => {
                let whole = rng.range_inclusive(2, 5) as i32;
                let part = rng.range_inclusive(1, whole as u32 - 1) as i32;
                integer_prompt(
                    index,
                    format!("{whole} - {part} ="),
                    whole - part,
                    "add_and_subtract_within_5",
                )
            }
            _ => {
                let total = rng.range_inclusive(2, 5) as i32;
                let left = rng.range_inclusive(1, total as u32 - 1) as i32;
                let right = total - left;
                integer_prompt(
                    index,
                    format!("{left} + {right} ="),
                    total,
                    "add_and_subtract_within_5",
                )
            }
        }
    })
}

fn generate_add_sub_to_10_prompts(
    runtime: &MaterialRuntime,
    prompt_count: usize,
    rng: &mut ActivityRng,
) -> anyhow::Result<Vec<GeneratedPrompt>> {
    let prompt_forms = parameter_string_list(runtime, "prompt_forms")
        .unwrap_or_else(|| vec!["equation".to_string(), "bond_missing".to_string()]);
    let operations = parameter_string_list(runtime, "operations")
        .unwrap_or_else(|| vec!["addition".to_string(), "subtraction".to_string()]);
    generate_unique_prompts(prompt_count, 12, rng, |index, rng| {
        let form = &prompt_forms[rng.index(prompt_forms.len())];
        if form == "bond_missing" {
            let shown = rng.range_inclusive(1, 9) as i32;
            let left_blank = rng.index(2) == 0;
            return integer_prompt(
                index,
                if left_blank {
                    format!("__ + {shown} = 10")
                } else {
                    format!("{shown} + __ = 10")
                },
                10 - shown,
                "number_bonds_within_10",
            );
        }

        let operation = &operations[rng.index(operations.len())];
        if operation == "subtraction" {
            let whole = rng.range_inclusive(2, 10) as i32;
            let part = rng.range_inclusive(1, whole as u32 - 1) as i32;
            integer_prompt(
                index,
                format!("{whole} - {part} ="),
                whole - part,
                "subtract_within_10",
            )
        } else {
            let total = rng.range_inclusive(2, 10) as i32;
            let left = rng.range_inclusive(1, total as u32 - 1) as i32;
            let right = total - left;
            integer_prompt(
                index,
                format!("{left} + {right} ="),
                total,
                "add_within_10",
            )
        }
    })
}

fn generate_add_sub_to_20_prompts(
    runtime: &MaterialRuntime,
    prompt_count: usize,
    rng: &mut ActivityRng,
) -> anyhow::Result<Vec<GeneratedPrompt>> {
    let prompt_forms = parameter_string_list(runtime, "prompt_forms").unwrap_or_else(|| {
        vec![
            "equation".to_string(),
            "bond_missing".to_string(),
            "missing_subtraction".to_string(),
        ]
    });
    let operations = parameter_string_list(runtime, "operations")
        .unwrap_or_else(|| vec!["addition".to_string(), "subtraction".to_string()]);
    generate_unique_prompts(prompt_count, 14, rng, |index, rng| {
        let form = &prompt_forms[rng.index(prompt_forms.len())];
        match form.as_str() {
            "bond_missing" => {
                let shown = rng.range_inclusive(1, 19) as i32;
                let left_blank = rng.index(2) == 0;
                integer_prompt(
                    index,
                    if left_blank {
                        format!("__ + {shown} = 20")
                    } else {
                        format!("{shown} + __ = 20")
                    },
                    20 - shown,
                    "number_bonds_within_20",
                )
            }
            "missing_subtraction" => {
                let whole = rng.range_inclusive(10, 20) as i32;
                let remaining = rng.range_inclusive(1, whole as u32 - 1) as i32;
                integer_prompt(
                    index,
                    format!("{whole} - __ = {remaining}"),
                    whole - remaining,
                    "missing_number_addition_and_subtraction_within_20",
                )
            }
            _ => {
                let operation = &operations[rng.index(operations.len())];
                if operation == "subtraction" {
                    let whole = rng.range_inclusive(4, 20) as i32;
                    let part = rng.range_inclusive(1, whole as u32 - 1) as i32;
                    integer_prompt(
                        index,
                        format!("{whole} - {part} ="),
                        whole - part,
                        "subtract_within_20",
                    )
                } else {
                    let total = rng.range_inclusive(4, 20) as i32;
                    let left = rng.range_inclusive(1, total as u32 - 1) as i32;
                    let right = total - left;
                    integer_prompt(
                        index,
                        format!("{left} + {right} ="),
                        total,
                        "add_within_20",
                    )
                }
            }
        }
    })
}

fn generate_unique_prompts(
    prompt_count: usize,
    attempt_multiplier: usize,
    rng: &mut ActivityRng,
    mut builder: impl FnMut(usize, &mut ActivityRng) -> GeneratedPrompt,
) -> anyhow::Result<Vec<GeneratedPrompt>> {
    let mut prompts = Vec::new();
    let mut seen = BTreeSet::new();
    let max_attempts = prompt_count.saturating_mul(attempt_multiplier).max(prompt_count);
    for index in 0..max_attempts {
        if prompts.len() >= prompt_count {
            break;
        }
        let prompt = builder(prompts.len(), rng);
        if seen.insert(prompt.prompt.clone()) {
            prompts.push(prompt);
        }
        if index + 1 == max_attempts && prompts.len() < prompt_count {
            bail!("unable to generate enough unique prompts");
        }
    }
    Ok(prompts)
}

fn parameter_usize(runtime: &MaterialRuntime, key: &str) -> Option<usize> {
    runtime.parameters.get(key)?.as_u64().map(|value| value as usize)
}

fn parameter_string_list(runtime: &MaterialRuntime, key: &str) -> Option<Vec<String>> {
    let values = runtime.parameters.get(key)?.as_array()?;
    let items = values
        .iter()
        .filter_map(|value| value.as_str().map(ToOwned::to_owned))
        .collect::<Vec<_>>();
    if items.is_empty() { None } else { Some(items) }
}

fn integer_prompt(index: usize, prompt: String, answer: i32, family: &str) -> GeneratedPrompt {
    GeneratedPrompt {
        prompt_id: format!("prompt_{index}"),
        prompt,
        answer_kind: ANSWER_KIND_INTEGER.to_string(),
        answer,
        family: family.to_string(),
    }
}

fn score_integer_activity(
    generated: &GeneratedActivity,
    responses: &[ActivityResponseInput],
) -> ScoredActivity {
    let responses_by_prompt = responses
        .iter()
        .map(|response| (response.prompt_id.as_str(), response.answer.trim()))
        .collect::<BTreeMap<_, _>>();
    let mut attempted_count = 0usize;
    let mut correct_count = 0usize;
    let mut weak_group_counts = BTreeMap::<String, usize>::new();
    let mut response_log = Vec::new();

    for prompt in &generated.prompts {
        let submitted = responses_by_prompt
            .get(prompt.prompt_id.as_str())
            .copied()
            .unwrap_or("");
        let parsed = submitted.parse::<i32>().ok();
        let is_attempted = !submitted.is_empty();
        let is_correct = parsed == Some(prompt.answer);
        if is_attempted {
            attempted_count += 1;
        }
        if is_correct {
            correct_count += 1;
        } else {
            *weak_group_counts.entry(prompt.family.clone()).or_insert(0) += 1;
        }
        response_log.push(json!({
            "prompt_id": prompt.prompt_id,
            "prompt": prompt.prompt,
            "submitted_answer": submitted,
            "expected_answer": prompt.answer,
            "correct": is_correct,
            "family": prompt.family,
        }));
    }

    let prompt_count = generated.prompts.len();
    let accuracy = if prompt_count == 0 {
        0.0
    } else {
        correct_count as f64 / prompt_count as f64
    };
    let passed = generated
        .pass_accuracy
        .map(|threshold| accuracy >= threshold)
        .unwrap_or(accuracy >= 0.8);
    let completion_reason = if attempted_count < prompt_count {
        "partial_submission".to_string()
    } else if passed {
        "pass_threshold_met".to_string()
    } else {
        "completed_below_threshold".to_string()
    };
    let mut weak_groups = weak_group_counts.into_iter().collect::<Vec<_>>();
    weak_groups.sort_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));

    ScoredActivity {
        attempted_count,
        correct_count,
        prompt_count,
        accuracy,
        passed,
        completion_reason,
        weak_groups: weak_groups.into_iter().map(|(group, _)| group).collect(),
        response_log,
    }
}