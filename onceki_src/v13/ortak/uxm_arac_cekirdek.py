
# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, hashlib, json, os, re, shutil, subprocess, sys, time
from pathlib import Path

try:
    csv.field_size_limit(sys.maxsize)
except Exception:
    pass

TR = {
 'test_desc':'UXM beklenen/gerçek test koşucusu',
 'fast_desc':'UXM hızlı hata anahtarı tarayıcısı',
 'clean_desc':'UXM çalışma alanı toparlayıcı',
 'report_desc':'UXM son rapor gösterici',
 'vscode_desc':'UXM VSCode eklenti kurucusu',
 'start':'UXM test koşusu başlıyor', 'build':'DERLEME', 'done':'BİTTİ', 'passed':'başarılı', 'mismatch':'uyuşmaz', 'buildfail':'derleme/çalışma hatası', 'skipped':'atlanan',
 'report':'RAPOR', 'no_csv':'expected_results CSV bulunamadı. Önce tum_test.bat / all_test.bat çalıştır veya -c ile CSV ver.',
 'scan':'HIZLI_TARA', 'source':'kaynak', 'bad':'hatalı_satır', 'unique':'tekil_hatalı_anahtar', 'manifest':'manifest',
 'clean':'TOPARLA', 'apply':'uygula', 'planned':'planlanan_taşıma', 'dry':'deneme',
 'installed':'VSCode eklentisi kuruldu', 'notfound':'bulunamadı'
}
EN = {
 'test_desc':'UXM expected/actual test runner',
 'fast_desc':'UXM fast failing-key scanner',
 'clean_desc':'UXM workspace organizer',
 'report_desc':'UXM latest report viewer',
 'vscode_desc':'UXM VSCode extension installer',
 'start':'UXM test run started', 'build':'BUILD', 'done':'DONE', 'passed':'passed', 'mismatch':'mismatch', 'buildfail':'build/run failure', 'skipped':'skipped',
 'report':'REPORT', 'no_csv':'expected_results CSV was not found. Run all_test.bat first or pass -c CSV.',
 'scan':'FAST_SCAN', 'source':'source', 'bad':'bad_rows', 'unique':'unique_bad_keys', 'manifest':'manifest',
 'clean':'CLEAN', 'apply':'apply', 'planned':'planned_moves', 'dry':'dry-run',
 'installed':'VSCode extension installed', 'notfound':'not found'
}

def S(lang): return TR if lang=='tr' else EN

def read_text(p: Path) -> str:
    return p.read_text(encoding='utf-8-sig', errors='replace')

