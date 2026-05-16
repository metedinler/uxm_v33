#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM Fast Key Scanner V6

Amaç:
- 1054+ testi baştan sona koşturmak yerine mevcut expected runner CSV'lerinden hatalıları bulur.
- Aynı testin farklı paket/stage kopyalarını semantic_key ile tekilleştirir.
- Sadece hatalı/uyuşmaz/build-fail testler için hızlı rerun manifestleri üretir.
- Hangi anahtar hangi sınıfa giriyor raporlar: memory policy, expected drift, runner false positive, real review.

Bu araç compiler/runtime değiştirmez. Sadece CSV okur ve manifest/rapor üretir.
"""
from __future__ import annotations
import argparse, csv, datetime, json, os, re, shutil
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

BAD_STATUSES_DEFAULT = {"UYUSMAZ", "BUILD_FAIL", "BUILD_OR_RUN_FAIL", "EXIT_MISMATCH", "BASARISIZ", "FAIL"}
PASS_STATUSES = {"BASARILI", "OK", "PASS", "PASSED", "SKIP", "SKIPPED"}

RESULT_CSV_NAMES = {
    "expected_results_v2.csv",
    "mismatches_v2.csv",
    "all_expected_results.csv",
    "all_expected_mismatches.csv",
    "stage17_results.csv",
    "test_results.csv",
}

HASH_RE = re.compile(r"^[0-9a-fA-F]{8,}$")
LEADING_INDEX_RE = re.compile(r"^\d{3,5}__")


def now() -> str:
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S")


def read_csv(path: Path) -> List[Dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", errors="replace", newline="") as f:
        return list(csv.DictReader(f))


def write_csv(path: Path, rows: List[Dict[str, object]], fields: List[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if fields is None:
        keys = []
        seen = set()
        for r in rows:
            for k in r.keys():
                if k not in seen:
                    seen.add(k); keys.append(k)
        fields = keys or ["empty"]
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader(); w.writerows(rows)


def rel_to_root(root: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve()))
    except Exception:
        return str(path)


def find_candidate_csvs(root: Path) -> List[Path]:
    candidates = []
    for base in [root / "expected_results_v2", root / "all_expected_results", root / "stage17_results", root / "stage_runs", root / "y_sonuclar"]:
        if base.exists():
            for p in base.rglob("*.csv"):
                if p.name in RESULT_CSV_NAMES or "mismatch" in p.name.lower() or "result" in p.name.lower():
                    candidates.append(p)
    # Kök raporları da dahil et.
    for p in root.glob("*.csv"):
        if p.name in RESULT_CSV_NAMES or "mismatch" in p.name.lower() or "result" in p.name.lower():
            candidates.append(p)
    # Aynı path tekrarı olmasın.
    uniq = []
    seen = set()
    for p in candidates:
        r = str(p.resolve()).lower()
        if r not in seen:
            seen.add(r); uniq.append(p)
    return sorted(uniq, key=lambda x: x.stat().st_mtime if x.exists() else 0, reverse=True)


def score_csv(path: Path) -> Tuple[int, int, float]:
    """Büyük ve güncel sonuç CSV'sini seçmek için skor."""
    try:
        rows = read_csv(path)
    except Exception:
        return (0, 0, 0)
    cols = set(rows[0].keys()) if rows else set()
    result_cols = {"status", "test_path", "expect_path"}
    has_core = 1 if result_cols.issubset(cols) else 0
    # Full sonuç CSV'si mismatch CSV'den daha değerlidir.
    name_bonus = 5 if path.name == "expected_results_v2.csv" else (3 if path.name == "all_expected_results.csv" else 1)
    return (has_core * 100000 + name_bonus * 10000 + len(rows), len(rows), path.stat().st_mtime)


def pick_csv(root: Path, requested: str) -> Path:
    if requested and requested.lower() != "auto":
        p = Path(requested)
        if not p.is_absolute(): p = root / p
        if not p.exists():
            raise FileNotFoundError(p)
        return p
    candidates = find_candidate_csvs(root)
    if not candidates:
        raise FileNotFoundError("Sonuç CSV bulunamadı. Önce run_02_all_expected.bat veya runner çalıştırılmalı.")
    return max(candidates, key=score_csv)


def compact(s: str) -> str:
    return re.sub(r"\s+", "", str(s or ""))


