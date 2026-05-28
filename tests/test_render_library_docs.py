import importlib.util
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "render_library_docs.py"
SPEC = importlib.util.spec_from_file_location("render_catalog_docs", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_render_markdown_generates_catalog_pages() -> None:
    MODULE.render_markdown("production")
    assert (MODULE.GENERATED_ROOT / "library-overview.md").exists()
    assert (MODULE.GENERATED_ROOT / "pathways.md").exists()
    assert (MODULE.GENERATED_ROOT / "playlists.md").exists()
    assert (
        MODULE.LIBRARY_DOCS_ROOT
        / "maths"
        / "arithmetic"
        / "household-arithmetic-fact-fluency"
        / "pathway.md"
    ).exists()
    assert (
        MODULE.LIBRARY_DOCS_ROOT
        / "maths"
        / "arithmetic"
        / "household-arithmetic-fact-fluency"
        / "materials"
        / "multiplication-facts-through-10-check.md"
    ).exists()
    assert not MODULE.LEGACY_MATERIALS_ROOT.exists()
    assert not (MODULE.DEVELOPER_ROOT / "README.md").exists()


def test_render_markdown_developer_mode_copies_repo_docs() -> None:
    MODULE.render_markdown("developer")
    assert (MODULE.DEVELOPER_ROOT / "README.md").exists()
    assert (MODULE.DEVELOPER_ROOT / "architecture" / "learning-product-definition.md").exists()
