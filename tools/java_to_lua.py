#!/usr/bin/env python3
"""Conservative Java-subset to Lua 5.4 transpiler for SteveCraft.

This is not a Java VM or a whole-Minecraft decompiler. Unsupported members are
reported and omitted; strict mode turns those omissions into a failed build.
"""
from __future__ import annotations
import argparse, json, re, sys
from pathlib import Path

TOKEN = re.compile(r'''//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[0-7_]+|(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?[fFdD]?|\d+[lL]?|[A-Za-z_$][\w$]*|>>>=|<<=|>>=|==|!=|<=|>=|&&|\|\||\+\+|--|\+=|-=|\*=|/=|%=|<<|>>>|>>|::|->|[{}()\[\];,.?:+\-*/%<>=!&|^~]''')
TYPE = r'(?:byte|short|int|long|float|double|boolean|char|String|[\w$.]+(?:\[\])?)'
RETURN_TYPE = r'(?:' + TYPE + r'|[\w$.]+\s*<\s*[\w$.,?\s]+\s*>)'
IMPORT_ADAPTERS = {"net.minecraft.util.Util": "MC.Util", "net.minecraft.world.entity.HumanoidArm": "MC.HumanoidArm"}
MTH_CONSTANTS = {"PI", "HALF_PI", "TWO_PI", "DEG_TO_RAD", "RAD_TO_DEG"}
ENGINE_API_TYPES = {"ModelPart", "PoseStack", "HumanoidModel", "AvatarRenderState", "HumanoidRenderState", "ArmedEntityRenderState", "MeshDefinition", "CubeDeformation", "CubeListBuilder", "PartDefinition", "PartPose", "ArmorModelSet", "RenderTypes", "RenderType", "EquipmentSlot", "ItemStack", "InteractionHand", "RandomSource", "SpearAnimations", "AnimationUtils", "Identifier", "Maps", "Map", "Set", "Function", "EntityModel", "ArmedModel", "HeadedModel", "Ease", "SwingDescription"}
ENGINE_API_METHODS = {"translateAndRotate", "addOrReplaceChild", "retainPartsAndChildren", "retainExactParts", "getRoot", "getChild", "animateCrossbowCharge", "animateCrossbowHold", "thirdPersonHandUse", "thirdPersonAttackHand", "entityCutout", "entityTranslucent"}

MATH = {"abs":"math.abs","sqrt":"math.sqrt","sin":"math.sin","cos":"math.cos","atan2":"math.atan",
        "tan":"math.tan","floor":"math.floor","ceil":"math.ceil",
        "min":"math.min","max":"math.max","pow":"math.pow"}
MTH = {"abs":"math.abs","sqrt":"MC.Mth.sqrt","sin":"MC.Mth.sin","cos":"MC.Mth.cos",
       "floor":"math.floor","ceil":"math.ceil","clamp":"MC.Mth.clamp",
       "lerp":"MC.Mth.lerp","sign":"MC.Mth.sign","wrapDegrees":"MC.Mth.wrapDegrees","lfloor":"MC.Mth.lfloor",
       "absMax":"MC.Mth.absMax","rotLerpRad":"MC.Mth.rotLerpRad"}

def tokens(source):
    out=[]
    for m in TOKEN.finditer(source):
        s=m.group(0)
        if s.startswith("//") or s.startswith("/*"): continue
        out.append(s)
    return out

def matching(ts, start, left="(", right=")"):
    depth=0
    for i in range(start,len(ts)):
        if ts[i]==left: depth+=1
        elif ts[i]==right:
            depth-=1
            if depth==0: return i
    raise ValueError("unclosed "+left)

