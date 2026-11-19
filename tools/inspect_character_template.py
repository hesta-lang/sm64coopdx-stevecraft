import bpy
import json
import os
import sys
from mathutils import Vector

addon_dir = os.environ.get('FAST64_ADDON')
if addon_dir:
    sys.path.insert(0, addon_dir)
    import fast64_gart
    fast64_gart.register()
    print('FAST64_GART_REGISTERED', fast64_gart.bl_info.get('version'))
else:
    print('FAST64_GART_NOT_LOADED')

def vec(v):
    return [round(float(x), 6) for x in v]

def primitive(value):
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    try:
        return [primitive(v) for v in value]
    except Exception:
        return str(value)

def props_of(pg, depth=0):
    result = {}
    if depth > 3 or not hasattr(pg, "bl_rna"):
        return result
    for prop in pg.bl_rna.properties:
        name = prop.identifier
        if name == "rna_type" or prop.is_readonly:
            continue
        try:
            value = getattr(pg, name)
            if value is None:
                result[name] = None
            elif isinstance(value, (str, int, float, bool)):
                result[name] = value
            elif prop.type == "FLOAT" and prop.array_length:
                result[name] = primitive(value)
            elif prop.type == "ENUM":
                result[name] = str(value)
            elif prop.type == "POINTER" and hasattr(value, "bl_rna"):
                result[name] = props_of(value, depth + 1)
            elif prop.type == "COLLECTION":
                result[name] = [props_of(v, depth + 1) for v in value]
            elif hasattr(value, "size") and hasattr(value, "filepath"):
                result[name] = {
                    "name": value.name,
                    "size": primitive(value.size),
                    "filepath": value.filepath,
                    "packed": bool(value.packed_file),
                }
        except Exception:
            pass
    return result

def mesh_bounds_in_armature(obj):
    if not obj.bound_box:
        return None
    transform = obj.parent.matrix_world.inverted() @ obj.matrix_world if obj.parent and obj.parent.type == "ARMATURE" else obj.matrix_world
    pts = [transform @ Vector(c) for c in obj.bound_box]
    return {
        "min": [round(min(p[i] for p in pts), 6) for i in range(3)],
        "max": [round(max(p[i] for p in pts), 6) for i in range(3)],
    }

def vertex_group_bounds(obj):
    if obj.type != "MESH" or obj.parent is None or obj.parent.type != "ARMATURE":
        return {}
    transform = obj.parent.matrix_world.inverted() @ obj.matrix_world
    result = {}
    for group in obj.vertex_groups:
        indices = []
        for v in obj.data.vertices:
            if any(a.group == group.index and a.weight > 0.001 for a in v.groups):
                indices.append(transform @ v.co)
        if indices:
            result[group.name] = {
                "min": [round(min(p[i] for p in indices), 6) for i in range(3)],
                "max": [round(max(p[i] for p in indices), 6) for i in range(3)],
                "count": len(indices),
            }
    return result

def object_info(obj):
    data = {
        "name": obj.name,
        "type": obj.type,
        "parent": obj.parent.name if obj.parent else None,
        "location": vec(obj.location),
        "dimensions": vec(obj.dimensions),
        "scale": vec(obj.scale),
        "rotation_euler": vec(obj.rotation_euler),
        "rotation_quaternion": vec(obj.rotation_quaternion),
        "rotation_mode": obj.rotation_mode,
        "matrix_local": [[round(float(obj.matrix_local[row][col]), 6) for col in range(4)] for row in range(4)],
        "matrix_world": [[round(float(obj.matrix_world[row][col]), 6) for col in range(4)] for row in range(4)],
        "matrix_parent_inverse": [[round(float(obj.matrix_parent_inverse[row][col]), 6) for col in range(4)] for row in range(4)],
        "children": [child.name for child in obj.children],
    }
    if obj.type == "MESH":
        data["vertices"] = len(obj.data.vertices)
        data["polygons"] = len(obj.data.polygons)
        data["vertex_groups"] = [g.name for g in obj.vertex_groups]
        data["materials"] = [m.name if m else None for m in obj.data.materials]
        data["bounds_in_armature"] = mesh_bounds_in_armature(obj)
        data["group_bounds"] = vertex_group_bounds(obj)
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
            if hasattr(bone, "switch_options"):
                item["switch_options"] = [
                    {
                        "switchType": option.switchType,
                        "optionArmature": option.optionArmature.name if option.optionArmature else None,
                    }
                    for option in bone.switch_options
                ]
            data["bones"].append(item)
    return data

def material_info(material):
    data = {
        "name": material.name,
        "use_nodes": material.use_nodes,
        "texture_nodes": [
            {"name": n.name, "type": n.type, "image": n.image.name if hasattr(n, "image") and n.image else None}
            for n in (material.node_tree.nodes if material.node_tree else [])
            if n.type == "TEX_IMAGE"
        ],
    }
    if hasattr(material, "f3d_mat"):
        data["f3d"] = props_of(material.f3d_mat)
    return data

output = os.environ.get("STEVE_REPORT", "template-report.json")
report = {
    "blender_version": bpy.app.version_string,
    "scene": bpy.context.scene.name,
    "objects": [object_info(o) for o in bpy.data.objects],
    "materials": [material_info(m) for m in bpy.data.materials],
    "actions": [
        {"name": a.name, "frame_range": [float(a.frame_range[0]), float(a.frame_range[1])], "fcurves": len(a.fcurves)}
        for a in bpy.data.actions
    ],
}
with open(output, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)
print("STEVE_TEMPLATE_REPORT_BEGIN")
print(json.dumps(report, indent=2))
print("STEVE_TEMPLATE_REPORT_END")
print("Report written to", output)
