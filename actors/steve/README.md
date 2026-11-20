# SteveCraft 64 DynOS actor

Minecraft Java 1.21.11 PlayerModel geometry and classic 64x64 Steve skin, rigged to the SM64CoopDX player armature.

The export retains the PlayerModel base cuboids and outer-layer groups: hat, jacket, sleeves and pants. The original skin UVs are split into per-cuboid textures for the F3D/DynOS renderer.

The detached Steve GeoLayout intentionally omits `geo_mirror_mario_set_alpha`. That Mario-specific callback reads `MarioBodyState.modelState`; SteveCraft changes that field to alpha zero to hide the native Mario body, so using the callback on Steve also made Steve invisible. The build sanitizer removes this callback on every export and CI checks that it stays absent.

The independent first-person viewmodel is generated under `actors/steve_hand/`. SM64CoopDX generates runtime DynOS resources from these actor source files when the mod pack loads.
