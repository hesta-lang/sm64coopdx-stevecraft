# AI modeling brief — Minecraft Java Steve for SM64CoopDX

## Attach these files to the 3D AI/editor

1. \`reference/Mario Coop Model Template.blend\` — official SM64CoopDX character template. Edit this scene.
2. \`reference/PlayerModel.java\` — Minecraft Java 1.21.11 classic wide Steve geometry and overlay definitions.
3. \`reference/HumanoidModel.java\` — parent model geometry and joint pivots.
4. \`reference/steve.png\` — original 64×64 classic wide Steve skin atlas.
5. \`reference/steve_rig_spec.json\` — required rig mapping.
6. \`SM64COOPDX_INTEGRATION_REFERENCE.md\` — target exporter and runtime structure.

The supplied Minecraft source and texture are pinned to the repository snapshot used by the kit workflow. Do not replace them with another Steve skin or model version.

## Prompt

Edit the supplied Blender character scene for Super Mario 64 Co-op Deluxe (SM64CoopDX). This is a conversion task, not a redesign.

Use Minecraft Java 1.21.11 PlayerModel.java and HumanoidModel.java as the authoritative geometry and pivot reference. Use the supplied 64×64 Steve PNG as the exact texture atlas. Preserve classic Steve proportions and appearance. Do not stylize, smooth, round, reinterpret or replace the character.

Open and modify the supplied \`Mario Coop Model Template.blend\`. Do not create an unrelated scene. Do not replace the template armature. The template armature and hierarchy are the target rig.

### Geometry

- Classic wide Steve, not slim/Alex.
- Head 8×8×8 pixels.
- Torso 8×12×4 pixels.
- Each arm 4×12×4 pixels.
- Each leg 4×12×4 pixels.
- Keep separate outer skin layers: head hat, torso jacket, left/right sleeves, left/right pants.
- Preserve the original 64×64 skin UV layout. Do not replace it with approximate solid colors.
- Hard 90-degree cube edges, flat faces; no bevel, smoothing, subdivision or rounded corners.
- Correctly orient face, hair, arms, hands, shirt, trousers and shoes from the original skin atlas.

### Required SM64CoopDX scene compatibility

Preserve these template objects and names:
- \`Mario\` — existing player armature.
- \`Mario Mesh\` — main Steve body mesh, parented to \`Mario\`.
- \`Capless Head\` — separate capless-head armature/switch branch.
- \`Capless Head Mesh\` — head-only mesh parented to \`Capless Head\`.
- \`Metal Mario\` and \`Metal Mario Mesh\` — preserve the metal body branch.
- \`Metal Capless Head\` and \`Metal Capless Head Mesh\` — preserve the separate metal capless-head branch.

Keep the existing bone names, hierarchy, pivots, armature modifiers and animation compatibility. Do not rename player bones or invent a new skeleton.

The main body mesh must have populated vertex groups:
- \`Head DL\`
- \`Torso\`
- \`Left Arm Color\`
- \`Right Arm Color\`
- \`Left Thigh Color\`
- \`Right Thigh Color\`

The capless head mesh must use the \`Capless Head\` vertex group and remain parented to the separate \`Capless Head\` armature. Do not parent it to \`Mario\`.

Keep Steve facing the same forward direction as the original Mario template. Keep the character upright: head above torso, legs below. Do not rotate the entire character sideways.

### Materials and UV

Use the supplied Steve PNG as an image texture. Preserve pixel-art sampling (nearest/point filtering). Keep UV maps and name the primary UV layer exactly \`UVMap\`. Create materials compatible with the supplied Fast64-Gart SM64 F3D exporter. Do not rely only on unsupported shader nodes.

### Output

Return:
1. Edited Blender scene named \`steve_compatible.blend\`.
2. A report listing preserved objects, armature, vertex groups, UV layer, materials and remaining incompatibilities.
3. Optional front/side/back preview renders.

Do not claim compatibility merely because the file opens. It must retain the SM64CoopDX template armature and be exportable through the SM64CoopDX Fast64 GeoLayout Armature exporter.

If you cannot preserve the rig or produce Fast64-compatible materials, report the exact blocker instead of returning a falsely compatible model.
