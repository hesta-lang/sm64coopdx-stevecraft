import bpy
import json
import os
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

report_path = Path(os.environ.get("STEVE_SCENE_REPORT", "build/ai-steve-scene-report.json"))

def fail(message):
    raise RuntimeError("AI Steve scene validation failed: " + message)

def require_object(name, kind):
    value = bpy.data.objects.get(name)
    if value is None:
        fail("required template object is missing: " + name)
    if value.type != kind:
        fail("{} must be {}, got {}".format(name, kind, value.type))
    return value

def assigned_vertex_count(mesh_obj, group_name):
    group = mesh_obj.vertex_groups.get(group_name)
    if group is None:
        return 0
    index = group.index
    return sum(1 for vertex in mesh_obj.data.vertices
               if any(item.group == index and item.weight > 0.0 for item in vertex.groups))

def validate_mesh(mesh_obj, label, required_groups):
    if len(mesh_obj.data.vertices) < 8 or len(mesh_obj.data.polygons) < 6:
        fail(label + " has no usable character geometry")
    uv = mesh_obj.data.uv_layers.get("UVMap")
    if uv is None or len(uv.data) != len(mesh_obj.data.loops):
        fail(label + " is missing a complete UVMap layer")
    if not mesh_obj.data.materials:
        fail(label + " has no materials")
    missing = [name for name in required_groups if assigned_vertex_count(mesh_obj, name) == 0]
    if missing:
        fail(label + " has empty or missing vertex groups: " + ", ".join(missing))
    if any(poly.material_index >= len(mesh_obj.data.materials) for poly in mesh_obj.data.polygons):
        fail(label + " has faces referencing missing material slots")
    names = []
    for material in mesh_obj.data.materials:
        if material is None or not hasattr(material, "f3d_mat"):
            fail(label + " contains a material without Fast64 F3D settings")
        names.append(material.name)
    return {
        "vertices": len(mesh_obj.data.vertices),
        "polygons": len(mesh_obj.data.polygons),
        "uv_layer": uv.name,
        "vertex_groups": {name: assigned_vertex_count(mesh_obj, name) for name in required_groups},
        "materials": names,
    }

def main():
    mario = require_object("Mario", "ARMATURE")
    body = require_object("Mario Mesh", "MESH")
    head = require_object("Capless Head Mesh", "MESH")
    metal = require_object("Metal Mario", "ARMATURE")
    metal_body = require_object("Metal Mario Mesh", "MESH")
    metal_head = require_object("Metal Capless Head Mesh", "MESH")

    if body.parent != mario or head.parent != mario:
        fail("Steve body and capless head must remain parented to Mario")
    if metal_body.parent != metal or metal_head.parent != metal:
        fail("the template's Metal Mario branch must be preserved")
    if not any(m.type == "ARMATURE" and m.object == mario for m in body.modifiers):
        fail("Mario Mesh has no armature modifier targeting Mario")
    if not any(m.type == "ARMATURE" and m.object == mario for m in head.modifiers):
        fail("Capless Head Mesh has no armature modifier targeting Mario")

    groups = ["Head DL", "Torso", "Left Arm Color", "Right Arm Color",
              "Left Thigh Color", "Right Thigh Color"]
    body_report = validate_mesh(body, "Mario Mesh", groups)
    head_report = validate_mesh(head, "Capless Head Mesh", ["Capless Head"])

    report = {
        "status": "passed",
        "blender_version": bpy.app.version_string,
        "objects": {
            "Mario": mario.name,
            "Mario Mesh": body_report,
            "Capless Head Mesh": head_report,
            "Metal Mario": metal.name,
            "Metal Mario Mesh": {"vertices": len(metal_body.data.vertices),
                                 "polygons": len(metal_body.data.polygons)},
            "Metal Capless Head Mesh": {"vertices": len(metal_head.data.vertices),
                                        "polygons": len(metal_head.data.polygons)},
        },
        "armature_bones": [bone.name for bone in mario.data.bones],
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("AI_STEVE_SCENE_VALIDATION_BEGIN")
    print(json.dumps(report, indent=2))
    print("AI_STEVE_SCENE_VALIDATION_END")

if __name__ == "__main__":
    main()
