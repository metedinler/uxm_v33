# -*- coding: utf-8 -*-
from pathlib import Path
import sys, argparse, shutil, os
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'araclar'))
from uxm_stage19_vscode_temizle import ensure_vscode

def main(argv=None):
    ap=argparse.ArgumentParser(description='UXM VSCode extension installer v15')
    ap.add_argument('-p','--project','--root',default='.',help='Project root')
    ap.add_argument('-u','--apply',action='store_true',help='Regenerate extension sources')
    args=ap.parse_args(argv)
    root=Path(args.project).resolve()
    src=ensure_vscode(root) if args.apply or not (root/'vscode/uxm-dil-destegi-v15/package.json').exists() else root/'vscode/uxm-dil-destegi-v15'
    home=Path(os.environ.get('USERPROFILE') or Path.home())
    dest=home/'.vscode'/'extensions'/'uxm-dil-destegi-v15'
    if dest.exists(): shutil.rmtree(dest)
    shutil.copytree(src,dest)
    print(f'VSCode extension installed: {dest}')
    return 0
if __name__=='__main__': raise SystemExit(main())
