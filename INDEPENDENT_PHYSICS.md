# SteveCraft native Mario isolation

## Scope

Version 0.22.0-alpha moves the local Steve player into a dedicated Lua locomotion action. MarioState and marioObj remain the engine-facing player state and interaction proxy, but they no longer choose or integrate Steve's normal walk/run/jump/fall/swim movement while isolation is active.

The mod does not modify SM64CoopDX C/C++ source or the APK.

## Native action replacement

At load time, SteveCraft registers `ACT_STEVECRAFT_CONTROLLED` as an unused stationary-group action with `ACT_FLAG_CUSTOM_ACTION`, but without `ACT_FLAG_INTANGIBLE` or `ACT_FLAG_INVULNERABLE`. Its Lua callback suppresses native `act_idle()` while keeping the state eligible for object interactions and `mario_ready_to_speak()`. NPC dialogue and sign-reading remain available.

`HOOK_BEFORE_MARIO_UPDATE` moves an attached local Steve into this action. `HOOK_BEFORE_SET_MARIO_ACTION` redirects subsequent native locomotion and physical-action transitions back to the Steve action. The custom action calls the exposed ground, air and water step functions only as entry points: `HOOK_BEFORE_PHYS_STEP` returns SteveCraft's own step result before the engine's native movement resolver or gravity executes.

The custom action supplies Steve-specific animation selection. Its gravity action hook suppresses native `apply_gravity()` if any path requests it. The force-water-action hook prevents Mario from automatically switching Steve into Mario's native swimming/plunge actions. The hazard-surface hook blocks Mario's quicksand sinking, lava boosts and wind reactions for the local Steve. Terminal death actions remain native; warp/death-plane and PSS timers remain level mechanics.

## Native geometry replacement

`HOOK_MARIO_OVERRIDE_GEOMETRY_INPUTS` returns `false` for the attached local Steve. The C implementation then returns before `update_mario_geometry_inputs()` calls:
- `f32_find_wall_collision()` (both native wall/position corrections);
- native floor and ceiling updates;
- native water-level and poison-gas-level updates;
- Mario's slope-slide, squish and off-floor input flag generation.

Before returning false, `steve_geometry.lua` repopulates only the contact data required by the engine bridge and Steve controller: floor and ceiling references/heights, water/gas levels, floor angle, and basic in-water/off-floor/gas flags. It does not alter MarioState position. Missing floor results retain the last known floor pointer only to keep the host action dispatcher alive; the Steve controller's own `onGround` flag remains based on the current real floor query.

## Movement and collision

`HOOK_BEFORE_PHYS_STEP` cancels the native `perform_ground_step`, `perform_air_step` and `perform_water_step` work. `independent_physics.lua` writes the accepted position and velocity through writable `MarioState.pos/vel` vector components, updates the host object's graphical transform and returns the appropriate native step result.

The collision source remains SM64CoopDX's level-surface queries, adapted to the Lua SkyCraft triangle solver. The current body approximation is a radius of 0.3 Minecraft blocks and height of 1.8 blocks, with a default 0.6-block step height. This is **not** a Minecraft voxel/AABB grid, and scale is still provisional at 160 SM64 units per 1.8 metres.

When a Lua movement step cannot be resolved, SteveCraft returns a neutral step result and stops that step rather than falling back to Mario's native movement. This avoids mixing two physical systems, but it can leave Steve temporarily stopped if geometry queries fail.

## Visual proxy

Steve's detached DynOS actor uses `MarioState.pos` and player yaw directly. Body pitch and roll are zeroed so Mario's acrobatic tilt never rotates Steve's whole cuboid body. The detached actor no longer borrows Mario's animation descriptor: `animations.lua` selects and applies independent Minecraft humanoid clips from SteveCraft's horizontal speed, sprint, crouch and water state. Its walk/run cycle remains active in air while horizontal speed remains.

The detached GeoLayout is sanitized at export time to remove `geo_mirror_mario_set_alpha`, `geo_move_mario_part_from_parent`, `geo_mario_tilt_torso` and `geo_mario_head_rotation`. These callbacks otherwise copy Mario-specific opacity, part offsets, torso lean and head rotation into the Steve rig.

The hidden Mario proxy keeps its engine object and interaction state, but its native body alpha and `header.gfx.shadowInvisible` are disabled. The detached Steve actor also has `header.gfx.shadowInvisible=true`, preventing either SM64-generated shadow from producing the black oval. No custom Minecraft-style shadow is drawn yet. The original Mario body/shadow visibility values are restored when the proxy is destroyed.

The separate first-person right arm is a 4×12×4 DynOS cuboid. Its shoulder position and long axis are calculated from first-person camera forward/right/up vectors, with movement bob and a B-button attack swing. The camera bridge adjusts eye height to Minecraft's 1.62-block standing and 1.27-block crouching values using the writable `gFirstPersonCamera.offset.y` component.

## Known side effects and unfinished work

Because the controller action is stationary rather than cutscene-group, `mario_handle_special_floors()` still runs. The hazard hook blocks quicksand, lava and wind movement effects, but warp/death-plane and PSS timer triggers remain native level mechanics. Terminal death actions are also preserved. Door/object interactions and NPC dialogue continue to use the host engine and can request transitions back into the Steve controller action. Sign-reading actions remain native. Health, damage and networking remain engine-owned. The camera position/focus are controlled by `camera.lua`; the host still supplies controller button state, optional mouse/analog yaw/pitch and the level's triangle surface queries.

Special cutscenes that require actual Mario movement are not fully reproduced. Remote players are not moved by this local isolation path.

This version still uses triangle geometry, not voxel collision. It does not provide exact Minecraft block material, moving-platform, fluid-current, lava, ladder, mount, status-effect or attribute behavior.

## Runtime toggles

The default mode is enabled. To deliberately restore the native player action/movement path for diagnosis:

```lua
SteveCraft.physics.set_independent_mode(false)
```

Re-enable it with:

```lua
SteveCraft.physics.set_independent_mode(true)
```

The geometry prepass is disabled by default while isolation is active. It can be toggled for diagnosis with:

```lua
SteveCraft.physics.set_native_geometry_disabled(false)
SteveCraft.physics.set_native_geometry_disabled(true)
```

## Independent camera

The custom camera controller runs after the Mario/player object and before the engine's normal `update_camera()`. It enables the existing first-person orientation source, freezes the native camera update with `camera_freeze()`, and writes the final `Camera` and `LakituState` vector components directly from Lua.

First-person eye height is 1.62 blocks standing and 1.27 blocks crouching. Third-person back/front target four blocks with a 16-step collision sweep using SM64 wall/floor/ceiling triangle queries. This collision is an approximation; it is not Minecraft voxel/AABB or VISUAL block raycasting.

On Android, D-pad buttons control yaw and pitch; optional C-buttons also work when shown in the touchscreen layout. Direct touch-drag is not available to this mod because the fork's touchscreen `touch_x/touch_y` deltas are not exposed through Lua or MarioState. Mouse/analog angles are reused where the host provides them. See `CAMERA_REFERENCE.md` for the input limitation and runtime details.

## Validation

Automated tests cover the Lua geometry adapter, independent movement resolver, detached animation clip selection, proxy transform ownership, first-person arm pose/swing, camera pose/eye-height conversion, D-pad look input, four-block orbit and triangle wall clipping. These tests do not prove that the Android DynOS runtime will behave correctly. A real SM64CoopDX Android test is required for standing height, ground contact, jumping, falls, walls, ceilings, water, dialog transitions, door/warp behavior and level bounds.
