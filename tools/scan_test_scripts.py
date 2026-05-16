#!/usr/bin/env python3
"""Scan repository scripts (.bat, .ps1, .py) to extract invoked tools and smoke-test suitability.
Generates reports/tool_smoke_report.md and .csv
"""
import os
import re
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / 'reports'
OUT_DIR.mkdir(exist_ok=True)

PATTERNS = [
    ('fbc', re.compile(r'\b(fbc(?:\.exe)?)\b', re.I)),
    ('nasm', re.compile(r'\bnasm\b', re.I)),
    ('uxm_native', re.compile(r'\buxm_native(?:\.exe)?\b', re.I)),
    ('uxm31_compiler', re.compile(r'uxm31_compiler', re.I)),
    ('uxm31_compiler_final', re.compile(r'uxm31_compiler_final', re.I)),
    ('uxminima', re.compile(r'uxminima|ux-minima', re.I)),
    ('vsce', re.compile(r'\bvsce\b', re.I)),
    ('npx', re.compile(r'\bnpx\b', re.I)),
    ('code_install_ext', re.compile(r'code\s+--install-extension', re.I)),
    ('robocopy', re.compile(r'\brobocopy\b', re.I)),
    ('7z', re.compile(r'\b7z\b', re.I)),
    ('zip', re.compile(r'\bzip\b', re.I)),
    ('tar', re.compile(r'\btar\b', re.I)),
    ('git', re.compile(r'\bgit\b', re.I)),
    ('python_cmd', re.compile(r'\bpython\b', re.I)),
    ('powershell', re.compile(r'Read-Host|Start-Process|start-process', re.I)),
]

ENV_VAR_RE = re.compile(r'%[A-Za-z0-9_]+%|\$\{?[A-Za-z_][A-Za-z0-9_]*\}?')
INTERACTIVE_RE = re.compile(r'\b(pause|set /p|read-host|read\(|input\()\b', re.I)
DESTRUCTIVE_RE = re.compile(r'\b(del\s+|rm\s+-rf|rd\s+/s|format\b|reg\s+add\b)', re.I)
HEAVY_TOOLS = {'fbc','nasm','uxm_native','uxm31_compiler','uxm31_compiler_final','vsce','npx','robocopy'}

def scan_file(p: Path):
    try:
        raw = p.read_text(encoding='utf-8')
    except Exception:
        raw = p.read_text(encoding='latin-1', errors='replace')
    found = set()
    examples = {}
    low = raw.lower()
    for name, rx in PATTERNS:
        m = rx.search(raw)
        if m:
            found.add(name)
            examples.setdefault(name, []).append(m.group(0))
    envs = ENV_VAR_RE.findall(raw)
    interactive = bool(INTERACTIVE_RE.search(raw))
    destructive = bool(DESTRUCTIVE_RE.search(raw))
    # find external subprocess launches in python
    subprocess_calls = []
    for rx in [r'subprocess\.run\(', r'subprocess\.Popen\(', r'os\.system\(', r'\bcall\s+"?']:
        if re.search(rx, raw, re.I): subprocess_calls.append(rx)

    # heuristic: if file is a .bat/.ps1 that lists many other .bat/.exe names, it's a runner
    references = re.findall(r"[A-Za-z0-9_\-\\/\.]+\.(bat|exe|ps1|sh|py)", raw, re.I)

    # suitability logic
    needs = set()
    for t in found:
        if t in HEAVY_TOOLS:
            needs.add(t)
    # also check for env var names that are likely %FBC%
    for e in envs:
        en = e.strip('%${}').upper()
        if 'FBC' in en or 'NASM' in en or 'UXM' in en or 'UXMINIMA' in en:
            needs.add(en.lower())

    suitability = 'yes'
    reasons = []
    if interactive:
        suitability = 'no'
        reasons.append('interactive prompt')
    if destructive:
        suitability = 'no'
        reasons.append('destructive operations')
    if needs and suitability == 'yes':
        suitability = 'yes - needs: ' + ','.join(sorted(needs))
    elif needs and suitability == 'no':
        reasons.append('and needs: ' + ','.join(sorted(needs)))

    notes = []
    if subprocess_calls: notes.append('calls subprocess APIs')
    if references: notes.append('references files: ' + ','.join(sorted(set(references))) )
    if examples:
        notes.append('examples: ' + ','.join([f"{k}({','.join(v[:1])})" for k,v in examples.items()]))

    return {
        'path': str(p.relative_to(ROOT)),
        'size': p.stat().st_size,
        'tools': ','.join(sorted(found)) if found else '',
        'env_vars': ','.join(sorted(set(envs))) if envs else '',
        'interactive': 'yes' if interactive else 'no',
        'destructive': 'yes' if destructive else 'no',
        'suitability': suitability if suitability!='yes' else ('yes - lightweight' if not needs else 'yes - needs dependencies'),
        'notes': '; '.join(notes + reasons)
    }

def main():
    exts = {'.bat','.ps1','.py','.sh'}
    rows = []
    for root, dirs, files in os.walk(ROOT):
        # skip .git and node_modules
        if '.git' in root or 'node_modules' in root or 'reports' in root:
            continue
        for fn in files:
            p = Path(root) / fn
            if p.suffix.lower() in exts:
                try:
                    rows.append(scan_file(p))
                except Exception as e:
                    rows.append({'path': str(p.relative_to(ROOT)), 'size': p.stat().st_size, 'tools':'ERROR', 'env_vars':'','interactive':'?','destructive':'?','suitability':'error','notes':str(e)})

    # write CSV
    csvp = OUT_DIR / 'tool_smoke_report.csv'
    mdp = OUT_DIR / 'tool_smoke_report.md'
    keys = ['path','size','tools','env_vars','interactive','destructive','suitability','notes']
    with open(csvp,'w',newline='',encoding='utf-8') as cf:
        w = csv.DictWriter(cf, fieldnames=keys)
        w.writeheader()
        for r in rows:
            w.writerow(r)

    # write markdown summary
    with open(mdp,'w',encoding='utf-8') as mf:
        mf.write('# UXM Tool Smoke Test Report\n\n')
        mf.write(f'Generated for workspace: {ROOT}\n\n')
        mf.write('| File | Size (bytes) | Tools found | Env vars | Interactive | Destructive | Suitability | Notes |\n')
        mf.write('|---|---:|---|---|---|---|---|---|\n')
        for r in rows:
            mf.write(f"| {r['path']} | {r['size']} | {r['tools']} | {r['env_vars']} | {r['interactive']} | {r['destructive']} | {r['suitability']} | {r['notes']} |\n")

    print('Wrote', csvp, mdp)

if __name__ == '__main__':
    main()
