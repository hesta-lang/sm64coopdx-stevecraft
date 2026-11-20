# SteveCraft Java to Lua transpilation

This pipeline belongs to the independent repository hesta-lang/sm64coopdx-stevecraft. It does not add SteveCraft code to the SM64CoopDX source tree and does not build or patch an APK.

## Purpose

Translate a deliberately limited subset of Minecraft Java source into Lua 5.4 modules that can be adapted for the SteveCraft mod. The converter is conservative: if a method contains unsupported syntax, it omits that entire method and records the reason in transpile-report.json. It does not emit guessed code.

## Run

    python3 tools/java_to_lua.py \
      --input /path/to/minecraft-java-sources \
      --output build/minecraft-lua \
      --version 26.3

Select individual classes with repeatable --class fully. Use --strict in CI or review builds to fail when a selected class has skipped methods or files.

Generated package directories preserve Java package names. Imported project classes become Lua require() calls. mc_compat.lua contains a limited Mth compatibility implementation; engine-facing classes still need explicit adapters to SM64CoopDX APIs.

## Minecraft 26.3 target inventory

tools/minecraft_26_3_targets.json records three real 26.3 targets and their dependency boundary:

- net.minecraft.util.Mth: a partial, manually ported set of numeric helpers is available in mc_compat.lua. The complete overloaded Java class is not translated.
- net.minecraft.client.model.HumanoidModel: inventoried, not yet transpiled. It depends on generic inheritance, constructors, model-part/geometry builder object graphs, pose stacks, collections, and renderer state.
- net.minecraft.client.model.player.PlayerModel: inventoried, not yet transpiled. It extends HumanoidModel<AvatarRenderState> and contains the Steve overlay visibility and slim-arm behavior, but its methods depend on model geometry, collections, renderer types, and inherited behavior.

The inventory references an unofficial decompiled source browser for class metadata. No Mojang source tree, JAR, texture, or generated Minecraft class file is included in this repository. The manifest test checks target identity, hierarchy, and the declared partial-port boundary; it does not claim that the full classes were transpiled.

## Current supported subset

- Top-level Java classes and primitive/simple-reference method signatures.
- Static final scalar constants and simple local declarations.
- Arithmetic, comparisons, boolean expressions, Math calls, and listed Mth mappings.
- if/else, while, simple constant-bound numeric for loops, return, and break.
- Imports of other simple project classes and calls between generated modules.

## Not supported / not yet equivalent

Constructors and object lifecycle, inheritance and virtual dispatch, interfaces/generics, nested/anonymous classes, overload resolution, Java arrays and collections, lambdas/streams, switch, exceptions, reflection, synchronization, native methods, and engine rendering/entity/world systems are not translated. Unsupported methods are reported and omitted.

Lua 5.4 has one general numeric type; this pipeline does not preserve Java long precision, integer overflow, exact narrowing-cast behavior, or all Java integer-division edge cases. The current Mth compatibility helpers therefore do not claim exact Java integer semantics for all overloads.

## Validation boundary

GitHub Actions validates the Java-subset fixtures, the Lua runtime assertions, and the 26.3 target inventory. Fixture success is not evidence that the full HumanoidModel or PlayerModel source has been transpiled or that generated modules work inside SM64CoopDX. Each translated subsystem must pass adapter-level tests before it is enabled in SteveCraft.

## Minecraft 26.3 physics and camera behavior ports

The runtime modules minecraft_26_3_physics.lua and minecraft_26_3_camera.lua are independent Lua ports of selected behavior from LocalPlayer, LivingEntity, Entity, and Camera. They are not emitted by the current generic java_to_lua.py converter: that converter does not yet support the constructors, entity lifecycle, world collision, renderer state, or engine APIs needed by those full classes. The new modules therefore express the source behavior in tested Lua functions and keep engine-specific bindings in physics.lua/camera.lua.

Coverage and limitations are recorded in tools/minecraft_26_3_physics_camera.json. The port covers ordinary ground/air movement, input shaping, sprint double-tap, jump impulse, gravity/drag, camera interpolation, perspective transforms, target distance, and the eight-ray clipping calculation.

Important gaps remain: SM64 does not expose Minecraft's item-use/hunger/attribute state by default; block friction is 0.6 unless a provider is supplied; SM64 triangle collisions are not Minecraft voxel/AABB collisions; the camera ray routine is not wired to a Minecraft block raycaster; and Lua bindings make camera position/focus read-only. These ports are not a claim of 100% vanilla equivalence and have not yet been tested in the Android game.
