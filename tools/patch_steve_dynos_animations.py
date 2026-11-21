#!/usr/bin/env python3
"""Append Bedrock-based animation records to a compatible SM64CoopDX DynOSBIN.

Geometry is preserved byte-for-byte. The source actor must use the standard
mario_geo 20-animated-part player rig. Animation clips are sampled from
Mojang bedrock-samples v1.26.60.5 and mapped onto that SM64 rig.
"""
from __future__ import annotations
import argparse, base64, hashlib, json, math, struct, zlib
from pathlib import Path

MAGIC = b"DYNOSBIN"
TYPE_ANIMATION = 8
TYPE_ANIMATION_TABLE = 9
PARTS = 20
INDEX_COUNT = (PARTS + 1) * 6
Y_DIVISOR = 189
# One 3-axis root translation group, followed by 20 AnimatedPart rotation groups.
# mario_geo part order: root, butt, torso, neck, L shoulder/arm/forearm/hand,
# R shoulder/arm/forearm/hand, L thigh/thigh mesh/lower leg/foot,
# R thigh/thigh mesh/lower leg/foot.
BONE_PART = {"root": 1, "waist": 2, "body": 3, "head": 4,
             "leftarm": 5, "rightarm": 9, "leftleg": 13, "rightleg": 17}
# MarioAnimID values from coop-deluxe/sm64coopdx/include/mario_animation_ids.h.
ANIM_MAP = {
    0x48: "walk", 0x72: "run", 0xBA: "walk", 0xC5: "idle",
    0x97: "start_crouch", 0x98: "crouch", 0x96: "stop_crouch",
    0x9B: "start_crawl", 0x99: "crawl", 0x9A: "stop_crawl",
    0xAA: "swim", 0xAB: "swim", 0xAC: "swim_legs", 0xAD: "swim",
    0xB2: "swim_idle", 0x47: "ride", 0x6D: "ride",
    0x65: "attack", 0x66: "attack", 0x67: "attack", 0x68: "attack_left",
    0x69: "attack_fast", 0x6A: "attack_fast_left",
    0x81: "sleep", 0x85: "sleep", 0x86: "sleep_lying", 0x87: "sleep_lying",
}


def s16(v): return ((int(v) + 32768) & 0xffff) - 32768

def deg_angle(deg): return s16(round(float(deg) * 65536.0 / 360.0))

def sin_deg(v): return math.sin(math.radians(v))

def cos_deg(v): return math.cos(math.radians(v))

def bedrock_to_sm64_rot(r):
    # Bedrock point basis (x,y,z)->SM64 (y,-x,-z); axial rotations use det(B)*B.
    x, y, z = r
    return (-y, x, z)

def lerp(a, b, t): return a + (b - a) * t

def keyframe(t, keys):
    if t <= keys[0][0]: return keys[0][1]
    if t >= keys[-1][0]: return keys[-1][1]
    for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
        if t0 <= t <= t1:
            q = (t - t0) / (t1 - t0)
            return tuple(lerp(v0[i], v1[i], q) for i in range(3))
    return keys[-1][1]

def empty(frames):
    return {b: [(0.0, 0.0, 0.0)] * frames for b in BONE_PART}

def clip(name, frames, loop, bones):
    for b, c in bones.items():
        if b not in BONE_PART or len(c) != frames:
            raise ValueError(f"Invalid animation channel {name}:{b}")
    return {"name": name, "frames": frames, "loop": loop, "bones": bones}

def walk_clip(name, frames):
    c = empty(frames)
    for f in range(frames):
        tcos = cos_deg(f * 360.0 / frames) * 57.3
        c["leftarm"][f] = (tcos, 0, 0)
        c["rightarm"][f] = (-tcos, 0, 0)
        c["leftleg"][f] = (-1.4 * tcos, -0.1, -0.1)
        c["rightleg"][f] = (1.4 * tcos, 0.1, 0.1)
    return clip(name, frames, True, c)

