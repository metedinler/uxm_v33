# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, json, time
from pathlib import Path

GOREVLER = [
  {"stage":"Stage-17","baslik":"Test Framework Upgrade","gorev":".expect mantığı, expected/actual karşılaştırma, status/flags/data/tape kontrolü.","kod":"ortak/uxm_arac_cekirdek.py, araclar/uxm_beklenen_duzelt.py, stage17_*.bat, uxm/tests/stage17"},
  {"stage":"Stage-18","baslik":"Final/ARGE + Native Bridge","gorev":"Final compiler’ın eski ayrı parser/runner hattını native çekirdeğe yaklaştırma.","kod":"araclar/uxm_stage18_native_bridge.py, stage18_native.bat, stage18_tamamla.bat, uxm/tests/mega_corpus"},
  {"stage":"Stage-19","baslik":"VSCode Integration Cleanup","gorev":"Eski internal interpreter uyarıları, final compiler build hataları, trace/diagnostic hizalama.","kod":"araclar/uxm_stage19_vscode_temizle.py, vscode/uxm-dil-destegi-v15, stage19_temizle.bat"},
  {"stage":"Stage-20","baslik":"Performance + Release Cleanup","gorev":"exe-only timing runner, build cache, dokümantasyon üretimi, servis tablosu otomasyonu.","kod":"araclar/uxm_stage20_performans_release.py, stage20_performans.bat, stage20_release.bat"},
]

def var_mi(root: Path, rel: str) -> bool:
    return (root / rel).exists()

def durum(root: Path, rels: list[str]) -> str:
    ok = [r for r in rels if var_mi(root, r)]
    if len(ok) == len(rels): return "var"
    if ok: return "kısmi"
    return "eksik"

def main(argv=None):
    ap=argparse.ArgumentParser(description="UXM stage görev özeti ve kod durum raporu")
    ap.add_argument('-p','--proje','--root',default='.',help='Proje kökü')
    ap.add_argument('-o','--cikti','--out',default='belgeler/STAGE_GOREV_DURUMU_V15.md',help='Markdown çıktı')
    ap.add_argument('-j','--json',default='belgeler/stage_gorev_durumu_v15.json',help='JSON çıktı')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve()
    checks={
      'Stage-17':['ortak/uxm_arac_cekirdek.py','araclar/uxm_beklenen_duzelt.py','stage17_duzelt.bat','stage17_kontrol.bat'],
      'Stage-18':['araclar/uxm_stage18_native_bridge.py','stage18_native.bat','stage18_tamamla.bat'],
      'Stage-19':['araclar/uxm_stage19_vscode_temizle.py','stage19_temizle.bat','vscode/uxm-dil-destegi-v15/package.json'],
      'Stage-20':['araclar/uxm_stage20_performans_release.py','stage20_performans.bat','stage20_release.bat'],
    }
    rows=[]
    for g in GOREVLER:
        d=durum(root,checks[g['stage']])
        rows.append({**g,'durum':d})
    md=['# UXM Stage 17-20 Görev ve Kod Durumu','',f'Üretim zamanı: {time.strftime("%Y-%m-%d %H:%M:%S")}', '', '| Stage | Görev | Kod durumu | İlgili dosyalar |','|---|---|---|---|']
    for r in rows:
        md.append(f"| {r['stage']} - {r['baslik']} | {r['gorev']} | {r['durum']} | `{r['kod']}` |")
    md += ['','Not: Bu rapor dosya varlığını ve paket kapsamını denetler; FreeBASIC/NASM derleme doğrulaması Windows terminalindeki test komutlarıyla yapılır.']
    out=root/args.cikti; out.parent.mkdir(parents=True,exist_ok=True); out.write_text('\n'.join(md),encoding='utf-8')
    jout=root/args.json; jout.parent.mkdir(parents=True,exist_ok=True); jout.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
    print('\n'.join(md))
    return 0
if __name__=='__main__': raise SystemExit(main())