def is_bad_status(status: str) -> bool:
    st = str(status or "").upper().strip()
    if not st: return True
    if st in PASS_STATUSES: return False
    if st in BAD_STATUSES_DEFAULT: return True
    return st not in PASS_STATUSES


def stem_no_ext(path_text: str) -> str:
    p = str(path_text or "").replace("\\", "/")
    name = p.rsplit("/", 1)[-1]
    return re.sub(r"\.(uxm|expect|bas|txt|csv)$", "", name, flags=re.I)


def semantic_key_from_row(row: Dict[str, str]) -> str:
    uid = row.get("unique_id") or stem_no_ext(row.get("test_path", ""))
    uid = uid.replace("\\", "/").strip()
    base = stem_no_ext(uid)
    base = LEADING_INDEX_RE.sub("", base)
    parts = base.split("__")
    # all_expected_known formatı: NNNN__sXX_PACKAGE__original_rel_key__hash
    if len(parts) >= 4 and re.match(r"s\d+_", parts[0], re.I) and HASH_RE.match(parts[-1]):
        return parts[-2].lower()
    if len(parts) >= 4 and re.match(r"\d+", parts[0]) and re.match(r"s\d+_", parts[1], re.I):
        return parts[-2].lower()
    if len(parts) >= 3 and HASH_RE.match(parts[-1]):
        return parts[-2].lower()
    # Stage/paket prefixlerini gevşek temizle.
    base = re.sub(r"^s\d+_[^_]+__", "", base, flags=re.I)
    base = re.sub(r"__[0-9a-fA-F]{8,}$", "", base)
    return base.lower()


def classify(row: Dict[str, str], semantic_key: str) -> str:
    st = str(row.get("status", "")).upper()
    actual = compact(row.get("actual_compact", "") or row.get("actual", ""))
    expected = compact(row.get("expected_compact", "") or row.get("expected", ""))
    msg = (row.get("message", "") + " " + row.get("actual_compact", "") + " " + row.get("raw_log", "")).lower()
    sk = semantic_key.lower()
    if "data" in msg and ("ustsiniri" in msg or "üstsiniri" in msg or "bellekust" in msg):
        return "memory_policy_data_directive"
    if "data=4096" in msg or "4096kb" in msg:
        return "memory_policy_data_directive"
    if "build" in st or "run_fail" in st or "fail" in st:
        return "build_or_runtime_fail"
    if actual == expected and actual:
        return "runner_false_positive_or_mode"
    if any(k in sk for k in ["expr_rpn_eval", "num_deriv", "integral_trap", "integral_simpson"]):
        return "math_arge_expected_or_stub_review"
    if any(k in sk for k in ["status_div_zero", "branch_current_zero", "branch_nonzero"]):
        return "native_status_branch_expected_review"
    if "tmp_det_debug" in sk:
        return "matrix_debug_extra_output"
    if "complex_basic" in sk:
        return "complex_expected_drift_abs_sqrt"
    if "numeric_poly_integral" in sk:
        return "numeric_rounding_expected_drift"
    if "probability_random" in sk:
        return "deterministic_random_expected_drift"
    if "linalg" in sk or "stage14" in sk:
        return "stage14_linalg_review"
    if "stage15" in sk or "stage16" in sk or "ml_" in sk or "dataset" in sk or "pipe_" in sk:
        return "stage15_16_ml_dataset_review"
    return "generic_mismatch_review"


def row_to_manifest(row: Dict[str, str], semantic_key: str) -> Dict[str, str]:
    test_path = row.get("test_path") or row.get("unique_test_path") or row.get("source_relative_path") or ""
    expect_path = row.get("expect_path") or row.get("unique_expect_path") or ""
    if not expect_path and test_path.lower().endswith(".uxm"):
        expect_path = re.sub(r"\.uxm$", ".expect", test_path, flags=re.I)
    return {
        "unique_id": row.get("unique_id") or semantic_key,
        "unique_test_path": test_path,
        "unique_expect_path": expect_path,
        "source_package": row.get("source") or row.get("source_package") or "fast_v6",
        "source_relative_path": row.get("source_relative_path") or test_path,
        "semantic_key": semantic_key,
        "previous_status": row.get("status", ""),
        "previous_expected_compact": row.get("expected_compact", ""),
        "previous_actual_compact": row.get("actual_compact", ""),
    }


def path_under_root(root: Path, rel: str) -> Path:
    return root / str(rel or "").replace("\\", "/")

