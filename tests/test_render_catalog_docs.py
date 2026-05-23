import importlib.util
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "render_catalog_docs.py"
SPEC = importlib.util.spec_from_file_location("render_catalog_docs", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_render_markdown_generates_catalog_pages() -> None:
    MODULE.render_markdown("production")
    assert (MODULE.GENERATED_ROOT / "catalog-overview.md").exists()
    assert (MODULE.GENERATED_ROOT / "plan-templates.md").exists()
    assert (MODULE.LIBRARY_ROOT / "maths" / "foundations" / "number-bonds-to-10-practice.md").exists()
    assert not (MODULE.DEVELOPER_ROOT / "README.md").exists()


def test_render_markdown_developer_mode_copies_repo_docs() -> None:
    MODULE.render_markdown("developer")
    assert (MODULE.DEVELOPER_ROOT / "README.md").exists()
    assert (MODULE.DEVELOPER_ROOT / "architecture" / "learning-product-definition.md").exists()
