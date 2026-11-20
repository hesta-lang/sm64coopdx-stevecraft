import json, subprocess, sys, tempfile, unittest, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FIXTURES=ROOT/"tools"/"minecraft_26_3_fixtures"
EXTRACTOR=ROOT/"tools"/"extract_minecraft_26_3.py"
class Minecraft263SourceExtractionTests(unittest.TestCase):
 def test_extracts_exact_entries_and_reports_engine_calls(self):
  with tempfile.TemporaryDirectory() as tmp:
   archive=Path(tmp)/"fixture.jar"; output=Path(tmp)/"out"; report=Path(tmp)/"report.json"
   with zipfile.ZipFile(archive,"w") as z:
    z.write(FIXTURES/"HumanoidModel.java","net/minecraft/client/model/HumanoidModel.java")
    z.write(FIXTURES/"PlayerModel.java","net/minecraft/client/model/player/PlayerModel.java")
   run=subprocess.run([sys.executable,str(EXTRACTOR),"--sources",str(archive),"--output",str(output),"--report",str(report)],capture_output=True,text=True)
   self.assertEqual(run.returncode,0,run.stdout+run.stderr)
   data=json.loads(report.read_text()); self.assertEqual(data["minecraft_version"],"26.3")
   self.assertFalse(data["full_source_committed"]); self.assertEqual(len(data["classes"]),2)
   self.assertTrue(any(x["name"]=="quadraticArmUpdate" for x in data["classes"][0]["selected_methods_extracted"]))
   self.assertTrue(any(x["name"]=="getRandomBodyPart" for x in data["classes"][1]["selected_methods_extracted"]))
   self.assertIn("Util.getRandom",data["classes"][1]["engine_api_calls"])
   self.assertIn("net.minecraft.util.Util",data["classes"][1]["imports"])
   player=(output/"net/minecraft/client/model/player/PlayerModel.java").read_text()
   self.assertIn("return Util.getRandom(this.bodyParts,random);",player)
if __name__=="__main__": unittest.main()
