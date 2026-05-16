#!/usr/bin/env python3
import argparse, csv, datetime, os, re, subprocess, time
from pathlib import Path
TOOL_PREFIXES=('ASM uretildi:','[V3.','NASM:','nasm ','FreeBASIC runtime ile link:','[UXM program derlendi.]','OK:','Derleyici hazir.')
def read_text(path): return Path(path).read_text(encoding='utf-8',errors='replace')
def parse_expect(path):
    mode='compact'; exit_code=0; body=[]
    for line in read_text(path).splitlines():
        low=line.strip().lower()
        if low.startswith('# mode:'): mode=line.split(':',1)[1].strip().lower(); continue
        if low.startswith('# exit_code:'):
            try: exit_code=int(line.split(':',1)[1].strip())
            except Exception: exit_code=0
            continue
        if low.startswith('#'): continue
        body.append(line.rstrip())
    return mode, exit_code, '\n'.join(body).strip('\n')
def normalize_compact(s): return re.sub(r'\s+','',s)
def normalize_exact(s): return '\n'.join([ln.rstrip() for ln in s.strip('\n').splitlines()]).strip('\n')
def filter_program_output(stdout,stderr):
    lines=[]
    combo=stdout + ('\n' if stdout and stderr else '') + stderr
    for raw in combo.splitlines():
        line=raw.rstrip('\r'); stripped=line.strip()
        if not stripped: continue
        if any(stripped.startswith(p) for p in TOOL_PREFIXES): continue
        if 'fbc.exe' in stripped and 'uxm31_runtime_fb_full.bas' in stripped: continue
        lines.append(line.rstrip())
    return '\n'.join(lines).strip('\n')
def compare(mode, expected, actual):
    if mode=='none': return True
    if mode=='contains': return expected in actual
    if mode=='exact': return normalize_exact(expected)==normalize_exact(actual)
    return normalize_compact(expected)==normalize_compact(actual)
def run_cmd(cmd,cwd,timeout):
    start=time.perf_counter()
    try:
        p=subprocess.run(cmd,cwd=str(cwd),shell=True,text=True,encoding='utf-8',errors='replace',capture_output=True,timeout=timeout)
        return p.returncode,p.stdout,p.stderr,time.perf_counter()-start
    except subprocess.TimeoutExpired as e:
        return 124,e.stdout or '',e.stderr or '',time.perf_counter()-start
def load_manifest(path):
    with open(path,encoding='utf-8-sig',errors='replace',newline='') as f: return list(csv.DictReader(f))
def write_csv(path,rows,fields):
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=fields); w.writeheader(); w.writerows(rows)
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',default='.')
    ap.add_argument('--manifest',default=r'uxm\tests\all_expected_known\ALL_EXPECTED_RUN_LIST.csv')
    ap.add_argument('--no-build',action='store_true')
    ap.add_argument('--stop-on-fail',action='store_true')
    ap.add_argument('--timeout-build',type=int,default=120)
    ap.add_argument('--timeout-test',type=int,default=120)
    ap.add_argument('--limit',type=int,default=0)
    ap.add_argument('--from-index',type=int,default=1)
    ap.add_argument('--name-contains',default='')
    args=ap.parse_args(); root=Path(args.root).resolve(); manifest=(root/args.manifest).resolve(); rows=load_manifest(manifest)
    if args.name_contains: rows=[r for r in rows if args.name_contains.lower() in r.get('unique_id','').lower() or args.name_contains.lower() in r.get('source_relative_path','').lower()]
    if args.from_index>1: rows=rows[args.from_index-1:]
    if args.limit>0: rows=rows[:args.limit]
    run_id=datetime.datetime.now().strftime('all_expected_%Y%m%d_%H%M%S'); outdir=root/'all_expected_results'/run_id; outdir.mkdir(parents=True,exist_ok=True)
    print(f'UXM All Expected Runner basladi: tests={len(rows)} run_dir={outdir}')
    build_sec=0.0
    if not args.no_build:
        cmd='.\\build_native.bat' if os.name=='nt' else 'build_native.bat'
        code,bout,berr,build_sec=run_cmd(cmd,root,args.timeout_build)
        (outdir/'build_stdout.txt').write_text(bout,encoding='utf-8',errors='replace'); (outdir/'build_stderr.txt').write_text(berr,encoding='utf-8',errors='replace')
        print(f'[BUILD] code={code} sure={build_sec:.2f} sn')
        if code!=0: return 2
    result_rows=[]; mismatches=[]; pass_count=mismatch_count=buildfail_count=0
    for idx,r in enumerate(rows,1):
        test_path=root/r['unique_test_path']; expect_path=root/r['unique_expect_path']
        mode,expected_exit,expected=parse_expect(expect_path)
        cmd=f'.\\build_one_native.bat "{test_path}" -x' if os.name=='nt' else f'build_one_native.bat "{test_path}" -x'
        code,stdout,stderr,sec=run_cmd(cmd,root,args.timeout_test)
        actual=filter_program_output(stdout,stderr); ok=compare(mode,expected,actual)
        status='BASARILI' if code==0 and ok else ('UYUSMAZ' if code==0 else 'BUILD_OR_RUN_FAIL')
        if status=='BASARILI': pass_count+=1
        elif status=='UYUSMAZ': mismatch_count+=1
        else: buildfail_count+=1
        print(f'[{idx:04d}/{len(rows):04d}] {status} {r["unique_id"]} ({sec:.2f} sn)')
        row={'index':idx,'status':status,'mode':mode,'seconds':f'{sec:.4f}','return_code':code,'unique_id':r['unique_id'],'test_path':r['unique_test_path'],'expect_path':r['unique_expect_path'],'source_package':r.get('source_package',''),'source_relative_path':r.get('source_relative_path',''),'expected_compact':normalize_compact(expected),'actual_compact':normalize_compact(actual)}
        result_rows.append(row)
        if status!='BASARILI':
            mismatches.append(row); mdir=outdir/'mismatches'/f'{idx:04d}_{r["unique_id"][:80]}'; mdir.mkdir(parents=True,exist_ok=True)
            (mdir/'expected.txt').write_text(expected,encoding='utf-8',errors='replace'); (mdir/'actual.txt').write_text(actual,encoding='utf-8',errors='replace')
            (mdir/'stdout.txt').write_text(stdout,encoding='utf-8',errors='replace'); (mdir/'stderr.txt').write_text(stderr,encoding='utf-8',errors='replace')
            if args.stop_on_fail: break
    fields=['index','status','mode','seconds','return_code','unique_id','test_path','expect_path','source_package','source_relative_path','expected_compact','actual_compact']
    write_csv(outdir/'all_expected_results.csv',result_rows,fields); write_csv(outdir/'all_expected_mismatches.csv',mismatches,fields)
    summary="# UXM All Expected Runner Summary\n\nRun: {}\n\n- Total selected: {}\n- Passed: {}\n- Mismatch: {}\n- Build/run fail: {}\n- Build seconds: {:.4f}\n".format(run_id,len(rows),pass_count,mismatch_count,buildfail_count,build_sec)
    (outdir/'ALL_EXPECTED_SUMMARY.md').write_text(summary,encoding='utf-8')
    print(f'BITTI: passed={pass_count}, mismatch={mismatch_count}, buildfail={buildfail_count}')
    return 0 if mismatch_count==0 and buildfail_count==0 else 1
if __name__=='__main__': raise SystemExit(main())
