#!/usr/bin/env python3
"""Validate and convert already-extracted SFF PNG frames + AIR timing to MugenActor manifests.

Usage:
 python tools/alpha_mugen_import.py --extracted path/to/sffcli/output --air Naruto.air --pack sasuke_base --out project/assets/mugen
Optional: --chromakey ff00ff --allow-missing
The binary SFF should first be extracted by a SFF v1/v2 extractor (e.g. sffcli -x).
Never claim the original MUGEN animation has been preserved unless all AIR references resolve.
"""
from __future__ import annotations
import argparse
import json
import re
import shutil
import sys
from pathlib import Path

RE_BEGIN=re.compile(r"^\[\s*Begin\s+Action\s+(\d+)\s*\]",re.I)
RE_FRAME=re.compile(r"^\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)(.*)")
RE_PNG=re.compile(r"(?:^|[\s_.(-])(\d{1,5})[\s_,.)-]+(\d{1,5})\.png$",re.I)
REQUIRED={"0","20","21","40","41","42","43","100","200","5000"}
def frames_from_air(path:Path):
    actions={}
    active=None
    for raw in path.read_text(encoding="latin-1",errors="replace").splitlines():
        s=raw.split(";")[0].strip()
        m=RE_BEGIN.match(s)
        if m:
            active=m.group(1);actions[active]=[];continue
        if active is None or not s or s.startswith("["):continue
        n=RE_FRAME.match(s)
        if not n:continue
        group,img,x,y,ticks=[int(n.group(i)) for i in range(1,6)]
        suffix=n.group(6).upper()
        actions[active].append({"key":f"{group}_{img}","x":x,"y":y,
                               "ticks":max(1,ticks if ticks!=-1 else 6),
                               "flip_h":"H" in suffix,"flip_v":"V" in suffix})
    return {k:v for k,v in actions.items() if v}
def inventory(folder:Path):
    found={}
    for f in sorted(folder.rglob("*")):
        if not f.is_file() or f.suffix.lower()!=".png":continue
        m=RE_PNG.search(f.name)
        if m:
            key=f"{int(m.group(1))}_{int(m.group(2))}"
            found.setdefault(key,f)
    return found
def dimensions(f:Path):
    # PNG IHDR allows dimensions without requiring Pillow.
    raw=f.open("rb").read(24)
    if len(raw)<24 or raw[:8]!=b"\x89PNG\r\n\x1a\n":raise ValueError(f"Not PNG: {f}")
    return int.from_bytes(raw[16:20],"big"),int.from_bytes(raw[20:24],"big")
def install(extracted:Path,air:Path,pack_name:str,out:Path,allow_missing=False):
    acts=frames_from_air(air)
    found=inventory(extracted)
    required=set()
    for frames in acts.values():
        required.update(f["key"] for f in frames)
    absent=sorted(required-set(found))
    essential=sorted(REQUIRED-set(acts))
    dest=out/pack_name
    if absent and not allow_missing:raise RuntimeError(f"{len(absent)} missing AIR sprites, examples: {absent[:20]}")
    if essential and not allow_missing:raise RuntimeError(f"Missing essential actions: {essential}")
    if not acts:raise RuntimeError("No AIR actions parsed")
    dest.mkdir(parents=True,exist_ok=True)
    sprites={}
    for key in sorted(required&set(found)):
        png=found[key]
        w,h=dimensions(png)
        if w<3 or h<3 or w>4096 or h>4096:raise ValueError(f"Unexpected frame size {png}: {w}x{h}")
        dst=f"{key}.png"
        shutil.copy2(png,dest/dst)
        sprites[key]={"file":dst,"axis":[w//2,h-1],"size":[w,h]}
    actions={}
    for action,frames in acts.items():
        usable=[f for f in frames if f["key"] in sprites]
        if usable:actions[action]=usable
    if "0" not in actions:raise RuntimeError("Missing usable standing action 0")
    report={
      "pack":pack_name,"air_actions":len(acts),"active_actions":len(actions),
      "unique_sprites":len(sprites),"referenced_sprites":len(required),
      "missing_frames":absent,"missing_core_actions":essential,
      "warning":"Default axis is bottom-center until SFF offsets or atlas metadata are verified. Verify each frame in-game."
    }
    (dest/"manifest.json").write_text(json.dumps({"display_scale":1.3333333,"sprites":sprites,"actions":actions},indent=2,ensure_ascii=False),encoding="utf-8")
    (dest/"IMPORT_QA.json").write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding="utf-8")
    print(json.dumps(report,indent=2,ensure_ascii=False))
    return not absent and not essential

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--extracted",type=Path,required=True)
    p.add_argument("--air",type=Path,required=True)
    p.add_argument("--pack",required=True)
    p.add_argument("--out",type=Path,default=Path("project/assets/mugen"))
    p.add_argument("--allow-missing",action="store_true")
    args=p.parse_args()
    if not args.extracted.is_dir() or not args.air.is_file():p.error("Missing SFF exported directory or AIR file")
    ok=install(args.extracted,args.air,args.pack,args.out,args.allow_missing)
    if not ok:print("WARNING: partial import (not release-quality)",file=sys.stderr)
if __name__=="__main__":main()
