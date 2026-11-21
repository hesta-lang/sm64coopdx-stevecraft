from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from tools.build_steve_dynos import BedrockModelError, build_model


GEO_TEMPLATE = """\
const GeoLayout steve_geo[] = {
    GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, steve_Torso_mesh_layer_1),
    GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, steve_Head_DL_mesh_layer_1),
    GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, steve_Left_Arm_Color_mesh_layer_1),
    GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, steve_Right_Arm_Color_mesh_layer_1),
    GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, steve_Left_Thigh_Color_mesh_layer_1),
    GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, steve_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert),
    GEO_DISPLAY_LIST(LAYER_OPAQUE, steve_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1),
};
"""


def make_geometry():
    parents = {
        "root": None,
        "waist": "root",
        "body": "waist",
        "head": "body",
        "cape": "body",
        "hat": "head",
        "leftArm": "body",
        "leftSleeve": "leftArm",
        "leftItem": "leftArm",
        "rightArm": "body",
        "rightSleeve": "rightArm",
        "rightItem": "rightArm",
        "leftLeg": "root",
        "leftPants": "leftLeg",
        "rightLeg": "root",
        "rightPants": "rightLeg",
        "jacket": "body",
    }
    cubes = {
        "head": [{"origin": [-4, 24, -4], "size": [8, 8, 8], "uv": [0, 0],
                  "rotation": [0, 15, 0]}],
        "hat": [{"origin": [-4, 24, -4], "size": [8, 8, 8], "uv": [0, 0],
                 "inflate": 0.5}],
        "body": [{"origin": [-4, 12, -2], "size": [8, 12, 4], "uv": [16, 16]}],
        "jacket": [{
            "origin": [-4, 12, -2], "size": [8, 12, 4],
            "uv": {
                "north": {"uv": [0, 0], "uv_size": [8, 12]},
                "south": {"uv": [8, 0], "uv_size": [8, 12]},
                "east": {"uv": [16, 0], "uv_size": [4, 12]},
                "west": {"uv": [20, 0], "uv_size": [4, 12]},
                "up": {"uv": [24, 0], "uv_size": [8, 4]},
                "down": {"uv": [32, 0], "uv_size": [8, 4]},
            },
        }],
        "leftArm": [{"origin": [4, 12, -2], "size": [4, 12, 4], "uv": [40, 16]}],
        "leftSleeve": [{
            "origin": [4, 12, -2], "size": [4, 12, 4], "uv": [40, 16],
            "inflate": 0.25, "mirror": True,
        }],
        "rightArm": [{"origin": [-8, 12, -2], "size": [4, 12, 4], "uv": [40, 16]}],
        "rightSleeve": [{"origin": [-8, 12, -2], "size": [4, 12, 4], "uv": [40, 16]}],
        "leftLeg": [{"origin": [0, 0, -2], "size": [4, 12, 4], "uv": [0, 32]}],
        "leftPants": [{"origin": [0, 0, -2], "size": [4, 12, 4], "uv": [0, 32]}],
        "rightLeg": [{"origin": [-4, 0, -2], "size": [4, 12, 4], "uv": [0, 32]}],
        "rightPants": [{"origin": [-4, 0, -2], "size": [4, 12, 4], "uv": [0, 32]}],
    }
    bones = []
    for name, parent in parents.items():
        bone = {"name": name, "pivot": [0, 0, 0]}
        if parent is not None:
            bone["parent"] = parent
        if name in cubes:
            bone["cubes"] = cubes[name]
        bones.append(bone)
    return {
        "format_version": "1.12.0",
        "minecraft:geometry": [{
            "description": {
                "identifier": "geometry.humanoid.custom",
                "texture_width": 64,
                "texture_height": 64,
            },
            "bones": bones,
        }],
    }


class DirectDynOSGeneratorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.geometry = self.root / "geometry.json"
        self.skin = self.root / "skin.png"
        self.geo = self.root / "geo.inc.c"
        self.output = self.root / "actors"
        self.geometry.write_text(json.dumps(make_geometry()), encoding="utf-8")
        skin = Image.new("RGBA", (64, 64), (70, 120, 180, 255))
        skin.putpixel((1, 1), (0, 0, 0, 0))
        skin.save(self.skin)
        self.geo.write_text(GEO_TEMPLATE, encoding="utf-8")

    def tearDown(self):
        self.temp.cleanup()

    def test_generates_native_mesh_and_face_textures(self):
        report = build_model(self.geometry, self.skin, self.geo, self.output)
        actor = self.output / "steve"
        self.assertEqual(report["geometry_identifier"], "geometry.humanoid.custom")
        self.assertEqual(report["bone_count"], 17)
        self.assertEqual(report["cube_count"], 12)
        self.assertEqual(report["face_count"], 72)
        self.assertEqual(report["vertex_count"], 12 * 24)
        self.assertEqual(report["triangle_count"], 12 * 12)
        self.assertTrue((actor / "model.inc.c").is_file())
        self.assertTrue((actor / "geo.inc.c").is_file())
        self.assertTrue((actor / "geo_header.h").is_file())
        self.assertEqual((actor / "geo.inc.c").read_text(), GEO_TEMPLATE)
        pngs = list(actor.glob("*.png"))
        self.assertEqual(len(pngs), 72)
        model = (actor / "model.inc.c").read_text()
        self.assertIn("gsDPSetTextureFilter(G_TF_POINT)", model)
        self.assertIn("gsDPLoadTextureBlock", model)
        self.assertIn("steve_Head_DL_mesh_layer_1", model)
        self.assertIn("steve_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1", model)
        self.assertIn("steve_Metal_Mario_Switch_Option_Torso_mesh_layer_1", model)
        self.assertIn("Texture steve_head_0_1_north_texture[]", model)

    def test_preserves_geo_layout_references_in_header(self):
        build_model(self.geometry, self.skin, self.geo, self.output)
        header = (self.output / "steve" / "geo_header.h").read_text()
        self.assertIn("extern const GeoLayout steve_geo[];", header)
        self.assertIn("extern Gfx steve_Torso_mesh_layer_1[];", header)
        self.assertIn(
            "extern Gfx steve_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert[];",
            header,
        )

    def test_rejects_cubes_on_unmapped_bones(self):
        data = make_geometry()
        data["minecraft:geometry"][0]["bones"][4]["cubes"] = [{
            "origin": [0, 0, 0], "size": [1, 1, 1], "uv": [0, 0]
        }]
        self.geometry.write_text(json.dumps(data), encoding="utf-8")
        with self.assertRaisesRegex(BedrockModelError, "not mapped"):
            build_model(self.geometry, self.skin, self.geo, self.output)

    def test_rejects_out_of_bounds_uv(self):
        data = make_geometry()
        head = next(b for b in data["minecraft:geometry"][0]["bones"] if b["name"] == "head")
        head["cubes"][0]["uv"] = [60, 60]
        self.geometry.write_text(json.dumps(data), encoding="utf-8")
        with self.assertRaisesRegex(BedrockModelError, "exceeds"):
            build_model(self.geometry, self.skin, self.geo, self.output)

    def test_rejects_invalid_hierarchy_cycle(self):
        data = make_geometry()
        data["minecraft:geometry"][0]["bones"][0]["parent"] = "head"
        self.geometry.write_text(json.dumps(data), encoding="utf-8")
        with self.assertRaisesRegex(BedrockModelError, "Cycle"):
            build_model(self.geometry, self.skin, self.geo, self.output)


if __name__ == "__main__":
    unittest.main()
