# SM64CoopDX integration reference for Steve

## Authoritative target

Steve is a playable character model, not a static prop. The scene must use the SM64CoopDX character template and the fork's Fast64 exporter.

References:
- [SM64CoopDX source](https://github.com/coop-deluxe/sm64coopdx)
- [SM64CoopDX Fast64 fork](https://github.com/coop-deluxe/fast64)
- [SM64CoopDX character template](https://github.com/coop-deluxe/character-template)
- [Custom GeoLayout export overview](https://sm64decomp.tenry.net/wiki/index.php/Custom_object)
- [SM64CoopDX mod filesystem guide](https://github.com/coop-deluxe/sm64coopdx/blob/main/docs/lua/guides/modfs.md)
- [Lua examples including Custom Player Model](https://github.com/coop-deluxe/sm64coopdx/blob/main/docs/lua/lua.md)

## Blender scene contract

The AI must edit the supplied \`Mario Coop Model Template.blend\`. It must retain the template armature and object names checked by \`tools/validate_ai_steve_scene.py\`.

The converter uses Fast64-Gart and the operator \`bpy.ops.object.sm64_export_geolayout_armature\`. Export is configured as C actor data with object name \`steve\`.

## Exported actor files

- \`actors/steve/geo.inc.c\`
- \`actors/steve/model.inc.c\`
- \`actors/steve/geo_header.h\`

These are SM64 actor/DynOS source files, not standalone FBX/GLB files and not proof of Android runtime compatibility.

## Runtime use

SM64CoopDX's mod filesystem supports custom model \`.bin\` resources and texture files. Lua can resolve a custom model URI with \`smlua_model_util_get_id\` and a texture URI with \`get_texture_info\`, as documented in the mod filesystem guide.

A generic actor export does not automatically register a new playable character. SteveCraft's Lua character-selection/runtime integration remains a separate step and must reference the generated model resource name.

## Acceptance checks

- Character upright and facing forward.
- Head, torso, both arms and both legs distinct and visible.
- Skin UVs sample the supplied original 64×64 texture.
- Player armature and required vertex groups preserved.
- Fast64 export creates all three actor source files.
- No unsupported placeholder GeoLayout commands.
- Android runtime has no black silhouette, missing textures or sideways pose.

A successful GitHub Actions export validates source conversion only. Visual and animation checks require the Android APK.
