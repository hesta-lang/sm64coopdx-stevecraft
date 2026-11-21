import importlib.util
import struct
import sys
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).with_name("patch_steve_dynos_animations.py")
spec = importlib.util.spec_from_file_location("patch_steve_dynos_animations", MODULE_PATH)
patcher = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = patcher
spec.loader.exec_module(patcher)


def read_string(data, pos):
    n = data[pos]
    pos += 1
    return data[pos:pos + n].decode("utf-8"), pos + n


def parse_suffix(data, offset):
    animations, table = {}, []
    while offset < len(data):
        kind = data[offset]
        offset += 1
        if kind == patcher.TYPE_ANIMATION:
            name, offset = read_string(data, offset)
            header = struct.unpack_from("<6hI", data, offset)
            offset += 16
            value_count = struct.unpack_from("<I", data, offset)[0]
            offset += 4
            values = struct.unpack_from(f"<{value_count}h", data, offset)
            offset += value_count * 2
            index_count = struct.unpack_from("<I", data, offset)[0]
            offset += 4
            indices = struct.unpack_from(f"<{index_count}H", data, offset)
            offset += index_count * 2
            animations[name] = (header, values, indices)
        elif kind == patcher.TYPE_ANIMATION_TABLE:
            name, offset = read_string(data, offset)
            table.append(name)
        else:
            raise AssertionError(f"Unknown DynOS record type {kind} at {offset - 1}")
    return animations, table


class BinaryPatchTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source_payload = b"\x05\x09mario_geo\x00\x00\x00\x00"
        source = patcher.pack_dynosbin(cls.source_payload)
        cls.output, cls.manifest = patcher.patch_actor(source)
        cls.decoded = patcher.unpack_dynosbin(cls.output)
        cls.animations, cls.table = parse_suffix(cls.decoded, len(cls.source_payload))

    def test_original_payload_is_preserved(self):
        self.assertEqual(self.decoded[:len(self.source_payload)], self.source_payload)
        self.assertIn(b"mario_geo", self.decoded)

    def test_table_has_256_entries_and_expected_mappings(self):
        self.assertEqual(len(self.table), 256)
        for anim_id in (0x48, 0x72, 0x98, 0xAA, 0xC5):
            self.assertEqual(self.table[anim_id], f"anim_{anim_id:02X}")
        self.assertEqual(self.table[0x49], "NULL")

    def test_all_clips_have_20_part_indices(self):
        self.assertEqual(len(self.animations), len(patcher.ANIM_MAP))
        for name, (header, values, indices) in self.animations.items():
            flags, divisor, start, loop_start, loop_end, parts, length = header
            self.assertEqual(parts, 20, name)
            self.assertEqual(len(indices), 126, name)
            self.assertGreater(loop_end, 0, name)
            self.assertEqual(length, 0, name)
            for count, offset in zip(indices[0::2], indices[1::2]):
                self.assertGreaterEqual(count, 1, name)
                self.assertLessEqual(offset + count, len(values), name)

    def test_bedrock_axis_conversion_and_walk_phase(self):
        self.assertEqual(patcher.bedrock_to_sm64_rot((10, 20, 30)), (-20, 10, 30))
        _, values, indices = self.animations["anim_48"]

        def first_value(part, axis):
            pair = (part * 3 + axis) * 2
            return values[indices[pair + 1]]

        self.assertNotEqual(first_value(5, 1), 0)
        self.assertEqual(first_value(9, 1), -first_value(5, 1))

    def test_dynosbin_header_size_matches_payload(self):
        self.assertEqual(self.output[:8], b"DYNOSBIN")
        self.assertEqual(struct.unpack_from("<Q", self.output, 8)[0], len(self.decoded))
        self.assertEqual(self.manifest["animation_record_count"], len(self.animations))


if __name__ == "__main__":
    unittest.main(verbosity=2)
