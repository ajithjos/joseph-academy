from __future__ import annotations

import shutil
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
CONTENT_ROOT = REPO_ROOT / "content"
DOCS_SOURCE_ROOT = REPO_ROOT / "docs"
DOCS_ROOT = REPO_ROOT / "docs_site" / "docs"
GENERATED_ROOT = DOCS_ROOT / "generated"
MATERIALS_ROOT = DOCS_ROOT / "materials"
LEGACY_LIBRARY_ROOT = DOCS_ROOT / "library"
DEVELOPER_ROOT = DOCS_ROOT / "developer"

VALID_MODES = {"production", "developer"}


def load_yaml(path: Path) -> dict:
    return yaml.safe_load(path.read_text())


def render_markdown(mode: str = "production") -> None:
    if mode not in VALID_MODES:
        raise ValueError(f"unsupported mode: {mode}")

    subjects = load_yaml(CONTENT_ROOT / "catalog" / "subjects.yaml")["subjects"]
    areas = load_yaml(CONTENT_ROOT / "catalog" / "areas.yaml")["areas"]
    skills = load_yaml(CONTENT_ROOT / "catalog" / "skills.yaml")["skills"]
    stages = load_yaml(CONTENT_ROOT / "catalog" / "stages.yaml")["stages"]
    playlists = load_yaml(CONTENT_ROOT / "catalog" / "playlists.yaml")["playlists"]
    materials = load_yaml(CONTENT_ROOT / "catalog" / "materials.yaml")["materials"]

    reset_output_dirs()

    write_file(
        GENERATED_ROOT / "catalog-overview.md",
        "\n".join(
            [
                "---",
                "title: Catalog Overview",
                "---",
                "",
                "# Catalog Overview",
                "",
                f"- subjects: {len(subjects)}",
                f"- areas: {len(areas)}",
                f"- skills: {len(skills)}",
                f"- stages: {len(stages)}",
                f"- playlists: {len(playlists)}",
                f"- materials: {len(materials)}",
                "",
                "The pages in this section are generated from the repo-owned catalog files under `content/`.",
            ]
        ),
    )

    write_file(
        GENERATED_ROOT / "areas.md",
        render_sections(
            "Areas",
            areas,
            lambda item: [
                f"## `{item['area_id']}`",
                "",
                f"- subject: `{item['subject_id']}`",
                "",
                item["description"],
            ],
        ),
    )

    write_file(
        GENERATED_ROOT / "skills.md",
        render_sections(
            "Skills",
            skills,
            lambda item: [
                f"## `{item['skill_id']}`",
                "",
                f"- subject: `{item['subject_id']}`",
                f"- area: `{item['area_id']}`",
                f"- recommended age: `{item['recommended_age']}`",
                f"- recommended level: {item['recommended_level']}",
                "",
                item["description"],
                "",
                f"Success criteria: {item['success_criteria']}",
            ],
        ),
    )

    write_file(
        GENERATED_ROOT / "stages.md",
        render_sections(
            "Stages",
            stages,
            lambda item: [
                f"## `{item['stage_id']}`",
                "",
                f"- subject: `{item['subject_id']}`",
                f"- area: `{item['area_id']}`",
                f"- recommended age: `{item['recommended_age']}`",
                f"- recommended level: {item['recommended_level']}",
                "",
                item["description"],
                "",
                "Skills:",
                *[f"- `{skill_id}`" for skill_id in item["skill_ids"]],
            ],
        ),
    )

    write_file(
        GENERATED_ROOT / "playlists.md",
        render_sections(
            "Playlists",
            playlists,
            lambda item: [
                f"## `{item['playlist_id']}`",
                "",
                f"- title: {item['title']}",
                f"- subject: `{item['subject_id']}`",
                f"- area: `{item['area_id']}`",
                f"- recommended age: `{item['recommended_age']}`",
                f"- recommended level: {item['recommended_level']}",
                f"- duration days: `{item['duration_days']}`",
                "",
                "Stages:",
                *[f"- `{stage_id}`" for stage_id in item["stage_ids"]],
                "",
                "Skills:",
                *[f"- `{skill_id}`" for skill_id in item["skill_ids"]],
                "",
                "Sessions:",
                *[
                    "- day "
                    f"{session['day_offset']}: {session['title']} -> skills "
                    f"{', '.join(session['skill_ids'])}"
                    for session in item["session_pattern"]["sessions"]
                ],
            ],
        ),
    )

    write_file(
        GENERATED_ROOT / "materials.md",
        render_sections(
            "Materials",
            materials,
            lambda item: [
                f"## `{item['material_id']}`",
                "",
                f"- type: `{item['type']}`",
                f"- subject: `{item['subject_id']}`",
                f"- area: `{item['area_id']}`",
                f"- path: `{item['path']}`",
                f"- estimated minutes: `{item['estimated_minutes']}`",
                "",
                "Skills:",
                *[f"- `{skill_id}`" for skill_id in item["skill_ids"]],
            ],
        ),
    )

    write_file(
        GENERATED_ROOT / "subjects.md",
        render_sections(
            "Subjects",
            subjects,
            lambda item: [
                f"## `{item['subject_id']}`",
                "",
                item["description"],
            ],
        ),
    )

    copy_material_markdown()
    if mode == "developer":
        copy_developer_docs()


def reset_output_dirs() -> None:
    legacy_directories = (LEGACY_LIBRARY_ROOT,)
    for directory in legacy_directories:
        if directory.exists():
            shutil.rmtree(directory)

    for directory in (GENERATED_ROOT, MATERIALS_ROOT, DEVELOPER_ROOT):
        if directory.exists():
            shutil.rmtree(directory)
        directory.mkdir(parents=True, exist_ok=True)


def copy_material_markdown() -> None:
    source_root = CONTENT_ROOT / "materials"
    for source in source_root.rglob("*.md"):
        target = MATERIALS_ROOT / source.relative_to(source_root)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source.read_text())


def copy_developer_docs() -> None:
    for source in DOCS_SOURCE_ROOT.rglob("*.md"):
        target = DEVELOPER_ROOT / source.relative_to(DOCS_SOURCE_ROOT)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(source.read_text())


def render_sections(title: str, items: list[dict], builder) -> str:
    lines = ["---", f"title: {title}", "---", "", f"# {title}", ""]
    for item in items:
        lines.extend(builder(item))
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


if __name__ == "__main__":
    selected_mode = sys.argv[1] if len(sys.argv) > 1 else "production"
    render_markdown(selected_mode)
