#!/usr/bin/env python3
"""Import Mojang Bedrock humanoid geometry into the SteveCraft DynOS schema."""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

SOURCE_REPOSITORY = "Mojang/bedrock-samples"
SOURCE_GEOMETRY_PATH = "resource_pack/models/entity/humanoid.custom.geo.json"
SOURCE_ENTITY_PATH = "resource_pack/entity/player.entity.json"
TARGET_GROUPS = {
    "Torso", "Head DL", "Left Arm Color",
    "Right Arm Color", "Left Thigh Color", "Right Thigh Color",
}
BONE_TO_CUBE = {
    "head": ("head_base", "Head DL", False),
    "hat": ("head_hat", "Head DL", True),
    "body": ("torso_base", "Torso", False),
    "jacket": ("torso_jacket", "Torso", True),
    "rightArm": ("right_arm_base", "Right Arm Color", False),
    "rightSleeve": ("right_arm_sleeve", "Right Arm Color", True),
    "leftArm": ("left_arm_base", "Left Arm Color", False),
    "leftSleeve": ("left_arm_sleeve", "Left Arm Color", True),
    "rightLeg": ("right_leg_base", "Right Thigh Color", False),
    "rightPants": ("right_leg_pants", "Right Thigh Color", True),
    "leftLeg": ("left_leg_base", "Left Thigh Color", False),
    "leftPants": ("left_leg_pants", "Left Thigh Color", True),
}
EXPECTED_CUBE_KEYS = {value[0] for value in BONE_TO_CUBE.values()}
EXPECTED_BONES = {
    "root", "waist", "body", "head", "cape", "hat",
    "leftArm", "leftSleeve", "leftItem",
    "rightArm", "rightSleeve", "rightItem",
    "leftLeg", "leftPants", "rightLeg", "rightPants", "jacket",
}


class BedrockGeometryError(ValueError):
    """Raised when a Bedrock geometry cannot be represented by this importer."""


