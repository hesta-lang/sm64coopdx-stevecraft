import bpy
import json
import os
import sys
from pathlib import Path

addon_parent = Path(os.environ["FAST64_ADDON"]).resolve()
addon_root = addon_parent / "fast64_gart"
if not (addon_root / "__init__.py").is_file():
    addon_root = addon_parent
sys.path.insert(0, str(addon_root))
sys.path.insert(0, str(addon_parent))
import fast64_gart
fast64_gart.register()
from fast64_internal.f3d.f3d_material import createF3DMat

fbx_path = Path(os.environ.get("STEVE_AI_FBX", "ai-model/steve_compatible.fbx")).resolve()
report_path = Path(os.environ.get("STEVE_IMPORT_REPORT", "build/ai-steve-fbx-import-report.json"))
scene_output = Path(os.environ.get("STEVE_SCENE_OUTPUT", "build/steve-ai-imported.blend")).resolve()

def fail(message):
    raise RuntimeError("AI Steve FBX import failed: " + message)

def image_from_material(material):
    if material and material.node_tree:
        for node in material.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.image:
                return node.image
    return None

def make_f3d_material(owner, source_material, slot_index):
    image = image_from_material(source_material)
    if image is None:
        fail("material '{}' has no embedded image texture".format(
            source_material.name if source_material else slot_index
        ))
    has_alpha = False
    if image.channels >= 4:
        pixels = image.pixels
        has_alpha = any(pixels[index] < 0.999 for index in range(3, len(pixels), 4))
    preset = "sm64_shaded_texture_cutout" if has_alpha else "Shaded Texture"
    material = createF3DMat(owner, preset)
    material.name = "AI Steve " + (source_material.name if source_material else str(slot_index))
    try:
        image.colorspace_settings.name = "sRGB"
    except Exception:
        pass
    material.f3d_update_flag = True
    f3d = material.f3d_mat
    f3d.tex0.tex = image
    f3d.tex0.tex_format = "RGBA16"
    f3d.tex0.tex_set = True
    f3d.tex0.autoprop = True
    f3d.tex0.S.clamp = True
    f3d.tex0.T.clamp = True
    f3d.rdp_settings.g_mdsft_text_filt = "G_TF_POINT"
    f3d.rdp_settings.g_tex_gen = False
    f3d.prim_color = (1.0, 1.0, 1.0, 1.0)
    f3d.draw_layer.sm64 = "1"
    material.diffuse_color = (1.0, 1.0, 1.0, 1.0)
    material.f3d_update_flag = False
    return material, image.name

def copy_mesh_into_template(source, target, required_groups, label):
    if source.type != "MESH" or target.type != "MESH":
        fail(label + " source/target is not a mesh")
    if len(source.data.vertices) < 8 or len(source.data.polygons) < 6:
        fail(label + " source mesh is empty")
    group_names = {group.name for group in source.vertex_groups}
    missing = [name for name in required_groups if name not in group_names]
    if missing:
        fail(label + " FBX lost required vertex groups: " + ", ".join(missing))
    if not source.data.uv_layers:
        fail(label + " FBX has no UV map")
    if not source.data.materials:
        fail(label + " FBX has no materials")

    # Keep the target template object's transforms and rig. Move only the
    # imported mesh vertices into the target object's local coordinate space.
    mesh = source.data.copy()
    source_to_target = target.matrix_world.inverted() @ source.matrix_world
    for vertex in mesh.vertices:
        vertex.co = source_to_target @ vertex.co
    if mesh.uv_layers.get("UVMap") is None:
        mesh.uv_layers[0].name = "UVMap"

    new_materials = []
    image_names = []
    for index, source_material in enumerate(source.data.materials):
        converted, image_name = make_f3d_material(target, source_material, index)
        new_materials.append(converted)
        image_names.append(image_name)
    mesh.materials.clear()
    for material in new_materials:
        mesh.materials.append(material)

    for group in list(target.vertex_groups):
        target.vertex_groups.remove(group)
    target_groups = {
        group.name: target.vertex_groups.new(name=group.name)
        for group in source.vertex_groups
    }
    for vertex in source.data.vertices:
        for assignment in vertex.groups:
            source_group = source.vertex_groups[assignment.group]
            target_groups[source_group.name].add(
                [vertex.index], assignment.weight, "REPLACE"
            )

    target.data = mesh
    return {
        "source_object": source.name,
        "target_object": target.name,
        "vertices": len(mesh.vertices),
        "polygons": len(mesh.polygons),
        "uv_layer": "UVMap",
        "vertex_groups": sorted(group_names),
        "materials": [material.name for material in new_materials],
        "texture_images": image_names,
    }

