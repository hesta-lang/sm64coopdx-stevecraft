# CJ for SM64CoopDX

Independent character-replacement mod for **SM64CoopDX Android**.

## Version

**0.1.0-alpha — native player model replacement**

## Architecture

This uses the first implementation option: **CJ replaces only Mario's visible model**.

- \`MarioState\` remains the sole player state.
- \`marioObj\` remains the single physical and visual player object.
- The game keeps its native movement, acceleration, jump, gravity, collision, water, interactions, camera and player actions.
- The mod does not spawn a second CJ entity and does not override the physics or collision solver.
- The model is applied to each local player state on clients that have the mod installed.

The script looks for a DynOS model named \`cj_geo\` in \`actors/cj/\`. It waits safely if the model is not present, leaving the original Mario model visible rather than applying an invalid ID.

## Current status

<badge color="warning">Framework only — CJ asset not included</badge>

The model replacement logic is in place, but this repository branch does not yet contain CJ's geometry or textures. Therefore CJ will **not appear yet**; Mario remains visible until a compatible \`cj_geo\` actor is added.

The model must be fitted to the SM64CoopDX player armature so the game's standard player animations can drive it. A standalone GTA San Andreas DFF/TXD is not automatically a DynOS player model.

## Installation

1. Download this branch as a ZIP.
2. Extract it.
3. Put the mod folder in SM64CoopDX's \`mods\` directory.
4. Enable it in the mod menu.
5. Until \`cj_geo\` is supplied, the game deliberately keeps Mario's original model.

SM64CoopDX loads the mod's \`main.lua\` and the additional Lua scripts in the same folder. DynOS actor resources belong under \`actors/\`.

## Validation

GitHub Actions checks every Lua script with Lua 5.4 and tests:
- safe behavior when the CJ model is missing
- model registration when \`cj_geo\` becomes available
- model replacement without spawning another object
- replacement for more than one player state
- avoiding redundant model setter calls

These tests do not run the Android game or validate a future CJ model's rig, materials, textures or animations.

## Next asset requirement

Add a legally obtained CJ character model with permission to use it, then convert/rig it for the native SM64 player armature and register its GeoLayout as \`cj_geo\`. Do not import GTA San Andreas code or assets wholesale into this mod.
