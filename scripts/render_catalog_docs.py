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
LIBRARY_ROOT = DOCS_ROOT / "library"
DEVELOPER_ROOT = DOCS_ROOT / "developer"

VALID_MODES = {"production", "developer"}


def load_yaml(path: Path) -> dict:
    return yaml.safe_load(path.read_text())


def render_markdown(mode: str = "production") -> None:
    if mode not in VALID_MODES:
        raise ValueError(f"unsupported mode: {mode}")

    subjects = load_yaml(CONTENT_ROOT / "catalog" / "subjects.yaml")["subjects"]
    capabilities = load_yaml(CONTENT_ROOT / "catalog" / "capabilities.yaml")["capabilities"]
    milestones = load_yaml(CONTENT_ROOT / "catalog" / "milestones.yaml")["milestones"]
    plan_templates = load_yaml(CONTENT_ROOT / "catalog" / "plan_templates.yaml")["plan_templates"]
    content_items = load_yaml(CONTENT_ROOT / "catalog" / "content_index.yaml")["content_items"]

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
                f"- capabilities: {len(capabilities)}",
                f"- milestones: {len(milestones)}",
                f"- plan templates: {len(plan_templates)}",
                f"- content items: {len(content_items)}",
                "",
                "The pages in this section are generated from the repo-owned catalog files under `content/`.",
            ]
        ),
    )

    write_file(
        GENERATED_ROOT / "capabilities.md",
        render_sections(
            "Capabilities",
            capabilities,
            lambda item: [
                f"## `{item['capability_id']}`",
                "",
                f"- subject: `{item['subject']}`",
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
        GENERATED_ROOT / "milestones.md",
        render_sections(
            "Milestones",
            milestones,
            lambda item: [
                f"## `{item['milestone_id']}`",
                "",
                f"- subject: `{item['subject']}`",
                f"- recommended age: `{item['recommended_age']}`",
                f"- recommended level: {item['recommended_level']}",
                "",
                item["description"],
                "",
                "Capabilities:",
                *[f"- `{capability_id}`" for capability_id in item["capability_ids"]],
            ],
        ),
    )

    write_file(
        GENERATED_ROOT / "plan-templates.md",
        render_sections(
            "Plan Templates",
            plan_templates,
            lambda item: [
                f"## `{item['plan_template_id']}`",
                "",
                f"- title: {item['title']}",
                f"- recommended age: `{item['recommended_age']}`",
                f"- recommended level: {item['recommended_level']}",
                f"- duration days: `{item['duration_days']}`",
                "",
                "Milestones:",
                *[f"- `{milestone_id}`" for milestone_id in item["milestone_ids"]],
                "",
                "Capabilities:",
                *[f"- `{capability_id}`" for capability_id in item["capability_ids"]],
                "",
                "Sessions:",
                *[
                    "- day "
                    f"{session['day_offset']}: {session['title']} -> capabilities "
                    f"{', '.join(session['capability_ids'])}"
                    for session in item["session_pattern"]["sessions"]
                ],
            ],
        ),
    )

    write_file(
        GENERATED_ROOT / "content-index.md",
        render_sections(
            "Content Index",
            content_items,
            lambda item: [
                f"## `{item['content_id']}`",
                "",
                f"- type: `{item['type']}`",
                f"- subject: `{item['subject']}`",
                f"- path: `{item['path']}`",
                f"- estimated minutes: `{item['estimated_minutes']}`",
                "",
                "Capabilities:",
                *[f"- `{capability_id}`" for capability_id in item["capability_ids"]],
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

    copy_library_markdown()
    if mode == "developer":
        copy_developer_docs()


def reset_output_dirs() -> None:
    for directory in (GENERATED_ROOT, LIBRARY_ROOT, DEVELOPER_ROOT):
        if directory.exists():
            shutil.rmtree(directory)
        directory.mkdir(parents=True, exist_ok=True)


def copy_library_markdown() -> None:
    source_root = CONTENT_ROOT / "library"
    for source in source_root.rglob("*.md"):
        target = LIBRARY_ROOT / source.relative_to(source_root)
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
