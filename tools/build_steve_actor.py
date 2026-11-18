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

def add_box(vertices, faces, face_materials, weights, center, size, group, materials,
            vertex_map, weighted_vertices, omit_faces=()):
    cx, cy, cz = center
    hx, hy, hz = (size[0] / 2, size[1] / 2, size[2] / 2)
    corners = [
        (cx-hx, cy-hy, cz-hz), (cx+hx, cy-hy, cz-hz),
        (cx+hx, cy+hy, cz-hz), (cx-hx, cy+hy, cz-hz),
        (cx-hx, cy-hy, cz+hz), (cx+hx, cy-hy, cz+hz),
        (cx+hx, cy+hy, cz+hz), (cx-hx, cy+hy, cz+hz),
    ]

    # Reuse coincident vertices only inside the same rigid vertex group.
    # Steve's sleeve and hand are one rigid arm, so their seam can be welded
    # without changing animation weights or merging independently moving bones.
    corner_indices = []
    for point in corners:
        key = (group, tuple(round(component, 6) for component in point))
        vertex_index = vertex_map.get(key)
        if vertex_index is None:
            vertex_index = len(vertices)
            vertices.append(point)
            vertex_map[key] = vertex_index
        corner_indices.append(vertex_index)
        weight_key = (vertex_index, group)
        if weight_key not in weighted_vertices:
            weights.append(weight_key)
            weighted_vertices.add(weight_key)

    c = corner_indices
    definitions = [
        ("front",  (c[4], c[5], c[6], c[7])),
        ("back",   (c[0], c[3], c[2], c[1])),
        ("top",    (c[1], c[2], c[6], c[5])),
        ("bottom", (c[0], c[4], c[7], c[3])),
        ("left",   (c[0], c[1], c[5], c[4])),
        ("right",  (c[3], c[7], c[6], c[2])),
    ]
    omitted = set(omit_faces)
    for face_name, face in definitions:
        if face_name in omitted:
            continue
        faces.append(face)
        face_materials.append(materials.get(face_name, materials["default"]))

def build_mesh(target, blocks, required_groups, material_bank):
    vertices, faces, face_materials, weights = [], [], [], []
    vertex_map = {}
    weighted_vertices = set()
    omitted_faces = 0
    for block in blocks:
        block_omissions = block.get("omit_faces", ())
        omitted_faces += len(block_omissions)
        add_box(vertices, faces, face_materials, weights,
                block["center"], block["size"], block["group"], block["materials"],
                vertex_map, weighted_vertices, block_omissions)
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
    return {
        "vertices": len(vertices),
        "faces": len(faces),
        "omitted_faces": omitted_faces,
        "groups": required_groups,
    }

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
         "materials": {"default": shirt}, "omit_faces": ("bottom",)},
        {"center": (0.375, -0.375, 0.0), "size": (0.25, 0.25, 0.25), "group": "Left Arm Color",
         "materials": {"default": skin}, "omit_faces": ("top",)},
        {"center": (0.75, 0.375, 0.0), "size": (0.50, 0.25, 0.25), "group": "Right Arm Color",
         "materials": {"default": shirt}, "omit_faces": ("bottom",)},
        {"center": (0.375, 0.375, 0.0), "size": (0.25, 0.25, 0.25), "group": "Right Arm Color",
         "materials": {"default": skin}, "omit_faces": ("top",)},
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

