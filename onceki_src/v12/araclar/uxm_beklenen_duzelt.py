# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, time
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ortak'))
from uxm_arac_cekirdek import read_text, write_text, _is_expect_meta_line

def duzelt_text(s: str) -> tuple[str,int]:
    changed=0; out=[]
    for line in (s or '').splitlines():
        if _is_expect_meta_line(line):
            changed += 1
            continue
        out.append(line)
    ns='\n'.join(out).strip('\r\n') + ('\n' if out else '')
    return ns, changed

def main(argv=None):
    ap=argparse.ArgumentParser(description='UXM .expect metaveri temizleyici')
    ap.add_argument('-p','--proje','--project','--root', default='.', help='Proje kökü')
    ap.add_argument('-d','--dizin','--dir', default='uxm/tests/all_expected_known', help='Expect aranacak dizin')
    ap.add_argument('-u','--uygula','--apply', action='store_true', help='Değişiklikleri uygula')
    ap.add_argument('-r','--recursive', action='store_true', default=True, help='Alt dizinleri tara')
    ap.add_argument('-o','--cikti','--out', default='beklenen_duzeltme_raporlari', help='Rapor klasörü')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); d=root/args.dizin
    files=sorted(d.rglob('*.expect')) if args.recursive else sorted(d.glob('*.expect'))
    stamp=time.strftime('%Y%m%d_%H%M%S'); rep=root/args.cikti/stamp; rep.mkdir(parents=True, exist_ok=True)
    rows=[]; total_lines=0; changed_files=0
    for p in files:
        old=read_text(p); new, cnt=duzelt_text(old)
        if cnt:
            changed_files += 1; total_lines += cnt
            if args.uygula:
                backup=rep/'yedekler'/p.relative_to(root)
                write_text(backup, old)
                write_text(p, new)
        rows.append({'dosya':str(p.relative_to(root)),'silinen_meta_satir':cnt,'degisti':bool(cnt)})
    csvp=rep/'beklenen_duzeltme.csv'
    with csvp.open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['dosya','silinen_meta_satir','degisti']); wr.writeheader(); wr.writerows(rows)
    print(f'[BEKLENEN_DUZELT] dosya={len(files)} degisecek={changed_files} silinecek_meta_satir={total_lines} uygula={args.uygula}')
    print(f'[BEKLENEN_DUZELT] rapor={rep}')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
