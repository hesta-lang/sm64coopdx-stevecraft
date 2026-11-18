# SteveCraft native reverse-engineering plan

## Purpose

This document changes the implementation strategy from a Blender-only character export toward a small native C++ player-model/runtime layer for the Android SM64CoopDX fork. It is not a plan to port the entire Minecraft game.

The relevant target is the Steve functionality already in SteveCraft: the Java player model, skin/outer layers, humanoid pose and animations, first-/third-person camera, and first-person arm. SM64CoopDX remains responsible for its own world, collision, character movement, level logic, rendering backend, and multiplayer transport unless a measured requirement proves otherwise.

## Verified facts and current blockers

1. The current Android fork is a native project. Its `Android.mk` enumerates both `*.c` and `*.cpp` files from `SRC_DIRS`, including `src/engine` and `src/game`. It also builds with Android NDK for `arm64-v8a`. C++ is therefore technically available, but only in a fork whose APK is rebuilt.
2. The mod repository is not itself a native extension point. A Lua/DynOS mod loaded from the mods folder cannot add a new `.cpp` translation unit to an already-built APK. Lua can remain a configuration/hook layer, but native runtime code must be compiled into a custom SM64CoopDX build.
3. The current generated `actors/steve/model.inc.c` is still the earlier primitive-colour model. Workflow run #26 stopped before replacing it: Fast64-Gart rejected the UV layer name. This explains why an installation using those committed actor files can still show the old simplified Steve model.
4. Workflow run #26 successfully generated the 12 small skin UV crops, then failed at Fast64 export with: `Object '' does not have a UV layer named 'UVMap.'`. The builder had named the layer `MinecraftSkinUV`. The native-reverse-port branch changes that layer to the required `UVMap`; the next workflow run must confirm whether export can proceed.
5. The current `animations.lua` is a partial adaptation of humanoid pose formulas. It uses fixed walk/run amplitudes, does not yet reproduce Minecraft's full local pose hierarchy/offsets, and maps those rotations onto SM64's existing animated nodes. It is not a complete port of Minecraft's animation runtime.
6. The current camera script delegates third-person behavior to SM64CoopDX's native camera system. It does not translate Minecraft's complete `Camera` class or collision-query stack.

## Swirly reference: what is and is not verified

The 30 September 2026 80 Level article describes Swirly's project as being built on an existing SM64CoopDX fork and says an in-depth technical breakdown and release were planned. A 4 October 2026 repost reproduces his announcement that the breakdown was coming. Those sources do not document the actual C++/Java translation architecture or expose the implementation.

References:
- https://80.lv/articles/someone-just-put-all-of-minecraft-into-super-mario-64
- https://kyami-777.hatenablog.com/entry/2026/10/04/110000

Therefore, SteveCraft must not claim to copy Swirly's internal method until his technical breakdown or source code can be inspected. The public MarioCraft project by a different author is not evidence of Swirly's method: MarioCraft explicitly runs a hidden Minecraft Java instance alongside SM64CoopDX and bridges their state. That is a different architecture.
- https://github.com/Boom64dude/MarioCraft

## Reverse-engineering scope

The phrase "all of Minecraft's source" is too broad for a Steve character mod. Minecraft contains unrelated systems (world generation, block/entity simulation, networking, menus, resource packs, audio, account/session services, platform code, and a modern renderer). Porting all of that would effectively create a second game engine inside SM64CoopDX and would not fix the character model.

The useful dependency slice is:

### Model and skin
- `PlayerModel`, `HumanoidModel`, `ModelPart`, `ModelPart.Cube`, `PartPose`, and `CubeListBuilder`.
- Reproduce model-part parentage, pivots, per-part local cuboid coordinates, cube inflation, mirrored faces, skin UV rectangles, overlay visibility, and the 64x64 classic skin layout.
- Do not map Minecraft's absolute model coordinates straight onto arbitrary SM64 vertex groups. Each model part must be transformed through its local pivot and the chosen SM64 bind-pose transform. The pivot hierarchy is the central missing validation step.
- Keep the N64/F3D texture-size, alpha, filtering, and display-list limits. Minecraft's modern rendering pipeline is not available in the target engine.