def write_text(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8', newline='\n')

def compact(s: str) -> str:
    return re.sub(r'\s+', '', (s or '').replace('\ufeff','')).strip()

INLINE_EXPECT_PREFIXES = (
    r'#\s*source\s*[:=]\s*embedded[_\s-]*expect[_\s-]*output',
    r'#\s*embedded[_\s-]*expect[_\s-]*output\s*[:=]?',
    r'#\s*expect[_\s-]*output\s*[:=]?',
)

META_ONLY_PREFIXES = (
    r'#\s*source\s*[:=](?!\s*embedded[_\s-]*expect[_\s-]*output)',
    r'#\s*expect[_\s-]*source\s*[:=]?',
    r'#\s*generated[_\s-]*from\s*[:=]?',
)

def _strip_inline_expect_prefix(line: str) -> tuple[str, bool]:
    """#source:embedded_EXPECT_OUTPUT7 gibi aynı satıra yapışmış beklenen çıktı ön eklerini ayıklar."""
    s=(line or '').replace('\ufeff','')
    changed=False
    for pat in INLINE_EXPECT_PREFIXES:
        ns=re.sub(pat, '', s, flags=re.I)
        if ns != s:
            s=ns; changed=True
    return s, changed

def _is_expect_meta_line(line: str) -> bool:
    """Beklenen çıktı dosyasındaki salt üretim/metaveri satırlarını tanır.
    DİKKAT: #source:embedded_EXPECT_OUTPUT7 gibi satırlar salt meta değildir;
    7 beklenen çıktıdır ve korunmalıdır.
    """
    st=(line or '').strip().replace('\ufeff','')
    if not st:
        return False
    # Inline embedded output ise satır silinmez, yalnız prefix temizlenir.
    _, inline_changed = _strip_inline_expect_prefix(st)
    if inline_changed:
        return False
    for pat in META_ONLY_PREFIXES:
        if re.match(pat, st, flags=re.I):
            return True
    low=st.lower().replace(' ', '').replace('\t','')
    if low.startswith('#expect_source:') or low.startswith('#expectsource:'):
        return True
    if low.startswith('#generated_from') or low.startswith('#generatedfrom'):
        return True
    return False

def _clean_expect_body(body: str) -> str:
    lines=[]
    for line in (body or '').splitlines():
        if _is_expect_meta_line(line):
            continue
        cleaned, _ = _strip_inline_expect_prefix(line)
        lines.append(cleaned)
    return '\n'.join(lines).strip('\r\n')

def read_expect(p: Path):
    text = read_text(p) if p.exists() else ''
    mode='compact'; exit_code=0; body=text
    if '---' in text:
        head, body = text.split('---', 1)
        for line in head.splitlines():
            low=line.strip().lower().replace(' ', '')
            if low.startswith('#'): low=low[1:].strip()
            if low.startswith('mode:') or low.startswith('kip:'):
                mode=low.split(':',1)[1].strip() or 'compact'
            elif low.startswith('exit_code:') or low.startswith('cikis_kodu:'):
                try: exit_code=int(low.split(':',1)[1].strip())
                except Exception: exit_code=0
    else:
        # Ayraçsız eski .expect biçimi: mod/exit satırlarını başlık say,
        # #source gibi üretim metaverilerini çıktıdan ayır.
        lines=[]
        for line in text.splitlines():
            st=line.strip()
            low=st.lower().replace(' ','')
            if low.startswith('#mode:') or low.startswith('mode:') or low.startswith('#kip:') or low.startswith('kip:'):
                mode=low.split(':',1)[1].strip() or mode; continue
            if low.startswith('#exit_code:') or low.startswith('exit_code:') or low.startswith('#cikis_kodu:') or low.startswith('cikis_kodu:'):
                try: exit_code=int(low.split(':',1)[1].strip())
                except Exception: pass
                continue
            if _is_expect_meta_line(line):
                continue
            lines.append(line)
        body='\n'.join(lines)
    return mode, exit_code, _clean_expect_body(body)

NOISE_PREFIXES = (
    'ASM uretildi:', 'ASM üretildi:', '[V3.3', 'NASM:', 'nasm ', 'FreeBASIC runtime',
    'Runtime cache', 'Kullanim:', 'Kullanım:', 'usage:', 'Rapor Olusturuldu:', 'Rapor Oluşturuldu:'
)
ERRTOK = ('error:', 'hata:', 'ld.exe:', 'cannot ', 'no such', 'nosuch', 'permission', 'file truncated', 'fatal error', 'build_or_run_fail')

def extract_program_output(raw: str) -> str:
    lines=[]
    for line in (raw or '').splitlines():
        st=line.strip('\r').strip()
        if not st: continue
        low=st.lower()
        if any(tok in low for tok in ERRTOK):
            lines.append(st); continue
        if st.startswith(NOISE_PREFIXES): continue
        if st.startswith('[') and ('program derlendi' in low or 'build' in low): continue
        if 'fbc.exe' in low and (' -x ' in low or low.startswith('"')): continue
        lines.append(st)
    return '\n'.join(lines).strip()

def run_cmd(cmd: str, cwd: Path, timeout: int, env=None):
    t0=time.time()
    try:
        p=subprocess.run(cmd, cwd=str(cwd), shell=True, text=True, encoding='utf-8', errors='replace', capture_output=True, timeout=timeout, env=env)
        return p.returncode, p.stdout or '', p.stderr or '', time.time()-t0
    except subprocess.TimeoutExpired as e:
        out=e.stdout if isinstance(e.stdout,str) else ''
        err=e.stderr if isinstance(e.stderr,str) else ''
        return 124, out, err+'\nTIMEOUT/ZAMAN_ASIMI', time.time()-t0

def rel(root: Path, p: Path) -> str:
    try: return str(p.relative_to(root))
    except Exception: return str(p)

def tests_from(root: Path, test_dir=None, manifest=None, recursive=True):
    items=[]
    if manifest:
        mp=Path(manifest); mp = mp if mp.is_absolute() else root/mp
        with mp.open('r',encoding='utf-8-sig',newline='') as f:
            for r in csv.DictReader(f):
                tp=r.get('test_path') or r.get('test') or r.get('uxm') or r.get('path')
                ep=r.get('expect_path') or r.get('expect')
                if not tp: continue
                t=Path(tp); t=t if t.is_absolute() else root/t
                e=Path(ep) if ep else t.with_suffix('.expect'); e=e if e.is_absolute() else root/e
                if t.exists() and e.exists(): items.append((t,e))
    else:
        td=root/(test_dir or 'uxm/tests/bellek_v11')
        globber=td.rglob if recursive else td.glob
        for t in sorted(globber('*.uxm')):
            e=t.with_suffix('.expect')
            if e.exists(): items.append((t,e))
    return items

def add_common(ap, lang='tr'):
    ap.add_argument('-p','--proje','--project','--root', dest='proje', default='.', metavar=('PROJE' if lang=='tr' else 'PROJECT'), help=('Proje kökü' if lang=='tr' else 'Project root'))

def run_tests(lang='tr', argv=None):
    T=S(lang)
    ap=argparse.ArgumentParser(description=T['test_desc'])
    add_common(ap, lang)
    ap.add_argument('-t','--test-dizini','--test-dir', dest='test_dizini', default=None, metavar=('DIZIN' if lang=='tr' else 'DIR'), help=('Test dizini' if lang=='tr' else 'Test directory'))
    ap.add_argument('-m','--manifest', default=None, metavar='CSV', help=('Test manifest CSV' if lang=='tr' else 'Test manifest CSV'))
    ap.add_argument('-o','--cikti','--out-root', dest='cikti', default='sonuclar' if lang=='tr' else 'results', metavar=('KLASOR' if lang=='tr' else 'FOLDER'), help=('Sonuç kök klasörü' if lang=='tr' else 'Output root folder'))
    ap.add_argument('-k','--derleme-yok','--no-build', dest='derleme_yok', action='store_true', help=('Derleme yapma' if lang=='tr' else 'Do not rebuild compiler'))
    ap.add_argument('-D','--ilk-hatada-dur','--stop-on-fail', dest='ilk_hatada_dur', action='store_true', help=('İlk hatada dur' if lang=='tr' else 'Stop on first failure'))
    ap.add_argument('-n','--adet','--limit', dest='adet', type=int, metavar='N', help=('En çok N test' if lang=='tr' else 'Run at most N tests'))
    ap.add_argument('-s','--basla','--from-index', dest='basla', type=int, default=1, metavar='N', help=('Başlangıç sırası' if lang=='tr' else 'Start index'))
    ap.add_argument('-a','--ara','--name-contains', dest='ara', default='', metavar=('METIN' if lang=='tr' else 'TEXT'), help=('Test adında metin ara' if lang=='tr' else 'Filter by test name'))
    ap.add_argument('-z','--zaman','--timeout-test', dest='zaman', type=int, default=120, metavar='SEC', help=('Test zaman aşımı saniye' if lang=='tr' else 'Per-test timeout in seconds'))
    ap.add_argument('--derleme-zamani','--timeout-build', dest='derleme_zamani', type=int, default=180, metavar='SEC', help=('Derleme zaman aşımı saniye' if lang=='tr' else 'Build timeout in seconds'))
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve()
    tests=tests_from(root,args.test_dizini,args.manifest)
    if args.ara: tests=[x for x in tests if args.ara.lower() in rel(root,x[0]).lower()]
    if args.basla>1: tests=tests[args.basla-1:]
    if args.adet is not None: tests=tests[:args.adet]
    stamp=time.strftime('%Y%m%d_%H%M%S')
    out=root/args.cikti/f'kosu_{stamp}'
    (out/'loglar').mkdir(parents=True,exist_ok=True)
    (out/'program_ciktilari').mkdir(parents=True,exist_ok=True)
    (out/'sorunlar').mkdir(parents=True,exist_ok=True)
    print(f"{T['start']}: test={len(tests)} {T['report'].lower()}={out}")
    if not args.derleme_yok:
        code,bo,be,sec=run_cmd('call build_native.bat',root,args.derleme_zamani)
        write_text(out/'derleme_stdout.txt',bo); write_text(out/'derleme_stderr.txt',be)
        print(f"[{T['build']}] code={code} sure={sec:.2f} sn")
        if code!=0: return code
    rows=[]; passed=mismatch=buildfail=skipped=0
    for i,(t,e) in enumerate(tests,1):
        mode, exp_code, exp_body=read_expect(e)
        if mode.lower() in ('none','skip','atla'):
            skipped+=1; continue
        uid=f'uxm_{i:04d}_{hashlib.sha1(str(t).encode()).hexdigest()[:10]}'
        env=os.environ.copy(); env['UXM_BUILD_ID']=uid
        cmd=f'call build_one_native.bat "{rel(root,t)}" -x'
        code,so,se,sec=run_cmd(cmd,root,args.zaman,env)
        raw=so+(('\n'+se) if se else '')
        actual=extract_program_output(raw)
        expc=compact(exp_body); actc=compact(actual)
        if code!=exp_code:
            status='BUILD_OR_RUN_FAIL'; buildfail+=1; ok=False; msg=f'exit {exp_code}!={code}'
        else:
            if mode=='exact': ok=(exp_body.strip()==actual.strip()); msg='exact'
            elif mode=='contains': ok=(expc in actc); msg='contains'
            else: ok=(expc==actc); msg='compact'
            if ok: status='BASARILI'; passed+=1
            else: status='UYUSMAZ'; mismatch+=1
        rawp=out/'loglar'/f'{i:04d}_{t.stem}.raw.log'; write_text(rawp,raw)
        progp=out/'program_ciktilari'/f'{i:04d}_{t.stem}.txt'; write_text(progp,actual)
        if status!='BASARILI':
            sd=out/'sorunlar'/f'{i:04d}_{t.stem}'; sd.mkdir(parents=True,exist_ok=True)
            write_text(sd/'beklenen.txt' if lang=='tr' else sd/'expected.txt', exp_body)
            write_text(sd/'gercek.txt' if lang=='tr' else sd/'actual.txt', actual)
            write_text(sd/'ham.log' if lang=='tr' else sd/'raw.log', raw)
        print(f'[{i:04d}/{len(tests):04d}] {status} {rel(root,t)} ({sec:.2f} sn) mode={mode}')
        if status!='BASARILI':
            print(f'        {msg}\n        beklenen: {expc[:160]}\n        gercek   : {actc[:160]}')
        rows.append({'sira':i,'durum':status,'mode':mode,'sure':f'{sec:.3f}','exit_code':code,'test_path':rel(root,t),'expect_path':rel(root,e),'expected_compact':expc,'actual_compact':actc,'raw_log':rel(root,rawp),'program_output':rel(root,progp),'message':msg})
        if args.ilk_hatada_dur and status!='BASARILI': break
    csvp=out/('sonuclar.csv' if lang=='tr' else 'results.csv')
    with csvp.open('w',encoding='utf-8-sig',newline='') as f:
        fields=list(rows[0].keys()) if rows else ['sira','durum']
        wr=csv.DictWriter(f,fields); wr.writeheader(); wr.writerows(rows)
    summary={'toplam':len(tests),'basarili':passed,'uyusmaz':mismatch,'derleme_veya_calisma_hatasi':buildfail,'atlanan':skipped,'csv':str(csvp),'klasor':str(out)}
    write_text(out/('ozet.json' if lang=='tr' else 'summary.json'), json.dumps(summary,ensure_ascii=False,indent=2))
    write_text(out/('RAPOR.md' if lang=='tr' else 'REPORT.md'), f"# UXM {'Test Raporu' if lang=='tr' else 'Test Report'}\n\n- Total/Toplam: {len(tests)}\n- Passed/Başarılı: {passed}\n- Mismatch/Uyuşmaz: {mismatch}\n- Build fail/Derleme hatası: {buildfail}\n- Skipped/Atlanan: {skipped}\n\nCSV: `{csvp}`\n")
    print(f"{T['done']}: {T['passed']}={passed}, {T['mismatch']}={mismatch}, {T['buildfail']}={buildfail}, {T['skipped']}={skipped}")
    print(f"{T['report']}: {out}")
    return 0 if mismatch==0 and buildfail==0 else 1

def find_latest_csv(root: Path, given=None):
    if given:
        p=Path(given); p=p if p.is_absolute() else root/p
        if p.exists(): return p
    patterns=['expected_results*.csv','sonuclar.csv','results.csv','stage17_results.csv']
    found=[]
    for pat in patterns:
        found.extend(root.glob(f'**/{pat}'))
    found=[p for p in found if 'Emekliler' not in str(p) and p.is_file()]
    if not found: return None
    return max(found, key=lambda p:p.stat().st_mtime)

def semantic_key(path: str) -> str:
    s=path.replace('\\','/').lower()
    name=Path(s).name
    name=re.sub(r'^\d+__', '', name)
    name=re.sub(r'__[0-9a-f]{10}(?=\.uxm$)', '', name)
    name=re.sub(r's\d+_stage\d+[^_]*__', '', name)
    return name

def fast_scan(lang='tr', argv=None):
    T=S(lang)
    ap=argparse.ArgumentParser(description=T['fast_desc'])
    add_common(ap, lang)
    ap.add_argument('-c','--csv','--source', default=None, metavar='CSV', help=('Kaynak sonuç CSV' if lang=='tr' else 'Source result CSV'))
    ap.add_argument('-o','--cikti','--out', dest='cikti', default='hizli_sonuclar/latest' if lang=='tr' else 'fast_results/latest', metavar=('KLASOR' if lang=='tr' else 'FOLDER'), help=('Çıktı klasörü' if lang=='tr' else 'Output directory'))
    ap.add_argument('--tum-kopyalar','--all-copies', dest='tum_kopyalar', action='store_true', help=('Tüm kopyaları manifestle' if lang=='tr' else 'Include all failing copies'))
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); src=find_latest_csv(root,args.csv)
    if not src:
        print(T['no_csv']); return 2
    rows=[]
    with src.open('r',encoding='utf-8-sig',newline='') as f:
        for r in csv.DictReader(f): rows.append(r)
    bad=[]
    for r in rows:
        status=(r.get('durum') or r.get('status') or r.get('result') or '').upper()
        if status and status not in ('BASARILI','PASS','PASSED','OK','SKIPPED','ATLANDI'):
            bad.append(r)
    bykey={}
    for r in bad:
        tp=r.get('test_path') or r.get('test') or r.get('path') or r.get('uxm') or ''
        key=semantic_key(tp)
        bykey.setdefault(key, r)
    out=root/args.cikti; out.mkdir(parents=True,exist_ok=True)
    def ep_for(tp):
        return str(Path(tp).with_suffix('.expect')).replace('\\','/')
    unique=out/'hatali_tekil_manifest.csv' if lang=='tr' else out/'failed_unique_manifest.csv'
    allm=out/'hatali_tum_kopyalar_manifest.csv' if lang=='tr' else out/'failed_all_manifest.csv'
    with unique.open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['key','test_path','expect_path','durum','actual_compact','expected_compact']); wr.writeheader()
        for k,r in sorted(bykey.items()):
            tp=r.get('test_path') or r.get('test') or r.get('path') or r.get('uxm') or ''
            wr.writerow({'key':k,'test_path':tp,'expect_path':r.get('expect_path') or ep_for(tp),'durum':r.get('durum') or r.get('status') or '', 'actual_compact':r.get('actual_compact') or r.get('gercek_kompakt') or '', 'expected_compact':r.get('expected_compact') or r.get('beklenen_kompakt') or ''})
    with allm.open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['key','test_path','expect_path','durum']); wr.writeheader()
        for r in bad:
            tp=r.get('test_path') or r.get('test') or r.get('path') or r.get('uxm') or ''
            wr.writerow({'key':semantic_key(tp),'test_path':tp,'expect_path':r.get('expect_path') or ep_for(tp),'durum':r.get('durum') or r.get('status') or ''})
    summary={'kaynak':str(src),'toplam':len(rows),'hatali_satir':len(bad),'tekil_hata':len(bykey),'tekil_manifest':str(unique),'tum_manifest':str(allm)}
    write_text(out/('ozet.json' if lang=='tr' else 'summary.json'),json.dumps(summary,ensure_ascii=False,indent=2))
    write_text(out/('HIZLI_RAPOR.md' if lang=='tr' else 'FAST_REPORT.md'), f"# {T['scan']}\n\n- {T['source']}: `{src}`\n- total/toplam: {len(rows)}\n- {T['bad']}: {len(bad)}\n- {T['unique']}: {len(bykey)}\n- manifest: `{unique}`\n")
    print(f"[{T['scan']}] {T['source']}={src} total={len(rows)} {T['bad']}={len(bad)} {T['unique']}={len(bykey)}")
    print(f"[{T['scan']}] {T['manifest']}={unique}")
    return 0

