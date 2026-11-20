#!/usr/bin/env python3
"""Extract selected method bodies from a NeoForm gameSources archive."""
from __future__ import annotations
import argparse, hashlib, json, re, zipfile
from pathlib import Path

SPECS = [
 {"class":"HumanoidModel","package":"net.minecraft.client.model","source_path":"net/minecraft/client/model/HumanoidModel.java",
  "selected_methods":["getHead","quadraticArmUpdate","getArm","setupAnim","createMesh"],
  "api_methods":["createMesh","createArmorMeshSet","createBabyArmorMeshSet","setupAnim","setupSwimAnimation","setupAttackAnimation","translateToHand","getArm","getHead","isTwoHanded","affectsOffhandPose","animateUseItem"],
  "helper_methods":["createBaseArmorMesh","createBabyArmorMesh","poseRightArm","poseLeftArm","poseBlockingArm","quadraticArmUpdate"],
  "field_names":["BABY_TRANSFORMER","OVERLAY_SCALE","HAT_OVERLAY_SCALE","LEGGINGS_OVERLAY_SCALE","DUCK_WALK_ROTATION","SPYGLASS_ARM_ROT_Y","SPYGLASS_ARM_ROT_X","SPYGLASS_ARM_CROUCH_ROT_X","HIGHEST_SHIELD_BLOCKING_ANGLE","LOWEST_SHIELD_BLOCKING_ANGLE","HORIZONTAL_SHIELD_MOVEMENT_LIMIT","TOOT_HORN_XROT_BASE","TOOT_HORN_YROT_BASE","ADULT_ARMOR_PARTS_PER_SLOT","BABY_ARMOR_PARTS_PER_SLOT","head","hat","body","rightArm","leftArm","rightLeg","leftLeg"],
  "fixture_fields":["head","leftArm","rightArm"],"api_surface_count":13},
 {"class":"PlayerModel","package":"net.minecraft.client.model.player","source_path":"net/minecraft/client/model/player/PlayerModel.java",
  "selected_methods":["getRandomBodyPart","setupAnim","translateToHand","createMesh","createArmorMeshSet"],
  "api_methods":["createMesh","createArmorMeshSet","setupAnim","translateToHand","getRandomBodyPart"],"helper_methods":[],
  "field_names":["LEFT_SLEEVE","RIGHT_SLEEVE","LEFT_PANTS","RIGHT_PANTS","bodyParts","leftSleeve","rightSleeve","leftPants","rightPants","jacket","slim"],
  "fixture_fields":["bodyParts","slim"],"api_surface_count":5},
 {"class":"Mth","package":"net.minecraft.util","source_path":"net/minecraft/util/Mth.java",
  "selected_methods":[
   {"name":"clamp","params":["double","double","double"]},
   {"name":"clampedLerp","params":["double","double","double"]},
   {"name":"absMax","params":["double","double"]},
   {"name":"equal","params":["double","double"]},
   {"name":"sign","params":["double"]},
   {"name":"lerp","params":["double","double","double"]},
   {"name":"square","params":["double"]},
   {"name":"inverseLerp","params":["double","double","double"]},
   {"name":"clampedMap","params":["double","double","double","double","double"]},
   {"name":"map","params":["double","double","double","double","double"]},
   {"name":"lengthSquared","params":["double","double","double"]},
   {"name":"length","params":["double","double","double"]}
  ],
  "api_methods":["clamp","lerp","sign","wrapDegrees","absMax","degreesDifference","degreesDifferenceAbs","rotateIfNecessary","approach","approachDegrees","positiveModulo","frac","square","cube","equal","clampedLerp","sin","cos","sqrt","rotLerpRad","inverseLerp","clampedMap","map","lengthSquared","length"],
  "helper_methods":[],
  "field_names":["PI","HALF_PI","TWO_PI","DEG_TO_RAD","RAD_TO_DEG","SIN_QUANTIZATION","SIN_MASK","COS_OFFSET","SIN_SCALE","SIN"],
  "fixture_fields":[],"api_surface_count":114}
]

