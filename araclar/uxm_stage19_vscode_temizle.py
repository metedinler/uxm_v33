# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, json, re, shutil, time
from pathlib import Path

WARN_KEYS = ['internal interpreter', 'legacy interpreter', 'old parser', 'eski internal', 'eski interpreter']
BUILD_ERR = ['error:', 'hata:', 'ld.exe', 'cannot open', 'permission denied', 'file truncated', 'no such file']
TRACE_KEYS = ['trace', 'diagnostic', 'diag', 'uyusmaz', 'mismatch']

def read(p): return p.read_text(encoding='utf-8-sig',errors='replace')
def write(p,s): p.parent.mkdir(parents=True,exist_ok=True); p.write_text(s,encoding='utf-8',newline='\n')

def ensure_vscode(root: Path):
    ext=root/'vscode'/'uxm-dil-destegi-v15'
    (ext/'syntaxes').mkdir(parents=True,exist_ok=True); (ext/'snippets').mkdir(parents=True,exist_ok=True)
    write(ext/'package.json', json.dumps({
      'name':'uxm-dil-destegi-v15','displayName':'UXM Dil Desteği / UXM Language Support','description':'UXM Türkçe ana dil, English command aliases, snippets and diagnostics task hooks.','version':'0.15.0','publisher':'mete','engines':{'vscode':'^1.80.0'},'categories':['Programming Languages'],
      'contributes':{'languages':[{'id':'uxm','aliases':['UXM','uXBasic Mini'],'extensions':['.uxm']}], 'grammars':[{'language':'uxm','scopeName':'source.uxm','path':'./syntaxes/uxm.tmLanguage.json'}], 'snippets':[{'language':'uxm','path':'./snippets/uxm.json'}], 'commands':[{'command':'uxm.stage17','title':'UXM: Stage-17 Test Altyapısını Kontrol Et / Check Stage-17'}, {'command':'uxm.stage18','title':'UXM: Stage-18 Native Bridge Raporu / Native Bridge Report'}, {'command':'uxm.stage19','title':'UXM: Stage-19 VSCode Temizliği / VSCode Cleanup'}, {'command':'uxm.stage20','title':'UXM: Stage-20 Release Raporu / Release Report'}]}
    },ensure_ascii=False,indent=2))
    write(ext/'language-configuration.json', json.dumps({'comments':{'lineComment':'#'},'brackets':[['(',')'],['[',']']]},ensure_ascii=False,indent=2))
    write(ext/'syntaxes'/'uxm.tmLanguage.json', json.dumps({'scopeName':'source.uxm','patterns':[{'match':'#.*$','name':'comment.line.number-sign.uxm'},{'match':'@!?\\d+','name':'entity.name.function.service.uxm'},{'match':'\\b(memory|cell|mode|total|tape|stack|data|fifo|queue|byte|kb|mb|dword|normal)\\b','name':'keyword.control.uxm'},{'match':'k-?\\d+','name':'constant.numeric.uxm'}]},ensure_ascii=False,indent=2))
    write(ext/'snippets'/'uxm.json', json.dumps({'bellek 16mb':{'prefix':'bellek16','body':['#memory total=16mb,tape=64kb,stack=64kb,data=4mb,fifo=64kb','#cell dword','#mode normal','>>>>>','$0'],'description':'16 MB bellek modeli'},'servis yazdır':{'prefix':'yazdir','body':['0(T-1)+k${1:65}','@61'],'description':'Sonucu yazdır'}},ensure_ascii=False,indent=2))
    write(ext/'extension.js', "module.exports={activate(){console.log('UXM v15 extension active')},deactivate(){}};\n")
    return ext

def main(argv=None):
    ap=argparse.ArgumentParser(description='Stage-19 VSCode integration cleanup')
    ap.add_argument('-p','--proje','--root',default='.',help='Proje kökü')
    ap.add_argument('-u','--uygula','--apply',action='store_true',help='VSCode eklenti dosyalarını üret/güncelle')
    ap.add_argument('-o','--cikti','--out',default='stage19_raporlari',help='Rapor klasörü')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve(); stamp=time.strftime('%Y%m%d_%H%M%S'); out=root/args.cikti/stamp; out.mkdir(parents=True,exist_ok=True)
    if args.uygula: ext=ensure_vscode(root)
    else: ext=root/'vscode'/'uxm-dil-destegi-v15'
    rows=[]
    for p in list(root.glob('**/*.txt'))+list(root.glob('**/*.log'))+list(root.glob('**/*.md'))+list(root.glob('**/*.csv')):
        if any(x in str(p) for x in ['Emekliler','node_modules']): continue
        try: txt=read(p)
        except Exception: continue
        low=txt.lower()
        rows.append({'file':str(p),'internal_interpreter_warnings':sum(low.count(k) for k in WARN_KEYS),'build_errors':sum(low.count(k) for k in BUILD_ERR),'trace_diag_mentions':sum(low.count(k) for k in TRACE_KEYS)})
    rows=[r for r in rows if r['internal_interpreter_warnings'] or r['build_errors'] or r['trace_diag_mentions']]
    with (out/'stage19_diagnostic_scan.csv').open('w',encoding='utf-8-sig',newline='') as f:
        wr=csv.DictWriter(f,['file','internal_interpreter_warnings','build_errors','trace_diag_mentions']); wr.writeheader(); wr.writerows(rows)
    md=['# Stage-19 VSCode Integration Cleanup Raporu','',f'Zaman: {time.strftime("%Y-%m-%d %H:%M:%S")}',f'- VSCode eklenti dizini: `{ext}`',f'- Tarama bulgusu: {len(rows)} dosya','', 'Amaç: eski internal interpreter uyarılarını, final compiler build hatalarını ve trace/diagnostic hizasını görünür kılmak.']
    write(out/'STAGE19_VSCODE_TEMIZLIK_RAPOR.md','\n'.join(md))
    print('\n'.join(md))
    return 0
if __name__=='__main__': raise SystemExit(main())
