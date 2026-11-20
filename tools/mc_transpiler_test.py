import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRANSPILER = ROOT / "tools" / "java_to_lua.py"
FIXTURES = ROOT / "tools" / "mc_sources_fixture"
MC_FIXTURES = ROOT / "tools" / "minecraft_26_3_fixtures"

class TranspilerIntegrationTests(unittest.TestCase):
    def test_java_subset_generates_modules_and_reports_unsupported_syntax(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "lua"
            report = Path(tmp) / "report.json"
            run = subprocess.run(
                [sys.executable, str(TRANSPILER), "--input", str(FIXTURES),
                 "--output", str(output), "--version", "test-fixture", "--report", str(report)],
                capture_output=True, text=True
            )
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            data = json.loads(report.read_text())
            self.assertEqual(data["translated_methods"], 5)
            self.assertEqual(len(data["skipped_methods"]), 1)
            self.assertEqual(data["strict_blockers"], 1)

            player = (output / "net/minecraft/demo/PlayerMath.lua").read_text()
            entry = (output / "net/minecraft/demo/PlayerEntry.lua").read_text()
            self.assertIn("PlayerMath.LIMIT", player)
            self.assertIn("MC.Mth.clamp", player)
            self.assertIn("MC.Mth.lerp", player)
            self.assertIn("value = value + 0.5", player)
            self.assertIn("for i = 0, (2 - 1), 1 do", player)
            self.assertIn("net/minecraft/demo/VecHelper", entry)

    def test_real_minecraft_method_excerpts_translate_only_supported_bodies(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "lua"
            report = Path(tmp) / "report.json"
            run = subprocess.run(
                [sys.executable, str(TRANSPILER), "--input", str(MC_FIXTURES),
                 "--output", str(output), "--version", "26.3-fixture", "--report", str(report)],
                capture_output=True, text=True
            )
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            data = json.loads(report.read_text())
            self.assertEqual(data["translated_methods"], 3)
            self.assertEqual(len(data["skipped_methods"]), 7)
            self.assertEqual(data["strict_blockers"], 7)
            self.assertFalse(data["skipped_files"])
            reasons = " | ".join(item["reason"] for item in data["skipped_methods"])
            self.assertIn("super calls", reasons)
            self.assertIn("ternary conditional operator", reasons)
            self.assertIn("object construction", reasons)
            self.assertIn("lambda/method reference", reasons)
            self.assertIn("unadapted Minecraft engine type/API", reasons)
            humanoid = (output / "net/minecraft/client/model/HumanoidModel.lua").read_text()
            player = (output / "net/minecraft/client/model/player/PlayerModel.lua").read_text()
            self.assertIn("function HumanoidModel:getHead()", humanoid)
            self.assertIn("function HumanoidModel:quadraticArmUpdate(x)", humanoid)
            self.assertNotIn("function HumanoidModel:getArm(", humanoid)
            self.assertIn("local Util = MC.Util", player)
            self.assertIn("function PlayerModel:getRandomBodyPart(random)", player)
            self.assertNotIn("function PlayerModel:setupAnim(", player)

    def test_qualified_class_filter_selects_the_requested_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "lua"
            report = Path(tmp) / "report.json"
            run = subprocess.run(
                [sys.executable, str(TRANSPILER), "--input", str(MC_FIXTURES),
                 "--output", str(output), "--class", "net.minecraft.client.model.player.PlayerModel",
                 "--report", str(report)], capture_output=True, text=True
            )
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            data = json.loads(report.read_text())
            self.assertEqual(len(data["files_seen"]), 1)
            self.assertTrue(data["files_seen"][0].endswith("PlayerModel.java"))
            self.assertEqual(data["generated_modules"], ["net/minecraft/client/model/player/PlayerModel.lua"])

    def test_strict_mode_fails_when_a_method_is_skipped(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = subprocess.run(
                [sys.executable, str(TRANSPILER), "--input", str(FIXTURES),
                 "--output", str(Path(tmp) / "lua"), "--strict"],
                capture_output=True, text=True
            )
            self.assertEqual(run.returncode, 2, run.stdout + run.stderr)

if __name__ == "__main__":
    unittest.main()
