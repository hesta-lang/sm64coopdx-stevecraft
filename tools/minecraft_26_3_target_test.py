import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/"tools"/"minecraft_26_3_targets.json"
COMPAT=ROOT/"mc_compat.lua"
class Minecraft263InventoryTests(unittest.TestCase):
 def test_source_pipeline_and_partial_coverage_are_recorded(self):
  data=json.loads(MANIFEST.read_text(encoding="utf-8"))
  self.assertEqual(data["minecraft_version"],"26.3")
  pipeline=data["source_pipeline"]
  self.assertEqual(pipeline["neoform_coordinate"],"net.neoforged:neoform:26.3-1@zip")
  self.assertEqual(pipeline["distribution"],"client")
  self.assertEqual(pipeline["result"],"gameSources")
  self.assertFalse(pipeline["full_source_committed"])
  targets={x["class"]:x for x in data["targets"]}
  self.assertEqual(set(targets),{"net.minecraft.util.Mth","net.minecraft.client.model.HumanoidModel","net.minecraft.client.model.player.PlayerModel"})
  humanoid=targets["net.minecraft.client.model.HumanoidModel"]; player=targets["net.minecraft.client.model.player.PlayerModel"]
  self.assertEqual(humanoid["status"],"partial_transpilation_verified_source")
  self.assertEqual(player["status"],"partial_transpilation_verified_source")
  self.assertIn("net.minecraft.client.model.HumanoidModel",player["extends"])
  self.assertIn("getHead",humanoid["transpiled_methods"]); self.assertIn("quadraticArmUpdate",humanoid["transpiled_methods"])
  self.assertEqual(player["transpiled_methods"],["getRandomBodyPart"])
  self.assertEqual(data["coverage"]["public_api_methods_translated"],2)
  self.assertEqual(data["coverage"]["public_api_methods_total"],18)
  self.assertAlmostEqual(data["coverage"]["public_api_coverage_percent"],11.1,places=1)
  self.assertFalse(data["runtime_validation"]["stevecraft_runtime_validated"])
 def test_mth_helpers_match_compatibility_functions(self):
  data=json.loads(MANIFEST.read_text(encoding="utf-8")); compat=COMPAT.read_text(encoding="utf-8")
  mth=next(x for x in data["targets"] if x["class"]=="net.minecraft.util.Mth")
  self.assertNotIn("fastFloor",mth["ported_methods"])
  for method in mth["ported_methods"]:
   with self.subTest(method=method): self.assertIn(f"function MC.Mth.{method}(",compat)
  self.assertIn("function MC.Util.getRandom(",compat)
  self.assertIn("SIN_SCALE=10430.378350470453",compat)
if __name__=="__main__": unittest.main()
