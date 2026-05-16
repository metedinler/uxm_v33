#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import annotations
import argparse, csv, json, re
from pathlib import Path

def find_latest(root: Path, explicit: str="") -> Path:
    if explicit:
        p = root / explicit if not Path(explicit).is_absolute() else Path(explicit)
        return p
    cands = []
    for base in ("expected_results_v4", "expected_results_v3", "expected_results_v2", "all_expected_results"):
        d = root / base
        if d.exists():
            cands += list(d.glob("**/*expected_results*.csv"))
            cands += list(d.glob("**/stage17_results.csv"))
    if not cands:
        raise FileNotFoundError("expected_results csv bulunamadi")
    return max(cands, key=lambda p: p.stat().st_mtime)

def semantic_key(test_path: str) -> str:
    stem = Path(test_path).stem
    m = re.search(r"__uxm_tests_(.+?)__[0-9a-f]{8,}$", stem, re.I)
    if m:
        return m.group(1).lower()
    return re.sub(r"^[0-9]+__", "", stem).lower()

def classify(row):
    st = (row.get("status") or "").upper()
    a = (row.get("actual_compact") or row.get("actual") or row.get("message") or "").lower()
    if "data bellek" in a or ("memory" in a and "ust" in a):
        return "MEMORY_POLICY"
    if "başka bir işlem" in a or "baska bir islem" in a or "permission" in a or "reopening" in a:
        return "PARALLEL_FILE_LOCK"
    if "ld.exe" in a or "cannotfind" in a or "cannot open" in a or "can'topen" in a:
        return "LINK_OR_TOOLCHAIN"
    if "assembler" in a or "nosuchinstruction" in a or "junkatendofline" in a:
        return "ASM_BUILD_ERROR"
    if "FAIL" in st or "BUILD" in st or "RUN" in st:
        return "BUILD_OR_RUNTIME_ERROR"
    return "OUTPUT_MISMATCH"

def main():
    ap = argparse.ArgumentParser(description="UXM Fast Key Scan V7")
    ap.add_argument("--root", default=".")
    ap.add_argument("--source", default="")
    ap.add_argument("--only", default="", help="status/class filter: mismatch, buildfail, memory, lock")
    args = ap.parse_args()
    root = Path(args.root).resolve()
    src = find_latest(root, args.source)
    out = root / "fast_results" / "latest"
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    with src.open("r", encoding="utf-8-sig", errors="replace", newline="") as f:
        for r in csv.DictReader(f):
            status = (r.get("status") or "").upper()
            if status in ("BASARILI", "SKIP", "SKIPPED", ""):
                continue
            cls = classify(r)
            flt = args.only.lower().strip()
            if flt:
                if flt == "mismatch" and "UYUSMAZ" not in status:
                    continue
                if flt == "buildfail" and "BUILD" not in status and "FAIL" not in status:
                    continue
                if flt == "memory" and cls != "MEMORY_POLICY":
                    continue
                if flt == "lock" and cls != "PARALLEL_FILE_LOCK":
                    continue
            r["class"] = cls
            r["semantic_key"] = semantic_key(r.get("test_path", ""))
            rows.append(r)
    unique = {}
    for r in rows:
        unique.setdefault(r["semantic_key"], r)
    unique_rows = list(unique.values())
    def write_manifest(path: Path, data):
        fields = ["unique_test_path", "unique_expect_path", "unique_id", "status", "class", "semantic_key", "source_csv"]
        with path.open("w", encoding="utf-8-sig", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields)
            w.writeheader()
            for r in data:
                w.writerow({
                    "unique_test_path": r.get("test_path", ""),
                    "unique_expect_path": r.get("expect_path", ""),
                    "unique_id": r.get("unique_id") or Path(r.get("test_path", "")).stem,
                    "status": r.get("status", ""),
                    "class": r.get("class", ""),
                    "semantic_key": r.get("semantic_key", ""),
                    "source_csv": str(src.relative_to(root) if str(src).startswith(str(root)) else src),
                })
    write_manifest(out / "failed_unique_manifest.csv", unique_rows)
    write_manifest(out / "failed_all_manifest.csv", rows)
    counts = {}
    for r in rows:
        counts[r["class"]] = counts.get(r["class"], 0) + 1
    with (out / "class_summary.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["class", "count"])
        for k, v in sorted(counts.items(), key=lambda x: (-x[1], x[0])):
            w.writerow([k, v])
    summary = {
        "source": str(src.relative_to(root) if str(src).startswith(str(root)) else src),
        "total_bad_rows": len(rows),
        "unique_bad_keys": len(unique_rows),
        "classes": counts,
    }
    (out / "FAST_KEY_SUMMARY.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    (out / "FAST_KEY_REPORT.md").write_text("# UXM Fast Key Report V7\n\n" + json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[FAST_SCAN_V7] source={summary['source']} bad_rows={len(rows)} unique_bad_keys={len(unique_rows)}")
    print(f"[FAST_SCAN_V7] unique_manifest={out / 'failed_unique_manifest.csv'}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
