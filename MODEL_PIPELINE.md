# Steve model and animation pipeline

## Export result

The model source is exported by the GitHub Actions workflow **Build Steve DynOS character**. It downloads the official SM64CoopDX player template, opens it with Blender 3.6.23 and Fast64-Gart, replaces the visible meshes with Steve's cuboid body and exports the actor GeoLayout.

Generated files are stored in `actors/steve/`:
- `geo.inc.c`
- `model.inc.c`
- `geo_header.h`

SM64CoopDX/DynOS is responsible for producing the runtime `steve_geo` model resource from the actor files when the game loads the mod. The runtime model is requested by Lua as `smlua_model_util_get_id("steve_geo")`.

## Rig

The source actor keeps the official SM64 player armature and required bone groups. The six main body parts are assigned to the matching groups:

- Head: `Head DL`
- Torso: `Torso`
- Left and right arms: `Left Arm Color`, `Right Arm Color`
- Left and right legs: `Left Thigh Color`, `Right Thigh Color`

Mario's hand switches, wing branches and held-object branch are ignored for the Steve actor. Capless and metal model variants are also replaced so they do not restore the original Mario geometry.

## Animation

Because the original SM64 player skeleton is preserved, the actor can use the engine's standard player animation set. This includes the game's standing, walking, running, jumping, falling, landing and damage/death motions.

Minecraft-specific animations have not been authored yet. The next animation pass should add blocky arm/leg timing and an appropriate idle stance without changing the compatible bone names or order.

## Runtime checks still required

- [ ] Actor is compiled and `steve_geo` resolves to a model ID on Android.
- [ ] Steve is visible on the local player and remote players.
- [ ] The head, torso, arms and legs rotate at the intended joints.
- [ ] Default player animations do not deform the cubes.
- [ ] First-person camera remains functional.
- [ ] Multiplayer sync is correct when SteveCraft is installed by all clients.

A successful GitHub export only validates the source generation. It does not prove that the target Android build can load or render the actor.
