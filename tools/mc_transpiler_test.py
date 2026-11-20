import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRANSPILER = ROOT / "tools" / "java_to_lua.py"
FIXTURES = ROOT / "tools" / "mc_sources_fixture"
MC_FIXTURES = ROOT / "tools" / "minecraft_26_3_fixture_tree"

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
            self.assertEqual(data["translated_methods"], 4)
            self.assertEqual(len(data["skipped_methods"]), 6)
            self.assertEqual(data["strict_blockers"], 6)
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
            self.assertIn("function HumanoidModel:getArm(arm)", humanoid)
            self.assertIn("local HumanoidArm = MC.HumanoidArm", humanoid)
            self.assertIn("if arm == HumanoidArm . LEFT then", humanoid)
            self.assertIn("local Util = MC.Util", player)
            self.assertIn("function PlayerModel:getRandomBodyPart(random)", player)
            self.assertNotIn("function PlayerModel:setupAnim(", player)

    def test_mth_explicit_self_calls_resolve_to_the_translated_class(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "src" / "net" / "minecraft" / "util" / "Mth.java"
            source.parent.mkdir(parents=True)
            source.write_text(
                "package net.minecraft.util; public class Mth { "
                "public static double clamp(double value,double min,double max) { "
                "return value<min?min:Math.min(value,max); } "
                "public static double approach(double current,double target,double step) { "
                "return current+Mth.clamp(target-current,-step,step); } }",
                encoding="utf-8"
            )
            output = Path(tmp) / "lua"
            report = Path(tmp) / "report.json"
            run = subprocess.run(
                [sys.executable, str(TRANSPILER), "--input", str(source.parent),
                 "--output", str(output), "--report", str(report)],
                capture_output=True, text=True
            )
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            generated = (output / "net/minecraft/util/Mth.lua").read_text()
            self.assertIn("function Mth.approach", generated)
            self.assertIn("Mth.clamp", generated)
            self.assertNotIn("MC.Mth.clamp", generated)

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

    def test_non_return_ternary_remains_blocked(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "src" / "net" / "minecraft" / "demo" / "Ternary.java"
            source.parent.mkdir(parents=True)
            source.write_text(
                "package net.minecraft.demo; public class Ternary { "
                "public int choose(boolean flag) { int value = flag ? 1 : 2; return value; } "
                "public int nested(boolean flag) { return flag ? (flag ? 1 : 2) : 3; } }",
                encoding="utf-8"
            )
            report = Path(tmp) / "report.json"
            run = subprocess.run(
                [sys.executable, str(TRANSPILER), "--input", str(source.parent),
                 "--output", str(Path(tmp) / "lua"), "--report", str(report)],
                capture_output=True, text=True
            )
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            data = json.loads(report.read_text())
            self.assertEqual(data["translated_methods"], 0)
            self.assertEqual(len(data["skipped_methods"]), 2)
            for item in data["skipped_methods"]:
                self.assertIn("ternary conditional operator", item["reason"])

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
