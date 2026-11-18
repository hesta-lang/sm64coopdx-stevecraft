# Camera and player-physics reverse engineering

## Scope and source basis

The target behavior is Minecraft Java 1.21.11. The source reference is the public community decompilation mirror below, not an official Mojang source release. The port should reproduce the player-facing rules and adapt them to SM64CoopDX's camera, surface collision and MarioState systems. It should not import a second world engine.

### Minecraft Java 1.21.11 classes examined

- `net.minecraft.client.Camera`: focus/eye-height interpolation, camera orientation, first/rear/front perspective placement, camera-distance scaling and third-person zoom collision.
- `net.minecraft.world.entity.Entity`: delta movement, input-relative movement, gravity, swept bounding-box collision and collision flags.
- `net.minecraft.world.entity.LivingEntity`: air, water and lava travel, friction, movement acceleration, jump impulse and fluid movement.
- `net.minecraft.client.player.LocalPlayer`: local input and view angles are updated separately from server movement synchronization.

Code references:
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/Camera.java
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/Entity.java
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/world/entity/LivingEntity.java
- https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/player/LocalPlayer.java

## 1. Minecraft camera behavior

### Focus point and interpolation

`Camera.setup(level, entity, detached, mirror, partialTick)` performs these operations:

1. Interpolate entity world position from previous position (`xo/yo/zo`) to current position using the render partial tick.
2. Add the interpolated eye height.
3. Apply view yaw and pitch from the focused entity.
4. In rear/front third-person mode, move backward along the rotated camera axis after shortening the desired distance against level geometry.
5. In first-person mode, retain the eye position without a rear camera offset.

`Camera.tick()` stores the previous eye height and approaches the entity's current eye height by half the remaining difference:
`eyeHeight += (entity.getEyeHeight() - eyeHeight) * 0.5`.
Rendering then interpolates between the old and new smoothed eye heights. This means the camera follows crouch/pose height without snapping.

### Orientation and perspective

The camera starts with local basis vectors:
- FORWARDS = (0, 0, -1)
- UP = (0, 1, 0)
- LEFT = (-1, 0, 0)

`setRotation(yaw, pitch)` constructs a Y-X-Z rotation using angles `PI - yawRadians`, `-pitchRadians`, and zero roll, then rotates all three basis vectors.

For third-person front view, Java changes yaw by 180 degrees and negates pitch before calculating the camera arm. This makes the view face the player rather than merely moving the camera to the opposite side.

The default detached camera distance is 4.0 units. For living entities it is multiplied by entity scale and the `CAMERA_DISTANCE` attribute. If riding a living mount, the camera uses the greater of the player's scaled distance and the mount's scaled distance.

### Camera collision: the eight-ray zoom solver

`getMaxZoom(distance)` runs eight ray tests from the corners of a 0.2 × 0.2 × 0.2 cube centered on the eye:
- Each coordinate offset is either -0.1 or +0.1.
- Every ray points backward along the camera's rotated forward vector.
- The query uses visible block geometry and excludes fluids.
- The nearest hit shortens the current camera distance; all later rays use that shorter distance.

This is not a sphere sweep. It is eight short offset line tests intended to reduce wall clipping around the camera body. The hit distance is measured from the central camera origin, not from each offset start point.

### Touch-look mapping for Android

Minecraft Java's `Camera` class does not read touch input itself; it consumes the focused entity's view rotation. The Android adaptation should therefore keep input collection separate from camera placement.

The SM64CoopDX fork already has a `TOUCH_MOUSE` region in `controller_touchscreen.c`. Its `Mouse` touch handler computes per-event X/Y deltas, applies the configured deadzone, and exposes `touch_x/touch_y`. Its first-person camera reads mouse-relative deltas and controller extension-stick input. The camera runtime should consume those deltas once per game update, not integrate the same touch movement in both the controller and camera layers.

## 2. SM64CoopDX camera behavior to reuse

Files inspected in `ManIsCat2/sm64coopdx`:
- `src/game/camera.c`
- `src/game/camera.h`
- `src/game/first_person_cam.c`
- `src/game/first_person_cam.h`
- `src/pc/controller/controller_touchscreen.c`
- `src/pc/controller/controller_mouse.c`

