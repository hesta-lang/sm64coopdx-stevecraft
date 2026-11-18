# Steve model and animation pipeline

## Export result

The model source is exported by the GitHub Actions workflow **Build Steve DynOS character**. It downloads the official SM64CoopDX player template, opens it with Blender 3.6.23 and Fast64-Gart, replaces the visible meshes with Steve's cuboid body and exports the actor GeoLayout.

Generated files are stored in `actors/steve/`:
- `geo.inc.c`
- `model.inc.c`
- `geo_header.h`

SM64CoopDX/DynOS is responsible for producing the runtime `steve_geo` model resource from the actor files when the game loads the mod. The runtime model is requested by Lua as `smlua_model_util_get_id("steve_geo")`.

## Rig

The source actor keeps the official SM64 player armature and required bone groups. The six main body parts are assigned to the matching groups:

- Head: `Head DL`
- Torso: `Torso`
- Left and right arms: `Left Arm Color`, `Right Arm Color`
- Left and right legs: `Left Thigh Color`, `Right Thigh Color`

Mario's hand switches, wing branches and held-object branch are ignored for the Steve actor. Capless and metal model variants are also replaced so they do not restore the original Mario geometry.

## Animation

Because the original SM64 player skeleton is preserved, the actor can use the engine's standard player animation set. This includes the game's standing, walking, running, jumping, falling, landing and damage/death motions.

The Minecraft-style animation clips are now registered in the engine's native animation format by `animations.lua`. They are generated from the compatible player rig's 20 animated GeoLayout nodes; the animation data contains 63 three-axis channels, including the three unused root-translation slots required by SM64's format.

The model remains on the SM64-compatible hierarchy so multiplayer, camera callbacks and the existing player systems continue to work. The new clips replace the stock pose only while the player is using Steve's model.

## Runtime checks still required

- [ ] Actor is compiled and `steve_geo` resolves to a model ID on Android.
- [ ] Steve is visible on the local player and remote players.
- [ ] The head, torso, arms and legs rotate at the intended joints.
- [ ] Default player animations do not deform the cubes.
- [ ] First-person camera remains functional.
- [ ] Multiplayer sync is correct when SteveCraft is installed by all clients.

A successful GitHub export only validates the source generation. It does not prove that the target Android build can load or render the actor.


## First-person arm

A second, standalone DynOS actor is generated at `actors/steve_hand/`. It contains two flat-shaded cuboids: a turquoise sleeve and a skin-tone hand. The Lua behavior positions this object relative to `gLakituState.curPos` using the same yaw and pitch values as the fork's first-person camera. It adds a walk sway and a forward punch pose.

This is a camera-attached 3D world object, not a dedicated HUD render pass. It may still be affected by world depth/occlusion, so its scale, placement and visibility require Android gameplay validation.

## DynOS parser compatibility

Fast64-Gart currently exports `CUSTOM_CMD()` placeholders that the Android fork's DynOS GeoLayout parser does not recognize. The build script removes only those empty placeholder lines and fails the build if any `CUSTOM_CMD` token remains. DynOS reads the actor sources and creates the runtime `.bin` resources when the mod pack loads; no prebuilt binary files are needed.


## Classic Minecraft first-person arm (0.5.0-alpha)

The first-person arm uses the classic Steve right-arm proportions: 4×12×4. Its source texture is a 64×64 classic Steve skin at assets/steve/steve_skin.png.

The generator extracts six separate face textures from the classic UV layout:
- Top: (44,16)–(47,19)
- Bottom: (48,16)–(51,19)
- Right side: (40,20)–(43,31)
- Front: (44,20)–(47,31)
- Left side: (48,20)–(51,31)
- Back: (52,20)–(55,31)

Each face is a small PNG so the N64 renderer does not need to load the entire 64×64 atlas into TMEM. DynOS resolves the PNGs using the texture names declared in actors/steve_hand/model.inc.c. The viewmodel keeps the Gun Mod camera-relative transform in first_person_hand.lua.

The source skin has a transparent outer-arm/sleeve overlay region. The generated arm therefore uses the complete base skin layer, which already contains the classic turquoise sleeve and skin pixels. Geometry and UVs follow Minecraft's classic arm layout, while rendering remains in SM64CoopDX's N64-style pipeline.


## First-person arm corrections (0.5.1-alpha)

The arm cuboid is reflected along its 12-unit axis so the hand end points toward the screen center and the turquoise shoulder/sleeve sits at the lower-right edge, matching the first-person pose. The actor scale is 2.5× rather than 3×, and the camera-relative anchor has been shifted farther right and lower.

The display list explicitly selects `gsDPSetTextureFilter(G_TF_POINT)`. The Android DynOS parser exposes this symbol through `gfx_symbols.h`, and the OpenGL renderer maps the non-linear sampler option to `GL_NEAREST`. This prevents bilinear interpolation from softening the 4×4 and 4×12 skin face textures.


## Perspective switching (0.6.0-alpha)

`camera.lua` no longer forces first person in every update. D-pad Up cycles between first person and the native SM64CoopDX third-person free-roam camera. The first-person hand script continues to check `get_first_person_enabled()`, so the viewmodel only exists in first-person mode.

