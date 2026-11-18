import bpy
import json
import os
import sys
from pathlib import Path

ADDON_DIR = os.environ["FAST64_ADDON"]
REPORT = os.environ.get("STEVE_BUILD_REPORT", "steve-build-report.json")
ACTOR_ROOT = Path(os.environ.get("STEVE_ACTOR_OUTPUT", "build/actor/actors")).resolve()
sys.path.insert(0, ADDON_DIR)

import fast64_gart
fast64_gart.register()
from fast64_internal.f3d.f3d_material import createF3DMat

def obj(name, kind):
    value = bpy.data.objects.get(name)
    if value is None or value.type != kind:
        raise RuntimeError("Required " + kind + " object missing: " + name)
    return value

def create_color_material(owner, key, color):
    material = createF3DMat(owner, "Shaded Solid")
    material.name = "Steve " + key.title()
    material.diffuse_color = color
    material.f3d_update_flag = True
    f3d = material.f3d_mat
    f3d.set_prim = True
    f3d.set_lights = False
    f3d.set_env = False
    f3d.set_blend = False
    f3d.set_combiner = True
    f3d.prim_color = color
    f3d.rdp_settings.g_lighting = False
    f3d.rdp_settings.g_tex_gen = False
    f3d.rdp_settings.g_shade = True
    f3d.draw_layer.sm64 = "1"
    material.f3d_update_flag = False
    return material

def add_box(vertices, faces, face_materials, weights, center, size, group, materials):
    cx, cy, cz = center
    hx, hy, hz = (size[0] / 2, size[1] / 2, size[2] / 2)
    base = len(vertices)
    vertices.extend([
        (cx-hx, cy-hy, cz-hz), (cx+hx, cy-hy, cz-hz),
        (cx+hx, cy+hy, cz-hz), (cx-hx, cy+hy, cz-hz),
        (cx-hx, cy-hy, cz+hz), (cx+hx, cy-hy, cz+hz),
        (cx+hx, cy+hy, cz+hz), (cx-hx, cy+hy, cz+hz),
    ])
    definitions = [
        ("front",  (base+4, base+5, base+6, base+7)),
        ("back",   (base+0, base+3, base+2, base+1)),
        ("top",    (base+1, base+2, base+6, base+5)),
        ("bottom", (base+0, base+4, base+7, base+3)),
        ("left",   (base+0, base+1, base+5, base+4)),
        ("right",  (base+3, base+7, base+6, base+2)),
    ]
    for face_name, face in definitions:
        faces.append(face)
        face_materials.append(materials.get(face_name, materials["default"]))
    weights.extend((i, group) for i in range(base, base + 8))

