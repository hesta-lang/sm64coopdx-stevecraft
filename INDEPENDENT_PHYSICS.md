# SteveCraft native Mario isolation

## Scope

Version 0.19.0-alpha moves the local Steve player into a dedicated Lua locomotion action. MarioState and marioObj remain the engine-facing player state and interaction proxy, but they no longer choose or integrate Steve's normal walk/run/jump/fall/swim movement while isolation is active.

The mod does not modify SM64CoopDX C/C++ source or the APK.

## Native action replacement

At load time, SteveCraft registers `ACT_STEVECRAFT_CONTROLLED` with `hook_mario_action()`. The action uses the currently unused cutscene-group slot `0x13F` so the ordinary stationary/moving/airborne/submerged Mario action handlers are not dispatched. It preserves reading/dialog actions needed for text UI.

`HOOK_BEFORE_MARIO_UPDATE` moves an attached local Steve into this action. `HOOK_BEFORE_SET_MARIO_ACTION` redirects subsequent native locomotion and physical-action transitions back to the Steve action. The custom action calls the exposed ground, air and water step functions only as entry points: `HOOK_BEFORE_PHYS_STEP` returns SteveCraft's own step result before the engine's native movement resolver or gravity executes.

The custom action supplies Steve-specific animation selection. Its gravity action hook suppresses native `apply_gravity()` if any path requests it. The force-water-action hook prevents Mario from automatically switching Steve into Mario's native swimming/plunge actions.

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

Steve's detached DynOS actor now uses `MarioState.pos` and `MarioState.faceAngle` directly for its transform. Only animation descriptor/frame data are borrowed from Mario's object. This avoids copying a stale native transform or its graphical height corrections.

The hidden Mario proxy keeps its engine object and interaction state, but its native body alpha and `header.gfx.shadowInvisible` are disabled so the old black Mario shadow does not remain underneath Steve. The original body/shadow visibility values are restored when the proxy is destroyed.

## Known side effects and unfinished work

Using the cutscene action group intentionally skips native `mario_handle_special_floors()` and normal Mario quicksand/slide/swim/cutscene action dispatch. That means warp floors, lava/vertical-wind floor reactions, PSS timers, quicksand and other special-floor behaviors need SteveCraft implementations before all levels can be considered compatible. Door/object interaction handlers, health, damage, networking and the camera still live in the host engine; interactions can request action transitions, which are redirected to the Steve action.

Dialogs and sign-reading actions are preserved. Special cutscenes that require actual Mario movement are not fully reproduced. Remote players are not moved by this local isolation path.

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

## Validation

Automated tests cover the Lua geometry adapter and independent movement resolver with mocked surfaces. Proxy tests verify that Steve follows MarioState directly and hides/restores the native shadow. These tests do not prove that the Android runtime will behave correctly. A real SM64CoopDX Android test is required for standing height, ground contact, jumping, falls, walls, ceilings, water, dialog transitions, door/warp behavior and level bounds.
