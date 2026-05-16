#!/usr/bin/env python3
"""
apply_canonical_impls.py

Find missing manifest Case IDs from reports/missing_manifest_impls.csv,
locate their implementations in onceki_src/ and strongestSRC/, and insert
the Case <id> blocks into corresponding files under uxm/core/runtime/services/.

This script makes backups of modified files under tools/backups/.

Run from repository root. It prints a CSV report to reports/apply_canonical_impls_report.csv
and a human summary to stdout.
"""
import csv
import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UXM_ROOT = ROOT
REPORTS = UXM_ROOT / 'reports'
MISSING_CSV = REPORTS / 'missing_manifest_impls.csv'
SEARCH_DIRS = [UXM_ROOT / 'onceki_src', UXM_ROOT / 'strongestSRC', UXM_ROOT]
TARGET_SERVICES_DIR = UXM_ROOT / 'uxm' / 'core' / 'runtime' / 'services'
BACKUP_DIR = UXM_ROOT / 'tools' / 'backups'
BACKUP_DIR.mkdir(parents=True, exist_ok=True)
REPORT_OUT = REPORTS / 'apply_canonical_impls_report.csv'

HOOKS_DIR = UXM_ROOT / 'uxm' / 'core' / 'runtime' / 'hooks'
RUNTIME_DIR = UXM_ROOT / 'uxm' / 'core' / 'runtime'

CASE_RE = re.compile(r'^\s*Case\s+(\d+)\b')

def read_missing_ids(path):
    ids = []
    if not path.exists():
        return ids
    with open(path, newline='') as f:
        r = csv.DictReader(f)
        for row in r:
            try:
                ids.append(int(row['id']))
            except Exception:
                continue
    return ids

def find_case_in_file(path, case_id):
    lines = path.read_text(encoding='utf-8', errors='ignore').splitlines()
    for i,l in enumerate(lines):
        m = CASE_RE.match(l)
        if m and int(m.group(1))==case_id:
            # find end index: look for next Case \d+ at same indentation or Case Else or End Select
            for j in range(i+1, len(lines)):
                if CASE_RE.match(lines[j]) or re.match(r'^\s*Case\b', lines[j]) or re.match(r'^\s*Case\s+Else\b', lines[j]):
                    end = j
                    break
                if re.match(r'^\s*End Select\b', lines[j]):
                    end = j
                    break
            else:
                end = len(lines)
            return lines[i:end]
    return None

def find_case_source(case_id):
    # Search SEARCH_DIRS for files containing 'Case <id>' lines
    for base in SEARCH_DIRS:
        if not base.exists():
            continue
        for p in base.rglob('*.bas'):
            try:
                with open(p, encoding='utf-8', errors='ignore') as f:
                    for ln in f:
                        if re.match(r'^\s*Case\s+%d\b' % case_id, ln):
                            return p
            except Exception:
                continue
    return None

def insert_case_into_target(target_path, case_lines, case_id):
    text = target_path.read_text(encoding='utf-8', errors='ignore')
    if re.search(r'^\s*Case\s+%d\b' % case_id, text, flags=re.M):
        return 'exists'
    # Find insertion point: before 'Case Else' or before 'End Select' in the file
    m = re.search(r'(^\s*Case\s+Else\b)', text, flags=re.M)
    insert_at = None
    if m:
        insert_at = m.start(1)
    else:
        m2 = re.search(r'(^\s*End Select\b)', text, flags=re.M)
        if m2:
            insert_at = m2.start(1)
    if insert_at is None:
        # fallback: append at end
        new_text = text + '\n' + '\n'.join(case_lines) + '\n'
    else:
        new_text = text[:insert_at] + '\n' + '\n'.join(case_lines) + '\n' + text[insert_at:]
    # backup
    bak = BACKUP_DIR / (target_path.name + '.bak')
    shutil.copy2(target_path, bak)
    target_path.write_text(new_text, encoding='utf-8')
    return 'inserted'

def main():
    missing_ids = read_missing_ids(MISSING_CSV)
    results = []
    if not missing_ids:
        print('No missing IDs found in', MISSING_CSV)
        return
    for cid in missing_ids:
        src = find_case_source(cid)
        if not src:
            results.append((cid, '', '', 'not_found'))
            continue
        blk = find_case_in_file(src, cid)
        if not blk:
            results.append((cid, str(src), '', 'extract_failed'))
            continue
        # map to target file by basename with fallbacks
        target_fname = src.name
        target = TARGET_SERVICES_DIR / target_fname
        # if service target doesn't exist, try decoding encoded names like
        # uxm__core__runtime__services__runtime_statistics_services.bas -> runtime_statistics_services.bas
        if not target.exists():
            candidate = None
            if '__' in target_fname:
                candidate = target_fname.split('__')[-1]
                candidate_path = TARGET_SERVICES_DIR / candidate
                if candidate_path.exists():
                    target = candidate_path
            # if still missing and source path suggests hooks, try hooks dir
            if not target.exists() and 'hooks' in str(src).lower():
                if candidate:
                    candidate_path = HOOKS_DIR / candidate
                else:
                    candidate_path = HOOKS_DIR / target_fname
                if candidate_path.exists():
                    target = candidate_path
            # if still missing, try placing under runtime root
            if not target.exists():
                if candidate:
                    candidate_path = RUNTIME_DIR / candidate
                else:
                    candidate_path = RUNTIME_DIR / target_fname
                if candidate_path.exists():
                    target = candidate_path
        if not target.exists():
            results.append((cid, str(src), str(target), 'target_missing'))
            continue
        status = insert_case_into_target(target, blk, cid)
        results.append((cid, str(src), str(target), status))

    with open(REPORT_OUT, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['id','source','target','status'])
        w.writerows(results)

    for r in results:
        print(','.join(map(str,r)))

if __name__ == '__main__':
    main()
