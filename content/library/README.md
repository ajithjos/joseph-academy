# Content Library

This directory is the cleaned authored source for pathway-contained curriculum.

The shape is:

```text
content/library/
  registry.yaml
  {subject}/
    {area}/
      {pathway}/
        pathway.md
        stages/
        skills/
        playlists/
        materials/
```

Use the brief in `docs/authoring/examples/` as the planning input.
Use the pathway directory here as the authored curriculum output.

The Rust loader and the docs-site renderer read this tree directly.