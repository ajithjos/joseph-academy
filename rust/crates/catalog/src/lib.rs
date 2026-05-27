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
pub struct AreaCatalog {
    pub areas: Vec<Area>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Subject {
    pub subject_id: String,
    pub title: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Area {
    pub area_id: String,
    pub subject_id: String,
    pub title: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillCatalog {
    pub skills: Vec<Skill>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Skill {
    pub skill_id: String,
    pub subject_id: String,
    pub area_id: String,
    pub title: String,
    pub recommended_age: u8,
    pub recommended_level: String,
    pub description: String,
    pub success_criteria: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StageCatalog {
    pub stages: Vec<Stage>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stage {
    pub stage_id: String,
    pub subject_id: String,
    pub area_id: String,
    pub title: String,
    pub recommended_age: u8,
    pub recommended_level: String,
    pub description: String,
    pub skill_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaylistCatalog {
    pub playlists: Vec<Playlist>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Playlist {
    pub playlist_id: String,
    pub title: String,
    pub subject_id: String,
    pub area_id: String,
    pub recommended_age: u8,
    pub recommended_level: String,
    pub stage_ids: Vec<String>,
    pub skill_ids: Vec<String>,
    pub duration_days: i32,
    pub session_pattern: SessionPattern,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionPattern {
    pub sessions: Vec<PlaylistSession>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlaylistSession {
    pub day_offset: i32,
    pub title: String,
    pub skill_ids: Vec<String>,
    pub material_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MaterialCatalog {
    pub materials: Vec<MaterialIndexItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct MaterialIndexItem {
    pub material_id: String,
    pub path: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub subject_id: String,
    pub area_id: String,
    pub skill_ids: Vec<String>,
    pub stage_ids: Vec<String>,
    pub recommended_age: u8,
    pub difficulty: String,
    pub estimated_minutes: u16,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MaterialDocument {
    pub id: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub subject_id: String,
    pub area_id: String,
    pub skill_ids: Vec<String>,
    pub stage_ids: Vec<String>,
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
    pub areas: Vec<Area>,
    pub skills: Vec<Skill>,
    pub stages: Vec<Stage>,
    pub playlists: Vec<Playlist>,
    pub materials: Vec<MaterialDocument>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogValidationReport {
    pub loaded_at_utc: String,
    pub subject_count: usize,
    pub area_count: usize,
    pub skill_count: usize,
    pub stage_count: usize,
    pub playlist_count: usize,
    pub material_count: usize,
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
    let areas: AreaCatalog = read_yaml(content_root.join("catalog/areas.yaml"))?;
    let skills: SkillCatalog = read_yaml(content_root.join("catalog/skills.yaml"))?;
    let stages: StageCatalog = read_yaml(content_root.join("catalog/stages.yaml"))?;
    let playlists: PlaylistCatalog = read_yaml(content_root.join("catalog/playlists.yaml"))?;
    let materials: MaterialCatalog = read_yaml(content_root.join("catalog/materials.yaml"))?;
    let material_documents = load_material_documents(content_root, &materials.materials)?;

    validate_catalog(
        &subjects.subjects,
        &areas.areas,
        &skills.skills,
        &stages.stages,
        &playlists.playlists,
        &materials.materials,
        &material_documents,
    )?;

    let bundle = CatalogBundle {
        subjects: subjects.subjects,
        areas: areas.areas,
        skills: skills.skills,
        stages: stages.stages,
        playlists: playlists.playlists,
        materials: material_documents,
    };
    let report = CatalogValidationReport {
        loaded_at_utc: Utc::now().to_rfc3339(),
        subject_count: bundle.subjects.len(),
        area_count: bundle.areas.len(),
        skill_count: bundle.skills.len(),
        stage_count: bundle.stages.len(),
        playlist_count: bundle.playlists.len(),
        material_count: bundle.materials.len(),
    };
    Ok((bundle, report))
}

pub fn load_bootstrap(bootstrap_path: &Path) -> anyhow::Result<IdentityBootstrap> {
    read_yaml(bootstrap_path)
}

impl CatalogBundle {
    pub fn skill_map(&self) -> HashMap<&str, &Skill> {
        self.skills
            .iter()
            .map(|skill| (skill.skill_id.as_str(), skill))
            .collect()
    }

    pub fn stage_map(&self) -> HashMap<&str, &Stage> {
        self.stages
            .iter()
            .map(|stage| (stage.stage_id.as_str(), stage))
            .collect()
    }

    pub fn playlist(&self, playlist_id: &str) -> Option<&Playlist> {
        self.playlists
            .iter()
            .find(|playlist| playlist.playlist_id == playlist_id)
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

fn load_material_documents(
    content_root: &Path,
    index_items: &[MaterialIndexItem],
) -> anyhow::Result<Vec<MaterialDocument>> {
    index_items
        .iter()
        .map(|item| {
            let source_path = content_root.join(&item.path);
            let raw = fs::read_to_string(&source_path)
                .with_context(|| format!("failed to read {}", source_path.display()))?;
            let (frontmatter, body) = split_frontmatter(&raw, &source_path)?;
            let mut document = parse_material_document(&frontmatter, body, &source_path)?;
            document.source_path = item.path.clone();
            validate_material_index_against_document(item, &document)?;
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

fn parse_material_document(frontmatter: &str, body: String, source_path: &Path) -> anyhow::Result<MaterialDocument> {
    #[derive(Debug, Deserialize)]
    struct MaterialFrontmatter {
        id: String,
        #[serde(rename = "type")]
        kind: String,
        subject_id: String,
        area_id: String,
        skill_ids: Vec<String>,
        stage_ids: Vec<String>,
        recommended_age: u8,
        difficulty: String,
        estimated_minutes: u16,
    }

    let metadata: MaterialFrontmatter = serde_yaml::from_str(frontmatter)
        .with_context(|| format!("invalid frontmatter in {}", source_path.display()))?;
    let title = body
        .lines()
        .find_map(|line| line.strip_prefix("# ").map(ToOwned::to_owned))
        .ok_or_else(|| anyhow!("{} is missing a markdown H1 title", source_path.display()))?;

    Ok(MaterialDocument {
        id: metadata.id,
        kind: metadata.kind,
        subject_id: metadata.subject_id,
        area_id: metadata.area_id,
        skill_ids: metadata.skill_ids,
        stage_ids: metadata.stage_ids,
        recommended_age: metadata.recommended_age,
        difficulty: metadata.difficulty,
        estimated_minutes: metadata.estimated_minutes,
        title,
        body,
        source_path: source_path.display().to_string(),
    })
}

fn validate_material_index_against_document(
    index_item: &MaterialIndexItem,
    document: &MaterialDocument,
) -> anyhow::Result<()> {
    if index_item.material_id != document.id {
        bail!("material id mismatch for {}", index_item.path);
    }
    if index_item.kind != document.kind {
        bail!("material type mismatch for {}", index_item.path);
    }
    if index_item.subject_id != document.subject_id {
        bail!("material subject mismatch for {}", index_item.path);
    }
    if index_item.area_id != document.area_id {
        bail!("material area mismatch for {}", index_item.path);
    }
    if index_item.skill_ids != document.skill_ids {
        bail!("skill ids mismatch for {}", index_item.path);
    }
    if index_item.stage_ids != document.stage_ids {
        bail!("stage ids mismatch for {}", index_item.path);
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
    areas: &[Area],
    skills: &[Skill],
    stages: &[Stage],
    playlists: &[Playlist],
    materials: &[MaterialIndexItem],
    material_documents: &[MaterialDocument],
) -> anyhow::Result<()> {
    ensure_unique_ids(subjects.iter().map(|subject| subject.subject_id.as_str()), "subject")?;
    ensure_unique_ids(areas.iter().map(|area| area.area_id.as_str()), "area")?;
    ensure_unique_ids(
        skills.iter().map(|skill| skill.skill_id.as_str()),
        "skill",
    )?;
    ensure_unique_ids(
        stages.iter().map(|stage| stage.stage_id.as_str()),
        "stage",
    )?;
    ensure_unique_ids(
        playlists
            .iter()
            .map(|playlist| playlist.playlist_id.as_str()),
        "playlist",
    )?;
    ensure_unique_ids(
        materials
            .iter()
            .map(|material| material.material_id.as_str()),
        "material",
    )?;

    let subject_ids: BTreeSet<_> = subjects.iter().map(|subject| subject.subject_id.as_str()).collect();
    let area_ids: BTreeSet<_> = areas.iter().map(|area| area.area_id.as_str()).collect();
    let skill_ids: BTreeSet<_> = skills.iter().map(|skill| skill.skill_id.as_str()).collect();
    let stage_ids: BTreeSet<_> = stages
        .iter()
        .map(|stage| stage.stage_id.as_str())
        .collect();
    let material_ids: BTreeSet<_> = material_documents.iter().map(|item| item.id.as_str()).collect();

    for area in areas {
        ensure_contains(
            &subject_ids,
            area.subject_id.as_str(),
            "area subject",
            &area.area_id,
        )?;
    }

    for skill in skills {
        ensure_contains(
            &subject_ids,
            skill.subject_id.as_str(),
            "skill subject",
            &skill.skill_id,
        )?;
        ensure_contains(&area_ids, skill.area_id.as_str(), "skill area", &skill.skill_id)?;
    }

    for stage in stages {
        ensure_contains(&subject_ids, stage.subject_id.as_str(), "stage subject", &stage.stage_id)?;
        ensure_contains(&area_ids, stage.area_id.as_str(), "stage area", &stage.stage_id)?;
        for skill_id in &stage.skill_ids {
            ensure_contains(
                &skill_ids,
                skill_id.as_str(),
                "stage skill",
                &stage.stage_id,
            )?;
        }
    }

    for playlist in playlists {
        ensure_contains(
            &subject_ids,
            playlist.subject_id.as_str(),
            "playlist subject",
            &playlist.playlist_id,
        )?;
        ensure_contains(&area_ids, playlist.area_id.as_str(), "playlist area", &playlist.playlist_id)?;
        for stage_id in &playlist.stage_ids {
            ensure_contains(
                &stage_ids,
                stage_id.as_str(),
                "playlist stage",
                &playlist.playlist_id,
            )?;
        }
        for skill_id in &playlist.skill_ids {
            ensure_contains(&skill_ids, skill_id.as_str(), "playlist skill", &playlist.playlist_id)?;
        }
        for session in &playlist.session_pattern.sessions {
            if session.day_offset < 0 {
                bail!("playlist {} uses a negative day_offset", playlist.playlist_id);
            }
            for skill_id in &session.skill_ids {
                ensure_contains(
                    &skill_ids,
                    skill_id.as_str(),
                    "session skill",
                    &playlist.playlist_id,
                )?;
            }
            for material_id in &session.material_ids {
                ensure_contains(
                    &material_ids,
                    material_id.as_str(),
                    "session material",
                    &playlist.playlist_id,
                )?;
            }
        }
    }

    for material in material_documents {
        ensure_contains(
            &subject_ids,
            material.subject_id.as_str(),
            "material subject",
            &material.id,
        )?;
        ensure_contains(&area_ids, material.area_id.as_str(), "material area", &material.id)?;
        for skill_id in &material.skill_ids {
            ensure_contains(
                &skill_ids,
                skill_id.as_str(),
                "material skill",
                &material.id,
            )?;
        }
        for stage_id in &material.stage_ids {
            ensure_contains(
                &stage_ids,
                stage_id.as_str(),
                "material stage",
                &material.id,
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
