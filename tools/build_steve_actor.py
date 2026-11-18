import bpy
import json
import os
import re
import sys
from pathlib import Path

ADDON_PARENT = Path(os.environ["FAST64_ADDON"]).resolve()
ADDON_ROOT = ADDON_PARENT / "fast64_gart"
if not (ADDON_ROOT / "__init__.py").is_file():
    ADDON_ROOT = ADDON_PARENT
REPORT = os.environ.get("STEVE_BUILD_REPORT", "steve-build-report.json")
ACTOR_ROOT = Path(os.environ.get("STEVE_ACTOR_OUTPUT", "build/actor/actors")).resolve()

# The add-on package itself is needed for fast64_internal imports, while its
# parent directory is needed to import the top-level package as fast64_gart.
sys.path.insert(0, str(ADDON_ROOT))
sys.path.insert(0, str(ADDON_PARENT))

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
    skin, hair, shirt, pants, eyes, shoes, metal_name = (
        materials[key] for key in ("skin", "hair", "shirt", "pants", "eyes", "shoes", "metal")
    )
    if metal:
        skin = hair = shirt = pants = eyes = shoes = metal_name

    # Classic Minecraft PlayerModel proportions expressed in the existing
    # player-template coordinate system: head 8^3, torso 8x12x4,
    # arms/legs 4x12x4. The player bone names are intentionally preserved.
    blocks = [
        {"center": (1.25, 0.0, 0.0), "size": (0.50, 0.50, 0.50), "group": "Head DL",
         "materials": {"default": skin, "front": skin, "back": hair, "top": hair,
                       "bottom": skin, "left": hair, "right": hair}},
        {"center": (0.625, 0.0, 0.0), "size": (0.75, 0.50, 0.25), "group": "Torso",
         "materials": {"default": shirt}},
        # Arms are 4x12x4. The upper 8 pixels are the turquoise sleeve,
        # and the lower 4 pixels are the skin-coloured hand.
        {"center": (0.75, -0.375, 0.0), "size": (0.50, 0.25, 0.25), "group": "Left Arm Color",
         "materials": {"default": shirt}},
        {"center": (0.375, -0.375, 0.0), "size": (0.25, 0.25, 0.25), "group": "Left Arm Color",
         "materials": {"default": skin}},
        {"center": (0.75, 0.375, 0.0), "size": (0.50, 0.25, 0.25), "group": "Right Arm Color",
         "materials": {"default": shirt}},
        {"center": (0.375, 0.375, 0.0), "size": (0.25, 0.25, 0.25), "group": "Right Arm Color",
         "materials": {"default": skin}},
        {"center": (-0.125, -0.125, 0.0), "size": (0.75, 0.25, 0.25), "group": "Left Thigh Color",
         "materials": {"default": pants, "bottom": shoes}},
        {"center": (-0.125, 0.125, 0.0), "size": (0.75, 0.25, 0.25), "group": "Right Thigh Color",
         "materials": {"default": pants, "bottom": shoes}},
    ]
    if not metal:
        blocks.extend([
            {"center": (1.25, -0.105, 0.262), "size": (0.055, 0.065, 0.018),
             "group": "Head DL", "materials": {"default": eyes}},
            {"center": (1.25, 0.105, 0.262), "size": (0.055, 0.065, 0.018),
             "group": "Head DL", "materials": {"default": eyes}},
            {"center": (1.48, 0.0, 0.262), "size": (0.045, 0.34, 0.018),
             "group": "Head DL", "materials": {"default": hair}},
        ])
    return blocks


