# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, shutil, os
from pathlib import Path
from uxm_stage19_vscode_temizle import ensure_vscode

def main(argv=None):
    ap=argparse.ArgumentParser(description='UXM VSCode eklentisi kurucu v15')
    ap.add_argument('-p','--proje','--root',default='.',help='Proje kökü')
    ap.add_argument('-u','--uygula','--apply',action='store_true',help='Eklenti kaynaklarını yeniden üret')
    args=ap.parse_args(argv)
    root=Path(args.proje).resolve()
    src=ensure_vscode(root) if args.uygula or not (root/'vscode/uxm-dil-destegi-v15/package.json').exists() else root/'vscode/uxm-dil-destegi-v15'
    home=Path(os.environ.get('USERPROFILE') or Path.home())
    dest=home/'.vscode'/'extensions'/'uxm-dil-destegi-v15'
    if dest.exists(): shutil.rmtree(dest)
    shutil.copytree(src,dest)
    print(f'VSCode eklentisi kuruldu: {dest}')
    return 0
if __name__=='__main__': raise SystemExit(main())
