import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tools" / "minecraft_26_3_targets.json"
COMPAT = ROOT / "mc_compat.lua"

class Minecraft263InventoryTests(unittest.TestCase):
    def test_real_target_classes_are_recorded_without_false_transpilation_claims(self):
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(data["minecraft_version"], "26.3")
        targets = {entry["class"]: entry for entry in data["targets"]}
        self.assertEqual(set(targets), {
            "net.minecraft.util.Mth",
            "net.minecraft.client.model.HumanoidModel",
            "net.minecraft.client.model.player.PlayerModel",
        })
        self.assertEqual(targets["net.minecraft.util.Mth"]["status"], "partial_manual_port")
        self.assertEqual(targets["net.minecraft.client.model.HumanoidModel"]["status"], "inventoried_not_transpiled")
        self.assertEqual(targets["net.minecraft.client.model.player.PlayerModel"]["status"], "inventoried_not_transpiled")
        self.assertIn("net.minecraft.client.model.HumanoidModel", targets["net.minecraft.client.model.player.PlayerModel"]["extends"])

    def test_every_listed_mth_port_exists_in_compat_module(self):
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        compat = COMPAT.read_text(encoding="utf-8")
        mth = next(x for x in data["targets"] if x["class"] == "net.minecraft.util.Mth")
        for method in mth["ported_methods"]:
            with self.subTest(method=method):
                self.assertIn(f"function MC.Mth.{method}(", compat)

if __name__ == "__main__":
    unittest.main()
