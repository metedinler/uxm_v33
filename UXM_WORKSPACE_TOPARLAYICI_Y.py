# -*- coding: utf-8 -*-
r"""
UXM_WORKSPACE_TOPARLAYICI_Y.py
-----------------------------
Calisma dizinini silmeden toparlar.
Varsayilan DRY-RUN'dir. --apply verilmeden hicbir tasima yapmaz.

Kullanim:
  py -3 tools_y\UXM_WORKSPACE_TOPARLAYICI_Y.py --stage 16
  py -3 tools_y\UXM_WORKSPACE_TOPARLAYICI_Y.py --stage 16 --apply
  py -3 tools_y\UXM_WORKSPACE_TOPARLAYICI_Y.py --stage 16 --apply --retire-current-build
  py -3 tools_y\UXM_WORKSPACE_TOPARLAYICI_Y.py --stage 16 --apply --only-builds

Politika:
- Aktif kaynak klasoru uxm/ tasinmaz.
- config/, docs/ tasinmaz.
- Mevcut ana build/test bat dosyalari tasinmaz.
- build ve build stage* gibi bitmis cikti klasorleri Emekliler/builds/<stamp>/ altina tasinir.
- sonuc*.txt, runall*.txt, runtest*.txt loglari Emekliler/logs/<stamp>/ altina tasinir.
- eski xlsx/csv raporlari Emekliler/reports veya Emekliler/csv altina tasinir.
- tasima manifesti ve undo bat uretir.
"""
from __future__ import annotations

import argparse
import csv
import re
import shutil
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List

KEEP_ROOT_NAMES = {
    "uxm", "config", "docs", ".vscode", "tools_y", "Emekliler", "y_sonuclar",
    "build_native.bat", "build_one_native.bat", "run_tests_native.bat", "runalltests.bat",
    "UXM_STAGE_RUNNER.py", "UXM_V33_EXISTING_FLOW_MANAGER.py",
}

KEEP_Y_NAMES = {
    "UXM_STAGE_RUNNER_Y.py", "UXM_WORKSPACE_TOPARLAYICI_Y.py", "UXM_EMEKLI_BUILD_ANALYZER_Y.py",
    "UXM_ZIP_AUDITOR_Y.py", "run_stage_y.bat", "run_full_y.bat", "run_toparlayici_y_dryrun.bat",
    "run_toparlayici_y_apply.bat", "run_emekli_build_analyzer_y.bat",
}

BUILD_DIR_RE = re.compile(r"^(build|built)(\s*stage\s*\d+|\s*\d+|[_ -]*stage[_ -]*\d+|)$", re.IGNORECASE)
SONUC_RE = re.compile(r"^(sonuc\d*|sonuc\(\d+\)|sonuc\.s\d+|runall.*|runtest.*|stage\d+_smoke_.*)\.(txt|log)$", re.IGNORECASE)

@dataclass
class Plan:
    src: Path
    dst: Path
    category: str
    reason: str


def stamp() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def ensure_unique(path: Path) -> Path:
    if not path.exists():
        return path
    base = path
    i = 1
    while True:
        cand = base.with_name(base.name + f"__{i}")
        if not cand.exists():
            return cand
        i += 1


def rel(p: Path, root: Path) -> str:
    try:
        return str(p.resolve().relative_to(root.resolve())).replace("/", "\\")
    except Exception:
        return str(p).replace("/", "\\")


def is_build_dir(p: Path) -> bool:
    if not p.is_dir():
        return False
    name = p.name.strip()
    if name.lower() == "build":
        return True
    if name.lower().startswith("build stage"):
        return True
    if name.lower().startswith("built"):
        return True
    return bool(BUILD_DIR_RE.match(name))


