#!/usr/bin/env python3
"""Conservative Java-subset to Lua 5.4 transpiler for SteveCraft.

This is not a Java VM or a whole-Minecraft decompiler. Unsupported members are
reported and omitted; strict mode turns those omissions into a failed build.
"""
from __future__ import annotations
import argparse, json, re, sys
from pathlib import Path

TOKEN = re.compile(r'''//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[0-7_]+|(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?[fFdD]?|\d+[lL]?|[A-Za-z_$][\w$]*|>>>=|<<=|>>=|==|!=|<=|>=|&&|\|\||\+\+|--|\+=|-=|\*=|/=|%=|<<|>>>|>>|->|[{}()\[\];,.?:+\-*/%<>=!&|^~]''')
TYPE = r'(?:byte|short|int|long|float|double|boolean|char|String|[\w$.]+(?:\[\])?)'

MATH = {"abs":"math.abs","sqrt":"math.sqrt","sin":"math.sin","cos":"math.cos",
        "tan":"math.tan","floor":"math.floor","ceil":"math.ceil",
        "min":"math.min","max":"math.max","pow":"math.pow"}
MTH = {"abs":"math.abs","sqrt":"math.sqrt","sin":"math.sin","cos":"math.cos",
       "floor":"math.floor","ceil":"math.ceil","clamp":"MC.Mth.clamp",
       "lerp":"MC.Mth.lerp","sign":"MC.Mth.sign","wrapDegrees":"MC.Mth.wrapDegrees",
       "fastFloor":"MC.Mth.fastFloor","absMax":"MC.Mth.absMax"}

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

def expr(ts, report, where):
    s=" ".join(ts)
    s=re.sub(r'\b(?:true|false|null)\b',lambda m:{"true":"true","false":"false","null":"nil"}[m.group()],s)
    s=re.sub(r'\bthis\s*\.\s*','self.',s)
    s=re.sub(r'\bMath\s*\.\s*(\w+)',lambda m:MATH.get(m.group(1),"math."+m.group(1)),s)
    s=re.sub(r'\bMth\s*\.\s*(\w+)',lambda m:MTH.get(m.group(1),"MC.Mth."+m.group(1)),s)
    s=s.replace("&&"," and ").replace("||"," or ")
    s=re.sub(r'(?<![=!<>])!(?!=)'," not ",s)
    s=re.sub(r'\b(\d[\d_]*)([lL])\b',r'\1',s)
    s=re.sub(r'\b0[xX]([0-9a-fA-F_]+)\b',lambda m:str(int(m.group(1).replace("_",""),16)),s)
    s=re.sub(r'\b0[bB]([01_]+)\b',lambda m:str(int(m.group(1).replace("_",""),2)),s)
    s=re.sub(r'\b0([0-7_]+)\b',lambda m:str(int(m.group(1).replace("_",""),8)),s)
    s=re.sub(r'\b(\d[\d_]*)[fFdD]\b',r'\1',s)
    s=re.sub(r'\s+', ' ', s).strip()
    if re.search(r'\b(?:byte|short|int|long|float|double)\s*\)'," ".join(ts)):
        report["warnings"].append(f"{where}: primitive cast erased; Java overflow/narrowing is not exact")
    if "/" in ts:
        report["warnings"].append(f"{where}: division uses Lua number semantics, not Java integer division")
    return s

class Body:
    def __init__(self, ts, report, where):
        self.t=ts; self.i=0; self.r=report; self.w=where
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
                init=" ".join(chunks[0]); cond=expr(chunks[1],self.r,self.w); step=" ".join(chunks[2])
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
            cond=expr(inside,self.r,self.w); body=self.statement(indent+1)
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
            return [pad+"return"+(" "+expr(e,self.r,self.w) if e else "")]
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
            return [pad+"local "+decl.group(2)+((" = "+expr(tokens(val[1:]),self.r,self.w)) if val else "")]
        raw=expr(e,self.r,self.w)
        raw=re.sub(r'\b([A-Za-z_$]\w*)\s*\+\+$',r'\1 = \1 + 1',raw)
        raw=re.sub(r'\b([A-Za-z_$]\w*)\s*--$',r'\1 = \1 - 1',raw)
        compound=re.fullmatch(r'([A-Za-z_$]\w*)\s*(\+=|-=|\*=|/=|%=)\s*(.+)',raw)
        if compound:
            op=compound.group(2)[0]
            raw=f"{compound.group(1)} = {compound.group(1)} {op} {compound.group(3)}"
        return [pad+raw]

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
    cls=re.search(r'\b(?:public\s+|final\s+|abstract\s+)*class\s+(\w+)',source)
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
        if imp.startswith("java.lang.") or imp == "net.minecraft.util.Mth": continue
        short=imp.rsplit(".",1)[-1]
        if short!=name: lines.append(f"local {short} = require('{imp.replace('.','/')}')")
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
    meth_re=re.compile(rf'((?:(?:public|protected|private|static|final|synchronized|native|abstract)\s+)*)({TYPE}|void)\s+(\w+)\s*\(([^)]*)\)\s*(?:throws\s+[\w.,\s]+)?\{{')
    cursor=0; methods=0
    for m in meth_re.finditer(class_body):
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
            lua=Body(bt,report,name+"."+mname)
            translated=[]
            while lua.i<len(lua.t): translated+=lua.statement(1)
            if any("switch" in x or "->" in x for x in bt): raise ValueError("switch/lambda syntax unsupported")
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
            "translated_methods":0,"skipped_methods":[],"skipped_files":[],"warnings":[]}
    paths=sorted(a.input.rglob("*.java"))
    if a.classes:
        wanted=set(a.classes); paths=[f for f in paths if any((f.stem==x or str(f).replace("/",".").endswith(x.replace(".","/")+".java")) for x in wanted)]
    for f in paths: translate_file(f,a.input,a.output,report,a.strict)
    report["strict_blockers"]=len(report["skipped_methods"])+len(report["skipped_files"])
    report["output_dir"]=str(a.output)
    target=a.report or (a.output/"transpile-report.json")
    target.parent.mkdir(parents=True,exist_ok=True); target.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,indent=2))
    if a.strict and report["strict_blockers"]: return 2
    return 0

if __name__=="__main__": sys.exit(main())
