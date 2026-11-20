import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tools" / "minecraft_26_3_physics_camera.json"

class Minecraft263PhysicsCameraPortTests(unittest.TestCase):
    def test_source_classes_and_modules_are_recorded(self):
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(data["minecraft_version"], "26.3")
        ports = {item["class"]: item for item in data["ports"]}
        self.assertEqual(set(ports), {
            "net.minecraft.client.player.LocalPlayer",
            "net.minecraft.world.entity.LivingEntity",
            "net.minecraft.world.entity.Entity",
            "net.minecraft.client.Camera",
        })
        self.assertEqual(ports["net.minecraft.client.player.LocalPlayer"]["lua_module"], "minecraft_26_3_physics.lua")
        self.assertEqual(ports["net.minecraft.world.entity.LivingEntity"]["status"], "normal_ground_air_jump_behavior_ported")
        self.assertEqual(ports["net.minecraft.client.Camera"]["status"], "camera_math_ported_engine_adapter_partial")

    def test_manifest_does_not_claim_full_vanilla_or_android_parity(self):
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        joined = json.dumps(data).lower()
        self.assertIn("not yet tested inside sm64coopdx android", joined)
        self.assertIn("voxel/aabb", joined)
        self.assertIn("read-only", joined)

if __name__ == "__main__":
    unittest.main()
