#!/usr/bin/env python3
import argparse
import csv
import datetime as dt
import os
import shutil
from pathlib import Path

KEEP_ROOT = {
    "build_native.bat", "build_one_native.bat",
    "run_01_stage.bat", "run_02_all_expected.bat", "run_03_mismatch_diag.bat", "run_04_fix_mismatches.bat",
    "run_05_workspace_clean_dryrun.bat", "run_06_workspace_clean_apply.bat", "run_07_emekli_analyze.bat", "run_08_perf_report.bat",
    "stage_state.json",
}
KEEP_DIRS = {"uxm", "tools", "tools_y", "config", "docs", "samples", "manifest", "Emekliler"}
MOVE_EXT = {".py", ".txt", ".csv", ".xlsx", ".md", ".json", ".log", ".zip", ".diff"}
OLD_BAT_PREFIXES = (
    "run_stage", "run_all_expected_tests", "run_mismatch_solver", "run_fix_known", "run_toparlayici",
    "run_emekli", "run_mega", "run_opt", "rtx", "rtxz", "run_tests_native", "runalltests",
    "run_full_y", "run_stage_y", "run_native", "smoke",
)

def unique(dst: Path) -> Path:
    if not dst.exists(): return dst
    i=1
    while True:
        cand = dst.with_name(f"{dst.stem}__{i}{dst.suffix}")
        if not cand.exists(): return cand
        i+=1

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--retire-build", action="store_true")
    ns=ap.parse_args()
    root=Path(ns.root).resolve()
    ts=dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    report=root/"workspace_clean_reports"/f"v5_{ts}"
    report.mkdir(parents=True, exist_ok=True)
    archive=root/"Emekliler"/"workspace_root_archive"/f"v5_{ts}"
    rows=[]
    for p in sorted(root.iterdir(), key=lambda x: x.name.lower()):
        name=p.name
        action="keep"; dest=""
        if name in {".git", ".venv", "venv"}:
            action="keep"
        elif p.is_dir():
            lname=name.lower()
            if ns.retire_build and (lname == "build" or lname.startswith("build stage")):
                action="move_dir_build"; dest=str(root/"Emekliler"/"builds"/f"{name}_{ts}")
            elif name not in KEEP_DIRS and name not in {"workspace_clean_reports", ".uxm_active_tool_tmp"}:
                action="move_dir_misc"; dest=str(archive/"dirs"/name)
        else:
            lower=name.lower()
            if name in KEEP_ROOT:
                action="keep"
            elif p.suffix.lower()==".bat" and lower.startswith(OLD_BAT_PREFIXES):
                action="move_bat_old"; dest=str(archive/"bat"/name)
            elif p.suffix.lower() in MOVE_EXT:
                action="move_root_artifact"; dest=str(archive/p.suffix.lower().lstrip(".")/name)
        rows.append({"path":name,"action":action,"dest":dest})
        if ns.apply and action.startswith("move"):
            d=unique(Path(dest)); d.parent.mkdir(parents=True, exist_ok=True); shutil.move(str(p), str(d))
    with (report/"workspace_clean_manifest_v5.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w=csv.DictWriter(f, fieldnames=["path","action","dest"]); w.writeheader(); w.writerows(rows)
    kept_bats=', '.join(sorted(x for x in KEEP_ROOT if x.endswith('.bat')))
    print(f"[WORKSPACE V5] apply={ns.apply} retire_build={ns.retire_build} report={report}")
    print(f"[WORKSPACE V5] root bat whitelist: {kept_bats}")
    return 0
if __name__ == "__main__": raise SystemExit(main())
