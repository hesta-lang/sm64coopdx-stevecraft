# SteveCraft Proxy Architecture

## Goal

Separate the player representation from the entity that SM64CoopDX simulates, without creating two competing physics bodies.

## Current implementation

- **Physical authority:** the engine's existing `MarioState` and `marioObj`. They continue to own movement, surface collision resolution, gravity, hit reactions, and the native camera's follow target.
- **Visual representation:** a separate, local-only Steve DynOS object is created for each player on each client. It has no interaction type, no hitbox, no gravity, and no independent movement controller. The native Mario body is hidden with zero alpha while the proxy is attached, preserving non-alpha model flags; the original body state is restored when the proxy is destroyed.
- **Transform:** the visual object copies position and orientation from the matching Mario object every object update.
- **Animation:** the visual copies the source object's animation descriptor, frame, timing, animation table, and scale. Steve's generated GeoLayout uses the same animated player hierarchy, so the normal player animation data can drive the detached mesh.
- **Head and torso:** Steve's GeoLayout uses the standard Mario head/torso Geo ASM callbacks. The visual object's `globalPlayerIndex` is set from `gNetworkPlayers[playerIndex].globalIndex`, allowing those callbacks to resolve the correct player's body-state data.
- **Multiplayer:** each client creates non-synchronized render-only copies for the local and remote Mario states. This avoids sending duplicate visual entities over the network; player motion remains synchronized by the game's existing player system.
- **First person:** the detached full body is hidden while the game's first-person mode is active. The existing Steve hand viewmodel remains responsible for the arm on screen.

## Triangle collision adapter

`tri_collider.lua` is a Lua adaptation of SkyCraft's `TriCollider.java` and `SkyTri.java` (MIT). `sm64_collision_adapter.lua` samples actual SM64 floor, ceiling, and wall triangles through the documented Lua API, then returns a pre-clipped movement vector. The normal SM64 physics step is not cancelled.

The feature is controlled by `SteveCraft.physics.set_triangle_collision_enabled(boolean)`. It is enabled by default when its API is present. Disable it if it causes extra bumps, sticking, or slope jitter; no Android in-game run has validated those interactions yet.

The solver only handles triangle geometry. It does not implement gravity, jump velocity, sprint acceleration, water movement, or Minecraft block rules. MarioCraft gets those values from a separately running Minecraft Java client, which is not part of this Android mod.

## Public Lua API

`SteveCraft.proxy` exposes:

- `update(marioState, modelId)`: register/update one player and ensure its Steve visual exists.
- `owns_mario_state(marioState)`: check whether that Mario state is managed by the proxy.
- `is_attached(playerIndex)`: check whether the separate Steve object is available.
- `get_state(playerIndex)`: read a copy of position, velocity, rotation, action, floor height, health, and head position.
- `get_camera_anchor(playerIndex)`: read the physical proxy's position, head position, and yaw.
- `get_physical_object(playerIndex)`: access the Mario collision/physics object.
- `get_visual_object(playerIndex)`: access the separate Steve render object.
- `destroy(playerIndex)` / `reset()`: remove visual proxies.

## Important limits

This is a representation/authority split, not a complete Minecraft physics port. The movement layer writes through the one MarioState. A SkyCraft-derived triangle pre-resolver can clip proposed ground/air displacement using surfaces sampled from the documented SM64CoopDX Lua collision API; the original engine step still runs afterward and remains the final contact authority. The visual Steve object never performs physics. This does not add Minecraft voxel/AABB collisions, full material friction, water/lava rules, or a new camera implementation.

The camera remains attached to the existing physical player because the Lua API does not expose a supported writable Lakitu position/focus target. The proxy exposes a consistent camera anchor for future camera work, while NEWCAM and the engine continue to handle actual tracking and touch orbit.

The detached Steve model mirrors the engine's current animation descriptor. This preserves the current SM64 animation set; it does not yet replace those clips with Minecraft's original Java animation controllers.

## Safety rule

Never add independent gravity, velocity integration, or collision resolution to the Steve render object. Any future Minecraft-like movement code must write through the one physical MarioState authority and then let the engine resolve contacts. This prevents double movement, jitter, and mismatched camera/collision positions.
