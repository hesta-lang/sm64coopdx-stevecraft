"""Sanitize Steve's detached DynOS GeoLayout for independent body opacity.

Mario's geo_mirror_mario_set_alpha callback reads MarioBodyState.modelState.
SteveCraft deliberately sets that value to alpha 0 to hide the native Mario body.
A detached Steve GeoLayout must not call that Mario-specific alpha callback.
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


def sanitize_steve_geo_source(source: str) -> tuple[str, dict[str, int]]:
    """Remove exporter-only commands and the shared Mario alpha callback."""
    source, custom_removed = _CUSTOM_COMMAND.subn("", source)
    source, alpha_removed = _MARIO_ALPHA_CALLBACK.subn("", source)

    if "CUSTOM_CMD" in source:
        raise ValueError("Unsupported CUSTOM_CMD token remains in Steve GeoLayout")
    if "geo_mirror_mario_set_alpha" in source:
        raise ValueError("Mario shared-alpha callback remains in detached Steve GeoLayout")

    return source, {
        "unsupported_custom_commands_removed": custom_removed,
        "shared_mario_alpha_callbacks_removed": alpha_removed,
    }


def sanitize_steve_geo_file(path: str | Path) -> dict[str, int]:
    geo_path = Path(path)
    source = geo_path.read_text(encoding="utf-8")
    sanitized, report = sanitize_steve_geo_source(source)
    geo_path.write_text(sanitized, encoding="utf-8")
    return report
