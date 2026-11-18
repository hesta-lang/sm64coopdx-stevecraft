#!/usr/bin/env python3
"""Generate the classic Minecraft Steve first-person arm for DynOS."""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image

# Classic wide/Steve Java skin right-arm UV layout, using zero-based pixels.
FACE_UV = {
    "top": (44, 16, 48, 20),
    "bottom": (48, 16, 52, 20),
    "right": (40, 20, 44, 32),
    "front": (44, 20, 48, 32),
    "left": (48, 20, 52, 32),
    "back": (52, 20, 56, 32),
}

# One 4x12x4 cuboid. Local X runs from the wrist (0) to the shoulder (12).
FACES = {
    "top": [(12,-2,-2),(12,2,-2),(12,2,2),(12,-2,2)],
    "bottom": [(0,-2,2),(0,2,2),(0,2,-2),(0,-2,-2)],
    "right": [(12,-2,-2),(12,-2,2),(0,-2,2),(0,-2,-2)],
    "front": [(12,-2,2),(12,2,2),(0,2,2),(0,-2,2)],
    "left": [(12,2,2),(12,2,-2),(0,2,-2),(0,2,2)],
    "back": [(12,2,-2),(12,-2,-2),(0,-2,-2),(0,2,-2)],
}

def write_actor(output: Path) -> None:
    tex_defs = []
    for face in FACES:
        tex_defs.append(
            'Texture steve_arm_' + face + '[] = { "actors/steve_hand/arm_' + face + '.png" };'
        )

    vertices = []
    for face, positions in FACES.items():
        h = 4 if face in ("top", "bottom") else 12
        uv = [(0,0),(96,0),(96,(h-1)*32),(0,(h-1)*32)]
        for (x,y,z),(s,t) in zip(positions,uv):
            vertices.append(
                f"    {{{{{x}, {y}, {z}}}, 0, {{{s}, {t}}}, {{255, 255, 255, 255}}}},"
            )

    gfx = [
        "const Gfx steve_hand_dl[] = {",
        "    gsDPPipeSync(),",
        "    gsSPClearGeometryMode(G_LIGHTING | G_CULL_BACK),",
        "    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),",
        "    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),",
        "    gsSPVertex(steve_hand_vertices, 24, 0),",
    ]
    for index, face in enumerate(FACES):
        h = 4 if face in ("top", "bottom") else 12
        gfx += [
            "    gsDPPipeSync(),",
            f"    gsDPLoadTextureBlock(steve_arm_{face}, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, {h}, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),",
            f"    gsSP2Triangles({index*4}, {index*4+1}, {index*4+2}, 0, {index*4}, {index*4+2}, {index*4+3}, 0),",
        ]
    gfx += [
        "    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),",
        "    gsDPPipeSync(),",
        "    gsSPEndDisplayList(),",
        "};",
    ]

    model = [
        "// Classic Minecraft Steve right arm viewmodel.",
        "// 4x12x4 geometry; six face textures use original classic-skin UV regions.",
        *tex_defs,
        "",
        "const Vtx steve_hand_vertices[] = {",
        *vertices,
        "};",
        "",
        *gfx,
        "",
    ]
    (output / "model.inc.c").write_text("\n".join(model), encoding="utf-8")
    (output / "geo.inc.c").write_text(
        "const GeoLayout steve_hand_geo[] = {\n"
        "    GEO_NODE_START(),\n"
        "    GEO_OPEN_NODE(),\n"
        "        GEO_CULLING_RADIUS(2000),\n"
        "        GEO_OPEN_NODE(),\n"
        "            GEO_SCALE(LAYER_FORCE, 196608),\n"
        "            GEO_OPEN_NODE(),\n"
        "                GEO_DISPLAY_LIST(LAYER_OPAQUE, steve_hand_dl),\n"
        "            GEO_CLOSE_NODE(),\n"
        "        GEO_CLOSE_NODE(),\n"
        "    GEO_CLOSE_NODE(),\n"
        "    GEO_END(),\n"
        "};\n",
        encoding="utf-8",
    )
    (output / "geo_header.h").write_text(
        "extern const GeoLayout steve_hand_geo[];\n", encoding="utf-8"
    )
    (output / "README.md").write_text(
        "# SteveCraft first-person arm\n\n"
        "Classic Minecraft Steve right arm: 4x12x4 model proportions, with all six "
        "faces extracted from the 64x64 classic Steve skin UV layout.\n",
        encoding="utf-8",
    )

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--skin", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    a = p.parse_args()
    skin = Image.open(a.skin).convert("RGBA")
    if skin.size != (64, 64):
        raise SystemExit(f"Expected a 64x64 Steve skin, got {skin.size}")
    a.output.mkdir(parents=True, exist_ok=True)

    for face, box in FACE_UV.items():
        crop = skin.crop(box)
        wanted = (4, 4) if face in ("top", "bottom") else (4, 12)
        if crop.size != wanted or crop.getchannel("A").getbbox() is None:
            raise SystemExit(f"Invalid or empty classic Steve UV face: {face}")
        crop.save(a.output / f"arm_{face}.png", optimize=False)

    write_actor(a.output)
    print("STEVE_HAND_BUILD_REPORT_BEGIN")
    print({
        "skin_size": list(skin.size),
        "arm_dimensions": [4, 12, 4],
        "uv_faces": list(FACE_UV),
        "face_textures": [f"arm_{face}.png" for face in FACE_UV],
        "vertices": 24,
        "triangles": 12,
    })
    print("STEVE_HAND_BUILD_REPORT_END")

if __name__ == "__main__":
    main()
