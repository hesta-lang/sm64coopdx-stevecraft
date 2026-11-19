# AI model upload

Two AI editor routes are supported.

## Browser route (recommended for Android)

1. Download the kit from the **Prepare Steve AI model kit** Actions run.
2. Open [AI 3D Editor](https://ai3deditor.com/) in your browser.
3. Upload `reference/Mario Coop Model Template.fbx` as the starting model.
4. Attach `reference/steve.png` as the texture reference, keep `PlayerModel.java` and `HumanoidModel.java` open as technical references if needed, and paste `AI_MODEL_PROMPT_WEB.md`.
5. Export the result as FBX, including textures, and upload it here as `ai-model/steve_compatible.fbx`.
6. The **Convert AI Steve FBX to DynOS** workflow starts automatically.

The FBX route checks that the editor preserved the main player armature weights, the exact SM64 vertex-group names, UVs and embedded texture images. If the web editor drops the rig or required mesh groups, conversion fails instead of silently exporting an incompatible character.

## Blender-scene route

If an AI agent can edit Blender scenes directly, use `reference/Mario Coop Model Template.blend` with `AI_MODEL_PROMPT.md` and upload its result as `ai-model/steve_compatible.blend`. This starts **Convert AI Steve Blender model to DynOS**.

Do not upload a generic newly generated Steve without the template rig. The conversion workflows require the actual SM64CoopDX player structure.
