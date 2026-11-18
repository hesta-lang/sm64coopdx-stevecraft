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
