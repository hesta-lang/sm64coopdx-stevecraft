from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from import_bedrock_geometry import (
    BedrockGeometryError,
    EXPECTED_BONES,
    EXPECTED_CUBE_KEYS,
    import_geometry_document,
    load_imported_spec,
    validate_imported_spec,
)


def make_sample_document():
    bones = [
        {"name": "root", "pivot": [0, 0, 0]},
        {"name": "body", "parent": "waist", "pivot": [0, 24, 0],
         "cubes": [{"origin": [-4, 12, -2], "size": [8, 12, 4], "uv": [16, 16]}]},
        {"name": "waist", "parent": "root", "pivot": [0, 12, 0]},
        {"name": "head", "parent": "body", "pivot": [0, 24, 0],
         "cubes": [{"origin": [-4, 24, -4], "size": [8, 8, 8], "uv": [0, 0]}]},
        {"name": "cape", "parent": "body", "pivot": [0, 24, 3]},
        {"name": "hat", "parent": "head", "pivot": [0, 24, 0],
         "cubes": [{"origin": [-4, 24, -4], "size": [8, 8, 8], "uv": [32, 0], "inflate": 0.5}]},
        {"name": "leftArm", "parent": "body", "pivot": [5, 22, 0],
         "cubes": [{"origin": [4, 12, -2], "size": [4, 12, 4], "uv": [32, 48]}]},
        {"name": "leftSleeve", "parent": "leftArm", "pivot": [5, 22, 0],
         "cubes": [{"origin": [4, 12, -2], "size": [4, 12, 4], "uv": [48, 48], "inflate": 0.25}]},
        {"name": "leftItem", "parent": "leftArm", "pivot": [6, 15, 1]},
        {"name": "rightArm", "parent": "body", "pivot": [-5, 22, 0],
         "cubes": [{"origin": [-8, 12, -2], "size": [4, 12, 4], "uv": [40, 16]}]},
        {"name": "rightSleeve", "parent": "rightArm", "pivot": [-5, 22, 0],
         "cubes": [{"origin": [-8, 12, -2], "size": [4, 12, 4], "uv": [40, 32], "inflate": 0.25}]},
        {"name": "rightItem", "parent": "rightArm", "pivot": [-6, 15, 1],
         "locators": {"lead_hold": [-6, 15, 1]}},
        {"name": "leftLeg", "parent": "root", "pivot": [1.9, 12, 0],
         "cubes": [{"origin": [-0.1, 0, -2], "size": [4, 12, 4], "uv": [16, 48]}]},
        {"name": "leftPants", "parent": "leftLeg", "pivot": [1.9, 12, 0],
         "cubes": [{"origin": [-0.1, 0, -2], "size": [4, 12, 4], "uv": [0, 48], "inflate": 0.25}]},
        {"name": "rightLeg", "parent": "root", "pivot": [-1.9, 12, 0],
         "cubes": [{"origin": [-3.9, 0, -2], "size": [4, 12, 4], "uv": [0, 16]}]},
        {"name": "rightPants", "parent": "rightLeg", "pivot": [-1.9, 12, 0],
         "cubes": [{"origin": [-3.9, 0, -2], "size": [4, 12, 4], "uv": [0, 32], "inflate": 0.25}]},
        {"name": "jacket", "parent": "body", "pivot": [0, 24, 0],
         "cubes": [{"origin": [-4, 12, -2], "size": [8, 12, 4], "uv": [16, 32], "inflate": 0.25}]},
    ]
    return {"format_version": "1.21.0", "minecraft:geometry": [{
        "description": {"identifier": "geometry.humanoid.custom",
                        "visible_bounds_width": 1,
                        "visible_bounds_height": 2,
                        "visible_bounds_offset": [0, 1, 0]},
        "bones": bones,
    }]}


def make_entity_document():
    return {"minecraft:client_entity": {"description": {
        "identifier": "minecraft:player",
        "scripts": {"scale": "0.9375"},
    }}}


