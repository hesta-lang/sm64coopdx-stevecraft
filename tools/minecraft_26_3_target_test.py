import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"tools"/"minecraft_26_3_targets.json"
COMPAT=ROOT/"mc_compat.lua"
class Minecraft263InventoryTests(unittest.TestCase):
 def test_source_pipeline_and_partial_coverage_are_recorded(self):
  data=json.loads(MANIFEST.read_text(encoding="utf-8"));self.assertEqual(data["minecraft_version"],"26.3")
  pipeline=data["source_pipeline"];self.assertEqual(pipeline["neoform_coordinate"],"net.neoforged:neoform:26.3-1@zip")
  self.assertEqual(pipeline["distribution"],"joined");self.assertEqual(pipeline["result"],"gameSources")
  self.assertEqual(pipeline["artifact_manifest"],"build/nfrt-artifact-manifest.properties")
  self.assertEqual(pipeline["tool_artifact_override"]["coordinate"],"net.neoforged.installertools:installertools:4.0.17:fatjar")
  self.assertIn("exact 4.0.17",pipeline["tool_artifact_override"]["method"]);self.assertFalse(pipeline["full_source_committed"])
  targets={x["class"]:x for x in data["targets"]}
  self.assertEqual(set(targets),{"net.minecraft.util.Mth","net.minecraft.client.model.HumanoidModel","net.minecraft.client.model.player.PlayerModel"})
  humanoid=targets["net.minecraft.client.model.HumanoidModel"];player=targets["net.minecraft.client.model.player.PlayerModel"];mth=targets["net.minecraft.util.Mth"]
  self.assertEqual(humanoid["status"],"partial_transpilation_verified_source");self.assertEqual(player["status"],"partial_transpilation_verified_source")
  self.assertEqual(mth["status"],"partial_source_transpilation_and_manual_adapters")
  self.assertIn("net.minecraft.client.model.HumanoidModel",player["extends"])
  self.assertIn("getHead",humanoid["transpiled_methods"]);self.assertIn("getArm",humanoid["transpiled_methods"]);self.assertIn("quadraticArmUpdate",humanoid["transpiled_methods"])
  self.assertEqual(player["transpiled_methods"],["getRandomBodyPart"]);self.assertEqual(humanoid["coverage"]["public_api_methods_translated"],2)
  self.assertEqual(mth["coverage"]["public_api_methods_translated"],12);self.assertEqual(mth["coverage"]["public_api_methods_total"],114);self.assertEqual(len(mth["transpiled_methods"]),12)
  self.assertEqual(data["coverage"]["public_api_methods_translated"],15);self.assertEqual(data["coverage"]["public_api_methods_total"],132)
  self.assertAlmostEqual(data["coverage"]["public_api_coverage_percent"],11.4,places=1);self.assertFalse(data["runtime_validation"]["stevecraft_runtime_validated"])
 def test_mth_helpers_match_compatibility_functions(self):
  data=json.loads(MANIFEST.read_text(encoding="utf-8"));compat=COMPAT.read_text(encoding="utf-8")
  mth=next(x for x in data["targets"] if x["class"]=="net.minecraft.util.Mth")
  self.assertNotIn("fastFloor",mth["ported_methods"]);self.assertEqual(mth["source_inventory"]["source_entry"],"net/minecraft/util/Mth.java")
  self.assertEqual(mth["source_inventory"]["verified_methods"],mth["ported_methods"]);self.assertEqual(mth["source_inventory"]["transpiled_signatures"],mth["transpiled_methods"])
  for method in mth["ported_methods"]:
   with self.subTest(method=method):self.assertIn(f"function MC.Mth.{method}(",compat)
  self.assertIn("function MC.Util.getRandom(",compat);self.assertIn("SIN_SCALE=10430.378350470453",compat);self.assertIn("MC.java_float = float32",compat)
if __name__=="__main__":unittest.main()
