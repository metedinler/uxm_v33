# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, hashlib, json, os, re, subprocess, sys, time
from pathlib import Path

def write(p,s): p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s,encoding='utf-8',newline='\n')
def read(p): return p.read_text(encoding='utf-8-sig',errors='replace')

def sha(p: Path):
    h=hashlib.sha256()
    try: h.update(p.read_bytes())
    except Exception: return ''
    return h.hexdigest()

def run_exe(exe: Path, n: int, timeout: int):
    rows=[]
    for i in range(1,n+1):
        t0=time.time()
        try:
            p=subprocess.run(str(exe),cwd=str(exe.parent),text=True,encoding='utf-8',errors='replace',capture_output=True,timeout=timeout)
            code=p.returncode; out=(p.stdout or '')+(p.stderr or '')
        except subprocess.TimeoutExpired as e:
            code=124; out='TIMEOUT'
        sec=time.time()-t0
        rows.append({'sira':i,'sure_saniye':f'{sec:.6f}','exit_code':code,'cikti_ozet':re.sub(r'\s+',' ',out)[:160]})
    return rows

def service_table(root: Path):
    refs={}
    for p in root.glob('uxm/tests/**/*.uxm'):
        if 'Emekliler' in str(p): continue
        try: txt=read(p)
        except Exception: continue
        for m in re.finditer(r'@!?([0-9]+)',txt):
            n=int(m.group(1)); refs.setdefault(n,set()).add(str(p.relative_to(root)))
    return [{'servis':k,'adet':len(v),'ornekler':'; '.join(sorted(list(v))[:5])} for k,v in sorted(refs.items())]

def build_cache(root: Path):
    files=list(root.glob('uxm/core/**/*.bas'))+list(root.glob('uxm/core/**/*.fbs'))+list(root.glob('*.bat'))+list(root.glob('araclar/*.py'))+list(root.glob('ortak/*.py'))
    rows=[]
    for p in sorted(set(files)):
        if 'Emekliler' in str(p): continue
        rows.append({'path':str(p.relative_to(root)),'sha256':sha(p),'size':p.stat().st_size if p.exists() else 0})
    return rows

def main(argv=None):
    ap=argparse.ArgumentParser(description='Stage-20 Performance + Release Cleanup')
    ap.add_argument('-p','--proje','--root',default='.',help='Proje kökü')
    ap.add_argument('-e','--exe',default='build/exe/program.exe',help='Exe-only timing için exe yolu')
    ap.add_argument('-n','--adet','--runs',type=int,default=5,help='Zamanlama tekrar sayısı')
    ap.add_argument('-z','--zaman','--timeout',type=int,default=20,help='Exe zaman aşımı')
    ap.add_argument('--sadece-rapor','--report-only',action='store_true',help='Exe yoksa sadece release raporu üret')
    ap.add_argument('-o','--cikti','--out',default='stage20_release',help='Rapor klasörü')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); stamp=time.strftime('%Y%m%d_%H%M%S'); out=root/args.cikti/stamp; out.mkdir(parents=True,exist_ok=True)
    cache=build_cache(root)
    with (out/'build_cache_manifest.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['path','sha256','size']); wr.writeheader(); wr.writerows(cache)
    services=service_table(root)
    with (out/'servis_tablosu_otomatik.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['servis','adet','ornekler']); wr.writeheader(); wr.writerows(services)
    exe=Path(args.exe); exe=exe if exe.is_absolute() else root/exe
    timing=[]
    if exe.exists() and not args.sadece_rapor:
        timing=run_exe(exe,args.adet,args.zaman)
    with (out/'exe_only_timing.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['sira','sure_saniye','exit_code','cikti_ozet']); wr.writeheader(); wr.writerows(timing)
    md=['# Stage-20 Performance + Release Cleanup Raporu','',f'Zaman: {time.strftime("%Y-%m-%d %H:%M:%S")}',f'- Build cache manifest satırı: {len(cache)}',f'- Otomatik servis tablosu satırı: {len(services)}',f'- Exe-only timing satırı: {len(timing)}',f'- Exe: `{exe}`', '', 'Üretilenler:', '- `build_cache_manifest.csv`', '- `servis_tablosu_otomatik.csv`', '- `exe_only_timing.csv`']
    write(out/'STAGE20_RELEASE_RAPOR.md','\n'.join(md))
    write(root/'belgeler'/'otomatik'/'SERVIS_TABLOSU_OTOMATIK.md', '# Otomatik Servis Tablosu\n\n'+'\n'.join([f"- @{r['servis']}: {r['adet']} testte geçiyor" for r in services]))
    print('\n'.join(md))
    return 0
if __name__=='__main__': raise SystemExit(main())
