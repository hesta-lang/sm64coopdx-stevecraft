import unittest
from pathlib import Path

from steve_geo_sanitizer import sanitize_steve_geo_source

ROOT = Path(__file__).resolve().parents[1]


class SteveGeoSanitizerTests(unittest.TestCase):
    def test_removes_all_mario_pose_callbacks_but_keeps_neutral_geo_switches(self):
        source = """const GeoLayout steve_geo[] = {
    GEO_SHADOW(99, 180, 100),
    GEO_OPEN_NODE(),
        GEO_ASM(0, geo_mirror_mario_set_alpha),
        GEO_ASM(0, geo_move_mario_part_from_parent),
        GEO_ASM(0, geo_mario_tilt_torso),
        GEO_ASM(0, geo_mario_head_rotation),
        GEO_SWITCH_CASE(0, geo_switch_mario_stand_run),
    GEO_CLOSE_NODE(),
    GEO_END(),
};
"""
        sanitized, report = sanitize_steve_geo_source(source)
        self.assertEqual(report["shared_mario_alpha_callbacks_removed"], 1)
        self.assertEqual(report["mario_pose_callbacks_removed"], 3)
        for callback in (
            "geo_mirror_mario_set_alpha",
            "geo_move_mario_part_from_parent",
            "geo_mario_tilt_torso",
            "geo_mario_head_rotation",
        ):
            self.assertNotIn(callback, sanitized)
        self.assertIn("GEO_SHADOW(99, 180, 100)", sanitized)
        self.assertIn("geo_switch_mario_stand_run", sanitized)

    def test_removes_unsupported_custom_command(self):
        source = "const GeoLayout steve_geo[] = {\n    CUSTOM_CMD(),\n    GEO_END(),\n};\n"
        sanitized, report = sanitize_steve_geo_source(source)
        self.assertEqual(report["unsupported_custom_commands_removed"], 1)
        self.assertNotIn("CUSTOM_CMD", sanitized)

    def test_committed_steve_geo_does_not_copy_native_mario_alpha(self):
        source = (ROOT / "actors" / "steve" / "geo.inc.c").read_text(encoding="utf-8")
        for callback in (
            "geo_mirror_mario_set_alpha",
            "geo_move_mario_part_from_parent",
            "geo_mario_tilt_torso",
            "geo_mario_head_rotation",
        ):
            self.assertNotIn(callback, source)


if __name__ == "__main__":
    unittest.main()
