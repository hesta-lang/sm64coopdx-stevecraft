# Camera reference for SteveCraft 64

## Minecraft Java Edition

The camera behavior was checked against decompiled Minecraft Java Edition sources. The latest reference used for this implementation is 1.21.11:

- `net.minecraft.client.Camera` (1.21.11): https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/Camera.java
- `net.minecraft.client.Minecraft` perspective cycling (1.21.11): https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/Minecraft.java
- `net.minecraft.client.Options` and default F5 binding (1.21.11): https://github.com/H1lkaaaGD/Minecraft_1.21.11_Source/blob/main/net/minecraft/client/Options.java
- Earlier 1.21.1 decompiled reference: https://github.com/Soumeh/1.21.1-Deobfuscated/blob/main/minecraft/src/net/minecraft/client/render/Camera.java

The Minecraft 1.21.11 camera starts from the focused entity's interpolated position plus interpolated eye height. In detached/third-person mode it moves backward by a default 4.0 units (or the entity's camera-distance attribute). For front-facing third person it rotates yaw by 180 degrees and negates pitch. Its `getMaxZoom` routine checks eight rays from slight offsets around the camera origin and shortens the desired distance to the nearest block collision.

The perspective key handler advances the camera-type enum, cycling first person, third person back, and third person front. In the source examined, F5 is the default perspective-toggle key.

## SteveCraft / SM64CoopDX adaptation

SteveCraft 0.6.0-alpha keeps the tested first-person implementation intact. Pressing D-pad Up (`U_JPAD`) switches between:

1. First person: the existing `gFirstPersonCamera` implementation and Steve's textured first-person arm.
2. Third person: `set_first_person_enabled(false)` hands control back to SM64CoopDX and switches the native camera to `CAMERA_MODE_FREE_ROAM`.

The native third-person system already supports following Mario, orbit input and geometry/wall avoidance. Reusing it is safer than writing a second camera position system on top of the engine before validating event order. The 1.21.1 Java ray-clipping algorithm is documented above as the target for a later refinement if native wall avoidance does not match Minecraft closely enough.

## Current limitations

- The first implementation cycles between first person and third person rear/free-orbit views.
- The distinct Minecraft third-person-front view is not included yet.
- The third-person distance, orbit sensitivity and Android touch mapping still need device-side tuning.
- GitHub Actions can validate Lua syntax; only in-game Android testing can confirm actual camera feel and wall behavior.


## SM64CoopDX camera implementation selected for 0.7.0-alpha

The previous `CAMERA_MODE_FREE_ROAM` view was too dependent on the default SM64 camera distance and produced a poor Minecraft-like framing. SteveCraft now uses the fork's `CAMERA_MODE_ROM_HACK` camera through its documented Lua configuration API:

- `camera_set_romhack_override(RCO_ALL_INCLUDING_VANILLA)`
- `camera_romhack_allow_dpad_usage(1)`
- `camera_romhack_set_collisions(1)`
- `camera_romhack_set_zoomed_in_dist(400)` and `camera_romhack_set_zoomed_out_dist(400)`
- `camera_romhack_set_zoomed_in_height(160)` and `camera_romhack_set_zoomed_out_height(160)`

The camera is seeded with `set_camera_mode_fixed` and immediately switched to `CAMERA_MODE_ROM_HACK` with zero transition frames. The player remains controlled by the engine's camera-relative movement system.

This approximates Minecraft's four-block distance and front/back perspectives. The fork's own ray-based collision and sliding code is used instead of copying the Minecraft implementation.


## SteveCraft 0.7.0-alpha: ROM_HACK camera

The third-person controller uses the target fork's exposed ROM_HACK camera API rather than its basic FREE_ROAM mode. It cycles with Y through first person, third-person back and third-person front. Third-person settings are 400 units for both zoom distances and 160 units for both heights, with D-pad orbit and collision checks enabled.

The camera is seeded with `set_camera_mode_fixed` before setting `CAMERA_MODE_ROM_HACK` with zero transition frames. The ROM_HACK camera's own camera-mode transition function derives the orbital yaw from that seed, after which its built-in visibility/raycast solver adjusts around walls.

Minecraft Java 1.21.11 uses an exact four-block camera distance and eight offset ray checks in `Camera.getMaxZoom`. SteveCraft uses the fork's existing collision solver; the two algorithms are similar in purpose but are not identical.


## Touch-controlled third-person camera (0.8.0-alpha)

The third-person view now uses the target fork's native `CAMERA_MODE_NEWCAM` / Puppycam system. In the Android `TOUCH_CONTROLS` build, `newcam_rotate_button` reads `touch_x` and `touch_y` when mouse-look is enabled. The touchscreen controller feeds these deltas from its configured `TOUCH_MOUSE` region, which is the drag-to-look zone on the right side of the screen.

SteveCraft enables:
- `camera_config_enable_free_cam(true)`
- `camera_config_enable_mouse_look(true)`
- `camera_config_enable_collisions(true)`

It disables the D-pad and analogue-stick camera input for this mode, sets touch sensitivity through the fork's camera settings, and restores the previous camera configuration when returning to first person.
