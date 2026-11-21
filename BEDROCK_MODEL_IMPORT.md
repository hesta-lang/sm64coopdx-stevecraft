# Bedrock Steve model import — prototype alpha

## Objective

Use Mojang's public Bedrock sample geometry as the source of truth for Steve's classic humanoid model, then convert it into the geometry schema consumed by SteveCraft's existing Blender/Fast64 DynOS exporter.

This is a geometry-first prototype. It does not port the Bedrock C++ game engine, renderer, animation runtime, or physics implementation.

## Pinned source

The importer workflow downloads these files from the Mojang/bedrock-samples repository:

- resource_pack/models/entity/humanoid.custom.geo.json
- resource_pack/entity/player.entity.json

Source revision: 15701fa9c13923f12662984c32c124327e40e3d3

The downloaded source is kept only in the CI workspace. It is not committed to the SteveCraft repository.

The sample repository states that its files are subject to the Minecraft End User License Agreement. Do not assume the model or texture can be relicensed under MIT or redistributed outside the EULA.

## What the importer reads

tools/import_bedrock_geometry.py validates the geometry identifier and converts the classic Steve geometry:

- 17 Bedrock bones and their parent relationships;
- bone pivots;
- 12 classic body and outer-layer cubes;
- cube dimensions, inflation, and UV origins;
- hand item locators;
- the player entity scale (0.9375).

The importer converts Bedrock's Y-up cube origins into the Y-down coordinates already consumed by the SteveCraft mesh builder. For the classic sample, the converted cube origins, dimensions and UV origins match the current 12-cube builder schema.

## DynOS compatibility mapping

Fast64's current template is based on the SM64CoopDX Mario player armature. The importer therefore preserves the complete Bedrock bone tree as metadata, but maps the visible cubes onto the six mesh groups available in that armature:

| Bedrock render bones | SM64 mesh group |
| --- | --- |
| head, hat | Head DL |
| body, jacket | Torso |
| leftArm, leftSleeve | Left Arm Color |
| rightArm, rightSleeve | Right Arm Color |
| leftLeg, leftPants | Left Thigh Color |
| rightLeg, rightPants | Right Thigh Color |

This preserves the classic cube geometry and UVs but does NOT create a native 17-bone Bedrock skeleton in DynOS. Cape and item locator bones are preserved in the intermediate spec; the cape and held-item rendering are not built by this first stage. Bedrock-only cube rotation, multiple cubes under a single render bone, and custom player geometries are rejected instead of being silently flattened.

The optional STEVE_BEDROCK_GEOMETRY_SPEC environment variable connects the imported spec to tools/build_steve_actor.py. When supplied, the Blender builder uses the imported cuboids and the Bedrock entity scale. Without it, the existing Java geometry source remains the default.

## Validation

tools/test_bedrock_geometry_importer.py includes synthetic unit tests and an integration test against the pinned official Mojang sample. The dedicated GitHub Actions workflow downloads the source, imports it, verifies the 17-bone and 12-cube counts, checks the 0.9375 entity scale, and validates the converted spec.

The workflow does not upload the downloaded source or generated import spec.

## Next stage after this prototype

Only after the model export is visually checked on SM64CoopDX Android should we replace the six-group mapping with a dedicated GeoLayout hierarchy for Bedrock's root/waist/body/head/arm/leg and overlay bones. That second stage also needs corresponding animation-channel mappings. It must not be claimed as implemented by this importer alpha.
