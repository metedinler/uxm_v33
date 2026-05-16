#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM Expected/Actual Runner V2

Amaç:
- Sadece .expect dosyası olan testleri çalıştırır.
- mode:none veya belirsiz testleri varsayılan olarak atlar.
- Derleme/link hatasını UYUSMAZ değil BUILD_FAIL olarak ayırır.
- exact/compact/contains karşılaştırmasını normalleştirir.
- Program çıktısını build_one_native.bat logundan ayıklar.
- Mismatch durumunda expected/actual/raw/stdout/stderr dosyaları üretir.

Not:
Bu runner mevcut build_native.bat ve build_one_native.bat dosyalarını kullanır.
Derleyici/runtime dosyalarını değiştirmez.
"""
from __future__ import annotations
import argparse, csv, datetime, json, os, re, subprocess, sys, time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Optional, Tuple, Dict

CONTROL_CHARS_RE = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")
ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")

TOOL_PREFIXES = (
    "ASM uretildi:", "ASM üretildi:", "[V3.", "NASM:", "nasm ",
    "FreeBASIC runtime ile link:", "FreeBASIC runtime cache ile link:",
    "FreeBASIC runtime kaynak ile link", "Runtime cache derleniyor:",
    "OK: build\\exe\\uxm_native.exe", "Derleyici hazir.", "Derleyici hazır.",
    "[UXM program derlendi.]", "UYARI:",
)
ERROR_HINTS = (
    " error ", "error:", "error ", "hata", "assemblermessages", "assembler messages",
    "ld.exe", "executable not found", "argument count mismatch", "duplicated definition",
)

def ts() -> str:
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

def norm_newlines(s: str) -> str:
    return (s or "").replace("\r\n", "\n").replace("\r", "\n")

def strip_ansi(s: str) -> str:
    return ANSI_RE.sub("", s or "")

def safe_cell(v) -> str:
    if v is None: return ""
    s = str(v)
    return CONTROL_CHARS_RE.sub(lambda m: "\\x%02X" % ord(m.group(0)), s)

def read_text(path: Path) -> str:
    for enc in ("utf-8-sig", "utf-8", "cp1254", "latin-1"):
        try:
            return path.read_text(encoding=enc, errors="strict")
        except UnicodeDecodeError:
            pass
    return path.read_text(encoding="latin-1", errors="replace")

@dataclass
class ExpectSpec:
    mode: str = "compact"
    exit_code: int = 0
    ignore_blank: bool = True
    expected: str = ""
    valid: bool = True
    reason: str = ""

def parse_bool(v: str, default=True) -> bool:
    x = str(v).strip().lower()
    if x in ("1","true","yes","evet","on"): return True
    if x in ("0","false","no","hayir","hayır","off"): return False
    return default

def parse_expect(path: Path) -> ExpectSpec:
    if not path.exists():
        return ExpectSpec(mode="none", valid=False, reason="expect_yok")
    raw = read_text(path)
    spec = ExpectSpec()
    body=[]
    for line in norm_newlines(raw).split("\n"):
        stripped=line.strip()
        if stripped.startswith("#") and ":" in stripped:
            k,v=stripped[1:].split(":",1)
            k=k.strip().lower().replace("-","_"); v=v.strip()
            if k=="mode": spec.mode=v.lower()
            elif k=="exit_code":
                try: spec.exit_code=int(v)
                except Exception: spec.exit_code=0
            elif k=="ignore_blank": spec.ignore_blank=parse_bool(v, True)
            continue
        if stripped.startswith("#"):
            continue
        body.append(line.rstrip("\n"))
    spec.expected="\n".join(body).strip("\n")
    if spec.mode not in ("exact","compact","contains","contains_compact","none"):
        spec.valid=False; spec.reason=f"gecersiz_mode:{spec.mode}"
    if spec.mode=="none":
        spec.valid=False; spec.reason="mode_none"
    if spec.expected.strip()=="" and spec.mode not in ("none",):
        spec.valid=False; spec.reason="expect_bos"
    return spec

def normalize_exact(s: str, ignore_blank=True) -> str:
    s=strip_ansi(norm_newlines(s))
    # Derleme araçlarının bazen sızdırdığı null/ctrl karakterlerini görünür metin karşılaştırmasından çıkar.
    s=CONTROL_CHARS_RE.sub("", s)
    lines=[ln.rstrip() for ln in s.split("\n")]
    if ignore_blank:
        lines=[ln for ln in lines if ln.strip()]
    return "\n".join(lines).strip()

def normalize_compact(s: str) -> str:
    return re.sub(r"\s+", "", normalize_exact(s, True))

def is_tool_line(line: str) -> bool:
    stripped=line.strip()
    if not stripped: return False
    if any(stripped.startswith(p) for p in TOOL_PREFIXES): return True
    low=stripped.lower()
    if "fbc.exe" in low and "uxm31_runtime_fb_full.bas" in low: return True
    if "build\\obj\\" in low and " -x " in low and "fbc" in low: return True
    return False

def extract_program_output(stdout: str, stderr: str) -> str:
    combo=strip_ansi(norm_newlines((stdout or "") + ("\n" if stdout and stderr else "") + (stderr or "")))
    lines=combo.split("\n")
    # En güvenli yol: son FreeBASIC link komutundan sonra, [UXM program derlendi.] öncesi.
    start=None
    for i,line in enumerate(lines):
        low=line.lower()
        if ("fbc" in low and " -x " in low and ("uxm31_runtime_fb_full.bas" in low or "uxm_runtime" in low)):
            start=i+1
    if start is None:
        for i,line in enumerate(lines):
            if line.strip().lower().startswith("freebasic runtime"):
                # Sonraki satır genelde echo edilen fbc komutudur.
                start=i+2
    if start is None:
        # Fallback: tool satırlarını süz.
        candidates=[ln for ln in lines if not is_tool_line(ln)]
        return "\n".join([ln for ln in candidates if ln.strip()]).strip()
    end=len(lines)
    for j in range(start, len(lines)):
        if lines[j].strip()=="[UXM program derlendi.]":
            end=j; break
    out=[]
    for ln in lines[start:end]:
        if is_tool_line(ln): continue
        out.append(ln.rstrip())
    return "\n".join(out).strip()

def compare(spec: ExpectSpec, actual: str) -> Tuple[bool,str]:
    if spec.mode=="exact":
        e=normalize_exact(spec.expected, spec.ignore_blank); a=normalize_exact(actual, spec.ignore_blank)
        return (e==a, "exact")
    if spec.mode=="contains":
        e=normalize_exact(spec.expected, spec.ignore_blank); a=normalize_exact(actual, spec.ignore_blank)
        # Kullanımda contains dosyaları bazen satır satır yazılıyor. Hem exact contains hem compact contains dene.
        return (e in a or normalize_compact(spec.expected) in normalize_compact(actual), "contains")
    if spec.mode=="contains_compact":
        return (normalize_compact(spec.expected) in normalize_compact(actual), "contains_compact")
    return (normalize_compact(spec.expected)==normalize_compact(actual), "compact")

def run_cmd(cmd: str, cwd: Path, timeout: int) -> Tuple[int,str,str,float]:
    start=time.perf_counter()
    try:
        p=subprocess.run(cmd, cwd=str(cwd), shell=True, text=True, encoding="utf-8", errors="replace", capture_output=True, timeout=timeout)
        return p.returncode, p.stdout or "", p.stderr or "", time.perf_counter()-start
    except subprocess.TimeoutExpired as e:
        out=e.stdout if isinstance(e.stdout,str) else (e.stdout.decode("utf-8","replace") if e.stdout else "")
        err=e.stderr if isinstance(e.stderr,str) else (e.stderr.decode("utf-8","replace") if e.stderr else "")
        return 124, out, err, time.perf_counter()-start

@dataclass
class TestItem:
    test_path: Path
    expect_path: Path
    unique_id: str
    source: str=""

@dataclass
class ResultRow:
    index: int
    status: str
    mode: str
    seconds: float
    return_code: int
    test_path: str
    expect_path: str
    unique_id: str
    expected_compact: str
    actual_compact: str
    message: str
    raw_log: str
    program_log: str
    source: str

def load_tests_from_dir(root: Path, test_dir: Path, recursive: bool) -> List[TestItem]:
    pattern="**/*.uxm" if recursive else "*.uxm"
    items=[]
    for p in sorted(test_dir.glob(pattern)):
        if not p.is_file(): continue
        exp=p.with_suffix(".expect")
        if not exp.exists(): continue
        rel=p.relative_to(root) if p.is_relative_to(root) else p
        uid=re.sub(r"[^A-Za-z0-9_.-]+","_", str(rel).replace("\\","/"))
        items.append(TestItem(p, exp, uid, "dir"))
    return items

def load_tests_from_manifest(root: Path, manifest: Path) -> List[TestItem]:
    items=[]
    with manifest.open("r", encoding="utf-8-sig", errors="replace", newline="") as f:
        for r in csv.DictReader(f):
            test_rel=r.get("unique_test_path") or r.get("test_path") or r.get("source_relative_path") or ""
            exp_rel=r.get("unique_expect_path") or r.get("expect_path") or ""
            if not test_rel or not exp_rel: continue
            p=root/test_rel; e=root/exp_rel
            if p.exists() and e.exists():
                uid=r.get("unique_id") or re.sub(r"[^A-Za-z0-9_.-]+","_",test_rel)
                items.append(TestItem(p,e,uid,r.get("source_package","") or "manifest"))
    return items

def build_compiler(root: Path, timeout: int, outdir: Path) -> bool:
    bat=root/"build_native.bat"
    if not bat.exists():
        print(f"[BUILD_FAIL] build_native.bat yok: {bat}"); return False
    cmd=f'"{bat}"'
    code,out,err,sec=run_cmd(cmd, root, timeout)
    (outdir/"build_stdout.txt").write_text(out,encoding="utf-8",errors="replace")
    (outdir/"build_stderr.txt").write_text(err,encoding="utf-8",errors="replace")
    print(f"[BUILD] code={code} seconds={sec:.2f}")
    return code==0

def main(argv=None) -> int:
    ap=argparse.ArgumentParser(description="UXM Expected/Actual Runner V2")
    ap.add_argument("--root", default=".")
    ap.add_argument("--test-dir", default="")
    ap.add_argument("--manifest", default="")
    ap.add_argument("--recursive", action="store_true")
    ap.add_argument("--stage", default="expected")
    ap.add_argument("--out-root", default="expected_results_v2")
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("--stop-on-fail", action="store_true")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--from-index", type=int, default=1)
    ap.add_argument("--name-contains", default="")
    ap.add_argument("--timeout-build", type=int, default=180)
    ap.add_argument("--timeout-test", type=int, default=180)
    args=ap.parse_args(argv)
    root=Path(args.root).resolve()
    out_root=(root/args.out_root).resolve() if not Path(args.out_root).is_absolute() else Path(args.out_root)
    run_id=f"{args.stage}_{ts()}"; outdir=out_root/run_id
    logdir=outdir/"logs"; progdir=outdir/"program_outputs"; mismatchdir=outdir/"mismatches"
    for d in (outdir,logdir,progdir,mismatchdir): d.mkdir(parents=True,exist_ok=True)
    if args.manifest:
        items=load_tests_from_manifest(root,(root/args.manifest).resolve() if not Path(args.manifest).is_absolute() else Path(args.manifest))
    else:
        td=Path(args.test_dir or "uxm/tests/stage17")
        if not td.is_absolute(): td=root/td
        items=load_tests_from_dir(root, td, args.recursive)
    if args.name_contains:
        key=args.name_contains.lower(); items=[x for x in items if key in x.unique_id.lower() or key in str(x.test_path).lower()]
    if args.from_index>1: items=items[args.from_index-1:]
    if args.limit>0: items=items[:args.limit]
    print(f"UXM Expected Runner V2: tests={len(items)} run_dir={outdir}")
    if not args.no_build and not build_compiler(root,args.timeout_build,outdir):
        return 2
    build_one=root/"build_one_native.bat"
    rows=[]; skipped=[]; passed=mismatch=buildfail=skip=0
    for idx,item in enumerate(items,1):
        spec=parse_expect(item.expect_path)
        rel=item.test_path.relative_to(root) if item.test_path.is_relative_to(root) else item.test_path
        erel=item.expect_path.relative_to(root) if item.expect_path.is_relative_to(root) else item.expect_path
        if not spec.valid:
            skip+=1; skipped.append({"index":idx,"test_path":str(rel),"expect_path":str(erel),"reason":spec.reason})
            print(f"[{idx:04d}/{len(items):04d}] SKIP {rel} reason={spec.reason}")
            continue
        cmd=f'"{build_one}" "{rel}" -x'
        code,out,err,sec=run_cmd(cmd,root,args.timeout_test)
        raw=(out or "")+("\n" if out and err else "")+(err or "")
        program=extract_program_output(out,err)
        ok,msg=compare(spec,program)
        if code!=spec.exit_code:
            status="BUILD_FAIL" if code!=0 else "EXIT_MISMATCH"; buildfail+=1; msg=f"exit_code expected={spec.exit_code} actual={code}"
        elif ok:
            status="BASARILI"; passed+=1
        else:
            status="UYUSMAZ"; mismatch+=1
        safe_id=re.sub(r"[^A-Za-z0-9_.-]+","_",item.unique_id)[:120]
        rawp=logdir/f"{idx:04d}_{safe_id}.raw.log"; progp=progdir/f"{idx:04d}_{safe_id}.program.txt"
        rawp.write_text(raw,encoding="utf-8",errors="replace"); progp.write_text(program,encoding="utf-8",errors="replace")
        row=ResultRow(idx,status,spec.mode,round(sec,4),code,str(rel),str(erel),item.unique_id,normalize_compact(spec.expected),normalize_compact(program),msg,str(rawp.relative_to(root)) if rawp.is_relative_to(root) else str(rawp),str(progp.relative_to(root)) if progp.is_relative_to(root) else str(progp),item.source)
        rows.append(row)
        print(f"[{idx:04d}/{len(items):04d}] {status} {rel} ({sec:.2f} sn) mode={spec.mode}")
        if status!="BASARILI":
            md=mismatchdir/f"{idx:04d}_{safe_id}"; md.mkdir(parents=True,exist_ok=True)
            (md/"expected.txt").write_text(spec.expected,encoding="utf-8",errors="replace")
            (md/"actual.txt").write_text(program,encoding="utf-8",errors="replace")
            (md/"raw.log").write_text(raw,encoding="utf-8",errors="replace")
            print(f"        {msg}")
            print(f"        beklenen(compact): {normalize_compact(spec.expected)[:140]}")
            print(f"        gercek(compact)  : {normalize_compact(program)[:140]}")
            if args.stop_on_fail: break
    fields=list(asdict(rows[0]).keys()) if rows else ["index","status","mode","seconds","return_code","test_path","expect_path","unique_id","expected_compact","actual_compact","message","raw_log","program_log","source"]
    def write_csv(path, data, fields):
        with path.open("w",encoding="utf-8-sig",newline="") as f:
            w=csv.DictWriter(f,fieldnames=fields); w.writeheader()
            for r in data:
                d=asdict(r) if hasattr(r,"__dataclass_fields__") else r
                w.writerow({k:safe_cell(d.get(k,"")) for k in fields})
    write_csv(outdir/"expected_results_v2.csv", rows, fields)
    write_csv(outdir/"mismatches_v2.csv", [r for r in rows if r.status!="BASARILI"], fields)
    if skipped:
        with (outdir/"skipped_v2.csv").open("w",encoding="utf-8-sig",newline="") as f:
            w=csv.DictWriter(f,fieldnames=["index","test_path","expect_path","reason"]); w.writeheader(); w.writerows(skipped)
    summary={"run_id":run_id,"total_selected":len(items),"passed":passed,"mismatch":mismatch,"buildfail":buildfail,"skipped":skip,"outdir":str(outdir)}
    (outdir/"summary_v2.json").write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding="utf-8")
    md=["# UXM Expected Runner V2 Summary","",f"Run: `{run_id}`","",f"- Total selected: {len(items)}",f"- Passed: {passed}",f"- Mismatch: {mismatch}",f"- Build/exit fail: {buildfail}",f"- Skipped: {skip}","",f"CSV: `{outdir/'expected_results_v2.csv'}`",f"Mismatches: `{outdir/'mismatches_v2.csv'}`"]
    (outdir/"EXPECTED_RUNNER_V2_REPORT.md").write_text("\n".join(md),encoding="utf-8")
    print(f"BITTI: passed={passed}, mismatch={mismatch}, buildfail={buildfail}, skipped={skip}")
    print(f"RAPOR: {outdir}")
    return 0 if mismatch==0 and buildfail==0 else 1

if __name__=="__main__":
    raise SystemExit(main())