def workspace_clean(lang='tr', argv=None):
    T=S(lang)
    ap=argparse.ArgumentParser(description=T['clean_desc'])
    add_common(ap, lang)
    ap.add_argument('-u','--uygula','--apply', dest='uygula', action='store_true', help=('Gerçek taşıma yap' if lang=='tr' else 'Apply planned moves'))
    ap.add_argument('-b','--build-emekli','--retire-build', dest='build_emekli', action='store_true', help=('build klasörünü de emekliye al' if lang=='tr' else 'Retire build folder too'))
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); stamp=time.strftime('%Y%m%d_%H%M%S')
    report=root/'toplama_raporlari'/stamp; report.mkdir(parents=True,exist_ok=True)
    keep={'build_native.bat','build_one_native.bat','yardim.bat','derleyici_derle.bat','bellek_test.bat','hizli_tara.bat','hatali_test.bat','tum_test.bat','alan_topla.bat','rapor_goster.bat','vscode_kur.bat'}
    keep_dirs={'uxm','araclar','tool_en','ortak','komutlar','vscode','belgeler','manifests','onceki_src','guncel_src','diffler','Emekliler'}
    moves=[]
    for p in root.iterdir():
        if p.name in keep or p.name in keep_dirs: continue
        if p.name.lower()=='build' and not args.build_emekli: continue
        if p.is_file() and (p.suffix.lower() in ('.zip','.diff','.log','.txt','.csv','.json') or p.suffix.lower()=='.bat' or p.suffix.lower()=='.py'):
            cat='dosyalar'
            if p.suffix.lower()=='.zip': cat='paketler'
            elif p.suffix.lower()=='.diff': cat='diffler'
            elif p.suffix.lower() in ('.log','.txt'): cat='loglar'
            elif p.suffix.lower() in ('.csv','.json'): cat='raporlar'
            elif p.suffix.lower()=='.bat': cat='eski_bat'
            elif p.suffix.lower()=='.py': cat='eski_python'
            moves.append((p, root/'Emekliler'/cat/stamp/p.name))
        elif p.is_dir() and (p.name.lower().startswith('expected_results') or p.name.lower().startswith('fast_results') or p.name.lower().startswith('mismatch') or p.name.lower().startswith('stage') or p.name.lower()=='build'):
            moves.append((p, root/'Emekliler'/'klasorler'/stamp/p.name))
    with (report/'toplama_manifest.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.writer(f); wr.writerow(['kaynak','hedef'])
        for a,b in moves: wr.writerow([str(a),str(b)])
    if args.uygula:
        for a,b in moves:
            b.parent.mkdir(parents=True,exist_ok=True)
            if b.exists(): b=b.with_name(b.stem+'_'+hashlib.sha1(str(time.time()).encode()).hexdigest()[:6]+b.suffix)
            shutil.move(str(a),str(b))
    print(f"[{T['clean']}] {T['apply']}={args.uygula} {T['planned']}={len(moves)} {T['report']}={report}")
    return 0

def show_report(lang='tr', argv=None):
    T=S(lang)
    ap=argparse.ArgumentParser(description=T['report_desc']); add_common(ap, lang); args=ap.parse_args(argv)
    root=Path(args.proje).resolve()
    candidates=list(root.glob('**/ozet.json'))+list(root.glob('**/summary.json'))+list(root.glob('**/RAPOR.md'))+list(root.glob('**/REPORT.md'))
    candidates=[p for p in candidates if 'Emekliler' not in str(p)]
    if not candidates:
        print(T['notfound']); return 1
    p=max(candidates,key=lambda x:x.stat().st_mtime)
    print(f"{T['report']}: {p}")
    try: print(read_text(p)[:4000])
    except Exception: pass
    return 0

def vscode_install(lang='tr', argv=None):
    T=S(lang)
    ap=argparse.ArgumentParser(description=T['vscode_desc']); add_common(ap, lang); args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); src=root/'vscode'/'uxm-dil-destegi-v11'
    home=Path(os.environ.get('USERPROFILE') or Path.home())
    dest=home/'.vscode'/'extensions'/'uxm-dil-destegi-v11'
    if dest.exists(): shutil.rmtree(dest)
    shutil.copytree(src,dest)
    print(f"{T['installed']}: {dest}")
    return 0