Relevant existing behavior:
- `update_camera()` already dispatches to native modes, including `CAMERA_MODE_NEWCAM`, `CAMERA_MODE_ROM_HACK`, `CAMERA_MODE_FREE_ROAM`, and the behind-Mario camera.
- The first-person override has a dedicated `gFirstPersonCamera` state and can freeze normal Lakitu camera processing while active.
- First-person look combines controller extension-stick/C-button input with mouse deltas. The fork scales X and Y sensitivity separately, clamps pitch to approximately ±0x3F00 angle units, and can re-center yaw with the left trigger.
- First-person head height is 120 engine units, lowered toward 60 while crouching/ledge-grabbing. Crouch height approaches in increments of 10 per update.
- The first-person camera writes its position and focus directly from Mario's position, camera yaw and pitch, and sets horizontal/vertical camera interpolation speeds to zero.
- `collide_with_walls(pos, offsetY, radius)` uses the level's wall-surface query and projects the camera position out along wall normals.
- `resolve_geometry_collisions(pos, lastGood)` checks wall collision, floor and ceiling, then clamps the camera between floor +125 and ceiling -125 where both exist.

### Camera adapter design

The native C++ camera module added in this branch implements Minecraft's camera transform and zoom mathematics. It intentionally does not implement a new world collision structure.

The Android engine adapter should:
1. Interpolate Mario's previous/current world position and eye-height value.
2. Feed view yaw/pitch and the selected perspective into `steve_mc_camera_build()`.
3. Implement `SteveMcCameraRaycastFn` using SM64 level-surface queries. For an accurate visual-block test, compare the ray result to the engine's visible camera-blocking surfaces; do not blindly treat water as a blocker.
4. Apply the resulting camera position/focus to the active SM64 camera mode.
5. Keep the touchscreen `TOUCH_MOUSE` region as the sole touch-delta source. Convert its deltas to yaw/pitch once, then let the camera consume the updated angles.
6. Preserve SM64's native cutscene, pause, cannon, water-surface and level-specific camera overrides.

The existing first-person camera is useful as a reference for input and head-height adaptation. For third-person Minecraft behavior, do not reuse its one-unit camera-arm formula: use the four-block detached camera arm and eight-ray shortening solver instead.

## 3. Minecraft player movement and physics

### Input-relative acceleration

`Entity.moveRelative(speed, input)` obtains a movement vector from the local input and the entity's yaw:
- Normalize the input only when its length exceeds 1.
- Multiply the normalized input by the requested speed.
- Rotate X/Z by yaw while preserving the vertical input component.
- Add the result to current delta movement; it is acceleration, not a direct position assignment.

The exact horizontal transform is:
`x' = x*cos(yaw) - z*sin(yaw)`
`z' = z*cos(yaw) + x*sin(yaw)`

### Ground and air travel

`LivingEntity.travel()` selects fluid travel, fall-flying travel, or air travel.

For ordinary air travel:
1. Read friction from the block below only while grounded; airborne friction is 1.
2. Horizontal friction for the end of the tick is `blockFriction * 0.91`.
3. On ground, movement acceleration speed is `getSpeed() * (0.21600002 / blockFriction^3)`.
4. In the air, acceleration speed is the entity's flying/air-control speed.
5. Add relative input acceleration and ask `Entity.move()` to move by current delta movement.
6. Apply effective gravity to vertical movement.
7. Apply horizontal friction to X/Z and 0.98 vertical drag (except movement modes that discard friction).

The movement speed and gravity values are attributes/state, not constants to hardcode into the SM64 engine adapter. The C++ prototype accepts them as inputs.

### Jump

`jumpFromGround()` computes:
`jumpPower = JUMP_STRENGTH * blockJumpFactor + jumpBoostPower`.
It sets vertical delta movement to the greater of the current Y velocity and jumpPower. While sprinting it adds a horizontal impulse of magnitude 0.2 in the yaw-forward direction.

The jump power therefore depends on attributes and supporting block state. A compatible Steve adapter must preserve those input values rather than assuming every jump has the same vertical velocity.

### Water and lava

Water travel uses:
- Input acceleration speed 0.02 by default.
- Horizontal slowdown 0.8 normally or 0.9 while sprinting.
- Water-movement efficiency can blend both slowdown and acceleration toward land movement.
- Vertical drag 0.8, then a gravity/16 adjustment when applicable.
- Separate +0.04 / -0.04 vertical impulses for jumping upward/downward in water.
- A separate surface-exit check when horizontal collision and clearance conditions allow jumping out.

Lava travel uses input speed 0.02, horizontal/vertical damping based on fluid depth, and gravity/4. Fall-flying has a separate steering and lift path and is not included in the current C++ prototype.