def build_mesh(target, blocks, required_groups, material_bank):
    vertices, faces, face_materials, weights = [], [], [], []
    for block in blocks:
        add_box(vertices, faces, face_materials, weights,
                block["center"], block["size"], block["group"], block["materials"])
    mesh = bpy.data.meshes.new(target.name + " Steve Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    old_data = target.data
    target.data = mesh
    for material in material_bank:
        mesh.materials.append(material)
    material_indices = {m.name: i for i, m in enumerate(material_bank)}
    for polygon, material_name in zip(mesh.polygons, face_materials):
        polygon.material_index = material_indices[material_name]
    for group in list(target.vertex_groups):
        target.vertex_groups.remove(group)
    groups = {name: target.vertex_groups.new(name=name) for name in required_groups}
    for vertex_index, group_name in weights:
        groups[group_name].add([vertex_index], 1.0, "REPLACE")
    if old_data and old_data.users == 0:
        bpy.data.meshes.remove(old_data)
    return {"vertices": len(vertices), "faces": len(faces), "groups": required_groups}

def body_blocks(materials, metal=False):
    skin, hair, shirt, pants, eyes, shoes, metal_name = materials
    if metal:
        skin = hair = shirt = pants = eyes = shoes = metal_name
    blocks = [
        {"center": (1.20, 0.0, 0.0), "size": (0.60, 0.56, 0.56), "group": "Head DL",
         "materials": {"default": skin, "front": skin, "back": hair, "top": hair,
                       "bottom": skin, "left": hair, "right": hair}},
        {"center": (0.62, 0.0, 0.0), "size": (0.66, 0.56, 0.32), "group": "Torso",
         "materials": {"default": shirt}},
        {"center": (0.60, -0.415, 0.0), "size": (0.62, 0.22, 0.22), "group": "Left Arm Color",
         "materials": {"default": shirt, "bottom": skin}},
        {"center": (0.60, 0.415, 0.0), "size": (0.62, 0.22, 0.22), "group": "Right Arm Color",
         "materials": {"default": shirt, "bottom": skin}},
        {"center": (0.00, -0.15, 0.0), "size": (0.62, 0.25, 0.28), "group": "Left Thigh Color",
         "materials": {"default": pants, "bottom": shoes}},
        {"center": (0.00, 0.15, 0.0), "size": (0.62, 0.25, 0.28), "group": "Right Thigh Color",
         "materials": {"default": pants, "bottom": shoes}},
    ]
    if not metal:
        blocks.extend([
            {"center": (1.425, -0.115, 0.292), "size": (0.065, 0.065, 0.018),
             "group": "Head DL", "materials": {"default": eyes}},
            {"center": (1.425, 0.115, 0.292), "size": (0.065, 0.065, 0.018),
             "group": "Head DL", "materials": {"default": eyes}},
            {"center": (1.485, 0.0, 0.292), "size": (0.09, 0.34, 0.018),
             "group": "Head DL", "materials": {"default": hair}},
        ])
    return blocks

def head_blocks(group, head_x, skin, hair, eyes):
    return [
        {"center": (head_x, 0.0, 0.0), "size": (0.60, 0.56, 0.56), "group": group,
         "materials": {"default": skin, "front": skin, "back": hair, "top": hair,
                       "bottom": skin, "left": hair, "right": hair}},
        {"center": (head_x + 0.225, -0.115, 0.292), "size": (0.065, 0.065, 0.018),
         "group": group, "materials": {"default": eyes}},
        {"center": (head_x + 0.225, 0.115, 0.292), "size": (0.065, 0.065, 0.018),
         "group": group, "materials": {"default": eyes}},
        {"center": (head_x + 0.285, 0.0, 0.292), "size": (0.09, 0.34, 0.018),
         "group": group, "materials": {"default": hair}},
    ]

def hide_mario_extras(armature):
    names = ("Left Hand Switch", "Right Hand Switch", "Right Wing", "Left Wing", "2 Held Object")
    ignored = []
    for name in names:
        bone = armature.data.bones.get(name)
        if bone and hasattr(bone, "geo_cmd"):
            bone.geo_cmd = "Ignore"
            ignored.append(name)
    return ignored

def main():
    scene = bpy.context.scene
    mario = obj("Mario", "ARMATURE")
    mario_mesh = obj("Mario Mesh", "MESH")
    if mario_mesh.parent != mario:
        raise RuntimeError("Mario Mesh must remain parented to the Mario armature")

    colors = {
        "skin": (0.72, 0.49, 0.32, 1.0),
        "hair": (0.22, 0.11, 0.055, 1.0),
        "shirt": (0.00, 0.61, 0.66, 1.0),
        "pants": (0.12, 0.25, 0.62, 1.0),
        "eyes": (0.035, 0.025, 0.020, 1.0),
        "shoes": (0.16, 0.095, 0.055, 1.0),
        "metal": (0.62, 0.68, 0.73, 1.0),
    }
    mats = {name: create_color_material(mario_mesh, name, color)
            for name, color in colors.items()}
    material_names = {key: value.name for key, value in mats.items()}
    all_materials = [mats[k] for k in ("skin", "hair", "shirt", "pants", "eyes", "shoes", "metal")]
    body_groups = ["Torso", "Head DL", "Left Arm Color", "Right Arm Color",
                   "Left Thigh Color", "Right Thigh Color"]

    meshes = {}
    meshes[mario_mesh.name] = build_mesh(
        mario_mesh, body_blocks(material_names), body_groups, all_materials
    )

    capless = obj("Capless Head Mesh", "MESH")
    meshes[capless.name] = build_mesh(
        capless, head_blocks("Capless Head", 0.47, material_names["skin"],
                             material_names["hair"], material_names["eyes"]),
        ["Capless Head"], [mats["skin"], mats["hair"], mats["eyes"]]
    )

    metal_arm = obj("Metal Mario", "ARMATURE")
    metal_mesh = obj("Metal Mario Mesh", "MESH")
    meshes[metal_mesh.name] = build_mesh(
        metal_mesh, body_blocks(material_names, metal=True), body_groups, [mats["metal"]]
    )
    metal_capless = obj("Metal Capless Head Mesh", "MESH")
    meshes[metal_capless.name] = build_mesh(
        metal_capless, head_blocks("Capless Head", 0.47, mats["metal"].name,
                                   mats["metal"].name, mats["metal"].name),
        ["Capless Head"], [mats["metal"]]
    )

    disabled = {"Mario": hide_mario_extras(mario),
                "Metal Mario": hide_mario_extras(metal_arm)}

    actor_root = Path(os.environ.get("STEVE_ACTOR_OUTPUT", "build/actor/actors")).resolve()
    actor_root.mkdir(parents=True, exist_ok=True)
    scene.gameEditorMode = "SM64"
    scene.fast64.sm64.export_type = "C"
    scene.saveTextures = False
    scene.geoSeparateTextureDef = False
    props = scene.fast64.sm64.combined_export
    props.export_header_type = "Custom"
    props.custom_export_path = str(actor_root)
    props.custom_include_directory = ""
    props.object_name = "steve"
    props.export_gfx = True
    props.export_col = False
    props.export_anim = False
    props.export_bhv = False
    props.export_script_loads = False
    props.export_all_selected = False
    props.use_name_filtering = True

    bpy.ops.object.select_all(action="DESELECT")
    mario.select_set(True)
    bpy.context.view_layer.objects.active = mario
    if mario.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    result = bpy.ops.object.sm64_export_geolayout_armature("EXEC_DEFAULT", export_obj=mario.name)
    if "FINISHED" not in result:
        raise RuntimeError("Fast64 actor export did not finish: " + repr(result))

    actor_dir = actor_root / "steve"
    required = ("geo.inc.c", "model.inc.c", "geo_header.h")
    missing = [name for name in required if not (actor_dir / name).is_file()]
    if missing:
        raise RuntimeError("Fast64 is missing exported actor files: " + ", ".join(missing))
    (actor_dir / "README.md").write_text(
        "# SteveCraft 64 DynOS actor\n\n"
        "Fast64-Gart export of the classic six-part Steve body, rigged to the "
        "SM64CoopDX player armature. The base game animation set drives the "
        "head, torso, arms and legs.\n\n"
        "Install this folder as mods/sm64coopdx-stevecraft/actors/steve/. "
        "SM64CoopDX builds steve_geo.bin when loading the actor.\n",
        encoding="utf-8",
    )
    report = {
        "blender_version": bpy.app.version_string,
        "fast64_version": list(fast64_gart.bl_info.get("version", [])),
        "geo_name": props.geo_name,
        "files": sorted(p.name for p in actor_dir.iterdir() if p.is_file()),
        "mesh_counts": meshes,
        "disabled_vanilla_branches": disabled,
        "export_result": list(result),
    }
    with open(os.environ.get("STEVE_BUILD_REPORT", "steve-build-report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print("STEVE_BUILD_REPORT_BEGIN")
    print(json.dumps(report, indent=2))
    print("STEVE_BUILD_REPORT_END")

if __name__ == "__main__":
    main()
