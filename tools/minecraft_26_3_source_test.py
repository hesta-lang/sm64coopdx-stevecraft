import json, subprocess, sys, tempfile, unittest, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FIXTURES=ROOT/"tools"/"minecraft_26_3_fixtures"
EXTRACTOR=ROOT/"tools"/"extract_minecraft_26_3.py"
TRANSPILER=ROOT/"tools"/"java_to_lua.py"
class Minecraft263SourceExtractionTests(unittest.TestCase):
 def test_extracts_exact_entries_and_reports_engine_calls(self):
  with tempfile.TemporaryDirectory() as tmp:
   archive=Path(tmp)/"fixture.jar"; output=Path(tmp)/"out"; report=Path(tmp)/"report.json"
   with zipfile.ZipFile(archive,"w") as z:
    z.write(FIXTURES/"HumanoidModel.java","net/minecraft/client/model/HumanoidModel.java")
    z.write(FIXTURES/"PlayerModel.java","net/minecraft/client/model/player/PlayerModel.java")
    z.write(FIXTURES/"Mth.java","net/minecraft/util/Mth.java")
   run=subprocess.run([sys.executable,str(EXTRACTOR),"--sources",str(archive),"--output",str(output),"--report",str(report)],capture_output=True,text=True)
   self.assertEqual(run.returncode,0,run.stdout+run.stderr)
   data=json.loads(report.read_text()); self.assertEqual(data["minecraft_version"],"26.3")
   self.assertFalse(data["full_source_committed"]); self.assertEqual(len(data["classes"]),3)
   self.assertTrue(any(x["name"]=="quadraticArmUpdate" for x in data["classes"][0]["selected_methods_extracted"]))
   self.assertTrue(any(x["name"]=="getRandomBodyPart" for x in data["classes"][1]["selected_methods_extracted"]))
   self.assertIn("Util.getRandom",data["classes"][1]["engine_api_calls"])
   self.assertIn("net.minecraft.util.Util",data["classes"][1]["imports"])
   self.assertIn("net.minecraft.world.entity.HumanoidArm",data["classes"][0]["imports"])
   self.assertEqual(data["classes"][0]["extends"],"EntityModel<T>")
   self.assertEqual(data["classes"][1]["extends"],"HumanoidModel<AvatarRenderState>")
   player=(output/"net/minecraft/client/model/player/PlayerModel.java").read_text()
   self.assertIn("return Util.getRandom(this.bodyParts,random);",player)
   humanoid=(output/"net/minecraft/client/model/HumanoidModel.java").read_text()
   self.assertIn("import net.minecraft.world.entity.HumanoidArm;",humanoid)
   mth=data["classes"][2]; self.assertEqual(mth["class"],"net.minecraft.util.Mth"); self.assertEqual(mth["api_surface_count"],114)
   expected={"clamp":["double","double","double"],"clampedLerp":["double","double","double"],"absMax":["double","double"],"equal":["double","double"],"sign":["double"],"lerp":["double","double","double"],"square":["double"],"inverseLerp":["double","double","double"],"clampedMap":["double","double","double","double","double"],"map":["double","double","double","double","double"],"lengthSquared":["double","double","double"],"length":["double","double","double"]}
   selected={item["name"]:item for item in mth["selected_methods_extracted"]}
   self.assertEqual(set(selected),set(expected))
   for name,params in expected.items():
    with self.subTest(method=name): self.assertEqual(selected[name]["parameter_types"],params)
   self.assertTrue(set(["PI","HALF_PI","TWO_PI","DEG_TO_RAD","RAD_TO_DEG","SIN_QUANTIZATION","SIN_MASK","COS_OFFSET","SIN_SCALE","SIN"]).issubset(mth["fields_present_in_source"]))
   lua_out=Path(tmp)/"lua"; transpile_report=Path(tmp)/"transpile-report.json"
   translated=subprocess.run([sys.executable,str(TRANSPILER),"--input",str(output),"--output",str(lua_out),"--version","26.3-fixture","--class","net.minecraft.util.Mth","--report",str(transpile_report)],capture_output=True,text=True)
   self.assertEqual(translated.returncode,0,translated.stdout+translated.stderr)
   result=json.loads(transpile_report.read_text()); self.assertEqual(result["translated_methods"],12,result)
   self.assertEqual(result["strict_blockers"],0,result); self.assertFalse(result["skipped_methods"],result); self.assertFalse(result["skipped_files"],result)
   generated=(lua_out/"net/minecraft/util/Mth.lua").read_text()
   for call in ["Mth.lerp(","Mth.inverseLerp(","Mth.clampedLerp(","Mth.lengthSquared("]: self.assertIn(call,generated)
   self.assertIn("MC.java_float(1.0E-5)",generated)
   java_out=Path(tmp)/"java-source"; java_out.mkdir()
   compiled=subprocess.run(["javac","-d",str(java_out),str(output/"net/minecraft/util/Mth.java"),str(ROOT/"tools"/"Minecraft263RealSourceRunner.java")],capture_output=True,text=True)
   self.assertEqual(compiled.returncode,0,compiled.stdout+compiled.stderr)
   executed=subprocess.run(["java","-cp",str(java_out),"Minecraft263RealSourceRunner"],capture_output=True,text=True)
   self.assertEqual(executed.returncode,0,executed.stdout+executed.stderr)
   reference=dict(line.split("=",1) for line in executed.stdout.splitlines())
   self.assertEqual(reference["clamp.inverted"],"6.0")
   self.assertEqual(reference["clampedLerp.middle"],"5.0")
   self.assertEqual(reference["length3"],"7.0")
if __name__=="__main__": unittest.main()