def main():
    if not fbx_path.is_file():
        fail("missing " + str(fbx_path))
    original_names = {obj.name for obj in bpy.data.objects}
    bpy.ops.import_scene.fbx(filepath=str(fbx_path))
    imported = [obj for obj in bpy.data.objects if obj.name not in original_names]
    imported_meshes = [obj for obj in imported if obj.type == "MESH"]
    if not imported_meshes:
        fail("FBX contains no imported meshes")

    body_groups = {"Head DL", "Torso", "Left Arm Color", "Right Arm Color",
                   "Left Thigh Color", "Right Thigh Color"}
    body_candidates = [
        obj for obj in imported_meshes
        if body_groups.issubset({group.name for group in obj.vertex_groups})
    ]
    head_candidates = [
        obj for obj in imported_meshes
        if "Capless Head" in {group.name for group in obj.vertex_groups}
    ]
    if len(body_candidates) != 1:
        fail("expected exactly one imported main body mesh with all six SM64 vertex groups; found {}".format(len(body_candidates)))
    if len(head_candidates) != 1:
        fail("expected exactly one imported capless-head mesh with Capless Head group; found {}".format(len(head_candidates)))

    body_source = body_candidates[0]
    head_source = head_candidates[0]
    if not any(mod.type == "ARMATURE" and mod.object for mod in body_source.modifiers):
        fail("main FBX body mesh lost its armature modifier; the AI editor must preserve the rig")
    if head_source.parent is None or head_source.parent.type != "ARMATURE":
        fail("capless head mesh is no longer parented to its separate head armature")
    body_target = bpy.data.objects.get("Mario Mesh")
    head_target = bpy.data.objects.get("Capless Head Mesh")
    mario = bpy.data.objects.get("Mario")
    if body_target is None or head_target is None or mario is None:
        fail("official template player objects are missing")

    body_report = copy_mesh_into_template(
        body_source, body_target,
        ["Head DL", "Torso", "Left Arm Color", "Right Arm Color",
         "Left Thigh Color", "Right Thigh Color"],
        "Main body"
    )
    head_report = copy_mesh_into_template(
        head_source, head_target, ["Capless Head"], "Capless head"
    )

    # The imported FBX armatures are discarded. The template's original
    # Mario and capless-head armatures, GeoLayout metadata and switch branches stay.
    imported_names = [obj.name for obj in imported]
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)

    report = {
        "status": "passed",
        "source_fbx": str(fbx_path),
        "blender_version": bpy.app.version_string,
        "retained_template_armature": mario.name,
        "body": body_report,
        "capless_head": head_report,
        "discarded_import_objects": imported_names,
    }
    # Pack imported texture images so the validated scene is self-contained.
    for image in bpy.data.images:
        if image.source == "FILE" and not image.packed_file:
            try:
                image.pack()
            except Exception as exc:
                fail("could not pack texture image '{}': {}".format(image.name, exc))
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    scene_output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(scene_output))
    print("AI_STEVE_FBX_IMPORT_BEGIN")
    print(json.dumps(report, indent=2))
    print("AI_STEVE_FBX_IMPORT_END")

if __name__ == "__main__":
    main()