# Minecraft Java 1.21.11 PlayerModel.createMesh() geometry.
# Origins include the PartPose offsets from HumanoidModel/PlayerModel.
MINECRAFT_PLAYER_CUBOIDS = [
    {"key": "head_base", "group": "Head DL", "origin": (-4.0, -8.0, -4.0),
     "size": (8.0, 8.0, 8.0), "inflate": 0.0, "uv": (0, 0), "outer": False},
    {"key": "head_hat", "group": "Head DL", "origin": (-4.0, -8.0, -4.0),
     "size": (8.0, 8.0, 8.0), "inflate": 0.5, "uv": (32, 0), "outer": True},
    {"key": "torso_base", "group": "Torso", "origin": (-4.0, 0.0, -2.0),
     "size": (8.0, 12.0, 4.0), "inflate": 0.0, "uv": (16, 16), "outer": False},
    {"key": "torso_jacket", "group": "Torso", "origin": (-4.0, 0.0, -2.0),
     "size": (8.0, 12.0, 4.0), "inflate": 0.25, "uv": (16, 32), "outer": True},
    {"key": "right_arm_base", "group": "Right Arm Color", "origin": (-8.0, 0.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.0, "uv": (40, 16), "outer": False},
    {"key": "right_arm_sleeve", "group": "Right Arm Color", "origin": (-8.0, 0.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.25, "uv": (40, 32), "outer": True},
    {"key": "left_arm_base", "group": "Left Arm Color", "origin": (4.0, 0.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.0, "uv": (32, 48), "outer": False, "mirror": True},
    {"key": "left_arm_sleeve", "group": "Left Arm Color", "origin": (4.0, 0.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.25, "uv": (48, 48), "outer": True},
    {"key": "right_leg_base", "group": "Right Thigh Color", "origin": (-3.9, 12.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.0, "uv": (0, 16), "outer": False},
    {"key": "right_leg_pants", "group": "Right Thigh Color", "origin": (-3.9, 12.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.25, "uv": (0, 32), "outer": True},
    {"key": "left_leg_base", "group": "Left Thigh Color", "origin": (-0.1, 12.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.0, "uv": (16, 48), "outer": False, "mirror": True},
    {"key": "left_leg_pants", "group": "Left Thigh Color", "origin": (-0.1, 12.0, -2.0),
     "size": (4.0, 12.0, 4.0), "inflate": 0.25, "uv": (0, 48), "outer": True},
]


def create_minecraft_texture_material(owner, key, texture_path, outer_layer):
    preset = "sm64_shaded_texture_cutout" if outer_layer else "Shaded Texture"
    material = createF3DMat(owner, preset)
    material.name = "Minecraft " + key.replace("_", " ").title()
    image = bpy.data.images.load(str(texture_path), check_existing=True)
    image.colorspace_settings.name = "sRGB"

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
    return material


def _minecraft_face_uvs(u0, v0, u1, v1, crop_u, crop_v, crop_width, crop_height):
    # ModelPart.Polygon remap order: upper-right, upper-left, lower-left, lower-right.
    # Minecraft skin UVs use a top-left origin; Blender UVs use a bottom-left origin.
    points = ((u1, v0), (u0, v0), (u0, v1), (u1, v1))
    return [
        ((u - crop_u) / crop_width, 1.0 - ((v - crop_v) / crop_height))
        for u, v in points
    ]


def build_minecraft_player_mesh(target, cuboids, required_groups, material_bank, coordinate_offset=(0.0, 0.0, 0.0)):
    vertices, faces, face_materials, face_uvs, weights = [], [], [], [], []
    vertex_map = {}
    weighted_vertices = set()
    material_indices = {material.name: i for i, material in enumerate(material_bank)}

    for cube in cuboids:
        x0, y0, z0 = cube["origin"]
        width, height, depth = cube["size"]
        grow = cube["inflate"]
        min_x, min_y, min_z = x0 - grow, y0 - grow, z0 - grow
        max_x = x0 + width + grow
        max_y = y0 + height + grow
        max_z = z0 + depth + grow
        if cube.get("mirror", False):
            # Minecraft ModelPart.Cube swaps X bounds and reverses each
            # polygon after UV remapping for CubeListBuilder.mirror().
            min_x, max_x = max_x, min_x

        # Exact vertex order from Minecraft's ModelPart.Cube constructor.
        mc_points = [
            (min_x, min_y, min_z), (max_x, min_y, min_z),
            (max_x, max_y, min_z), (min_x, max_y, min_z),
            (min_x, min_y, max_z), (max_x, min_y, max_z),
            (max_x, max_y, max_z), (min_x, max_y, max_z),
        ]

        # Map Minecraft (X right, Y down, Z depth) to SM64's player
        # vertical/side/depth axes, preserving the armature's existing origins.
        corner_indices = []
        for mc_x, mc_y, mc_z in mc_points:
            point = (1.0 - mc_y / 16.0 - coordinate_offset[0],\n                     -mc_x / 16.0 - coordinate_offset[1],\n                     -mc_z / 16.0 - coordinate_offset[2])
            key = (cube["group"], tuple(round(value, 6) for value in point))
            vertex_index = vertex_map.get(key)
            if vertex_index is None:
                vertex_index = len(vertices)
                vertices.append(point)
                vertex_map[key] = vertex_index
            corner_indices.append(vertex_index)
            weight_key = (vertex_index, cube["group"])
            if weight_key not in weighted_vertices:
                weights.append(weight_key)
                weighted_vertices.add(weight_key)

        t0, t1, t2, t3, l0, l1, l2, l3 = corner_indices
        u, v = cube["uv"]
        u0 = float(u)
        u1 = u0 + depth
        u2 = u1 + width
        u22 = u2 + width
        u3 = u2 + depth
        u4 = u3 + width
        v0 = float(v)
        v1 = v0 + depth
        v2 = v1 + height
        crop_width = int(2 * width + 2 * depth)
        crop_height = int(height + depth)

        # Six polygons and UV rectangles copied from ModelPart.Cube.
        polygon_defs = [
            ((l1, l0, t0, t1), (u1, v0, u2, v1)),   # DOWN
            ((t2, t3, l3, l2), (u2, v1, u22, v0)),  # UP
            ((t0, l0, l3, t3), (u0, v1, u1, v2)),   # WEST
            ((t1, t0, t3, t2), (u1, v1, u2, v2)),   # NORTH
            ((l1, t1, t2, l2), (u2, v1, u3, v2)),   # EAST
            ((l0, l1, l2, l3), (u3, v1, u4, v2)),   # SOUTH
        ]
        for face, rect in polygon_defs:
            uvs = _minecraft_face_uvs(
                rect[0], rect[1], rect[2], rect[3],
                u0, v0, crop_width, crop_height
            )
            if cube.get("mirror", False):
                face = tuple(reversed(face))
                uvs = list(reversed(uvs))
            faces.append(face)
            face_materials.append(cube["material"])
            face_uvs.append(uvs)

    mesh = bpy.data.meshes.new(target.name + " Minecraft PlayerModel Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    old_data = target.data
    target.data = mesh
    for material in material_bank:
        mesh.materials.append(material)

    uv_layer = mesh.uv_layers.new(name="UVMap")  # Fast64-Gart requires this exact layer name.
    for polygon, material_name, uvs in zip(mesh.polygons, face_materials, face_uvs):
        if material_name not in material_indices:
            raise RuntimeError("Missing Minecraft texture material: " + material_name)
        polygon.material_index = material_indices[material_name]
        if len(polygon.loop_indices) != 4:
            raise RuntimeError("Minecraft cube face did not export as a quad")
        for loop_index, uv in zip(polygon.loop_indices, uvs):
            uv_layer.data[loop_index].uv = uv

    for group in list(target.vertex_groups):
        target.vertex_groups.remove(group)
    groups = {name: target.vertex_groups.new(name=name) for name in required_groups}
    for vertex_index, group_name in weights:
        groups[group_name].add([vertex_index], 1.0, "REPLACE")

    if old_data and old_data.users == 0:
        bpy.data.meshes.remove(old_data)

    return {
        "vertices": len(vertices),
        "faces": len(faces),
        "cuboids": len(cuboids),
        "outer_layer_cuboids": sum(1 for cube in cuboids if cube["outer"]),
        "groups": required_groups,
        "skin_texture_materials": sorted(material.name for material in material_bank),
    }


def minecraft_cube_materials(cuboids, materials):
    configured = []
    for source in cuboids:
        cube = dict(source)
        cube["material"] = materials[cube["key"]].name
        configured.append(cube)
    return configured

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
    # Only the optional Metal Mario variant still uses primitive colours.
    # The normal Steve model now uses the full Minecraft skin textures.
    colors = {
        "Metal": (158, 173, 186),
    }
    old_combiner = (
        "gsDPSetCombineLERP(0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT, "
        "0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT),"
    )
    new_combiner = (
        "gsDPSetCombineLERP(0, 0, 0, PRIMITIVE, 0, 0, 0, 1, "
        "0, 0, 0, PRIMITIVE, 0, 0, 0, 1),"
    )
    patched = []
    for material_name, rgb in colors.items():
        marker = "Gfx mat_steve_Steve_" + material_name + "[] = {"
        start = source.find(marker)
        if start < 0:
            # The textured Minecraft PlayerModel no longer uses the old
            # primitive palette; keep the patch optional for absent variants.
            continue
        end = source.find("\n};", start)
        if end < 0:
            raise RuntimeError("Unterminated Steve F3D material: " + material_name)
        block = source[start:end + 3]
        if old_combiner not in block:
            raise RuntimeError("Unexpected F3D combiner in material: " + material_name)
        block = block.replace(old_combiner, new_combiner, 1)
        pipe = "gsDPPipeSync(),"
        if pipe not in block:
            raise RuntimeError("Missing pipe sync in material: " + material_name)
        prim = "gsDPSetPrimColor(0, 0, {}, {}, {}, 255),".format(*rgb)
        block = block.replace(pipe, pipe + "\n\t" + prim, 1)
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


def read_vertex_bounds(model_source, array_name):
    declaration = re.search(
        r"Vtx\s+" + re.escape(array_name) + r"\[\d+\]\s*=\s*\{([\s\S]*?)\n\};",
        model_source,
    )
    if declaration is None:
        raise RuntimeError("Missing exported vertex array: " + array_name)
    coordinates = [
        tuple(int(component) for component in match)
        for match in re.findall(
            r"\{\{\{\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\}",
            declaration.group(1),
        )
    ]
    if not coordinates:
        raise RuntimeError("No vertex coordinates found in: " + array_name)
    return {
        "min": [min(point[axis] for point in coordinates) for axis in range(3)],
        "max": [max(point[axis] for point in coordinates) for axis in range(3)],
    }


def validate_capless_head_alignment(actor_dir, tolerance=2):
    model_source = (actor_dir / "model.inc.c").read_text(encoding="utf-8")
    pairs = {
        "head_base": (
            "steve_Head_DL_mesh_layer_1_vtx_0",
            "steve_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1_vtx_0",
        ),
        "head_hat": (
            "steve_Head_DL_mesh_layer_1_vtx_1",
            "steve_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1_vtx_1",
        ),
    }
    report = {}
    for layer, (normal_name, capless_name) in pairs.items():
        normal = read_vertex_bounds(model_source, normal_name)
        capless = read_vertex_bounds(model_source, capless_name)
        deltas = {
            "min": [capless["min"][i] - normal["min"][i] for i in range(3)],
            "max": [capless["max"][i] - normal["max"][i] for i in range(3)],
        }
        largest_delta = max(abs(value) for values in deltas.values() for value in values)
        report[layer] = {"normal": normal, "capless": capless, "delta": deltas}
        if largest_delta > tolerance:
            raise RuntimeError(
                "Capless " + layer + " is not aligned with the normal head; "
                "largest vertex-bound delta is " + str(largest_delta) +
                " (tolerance " + str(tolerance) + ")"
            )
    return report


def main():
    scene = bpy.context.scene
    mario = obj("Mario", "ARMATURE")
    mario_mesh = obj("Mario Mesh", "MESH")
    if mario_mesh.parent != mario:
        raise RuntimeError("Mario Mesh must remain parented to the Mario armature")

    # Retain the template's separate metal-cap model. The normal player uses
    # the Minecraft Java PlayerModel cubes, overlays, and classic Steve skin.
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

    skin_texture_root = Path(os.environ.get(
        "STEVE_SKIN_TEXTURE_ROOT", "build/steve-skin-textures"
    )).resolve()
    manifest_path = skin_texture_root / "manifest.json"
    if not manifest_path.is_file():
        raise RuntimeError("Minecraft skin crop manifest is missing: " + str(manifest_path))
    skin_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    skin_materials = {}
    for cube in MINECRAFT_PLAYER_CUBOIDS:
        key = cube["key"]
        texture_path = skin_texture_root / (key + ".png")
        if not texture_path.is_file():
            raise RuntimeError("Minecraft skin texture is missing: " + str(texture_path))
        if key not in skin_materials:
            skin_materials[key] = create_minecraft_texture_material(
                mario_mesh, key, texture_path, cube["outer"]
            )

    minecraft_material_bank = list(skin_materials.values())
    body_groups = [
        "Torso", "Head DL", "Left Arm Color", "Right Arm Color",
        "Left Thigh Color", "Right Thigh Color",
    ]

    meshes = {}
    normal_cuboids = minecraft_cube_materials(MINECRAFT_PLAYER_CUBOIDS, skin_materials)
    meshes[mario_mesh.name] = build_minecraft_player_mesh(
        mario_mesh, normal_cuboids, body_groups, minecraft_material_bank
    )

    capless = obj("Capless Head Mesh", "MESH")
    head_cuboids = [cube for cube in MINECRAFT_PLAYER_CUBOIDS
                    if cube["key"] in ("head_base", "head_hat")]
    capless_cuboids = minecraft_cube_materials(head_cuboids, skin_materials)
    for cube in capless_cuboids:
        cube["group"] = "Capless Head"

    # The capless head is a separate armature whose display-list bone starts
    # at its own origin. The normal Mario head is attached to the Head DL bone,
    # whose rest pivot is offset in the main Mario armature. Convert the
    # Minecraft root-space cuboids into the capless head's local pivot space.
    mario_head_bone = mario.data.bones.get("Head DL")
    capless_armature = capless.parent
    capless_head_bone = capless_armature.data.bones.get("Capless Head")
    if mario_head_bone is None or capless_head_bone is None:
        raise RuntimeError("Could not resolve Mario Head DL / Capless Head rest pivots")
    capless_pivot_offset = tuple(
        float(mario_head_bone.head_local[i] - capless_head_bone.head_local[i])
        for i in range(3)
    )
    head_material_bank = [skin_materials["head_base"], skin_materials["head_hat"]]
    meshes[capless.name] = build_minecraft_player_mesh(
        capless, capless_cuboids, ["Capless Head"], head_material_bank,
        coordinate_offset=capless_pivot_offset
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
    disabled = {
        "Mario": hide_mario_extras(mario),
        "Metal Mario": hide_mario_extras(metal_arm),
    }

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
    capless_alignment = validate_capless_head_alignment(actor_dir)

    (actor_dir / "README.md").write_text(
        "# SteveCraft 64 DynOS actor\\n\\n"
        "Minecraft Java 1.21.11 PlayerModel geometry and classic 64x64 Steve skin, "
        "rigged to the SM64CoopDX player armature.\\n\\n"
        "The export retains the PlayerModel base cubes and all four outer-layer groups: "
        "hat, jacket, sleeves and pants. The original skin UVs are split into small "
        "per-cuboid textures to fit the N64 texture memory limits.\\n\\n"
        "The independent first-person viewmodel is generated under actors/steve_hand/.\\n"
        "SM64CoopDX generates runtime DynOS resources when the mod pack loads.\\n",
        encoding="utf-8",
    )

    report = {
        "blender_version": bpy.app.version_string,
        "fast64_version": list(fast64_gart.bl_info.get("version", [])),
        "geo_name": props.geo_name,
        "files": sorted(p.name for p in actor_dir.iterdir() if p.is_file()),
        "mesh_counts": meshes,
        "minecraft_player_model": {
            "source": "Minecraft Java 1.21.11 PlayerModel.createMesh / HumanoidModel.createMesh",
            "base_cuboids": sum(1 for cube in MINECRAFT_PLAYER_CUBOIDS if not cube["outer"]),
            "outer_layer_cuboids": sum(1 for cube in MINECRAFT_PLAYER_CUBOIDS if cube["outer"]),
            "skin_uv_manifest": skin_manifest["cubes"],
            "axes": "Minecraft XYZ mapped to the SM64 player armature axes",
            "capless_head_pivot_offset": list(capless_pivot_offset),
        },
        "disabled_vanilla_branches": disabled,
        "static_eye_switches": static_eye_switches,
        "unsupported_custom_commands_removed": removed_custom_commands,
        "steve_root_scale": steve_root_scale,
        "metal_variant_primitive_materials": primitive_materials,
        "first_person_hand": first_person_hand,
        "capless_head_alignment": capless_alignment,
        "export_result": list(result),
    }
    with open(os.environ.get("STEVE_BUILD_REPORT", "steve-build-report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print("STEVE_BUILD_REPORT_BEGIN")
    print(json.dumps(report, indent=2))
    print("STEVE_BUILD_REPORT_END")

if __name__ == "__main__":
    main()
