# Steve model and animation pipeline

## Why the OBJ is not loaded directly

The Lua player-model example in SM64CoopDX registers an exported GeoLayout with `smlua_model_util_get_id()`, then applies the resulting extended model ID to the player's Mario object. The sample actor is supplied as a DynOS `.bin` resource under `actors/`.

SM64CoopDX does not treat an arbitrary OBJ as a player model. The reference OBJ in this repository is only the six-part source mesh.

## Required conversion

1. Open the SM64CoopDX character template in Blender with the Fast64-Gart add-on.
2. Preserve the template's SM64-compatible player armature and its required bone hierarchy.
3. Replace its mesh with the six Steve cuboids from `assets/steve/steve_reference.obj`.
4. Bind the head, torso, arms and legs to the matching armature groups. The rig specification is in `assets/steve/steve_rig_spec.json`.
5. Export the actor GeoLayout to the mod's `actors/` resource location using the name `steve_geo`.
6. Build and test the exported resource in the target SM64CoopDX build.
7. Only after verifying the generated `actors/steve_geo.bin` in Android should `character.lua` register it and apply the model to player objects.

The armature is important: merely exporting six unrigged cuboids would create a static character, not an animated player model.

## Animation plan

First reuse the standard SM64 player animation set with the compatible Steve rig. Then replace or register custom clips for:
- Idle
- Walk
- Run
- Jump
- Fall
- Land
- Hurt
- Death

The engine's animation system animates the expected armature bones. A custom animation file is not useful until the exported model has the corresponding rig and bone ordering.

## Validation gates

- [ ] GeoLayout resource loads without a model lookup error.
- [ ] Six cuboids are visible on a remote or third-person player.
- [ ] Head, torso, arms and legs follow the player skeleton correctly.
- [ ] Walking, jumping, falling and landing animations do not deform the model.
- [ ] Multiplayer synchronization is correct.
- [ ] First-person camera remains functional on Android.

Do not enable model registration until the binary asset passes these checks.