def method_header(name):
 return re.compile(rf"(?m)^[ \t]*(?:(?:public|protected|private)\s+)[^{{;]*?\b{re.escape(name)}\s*\((?P<params>[^)]*)\)\s*(?:throws\s+[^{{]+)?\{{")

def parameter_types(params):
 if not params.strip(): return []
 result=[]
 for part in params.split(","):
  cleaned=re.sub(r"\bfinal\b","",part).strip()
  match=re.fullmatch(r"([\w.$]+(?:\[\])?)\s+[A-Za-z_$]\w*",cleaned)
  if not match: return None
  result.append(match.group(1))
 return result

def read_entry(archive,suffix):
 matches=[name for name in archive.namelist() if name.endswith(suffix)]
 if len(matches)!=1: raise RuntimeError(f"Expected one {suffix} entry; found {matches}")
 return matches[0],archive.read(matches[0]).decode("utf-8")

def find_method(source,selected):
 name=selected if isinstance(selected,str) else selected["name"]
 expected=None if isinstance(selected,str) else selected.get("params")
 for match in method_header(name).finditer(source):
  if expected is not None and parameter_types(match.group("params"))!=expected: continue
  if source[:match.start()].count("{")-source[:match.start()].count("}")!=1: continue
  depth=0
  for index in range(match.end()-1,len(source)):
   if source[index]=="{": depth+=1
   elif source[index]=="}":
    depth-=1
    if depth==0: return source[match.start():index+1].strip(),source.count("\n",0,match.start())+1
 expected_text="" if expected is None else "("+", ".join(expected)+")"
 raise RuntimeError(f"Could not extract top-level method {name}{expected_text}")

def find_class_header(source,name):
 match=re.search(rf"(?m)^[ \t]*(?:public\s+)?class\s+{re.escape(name)}\b[^{{]*\{{",source)
 if not match: raise RuntimeError(f"Class declaration not found: {name}")
 return match.group(0).strip()

def class_extends(header):
 match=re.search(r"\bclass\s+\w+",header)
 if not match: return None
 rest=header[match.end():].lstrip()
 if rest.startswith("<"):
  depth=0; end=None
  for index,char in enumerate(rest):
   if char=="<": depth+=1
   elif char==">":
    depth-=1
    if depth==0:
     end=index+1; break
  if end is None: raise RuntimeError("Unclosed generic type parameters in class header")
  rest=rest[end:]
 parent=re.search(r"\bextends\s+(.+?)(?=\s+implements\s+|\s*\{)",rest)
 return parent.group(1).strip() if parent else None