def expr(ts, report, where, class_name=None, class_methods=()):
    s=" ".join(ts)
    s=re.sub(r'\b(?:true|false|null)\b',lambda m:{"true":"true","false":"false","null":"nil"}[m.group()],s)
    s=re.sub(r'\bthis\s*\.\s*','self.',s)
    s=re.sub(r'\bMath\s*\.\s*PI\b', 'math.pi', s)
    s=re.sub(r'\bMath\s*\.\s*E\b', 'math.exp(1)', s)
    s=re.sub(r'\bMath\s*\.\s*(\w+)',lambda m:MATH.get(m.group(1),"math."+m.group(1)),s)
    s=re.sub(r'\bMth\s*\.\s*(PI|HALF_PI|TWO_PI|DEG_TO_RAD|RAD_TO_DEG)\b',lambda m:'MC.Mth.'+m.group(1),s)
    def mth_call(match):
        method = match.group(1)
        if class_name == "Mth" and method == "lfloor":
            return "MC.Mth.lfloor"
        if class_name == "Mth" and method in class_methods:
            return f"Mth.{method}"
        return MTH.get(method, "MC.Mth." + method)
    s=re.sub(r'\bMth\s*\.\s*(\w+)',mth_call,s)
    if class_name == "Mth":
        s=re.sub(r'(?<![\w$.])lfloor\s*\(', "MC.Mth.lfloor(", s)
    if class_name and class_methods:
        own_pattern="|".join(re.escape(x) for x in sorted(class_methods,key=len,reverse=True))
        s=re.sub(rf'(?<![\w$.])({own_pattern})\s*\(',lambda m:f"{class_name}.{m.group(1)}(",s)
    s=s.replace("&&"," and ").replace("||"," or ").replace("!=","~=")
    s=re.sub(r'(?<![=!<>])!(?!=)'," not ",s)
    s=re.sub(r'\b(\d[\d_]*)([lL])\b',r'\1',s)
    s=re.sub(r'\b0[xX]([0-9a-fA-F_]+)\b',lambda m:str(int(m.group(1).replace("_",""),16)),s)
    s=re.sub(r'\b0[bB]([01_]+)\b',lambda m:str(int(m.group(1).replace("_",""),2)),s)
    s=re.sub(r'\b0([0-7_]+)\b',lambda m:str(int(m.group(1).replace("_",""),8)),s)
    def normalize_float_suffix(match):
        literal=match.group(1)
        return f"MC.java_float({literal})" if match.group(2).lower()=="f" else literal
    s=re.sub(r'(?<![\w.])((?:\d[\d_]*(?:\.\d[\d_]*)?|\.\d[\d_]+)(?:[eE][+-]?\d[\d_]*)?)([fFdD])\b',normalize_float_suffix,s)
    s=re.sub(r'\s+', ' ', s).strip()
    if re.search(r'\b(?:byte|short|int|long|float|double)\s*\)'," ".join(ts)):
        report["warnings"].append(f"{where}: primitive cast erased; Java overflow/narrowing is not exact")
    if "/" in ts:
        report["warnings"].append(f"{where}: division uses Lua number semantics, not Java integer division")
    return s

