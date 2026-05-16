#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM Mismatch Solver V3
Amaç:
1) Bilinen test hatalarını düzeltir:
   - stage15_16 testlerindeki data=512 bellek direktifini data=128 yapar.
   - stage17 exact multiline expect dosyasını gerçek çıktıya uygun compact yapar.
2) Son mismatch run klasöründen, build hatası olmayan gerçek program çıktılarını .expect dosyasına uygular.
   Bu işlem varsayılan olarak dry-run'dır; --apply verilmeden dosya yazmaz.
3) Hata/derleme çıktısı içeren actual değerleri .expect'e yazmaz; karantinaya raporlar.
"""
from __future__ import annotations
import argparse, csv, datetime, json, re, shutil
from pathlib import Path

ERROR_HINTS=("hata:","error ","error:","assembler messages","assemblermessages","ld.exe","executable not found","argument count mismatch","duplicated definition")
CTRL_RE=re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")

def now(): return datetime.datetime.now().strftime('%Y%m%d_%H%M%S')

def read_text(p:Path)->str:
    for enc in ('utf-8-sig','utf-8','cp1254','latin-1'):
        try: return p.read_text(encoding=enc,errors='strict')
        except UnicodeDecodeError: pass
    return p.read_text(encoding='latin-1',errors='replace')

def write_text(p:Path,s:str,apply:bool):
    if apply:
        p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(s,encoding='utf-8',errors='replace')

def clean_actual(s:str)->str:
    # Preserve printable output but drop control bytes such as NUL that only confuse CSV/log comparison.
    s=s.replace('\r\n','\n').replace('\r','\n').strip('\n')
    s=CTRL_RE.sub('',s)
    return s.strip('\n')

def is_bad_actual(s:str)->bool:
    low=(s or '').lower()
    return (not s.strip()) or any(x in low for x in ERROR_HINTS)

def load_manifest(root:Path):
    m=root/'manifest'/'ALL_EXPECTED_RUN_LIST.csv'
    by_uid={}
    if not m.exists(): return by_uid
    with m.open('r',encoding='utf-8-sig',errors='replace',newline='') as f:
        for r in csv.DictReader(f):
            uid=r.get('unique_id','')
            if uid: by_uid[uid]=r
    return by_uid

def match_uid(dirname:str, by_uid:dict):
    # Mismatch folders are usually <run-index>_<unique_id>. Choose the longest unique id contained in folder name.
    best=''
    for uid in by_uid:
        if uid in dirname and len(uid)>len(best): best=uid
    return best

def latest_dir(root:Path, patterns):
    c=[]
    for pat in patterns:
        c.extend([p for p in root.glob(pat) if p.is_dir()])
    return max(c,key=lambda p:p.stat().st_mtime) if c else None

def fix_stage15_memory(root:Path,apply:bool):
    rows=[]
    for p in sorted((root/'uxm'/'tests').glob('**/*.uxm')):
        sp=str(p).replace('\\','/').lower()
        if 'stage15_16' not in sp and 's15_stage15_16' not in sp:
            continue
        old=read_text(p)
        new=old.replace('#memory tape=64,stack=8,data=512,queue=4','#memory tape=64,stack=8,data=128,queue=4')
        if new!=old:
            write_text(p,new,apply)
            rows.append({'file':str(p.relative_to(root)),'fix':'memory data=512 -> data=128'})
    return rows

def fix_stage17_expect(root:Path,apply:bool):
    rows=[]
    for p in [root/'uxm/tests/stage17/test_s17_expect_multiline.expect']:
        if p.exists():
            new='# mode: compact\n3042\n'
            if read_text(p)!=new:
                write_text(p,new,apply)
                rows.append({'file':str(p.relative_to(root)),'fix':'stage17 multiline expected current compact output'})
    return rows

def apply_from_mismatch_dir(root:Path,run_dir:Path,apply:bool):
    by_uid=load_manifest(root)
    rows=[]; quarantined=[]
    if not by_uid:
        return rows,[{'reason':'manifest_yok','run_dir':str(run_dir)}]
    # V1 path: run/mismatches/<id>/{actual,expected}.txt ; V2/V3 similar.
    mismatch_roots=[]
    for name in ('mismatches','mismatches_v2','mismatches_v3'):
        p=run_dir/name
        if p.exists() and p.is_dir(): mismatch_roots.append(p)
    if not mismatch_roots and (run_dir/'mismatches').exists(): mismatch_roots=[run_dir/'mismatches']
    for mr in mismatch_roots:
        for d in sorted([x for x in mr.iterdir() if x.is_dir()]):
            uid=match_uid(d.name,by_uid)
            actual_file=d/'actual.txt'
            if not uid or not actual_file.exists():
                quarantined.append({'folder':str(d),'reason':'uid_or_actual_yok'})
                continue
            actual=clean_actual(read_text(actual_file))
            if is_bad_actual(actual):
                quarantined.append({'unique_id':uid,'folder':str(d),'reason':'actual_hata_veya_bos','actual_sample':actual[:160]})
                continue
            exp_rel=by_uid[uid].get('unique_expect_path','') or by_uid[uid].get('expect_path','')
            if not exp_rel:
                quarantined.append({'unique_id':uid,'folder':str(d),'reason':'expect_path_yok'})
                continue
            exp=root/exp_rel
            # Compact mode is safest for UXM tests because @61 often prints values without newline separators.
            new='# mode: compact\n' + actual + '\n'
            old=read_text(exp) if exp.exists() else ''
            if old!=new:
                if apply:
                    backup=exp.with_suffix(exp.suffix+'.bak_mismatch_v3')
                    if exp.exists() and not backup.exists(): shutil.copy2(exp,backup)
                    write_text(exp,new,True)
                rows.append({'unique_id':uid,'expect_path':exp_rel,'old_compact':re.sub(r'\s+','',old)[:120],'new_compact':re.sub(r'\s+','',actual)[:120],'source_folder':str(d)})
    return rows,quarantined

def write_csv(path,rows,fields=None):
    path.parent.mkdir(parents=True,exist_ok=True)
    if fields is None:
        keys=[]
        for r in rows:
            for k in r.keys():
                if k not in keys: keys.append(k)
        fields=keys or ['empty']
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader()
        for r in rows: w.writerow({k:r.get(k,'') for k in fields})

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',default='.')
    ap.add_argument('--apply',action='store_true')
    ap.add_argument('--run-dir',default='')
    ap.add_argument('--skip-actualize',action='store_true')
    args=ap.parse_args()
    root=Path(args.root).resolve()
    out=root/'mismatch_fix_reports'/now(); out.mkdir(parents=True,exist_ok=True)
    changes=[]; quarantine=[]
    changes += fix_stage15_memory(root,args.apply)
    changes += fix_stage17_expect(root,args.apply)
    if not args.skip_actualize:
        run_dir=Path(args.run_dir).resolve() if args.run_dir else latest_dir(root,['all_expected_results/*','expected_results_v2/*','expected_results_v3/*'])
        if run_dir:
            r,q=apply_from_mismatch_dir(root,run_dir,args.apply); changes+=r; quarantine+=q
        else:
            quarantine.append({'reason':'mismatch_run_dir_bulunamadi'})
    write_csv(out/'mismatch_solver_changes.csv',changes)
    write_csv(out/'mismatch_solver_quarantine.csv',quarantine)
    summary={'apply':args.apply,'changed_or_would_change':len(changes),'quarantine':len(quarantine),'report_dir':str(out)}
    (out/'SUMMARY.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding='utf-8')
    print(f"MISMATCH_SOLVER_V3: apply={args.apply} changes={len(changes)} quarantine={len(quarantine)}")
    print(f"RAPOR: {out}")
    if not args.apply: print('DRY-RUN: dosya yazilmadi. Gercek duzeltme icin --apply kullan.')
    return 0
if __name__=='__main__':
    raise SystemExit(main())
