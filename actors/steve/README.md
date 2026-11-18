# SteveCraft 64 DynOS actor

Fast64-Gart export of Steve's cuboid body, rigged to the SM64CoopDX player armature. The base game animation set drives the head, torso, arms and legs. Each arm has a turquoise sleeve and a skin-tone hand block.

DynOS reads these source files and generates the runtime `.bin` resources when the mod pack loads. Unsupported `CUSTOM_CMD()` placeholders are removed by the build script. The independent first-person arm is generated under `actors/steve_hand/`.
