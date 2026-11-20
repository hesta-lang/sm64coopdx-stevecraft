"""Sanitize Steve's detached DynOS GeoLayout for independent body opacity.

Mario's alpha, torso-tilt, part-offset and head-rotation callbacks read Mario-specific
state and make a detached Steve model inherit Mario's pose. SteveCraft owns its own
Minecraft animation curves, so the detached Steve GeoLayout must not call those
Mario-specific body-pose callbacks.
"""

from __future__ import annotations

import re
from pathlib import Path

_CUSTOM_COMMAND = re.compile(
    r"(?m)^[ \t]*CUSTOM_CMD\(\),[ \t]*(?:\r?\n|$)"
)
_MARIO_ALPHA_CALLBACK = re.compile(
    r"(?m)^[ \t]*GEO_ASM\(\s*0\s*,\s*geo_mirror_mario_set_alpha\s*\)\s*,[ \t]*(?:\r?\n|$)"
)
_MARIO_POSE_CALLBACK = re.compile(
    r"(?m)^[ \t]*GEO_ASM\(\s*0\s*,\s*"
    r"(?:geo_move_mario_part_from_parent|geo_mario_tilt_torso|geo_mario_head_rotation)"
    r"\s*\)\s*,[ \t]*(?:\r?\n|$)"
)


def sanitize_steve_geo_source(source: str) -> tuple[str, dict[str, int]]:
    """Remove exporter-only commands and the shared Mario alpha callback."""
    source, custom_removed = _CUSTOM_COMMAND.subn("", source)
    source, alpha_removed = _MARIO_ALPHA_CALLBACK.subn("", source)
    source, pose_removed = _MARIO_POSE_CALLBACK.subn("", source)

    if "CUSTOM_CMD" in source:
        raise ValueError("Unsupported CUSTOM_CMD token remains in Steve GeoLayout")
    forbidden_pose_callbacks = (
        "geo_mirror_mario_set_alpha",
        "geo_move_mario_part_from_parent",
        "geo_mario_tilt_torso",
        "geo_mario_head_rotation",
    )
    if any(callback in source for callback in forbidden_pose_callbacks):
        raise ValueError("Mario-specific pose callback remains in detached Steve GeoLayout")

    return source, {
        "unsupported_custom_commands_removed": custom_removed,
        "shared_mario_alpha_callbacks_removed": alpha_removed,
        "mario_pose_callbacks_removed": pose_removed,
    }


def sanitize_steve_geo_file(path: str | Path) -> dict[str, int]:
    geo_path = Path(path)
    source = geo_path.read_text(encoding="utf-8")
    sanitized, report = sanitize_steve_geo_source(source)
    geo_path.write_text(sanitized, encoding="utf-8")
    return report