class Body:
    def __init__(self, ts, report, where, class_name=None, class_methods=()):
        self.t=ts; self.i=0; self.r=report; self.w=where; self.c=class_name; self.cm=class_methods
    def take_expr(self, stop):
        start=self.i; depth=0
        while self.i<len(self.t):
            x=self.t[self.i]
            if depth==0 and x in stop: break
            if x in ("(","["): depth+=1
            elif x in (")","]"): depth-=1
            self.i+=1
        return self.t[start:self.i]
    def statement(self, indent=1):
        pad="    "*indent
        if self.i>=len(self.t): return []
        if self.t[self.i]==";": self.i+=1; return []
        if self.t[self.i]=="{":
            self.i+=1; out=[]
            while self.i<len(self.t) and self.t[self.i]!="}": out+=self.statement(indent)
            if self.i<len(self.t): self.i+=1
            return out
        if self.t[self.i] in ("if","while","for"):
            kind=self.t[self.i]; self.i+=1
            if self.i>=len(self.t) or self.t[self.i]!="(": raise ValueError("expected condition")
            end=matching(self.t,self.i); inside=self.t[self.i+1:end]; self.i=end+1
            if kind=="for":
                chunks=[]; start=0; dep=0
                for j,x in enumerate(inside):
                    dep += x in ("(","["); dep -= x in (")","]")
                    if x==";" and dep==0: chunks.append(inside[start:j]); start=j+1
                chunks.append(inside[start:])
                if len(chunks)!=3: raise ValueError("unsupported for header")
                init=" ".join(chunks[0]); cond=expr(chunks[1],self.r,self.w,self.c,self.cm); step=" ".join(chunks[2])
                m=re.match(r'\s*(?:(?:int|long|var)\s+)?(\w+)\s*=\s*(-?\d+)\s*$',init)
                sm=re.fullmatch(r'\s*(\w+)\s*(\+\+|--)\s*',step)
                if m and sm and m.group(1)==sm.group(1) and re.fullmatch(rf'{re.escape(m.group(1))}\s*(<|<=|>|>=)\s*-?\d+',cond):
                    v=m.group(1); op=re.search(r'(<=|>=|<|>)',cond).group(1); limit=re.search(r'-?\d+$',cond).group()
                    if (op in ("<","<=") and sm.group(2)=="--") or (op in (">",">=") and sm.group(2)=="++"):
                        raise ValueError("for loop direction mismatch")
                    if op=="<" and sm.group(2)=="++": limit=f"({limit} - 1)"
                    if op==">" and sm.group(2)=="--": limit=f"({limit} + 1)"
                    body=self.statement(indent+1)
                    out=[pad+f"for {v} = {m.group(2)}, {limit}, {1 if sm.group(2)=='++' else -1} do"]+body+[pad+"end"]
                    return out
                raise ValueError("only constant-bound numeric for loops are supported")
            cond=expr(inside,self.r,self.w,self.c,self.cm); body=self.statement(indent+1)
            if kind=="if":
                out=[pad+"if "+cond+" then"]+body
                if self.i<len(self.t) and self.t[self.i]=="else":
                    self.i+=1; other=self.statement(indent+1); out += [pad+"else"]+other
                return out+[pad+"end"]
            return [pad+"while "+cond+" do"]+body+[pad+"end"]
        if self.t[self.i] in ("switch","try","throw","synchronized"):
            raise ValueError("unsupported statement: "+self.t[self.i])
        if self.t[self.i]=="return":
            self.i+=1; e=self.take_expr({";"})
            if self.i<len(self.t): self.i+=1
            ternary=split_ternary(e)
            if ternary:
                condition,when_true,when_false=ternary
                if not condition or not when_true or not when_false:
                    raise ValueError("malformed return ternary expression")
                return [pad+"if "+expr(condition,self.r,self.w,self.c,self.cm)+" then",
                        pad+"    return "+expr(when_true,self.r,self.w,self.c,self.cm),
                        pad+"else",
                        pad+"    return "+expr(when_false,self.r,self.w,self.c,self.cm),
                        pad+"end"]
            return [pad+"return"+(" "+expr(e,self.r,self.w,self.c,self.cm) if e else "")]
        if self.t[self.i] in ("break","continue"):
            op=self.t[self.i]; self.i+=1
            if self.i<len(self.t) and self.t[self.i]==";": self.i+=1
            if op=="continue": raise ValueError("continue is unsupported")
            return [pad+"break"]
        e=self.take_expr({";"})
        if self.i<len(self.t): self.i+=1
        if not e: return []
        # Local declaration: primitive/simple reference type + one variable.
        raw=" ".join(e)
        decl=re.match(rf'^(?:final\s+)?({TYPE})\s+([A-Za-z_$]\w*)\s*(=\s*[\s\S]+)?$',raw)
        if decl:
            val=decl.group(3)
            return [pad+"local "+decl.group(2)+((" = "+expr(tokens(val[1:]),self.r,self.w,self.c,self.cm)) if val else "")]
        raw=expr(e,self.r,self.w,self.c,self.cm)
        raw=re.sub(r'\b([A-Za-z_$]\w*)\s*\+\+$',r'\1 = \1 + 1',raw)
        raw=re.sub(r'\b([A-Za-z_$]\w*)\s*--$',r'\1 = \1 - 1',raw)
        compound=re.fullmatch(r'([A-Za-z_$]\w*)\s*(\+=|-=|\*=|/=|%=)\s*(.+)',raw)
        if compound:
            op=compound.group(2)[0]
            raw=f"{compound.group(1)} = {compound.group(1)} {op} {compound.group(3)}"
        return [pad+raw]

def split_ternary(ts):
    """Split one top-level Java conditional expression without eager branch evaluation."""
    depth=0; question=-1; colon=-1
    for i, token in enumerate(ts):
        if token in ("(", "["): depth += 1
        elif token in (")", "]"): depth -= 1
        elif depth == 0:
            if token == "?":
                if question >= 0: return None
                question = i
            elif token == ":" and question >= 0:
                colon = i
                break
    if question <= 0 or colon <= question + 1 or colon >= len(ts) - 1:
        return None
    if "?" in ts[:question] or "?" in ts[question + 1:colon] or "?" in ts[colon + 1:]:
        return None
    return ts[:question], ts[question + 1:colon], ts[colon + 1:]


def has_only_return_ternaries(body_tokens):
    """Allow one top-level ternary in each return expression, including nested blocks."""
    i=0
    while i<len(body_tokens):
        if body_tokens[i]=="?":
            return False
        if body_tokens[i]=="return":
            end=i+1; depth=0
            while end<len(body_tokens):
                token=body_tokens[end]
                if token in ("(","["): depth+=1
                elif token in (")","]"): depth-=1
                if token==";" and depth==0: break
                if token in ("{","}") and depth==0: break
                end+=1
            expression=body_tokens[i+1:end]
            if "?" in expression and not split_ternary(expression):
                return False
            i=end+1 if end<len(body_tokens) and body_tokens[end]==";" else end
        else:
            i+=1
    return True