Reference notes and the Minecraft Java camera source links are recorded in `CAMERA_REFERENCE.md`.


## Minecraft Java player model compatibility (0.7.0-alpha)

The body builder now follows the classic `PlayerModel` part dimensions from Minecraft Java 1.21.11:
- Head: 8×8×8
- Body: 8×12×4
- Both arms: 4×12×4
- Both legs: 4×12×4

The Fast64 output retains SM64CoopDX's required player bone names and hierarchy. The generated root scale is raised from 0.25 to 0.5 so the small normalized Blender source mesh is not rendered as a tiny point at the 4-block third-person camera distance.

References:
- `PlayerModel.java`: https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java
- `HumanoidModel.java`: https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java

The geometry proportions are recreated from the source API; Minecraft assets or proprietary textures are not copied. The visible body still uses the SteveCraft material palette rather than the full original skin atlas.

## Minecraft-style perspective controller (0.7.0-alpha)

The perspective controller now cycles with the Y button:
1. First person
2. Third-person rear
3. Third-person front

Both third-person views use SM64CoopDX's `CAMERA_MODE_ROM_HACK` implementation rather than `CAMERA_MODE_FREE_ROAM`. The mod enables its vanilla-course override and collision checks, sets both zoom distances to 400 engine units and both camera heights to 160 units. Those settings approximate Minecraft's four-block rear camera and eye-level focus for the current SM64 world scale.

D-pad controls while in third person:
- Up: centre behind Steve
- Left/Right: orbit around Steve
- Down: snap the orbit angle to 45-degree steps

The ROM_HACK camera's collision solver checks visibility using level surface raycasts and slides the camera toward a clear position. This is the fork's native solver, not a direct copy of Minecraft's eight-ray `Camera.getMaxZoom` implementation. Camera mode changes use zero transition frames and the fixed-camera seed resets interpolation before entering ROM_HACK.

## Minecraft humanoid animation port (0.9.0-alpha)

`animations.lua` bakes the Minecraft Java 1.21.11 humanoid formulas into the engine's native `Animation` value/index tables and registers these clips:

- Idle: `AnimationUtils.bobModelPart` on both arms
- Walk and run: `HumanoidModel.setupAnim` limb equations, with 0.60 and 1.00 fixed walk amounts
- Crouch and crouch-walk: the source torso and arm rotations, with the walk cycle retained when moving
- Swim: the source 26-phase arm stroke and leg flutter, sampled at the 30 Hz SM64 update rate
- Jump, fall and landing: the neutral humanoid pose with the normal Minecraft arm bob; vanilla Minecraft does not add a separate limb animation for a normal jump

The SM64 player GeoLayout has 20 animated nodes (the constant `MARIO_ANIM_PART_MAX` includes the NONE slot). Animation clips therefore use 63 channels: three root-translation slots plus three rotations for each animated node. The node order is kept identical to the stock player rig. Minecraft's local X/Y/Z rotations are remapped to the actor's local axes before baking.

There are deliberate limits in this first implementation. Minecraft calculates `walkAnimationPos` and `walkAnimationSpeed` from entity movement, while the Lua hook exposes SM64 animation IDs rather than that exact pair; consequently, walk and run use fixed amplitudes. Crouch rotations are applied, but the head/body/arm/leg positional offsets from Minecraft are not yet translated into SM64 local units. The normal jump remains neutral because that is closer to vanilla Minecraft than Mario's distinct jump pose.

Source references (decompiled community mirror of Java 1.21.11):
- `HumanoidModel.java`: https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java
- `AnimationUtils.java`: https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/AnimationUtils.java
- `PlayerModel.java`: https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java

## Model geometry optimization (0.9.0-alpha)

The Blender generator omits the two coincident internal quads where each turquoise sleeve meets its skin-coloured hand. It also welds the four shared seam vertices inside that same arm vertex group. Vertices are never welded across different animated groups, so the rigid joints stay independent. No silhouette faces are removed. The same optimization is applied to the metallic model variant.


## Body proportions and scale update (0.7.0-alpha)

The Blender actor builder now creates the classic Minecraft body proportions (head 8×8×8, torso 8×12×4, arms and legs 4×12×4) while keeping the SM64CoopDX player's named bone groups. After Fast64 export, the build script changes only the root `steve_geo` scale from 0.25 to 0.5. The build workflow checks the resulting GeoLayout scale.


## Model material and scale corrections (0.8.0-alpha)

The previous exported vertex arrays contain white RGBA values, while the `Shaded Solid` preset was emitting a combiner that read `SHADE`. That combination rendered the Steve pieces white rather than using their intended palette. The generator now patches each generated F3D material to use `PRIMITIVE` and emits `gsDPSetPrimColor` values for skin, hair, eyes, shirt, pants, shoes and metal.

The root GeoLayout is now set to scale 1.0 (65536 in 16.16 format), preserving the 8×8×8 head and the 8×12×4 / 4×12×4 body proportions at the scale exported by Fast64.

The workflow checks the final root scale and that the generated model contains the expected primitive-color setup.
