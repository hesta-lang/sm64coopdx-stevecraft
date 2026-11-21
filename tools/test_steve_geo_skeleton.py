from __future__ import annotations

import unittest

from steve_geo_skeleton import (
    EXPECTED_ANIMATED_NODES,
    FULL_BODY_LAYOUTS,
    patch_steve_dynos_skeleton_source,
)


def make_layout(name: str, layer: str = "LAYER_OPAQUE") -> str:
    lines = [f"const GeoLayout {name}[] = {{", f"    GEO_ANIMATED_PART({layer}, 0, 0, 0, NULL),"]
    for index in range(13):
        lines.append(f"    GEO_ANIMATED_PART({layer}, {index}, 0, 0, NULL),")

    for side in ("Left", "Right"):
        lines.extend([
            f"    GEO_ANIMATED_PART({layer}, 0, 0, 0, steve_{side}_Arm_Color_mesh_layer_1),",
            "    GEO_OPEN_NODE(),",
            f"        GEO_ANIMATED_PART({layer}, 31, 0, 0, NULL),",
            "    GEO_CLOSE_NODE(),",
        ])
    lines.extend(["};", ""])
    return "\n".join(lines)


class SteveGeoSkeletonTests(unittest.TestCase):
    def test_inserts_both_wrist_nodes_in_all_full_body_layouts(self):
        source = "".join(
            make_layout(name, "LAYER_TRANSPARENT" if "opt" in name else "LAYER_OPAQUE")
            for name in FULL_BODY_LAYOUTS
        )
        patched, report = patch_steve_dynos_skeleton_source(source)

        self.assertEqual(report["layouts_validated"], list(FULL_BODY_LAYOUTS))
        self.assertEqual(report["inserted_wrist_nodes"], {"left": 4, "right": 4})
        for name in FULL_BODY_LAYOUTS:
            start = patched.index(f"const GeoLayout {name}[] = {{")
            end = patched.index("\n};", start)
            layout = patched[start:end]
            self.assertEqual(
                layout.count("GEO_ANIMATED_PART("),
                EXPECTED_ANIMATED_NODES,
                name,
            )
            layer = "LAYER_TRANSPARENT" if "opt" in name else "LAYER_OPAQUE"
            self.assertIn(
                f"GEO_ANIMATED_PART({layer}, 31, 0, 0, NULL),\n"
                "        GEO_OPEN_NODE(),\n"
                f"            GEO_ANIMATED_PART({layer}, 0, 0, 0, NULL),\n"
                "        GEO_CLOSE_NODE(),",
                layout,
            )

    def test_is_idempotent(self):
        source = "".join(make_layout(name) for name in FULL_BODY_LAYOUTS)
        first, _ = patch_steve_dynos_skeleton_source(source)
        second, report = patch_steve_dynos_skeleton_source(first)
        self.assertEqual(first, second)
        self.assertEqual(report["inserted_wrist_nodes"], {"left": 0, "right": 0})

    def test_rejects_a_missing_wrist_branch(self):
        source = "".join(make_layout(name) for name in FULL_BODY_LAYOUTS)
        source = source.replace(
            "GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, steve_Right_Arm_Color_mesh_layer_1),\n"
            "    GEO_OPEN_NODE(),\n"
            "        GEO_ANIMATED_PART(LAYER_OPAQUE, 31, 0, 0, NULL),",
            "GEO_ANIMATED_PART(LAYER_OPAQUE, 0, 0, 0, NULL),\n"
            "    GEO_OPEN_NODE(),\n"
            "        GEO_ANIMATED_PART(LAYER_OPAQUE, 31, 0, 0, NULL),",
        )
        with self.assertRaisesRegex(ValueError, "right arm display node"):
            patch_steve_dynos_skeleton_source(source)


if __name__ == "__main__":
    unittest.main()