def is_single_return_ternary(body_tokens):
    if not body_tokens or body_tokens[0] != "return":
        return False
    expression = body_tokens[1:-1] if body_tokens[-1] == ";" else body_tokens[1:]
    if not expression or any(token in (";", "{", "}") for token in expression):
        return False
    return split_ternary(expression) is not None


def validate_method_tokens(bt, where):
    joined = " ".join(bt)
    if "super" in bt:
        raise ValueError("super calls require Java inheritance and virtual dispatch")
    if "new" in bt:
        idx = bt.index("new")
        target = bt[idx + 1] if idx + 1 < len(bt) else "object"
        raise ValueError("object construction requires an explicit constructor adapter: " + target)
    if "->" in bt or "::" in bt:
        raise ValueError("lambda/method reference requires a functional-interface adapter")
    if "?" in bt and not has_only_return_ternaries(bt):
        raise ValueError("ternary conditional operator is supported only as one top-level return expression")
    if re.search(r'\(\s*(?:byte|short|int|long|float|double|char)\s*\)', joined):
        raise ValueError("primitive casts require Java narrowing/overflow semantics")
    for i, token in enumerate(bt):
        if token == "Mth" and i + 2 < len(bt) and bt[i + 1] == ".":
            method = bt[i + 2]
            if method not in MTH and method not in MTH_CONSTANTS:
                raise ValueError("unadapted Minecraft Mth API: " + method)
        if token == "Math" and i + 2 < len(bt) and bt[i + 1] == ".":
            method = bt[i + 2]
            if method not in MATH and method not in {"PI", "E"}:
                raise ValueError("unadapted Java Math API: " + method)
        if token == "Util":
            if i + 2 >= len(bt) or bt[i + 1] != "." or bt[i + 2] != "getRandom":
                raise ValueError("unadapted Minecraft Util API")
        if token in ENGINE_API_TYPES:
            raise ValueError("unadapted Minecraft engine type/API: " + token)
        if i > 0 and bt[i - 1] == "." and token in ENGINE_API_METHODS:
            raise ValueError("unadapted Minecraft engine method: " + token)

def split_args(source):
    if not source.strip(): return []
    out=[]; cur=[]; depth=0
    for x in tokens(source):
        if x in ("(","[","<"): depth+=1
        elif x in (")","]",">"): depth-=1
        if x=="," and depth==0: out.append(cur); cur=[]
        else: cur.append(x)
    if cur: out.append(cur)
    return out

