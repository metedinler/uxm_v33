#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""UXM placeholder/TODO/dummy denetleyici.
Release kapısında sıfır yalan hedefi için kullanılır. Kod, registry ve docs içinde kalan
placeholder/TODO/dummy/stub/reserved/planned izlerini CSV ve Markdown olarak raporlar.
"""
import argparse, csv, re, sys
from pathlib import Path
PATTERNS=[r'placeholder',r'TODO',r'dummy',r'stub',r'not implemented',r'planned',r'reserved',r'taslak',r'planlandı',r'geçici']
RX=re.compile('|'.join(PATTERNS), re.I)
SKIP={'.zip','.exe','.obj','.o','.dll','.png','.jpg','.xlsx'}
def main():
    ap=argparse.ArgumentParser(description='UXM placeholder/TODO/dummy taraması')
    ap.add_argument('--kok','--root',default='.',dest='root')
    ap.add_argument('--cikti','--out',default='placeholder_raporu',dest='out')
    ap.add_argument('--hata-ver','--fail',action='store_true',dest='fail')
    ns=ap.parse_args()
    root=Path(ns.root)
    out=Path(ns.out); out.mkdir(parents=True, exist_ok=True)
    rows=[]
    ignored_dirs={'Emekliler','build','sonuclar_tum','sonuclar_hatali','expected_results_v2','expected_results_v3','expected_results_v4','expected_results_v5'}
    for p in root.rglob('*'):
        if not p.is_file() or p.suffix.lower() in SKIP:
            continue
        if any(part in ignored_dirs for part in p.parts):
            continue
        try:
            txt=p.read_text(encoding='utf-8', errors='replace')
        except Exception:
            continue
        for i,line in enumerate(txt.splitlines(),1):
            if RX.search(line):
                rows.append({'dosya':str(p.relative_to(root)),'satir':i,'metin':line.strip()[:300]})
    csvp=out/'placeholder_taramasi.csv'
    with csvp.open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f, fieldnames=['dosya','satir','metin'])
        w.writeheader(); w.writerows(rows)
    md=out/'PLACEHOLDER_RAPORU.md'
    md.write_text(f'# UXM Placeholder/TODO/Dummy Raporu\n\nToplam bulgu: {len(rows)}\n\nCSV: `{csvp}`\n', encoding='utf-8')
    print(f'[PLACEHOLDER_TARA] bulgu={len(rows)} rapor={md}')
    if ns.fail and rows:
        return 1
    return 0
if __name__=='__main__':
    sys.exit(main())