def build_plan(root: Path, stage: int, tag: str, args) -> List[Plan]:
    plans: List[Plan] = []
    emekli = root / "Emekliler"

    for p in sorted(root.iterdir(), key=lambda x: x.name.lower()):
        if p.name in KEEP_ROOT_NAMES or p.name in KEEP_Y_NAMES:
            continue
        if p.name.lower().startswith("tools_y"):
            continue

        if p.is_dir() and is_build_dir(p):
            if p.name.lower() == "build" and not args.retire_current_build:
                continue
            plans.append(Plan(p, emekli / "builds" / tag / p.name, "build_dir", "bitmis build/obj/asm/exe ciktilari"))
            continue

        if args.only_builds:
            continue

        low = p.name.lower()
        if p.is_file() and SONUC_RE.match(p.name):
            plans.append(Plan(p, emekli / "logs" / tag / p.name, "log", "test/build log dosyasi"))
        elif p.is_file() and low.endswith(".xlsx"):
            plans.append(Plan(p, emekli / "reports" / tag / p.name, "xlsx_report", "eski Excel raporu"))
        elif p.is_file() and low.endswith(".csv") and p.name not in {"test_history.csv", "test_stats_summary.csv"}:
            plans.append(Plan(p, emekli / "csv" / tag / p.name, "csv", "ara/deneme csv raporu"))
        elif p.is_file() and low.endswith(".zip"):
            plans.append(Plan(p, emekli / "packages" / tag / p.name, "package_zip", "eski paket/zip arsivi"))
        elif p.is_file() and low.endswith(".diff"):
            plans.append(Plan(p, emekli / "diffs" / tag / p.name, "diff", "eski diff arsivi"))
        elif p.is_file() and (low.endswith("y.py") or low.endswith("y.bat")):
            # Kullanıcının yeni/y hattı denemelerini kaybetmeyelim; ayrı incelenecek klasöre al.
            plans.append(Plan(p, emekli / "y_denemeleri" / tag / p.name, "y_trial", "kullanici y suffix deneme dosyasi"))
        elif p.is_dir() and low in {"patched_existing_files", "patch_instructions", "recovered_data", "sample_stage12_audit_from_uploaded_zip", "sample_stage12_optimizer_analyze_only"}:
            plans.append(Plan(p, emekli / "analysis_artifacts" / tag / p.name, "analysis_artifact", "onceki analiz/yama ara urunu"))

    return plans


def execute(root: Path, plans: List[Plan], apply: bool, stage: int, tag: str) -> Path:
    report_dir = root / "toparlama_raporlari" / tag
    report_dir.mkdir(parents=True, exist_ok=True)
    manifest = report_dir / "toparlama_manifest_y.csv"
    undo = report_dir / "UNDO_toparlama_y.bat"
    with manifest.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["action", "category", "src", "dst", "reason"])
        for plan in plans:
            dst = ensure_unique(plan.dst)
            w.writerow(["MOVE" if apply else "DRY_RUN", plan.category, rel(plan.src, root), rel(dst, root), plan.reason])
            if apply:
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(plan.src), str(dst))
    with undo.open("w", encoding="utf-8") as f:
        f.write("@echo off\nrem Manifestten elle kontrol ederek geri alma iskeleti.\n")
        f.write("rem Geri almak icin manifestteki dst ve src yollarini kontrol et.\n")
    md = report_dir / "TOPARLAMA_RAPORU_Y.md"
    counts = {}
    for p in plans:
        counts[p.category] = counts.get(p.category, 0) + 1
    lines = [f"# UXM Toparlama Raporu Y\n\nStage: {stage}\nMod: {'APPLY' if apply else 'DRY-RUN'}\n\n", "## Sayim\n"]
    for k in sorted(counts):
        lines.append(f"- {k}: {counts[k]}\n")
    lines.append("\nSilme yoktur; sadece Emekliler altina tasima vardir.\n")
    md.write_text("".join(lines), encoding="utf-8")
    return manifest


def main() -> int:
    ap = argparse.ArgumentParser(description="UXM calisma dizini toparlayici Y")
    ap.add_argument("--root", default=".")
    ap.add_argument("--stage", type=int, default=16)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--retire-current-build", action="store_true")
    ap.add_argument("--only-builds", action="store_true")
    args = ap.parse_args()
    root = Path(args.root).resolve()
    tag = stamp()
    plans = build_plan(root, args.stage, tag, args)
    manifest = execute(root, plans, args.apply, args.stage, tag)
    print(f"[OK] Manifest: {manifest}")
    print(f"[INFO] Planlanan tasima: {len(plans)}")
    if not args.apply:
        print("[DRY-RUN] Hicbir dosya tasinmadi. Gercek islem icin --apply kullan.")
    else:
        print("[APPLY] Tasima tamamlandi.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
