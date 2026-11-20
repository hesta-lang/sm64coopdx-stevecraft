import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRANSPILER = ROOT / "tools" / "java_to_lua.py"
FIXTURES = ROOT / "tools" / "mc_sources_fixture"

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