def _number(value: Any, label: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise BedrockGeometryError(f"{label} must be a number")
    result = float(value)
    if not math.isfinite(result):
        raise BedrockGeometryError(f"{label} must be finite")
    return result


def _vector(value: Any, length: int, label: str) -> list[float]:
    if not isinstance(value, list) or len(value) != length:
        raise BedrockGeometryError(f"{label} must contain {length} numbers")
    return [_number(part, f"{label}[{index}]") for index, part in enumerate(value)]


def bedrock_to_target_point(point: list[float]) -> list[float]:
    """Map Bedrock pixels (X right, Y up, Z depth) to SM64 armature units."""
    x, y, z = point
    return [
        round(y / 16.0 - 0.5, 6),
        round(-x / 16.0, 6),
        round(-z / 16.0, 6),
    ]


def _find_geometry(document: dict[str, Any]) -> dict[str, Any]:
    geometries = document.get("minecraft:geometry")
    if not isinstance(geometries, list):
        raise BedrockGeometryError("Missing minecraft:geometry array")
    matches = [
        item for item in geometries
        if isinstance(item, dict)
        and isinstance(item.get("description"), dict)
        and item["description"].get("identifier") == "geometry.humanoid.custom"
    ]
    if len(matches) != 1:
        raise BedrockGeometryError(
            "Expected exactly one geometry.humanoid.custom entry; "
            f"found {len(matches)}"
        )
    return matches[0]


def _validate_bone_tree(bones: list[dict[str, Any]]) -> None:
    by_name: dict[str, dict[str, Any]] = {}
    for index, bone in enumerate(bones):
        if not isinstance(bone, dict):
            raise BedrockGeometryError(f"Bone {index} must be an object")
        name = bone.get("name")
        if not isinstance(name, str) or not name:
            raise BedrockGeometryError(f"Bone {index} has no valid name")
        if name in by_name:
            raise BedrockGeometryError(f"Duplicate Bedrock bone: {name}")
        by_name[name] = bone

    missing = sorted(EXPECTED_BONES - set(by_name))
    if missing:
        raise BedrockGeometryError(
            "Bedrock humanoid geometry is missing required bones: " + ", ".join(missing)
        )

    for name, bone in by_name.items():
        parent = bone.get("parent")
        if parent is not None and parent not in by_name:
            raise BedrockGeometryError(f"Bone {name} refers to missing parent {parent}")
        _vector(bone.get("pivot"), 3, f"bone {name} pivot")

    for name in by_name:
        seen: set[str] = set()
        current: str | None = name
        while current is not None:
            if current in seen:
                raise BedrockGeometryError(f"Cycle detected in Bedrock bone tree at {current}")
            seen.add(current)
            current = by_name[current].get("parent")


def import_geometry_document(
    document: dict[str, Any],
    source_revision: str | None = None,
    entity_document: dict[str, Any] | None = None,
) -> dict[str, Any]:
    if not isinstance(document, dict):
        raise BedrockGeometryError("Geometry document must be a JSON object")
    geometry = _find_geometry(document)
    description = geometry["description"]
    bones = geometry.get("bones")
    if not isinstance(bones, list):
        raise BedrockGeometryError("geometry.humanoid.custom has no bones array")
    _validate_bone_tree(bones)

    unsupported = sorted(
        bone["name"] for bone in bones
        if bone.get("cubes") and bone["name"] not in BONE_TO_CUBE
    )
    if unsupported:
        raise BedrockGeometryError(
            "This first DynOS mapping does not yet support cube geometry on: "
            + ", ".join(unsupported)
        )

    cuboids: list[dict[str, Any]] = []
    for bone in bones:
        name = bone["name"]
        cubes = bone.get("cubes") or []
        if not isinstance(cubes, list):
            raise BedrockGeometryError(f"{name}.cubes must be an array")
        if len(cubes) > 1:
            raise BedrockGeometryError(
                f"{name} has {len(cubes)} cubes; this first importer expects one "
                "classic Steve cuboid per render bone"
            )
        if not cubes:
            continue
        cube = cubes[0]
        if not isinstance(cube, dict):
            raise BedrockGeometryError(f"{name} cube must be an object")
        if cube.get("rotation") is not None:
            raise BedrockGeometryError(
                f"{name} uses a rotated cube; rotated Bedrock cubes are not "
                "supported by this first DynOS conversion"
            )

        origin = _vector(cube.get("origin"), 3, f"{name} cube origin")
        size = _vector(cube.get("size"), 3, f"{name} cube size")
        if any(value <= 0 for value in size):
            raise BedrockGeometryError(f"{name} cube dimensions must be positive")
        uv = _vector(cube.get("uv"), 2, f"{name} cube uv")
        inflate = _number(cube.get("inflate", 0.0), f"{name} cube inflate")
        if inflate < 0:
            raise BedrockGeometryError(f"{name} cube inflate cannot be negative")

        key, group, outer = BONE_TO_CUBE[name]
        # Bedrock is Y-up; the existing mesh builder consumes a Java-style
        # Y-down origin. This keeps the classic cube coordinates equivalent.
        converted_origin = [
            round(origin[0], 6),
            round(24.0 - origin[1] - size[1], 6),
            round(origin[2], 6),
        ]
        item = {
            "key": key,
            "group": group,
            "origin": converted_origin,
            "size": [round(value, 6) for value in size],
            "inflate": round(inflate, 6),
            "uv": [round(value, 6) for value in uv],
            "outer": outer,
            "bedrock_bone": name,
        }
        if cube.get("mirror") is True:
            item["mirror"] = True
        cuboids.append(item)

    keys = [cube["key"] for cube in cuboids]
    if len(keys) != len(set(keys)) or set(keys) != EXPECTED_CUBE_KEYS:
        missing = sorted(EXPECTED_CUBE_KEYS - set(keys))
        unexpected = sorted(set(keys) - EXPECTED_CUBE_KEYS)
        raise BedrockGeometryError(
            "Classic Steve geometry must map exactly 12 cuboids; "
            f"missing={missing}, unexpected={unexpected}"
        )

    bone_tree = []
    for bone in bones:
        name = bone["name"]
        pivot = _vector(bone.get("pivot"), 3, f"bone {name} pivot")
        locators = bone.get("locators", {})
        if not isinstance(locators, dict):
            raise BedrockGeometryError(f"{name}.locators must be an object")
        bone_tree.append({
            "name": name,
            "parent": bone.get("parent"),
            "pivot_bedrock": [round(value, 6) for value in pivot],
            "pivot_target": bedrock_to_target_point(pivot),
            "locators": locators,
            "has_geometry": bool(bone.get("cubes")),
        })

    entity_scale = 1.0
    entity_identifier = None
    if entity_document is not None:
        try:
            entity_description = entity_document["minecraft:client_entity"]["description"]
            entity_identifier = entity_description.get("identifier")
            scale_value = entity_description.get("scripts", {}).get("scale", "1.0")
            entity_scale = _number(float(scale_value), "player entity scale")
        except (KeyError, TypeError, ValueError) as exc:
            raise BedrockGeometryError("Could not read player.entity.json scale") from exc
        if entity_scale <= 0 or entity_scale > 2:
            raise BedrockGeometryError("Player entity scale must be between 0 and 2")

    return {
        "schema_version": 1,
        "source": SOURCE_REPOSITORY,
        "source_revision": source_revision,
        "source_geometry_path": SOURCE_GEOMETRY_PATH,
        "source_entity_path": SOURCE_ENTITY_PATH if entity_document is not None else None,
        "format_version": document.get("format_version"),
        "geometry_identifier": description.get("identifier"),
        "visible_bounds": description.get("visible_bounds", {}),
        "entity_identifier": entity_identifier,
        "entity_scale": round(entity_scale, 6),
        "bone_count": len(bone_tree),
        "cube_count": len(cuboids),
        "bone_tree": bone_tree,
        "cuboids": sorted(cuboids, key=lambda item: item["key"]),
        "target_groups": sorted(TARGET_GROUPS),
        "coordinate_conversion": (
            "Bedrock origin Y-up to builder Y-down: target_origin_y = 24 - origin_y - size_y; "
            "armature axes are vertical/side/depth"
        ),
        "limitations": [
            "The complete Bedrock hierarchy is preserved as import metadata.",
            "Visible cube geometry is weighted to the six existing SM64CoopDX player mesh groups.",
            "Bedrock-only cape and item locator bones are preserved as metadata but are not rendered by this first import.",
            "Rotated cubes, multiple cubes per render bone, and non-classic custom player geometry are rejected.",
        ],
    }


def validate_imported_spec(spec: dict[str, Any]) -> None:
    if not isinstance(spec, dict) or spec.get("schema_version") != 1:
        raise BedrockGeometryError("Unsupported Bedrock import spec schema")
    if spec.get("geometry_identifier") != "geometry.humanoid.custom":
        raise BedrockGeometryError("Import spec does not describe geometry.humanoid.custom")
    cuboids = spec.get("cuboids")
    if not isinstance(cuboids, list) or len(cuboids) != 12:
        raise BedrockGeometryError("Import spec must contain exactly 12 cuboids")

    keys: set[str] = set()
    for index, cube in enumerate(cuboids):
        if not isinstance(cube, dict):
            raise BedrockGeometryError(f"Imported cuboid {index} must be an object")
        key = cube.get("key")
        if not isinstance(key, str) or key in keys:
            raise BedrockGeometryError(f"Imported cuboid {index} has a missing or duplicate key")
        keys.add(key)
        if cube.get("group") not in TARGET_GROUPS:
            raise BedrockGeometryError(f"{key} maps to an unsupported SM64 group")
        _vector(cube.get("origin"), 3, f"{key}.origin")
        _vector(cube.get("size"), 3, f"{key}.size")
        _vector(cube.get("uv"), 2, f"{key}.uv")
    if keys != EXPECTED_CUBE_KEYS:
        raise BedrockGeometryError("Import spec is missing one or more classic Steve cuboids")

    bone_tree = spec.get("bone_tree")
    if not isinstance(bone_tree, list) or len(bone_tree) < len(EXPECTED_BONES):
        raise BedrockGeometryError("Import spec does not preserve the complete Bedrock bone tree")
    entity_scale = _number(spec.get("entity_scale", 1.0), "entity_scale")
    if entity_scale <= 0 or entity_scale > 2:
        raise BedrockGeometryError("Import spec entity_scale is out of range")


def load_imported_spec(path: str | Path) -> dict[str, Any]:
    spec = json.loads(Path(path).read_text(encoding="utf-8"))
    validate_imported_spec(spec)
    return spec


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--entity-config", type=Path)
    parser.add_argument("--source-revision", default=None)
    args = parser.parse_args()

    document = json.loads(args.input.read_text(encoding="utf-8"))
    entity_document = (
        json.loads(args.entity_config.read_text(encoding="utf-8"))
        if args.entity_config else None
    )
    spec = import_geometry_document(
        document,
        source_revision=args.source_revision,
        entity_document=entity_document,
    )
    validate_imported_spec(spec)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(spec, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "geometry_identifier": spec["geometry_identifier"],
        "source_revision": spec["source_revision"],
        "bone_count": spec["bone_count"],
        "cube_count": spec["cube_count"],
        "entity_scale": spec["entity_scale"],
        "mapped_groups": spec["target_groups"],
        "output": str(args.output),
    }, indent=2))


if __name__ == "__main__":
    main()