### Collision behavior that must not be copied literally

Minecraft `Entity.collide()` resolves an entity AABB against voxel collision shapes. It clips requested movement along axes and may evaluate candidate step-up heights when the entity is grounded and hits a horizontal obstacle.

SM64CoopDX is not a voxel engine:
- Mario's world collision uses level surfaces, floor/ceiling queries and wall planes.
- `perform_ground_step()` and `perform_air_step()` divide movement into four quarter-steps.
- Ground steps query floor, ceiling, water and wall surfaces; air steps separately detect landing, walls, ledges and ceilings.
- Movement is state/action-driven: walking, jumping, freefall, swimming and other modes each choose their own velocity updates.

Reimplementing Minecraft's voxel AABB solver inside SM64 would require a voxel representation of all SM64 levels and would conflict with the existing engine. The intended port is to reproduce Minecraft's input acceleration, drag, jump and fluid rules, while using SM64's own floor/wall/ceiling collision results.

## 4. Native C++ code added in this branch

### Camera

- `native/stevecraft_minecraft_camera.h`
- `native/stevecraft_minecraft_camera.cpp`

Implemented:
- Previous/current player position interpolation.
- Smoothed eye-height tick and partial-tick interpolation.
- Rear and front third-person orientation.
- Four-unit default distance when supplied by the caller; scale and mount-distance selection.
- Exact eight-ray, 0.1-unit corner offset zoom-shortening model.
- First-person zero-offset placement.
- Configurable look-delta accumulation with pitch clamping.

The collision callback is an interface only. It must be supplied by the Android engine adapter before third-person wall avoidance can work in-game.

### Physics

- `native/stevecraft_minecraft_physics.h`
- `native/stevecraft_minecraft_physics.cpp`

Implemented:
- Normalized yaw-relative input acceleration.
- Ground friction-influenced acceleration and caller-supplied air-control speed.
- Attribute-based ground jump and sprint impulse.
- Air gravity and horizontal/vertical drag.
- Water acceleration, efficiency blending, drag and the gravity/16 fluid adjustment.
- Shallow/deep lava drag and gravity/4.
- Horizontal-axis velocity removal when the engine reports that axis was clipped.

The module is a two-stage calculation:
1. `steve_mc_physics_begin_step()` updates velocity and returns desired displacement.
2. SM64 executes its own ground/air/water collision step.
3. `steve_mc_physics_end_step()` consumes the actual displacement/collision flags and applies the movement aftermath.

### Not yet implemented

- Full fall-flying/elytra steering.
- All climbable, powder-snow, honey, cobweb, soul-sand and other block-specific movement modifiers.
- The jump-out-of-water clearance ray and entity-specific effects/potions/attributes.
- All Minecraft collision-shape and step-up rules (intentionally delegated to SM64 surfaces).
- Camera input integration into the engine's selected camera mode.
- Native Android NDK compilation inside the installed SM64CoopDX APK.
- Multiplayer state mapping and in-game Android validation.

## 5. Correct engine integration order

1. Keep the engine's input collection. Translate Android touch-stick input into Mario's intended movement vector and `TOUCH_MOUSE` movement into view yaw/pitch.
2. Compute the C++ movement acceleration and requested displacement for the local Steve player.
3. Pass the requested movement into the existing SM64 ground/air/water step solver, preserving its wall, floor, ceiling and ledge behavior.
4. Feed SM64's actual displacement and collision result back to the C++ physics finish step.
5. Convert the resulting Minecraft-style velocity into the local MarioState fields used by that action. Do not run the new module for remote players until movement replication is designed.
6. Update the camera after the current player transform has been resolved, using the engine ray/surface callback.
7. Keep vanilla Mario behavior as the fallback for all characters other than Steve.

This integration belongs in the writable Android engine fork under an `Android.mk` source directory such as `src/game`; putting `.cpp` files inside a Lua/DynOS mod does not link them into the APK.

## 6. Validation

The host C++ workflow tests:
- First-person, rear third-person and front third-person camera positions.
- Eye-height smoothing.
- Eight-ray camera-distance reduction.
- Yaw/pitch look-delta mapping.
- Ground speed acceleration at default block friction.
- Diagonal input normalization.
- Air-control speed.
- Attribute-based sprint jump.
- Horizontal collision velocity clipping.
- Water acceleration, drag and fluid gravity adjustment.

A passing host test validates the isolated calculations only. Android camera collision, MarioState mapping, touch feel and visual correctness require a native APK build and device testing.