def head_blocks(group, head_x, skin, hair, eyes):
    return [
        {"center": (head_x, 0.0, 0.0), "size": (0.50, 0.50, 0.50), "group": group,
         "materials": {"default": skin, "front": skin, "back": hair, "top": hair,
                       "bottom": skin, "left": hair, "right": hair}},
        {"center": (head_x, -0.105, 0.262), "size": (0.055, 0.065, 0.018),
         "group": group, "materials": {"default": eyes}},
        {"center": (head_x, 0.105, 0.262), "size": (0.055, 0.065, 0.018),
         "group": group, "materials": {"default": eyes}},
        {"center": (head_x + 0.23, 0.0, 0.262), "size": (0.045, 0.34, 0.018),
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

def freeze_steve_eye_switches():
    # The original template's seven eye-material branches point to Mario
    # textures. Steve's eyes are geometry/material blocks, so keep one static
    # head branch instead of exporting those Mario eye-state branches.
    changed = []
    for armature in bpy.data.objects:
        if armature.type != "ARMATURE":
            continue
        for bone in armature.data.bones:
            if "Eye State Switch" in bone.name and getattr(bone, "geo_cmd", None) == "Switch":
                bone.geo_cmd = "Start"
                changed.append(armature.name + ":" + bone.name)
    return changed


def sanitize_unsupported_geo_commands(actor_dir):
    geo_path = actor_dir / "geo.inc.c"
    source = geo_path.read_text(encoding="utf-8")
    source, removed = re.subn(
        r"(?m)^[ \t]*CUSTOM_CMD\(\),[ \t]*(?:\r?\n|$)",
        "",
        source,
    )
    if "CUSTOM_CMD" in source:
        raise RuntimeError("Unsupported CUSTOM_CMD token remains in Steve GeoLayout")
    geo_path.write_text(source, encoding="utf-8")
    return removed


def write_first_person_hand_actor(actor_root):
    hand_dir = actor_root / "steve_hand"
    hand_dir.mkdir(parents=True, exist_ok=True)
    (hand_dir / "README.md").write_text(
        "# SteveCraft first-person arm\\n\\n"
        "Generated from assets/steve/steve_skin.png by tools/build_steve_hand.py.\\n",
        encoding="utf-8",
    )
    return {
        "geo_name": "steve_hand_geo",
        "dimensions": [4, 12, 4],
        "texture_source": "assets/steve/steve_skin.png",
        "generator": "tools/build_steve_hand.py",
    }



def apply_steve_primitive_colors(actor_dir):
    model_path = actor_dir / "model.inc.c"
    source = model_path.read_text(encoding="utf-8")
    colors = {
        "Shirt": (0, 156, 168),
        "Skin": (184, 125, 82),
        "Hair": (56, 28, 14),
        "Eyes": (9, 6, 5),
        "Pants": (31, 64, 158),
        "Shoes": (41, 24, 14),
        "Metal": (158, 173, 186),
    }
    combiner = (
        "gsDPSetCombineLERP(0, 0, 0, PRIMITIVE, 0, 0, 0, 1, "
        "0, 0, 0, PRIMITIVE, 0, 0, 0, 1),"
    )
    patched = []
    for material_name, rgb in colors.items():
        marker = "Gfx mat_steve_Steve_" + material_name + "[] = {"
        start = source.find(marker)
        if start < 0:
            raise RuntimeError("Missing Steve F3D material: " + material_name)
        end = source.find("\\n};", start)
        if end < 0:
            raise RuntimeError("Unterminated Steve F3D material: " + material_name)
        block = source[start:end + 3]
        block, combine_count = re.subn(
            r"gsDPSetCombineLERP\\([^;]*?\\),",
            combiner,
            block,
            count=1,
        )
        if combine_count != 1:
            raise RuntimeError("Could not set primitive combiner: " + material_name)
        prim = "gsDPSetPrimColor(0, 0, {}, {}, {}, 255),".format(*rgb)
        block, pipe_count = re.subn(
            r"(gsDPPipeSync\\(\\),)",
            r"\\1\\n\\t" + prim,
            block,
            count=1,
        )
        if pipe_count != 1:
            raise RuntimeError("Could not set primitive color: " + material_name)
        source = source[:start] + block + source[end + 3:]
        patched.append(material_name)
    model_path.write_text(source, encoding="utf-8")
    return patched



def set_steve_root_scale(actor_dir, scale_value=65536):
    geo_path = actor_dir / "geo.inc.c"
    source = geo_path.read_text(encoding="utf-8")
    marker = "const GeoLayout steve_geo[] = {"
    start = source.find(marker)
    if start < 0:
        raise RuntimeError("steve_geo root GeoLayout was not found")
    prefix, root = source[:start], source[start:]
    root, count = re.subn(
        r"(GEO_SCALE\(LAYER_FORCE,\s*)16384(\s*\))",
        lambda match: match.group(1) + str(scale_value) + match.group(2),
        root,
        count=1,
    )
    if count != 1:
        raise RuntimeError("Could not set the Steve root GeoLayout scale")
    geo_path.write_text(prefix + root, encoding="utf-8")
    return scale_value


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

    static_eye_switches = freeze_steve_eye_switches()
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

    removed_custom_commands = sanitize_unsupported_geo_commands(actor_dir)
    primitive_materials = apply_steve_primitive_colors(actor_dir)
    steve_root_scale = set_steve_root_scale(actor_dir, 65536)
    first_person_hand = write_first_person_hand_actor(actor_root)

    (actor_dir / "README.md").write_text(
        "# SteveCraft 64 DynOS actor\\n\\n"
        "Fast64-Gart export of Steve's cuboid body, rigged to the SM64CoopDX player armature. "
        "The standard player animations drive the head, torso, arms and legs.\\n\\n"
        "The arms use a turquoise sleeve block and a skin-tone hand block. "
        "The independent first-person viewmodel is generated under actors/steve_hand/.\\n\\n"
        "SM64CoopDX reads these source files and generates the runtime DynOS .bin resources "
        "when the mod pack loads. Unsupported CUSTOM_CMD placeholders are removed before "
        "the source is committed.\\n",
        encoding="utf-8",
    )
    report = {
        "blender_version": bpy.app.version_string,
        "fast64_version": list(fast64_gart.bl_info.get("version", [])),
        "geo_name": props.geo_name,
        "files": sorted(p.name for p in actor_dir.iterdir() if p.is_file()),
        "mesh_counts": meshes,
        "disabled_vanilla_branches": disabled,
        "static_eye_switches": static_eye_switches,
        "unsupported_custom_commands_removed": removed_custom_commands,
        "steve_root_scale": steve_root_scale,
        "primitive_materials": primitive_materials,
        "first_person_hand": first_person_hand,
        "export_result": list(result),
    }
    with open(os.environ.get("STEVE_BUILD_REPORT", "steve-build-report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print("STEVE_BUILD_REPORT_BEGIN")
    print(json.dumps(report, indent=2))
    print("STEVE_BUILD_REPORT_END")

if __name__ == "__main__":
    main()
