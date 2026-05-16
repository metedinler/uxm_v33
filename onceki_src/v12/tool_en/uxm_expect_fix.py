# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, time
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ortak'))
from uxm_arac_cekirdek import read_text, write_text, _is_expect_meta_line

def fix_text(s: str) -> tuple[str,int]:
    changed=0; out=[]
    for line in (s or '').splitlines():
        if _is_expect_meta_line(line):
            changed += 1
            continue
        out.append(line)
    ns='\n'.join(out).strip('\r\n') + ('\n' if out else '')
    return ns, changed

def main(argv=None):
    ap=argparse.ArgumentParser(description='UXM .expect metadata cleaner')
    ap.add_argument('-p','--project','--root', default='.', help='Project root')
    ap.add_argument('-d','--dir', default='uxm/tests/all_expected_known', help='Directory to scan for .expect files')
    ap.add_argument('-u','--apply', action='store_true', help='Apply changes')
    ap.add_argument('-r','--recursive', action='store_true', default=True, help='Scan subdirectories')
    ap.add_argument('-o','--out', default='expect_fix_reports', help='Report folder')
    args=ap.parse_args(argv)
    root=Path(args.project).resolve(); d=root/args.dir
    files=sorted(d.rglob('*.expect')) if args.recursive else sorted(d.glob('*.expect'))
    stamp=time.strftime('%Y%m%d_%H%M%S'); rep=root/args.out/stamp; rep.mkdir(parents=True, exist_ok=True)
    rows=[]; total_lines=0; changed_files=0
    for p in files:
        old=read_text(p); new, cnt=fix_text(old)
        if cnt:
            changed_files += 1; total_lines += cnt
            if args.apply:
                backup=rep/'backups'/p.relative_to(root)
                write_text(backup, old)
                write_text(p, new)
        rows.append({'file':str(p.relative_to(root)),'metadata_lines_removed':cnt,'changed':bool(cnt)})
    csvp=rep/'expect_fix.csv'
    with csvp.open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['file','metadata_lines_removed','changed']); wr.writeheader(); wr.writerows(rows)
    print(f'[EXPECT_FIX] files={len(files)} changed_files={changed_files} metadata_lines={total_lines} apply={args.apply}')
    print(f'[EXPECT_FIX] report={rep}')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
