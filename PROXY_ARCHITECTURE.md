# SteveCraft Proxy Architecture

## Goal

Keep Steve's visual model independent from SM64CoopDX's Mario mesh and normal locomotion, while retaining one engine-facing MarioState bridge for object interactions, health, networking and level systems.

## Current implementation

- **Engine bridge:** MarioState and marioObj remain registered with SM64CoopDX so the level can process interactions, damage and network state. The independent camera object owns the final Camera/Lakitu transforms. SteveCraft redirects the local player's ordinary locomotion into its own Lua action and resolves the intercepted movement steps itself.
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

## Independent camera

The local camera is no longer positioned by Mario/NEWCAM. A renderless Lua behavior runs in `OBJ_LIST_UNIMPORTANT`, after the player object and `first_person_update()` but before `update_camera()`. It calls `camera_freeze()` to stop the native camera update and writes the final position/focus to the writable XYZ components of `Camera` and `LakituState`.

First-person eye height is 1.62 Minecraft blocks when standing and 1.27 when crouching. Third-person back/front target four blocks and clip against SM64 level triangles using wall/floor/ceiling queries. This is a triangle-based approximation, not a Minecraft voxel VISUAL raycast. The independent eight-ray VISUAL math in `minecraft_26_3_camera.lua` is not connected to the game level.

Android look input uses D-pad left/right for yaw and up/down for pitch; C-buttons are an alternative if enabled in the touchscreen layout. Default speed is 2 degrees per frame. The fork's touchscreen Mouse handler calculates `touch_x/touch_y` but does not expose them to the Lua layer or copy them into the player controller, so a direct finger-drag gesture is not available to this standalone mod. A native binding would be required for real swipe-look. Mouse and analog input are reused when the fork updates `gFirstPersonCamera.yaw/pitch`.

The custom camera preserves the host's configured projection/FOV; it does not yet port Minecraft's sprint FOV changes or all camera easing curves.

## Validation and remaining work

Automated tests cover independent animation clip selection, proxy transform ownership, right-arm camera-space pose/swing, first-person eye-height conversion, camera perspective switching, physics isolation and the geometry adapter. These are unit/integration tests with mocks; they do not prove Android DynOS rendering.

Still requires in-game Android verification:
- actor regeneration and DynOS model resolution;
- body proportions, head/torso separation and joint rotations;
- idle, walk, run, crouch, swim and airborne movement animation;
- first-person arm position, scale and swing;
- standing/crouching eye height;
- third-person D-pad/C-button look and clipping on walls;
- mouse/analog input on the Android build if those inputs are enabled;
- local/remote player appearance and level interactions.

The render-only Steve object must never gain a second gravity, movement or collision controller. All physical movement continues through the single MarioState bridge to avoid double movement and camera/position divergence.