class BedrockGeometryImporterTests(unittest.TestCase):
    def test_imports_17_bones_and_12_cuboids(self):
        spec = import_geometry_document(make_sample_document(), "fixture-revision")
        self.assertEqual(spec["bone_count"], 17)
        self.assertEqual(spec["cube_count"], 12)
        self.assertEqual({item["name"] for item in spec["bone_tree"]}, EXPECTED_BONES)
        self.assertEqual({item["key"] for item in spec["cuboids"]}, EXPECTED_CUBE_KEYS)
        validate_imported_spec(spec)

    def test_bedrock_y_up_is_converted_to_builder_y_down(self):
        spec = import_geometry_document(make_sample_document())
        cuboids = {item["key"]: item for item in spec["cuboids"]}
        self.assertEqual(cuboids["head_base"]["origin"], [-4.0, -8.0, -4.0])
        self.assertEqual(cuboids["torso_base"]["origin"], [-4.0, 0.0, -2.0])
        self.assertEqual(cuboids["right_leg_base"]["origin"], [-3.9, 12.0, -2.0])

    def test_preserves_bone_pivots_parents_and_item_locator(self):
        spec = import_geometry_document(make_sample_document())
        bones = {item["name"]: item for item in spec["bone_tree"]}
        self.assertEqual(bones["body"]["parent"], "waist")
        self.assertEqual(bones["rightItem"]["parent"], "rightArm")
        self.assertEqual(bones["rightItem"]["locators"]["lead_hold"], [-6, 15, 1])
        self.assertEqual(bones["head"]["pivot_target"], [1.0, 0.0, 0.0])

    def test_reads_bedrock_entity_scale(self):
        spec = import_geometry_document(
            make_sample_document(), entity_document=make_entity_document()
        )
        self.assertAlmostEqual(spec["entity_scale"], 0.9375)

    def test_rejects_missing_required_bone(self):
        document = make_sample_document()
        document["minecraft:geometry"][0]["bones"] = [
            item for item in document["minecraft:geometry"][0]["bones"]
            if item["name"] != "rightItem"
        ]
        with self.assertRaisesRegex(BedrockGeometryError, "missing required bones"):
            import_geometry_document(document)

    def test_rejects_rotated_cubes(self):
        document = make_sample_document()
        head = next(item for item in document["minecraft:geometry"][0]["bones"]
                    if item["name"] == "head")
        head["cubes"][0]["rotation"] = [0, 15, 0]
        with self.assertRaisesRegex(BedrockGeometryError, "rotated cube"):
            import_geometry_document(document)

    def test_validates_serialized_spec(self):
        spec = import_geometry_document(make_sample_document())
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "bedrock-import.json"
            path.write_text(json.dumps(spec), encoding="utf-8")
            loaded = load_imported_spec(path)
        self.assertEqual(loaded["cube_count"], 12)

    @unittest.skipUnless(os.environ.get("BEDROCK_GEOMETRY_SOURCE"),
                         "Official Mojang Bedrock geometry is supplied by CI")
    def test_official_mojang_sample_geometry(self):
        source_path = Path(os.environ["BEDROCK_GEOMETRY_SOURCE"])
        document = json.loads(source_path.read_text(encoding="utf-8"))
        entity_path = os.environ.get("BEDROCK_ENTITY_SOURCE")
        entity_document = (
            json.loads(Path(entity_path).read_text(encoding="utf-8"))
            if entity_path else None
        )
        spec = import_geometry_document(
            document,
            source_revision=os.environ.get("BEDROCK_SOURCE_REVISION"),
            entity_document=entity_document,
        )
        self.assertEqual(spec["bone_count"], 17)
        self.assertEqual(spec["cube_count"], 12)
        self.assertEqual(spec["geometry_identifier"], "geometry.humanoid.custom")
        self.assertAlmostEqual(spec["entity_scale"], 0.9375)
        validate_imported_spec(spec)


if __name__ == "__main__":
    unittest.main()