def exists_manifest_row(root: Path, m: Dict[str, str]) -> bool:
    return bool(m.get("unique_test_path")) and bool(m.get("unique_expect_path")) and path_under_root(root, m["unique_test_path"]).exists() and path_under_root(root, m["unique_expect_path"]).exists()


def choose_representative(rows: List[Dict[str, str]]) -> Dict[str, str]:
    # BUILD_FAIL önce; aynı anahtarın asıl kıran örneği budur. Sonra en yeni/sayıca büyük index tercih edilir.
    def score(r):
        st = str(r.get("status", "")).upper()
        idx = 0
        try: idx = int(float(r.get("index", "0") or 0))
        except Exception: pass
        path = r.get("test_path", "")
        return ((2 if "BUILD" in st or "FAIL" in st else 1 if st == "UYUSMAZ" else 0), idx, len(path))
    return max(rows, key=score)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="UXM V6 hızlı CSV anahtar tarama ve fail-only manifest üretici")
    ap.add_argument("--root", default=".")
    ap.add_argument("--csv", default="auto", help="auto veya sonuç CSV yolu")
    ap.add_argument("--out-root", default="fast_results")
    ap.add_argument("--latest-dir", default="fast_results/latest")
    ap.add_argument("--include-status", default="", help="Virgüllü statü filtresi. Boşsa BASARILI olmayanlar.")
    ap.add_argument("--name-contains", default="")
    ap.add_argument("--all-copies", action="store_true", help="Benzersiz anahtar yerine tüm hatalı kopyaları manifestte tut.")
    args = ap.parse_args(argv)

    root = Path(args.root).resolve()
    csv_path = pick_csv(root, args.csv)
    rows = read_csv(csv_path)
    if args.include_status.strip():
        wanted = {x.strip().upper() for x in args.include_status.split(",") if x.strip()}
        bad = [r for r in rows if str(r.get("status", "")).upper().strip() in wanted]
    else:
        bad = [r for r in rows if is_bad_status(r.get("status", ""))]
    if args.name_contains:
        key = args.name_contains.lower()
        bad = [r for r in bad if key in str(r.get("test_path", "") + r.get("unique_id", "")).lower()]

    grouped: Dict[str, List[Dict[str, str]]] = defaultdict(list)
    classified_rows = []
    for r in bad:
        sk = semantic_key_from_row(r)
        cls = classify(r, sk)
        rr = dict(r)
        rr["semantic_key"] = sk
        rr["class"] = cls
        grouped[sk].append(rr)
        classified_rows.append(rr)

    ts = now()
    outdir = (root / args.out_root / f"fast_key_scan_{ts}").resolve()
    latest = (root / args.latest_dir).resolve()
    outdir.mkdir(parents=True, exist_ok=True); latest.mkdir(parents=True, exist_ok=True)

    # manifestler
    all_manifest = []
    for r in classified_rows:
        m = row_to_manifest(r, r["semantic_key"]); m["class"] = r["class"]
        if exists_manifest_row(root, m): all_manifest.append(m)

    unique_manifest = []
    key_summary = []
    for sk, rs in sorted(grouped.items()):
        rep = choose_representative(rs)
        cls_counts = Counter(r.get("class", "") for r in rs)
        stat_counts = Counter(str(r.get("status", "")) for r in rs)
        m = row_to_manifest(rep, sk); m["class"] = rep.get("class", "")
        if exists_manifest_row(root, m):
            unique_manifest.append(m)
        key_summary.append({
            "semantic_key": sk,
            "count": len(rs),
            "statuses": ";".join(f"{k}:{v}" for k,v in stat_counts.most_common()),
            "classes": ";".join(f"{k}:{v}" for k,v in cls_counts.most_common()),
            "representative_test_path": m.get("unique_test_path", ""),
            "representative_expect_path": m.get("unique_expect_path", ""),
            "expected_compact": rep.get("expected_compact", ""),
            "actual_compact": rep.get("actual_compact", ""),
        })

    # sınıfa göre manifestler
    by_class = defaultdict(list)
    for m in all_manifest:
        by_class[m.get("class", "generic")].append(m)

    manifest_fields = ["unique_id","unique_test_path","unique_expect_path","source_package","source_relative_path","semantic_key","class","previous_status","previous_expected_compact","previous_actual_compact"]
    write_csv(outdir / "failed_all_manifest.csv", all_manifest, manifest_fields)
    write_csv(outdir / "failed_unique_manifest.csv", unique_manifest, manifest_fields)
    write_csv(outdir / "failed_key_summary.csv", key_summary)
    write_csv(outdir / "failed_classified_rows.csv", classified_rows)
    write_csv(outdir / "status_summary.csv", [{"status":k,"count":v} for k,v in Counter(r.get("status","") for r in rows).most_common()])
    write_csv(outdir / "bad_status_summary.csv", [{"status":k,"count":v} for k,v in Counter(r.get("status","") for r in bad).most_common()])
    write_csv(outdir / "class_summary.csv", [{"class":k,"count":v} for k,v in Counter(r.get("class","") for r in classified_rows).most_common()])

    for cls, ms in by_class.items():
        safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", cls)
        write_csv(outdir / f"failed_class_{safe}.csv", ms, manifest_fields)

    # latest klasörünü güncelle
    for name in ["failed_all_manifest.csv", "failed_unique_manifest.csv", "failed_key_summary.csv", "failed_classified_rows.csv", "status_summary.csv", "bad_status_summary.csv", "class_summary.csv"]:
        shutil.copy2(outdir / name, latest / name)
    # class manifestleri de kopyala
    for p in outdir.glob("failed_class_*.csv"):
        shutil.copy2(p, latest / p.name)

    summary = {
        "source_csv": rel_to_root(root, csv_path),
        "total_rows": len(rows),
        "bad_rows": len(bad),
        "unique_bad_keys": len(grouped),
        "failed_all_manifest_rows": len(all_manifest),
        "failed_unique_manifest_rows": len(unique_manifest),
        "class_counts": Counter(r.get("class", "") for r in classified_rows),
        "status_counts": Counter(r.get("status", "") for r in rows),
        "outdir": rel_to_root(root, outdir),
        "latest_dir": rel_to_root(root, latest),
    }
    # Counter json uyumu
    summary_json = dict(summary)
    summary_json["class_counts"] = dict(summary_json["class_counts"])
    summary_json["status_counts"] = dict(summary_json["status_counts"])
    (outdir / "FAST_KEY_SUMMARY.json").write_text(json.dumps(summary_json, ensure_ascii=False, indent=2), encoding="utf-8")
    shutil.copy2(outdir / "FAST_KEY_SUMMARY.json", latest / "FAST_KEY_SUMMARY.json")

    md = []
    md.append("# UXM Fast Key Scan V6\n")
    md.append(f"Kaynak CSV: `{rel_to_root(root, csv_path)}`\n")
    md.append(f"Toplam satır: **{len(rows)}**\n")
    md.append(f"Hatalı/uyuşmaz satır: **{len(bad)}**\n")
    md.append(f"Benzersiz hatalı anahtar: **{len(grouped)}**\n")
    md.append(f"Hızlı koşulacak unique manifest: `{rel_to_root(root, latest / 'failed_unique_manifest.csv')}`\n")
    md.append(f"Tüm hatalı kopya manifesti: `{rel_to_root(root, latest / 'failed_all_manifest.csv')}`\n")
    md.append("\n## Sınıf özeti\n")
    for k,v in Counter(r.get("class", "") for r in classified_rows).most_common():
        md.append(f"- {k}: {v}\n")
    md.append("\n## Önerilen hızlı sıra\n")
    md.append("1. `run_09_fast_key_scan.bat`\n")
    md.append("2. `run_10_rerun_failed_unique.bat --no-build` veya buildsiz değilse direkt `run_10_rerun_failed_unique.bat`\n")
    md.append("3. Unique anahtarlar temizlenirse `run_11_rerun_failed_all.bat --no-build`\n")
    (outdir / "FAST_KEY_REPORT.md").write_text("".join(md), encoding="utf-8")
    shutil.copy2(outdir / "FAST_KEY_REPORT.md", latest / "FAST_KEY_REPORT.md")

    print(f"[FAST_SCAN] source={rel_to_root(root,csv_path)} total={len(rows)} bad_rows={len(bad)} unique_bad_keys={len(grouped)}")
    print(f"[FAST_SCAN] unique_manifest={rel_to_root(root, latest/'failed_unique_manifest.csv')}")
    print(f"[FAST_SCAN] all_manifest={rel_to_root(root, latest/'failed_all_manifest.csv')}")
    print(f"[FAST_SCAN] report={rel_to_root(root, latest/'FAST_KEY_REPORT.md')}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
