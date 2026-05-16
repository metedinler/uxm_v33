#!/usr/bin/env python3
"""
Comm watcher for UXM — watches tools/vscode_integration/comm/
and processes command_<id>.json files, producing result_<id>.json.

Designed to run alongside the UXM runtime; performs actions by
running workspace batch scripts (compile/run) or updating alias file.
"""
from pathlib import Path
import json
import time
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
COMM_DIR = Path(__file__).resolve().parent / 'comm'
PROCESSING_DIR = COMM_DIR / 'processing'
DONE_DIR = COMM_DIR / 'done'

def ensure_dirs():
    COMM_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSING_DIR.mkdir(parents=True, exist_ok=True)
    DONE_DIR.mkdir(parents=True, exist_ok=True)

def atomic_move_to_processing(p: Path):
    dest = PROCESSING_DIR / p.name
    p.replace(dest)
    return dest

def run_shell(cmd, cwd=None, timeout=None):
    try:
        completed = subprocess.run(cmd, shell=True, cwd=cwd or str(ROOT), capture_output=True, text=True, timeout=timeout)
        return {'returncode': completed.returncode, 'stdout': completed.stdout, 'stderr': completed.stderr}
    except Exception as e:
        return {'error': str(e)}

def add_alias(alias):
    addr_file = Path(__file__).resolve().parent / 'uxm_addresses.json'
    data = {}
    if addr_file.exists():
        try:
            data = json.loads(addr_file.read_text(encoding='utf-8'))
        except Exception:
            data = {}
    name = alias.get('name')
    if name:
        data[name] = {'address': alias.get('address'), 'desc': alias.get('desc')}
        addr_file.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')
    return data

def write_result(res_obj, cid):
    res_file = COMM_DIR / f'result_{cid}.json'
    res_file.write_text(json.dumps(res_obj, indent=2, ensure_ascii=False), encoding='utf-8')

def handle_command(cmdobj):
    cid = cmdobj.get('id') or str(int(time.time()*1000))
    cmd = cmdobj.get('cmd')
    cwd = cmdobj.get('cwd') or str(ROOT)
    res = {'id': cid, 'cmd': cmd, 'ts': time.time()}
    if cmd == 'compile':
        script = cmdobj.get('script') or 'build_native.bat'
        r = run_shell(f'"{cwd}\\{script}"', cwd=cwd, timeout=900)
        res.update(r)
        res['ok'] = (r.get('returncode', 1) == 0)
    elif cmd in ('run_tests', 'run'):
        script = cmdobj.get('script') or 'run_all_expected_tests_no_build.bat'
        r = run_shell(f'"{cwd}\\{script}"', cwd=cwd, timeout=3600)
        res.update(r)
        res['ok'] = (r.get('returncode', 1) == 0)
    elif cmd == 'add_alias':
        alias = cmdobj.get('alias') or {}
        data = add_alias(alias)
        res['ok'] = True
        res['alias'] = data.get(alias.get('name'))
    elif cmd == 'trace':
        f = cmdobj.get('file')
        if not f:
            res['ok'] = False
            res['error'] = 'file parameter missing'
        else:
            full = (Path(cwd) / f).resolve()
            if not str(full).startswith(str(ROOT)):
                res['ok'] = False
                res['error'] = 'path outside workspace not allowed'
            elif not full.exists():
                res['ok'] = False
                res['error'] = 'file not found'
            else:
                lines = full.read_text(encoding='utf-8', errors='ignore').splitlines()
                res['lines'] = lines[-200:]
                res['ok'] = True
    else:
        shell = cmdobj.get('shell')
        if shell:
            r = run_shell(shell, cwd=cwd)
            res.update(r)
            res['ok'] = (r.get('returncode', 1) == 0)
        else:
            res['ok'] = False
            res['error'] = f'unknown cmd: {cmd}'
    return res

def worker_once():
    for p in COMM_DIR.glob('command_*.json'):
        if p.is_file():
            try:
                proc = atomic_move_to_processing(p)
                data = json.loads(proc.read_text(encoding='utf-8'))
                cid = data.get('id') or proc.stem.split('_',1)[1] if '_' in proc.stem else str(int(time.time()*1000))
                res = handle_command(data)
                write_result(res, cid)
                dest = DONE_DIR / f'{proc.name}.{int(time.time())}.done'
                proc.replace(dest)
            except Exception as e:
                cid = 'unknown'
                try:
                    write_result({'id': cid, 'ok': False, 'error': str(e)}, cid)
                except Exception:
                    pass

def run_daemon(poll=1.0):
    ensure_dirs()
    print('Comm watcher started, watching', COMM_DIR)
    try:
        while True:
            worker_once()
            time.sleep(poll)
    except KeyboardInterrupt:
        print('Exiting comm watcher')

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--once', action='store_true')
    args = parser.parse_args()
    if args.once:
        ensure_dirs()
        worker_once()
    else:
        run_daemon()
