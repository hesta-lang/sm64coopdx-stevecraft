import bpy
import os
from pathlib import Path

output = Path(os.environ["STEVE_TEMPLATE_FBX"]).resolve()
output.parent.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.data.objects:
    if obj.type in {"MESH", "ARMATURE"}:
        obj.select_set(True)

bpy.ops.export_scene.fbx(
    filepath=str(output),
    use_selection=True,
    object_types={"MESH", "ARMATURE"},
    apply_unit_scale=True,
    apply_scale_options="FBX_SCALE_UNITS",
    axis_forward="-Z",
    axis_up="Y",
    use_mesh_modifiers=False,
    mesh_smooth_type="OFF",
    use_custom_props=True,
    add_leaf_bones=False,
    bake_anim=False,
    path_mode="COPY",
    embed_textures=True,
)
if not output.is_file() or output.stat().st_size < 1024:
    raise RuntimeError("Template FBX export did not create a valid file")
print("STEVE_TEMPLATE_FBX", str(output), output.stat().st_size)
