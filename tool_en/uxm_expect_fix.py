# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, time, re
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ortak'))
from uxm_arac_cekirdek import read_text, write_text, _is_expect_meta_line, _strip_inline_expect_prefix

def duzelt_text(s: str) -> tuple[str,int,int]:
    """.expect dosyasını temizler.
    - Salt meta satırlarını siler.
    - #source:embedded_EXPECT_OUTPUT7 gibi satırları 7 yapar.
    """
    silinen=0; inline=0; out=[]
    for line in (s or '').splitlines():
        if _is_expect_meta_line(line):
            silinen += 1
            continue
        cleaned, changed = _strip_inline_expect_prefix(line)
        if changed: inline += 1
        out.append(cleaned)
    ns='\n'.join(out).strip('\r\n') + ('\n' if out else '')
    return ns, silinen, inline

def main(argv=None):
    ap=argparse.ArgumentParser(description='UXM .expect metadata cleaner')
    ap.add_argument('-p','--proje','--project','--root', default='.', help='Project root')
    ap.add_argument('-d','--dizin','--dir', default='uxm/tests/all_expected_known', help='Directory to scan')
    ap.add_argument('-a','--ara','--contains', default='', help='Only .expect files whose path/text contains this phrase')
    ap.add_argument('-u','--uygula','--apply', action='store_true', help='Apply changes')
    ap.add_argument('-r','--recursive', action='store_true', default=True, help='Scan subdirectories')
    ap.add_argument('-o','--cikti','--out', default='beklenen_duzeltme_raporlari', help='Report folder')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); d=root/args.dizin
    files=sorted(d.rglob('*.expect')) if args.recursive else sorted(d.glob('*.expect'))
    if args.ara:
        q=args.ara.lower()
        files=[p for p in files if q in str(p.relative_to(root)).lower() or q in read_text(p).lower()]
    stamp=time.strftime('%Y%m%d_%H%M%S'); rep=root/args.cikti/stamp; rep.mkdir(parents=True, exist_ok=True)
    rows=[]; total_del=0; total_inline=0; changed_files=0
    for p in files:
        old=read_text(p); new, silinen, inline=duzelt_text(old)
        changed=(new != old)
        if changed:
            changed_files += 1; total_del += silinen; total_inline += inline
            if args.uygula:
                backup=rep/'yedekler'/p.relative_to(root)
                write_text(backup, old)
                write_text(p, new)
        rows.append({'dosya':str(p.relative_to(root)),'silinen_meta_satir':silinen,'inline_prefix_duzeltme':inline,'degisti':changed})
    csvp=rep/'beklenen_duzeltme.csv'
    with csvp.open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['dosya','silinen_meta_satir','inline_prefix_duzeltme','degisti']); wr.writeheader(); wr.writerows(rows)
    print(f'[BEKLENEN_DUZELT] dosya={len(files)} degisecek={changed_files} silinecek_meta_satir={total_del} inline_duzeltme={total_inline} uygula={args.uygula}')
    print(f'[BEKLENEN_DUZELT] rapor={rep}')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