def idle_clip():
    # animation.humanoid.bob; life_time is sampled at 20 updates/second.
    frames = 70
    c = empty(frames)
    for f in range(frames):
        bob = cos_deg(f * 103.2 / 20.0) * 2.865 + 2.865
        c["leftarm"][f] = (0, 0, -bob)
        c["rightarm"][f] = (0, 0, bob)
    return clip("idle", frames, True, c)

def crouch_clip():
    # animation.player.sneaking, with per-bone positional offsets omitted because
    # the SM64 animation index can animate rotation but not each part's position.
    frames = 8
    c = empty(frames)
    for f in range(frames):
        c["root"][f] = (28.0, 0, 0)
        c["leftarm"][f] = (-5.7, 0, 0)
        c["rightarm"][f] = (-5.7, 0, 0)
        c["leftleg"][f] = (-28.0, -0.1, -0.1)
        c["rightleg"][f] = (-28.0, 0.1, 0.1)
    return clip("crouch", frames, True, c)

def transition(name, target, reverse=False):
    frames = 10
    c = empty(frames)
    for bone in c:
        pose = target["bones"].get(bone, [(0, 0, 0)])[0]
        for f in range(frames):
            t = f / (frames - 1)
            if reverse: t = 1 - t
            c[bone][f] = tuple(x * t for x in pose)
    return clip(name, frames, False, c)

SWIM_LEFT = [(0.0, (0, 180, 180)), (0.7, (0, 180, 287.2)),
             (1.1, (90, 180, 180)), (1.3, (0, 180, 180))]
SWIM_RIGHT = [(0.0, (0, 180, -180)), (0.7, (0, 180, -287.2)),
              (1.1, (90, 180, -180)), (1.3, (0, 180, -180))]

def swim_clip(name="swim", legs_only=False, idle=False):
    # animation.player.swim and animation.player.swim.legs; default target pitch 0.
    frames, duration = 26, 1.3
    c = empty(frames)
    for f in range(frames):
        t = f * duration / frames
        if not legs_only and not idle:
            c["leftarm"][f] = keyframe(t, SWIM_LEFT)
            c["rightarm"][f] = keyframe(t, SWIM_RIGHT)
        if not idle:
            phase = f * 390.0 / 20.0
            c["leftleg"][f] = (cos_deg(phase + 180) * 17.2, -0.1, -0.1)
            c["rightleg"][f] = (cos_deg(phase) * 17.2, 0.1, 0.1)
        c["root"][f] = (90.0, 0, 0)
    if idle:
        c = empty(frames)
        c["root"] = [(90.0, 0, 0)] * frames
    return clip(name, frames, True, c)

def crawl_clip():
    # animation.player.crawl reuses the swimming arms and root pose; crawl.legs
    # phase is based on modified_distance_moved rather than wall-clock time.
    frames, duration = 26, 1.3
    c = empty(frames)
    for f in range(frames):
        t = f * duration / frames
        phase = f * 30.0
        c["leftarm"][f] = keyframe(t, SWIM_LEFT)
        c["rightarm"][f] = keyframe(t, SWIM_RIGHT)
        c["leftleg"][f] = (cos_deg(phase + 180) * 17.2, -0.1, -0.1)
        c["rightleg"][f] = (cos_deg(phase) * 17.2, 0.1, 0.1)
        c["root"][f] = (90.0, 0, 0)
    return clip("crawl", frames, True, c)

def attack_clip(name, left=False):
    # animation.player.attack.rotations. The body yaw variable in player.entity
    # uses JavaScript Math.sin (radians), while animation JSON math.sin is degrees.
    frames = 21
    c = empty(frames)
    for f in range(frames):
        t = f / (frames - 1)
        attack_phase = sin_deg((1 - (1 - t) ** 4) * 180)
        arm_curve = attack_phase * 1.2 + sin_deg(t * 180)
        body_yaw = math.sin(360.0 * math.sqrt(t)) * 5.0
        lp, rp = -arm_curve * 10.0, -arm_curve * 30.0
        ry = (-90.0 * attack_phase + 30.0) if abs(attack_phase) > 1e-8 else 0.0
        if left:
            lp, rp = rp, lp
            c["leftarm"][f] = (lp, ry, 0)
            c["rightarm"][f] = (rp, 0, 0)
        else:
            c["leftarm"][f] = (lp, 0, 0)
            c["rightarm"][f] = (rp, ry, 0)
        c["body"][f] = (0, body_yaw, 0)
    return clip(name, frames, False, c)

