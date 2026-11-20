# SteveCraft Proxy Architecture

## Goal

Keep Steve's visual model independent from SM64CoopDX's Mario mesh and normal locomotion, while retaining one engine-facing MarioState bridge for object interactions, health, networking and level systems.

## Current implementation

- **Engine bridge:** MarioState and marioObj remain registered with SM64CoopDX so the level can process interactions, damage, network state and the host camera. SteveCraft redirects the local player's ordinary locomotion into its own Lua action and resolves the intercepted movement steps itself.
- **Visual representation:** a separate, local-only Steve DynOS object is created for each player on each client. It has no interaction type, hitbox, gravity or physics body.
- **Body visibility:** the native Mario body is hidden with zero alpha while the proxy is attached. The native Mario shadow and detached Steve actor shadow are also hidden. Original Mario body/shadow visibility is restored when the proxy is destroyed.
- **Transform:** Steve follows `MarioState.pos` directly. It follows yaw only; pitch and roll are forced to zero so acrobatic Mario orientation cannot tip the Minecraft body sideways. The potentially delayed native marioObj graphical transform is not used as positional authority.
- **GeoLayout:** Steve's detached GeoLayout is sanitized to remove Mario-only alpha, head, torso and part-offset callbacks. Remaining player-state switches are retained for cap/body variants.
- **Animation:** `animations.lua` registers independent Minecraft humanoid clips and applies them directly to the detached Steve visual object. The controller reads SteveCraft's movement state; it does not depend on Mario's current animation ID or the DynOS model ID stored in player sync. Current clips are idle, walk, run, crouch, crouch-walk and swim. Walking/running animation continues in air while horizontal speed remains.
- **First person:** the detached body is hidden in first person. A separate 4×12×4 Steve right-arm actor is placed in camera space using first-person yaw/pitch, with movement bob and a B-button swing. Its screen-space placement is calculated from camera forward/right/up axes rather than Mario's wrist offset.
- **Multiplayer:** each client creates non-synchronized render-only copies for local and remote player states. Existing player networking remains responsible for the engine-facing player data.

## Movement and collision bridge

The local Steve controller writes position and velocity through MarioState's writable vector components and intercepts ground, air and water step hooks. The native geometry-input prepass is also bypassed; `steve_geometry.lua` repopulates the basic floor, ceiling, water and poison-gas contact fields without moving the player.

The collision source is still SM64CoopDX level surfaces. `sm64_collision_adapter.lua` samples floor, ceiling and wall triangles; `tri_collider.lua` resolves a proposed movement vector against those triangles. The normal geometry and movement corrections are not the movement authority for Steve while isolation mode is active.

This is not Minecraft voxel/AABB collision. The current footprint is radial, height and block-to-SM64 scale remain approximate, and level-specific warp/death-plane/PSS triggers, health, damage, interaction processing and networking remain engine-owned.

## Public Lua API

`SteveCraft.proxy` exposes:

- `update(marioState, modelId)`: register/update one player and ensure the Steve visual exists.
- `owns_mario_state(marioState)`: check whether that Mario state is managed by the proxy.
- `is_attached(playerIndex)`: check whether the separate Steve object is available.
- `get_state(playerIndex)`: read a copy of position, velocity, rotation, action, floor height, health and head position.
- `get_camera_anchor(playerIndex)`: read the physical proxy's position, head position and yaw.
- `get_physical_object(playerIndex)`: access the Mario collision/engine bridge object.
- `get_visual_object(playerIndex)`: access the separate Steve render object.
- `destroy(playerIndex)` / `reset()`: remove visual proxies.

`SteveCraft.physics.get_animation_state(marioState)` exposes the current Minecraft movement values used by the detached animation controller: horizontal/vertical speed, grounded/water/air state, crouching and sprinting.

## Camera limits

First-person eye height is adjusted to Minecraft's standing 1.62-block and crouching 1.27-block values using the writable `gFirstPersonCamera.offset.y` component. The native default first-person FOV is 70°; SteveCraft keeps the user's configured FOV rather than forcing it.

Third-person uses NEWCAM so Android touch orbit and native surface collision keep working. The Lua API exposes camera yaw, but not a writable final Camera/Lakitu position or focus, nor a Minecraft block VISUAL raycaster. Exact four-block third-person distance and Minecraft's eight-ray clipping therefore cannot yet be applied to the live camera without adding a C/C++ engine hook.

## Validation and remaining work

Automated tests cover independent animation clip selection, proxy transform ownership, right-arm camera-space pose/swing, first-person eye-height conversion, camera perspective switching, physics isolation and the geometry adapter. These are unit/integration tests with mocks; they do not prove Android DynOS rendering.

Still requires in-game Android verification:
- actor regeneration and DynOS model resolution;
- body proportions, head/torso separation and joint rotations;
- idle, walk, run, crouch, swim and airborne movement animation;
- first-person arm position, scale and swing;
- standing/crouching eye height;
- third-person touch orbit and clipping on walls;
- local/remote player appearance and level interactions.

The render-only Steve object must never gain a second gravity, movement or collision controller. All physical movement continues through the single MarioState bridge to avoid double movement and camera/position divergence.
