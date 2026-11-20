import subprocess, sys, tempfile, unittest, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tools" / "minecraft_26_3_fixtures"
EXTRACTOR = ROOT / "tools" / "extract_minecraft_26_3.py"
GENERATOR = ROOT / "tools" / "minecraft_26_3_model_reference.py"

class Minecraft263ModelReferenceTests(unittest.TestCase):
    def test_compiles_and_runs_source_extracted_model_methods(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            archive = root / "fixture-sources.zip"
            extracted = root / "extracted"
            report = root / "source-report.json"
            generated = root / "Minecraft263ModelReferenceRunner.java"
            with zipfile.ZipFile(archive, "w") as z:
                z.write(FIXTURES / "HumanoidModel.java",
                        "net/minecraft/client/model/HumanoidModel.java")
                z.write(FIXTURES / "PlayerModel.java",
                        "net/minecraft/client/model/player/PlayerModel.java")
                z.write(FIXTURES / "Mth.java", "net/minecraft/util/Mth.java")
            run = subprocess.run(
                [sys.executable, str(EXTRACTOR), "--sources", str(archive),
                 "--output", str(extracted), "--report", str(report)],
                capture_output=True, text=True
            )
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            build = subprocess.run(
                [sys.executable, str(GENERATOR), "--input", str(extracted),
                 "--output", str(generated)],
                capture_output=True, text=True
            )
            self.assertEqual(build.returncode, 0, build.stdout + build.stderr)
            source = generated.read_text(encoding="utf-8")
            self.assertIn("return this.head;", source)
            self.assertIn("HumanoidArm.LEFT", source)
            self.assertIn("Util.getRandom(this.bodyParts,random)", source)
            classes = root / "classes"
            classes.mkdir()
            compiled = subprocess.run(
                ["javac", "-d", str(classes), str(generated)],
                capture_output=True, text=True
            )
            self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
            executed = subprocess.run(
                ["java", "-cp", str(classes), "Minecraft263ModelReferenceRunner"],
                capture_output=True, text=True
            )
            self.assertEqual(executed.returncode, 0, executed.stdout + executed.stderr)
            values = dict(line.split("=", 1) for line in executed.stdout.splitlines())
            self.assertEqual(values["model.head"], "head")
            self.assertEqual(values["model.arm.left"], "leftArm")
            self.assertEqual(values["model.arm.right"], "rightArm")
            self.assertEqual(values["model.random.0"], "head")
            self.assertEqual(values["model.random.1"], "rightArm")
            self.assertEqual(values["model.random.2"], "rightLeg")
            self.assertAlmostEqual(float(values["model.quadratic.2"]), -19.41, places=4)

if __name__ == "__main__":
    unittest.main()
