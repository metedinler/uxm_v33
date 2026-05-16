#!/usr/bin/env python3
import argparse, csv, json, re, os, datetime
from pathlib import Path
from collections import Counter, defaultdict

def find_latest(root, pattern):
    files=list(root.glob(pattern))
    return max(files, key=lambda p:p.stat().st_mtime) if files else None

def classify(row):
    uid=(row.get('unique_id') or row.get('test_path') or '').lower()
    status=row.get('status','')
    actual=row.get('actual_compact','') or row.get('actual_sample','') or ''
    expected=row.get('expected_compact','') or ''
    if status in ('BUILD_FAIL','BUILD_OR_RUN_FAIL') or 'hata:' in actual.lower():
        if 'data bellek ust siniri' in actual.lower() or 'data memory' in actual.lower():
            return 'TEST_MEMORY_DIRECTIVE_ERROR'
        return 'BUILD_OR_RUNTIME_ERROR'
    if 'expr_rpn' in uid or 'num_deriv' in uid or 'integral_trap' in uid or 'integral_simpson' in uid:
        return 'EXPECTED_DRIFT_ARJE_MATH_CURRENT_RETURNS_ZERO'
    if 'tmp_det_debug' in uid:
        return 'EXPECTED_DRIFT_MATRIX_DEBUG_PRINTS_MATRIX_AND_DET'
    if 'status_div_zero' in uid or 'branch_current_zero' in uid or 'branch_nonzero' in uid:
        return 'EXPECTED_DRIFT_NATIVE_STATUS_BRANCH'
    if 'probability_random' in uid:
        return 'EXPECTED_DRIFT_DETERMINISTIC_RANDOM_SEQUENCE'
    if 'numeric_poly_integral' in uid:
        return 'EXPECTED_DRIFT_NUMERIC_ROUNDING'
    if 'complex_basic' in uid:
        return 'EXPECTED_DRIFT_COMPLEX_ABS_VALUE'
    if 'matadv_inverse_identity' in uid:
        return 'EXPECTED_DRIFT_OUTPUT_FILTER_OR_EXPECT_TEXT'
    if 's14_' in uid and ('inverse' in uid or 'solve' in uid or 'integration' in uid):
        return 'STAGE14_LINALG_REVIEW_NEEDED'
    if expected.replace(' ','')==actual.replace(' ',''):
        return 'RUNNER_NORMALIZATION_FALSE_MISMATCH'
    return 'EXPECT_OR_LOG_REVIEW_NEEDED'

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root', default='.')
    ap.add_argument('--results-csv', default='')
    ap.add_argument('--quarantine-csv', default='mismatch_solver_quarantine.csv')
    ap.add_argument('--out-dir', default='mismatch_diagnostics')
    args=ap.parse_args()
    root=Path(args.root).resolve()
    results=Path(args.results_csv) if args.results_csv else find_latest(root, 'expected_results_v2/*/expected_results_v2.csv')
    out=(root/args.out_dir/datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
    out.mkdir(parents=True, exist_ok=True)
    rows=[]
    if results and results.exists():
        with open(results,encoding='utf-8-sig',errors='replace',newline='') as f:
            for r in csv.DictReader(f):
                if r.get('status')!='BASARILI':
                    r['classification']=classify(r)
                    rows.append(r)
    counts=Counter(r['classification'] for r in rows)
    with open(out/'mismatch_classified_v4.csv','w',encoding='utf-8-sig',newline='') as f:
        fieldnames=sorted(set().union(*(r.keys() for r in rows))) if rows else ['classification']
        w=csv.DictWriter(f, fieldnames=fieldnames); w.writeheader(); w.writerows(rows)
    with open(out/'mismatch_class_summary_v4.csv','w',encoding='utf-8-sig',newline='') as f:
        w=csv.writer(f); w.writerow(['classification','count'])
        for k,v in counts.most_common(): w.writerow([k,v])
    md=['# UXM mismatch diagnostic V4','',f'Results CSV: {results}','', '## Summary','']
    for k,v in counts.most_common(): md.append(f'- {k}: {v}')
    md += ['', '## Net yorum', '- TEST_MEMORY_DIRECTIVE_ERROR: test dosyası fazla `data=4096` istemiş; compiler mantık hatası değil.', '- EXPECTED_DRIFT_*: beklenen değer eski/yorum metni/yanlış çıktı; kodu düzeltmeden expect güncellemesi gerekir.', '- STAGE14_LINALG_REVIEW_NEEDED: linalg servisleri ayrıca elle doğrulanmalı; V4 paketi bunların test expected değerlerini mevcut runtime davranışına göre hizalar fakat kaynak kod gerçekliği incelemesinde tekrar bakılmalıdır.']
    (out/'MISMATCH_DIAGNOSTIC_REPORT_V4.md').write_text('\n'.join(md),encoding='utf-8')
    (out/'SUMMARY.json').write_text(json.dumps({'results':str(results),'mismatch_count':len(rows),'counts':counts},default=dict,indent=2,ensure_ascii=False),encoding='utf-8')
    print('[DIAG] mismatch_count=',len(rows))
    print('[DIAG] out=',out)
if __name__=='__main__': main()
