# Steve model and animation pipeline

## Export result

The model source is exported by the GitHub Actions workflow **Build Steve DynOS character**. It downloads the official SM64CoopDX player template, opens it with Blender 3.6.23 and Fast64-Gart, replaces the visible meshes with Steve's cuboid body and exports the actor GeoLayout.

Generated files are stored in `actors/steve/`:
- `geo.inc.c`
- `model.inc.c`
- `geo_header.h`

SM64CoopDX/DynOS produces the runtime `steve_geo` model resource from the actor files when the game loads the mod. Lua requests it with `smlua_model_util_get_id("steve_geo")`.

## Rig and mesh-space correction (0.13.0-alpha)

The source actor keeps the official SM64CoopDX player armature and bone groups:

- Head: `Head DL`
- Torso: `Torso`
- Left/right arms: `Left Arm Color`, `Right Arm Color`
- Left/right legs: `Left Thigh Color`, `Right Thigh Color`

The official template's body mesh objects have a +90-degree local X rotation relative to their armatures. Earlier geometry generation wrote armature-space coordinates directly into mesh-local vertices, so the object's transform swapped side and depth axes. The model is now converted through the inverse of each mesh object's actual transform:

1. Build Minecraft's intended point in the armature coordinate system.
2. Calculate the mesh-to-armature matrix from the mesh parent and world matrices.
3. Apply the inverse matrix before writing the vertex into mesh-local data.

The normal player mesh and capless-head mesh use the same conversion. The export report records the template matrices so a future template update cannot silently change this assumption.

Fast64 also requires a UV layer named exactly `UVMap`. The builder now creates that layer instead of the previous custom name.

## Minecraft geometry and textures

The generator creates the 12 PlayerModel cubes from Minecraft Java 1.21.11: six base cubes and six outer-layer cubes. Each part retains the corresponding region of the classic 64×64 Steve skin. The UV cropping tool creates small per-cuboid PNGs to keep textures within the N64 renderer's memory limits.

The actor remains a DynOS/F3D model. Minecraft's Java renderer, lighting and exact translucent-layer sorting are not transplanted.

## Animation

Because the original SM64 player skeleton is preserved, the actor can use the engine's standard player animation set. SteveCraft also registers Minecraft-style clips through `animations.lua` for idle, walk, run, crouch, crouch-walk and swim. Only players using Steve's model receive those clips.

## Animation

Because the original SM64 player skeleton is preserved, the actor can use the engine's standard player animation set. SteveCraft also registers Minecraft-style clips through `animations.lua` for idle, walk, run, crouch, crouch-walk and swim. Only players using Steve's model receive those clips.

## DynOS skeleton alignment (model-fix alpha)

Minecraft-style clips are baked against 20 animated GeoLayout nodes: the root rotation node plus the 19 named body parts in `animations.lua`. The original Fast64 export contained only 18 animated parts because it omitted the zero-offset `leftHand` and `rightHand` wrist nodes after the arm forearms. That shifted later animation channels onto the wrong body parts.

`tools/steve_geo_skeleton.py` now inserts those two empty wrist joints into all four full-body layouts (opaque, transparent and metal variants) immediately after export. The model remains a set of six rigid Minecraft cuboid body groups; the extra nodes carry animation transforms only and do not add geometry. The build report records the number of validated layouts and inserted wrist nodes.

`tools/test_steve_geo_skeleton.py` checks all four layouts for exactly 20 animated nodes, verifies insertion order, and tests repeatability. This validates the generated source structure; Android rendering and movement still require an in-game test.

## Runtime checks still required

- [ ] Actor builds and `steve_geo` resolves on Android.
- [ ] Steve's head is above the torso; torso, both arms and both legs are separated and visible.
- [ ] The face and all body regions sample the intended Steve skin faces.
- [ ] Head, torso, arms and legs rotate at the intended joints.
- [ ] Idle, walk, run and jump poses do not roll the whole body onto its side.
- [ ] First-person camera and touch orbit remain functional.
- [ ] Jump motion is vertical only, with no residual X/Z movement.
- [ ] Android gameplay and multiplayer model selection are validated.

A successful source export does not prove that the Android DynOS runtime renders the actor correctly.
