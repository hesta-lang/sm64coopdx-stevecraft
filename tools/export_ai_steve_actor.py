import bpy
import json
import os
import re
import sys
from pathlib import Path

addon_parent = Path(os.environ["FAST64_ADDON"]).resolve()
addon_root = addon_parent / "fast64_gart"
if not (addon_root / "__init__.py").is_file():
    addon_root = addon_parent
sys.path.insert(0, str(addon_root))
sys.path.insert(0, str(addon_parent))
import fast64_gart
fast64_gart.register()

output_root = Path(os.environ.get("STEVE_ACTOR_OUTPUT", "build/actor/actors")).resolve()
report_path = Path(os.environ.get("STEVE_EXPORT_REPORT", "build/ai-steve-export-report.json"))

def main():
    mario = bpy.data.objects.get("Mario")
    if mario is None or mario.type != "ARMATURE":
        raise RuntimeError("Mario armature missing after scene validation")

    scene = bpy.context.scene
    scene.gameEditorMode = "SM64"
    scene.fast64.sm64.export_type = "C"
    scene.saveTextures = False
    scene.geoSeparateTextureDef = False
    props = scene.fast64.sm64.combined_export
    props.export_header_type = "Custom"
    props.custom_export_path = str(output_root)
    props.custom_include_directory = ""
    props.object_name = "steve"
    props.export_gfx = True
    props.export_col = False
    props.export_anim = False
    props.export_bhv = False
    props.export_script_loads = False
    props.export_all_selected = False
    props.use_name_filtering = True

    bpy.ops.object.select_all(action="DESELECT")
    mario.select_set(True)
    bpy.context.view_layer.objects.active = mario
    if mario.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    result = bpy.ops.object.sm64_export_geolayout_armature("EXEC_DEFAULT", export_obj=mario.name)
    if "FINISHED" not in result:
        raise RuntimeError("Fast64 GeoLayout export did not finish: " + repr(result))

    actor_dir = output_root / "steve"
    required = ["geo.inc.c", "model.inc.c", "geo_header.h"]
    missing = [name for name in required if not (actor_dir / name).is_file()]
    if missing:
        raise RuntimeError("Fast64 export is missing: " + ", ".join(missing))

    geo_path = actor_dir / "geo.inc.c"
    geo = geo_path.read_text(encoding="utf-8")
    geo, count = re.subn(r"(GEO_SCALE\(LAYER_FORCE,\s*)16384(\s*\))",
                         r"\g<1>65536\2", geo, count=1)
    if count != 1:
        raise RuntimeError("Could not apply Steve root scale; inspect exported GeoLayout")
    geo_path.write_text(geo, encoding="utf-8")

    model = (actor_dir / "model.inc.c").read_text(encoding="utf-8")
    if "CUSTOM_CMD" in geo:
        raise RuntimeError("Unsupported CUSTOM_CMD remains in GeoLayout")
    if "gsDPSetTextureImage" not in model:
        raise RuntimeError("Exported model has no texture image commands")
    if "G_IM_FMT_RGBA" not in model:
        raise RuntimeError("Exported model has no RGBA texture data")
    if "G_TF_POINT" not in model:
        raise RuntimeError("Exported model is missing nearest-neighbor pixel-art filtering")

    report = {
        "status": "passed",
        "blender_version": bpy.app.version_string,
        "fast64_version": list(fast64_gart.bl_info.get("version", [])),
        "export_result": list(result),
        "actor_directory": str(actor_dir),
        "files": sorted(path.name for path in actor_dir.iterdir() if path.is_file()),
        "root_scale": 65536,
        "source_scene": "ai-model/steve_compatible.blend",
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("AI_STEVE_EXPORT_BEGIN")
    print(json.dumps(report, indent=2))
    print("AI_STEVE_EXPORT_END")

if __name__ == "__main__":
    main()