def ride_clip():
    # animation.humanoid.riding.arms and .legs.
    frames = 8
    c = empty(frames)
    for f in range(frames):
        c["leftarm"][f] = (-36, 0, 0)
        c["rightarm"][f] = (-36, 0, 0)
        c["leftleg"][f] = (-81, -18, 0)
        c["rightleg"][f] = (-81, 18, 0)
    return clip("ride", frames, True, c)

def sleep_clip(name):
    # animation.player.sleeping at the default bed/body orientation. Its dynamic
    # bed-alignment offset depends on body_y_rotation/sleep_rotation and is omitted.
    frames = 8
    c = empty(frames)
    for f in range(frames):
        c["root"][f] = (-90, 270, 0)
        c["head"][f] = (30, 0, 0)
    return clip(name, frames, True, c)

def build_clips():
    crouch = crouch_clip()
    crawl = crawl_clip()
    return {
        "walk": walk_clip("walk", 32), "run": walk_clip("run", 24),
        "idle": idle_clip(), "crouch": crouch,
        "start_crouch": transition("start_crouch", crouch),
        "stop_crouch": transition("stop_crouch", crouch, True),
        "crawl": crawl, "start_crawl": transition("start_crawl", crawl),
        "stop_crawl": transition("stop_crawl", crawl, True),
        "swim": swim_clip("swim"), "swim_legs": swim_clip("swim_legs", legs_only=True),
        "swim_idle": swim_clip("swim_idle", idle=True), "ride": ride_clip(),
        "attack": attack_clip("attack"), "attack_left": attack_clip("attack_left", True),
        "attack_fast": attack_clip("attack_fast"),
        "attack_fast_left": attack_clip("attack_fast_left", True),
        "sleep": sleep_clip("sleep"), "sleep_lying": sleep_clip("sleep_lying"),
    }

def enc_string(s):
    b = s.encode("utf-8")
    if len(b) > 255: raise ValueError("DynOS string too long")
    return bytes([len(b)]) + b

def encode_animation(anim_id, clip_data):
    frames = clip_data["frames"]
    if not 1 <= frames <= 32767: raise ValueError("Invalid frame count")
    values, indices = [], []
    # Group 0 is root translation XYZ. Bedrock root translation is kept at zero
    # so the render model does not drift away from Mario's collision/physics body.
    groups = [([0] * frames, [0] * frames, [0] * frames)]
    rotations = [[(0, 0, 0)] * frames for _ in range(PARTS)]
    for bone, curve in clip_data["bones"].items():
        part = BONE_PART[bone] - 1
        rotations[part] = [tuple(deg_angle(v) for v in bedrock_to_sm64_rot(e)) for e in curve]
    for part_curve in rotations:
        groups.append(tuple([part_curve[f][axis] for f in range(frames)] for axis in range(3)))
    for group in groups:
        if len(group) != 3: raise AssertionError("Bad animation group")
        for channel in group:
            compact = list(channel)
            if all(v == compact[0] for v in compact): compact = compact[:1]
            offset = len(values)
            if len(compact) > 0xffff or offset > 0xffff: raise ValueError("u16 animation limit exceeded")
            indices.extend((len(compact), offset))
            values.extend(s16(v) for v in compact)
    if len(indices) != INDEX_COUNT: raise AssertionError(f"Expected {INDEX_COUNT} index values")
    flags = 0 if clip_data["loop"] else 1  # ANIM_FLAG_NOLOOP
    record = bytearray([TYPE_ANIMATION])
    record += enc_string(f"anim_{anim_id:02X}")
    record += struct.pack("<6hI", flags, Y_DIVISOR, 0, 0, frames, PARTS, 0)
    record += struct.pack("<I", len(values)) + struct.pack(f"<{len(values)}h", *values)
    record += struct.pack("<I", len(indices)) + struct.pack(f"<{len(indices)}H", *indices)
    return bytes(record)

