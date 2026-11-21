"""Align Steve's generated GeoLayout with the 20-node DynOS animation rig.

The Minecraft clips reserve animated nodes for leftHand and rightHand. The
stock Fast64 export omits those empty wrist nodes, shifting every channel after
each forearm. This pass restores the two zero-offset nodes after the forearms.
"""

from __future__ import annotations

import re
from pathlib import Path

FULL_BODY_LAYOUTS = (
    "steve_geo",
    "steve_geo_opt_1",
    "steve_geo_opt_1_1",
    "steve_Metal_Mario",
)
EXPECTED_ANIMATED_NODES = 20

_LAYOUT_START = re.compile(
    r"(?m)^const\s+GeoLayout\s+(?P<name>[A-Za-z0-9_]+)\[\]\s*=\s*\{"
)
_ARM_LINE = {
    "left": re.compile(
        r"(?m)^(?P<indent>[ \t]*)GEO_ANIMATED_PART\(\s*"
        r"(?P<layer>LAYER_OPAQUE|LAYER_TRANSPARENT),\s*0,\s*0,\s*0,\s*"
        r"steve_[A-Za-z0-9_]*Left_Arm_Color_mesh_layer_1\s*\),[ \t]*$"
    ),
    "right": re.compile(
        r"(?m)^(?P<indent>[ \t]*)GEO_ANIMATED_PART\(\s*"
        r"(?P<layer>LAYER_OPAQUE|LAYER_TRANSPARENT),\s*0,\s*0,\s*0,\s*"
        r"steve_[A-Za-z0-9_]*Right_Arm_Color_mesh_layer_1\s*\),[ \t]*$"
    ),
}
_FOREARM_LINE = re.compile(
    r"(?m)^(?P<indent>[ \t]*)GEO_ANIMATED_PART\(\s*"
    r"(?P<layer>LAYER_OPAQUE|LAYER_TRANSPARENT),\s*31,\s*0,\s*0,\s*NULL\s*\),[ \t]*$"
)
_ZERO_HAND_NODE = re.compile(
    r"^[ \t]*GEO_OPEN_NODE\(\),[ \t]*\r?\n"
    r"[ \t]*GEO_ANIMATED_PART\(\s*LAYER_(?:OPAQUE|TRANSPARENT),\s*"
    r"0,\s*0,\s*0,\s*NULL\s*\),[ \t]*\r?\n"
    r"[ \t]*GEO_CLOSE_NODE\(\),[ \t]*"
)


def _extract_layouts(source: str) -> dict[str, tuple[int, int]]:
    layouts: dict[str, tuple[int, int]] = {}
    for match in _LAYOUT_START.finditer(source):
        end = source.find("\n};", match.end())
        if end < 0:
            raise ValueError(f"Unterminated GeoLayout: {match.group('name')}")
        layouts[match.group("name")] = (match.start(), end + 3)
    return layouts


def _line_ending(source: str) -> str:
    return "\r\n" if "\r\n" in source else "\n"


def _patch_layout(layout: str, layout_name: str, newline: str) -> tuple[str, dict[str, int]]:
    counts = {"left": 0, "right": 0}
    for side, arm_pattern in _ARM_LINE.items():
        arm_matches = list(arm_pattern.finditer(layout))
        if len(arm_matches) != 1:
            raise ValueError(
                f"{layout_name}: expected one {side} arm display node, found {len(arm_matches)}"
            )

        arm = arm_matches[0]
        after_arm = layout[arm.end():]
        open_match = re.match(r"[ \t]*\r?\n(?P<indent>[ \t]*)GEO_OPEN_NODE\(\),[ \t]*\r?\n", after_arm)
        if open_match is None:
            raise ValueError(f"{layout_name}: {side} arm has no child GeoLayout node")

        forearm = _FOREARM_LINE.match(after_arm[open_match.end():])
        if forearm is None:
            raise ValueError(f"{layout_name}: {side} arm is not followed by the expected forearm node")

        forearm_end = open_match.end() + forearm.end()
        after_forearm = after_arm[forearm_end:]
        existing = re.match(r"[ \t]*\r?\n(?P<indent>[ \t]*)GEO_OPEN_NODE\(\),", after_forearm)
        if existing is not None:
            if _ZERO_HAND_NODE.match(after_forearm[existing.start(1):]) is None:
                raise ValueError(f"{layout_name}: unexpected child under {side} forearm")
            continue

        # The following close must close the arm's existing child list. The
        # inserted open/close pair creates the missing zero-offset wrist node.
        following_close = re.match(r"[ \t]*\r?\n(?P<close_indent>[ \t]*)GEO_CLOSE_NODE\(\),", after_forearm)
        if following_close is None:
            raise ValueError(f"{layout_name}: missing close after {side} forearm")

        fore_indent = forearm.group("indent")
        parent_indent = open_match.group("indent")
        if not fore_indent.startswith(parent_indent) or len(fore_indent) <= len(parent_indent):
            raise ValueError(f"{layout_name}: inconsistent indentation around {side} forearm")
        indent_unit = fore_indent[len(parent_indent):]
        child_indent = fore_indent + indent_unit
        insert = (
            newline + fore_indent + "GEO_OPEN_NODE()," +
            newline + child_indent +
            f"GEO_ANIMATED_PART({forearm.group('layer')}, 0, 0, 0, NULL)," +
            newline + fore_indent + "GEO_CLOSE_NODE(),"
        )
        absolute_insert = arm.end() + forearm_end
        layout = layout[:absolute_insert] + insert + layout[absolute_insert:]
        counts[side] = 1

    animated_nodes = len(re.findall(r"\bGEO_ANIMATED_PART\s*\(", layout))
    if animated_nodes != EXPECTED_ANIMATED_NODES:
        raise ValueError(
            f"{layout_name}: expected {EXPECTED_ANIMATED_NODES} animated nodes after "
            f"wrist alignment, found {animated_nodes}"
        )
    return layout, counts


def patch_steve_dynos_skeleton_source(source: str) -> tuple[str, dict]:
    """Insert missing wrist nodes and validate all full-body DynOS layouts."""
    layouts = _extract_layouts(source)
    missing = [name for name in FULL_BODY_LAYOUTS if name not in layouts]
    if missing:
        raise ValueError("Missing full-body Steve GeoLayouts: " + ", ".join(missing))

    newline = _line_ending(source)
    report = {
        "layouts_validated": [],
        "animated_nodes_per_layout": EXPECTED_ANIMATED_NODES,
        "inserted_wrist_nodes": {"left": 0, "right": 0},
    }

    for name in FULL_BODY_LAYOUTS:
        start, end = layouts[name]
        original = source[start:end]
        patched, counts = _patch_layout(original, name, newline)
        source = source[:start] + patched + source[end:]
        delta = len(patched) - len(original)
        layouts = {
            key: (a + delta, b + delta) if a > start else (a, b)
            for key, (a, b) in layouts.items()
        }
        report["layouts_validated"].append(name)
        for side in ("left", "right"):
            report["inserted_wrist_nodes"][side] += counts[side]

    return source, report


def patch_steve_dynos_skeleton(path: str | Path) -> dict:
    geo_path = Path(path)
    source = geo_path.read_text(encoding="utf-8")
    patched, report = patch_steve_dynos_skeleton_source(source)
    geo_path.write_text(patched, encoding="utf-8")
    return report