def translate_file(path, root, outroot, report, strict):
    source=path.read_text(encoding="utf-8")
    pkg=re.search(r'\bpackage\s+([\w.]+)\s*;',source)
    package=pkg.group(1) if pkg else ""
    cls=re.search(r'(?m)(?:^[ \t]*|;[ \t]*)(?:(?:public|protected|private)\s+)?(?:(?:final|abstract|static)\s+)*class\s+(\w+)',source)
    if not cls:
        report["skipped_files"].append({"file":str(path),"reason":"no top-level class"})
        return
    name=cls.group(1)
    imports=re.findall(r'\bimport\s+static\s+[\w.]+\.(\w+)\s*;',source)
    class_imports=re.findall(r'\bimport\s+([\w.]+)\s*;',source)
    report["files_seen"].append(str(path))
    lines=[f"-- Generated from {package+'.' if package else ''}{name}; edit Java source, not this file.",
           "local MC = require('mc_compat')", f"local {name} = {{}}"]
    for imp in class_imports:
        if imp.startswith("java.") or imp == "net.minecraft.util.Mth": continue
        short=imp.rsplit(".",1)[-1]
        if imp in IMPORT_ADAPTERS:
            lines.append(f"local {short} = {IMPORT_ADAPTERS[imp]}")
        elif short!=name:
            lines.append(f"local {short} = require('{imp.replace('.','/')}')")
    # top-level fields and methods are selected from the class body.
    brace=source.find("{",cls.end())
    if brace<0: return
    body_start=brace+1; depth=1; i=body_start; quote=None; esc=False
    while i<len(source) and depth:
        c=source[i]
        if quote:
            if esc: esc=False
            elif c=="\\": esc=True
            elif c==quote: quote=None
        elif c in ("'",'"'): quote=c
        elif c=="{": depth+=1
        elif c=="}": depth-=1
        i+=1
    class_body=source[body_start:i-1]
    # Fields: only static final, single primitive/String initializer.
    field_re=re.compile(rf'\b(?:public|protected|private)?\s*(?:static\s+)?final\s+({TYPE})\s+(\w+)\s*=\s*([^;]+);')
    field_names=set()
    for f in field_re.finditer(class_body):
        typ,var,val=f.groups()
        if "static" not in f.group(0): continue
        field_names.add(var)
        lines.append(f"{name}.{var} = {expr(tokens(val),report,name+'.'+var)}")
    # Methods. Non-static instance methods become colon methods and receive self.
    meth_re=re.compile(rf'((?:(?:public|protected|private|static|final|synchronized|native|abstract)\s+)*)({RETURN_TYPE}|void)\s+(\w+)\s*\(([^)]*)\)\s*(?:throws\s+[\w.,\s]+)?\{{')
    method_matches=list(meth_re.finditer(class_body))
    class_methods={item.group(3) for item in method_matches}
    cursor=0; methods=0
    for m in method_matches:
        flags,ret,mname,args=m.groups()
        start=m.end(); d=1; j=start; q=None; e=False
        while j<len(class_body) and d:
            c=class_body[j]
            if q:
                if e: e=False
                elif c=="\\": e=True
                elif c==q: q=None
            elif c in ("'",'"'): q=c
            elif c=="{": d+=1
            elif c=="}": d-=1
            j+=1
        body=class_body[start:j-1]
        argspec=[]; badarg=False
        for a in split_args(args):
            aa=" ".join(a)
            am=re.match(rf'^(?:final\s+)?({TYPE})\s+(\w+)$',aa)
            if not am: badarg=True; break
            argspec.append(am.group(2))
        if badarg:
            report["skipped_methods"].append({"class":name,"method":mname,"reason":"unsupported parameter declaration"}); continue
        try:
            bt=tokens(body)
            validate_method_tokens(bt, name+"."+mname)
            if "switch" in bt:
                raise ValueError("switch statement is unsupported")
            lua=Body(bt,report,name+"."+mname,name,class_methods)
            translated=[]
            while lua.i<len(lua.t): translated+=lua.statement(1)
            for field_name in field_names:
                translated=[re.sub(rf'\b{re.escape(field_name)}\b',f'{name}.{field_name}',line) for line in translated]
            if not any(x.strip() for x in translated): translated=["    -- empty"]
        except Exception as ex:
            report["skipped_methods"].append({"class":name,"method":mname,"reason":str(ex)})
            continue
        is_static="static" in flags.split()
        args_lua=", ".join(argspec)
        if is_static:
            lines.append(f"function {name}.{mname}({args_lua})")
        else:
            lines.append(f"function {name}:{mname}({args_lua})")
        lines.extend(translated); lines.append("end"); methods+=1
        report["translated_methods"]+=1
        report["translated_method_details"].append({"class":(package+"." if package else "")+name,"method":mname,"signature":f"{ret} {mname}({args})"})
    if methods==0:
        report["skipped_files"].append({"file":str(path),"reason":"no supported methods"})
    lines.append("return "+name)
    dest=outroot/(package.replace(".","/") if package else "")/(name+".lua")
    dest.parent.mkdir(parents=True,exist_ok=True); dest.write_text("\n".join(lines)+"\n",encoding="utf-8")
    report["generated_modules"].append(dest.relative_to(outroot).as_posix())

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--input",required=True,type=Path); p.add_argument("--output",required=True,type=Path)
    p.add_argument("--class",dest="classes",action="append",default=[])
    p.add_argument("--version",default="unspecified"); p.add_argument("--strict",action="store_true")
    p.add_argument("--report",type=Path)
    a=p.parse_args()
    if not a.input.is_dir(): p.error("--input must be a directory containing Java source files")
    report={"minecraft_source_version":a.version,"files_seen":[],"generated_modules":[],
            "translated_methods":0,"translated_method_details":[],"skipped_methods":[],"skipped_files":[],"warnings":[]}
    paths=sorted(a.input.rglob("*.java"))
    if a.classes:
        wanted=set(a.classes)
        paths=[f for f in paths if f.stem in wanted or f.relative_to(a.input).with_suffix("").as_posix().replace("/", ".") in wanted]
    for f in paths: translate_file(f,a.input,a.output,report,a.strict)
    report["strict_blockers"]=len(report["skipped_methods"])+len(report["skipped_files"])
    report["output_dir"]=str(a.output)
    target=a.report or (a.output/"transpile-report.json")
    target.parent.mkdir(parents=True,exist_ok=True); target.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,indent=2))
    if a.strict and report["strict_blockers"]: return 2
    return 0

if __name__=="__main__": sys.exit(main())
