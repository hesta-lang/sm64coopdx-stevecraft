#!/usr/bin/env python3
"""Crop the exact per-cube UV rectangles used by Minecraft Java PlayerModel 1.21.11."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from PIL import Image

# name: (u, v, width, height, depth, is_outer_layer)
# Bounds are derived from ModelPart.Cube's six-face UV layout:
# width = 2 * cube_width + 2 * cube_depth
# height = cube_height + cube_depth
CUBES = {
    "head_base": (0, 0, 8, 8, 8, False),
    "head_hat": (32, 0, 8, 8, 8, True),
    "torso_base": (16, 16, 8, 12, 4, False),
    "torso_jacket": (16, 32, 8, 12, 4, True),
    "right_arm_base": (40, 16, 4, 12, 4, False),
    "right_arm_sleeve": (40, 32, 4, 12, 4, True),
    "left_arm_base": (32, 48, 4, 12, 4, False),
    "left_arm_sleeve": (48, 48, 4, 12, 4, True),
    "right_leg_base": (0, 16, 4, 12, 4, False),
    "right_leg_pants": (0, 32, 4, 12, 4, True),
    "left_leg_base": (16, 48, 4, 12, 4, False),
    "left_leg_pants": (0, 48, 4, 12, 4, True),
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skin", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    skin = Image.open(args.skin).convert("RGBA")
    if skin.size != (64, 64):
        raise SystemExit(f"Expected Minecraft Java 64x64 skin, got {skin.size}")

    args.output.mkdir(parents=True, exist_ok=True)
    report = {"source": str(args.skin), "skin_size": list(skin.size), "cubes": {}}

    for name, (u, v, width, height, depth, outer) in CUBES.items():
        crop_width = 2 * width + 2 * depth
        crop_height = height + depth
        bounds = (u, v, u + crop_width, v + crop_height)
        if bounds[2] > 64 or bounds[3] > 64:
            raise SystemExit(f"UV rectangle for {name} exceeds the 64x64 skin: {bounds}")

        crop = skin.crop(bounds)
        if crop.size != (crop_width, crop_height):
            raise SystemExit(f"Incorrect crop size for {name}: {crop.size}")
        alpha_bounds = crop.getchannel("A").getbbox()
        # Empty outer-layer regions are valid in Minecraft skins: a fully
        # transparent hat/sleeve/jacket/pants cube is intentionally invisible.
        # Base body UVs must still contain pixels.
        if alpha_bounds is None and not outer:
            raise SystemExit(f"Base skin UV region for {name} is fully transparent")

        output = args.output / f"{name}.png"
        crop.save(output, optimize=False)
        report["cubes"][name] = {
            "uv": [u, v],
            "dimensions": [width, height, depth],
            "crop": list(bounds),
            "image": output.name,
            "size": list(crop.size),
            "outer_layer": outer,
            "fully_transparent": alpha_bounds is None,
        }

    (args.output / "manifest.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
