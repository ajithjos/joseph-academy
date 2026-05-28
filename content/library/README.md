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

Legacy `content/catalog/` and `content/materials/` remain in the repo as compatibility surfaces until the runtime loader is migrated.