def encode_table(mapping):
    out = bytearray()
    for anim_id in range(256):
        out.append(TYPE_ANIMATION_TABLE)
        out += enc_string(mapping.get(anim_id, "NULL"))
    return bytes(out)

def unpack_dynosbin(data):
    if len(data) < 16 or data[:8] != MAGIC: raise ValueError("Not a DynOSBIN actor")
    size = struct.unpack_from("<Q", data, 8)[0]
    payload = zlib.decompress(data[16:])
    if len(payload) != size: raise ValueError("DynOSBIN uncompressed size mismatch")
    return payload

def pack_dynosbin(payload):
    return MAGIC + struct.pack("<Q", len(payload)) + zlib.compress(payload, 9)

def patch_actor(input_bytes):
    original = unpack_dynosbin(input_bytes)
    if b"mario_geo" not in original: raise ValueError("The actor must contain a mario_geo GeoLayout")
    if b"anim_" in original: raise ValueError("The source already contains animation records")
    clips = build_clips()
    result_payload = bytearray(original)
    for anim_id, name in sorted(ANIM_MAP.items()):
        if name not in clips: raise ValueError(f"Missing clip {name}")
        result_payload += encode_animation(anim_id, clips[name])
    result_payload += encode_table({i: f"anim_{i:02X}" for i in ANIM_MAP})
    output = pack_dynosbin(bytes(result_payload))
    decoded = unpack_dynosbin(output)
    if decoded[:len(original)] != original: raise AssertionError("Source geometry changed")
    manifest = {
        "source_sha256": hashlib.sha256(input_bytes).hexdigest(),
        "source_payload_sha256": hashlib.sha256(original).hexdigest(),
        "output_sha256": hashlib.sha256(output).hexdigest(),
        "source_bytes": len(input_bytes), "output_bytes": len(output),
        "payload_bytes_before": len(original), "payload_bytes_after": len(decoded),
        "animation_record_count": len(ANIM_MAP), "animation_table_entries": 256,
        "animation_ids": {f"0x{i:02X}": n for i, n in sorted(ANIM_MAP.items())},
        "animation_parts": PARTS, "index_entries_per_animation": INDEX_COUNT,
        "bedrock_source_revision": "Mojang/bedrock-samples 15701fa9c13923f12662984c32c124327e40e3d3 (v1.26.60.5)",
        "bedrock_animations_sampled": [
            "animation.player.move.arms", "animation.player.move.legs", "animation.humanoid.bob",
            "animation.player.sneaking", "animation.player.swim", "animation.player.swim.legs",
            "animation.player.crawl", "animation.player.attack.rotations", "animation.player.sleeping",
            "animation.humanoid.riding.arms", "animation.humanoid.riding.legs",
        ],
        "limitations": [
            "Only core third-person body poses are mapped; item/equipment animation controllers are not reproduced.",
            "Bedrock overlay bones (hat, jacket, sleeves, pants, cape and held items) share their parent joint; the SM64 player rig has 20 animated parts.",
            "The root translation channel is left at zero to keep the rendered model aligned with Mario's collision/physics object.",
            "Bedrock query-driven states are sampled into fixed clips; live target-look, item-use and distance-dependent blending are not identical to Bedrock runtime controllers.",
            "The uploaded actor's geometry, display lists, GeoLayouts and textures are preserved byte-for-byte in the decompressed payload.",
        ],
    }
    return output, manifest

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument("--input", type=Path)
    group.add_argument("--input-base64", type=Path)
    ap.add_argument("--output", required=True, type=Path)
    ap.add_argument("--manifest", type=Path)
    args = ap.parse_args()
    if args.input:
        src = args.input.read_bytes()
    else:
        src = base64.b64decode("".join(args.input_base64.read_text(encoding="ascii").split()), validate=True)
    out, manifest = patch_actor(src)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(out)
    manifest_path = args.manifest or args.output.with_suffix(".json")
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "bytes": len(out), "animations": len(ANIM_MAP),
                      "table_entries": 256, "sha256": manifest["output_sha256"]}, indent=2))

if __name__ == "__main__": main()
