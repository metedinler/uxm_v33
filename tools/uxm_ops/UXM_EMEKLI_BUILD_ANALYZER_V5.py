#!/usr/bin/env python3
import argparse
import csv
import datetime as dt
import json
import re
from collections import Counter
from pathlib import Path

PATTERNS = [
    ("Duplicated definition", re.compile(r"Duplicated definition", re.I)),
    ("Argument count mismatch", re.compile(r"Argument count mismatch", re.I)),
    ("ld.exe not found", re.compile(r"ld\.exe|Executable not found", re.I)),
    ("data memory limit", re.compile(r"data bellek|data memory|ust siniri", re.I)),
    ("UYUSMAZ", re.compile(r"UYUSMAZ", re.I)),
    ("BUILD_OR_RUN_FAIL", re.compile(r"BUILD_OR_RUN_FAIL|FAIL_BUILD|BUILD_FAIL", re.I)),
]

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--root", default=".")
    ns=ap.parse_args(); root=Path(ns.root).resolve()
    em=root/"Emekliler"
    ts=dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    out=root/"y_sonuclar"/"emekli_dersleri"/f"v5_{ts}"; out.mkdir(parents=True,exist_ok=True)
    files=[]; counts=Counter()
    if em.exists():
        for p in em.rglob("*"):
            if p.is_file() and p.suffix.lower() in {".txt",".log",".csv",".md"}:
                try: text=p.read_text(encoding="utf-8-sig", errors="replace")[:200000]
                except Exception: continue
                local=[]
                for name,rx in PATTERNS:
                    c=len(rx.findall(text))
                    if c: counts[name]+=c; local.append(f"{name}:{c}")
                if local: files.append({"file":str(p.relative_to(root)),"patterns":"; ".join(local)})
    with (out/"emekli_error_patterns_v5.csv").open("w",encoding="utf-8-sig",newline="") as f:
        w=csv.writer(f); w.writerow(["pattern","count"]); w.writerows(counts.most_common())
    with (out/"emekli_files_with_patterns_v5.csv").open("w",encoding="utf-8-sig",newline="") as f:
        w=csv.DictWriter(f, fieldnames=["file","patterns"]); w.writeheader(); w.writerows(files)
    (out/"SUMMARY.json").write_text(json.dumps({"pattern_counts":dict(counts),"files":len(files),"out":str(out)},ensure_ascii=False,indent=2),encoding="utf-8")
    print(f"[EMEKLI V5] report={out}")
    for k,v in counts.most_common(): print(f"  {k}: {v}")
    return 0
if __name__=="__main__": raise SystemExit(main())
