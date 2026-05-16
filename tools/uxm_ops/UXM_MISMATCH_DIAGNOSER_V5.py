#!/usr/bin/env python3
import argparse
import csv
import datetime as dt
import json
import os
import re
from collections import Counter
from pathlib import Path

ROOT = Path.cwd()

def find_latest_results() -> Path | None:
    cands = []
    for d in [ROOT / "expected_results_v2", ROOT / "expected_results_v3", ROOT / "all_expected_results"]:
        if d.exists():
            for p in d.rglob("expected_results*.csv"):
                cands.append(p)
            for p in d.rglob("stage17_results.csv"):
                cands.append(p)
    return max(cands, key=lambda p: p.stat().st_mtime) if cands else None

def classify(row):
    uid = (row.get("unique_id") or row.get("test_path") or "").lower()
    exp = (row.get("expected_compact") or "").lower()
    act = (row.get("actual_compact") or "").lower()
    status = (row.get("status") or "").upper()
    if status in {"BUILD_OR_RUN_FAIL", "BUILD_FAIL"} or "hata" in act or "error" in act or "assembler" in act:
        return "BUILD_OR_RUNTIME_ERROR"
    if any(x in uid for x in ["math04_expr_rpn", "math05_num_deriv", "math06_integral_trap", "math07_integral_simpson"]):
        return "EXPECTED_DRIFT_ARJE_MATH_CURRENT_RETURNS_ZERO"
    if "tmp_det_debug" in uid:
        return "EXPECTED_DRIFT_MATRIX_DEBUG_PRINTS_MATRIX_AND_DET"
    if any(x in uid for x in ["test13_status_div_zero", "test14_branch_current_zero", "test15_branch_nonzero"]):
        return "EXPECTED_DRIFT_NATIVE_STATUS_BRANCH"
    if "complex_basic" in uid:
        return "EXPECTED_DRIFT_COMPLEX_ABS_VALUE"
    if "numeric_poly_integral" in uid:
        return "EXPECTED_DRIFT_NUMERIC_ROUNDING"
    if "probability_random" in uid:
        return "EXPECTED_DRIFT_DETERMINISTIC_RANDOM_SEQUENCE"
    if "matadv_inverse_identity" in uid:
        return "EXPECTED_DRIFT_OUTPUT_FILTER_OR_EXPECT_TEXT"
    if "s14_" in uid or "linalg" in uid:
        return "STAGE14_LINALG_REVIEW_NEEDED"
    if "data=4096" in act or "bellek" in act:
        return "TEST_MEMORY_DIRECTIVE_TOO_LARGE"
    return "REVIEW_NEEDED"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--results", default="")
    ns = ap.parse_args()
    os.chdir(ns.root); global ROOT; ROOT = Path.cwd()
    src = Path(ns.results) if ns.results else find_latest_results()
    if not src or not src.exists():
        print("[DIAG V5] expected_results csv bulunamadi")
        return 2
    ts = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    outdir = ROOT / "mismatch_diagnostics" / f"v5_{ts}"
    outdir.mkdir(parents=True, exist_ok=True)
    rows=[]
    with src.open("r", encoding="utf-8-sig", errors="replace", newline="") as f:
        for row in csv.DictReader(f):
            st=(row.get("status") or "").upper()
            if st in {"BASARILI", "SKIPPED", "ATLADI"}:
                continue
            row["classification"] = classify(row)
            rows.append(row)
    headers = sorted(set().union(*(r.keys() for r in rows))) if rows else ["classification"]
    with (outdir / "mismatch_classified_v5.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w=csv.DictWriter(f, fieldnames=headers); w.writeheader(); w.writerows(rows)
    counts=Counter(r.get("classification","") for r in rows)
    with (outdir / "mismatch_class_summary_v5.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w=csv.writer(f); w.writerow(["classification","count"]); w.writerows(counts.most_common())
    (outdir / "SUMMARY.json").write_text(json.dumps({"source":str(src),"mismatch_count":len(rows),"classes":dict(counts),"outdir":str(outdir)},ensure_ascii=False,indent=2),encoding="utf-8")
    md=["# UXM Mismatch Diagnostic V5", "", f"Source: `{src}`", f"Mismatch count: {len(rows)}", "", "## Classes"]
    for k,v in counts.most_common(): md.append(f"- {k}: {v}")
    (outdir / "MISMATCH_DIAGNOSTIC_REPORT_V5.md").write_text("\n".join(md)+"\n",encoding="utf-8")
    print(f"[DIAG V5] source={src}")
    print(f"[DIAG V5] mismatch={len(rows)} report={outdir}")
    for k,v in counts.most_common(): print(f"  {k}: {v}")
    return 0
if __name__ == "__main__": raise SystemExit(main())
