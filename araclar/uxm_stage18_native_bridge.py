# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, json, re, time
from pathlib import Path

BRIDGE_KEYS = ['native', 'build_one_native', 'native_cli', 'UXM_BUILD_ID', 'build\\exe', 'build/exe']
LEGACY_KEYS = ['internal interpreter', 'legacy runner', 'old parser', 'eski parser', 'eski runner']

def oku(p: Path) -> str:
    return p.read_text(encoding='utf-8-sig',errors='replace')

def yaz(p: Path, s: str):
    p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s,encoding='utf-8',newline='\n')

def scan_file(p: Path):
    try: txt=oku(p)
    except Exception: return None
    low=txt.lower()
    return {
      'file':str(p),
      'native_hits':sum(1 for k in BRIDGE_KEYS if k.lower() in low),
      'legacy_hits':sum(1 for k in LEGACY_KEYS if k.lower() in low),
      'has_expect_source':'#source:embedded_expect_output' in low,
      'service_refs':len(re.findall(r'@!?\d+',txt)),
    }

def main(argv=None):
    ap=argparse.ArgumentParser(description='Stage-18 Final/ARGE + Native Bridge denetimi')
    ap.add_argument('-p','--proje','--root',default='.',help='Proje kökü')
    ap.add_argument('-u','--uygula','--apply',action='store_true',help='Güvenli düzeltmeleri uygula')
    ap.add_argument('-o','--cikti','--out',default='stage18_raporlari',help='Rapor klasörü')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); stamp=time.strftime('%Y%m%d_%H%M%S'); out=root/args.cikti/stamp; out.mkdir(parents=True,exist_ok=True)
    files=[]
    for pat in ['*.bat','*.py','uxm/tests/**/*.uxm','uxm/tests/**/*.expect','tools/**/*.py','araclar/**/*.py','ortak/**/*.py']:
        files += list(root.glob(pat))
    rows=[]
    for p in sorted(set(files)):
        if any(x in str(p) for x in ['Emekliler','__pycache__']): continue
        r=scan_file(p)
        if r and (r['native_hits'] or r['legacy_hits'] or r['has_expect_source'] or r['service_refs']): rows.append(r)
    # Stage-18 zorunlu dosya durumları
    required=[
      'build_one_native.bat','ortak/uxm_arac_cekirdek.py','stage18_tamamla.bat',
      'uxm/tests/all_expected_known/0499__s18_STAGE18_MEGA_TEST_CORPUS_TRANSLATORS_PACKAGE__uxm_tests_mega_corpus_example_13_tensor4d_flat_logic__948afdf95a.uxm',
      'uxm/tests/all_expected_known/0499__s18_STAGE18_MEGA_TEST_CORPUS_TRANSLATORS_PACKAGE__uxm_tests_mega_corpus_example_13_tensor4d_flat_logic__948afdf95a.expect'
    ]
    req_rows=[{'path':r,'exists':(root/r).exists()} for r in required]
    with (out/'stage18_native_bridge_scan.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,fieldnames=['file','native_hits','legacy_hits','has_expect_source','service_refs']); wr.writeheader(); wr.writerows(rows)
    with (out/'stage18_required_files.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,fieldnames=['path','exists']); wr.writeheader(); wr.writerows(req_rows)
    missing=[r['path'] for r in req_rows if not r['exists']]
    legacy=[r for r in rows if r['legacy_hits']]
    md=['# Stage-18 Final/ARGE + Native Bridge Raporu','',f'Zaman: {time.strftime("%Y-%m-%d %H:%M:%S")}', '', f'- Zorunlu dosya eksik sayısı: {len(missing)}', f'- Eski parser/runner uyarı sayısı: {len(legacy)}', f'- Taranan ilgili dosya: {len(rows)}', '', '## Eksik zorunlu dosyalar']
    md += [f'- `{m}`' for m in missing] or ['- Yok']
    md += ['', '## Yorum', 'Stage-18’in amacı eski ARGE/final test hattını native build/test çekirdeğine yaklaştırmaktır. Bu araç bridge dosyalarını, eski interpreter/runner işaretlerini ve @servis kullanım yoğunluğunu raporlar.']
    yaz(out/'STAGE18_NATIVE_BRIDGE_RAPOR.md','\n'.join(md))
    print('\n'.join(md))
    return 0 if not missing else 1
if __name__=='__main__': raise SystemExit(main())