### Animation
- `HumanoidModel.setupAnim`, `AnimationUtils`, `AnimationState`, `AnimationDefinition`, `AnimationChannel`, and `KeyframeAnimations`, plus the entity movement values that feed them.
- Port the pose evaluation as original C++ code: hierarchical part transforms, interpolation, easing, limb swing, idle bob, crouch, swim, attack/use-item arm poses, and the first-person arm swing.
- Translate the resulting pose into the SM64 actor's animation/GeoLayout nodes. Do not assume Minecraft's part order or local rotation axes match Mario's animation channel order.

### Camera and first-person view
- `Camera` perspective setup, eye-height/focus interpolation, rear/front third-person orientation, desired camera distance, and camera collision shortening.
- Reuse SM64CoopDX's level collision/raycast and Android touch input where possible. Port the camera rules and coordinate transforms, not an entire second world collision engine.
- Treat the first-person arm as a separate camera-attached viewmodel with its own swing and movement offsets, not as a normal world-space arm.

## Proposed target architecture

| Layer | Responsibility | Implementation |
|---|---|---|
| Minecraft behavior reference | Define dimensions, pivots, UVs, pose equations and camera rules | Decompiled/community source as a reference; independently written compatible code |
| Native player model | Build/cache Steve part geometry and per-part transforms | C++ compiled into the Android SM64CoopDX fork |
| Native pose evaluator | Evaluate Minecraft-style pose and map it to the actor rig | C++ called once per player update |
| SM64 render adapter | Convert transformed parts to SM64 GeoLayout/DynOS/F3D-compatible resources | Existing SM64 renderer and actor structures; no OpenGL renderer replacement |
| Camera adapter | Apply Minecraft-like first-/third-person parameters and touch look | C++ engine integration using existing SM64 collision and Android input |
| Mod configuration | Toggle perspectives, select skin, expose options and debug controls | Lua only where the existing API is sufficient |

The first native implementation should be isolated behind a small C-compatible interface so SM64's existing C game code can call it and the C++ implementation remains self-contained. The Android build must compile the source into the APK. The existing Lua mod can call exposed functions only after the fork adds and registers those bindings.

## Integration constraint

The connected GitHub account can update `hesta-lang/sm64coopdx-stevecraft`, but it currently has read-only access to `ManIsCat2/sm64coopdx`. Adding C++ files to SteveCraft's mod folder would not make Android compile them. Native integration requires a writable fork of the Android engine and a rebuilt APK; no fake `.cpp`-inside-a-Lua-mod workaround will be used.

## Implementation order

1. Make the existing model-generation workflow export successfully and stop distributing stale primitive actor files.
2. Inspect the template armature's rest transforms and derive the exact conversion from each Minecraft part-local coordinate system to each SM64 bone's bind space.
3. Validate an unanimated standing Steve before adding any custom pose. Confirm head above torso, both arms at shoulders, both legs at hips, front face toward the camera, and correct ground contact.
4. Port the model-part and pose evaluation into a native C++ module in the Android engine fork.
5. Add the camera and first-person viewmodel integration after the body pose is verified.
6. Test Android arm64-v8a with idle, walk, run, crouch, jump, fall, swim, front/rear third person, touch orbit, and multiplayer.

## Acceptance criteria

- The unanimated player stands upright in the same rest orientation as the stock SM64 actor.
- Minecraft's base and outer cuboids have the right pivots, mirroring, face winding, UVs and alpha.
- The limbs rotate around the correct shoulder/hip pivots, without stretching or detaching.
- Animation pose matches the source equations at equivalent animation phase and speed.
- First-/third-person transitions are immediate; touch orbit works without camera drift.
- Android build succeeds and the new runtime is actually compiled into the installed APK.
- Multiplayer clients see the same player model and pose without replacing SM64's world simulation.

## Source notes

The Minecraft references currently used are from a community-maintained decompilation mirror of Java 1.21.11, not an official Mojang source release:
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/player/PlayerModel.java
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/HumanoidModel.java
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/model/geom/ModelPart.java
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/Camera.java
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/AnimationUtils.java

This project uses those sources to understand behavior and write a compatible implementation; it does not copy or translate the complete proprietary Minecraft source tree.
