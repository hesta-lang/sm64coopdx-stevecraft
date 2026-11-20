# SteveCraft independent movement controller

## Ownership model

The local player's movement is owned by SteveCraft in the normal ground, air and water step paths. Mario is retained as the engine-facing state carrier and interaction proxy; its native model is hidden while the detached Steve object is rendered.

The controller uses two APIs from the Android fork:

- `HOOK_BEFORE_PHYS_STEP` runs before `perform_ground_step`, `perform_air_step` and `perform_water_step`.
- A numeric return value causes the corresponding engine function to return immediately with that step result.

When the Lua collision adapter resolves a move, SteveCraft updates the nested `MarioState.pos.x/y/z` and `MarioState.vel.x/y/z` components, synchronizes the Mario object's graphics transform, and returns a compatible ground/air/water result. This bypasses the native position integration, native final collision step and the gravity call at the end of `perform_air_step`.

The Android fork's generated Lua bindings mark the `MarioState.pos` and `MarioState.vel` properties read-only, but expose them as mutable `LOT_VEC3F` C objects; the nested `Vec3f.x/y/z` fields are writable. This is why the implementation writes components instead of assigning a new vector to `m.pos` or `m.vel`.

## Collision source and limits

SteveCraft still calls the engine's `find_floor`, `find_ceil` and wall-collision query functions to sample level surfaces. Those triangles are passed to the Lua port of SkyCraft TriCollider. The native movement step is bypassed, but the source geometry is not converted into Minecraft blocks.

The current horizontal player footprint is an approximation: a radius of 0.3 Minecraft blocks and a height of 1.8 blocks. It is not a true rectangular AABB swept against a voxel grid. Step height defaults to 0.6 blocks. Scale remains provisional at 160 SM64 units per 1.8 m.

The independent override is attempted for `STEP_TYPE_GROUND`, `STEP_TYPE_AIR` and `STEP_TYPE_WATER`. It falls back to the old native path when surface queries, collision sampling, or position writes fail. Special actions which do not call those three step functions are not universally replaced. Existing Mario health, damage, interactions, level bounds, camera, and networking remain part of the host engine.

## Toggle

The mode is enabled by default:

```lua
SteveCraft.physics.set_independent_mode(true)
```

Disable it temporarily to compare native behavior:

```lua
SteveCraft.physics.set_independent_mode(false)
```

Availability can be queried with:

```lua
SteveCraft.physics.is_independent_collision_available()
```

## Validation status

CI tests verify the Lua controller's ground movement, wall clipping, floor landing, ceiling clipping, water floor contact, and graphics transform synchronization using mocked collision queries. They do not replace a real Android test. In-game verification is still needed for action transitions, edge falls, slopes, stairs, moving platforms, multiplayer state, and world bounds.
