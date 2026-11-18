import bpy
import json
import os

def vec(v):
    return [round(float(x), 6) for x in v]

def object_info(obj):
    data = {
        "name": obj.name,
        "type": obj.type,
        "parent": obj.parent.name if obj.parent else None,
        "location": vec(obj.location),
        "dimensions": vec(obj.dimensions),
        "scale": vec(obj.scale),
        "children": [child.name for child in obj.children],
    }
    if obj.type == "MESH":
        data["vertices"] = len(obj.data.vertices)
        data["polygons"] = len(obj.data.polygons)
        data["vertex_groups"] = [g.name for g in obj.vertex_groups]
        data["materials"] = [m.name if m else None for m in obj.data.materials]
    if obj.type == "ARMATURE":
        data["bones"] = []
        for bone in obj.data.bones:
            item = {
                "name": bone.name,
                "parent": bone.parent.name if bone.parent else None,
                "head_local": vec(bone.head_local),
                "tail_local": vec(bone.tail_local),
                "length": round(float(bone.length), 6),
                "use_deform": bool(bone.use_deform),
            }
            if hasattr(bone, "geo_cmd"):
                item["geo_cmd"] = bone.geo_cmd
            data["bones"].append(item)
    return data

output = os.environ.get("STEVE_REPORT", "template-report.json")
report = {
    "blender_version": bpy.app.version_string,
    "scene": bpy.context.scene.name,
    "objects": [object_info(o) for o in bpy.data.objects],
    "actions": [
        {
            "name": a.name,
            "frame_range": [float(a.frame_range[0]), float(a.frame_range[1])],
            "fcurves": len(a.fcurves),
        }
        for a in bpy.data.actions
    ],
}
with open(output, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)
print("STEVE_TEMPLATE_REPORT_BEGIN")
print(json.dumps(report, indent=2))
print("STEVE_TEMPLATE_REPORT_END")
print("Report written to", output)
