# SteveCraft Proxy Architecture

## One physical player and one rendered body

SteveCraft keeps SM64CoopDX's native MarioState and marioObj as the only player entity. The mod does not create a second full-body Steve object.

- **Physics and collision:** the engine's native player object remains authoritative for movement, gravity, floor/wall/ceiling contacts, hit reactions and interactions.
- **Model replacement:** proxy.lua calls obj_set_model_extended(m.marioObj, steveModelId) to change the model on that same native object. This is the supported Lua API for replacing an object's extended model.
- **Animation:** marioObj keeps its native animation descriptor and timing. animations.lua applies Steve's registered clips to this object; no frame data is copied to a detached object.
- **Transform:** position, facing, scale and player animation stay under the engine's normal update path. There is no second object to drift, rotate differently or remain behind on the floor.
- **Multiplayer:** each client applies the Steve model to each locally simulated MarioState. The game continues synchronizing player state through its own networking.
- **First person:** the engine's first-person camera hides the full player body. first_person_hand.lua supplies the independent Steve forearm viewmodel only while first person is active.

proxy.lua exposes update, owns_mario_state, is_attached, get_state, get_camera_anchor, get_physical_object, get_visual_object, destroy and reset. Both get_physical_object and get_visual_object refer to the same native marioObj by design.

## Camera boundary

The perspective controller provides three modes: first person, rear third person and front third person. First person uses gFirstPersonCamera with Steve's hand viewmodel. Third person uses NEWCAM with touch orbit and the engine's collision handling.

The independent minecraft_26_3_camera.lua module contains Minecraft camera math for interpolation, eye position, perspective rotation and eight-ray third-person clipping. Its XYZ result cannot be written into Lakitu's camera state through the current Lua bindings. Thus this is a practical in-mod perspective controller, not exact Minecraft camera-position parity.

## Triangle collision adapter

sm64_collision_adapter.lua and tri_collider.lua are optional geometry helpers. They do not create a second player body. Native SM64 collision remains the final contact authority. The extra triangular pre-resolver stays disabled by default to avoid solving the same collision twice.

## Safety rule

Do not spawn a second full-body Steve model. Do not add gravity, velocity integration or collision resolution to a visual Steve object. Any future movement changes must update the existing MarioState and let SM64CoopDX resolve contacts.
