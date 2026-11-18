# Camera reference for SteveCraft 64

## Minecraft Java Edition

The camera behavior was studied from a decompiled Minecraft Java Edition 1.21.1 source tree:

- `net.minecraft.client.render.Camera`: https://github.com/Soumeh/1.21.1-Deobfuscated/blob/main/minecraft/src/net/minecraft/client/render/Camera.java
- `net.minecraft.client.MinecraftClient`: https://github.com/Soumeh/1.21.1-Deobfuscated/blob/main/minecraft/src/net/minecraft/client/MinecraftClient.java
- Yarn's mapped Camera API for a current 1.21.x reference: https://maven.fabricmc.net/docs/yarn-1.21.11+build.3/net/minecraft/client/render/Camera.html

The Minecraft camera implementation follows the focused entity, starts from its interpolated position/eye height, and in third person moves backward by 4 blocks. For front-facing third person it rotates yaw by 180 degrees and negates pitch. Its `clipToSpace` routine checks eight rays from slight offsets around the camera origin and shortens the desired distance to the nearest collision.

The perspective key handler advances the `Perspective` enum to the next value, which cycles first person, third person back, and third person front.

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
