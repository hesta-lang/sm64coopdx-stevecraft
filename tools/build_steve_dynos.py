#!/usr/bin/env python3
"""Generate a Minecraft Bedrock humanoid as native SM64CoopDX DynOS C.

This build path consumes Bedrock Geometry JSON directly. It does not import
Blender or require Fast64. The Mario-compatible GeoLayout is kept as the
animation layer while the visible cuboids and textures are generated here.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
from pathlib import Path
from typing import Any

from PIL import Image, ImageOps

PIXEL_SCALE = 6.25
WORLD_BIAS = (50.0, 0.0, 0.0)

# Bind-pose translations read from the current actors/steve/geo.inc.c.
GROUP_PIVOTS = {
    "torso": (32.0, 0.0, 0.0),
    "head": (73.0, 0.0, 0.0),
    "left_arm": (63.0, -5.0, 37.0),
    "right_arm": (64.0, -5.0, -37.0),
    "left_leg": (6.0, -4.0, 20.0),
    "right_leg": (6.0, -4.0, -20.0),
}
BONE_GROUP = {
    "body": ("torso", "base"), "jacket": ("torso", "outer"),
    "head": ("head", "base"), "hat": ("head", "outer"),
    "leftArm": ("left_arm", "base"), "leftSleeve": ("left_arm", "outer"),
    "rightArm": ("right_arm", "base"), "rightSleeve": ("right_arm", "outer"),
    "leftLeg": ("left_leg", "base"), "leftPants": ("left_leg", "outer"),
    "rightLeg": ("right_leg", "base"), "rightPants": ("right_leg", "outer"),
}
GROUPS = ("torso", "head", "left_arm", "right_arm", "left_leg", "right_leg")
LAYERS = ("base", "outer")
FACE_NAMES = ("north", "south", "east", "west", "up", "down")

# Bedrock-space vertex order for each face. Its winding is corrected after
# conversion to SM64 coordinates, where the axis transform is reflected.
FACE_CORNERS = {
    "north": lambda x0, x1, y0, y1, z0, z1: [
        (x0, y0, z0), (x0, y1, z0), (x1, y1, z0), (x1, y0, z0)],
    "south": lambda x0, x1, y0, y1, z0, z1: [
        (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), (x0, y0, z1)],
    "east": lambda x0, x1, y0, y1, z0, z1: [
        (x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)],
    "west": lambda x0, x1, y0, y1, z0, z1: [
        (x0, y0, z1), (x0, y1, z1), (x0, y1, z0), (x0, y0, z0)],
    "up": lambda x0, x1, y0, y1, z0, z1: [
        (x0, y1, z0), (x0, y1, z1), (x1, y1, z1), (x1, y1, z0)],
    "down": lambda x0, x1, y0, y1, z0, z1: [
        (x0, y0, z1), (x0, y0, z0), (x1, y0, z0), (x1, y0, z1)],
}
FACE_UV_CORNERS = {
    "north": ("bl", "tl", "tr", "br"),
    "south": ("br", "tr", "tl", "bl"),
    "east": ("bl", "tl", "tr", "br"),
    "west": ("br", "tr", "tl", "bl"),
    "up": ("tl", "bl", "br", "tr"),
    "down": ("bl", "tl", "tr", "br"),
}


class BedrockModelError(ValueError):
    """Raised when Bedrock geometry cannot be represented safely."""


def number(value: Any, label: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise BedrockModelError(f"{label} must be numeric")
    value = float(value)
    if not math.isfinite(value):
        raise BedrockModelError(f"{label} must be finite")
    return value


def vector(value: Any, label: str, length: int = 3) -> tuple[float, ...]:
    if not isinstance(value, list) or len(value) != length:
        raise BedrockModelError(f"{label} must contain {length} numbers")
    return tuple(number(item, f"{label}[{i}]") for i, item in enumerate(value))


def rotate_vector(point: tuple[float, float, float],
                  angles: tuple[float, float, float]) -> tuple[float, float, float]:
    """Apply Euler rotations around X, then Y, then Z (degrees)."""
    x, y, z = point
    ax, ay, az = (math.radians(value) for value in angles)

    c, s = math.cos(ax), math.sin(ax)
    y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(ay), math.sin(ay)
    x, z = x * c + z * s, -x * s + z * c
    c, s = math.cos(az), math.sin(az)
    x, y = x * c - y * s, x * s + y * c
    return x, y, z


def rotate_about(point, pivot, angles):
    relative = tuple(point[i] - pivot[i] for i in range(3))
    rotated = rotate_vector(relative, angles)
    return tuple(rotated[i] + pivot[i] for i in range(3))


def find_geometry(document: dict[str, Any]) -> dict[str, Any]:
    geometries = document.get("minecraft:geometry")
    if not isinstance(geometries, list):
        raise BedrockModelError("Missing minecraft:geometry array")
    matches = [
        entry for entry in geometries
        if isinstance(entry, dict)
        and isinstance(entry.get("description"), dict)
        and entry["description"].get("identifier") == "geometry.humanoid.custom"
    ]
    if len(matches) != 1:
        raise BedrockModelError(
            "Expected exactly one geometry.humanoid.custom entry; found "
            + str(len(matches))
        )
    return matches[0]


def validate_bones(items: list[dict[str, Any]]):
    bones = {}
    for index, raw in enumerate(items):
        if not isinstance(raw, dict):
            raise BedrockModelError(f"Bone {index} must be an object")
        name = raw.get("name")
        if not isinstance(name, str) or not name:
            raise BedrockModelError(f"Bone {index} has no valid name")
        if name in bones:
            raise BedrockModelError(f"Duplicate bone: {name}")
        bone = dict(raw)
        bone["_pivot"] = vector(raw.get("pivot"), f"bone {name}.pivot")
        bone["_rotation"] = vector(raw.get("rotation", [0, 0, 0]), f"bone {name}.rotation")
        bones[name] = bone

    for name, bone in bones.items():
        parent = bone.get("parent")
        if parent is not None and parent not in bones:
            raise BedrockModelError(f"Bone {name} refers to missing parent {parent}")
        seen = set()
        current = name
        while current is not None:
            if current in seen:
                raise BedrockModelError(f"Cycle detected in bone hierarchy at {current}")
            seen.add(current)
            current = bones[current].get("parent")

    report = [{
        "name": name,
        "parent": bone.get("parent"),
        "pivot": list(bone["_pivot"]),
        "rotation": list(bone["_rotation"]),
        "has_cubes": bool(bone.get("cubes")),
        "locators": bone.get("locators", {}),
    } for name, bone in bones.items()]
    return bones, report


def cube_face_uvs(cube: dict[str, Any], size: tuple[float, float, float]):
    width, height, depth = size
    uv = cube.get("uv")
    if isinstance(uv, list) and len(uv) == 2:
        u = number(uv[0], "cube.uv[0]")
        v = number(uv[1], "cube.uv[1]")
        return {
            "north": (u + 2 * depth + width, v + depth, width, height),
            "south": (u + depth, v + depth, width, height),
            "east": (u + depth + width, v + depth, depth, height),
            "west": (u, v + depth, depth, height),
            "up": (u + depth, v, width, depth),
            "down": (u + depth + width, v, width, depth),
        }
    if isinstance(uv, dict):
        result = {}
        for face, data in uv.items():
            if face not in FACE_NAMES:
                continue
            if not isinstance(data, dict):
                raise BedrockModelError(f"cube.uv.{face} must be an object")
            origin = vector(data.get("uv"), f"cube.uv.{face}.uv", 2)
            face_size = vector(data.get("uv_size"), f"cube.uv.{face}.uv_size", 2)
            result[face] = (origin[0], origin[1], face_size[0], face_size[1])
        if result:
            return result
    raise BedrockModelError("cube.uv must be a two-number array or per-face object")


def crop_face(skin: Image.Image, rect, mirror: bool, label: str):
    x, y, width, height = rect
    flip_x, flip_y = width < 0, height < 0
    if flip_x:
        x, width = x + width, -width
    if flip_y:
        y, height = y + height, -height
    values = (x, y, width, height)
    rounded = tuple(round(value) for value in values)
    if any(abs(a - b) > 1e-5 for a, b in zip(values, rounded)):
        raise BedrockModelError(f"{label} UV rectangle must use whole pixels")
    x, y, width, height = rounded
    if width <= 0 or height <= 0:
        raise BedrockModelError(f"{label} UV face is empty")
    if x < 0 or y < 0 or x + width > skin.width or y + height > skin.height:
        raise BedrockModelError(
            f"{label} UV {(x, y, width, height)} exceeds the {skin.width}x{skin.height} skin"
        )
    if width > 64 or height > 32 or width * height > 2048:
        raise BedrockModelError(
            f"{label} face {width}x{height} is too large for a safe RGBA16 TMEM tile"
        )
    image = skin.crop((x, y, x + width, y + height))
    if mirror or flip_x:
        image = ImageOps.mirror(image)
    if flip_y:
        image = ImageOps.flip(image)
    return image


def bedrock_to_actor(point, group):
    x, y, z = point
    world = (y * PIXEL_SCALE - WORLD_BIAS[0], -x * PIXEL_SCALE, -z * PIXEL_SCALE)
    pivot = GROUP_PIVOTS[group]
    return tuple(world[i] - pivot[i] for i in range(3))


def transform_cube_point(point, cube, bone_name, bones):
    cube_rotation = vector(cube.get("rotation", [0, 0, 0]), "cube.rotation")
    if any(abs(value) > 1e-8 for value in cube_rotation):
        pivot_raw = cube.get("pivot")
        if pivot_raw is None:
            origin = vector(cube.get("origin"), "cube.origin")
            size = vector(cube.get("size"), "cube.size")
            pivot = tuple(origin[i] + size[i] / 2.0 for i in range(3))
        else:
            pivot = vector(pivot_raw, "cube.pivot")
        point = rotate_about(point, pivot, cube_rotation)

    current = bone_name
    while current is not None:
        bone = bones[current]
        rotation = bone["_rotation"]
        if any(abs(value) > 1e-8 for value in rotation):
            point = rotate_about(point, bone["_pivot"], rotation)
        current = bone.get("parent")
    return bedrock_to_actor(point, BONE_GROUP[bone_name][0])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return sum(a[i] * b[i] for i in range(3))


def face_vertices(face, bounds, cube, bone_name, bones, center):
    x0, x1, y0, y1, z0, z1 = bounds
    raw_positions = FACE_CORNERS[face](x0, x1, y0, y1, z0, z1)
    positions = [
        transform_cube_point(point, cube, bone_name, bones)
        for point in raw_positions
    ]
    face_center = tuple(sum(point[i] for point in positions) / 4.0 for i in range(3))
    normal = cross(
        tuple(positions[1][i] - positions[0][i] for i in range(3)),
        tuple(positions[2][i] - positions[0][i] for i in range(3)),
    )
    outward = tuple(face_center[i] - center[i] for i in range(3))
    labels = list(FACE_UV_CORNERS[face])
    if dot(normal, outward) < 0:
        positions.reverse()
        labels.reverse()
    return list(zip(positions, labels))


def safe_symbol(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def geo_symbols(geo_source: str):
    layouts = re.findall(r"const\s+GeoLayout\s+([A-Za-z0-9_]+)\s*\[\s*\]", geo_source)
    meshes = set()
    for match in re.finditer(r"GEO_(?:DISPLAY_LIST|ANIMATED_PART)\s*\(([^)]*)\)", geo_source):
        args = match.group(1).split(",")
        symbol = args[-1].strip() if args else ""
        if symbol.startswith("steve_") and symbol != "NULL":
            meshes.add(symbol)
    if not layouts or not meshes:
        raise BedrockModelError("GeoLayout template has no Steve layouts or mesh references")
    return layouts, sorted(meshes)


def emit_header(layouts, meshes):
    lines = [
        "#ifndef STEVE_DYNOS_GEO_HEADER_H",
        "#define STEVE_DYNOS_GEO_HEADER_H",
        "",
    ]
    lines.extend(f"extern const GeoLayout {name}[];" for name in layouts)
    lines.append("")
    lines.extend(f"extern Gfx {name}[];" for name in meshes)
    lines.extend(["", "#endif", ""])
    return "\n".join(lines)


def emit_group(symbol, cube_symbols):
    lines = [f"Gfx {symbol}[] = {{", "    gsDPPipeSync(),"]
    lines.extend(f"    gsSPDisplayList({name})," for name in cube_symbols)
    lines.extend(["    gsSPEndDisplayList(),", "};", ""])
    return lines


def parse_entity_scale(path):
    if path is None:
        return None, None
    data = json.loads(path.read_text(encoding="utf-8"))
    try:
        description = data["minecraft:client_entity"]["description"]
        identifier = description.get("identifier")
        scale = number(float(description.get("scripts", {}).get("scale", 1.0)),
                       "player entity scale")
    except (KeyError, TypeError, ValueError) as exc:
        raise BedrockModelError("Could not read entity identifier or scale") from exc
    if not 0 < scale <= 2:
        raise BedrockModelError("Entity scale must be greater than 0 and at most 2")
    return identifier, scale


def build_model(geometry_path: Path, skin_path: Path, geo_template: Path,
                output_root: Path, entity_config: Path | None = None):
    document = json.loads(geometry_path.read_text(encoding="utf-8"))
    geometry = find_geometry(document)
    raw_bones = geometry.get("bones")
    if not isinstance(raw_bones, list):
        raise BedrockModelError("Geometry has no bones array")
    bones, bone_report = validate_bones(raw_bones)

    skin = Image.open(skin_path).convert("RGBA")
    if skin.size != (64, 64):
        raise BedrockModelError(f"Expected a 64x64 Minecraft skin, got {skin.size}")

    output = output_root / "steve"
    output.mkdir(parents=True, exist_ok=True)
    geo_text = geo_template.read_text(encoding="utf-8")
    layouts, mesh_symbols = geo_symbols(geo_text)

    by_group = {(group, layer): [] for group in GROUPS for layer in LAYERS}
    lines = [
        "// Generated directly from Mojang Bedrock Geometry JSON.",
        "// Do not hand-edit; run tools/build_steve_dynos.py.",
        "// Small per-face RGBA PNGs keep texture loads below the N64 TMEM limit.",
        "",
    ]
    cube_report = []
    texture_report = []
    cube_index = 0

    for bone_name, bone in bones.items():
        cubes = bone.get("cubes") or []
        if not isinstance(cubes, list):
            raise BedrockModelError(f"{bone_name}.cubes must be an array")
        if cubes and bone_name not in BONE_GROUP:
            raise BedrockModelError(
                f"Bone {bone_name} contains cubes but is not mapped to a Mario mesh group"
            )
        if not cubes:
            continue

        group, layer = BONE_GROUP[bone_name]
        for local_index, cube in enumerate(cubes):
            if not isinstance(cube, dict):
                raise BedrockModelError(f"{bone_name}.cubes[{local_index}] must be an object")
            origin = vector(cube.get("origin"), f"{bone_name}.cube.origin")
            size = vector(cube.get("size"), f"{bone_name}.cube.size")
            if any(value <= 0 for value in size):
                raise BedrockModelError(f"{bone_name} cube dimensions must be positive")
            inflate = number(cube.get("inflate", 0.0), f"{bone_name}.cube.inflate")
            low = tuple(origin[i] - inflate for i in range(3))
            high = tuple(origin[i] + size[i] + inflate for i in range(3))
            if any(high[i] <= low[i] for i in range(3)):
                raise BedrockModelError(f"{bone_name} cube is empty after inflation")
            uv_faces = cube_face_uvs(cube, size)
            if set(uv_faces) != set(FACE_NAMES):
                raise BedrockModelError(
                    f"{bone_name} cube must provide all six UV faces; "
                    f"got {sorted(uv_faces)}"
                )
            mirror = cube.get("mirror", False)
            if not isinstance(mirror, bool):
                raise BedrockModelError(f"{bone_name}.cube.mirror must be boolean")

            tag = safe_symbol(f"steve_{bone_name}_{local_index}_{cube_index}")
            vtx_symbol = f"{tag}_vtx"
            dl_symbol = f"{tag}_dl"
            bounds = (low[0], high[0], low[1], high[1], low[2], high[2])
            center_bedrock = tuple((low[i] + high[i]) / 2.0 for i in range(3))
            center = transform_cube_point(center_bedrock, cube, bone_name, bones)

            texture_defs = []
            vertex_lines = []
            face_info = []
            for face_index, face in enumerate(FACE_NAMES):
                image = crop_face(skin, uv_faces[face], mirror, f"{bone_name}.{face}")
                filename = f"{tag}_{face}.png"
                (output / filename).parent.mkdir(parents=True, exist_ok=True)
                image.save(output / filename, format="PNG", optimize=True)
                digest = hashlib.sha256((output / filename).read_bytes()).hexdigest()
                texture_symbol = f"{tag}_{face}_texture"
                texture_defs.append(
                    f'Texture {texture_symbol}[] = {{ "steve/{filename}" }};'
                )
                face_info.append({
                    "face": face,
                    "texture": texture_symbol,
                    "width": image.width,
                    "height": image.height,
                    "file": filename,
                    "sha256": digest,
                })

                points = face_vertices(face, bounds, cube, bone_name, bones, center)
                uv_points = {
                    "tl": (0, 0),
                    "tr": ((image.width - 1) * 32, 0),
                    "br": ((image.width - 1) * 32, (image.height - 1) * 32),
                    "bl": (0, (image.height - 1) * 32),
                }
                for point, label in points:
                    coords = tuple(round(value) for value in point)
                    if any(value < -32768 or value > 32767 for value in coords):
                        raise BedrockModelError(f"{bone_name} cube vertex exceeds signed 16-bit range")
                    s, t = uv_points[label]
                    vertex_lines.append(
                        f"    {{{{{{{coords[0]}, {coords[1]}, {coords[2]}}}, "
                        f"0, {{{s}, {t}}}, {{0xFF, 0xFF, 0xFF, 0xFF}}}}}},"
                    )

            if len(vertex_lines) != 24:
                raise BedrockModelError(f"{bone_name} cube generated {len(vertex_lines)} vertices")
            lines.extend(texture_defs)
            lines.append("")
            lines.append(f"Vtx {vtx_symbol}[24] = {{")
            lines.extend(vertex_lines)
            lines.extend(["};", ""])
            lines.append(f"Gfx {dl_symbol}[] = {{")
            lines.extend([
                "    gsDPPipeSync(),",
                "    gsDPSetTextureFilter(G_TF_POINT),",
                "    gsSPClearGeometryMode(G_LIGHTING),",
                "    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),",
                "    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),",
                f"    gsSPVertex({vtx_symbol}, 24, 0),",
            ])
            for index, face in enumerate(face_info):
                lines.extend([
                    "    gsDPPipeSync(),",
                    f"    gsDPLoadTextureBlock({face['texture']}, G_IM_FMT_RGBA, G_IM_SIZ_16b, "
                    f"{face['width']}, {face['height']}, 0, G_TX_CLAMP, G_TX_CLAMP, "
                    "G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),",
                    f"    gsSP2Triangles({index * 4}, {index * 4 + 1}, {index * 4 + 2}, 0, "
                    f"{index * 4}, {index * 4 + 2}, {index * 4 + 3}, 0),",
                ])
            lines.extend([
                "    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),",
                "    gsDPPipeSync(),",
                "    gsSPEndDisplayList(),",
                "};",
                "",
            ])

            by_group[(group, layer)].append(dl_symbol)
            texture_report.extend(face_info)
            cube_report.append({
                "bone": bone_name,
                "cube_index": local_index,
                "symbol": dl_symbol,
                "group": group,
                "layer": layer,
                "origin": list(origin),
                "size": list(size),
                "inflate": inflate,
                "rotation": list(vector(cube.get("rotation", [0, 0, 0]), "cube.rotation")),
                "faces": len(face_info),
                "vertices": 24,
                "triangles": 12,
            })
            cube_index += 1

    if cube_index == 0:
        raise BedrockModelError("No supported Bedrock cubes were found")

    group_symbols = {
        "torso": "steve_Torso_mesh_layer_1",
        "head": "steve_Head_DL_mesh_layer_1",
        "left_arm": "steve_Left_Arm_Color_mesh_layer_1",
        "right_arm": "steve_Right_Arm_Color_mesh_layer_1",
        "left_leg": "steve_Left_Thigh_Color_mesh_layer_1",
        "right_leg": "steve_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert",
    }
    for group in GROUPS:
        symbols = by_group[(group, "base")] + by_group[(group, "outer")]
        if not symbols:
            raise BedrockModelError(f"No Bedrock cubes mapped to required part {group}")
        lines.extend(emit_group(group_symbols[group], symbols))

    capless_symbol = "steve_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1"
    if not by_group[("head", "base")]:
        raise BedrockModelError("Bedrock head base cube is required")
    lines.extend(emit_group(capless_symbol, by_group[("head", "base")]))

    aliases = {
        "steve_Metal_Mario_Switch_Option_Torso_mesh_layer_1": group_symbols["torso"],
        "steve_Metal_Mario_Switch_Option_Head_DL_mesh_layer_1": group_symbols["head"],
        "steve_Metal_Mario_Switch_Option_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1":
            capless_symbol,
        "steve_Metal_Mario_Switch_Option_Left_Arm_Color_mesh_layer_1": group_symbols["left_arm"],
        "steve_Metal_Mario_Switch_Option_Right_Arm_Color_mesh_layer_1": group_symbols["right_arm"],
        "steve_Metal_Mario_Switch_Option_Left_Thigh_Color_mesh_layer_1": group_symbols["left_leg"],
        "steve_Metal_Mario_Switch_Option_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert_with_layer_1_revert":
            group_symbols["right_leg"],
        "steve_Metal_Mario_Switch_Option_Right_Thigh_Color_mesh_layer_1_with_layer_5_revert_with_layer_5_revert":
            group_symbols["right_leg"],
        "steve_Right_Thigh_Color_mesh_layer_1_with_layer_5_revert": group_symbols["right_leg"],
    }
    for alias, target in aliases.items():
        lines.extend([
            f"Gfx {alias}[] = {{",
            f"    gsSPDisplayList({target}),",
            "    gsSPEndDisplayList(),",
            "};",
            "",
        ])

    generated = set(re.findall(r"Gfx\s+([A-Za-z0-9_]+)\s*\[\s*\]", "\n".join(lines)))
    missing = sorted(set(mesh_symbols) - generated)
    if missing:
        raise BedrockModelError(
            "GeoLayout references mesh symbols not generated: " + ", ".join(missing)
        )

    output_root.mkdir(parents=True, exist_ok=True)
    (output / "model.inc.c").write_text("\n".join(lines), encoding="utf-8")
    (output / "geo.inc.c").write_text(geo_text, encoding="utf-8")
    (output / "geo_header.h").write_text(emit_header(layouts, mesh_symbols), encoding="utf-8")
    (output / "README.md").write_text(
        "# SteveCraft direct Bedrock DynOS actor\n\n"
        "Generated directly from Bedrock Geometry JSON by tools/build_steve_dynos.py. "
        "The model uses native DynOS C display lists and small per-face RGBA PNG textures; "
        "Blender and Fast64 are not used by this build path.\n\n"
        "The existing Mario-compatible GeoLayout remains the animation compatibility layer. "
        "The Bedrock bone tree is included in the build report, but this alpha does not "
        "replace the Mario animation rig with a native 17-bone Bedrock rig.\n",
        encoding="utf-8",
    )

    entity_identifier, entity_scale = parse_entity_scale(entity_config)
    unique_texture_hashes = {item["sha256"] for item in texture_report}
    return {
        "generator": "tools/build_steve_dynos.py",
        "source_geometry": str(geometry_path),
        "geometry_identifier": geometry["description"].get("identifier"),
        "source_format_version": document.get("format_version"),
        "bone_count": len(bones),
        "cube_count": cube_index,
        "face_count": len(texture_report),
        "vertex_count": cube_index * 24,
        "triangle_count": cube_index * 12,
        "texture_count": len(texture_report),
        "unique_texture_content_count": len(unique_texture_hashes),
        "group_cube_counts": {f"{g}:{l}": len(by_group[(g, l)]) for g in GROUPS for l in LAYERS},
        "geo_layout_count": len(layouts),
        "geo_mesh_symbol_count": len(mesh_symbols),
        "geo_template_preserved": True,
        "entity_identifier": entity_identifier,
        "entity_scale_from_entity_config": entity_scale,
        "entity_scale_applied": False,
        "bedrock_bones": bone_report,
        "cubes": cube_report,
        "textures": texture_report,
        "limitations": [
            "Cubes are baked into six existing Mario/DynOS animated mesh groups.",
            "The repository GeoLayout remains unchanged; the original Mario animation ordering is kept.",
            "The Bedrock bone tree is metadata, not a native Bedrock animation rig.",
            "Static Bedrock bone/cube rotations are baked into bind-pose vertices.",
            "The Metal Mario layout branches reuse the same textured geometry.",
            "Skin-face orientation and model scale still require in-game Android visual validation.",
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--geometry", required=True, type=Path)
    parser.add_argument("--skin", required=True, type=Path)
    parser.add_argument("--geo-template", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path,
                        help="actors directory; model is written to OUTPUT/steve")
    parser.add_argument("--entity-config", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()

    report = build_model(
        args.geometry, args.skin, args.geo_template, args.output, args.entity_config
    )
    report_path = args.report or (args.output.parent / "steve-dynos-report.json")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n",
                           encoding="utf-8")
    summary = {
        key: report[key] for key in (
            "bone_count", "cube_count", "face_count", "vertex_count",
            "triangle_count", "texture_count", "geo_layout_count",
            "geo_mesh_symbol_count",
        )
    }
    print("STEVE_DYNOS_BUILD_REPORT_BEGIN")
    print(json.dumps(summary, indent=2))
    print("STEVE_DYNOS_BUILD_REPORT_END")


if __name__ == "__main__":
    main()
