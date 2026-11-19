# Prompt for a web-based AI 3D editor — SteveCraft

Recommended browser editor: [AI 3D Editor](https://ai3deditor.com/). It accepts uploaded OBJ/FBX meshes and supports text-prompt edits. Its export must be FBX for the SteveCraft conversion workflow.

## Upload these files from the Steve AI model kit

- \`reference/Mario Coop Model Template.fbx\` — the SM64CoopDX player template exported with its armature and meshes.
- \`reference/steve.png\` — original Minecraft Java 1.21.11 classic wide Steve 64×64 skin.
- \`reference/PlayerModel.java\` and \`reference/HumanoidModel.java\` — geometry and pivot reference.
- \`reference/steve_rig_spec.json\` — required body-part and rig specification.

## Prompt

Modify the uploaded FBX character model into the classic Minecraft Java 1.21.11 Steve player model. This is a strict conversion, not a redesign.

Use the attached Minecraft PlayerModel.java and HumanoidModel.java as the geometry/pivot source and the attached 64×64 Steve skin as the exact appearance reference. Keep the low-poly, hard-edged, rectangular cuboid appearance. Do not make a realistic human, do not smooth, bevel, round, subdivide or stylize the geometry.

Required Minecraft proportions:
- Head 8×8×8 pixels.
- Torso 8×12×4 pixels.
- Each arm 4×12×4 pixels (classic wide Steve, not Alex/slim).
- Each leg 4×12×4 pixels.
- Preserve the outer hat, jacket, sleeves and pants layers as separate geometry where possible.
- Preserve the original Steve skin texture and pixel-art UV mapping. Use nearest/point texture filtering.

CRITICAL RIG REQUIREMENTS:
- Preserve the uploaded FBX armature and its bone names/hierarchy.
- Do not generate a replacement skeleton.
- Preserve the mesh armature modifier and skin weights.
- Preserve these vertex group names on the main body mesh exactly:
  Head DL, Torso, Left Arm Color, Right Arm Color, Left Thigh Color, Right Thigh Color.
- Preserve a separate capless head mesh with the Capless Head vertex group.
- Preserve the object names Mario Mesh and Capless Head Mesh.
- Keep the character upright and facing the same forward direction as the uploaded template.
- Do not merge the head, torso, arms and legs into one unweighted static object.
- Do not remove or rename the existing armature.

Return an FBX named steve_compatible.fbx with the armature, skin weights, UV maps and embedded image textures. Also provide a front/side/back preview and report whether all required bone groups and the original armature were preserved.

If the editor cannot preserve the uploaded rig and vertex groups, do not claim the result is SM64CoopDX-compatible. State exactly which rig data was lost.
