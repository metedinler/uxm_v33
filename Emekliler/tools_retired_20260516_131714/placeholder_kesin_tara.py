#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""UXM kesin placeholder denetimi.
Kaynak kodda yalandan işlev, TODO, dummy, placeholder veya yanlışlıkla geçerli görünen reserved izlerini bulur.
List/dict/set kılavuz örneği olduğu için UXM core denetimine dahil edilmez.
"""
from __future__ import annotations
import argparse, csv, re, sys
from pathlib import Path

PATTERNS = [
    ("PLACEHOLDER", re.compile(r"placeholder", re.I)),
    ("TODO", re.compile(r"\bTODO\b", re.I)),
    ("DUMMY", re.compile(r"\bdummy\b", re.I)),
    ("STUB", re.compile(r"\bstub\b", re.I)),
    ("FAKE", re.compile(r"\bfake\b|sahte|yalandan", re.I)),
    ("NOT_IMPLEMENTED", re.compile(r"not implemented|notimplemented|uygulanmad", re.I)),
]
ALLOW = [
    re.compile(r"intentionally keeps host-level placeholders", re.I),
    re.compile(r"Fractional inverse is reserved", re.I),
    re.compile(r"reserved alan", re.I),
]
EXTS = {'.bas','.bi','.inc','.py','.bat','.md','.csv'}

def allowed(line:str)->bool:
    return any(p.search(line) for p in ALLOW)

def main():
    ap=argparse.ArgumentParser(description='UXM kesin placeholder/dummy/TODO denetimi')
    ap.add_argument('--kok','--root',dest='root',default='.',help='Proje kökü')
    ap.add_argument('--cikti','--out',dest='out',default='placeholder_kesin_rapor.csv',help='CSV çıktı')
    ap.add_argument('--kapi','--gate',action='store_true',help='Bulgu varsa hata kodu 2 döndür')
    args=ap.parse_args()
    root=Path(args.root).resolve()
    rows=[]
    for base in [root/'uxm'/'core', root/'araclar', root/'tool_en']:
        if not base.exists(): continue
        for p in base.rglob('*'):
            if not p.is_file() or p.suffix.lower() not in EXTS: continue
            try: txt=p.read_text(encoding='utf-8', errors='ignore').splitlines()
            except Exception: continue
            for no,line in enumerate(txt,1):
                if allowed(line): continue
                for kind,pat in PATTERNS:
                    if pat.search(line):
                        rows.append({'tur':kind,'dosya':str(p.relative_to(root)),'satir':no,'metin':line.strip()[:300]})
    out=Path(args.out)
    if not out.is_absolute(): out=root/out
    out.parent.mkdir(parents=True,exist_ok=True)
    with out.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['tur','dosya','satir','metin']); w.writeheader(); w.writerows(rows)
    print(f'[PLACEHOLDER_DENETIM] bulgu={len(rows)} rapor={out}')
    if rows and args.kapi: return 2
    return 0
if __name__=='__main__': raise SystemExit(main())
