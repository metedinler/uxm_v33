# -*- coding: utf-8 -*-
r"""
UXM_ZIP_AUDITOR_Y.py
-------------------
Verilen zip/proje klasorunun mevcut halini inceler ve sonraki kaynak kod gercekligi incelemesi icin veri toplar.

Kullanim:
  py -3 tools_y\UXM_ZIP_AUDITOR_Y.py --zip 1.zip
  py -3 tools_y\UXM_ZIP_AUDITOR_Y.py --root .
"""
from __future__ import annotations

import argparse
import csv
import zipfile
from collections import Counter
from datetime import datetime
from pathlib import Path


def stamp():
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def classify(name: str) -> str:
    low = name.lower()
    if low.endswith((".bas", ".fbs")):
        return "freebasic_source"
    if low.endswith(".uxm"):
        return "uxm_test_or_source"
    if low.endswith(".bat"):
        return "bat_tool"
    if low.endswith(".py"):
        return "python_tool"
    if low.endswith(".csv"):
        return "csv"
    if low.endswith(".xlsx"):
        return "xlsx"
    if low.endswith(".asm"):
        return "asm"
    if low.endswith((".o", ".obj")):
        return "object"
    if low.endswith(".exe"):
        return "exe"
    if low.endswith((".txt", ".log", ".md")):
        return "doc_or_log"
    if low.endswith((".zip", ".diff")):
        return "package_or_diff"
    return "other"


def scan_zip(zip_path: Path):
    rows = []
    with zipfile.ZipFile(zip_path, 'r') as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            parts = Path(info.filename).parts
            root = parts[0] if parts else ""
            top2 = "/".join(parts[:2]) if len(parts) >= 2 else root
            rows.append([info.filename, root, top2, classify(info.filename), info.file_size])
    return rows


def scan_root(root: Path):
    rows = []
    for p in root.rglob("*"):
        if p.is_file():
            rp = str(p.relative_to(root)).replace('\\', '/')
            parts = Path(rp).parts
            top = parts[0] if parts else ""
            top2 = "/".join(parts[:2]) if len(parts) >= 2 else top
            try:
                size = p.stat().st_size
            except Exception:
                size = 0
            rows.append([rp, top, top2, classify(rp), size])
    return rows


def write_reports(rows, outdir: Path):
    outdir.mkdir(parents=True, exist_ok=True)
    with (outdir / "zip_or_workspace_inventory_y.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Path", "Top", "Top2", "Kind", "Bytes"])
        w.writerows(rows)
    by_kind = Counter(r[3] for r in rows)
    by_top = Counter(r[1] for r in rows)
    with (outdir / "zip_or_workspace_summary_y.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Metric", "Name", "Count"])
        for k, v in by_kind.most_common():
            w.writerow(["kind", k, v])
        for k, v in by_top.most_common(50):
            w.writerow(["top", k, v])
    lines = ["# UXM Zip/Workspace Audit Y\n\n", f"Dosya sayisi: {len(rows)}\n\n", "## Turler\n"]
    for k, v in by_kind.most_common():
        lines.append(f"- {k}: {v}\n")
    lines.append("\n## Not\nBu rapor sonraki kaynak kod gercekligi incelemesi icin ham envanterdir.\n")
    (outdir / "UXM_ZIP_WORKSPACE_AUDIT_Y.md").write_text("".join(lines), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--zip", default="")
    ap.add_argument("--root", default="")
    args = ap.parse_args()
    outdir = Path("y_sonuclar") / "zip_audit" / stamp()
    if args.zip:
        rows = scan_zip(Path(args.zip))
    else:
        rows = scan_root(Path(args.root or "."))
    write_reports(rows, outdir)
    print(f"[OK] Audit: {outdir}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
