use std::collections::{BTreeSet, HashMap};
use std::fs;
use std::path::Path;

use anyhow::{Context, anyhow, bail};
use chrono::Utc;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubjectCatalog {
    pub subjects: Vec<Subject>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Subject {
    pub subject_id: String,
    pub title: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CapabilityCatalog {
    pub capabilities: Vec<Capability>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Capability {
    pub capability_id: String,
    pub subject: String,
    pub title: String,
    pub recommended_age: u8,
    pub recommended_level: String,
    pub description: String,
    pub success_criteria: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MilestoneCatalog {
    pub milestones: Vec<Milestone>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Milestone {
    pub milestone_id: String,
    pub subject: String,
    pub title: String,
    pub recommended_age: u8,
    pub recommended_level: String,
    pub description: String,
    pub capability_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanTemplateCatalog {
    pub plan_templates: Vec<PlanTemplate>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanTemplate {
    pub plan_template_id: String,
    pub title: String,
    pub recommended_age: u8,
    pub recommended_level: String,
    pub milestone_ids: Vec<String>,
    pub capability_ids: Vec<String>,
    pub duration_days: i32,
    pub session_pattern: SessionPattern,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionPattern {
    pub sessions: Vec<PlanTemplateSession>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanTemplateSession {
    pub day_offset: i32,
    pub title: String,
    pub capability_ids: Vec<String>,
    pub content_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentIndex {
    pub content_items: Vec<ContentIndexItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ContentIndexItem {
    pub content_id: String,
    pub path: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub subject: String,
    pub capability_ids: Vec<String>,
    pub milestone_ids: Vec<String>,
    pub recommended_age: u8,
    pub difficulty: String,
    pub estimated_minutes: u16,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentDocument {
    pub id: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub subject: String,
    pub capability_ids: Vec<String>,
    pub milestone_ids: Vec<String>,
    pub recommended_age: u8,
    pub difficulty: String,
    pub estimated_minutes: u16,
    pub title: String,
    pub body: String,
    pub source_path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogBundle {
    pub subjects: Vec<Subject>,
    pub capabilities: Vec<Capability>,
    pub milestones: Vec<Milestone>,
    pub plan_templates: Vec<PlanTemplate>,
    pub content_items: Vec<ContentDocument>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogValidationReport {
    pub loaded_at_utc: String,
    pub subject_count: usize,
    pub capability_count: usize,
    pub milestone_count: usize,
    pub plan_template_count: usize,
    pub content_item_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IdentityBootstrap {
    pub team: BootstrapTeam,
    pub users: Vec<BootstrapUser>,
    pub memberships: Vec<BootstrapMembership>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BootstrapTeam {
    pub team_id: String,
    pub display_name: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BootstrapUser {
    pub user_id: String,
    pub username: String,
    pub display_name: String,
    pub date_of_birth: Option<chrono::NaiveDate>,
    pub sex: Option<String>,
    pub current_level: Option<String>,
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BootstrapMembership {
    pub team_id: String,
    pub user_id: String,
    pub role: String,
}

pub fn load_catalog_bundle(content_root: &Path) -> anyhow::Result<(CatalogBundle, CatalogValidationReport)> {
    let subjects: SubjectCatalog = read_yaml(content_root.join("catalog/subjects.yaml"))?;
    let capabilities: CapabilityCatalog = read_yaml(content_root.join("catalog/capabilities.yaml"))?;
    let milestones: MilestoneCatalog = read_yaml(content_root.join("catalog/milestones.yaml"))?;
    let plan_templates: PlanTemplateCatalog = read_yaml(content_root.join("catalog/plan_templates.yaml"))?;
    let content_index: ContentIndex = read_yaml(content_root.join("catalog/content_index.yaml"))?;
    let content_items = load_content_documents(content_root, &content_index.content_items)?;

    validate_catalog(
        &subjects.subjects,
        &capabilities.capabilities,
        &milestones.milestones,
        &plan_templates.plan_templates,
        &content_index.content_items,
        &content_items,
    )?;

    let bundle = CatalogBundle {
        subjects: subjects.subjects,
        capabilities: capabilities.capabilities,
        milestones: milestones.milestones,
        plan_templates: plan_templates.plan_templates,
        content_items,
    };
    let report = CatalogValidationReport {
        loaded_at_utc: Utc::now().to_rfc3339(),
        subject_count: bundle.subjects.len(),
        capability_count: bundle.capabilities.len(),
        milestone_count: bundle.milestones.len(),
        plan_template_count: bundle.plan_templates.len(),
        content_item_count: bundle.content_items.len(),
    };
    Ok((bundle, report))
}

pub fn load_bootstrap(bootstrap_path: &Path) -> anyhow::Result<IdentityBootstrap> {
    read_yaml(bootstrap_path)
}

impl CatalogBundle {
    pub fn capability_map(&self) -> HashMap<&str, &Capability> {
        self.capabilities
            .iter()
            .map(|capability| (capability.capability_id.as_str(), capability))
            .collect()
    }

    pub fn milestone_map(&self) -> HashMap<&str, &Milestone> {
        self.milestones
            .iter()
            .map(|milestone| (milestone.milestone_id.as_str(), milestone))
            .collect()
    }

    pub fn plan_template(&self, plan_template_id: &str) -> Option<&PlanTemplate> {
        self.plan_templates
            .iter()
            .find(|plan_template| plan_template.plan_template_id == plan_template_id)
    }
}

fn read_yaml<T>(path: impl AsRef<Path>) -> anyhow::Result<T>
where
    T: for<'de> Deserialize<'de>,
{
    let path = path.as_ref();
    let raw = fs::read_to_string(path).with_context(|| format!("failed to read {}", path.display()))?;
    serde_yaml::from_str(&raw).with_context(|| format!("failed to parse yaml {}", path.display()))
}

fn load_content_documents(
    content_root: &Path,
    index_items: &[ContentIndexItem],
) -> anyhow::Result<Vec<ContentDocument>> {
    index_items
        .iter()
        .map(|item| {
            let source_path = content_root.join(&item.path);
            let raw = fs::read_to_string(&source_path)
                .with_context(|| format!("failed to read {}", source_path.display()))?;
            let (frontmatter, body) = split_frontmatter(&raw, &source_path)?;
            let mut document = parse_content_document(&frontmatter, body, &source_path)?;
            document.source_path = item.path.clone();
            validate_index_item_against_document(item, &document)?;
            Ok(document)
        })
        .collect()
}

fn split_frontmatter(raw: &str, source_path: &Path) -> anyhow::Result<(String, String)> {
    let mut lines = raw.lines();
    if lines.next() != Some("---") {
        bail!("{} is missing YAML frontmatter", source_path.display());
    }

    let mut frontmatter = Vec::new();
    for line in lines.by_ref() {
        if line == "---" {
            let body = lines.collect::<Vec<_>>().join("\n").trim().to_string();
            return Ok((frontmatter.join("\n"), body));
        }
        frontmatter.push(line.to_string());
    }

    bail!("{} has an unterminated frontmatter block", source_path.display())
}

fn parse_content_document(frontmatter: &str, body: String, source_path: &Path) -> anyhow::Result<ContentDocument> {
    #[derive(Debug, Deserialize)]
    struct ContentFrontmatter {
        id: String,
        #[serde(rename = "type")]
        kind: String,
        subject: String,
        capability_ids: Vec<String>,
        milestone_ids: Vec<String>,
        recommended_age: u8,
        difficulty: String,
        estimated_minutes: u16,
    }

    let metadata: ContentFrontmatter = serde_yaml::from_str(frontmatter)
        .with_context(|| format!("invalid frontmatter in {}", source_path.display()))?;
    let title = body
        .lines()
        .find_map(|line| line.strip_prefix("# ").map(ToOwned::to_owned))
        .ok_or_else(|| anyhow!("{} is missing a markdown H1 title", source_path.display()))?;

    Ok(ContentDocument {
        id: metadata.id,
        kind: metadata.kind,
        subject: metadata.subject,
        capability_ids: metadata.capability_ids,
        milestone_ids: metadata.milestone_ids,
        recommended_age: metadata.recommended_age,
        difficulty: metadata.difficulty,
        estimated_minutes: metadata.estimated_minutes,
        title,
        body,
        source_path: source_path.display().to_string(),
    })
}

fn validate_index_item_against_document(
    index_item: &ContentIndexItem,
    document: &ContentDocument,
) -> anyhow::Result<()> {
    if index_item.content_id != document.id {
        bail!("content id mismatch for {}", index_item.path);
    }
    if index_item.kind != document.kind {
        bail!("content type mismatch for {}", index_item.path);
    }
    if index_item.subject != document.subject {
        bail!("content subject mismatch for {}", index_item.path);
    }
    if index_item.capability_ids != document.capability_ids {
        bail!("capability ids mismatch for {}", index_item.path);
    }
    if index_item.milestone_ids != document.milestone_ids {
        bail!("milestone ids mismatch for {}", index_item.path);
    }
    if index_item.recommended_age != document.recommended_age {
        bail!("recommended age mismatch for {}", index_item.path);
    }
    if index_item.difficulty != document.difficulty {
        bail!("difficulty mismatch for {}", index_item.path);
    }
    if index_item.estimated_minutes != document.estimated_minutes {
        bail!("estimated minutes mismatch for {}", index_item.path);
    }
    Ok(())
}

fn validate_catalog(
    subjects: &[Subject],
    capabilities: &[Capability],
    milestones: &[Milestone],
    plan_templates: &[PlanTemplate],
    content_index: &[ContentIndexItem],
    content_items: &[ContentDocument],
) -> anyhow::Result<()> {
    ensure_unique_ids(subjects.iter().map(|subject| subject.subject_id.as_str()), "subject")?;
    ensure_unique_ids(
        capabilities.iter().map(|capability| capability.capability_id.as_str()),
        "capability",
    )?;
    ensure_unique_ids(
        milestones.iter().map(|milestone| milestone.milestone_id.as_str()),
        "milestone",
    )?;
    ensure_unique_ids(
        plan_templates
            .iter()
            .map(|plan_template| plan_template.plan_template_id.as_str()),
        "plan template",
    )?;
    ensure_unique_ids(
        content_index
            .iter()
            .map(|content_item| content_item.content_id.as_str()),
        "content item",
    )?;

    let subject_ids: BTreeSet<_> = subjects.iter().map(|subject| subject.subject_id.as_str()).collect();
    let capability_ids: BTreeSet<_> = capabilities
        .iter()
        .map(|capability| capability.capability_id.as_str())
        .collect();
    let milestone_ids: BTreeSet<_> = milestones
        .iter()
        .map(|milestone| milestone.milestone_id.as_str())
        .collect();
    let content_ids: BTreeSet<_> = content_items.iter().map(|item| item.id.as_str()).collect();

    for capability in capabilities {
        ensure_contains(
            &subject_ids,
            capability.subject.as_str(),
            "capability subject",
            &capability.capability_id,
        )?;
    }

    for milestone in milestones {
        ensure_contains(
            &subject_ids,
            milestone.subject.as_str(),
            "milestone subject",
            &milestone.milestone_id,
        )?;
        for capability_id in &milestone.capability_ids {
            ensure_contains(
                &capability_ids,
                capability_id.as_str(),
                "milestone capability",
                &milestone.milestone_id,
            )?;
        }
    }

    for plan_template in plan_templates {
        for milestone_id in &plan_template.milestone_ids {
            ensure_contains(
                &milestone_ids,
                milestone_id.as_str(),
                "plan template milestone",
                &plan_template.plan_template_id,
            )?;
        }
        for capability_id in &plan_template.capability_ids {
            ensure_contains(
                &capability_ids,
                capability_id.as_str(),
                "plan template capability",
                &plan_template.plan_template_id,
            )?;
        }
        for session in &plan_template.session_pattern.sessions {
            if session.day_offset < 0 {
                bail!(
                    "plan template {} uses a negative day_offset",
                    plan_template.plan_template_id
                );
            }
            for capability_id in &session.capability_ids {
                ensure_contains(
                    &capability_ids,
                    capability_id.as_str(),
                    "session capability",
                    &plan_template.plan_template_id,
                )?;
            }
            for content_id in &session.content_ids {
                ensure_contains(
                    &content_ids,
                    content_id.as_str(),
                    "session content",
                    &plan_template.plan_template_id,
                )?;
            }
        }
    }

    for content_item in content_items {
        ensure_contains(
            &subject_ids,
            content_item.subject.as_str(),
            "content subject",
            &content_item.id,
        )?;
        for capability_id in &content_item.capability_ids {
            ensure_contains(
                &capability_ids,
                capability_id.as_str(),
                "content capability",
                &content_item.id,
            )?;
        }
        for milestone_id in &content_item.milestone_ids {
            ensure_contains(
                &milestone_ids,
                milestone_id.as_str(),
                "content milestone",
                &content_item.id,
            )?;
        }
    }

    Ok(())
}

fn ensure_unique_ids<'a>(ids: impl Iterator<Item = &'a str>, label: &str) -> anyhow::Result<()> {
    let mut seen = BTreeSet::new();
    for id in ids {
        if !seen.insert(id.to_string()) {
            bail!("duplicate {} id '{}'", label, id);
        }
    }
    Ok(())
}

fn ensure_contains(allowed: &BTreeSet<&str>, value: &str, label: &str, owner_id: &str) -> anyhow::Result<()> {
    if !allowed.contains(value) {
        bail!("{} '{}' references missing id '{}'", label, owner_id, value);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn loads_the_repo_catalog() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("../../../content")
            .canonicalize()
            .expect("content root");
        let result = load_catalog_bundle(&root);
        assert!(result.is_ok(), "catalog should load: {result:?}");
    }
}