def analyze_source(source,spec):
 name=spec["class"]; header=find_class_header(source,name)
 imports=re.findall(r"(?m)^[ \t]*import\s+([^;]+);",source)
 constructors=[m.group(0).split("{",1)[0].strip() for m in re.finditer(
  rf"(?m)^[ \t]*(?:public|protected|private)\s+{re.escape(name)}\s*\([^)]*\)\s*\{{",source)]
 ext=class_extends(header)
 impl=re.search(r"\bimplements\s+(.+?)\s*\{",header)
 fields=[field for field in spec["field_names"] if re.search(rf"\b{re.escape(field)}\b",source)]
 methods=[method for method in spec["api_methods"]+spec["helper_methods"] if re.search(rf"\b{re.escape(method)}\s*\(",source)]
 types=["Mth","Util","ModelPart","PoseStack","CubeListBuilder","PartDefinition","PartPose","MeshDefinition","ArmorModelSet","RenderTypes","AnimationUtils","SpearAnimations","Ease","HumanoidArm","RandomSource"]
 type_refs=sorted({x for x in types if re.search(rf"\b{re.escape(x)}\b",source)})
 static_calls={f"{owner}.{method}" for owner,method in re.findall(r"\b([A-Z][A-Za-z0-9_]*)\s*\.\s*([A-Za-z_]\w*)\s*\(",source)}
 refs={f"{owner}::{method}" for owner,method in re.findall(r"\b([A-Z][A-Za-z0-9_]*)\s*::\s*([A-Za-z_]\w*)",source)}
 instance_names=["getChild","translateAndRotate","addOrReplaceChild","getRoot","retainPartsAndChildren","retainExactParts","map"]
 instance_calls={"instance."+x for x in instance_names if re.search(r"\.\s*"+re.escape(x)+r"\s*\(",source)}
 return {"class":spec["package"]+"."+name,"source_entry":spec["source_path"],"package":spec["package"],
  "class_declaration":header,"extends":ext,
  "implements":[x.strip() for x in impl.group(1).split(",")] if impl else [],
  "imports":imports,"fields_present_in_source":fields,"constructors":constructors,
  "api_surface_count":spec["api_surface_count"],"api_methods":spec["api_methods"],"helper_methods":spec["helper_methods"],
  "methods_present_in_source":methods,"engine_api_type_references":type_refs,
  "engine_api_calls":sorted(static_calls|refs|instance_calls)}

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument("--sources",required=True,type=Path); p.add_argument("--output",required=True,type=Path)
 p.add_argument("--report",required=True,type=Path); p.add_argument("--neoform-coordinate",default="net.neoforged:neoform:26.3-1@zip")
 a=p.parse_args()
 if not a.sources.is_file(): p.error("source archive does not exist")
 digest=hashlib.sha256(a.sources.read_bytes()).hexdigest(); a.output.mkdir(parents=True,exist_ok=True)
 reports=[]
 with zipfile.ZipFile(a.sources) as archive:
  for spec in SPECS:
   entry,source=read_entry(archive,spec["source_path"]); info=analyze_source(source,spec)
   methods=[]; selected=[]
   for method_spec in spec["selected_methods"]:
    body,line=find_method(source,method_spec); methods.append(body)
    method_name=method_spec if isinstance(method_spec,str) else method_spec["name"]
    header=body.split("{",1)[0].strip()
    params_match=re.search(r"\(([^)]*)\)",header)
    selected.append({"name":method_name,"source_line":line,"signature":header,"parameter_types":parameter_types(params_match.group(1)) if params_match else []})
   wrapper=[f"package {spec['package']};"]
   for imported in info["imports"]:
    if imported in ("net.minecraft.util.Util","net.minecraft.world.entity.HumanoidArm"):
     wrapper.append(f"import {imported};")
   wrapper.extend(["","// Selected source-derived method excerpts; the full Minecraft type is omitted.",info["class_declaration"]])
   for field in spec["fixture_fields"]:
    declaration=next((line.strip() for line in source.splitlines()
      if re.match(r"^[ \t]*(?:public|protected|private)\b",line) and re.search(rf"\b{re.escape(field)}\s*(?:;|=)",line)),None)
    if declaration: wrapper.append("    "+declaration)
   for body,item in zip(methods,selected):
    wrapper.extend(["",f"    // Extracted from {entry}:{item['source_line']}","    "+body.replace("\n","\n    ")])
   wrapper.append("}")
   destination=a.output/Path(*spec["package"].split("."))/(spec["class"]+".java")
   destination.parent.mkdir(parents=True,exist_ok=True); destination.write_text("\n".join(wrapper)+"\n",encoding="utf-8")
   info.update({"source_entry":entry,"selected_methods_extracted":selected,"wrapper_path":destination.as_posix(),"status":"source_excerpt_only"})
   reports.append(info)
 report={"minecraft_version":"26.3","neoform_coordinate":a.neoform_coordinate,"source_archive":a.sources.name,
  "source_archive_sha256":digest,"full_source_committed":False,"classes":reports}
 a.report.parent.mkdir(parents=True,exist_ok=True); a.report.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
 print(json.dumps(report,indent=2)); return 0
if __name__=="__main__": raise SystemExit(main())
