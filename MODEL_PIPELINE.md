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


## AI-assisted source-model pipeline (0.14.0-alpha)

The former procedural mesh builder is retained only as a legacy/reference path. The new target is an AI-edited Blender scene based on the official SM64CoopDX character template.

1. Run **Prepare Steve AI model kit** in GitHub Actions. The workflow downloads the pinned Minecraft Java 1.21.11 `PlayerModel.java`, `HumanoidModel.java`, the original wide Steve 64×64 skin, and the official SM64CoopDX Mario character template. It packages these references with `AI_MODEL_PROMPT.md`.
2. Give the kit to a 3D AI/editor. Paste `AI_MODEL_PROMPT.md` and require the result `steve_compatible.blend`.
3. Upload the returned scene to `ai-model/steve_compatible.blend` on branch `stevecraft-ai-model-pipeline-alpha`.
4. **Convert AI Steve Blender model to DynOS** validates the retained player armature, required mesh objects, vertex groups, UVMap and Fast64 materials. It then exports `actors/steve/geo.inc.c`, `model.inc.c` and `geo_header.h` using Fast64-Gart.
5. The workflow uploads the converted actor and reports, then commits generated actor source only if validation and export checks pass.

The Minecraft texture is fetched into the Actions workspace and is not committed to this repository by the handoff workflow. Source and texture licensing remains with their respective owners.

The AI model handoff and conversion are not yet a completed character conversion: the AI-generated `steve_compatible.blend` still has to be produced and uploaded. The old procedural model is not silently treated as the new model. An Actions export success is not an Android runtime test.


## Browser-based FBX route

The AI handoff kit also exports the official character template to FBX for browser-based prompt editors. The web prompt is `AI_MODEL_PROMPT_WEB.md`; upload the result as `ai-model/steve_compatible.fbx`. The FBX converter imports the edited geometry into a fresh copy of the original Blender template, keeps the original SM64CoopDX armatures and GeoLayout metadata, maps the FBX skin weights back to the template vertex groups, converts embedded image materials to Fast64 F3D textures, validates the scene, and exports the DynOS actor. It intentionally fails if the editor drops required armature weights, mesh groups, UVs or embedded textures.
