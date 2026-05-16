#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UXM Expected Runner V5
- .expect dosyası olmayan veya mode:none olan testleri koşmaz.
- Program çıktısını build/link loglarından ayıklar.
- BUILD_OR_RUN_FAIL ile UYUSMAZ ayrıdır.
- exact / compact / contains / contains_compact destekler.
- Kontrol karakterleri CSV ve karşılaştırmada güvenli biçimde ele alınır.
"""
from __future__ import annotations
import argparse, csv, datetime, json, re, subprocess, time, hashlib, sys
try:
    csv.field_size_limit(sys.maxsize)
except OverflowError:
    csv.field_size_limit(2147483647)
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Tuple

CONTROL_CHARS_RE = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")
ANSI_RE = re.compile(r"\x1b\[[0-9;]*[A-Za-z]")
TOOL_PREFIXES = (
    "ASM uretildi:", "ASM üretildi:", "[V3.", "NASM:", "nasm ",
    "FreeBASIC runtime ile link:", "FreeBASIC runtime cache ile link:",
    "FreeBASIC runtime kaynak ile link", "Runtime cache derleniyor:",
    "OK: build\\exe\\uxm_native.exe", "Derleyici hazir.", "Derleyici hazır.",
    "[UXM program derlendi.]", "UYARI:", "Rapor Olusturuldu:", "Press any key",
)
ERROR_HINTS = (
    "error ", "error:", "hata:", "assembler messages", "assemblermessages",
    "ld.exe", "executable not found", "argument count mismatch", "duplicated definition",
)

def ts() -> str:
    return datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

def norm_newlines(s: str) -> str:
    return (s or "").replace("\r\n", "\n").replace("\r", "\n")

def strip_ansi(s: str) -> str:
    return ANSI_RE.sub("", s or "")

def safe_cell(v) -> str:
    s = "" if v is None else str(v)
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
    strip_control: bool = True
    expected: str = ""
    valid: bool = True
    reason: str = ""

def parse_bool(v: str, default=True) -> bool:
    x=str(v).strip().lower()
    if x in ("1","true","yes","evet","on"): return True
    if x in ("0","false","no","hayir","hayır","off"): return False
    return default

def parse_expect(path: Path) -> ExpectSpec:
    if not path.exists():
        return ExpectSpec(mode="none", valid=False, reason="expect_yok")
    raw=read_text(path)
    spec=ExpectSpec()
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
            elif k=="strip_control": spec.strip_control=parse_bool(v, True)
            continue
        if stripped.startswith("#"):
            continue
        body.append(line.rstrip("\n"))
    spec.expected="\n".join(body).strip("\n")
    if spec.mode not in ("exact","compact","contains","contains_compact","none"):
        spec.valid=False; spec.reason=f"gecersiz_mode:{spec.mode}"
    if spec.mode=="none":
        spec.valid=False; spec.reason="mode_none"
    if spec.expected.strip()=="" and spec.mode!="none":
        spec.valid=False; spec.reason="expect_bos"
    return spec

def normalize_exact(s: str, ignore_blank=True, strip_control=True) -> str:
    s=strip_ansi(norm_newlines(s))
    if strip_control:
        s=CONTROL_CHARS_RE.sub("", s)
    lines=[ln.rstrip() for ln in s.split("\n")]
    if ignore_blank:
        lines=[ln for ln in lines if ln.strip()]
    return "\n".join(lines).strip()

def normalize_compact(s: str, strip_control=True) -> str:
    return re.sub(r"\s+", "", normalize_exact(s, True, strip_control))

def is_tool_line(line: str) -> bool:
    st=line.strip()
    if not st: return False
    if any(st.startswith(p) for p in TOOL_PREFIXES): return True
    low=st.lower()
    if "fbc.exe" in low and "uxm31_runtime_fb_full.bas" in low: return True
    if "build\\obj\\" in low and " -x " in low and "fbc" in low: return True
    return False

def extract_program_output(stdout: str, stderr: str) -> str:
    combo=strip_ansi(norm_newlines((stdout or "") + ("\n" if stdout and stderr else "") + (stderr or "")))
    lines=combo.split("\n")
    start=None
    for i,line in enumerate(lines):
        low=line.lower()
        if ("fbc" in low and " -x " in low and ("uxm31_runtime_fb_full.bas" in low or "uxm_runtime" in low)):
            start=i+1
    if start is None:
        for i,line in enumerate(lines):
            if line.strip().lower().startswith("freebasic runtime"):
                start=i+2
    if start is None:
        candidates=[ln.rstrip() for ln in lines if not is_tool_line(ln)]
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

def has_error_text(s: str) -> bool:
    low=(s or "").lower()
    return any(x in low for x in ERROR_HINTS)

def compare(spec: ExpectSpec, actual: str) -> Tuple[bool,str]:
    if spec.mode=="exact":
        e=normalize_exact(spec.expected, spec.ignore_blank, spec.strip_control)
        a=normalize_exact(actual, spec.ignore_blank, spec.strip_control)
        return (e==a, "exact")
    if spec.mode=="contains":
        e=normalize_exact(spec.expected, spec.ignore_blank, spec.strip_control)
        a=normalize_exact(actual, spec.ignore_blank, spec.strip_control)
        return (e in a or normalize_compact(spec.expected, spec.strip_control) in normalize_compact(actual, spec.strip_control), "contains")
    if spec.mode=="contains_compact":
        return (normalize_compact(spec.expected, spec.strip_control) in normalize_compact(actual, spec.strip_control), "contains_compact")
    return (normalize_compact(spec.expected, spec.strip_control)==normalize_compact(actual, spec.strip_control), "compact")

def run_cmd(cmd: str, cwd: Path, timeout: int):
    start=time.perf_counter()
    try:
        p=subprocess.run(cmd, cwd=str(cwd), shell=True, text=True, encoding="utf-8", errors="replace", capture_output=True, timeout=timeout)
        return p.returncode, p.stdout or "", p.stderr or "", time.perf_counter()-start
    except subprocess.TimeoutExpired as e:
        out=e.stdout if isinstance(e.stdout,str) else (e.stdout.decode("utf-8","replace") if e.stdout else "")
        err=e.stderr if isinstance(e.stderr,str) else (e.stderr.decode("utf-8","replace") if e.stderr else "")
        return 124,out,err,time.perf_counter()-start

@dataclass
class TestItem:
    test_path: Path
    expect_path: Path
    unique_id: str
    source: str=""

@dataclass
class ResultRow:
    index:int; status:str; mode:str; seconds:float; return_code:int
    test_path:str; expect_path:str; unique_id:str
    expected_compact:str; actual_compact:str; message:str; raw_log:str; program_log:str; source:str

def load_tests_from_dir(root: Path, test_dir: Path, recursive: bool) -> List[TestItem]:
    items=[]
    for p in sorted(test_dir.glob("**/*.uxm" if recursive else "*.uxm")):
        if not p.is_file(): continue
        e=p.with_suffix(".expect")
        if not e.exists(): continue
        rel=p.relative_to(root) if p.is_relative_to(root) else p
        uid=re.sub(r"[^A-Za-z0-9_.-]+","_",str(rel).replace("\\","/"))
        items.append(TestItem(p,e,uid,"dir"))
    return items

def load_tests_from_manifest(root: Path, manifest: Path) -> List[TestItem]:
    items=[]
    with manifest.open("r",encoding="utf-8-sig",errors="replace",newline="") as f:
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
    code,out,err,sec=run_cmd(f'"{bat}"',root,timeout)
    (outdir/"build_stdout.txt").write_text(out,encoding="utf-8",errors="replace")
    (outdir/"build_stderr.txt").write_text(err,encoding="utf-8",errors="replace")
    print(f"[BUILD] code={code} seconds={sec:.2f}")
    return code==0

def main(argv=None) -> int:
    ap=argparse.ArgumentParser(description="UXM Expected Runner V5")
    ap.add_argument("--root",default=".")
    ap.add_argument("--test-dir",default="")
    ap.add_argument("--manifest",default="")
    ap.add_argument("--recursive",action="store_true")
    ap.add_argument("--stage",default="expected_v5")
    ap.add_argument("--out-root",default="expected_results_v5")
    ap.add_argument("--no-build",action="store_true")
    ap.add_argument("--stop-on-fail",action="store_true")
    ap.add_argument("--limit",type=int,default=0)
    ap.add_argument("--from-index",type=int,default=1)
    ap.add_argument("--name-contains",default="")
    ap.add_argument("--timeout-build",type=int,default=180)
    ap.add_argument("--timeout-test",type=int,default=180)
    args=ap.parse_args(argv)
    root=Path(args.root).resolve()
    out_root=(root/args.out_root).resolve() if not Path(args.out_root).is_absolute() else Path(args.out_root)
    outdir=out_root/f"{args.stage}_{ts()}"; logdir=outdir/"logs"; progdir=outdir/"program_outputs"; mismatchdir=outdir/"mismatches"
    for d in (outdir,logdir,progdir,mismatchdir): d.mkdir(parents=True,exist_ok=True)
    items=load_tests_from_manifest(root,(root/args.manifest).resolve() if args.manifest and not Path(args.manifest).is_absolute() else Path(args.manifest)) if args.manifest else load_tests_from_dir(root, root/Path(args.test_dir or "uxm/tests/stage17"), args.recursive)
    if args.name_contains:
        key=args.name_contains.lower(); items=[x for x in items if key in x.unique_id.lower() or key in str(x.test_path).lower()]
    if args.from_index>1: items=items[args.from_index-1:]
    if args.limit>0: items=items[:args.limit]
    print(f"UXM Expected Runner V5: tests={len(items)} run_dir={outdir}")
    if not args.no_build and not build_compiler(root,args.timeout_build,outdir): return 2
    build_one=root/"build_one_native.bat"
    rows=[]; skipped=[]; passed=mismatch=buildfail=skip=0
    for idx,item in enumerate(items,1):
        spec=parse_expect(item.expect_path)
        rel=item.test_path.relative_to(root) if item.test_path.is_relative_to(root) else item.test_path
        erel=item.expect_path.relative_to(root) if item.expect_path.is_relative_to(root) else item.expect_path
        if not spec.valid:
            skip+=1; skipped.append({"index":idx,"test_path":str(rel),"expect_path":str(erel),"reason":spec.reason}); print(f"[{idx:04d}/{len(items):04d}] SKIP {rel} reason={spec.reason}"); continue
        # V4: Her test icin benzersiz build id verilir. Boylece iki terminalde kosan testler
        # build\asm\program.asm / build\exe\program.exe uzerinden birbirine girmez.
        build_id="t%04d_%s" % (idx, hashlib.sha1(str(rel).encode("utf-8", errors="replace")).hexdigest()[:10])
        cmd=f'set "UXM_BUILD_ID={build_id}" && "{build_one}" "{rel}" -x'
        code,out,err,sec=run_cmd(cmd,root,args.timeout_test)
        raw=(out or "")+("\n" if out and err else "")+(err or "")
        program=extract_program_output(out,err)
        ok,msg=compare(spec,program)
        if code!=spec.exit_code or has_error_text(raw) and code!=0:
            status="BUILD_OR_RUN_FAIL"; buildfail+=1; msg=f"exit_code expected={spec.exit_code} actual={code}"
        elif ok:
            status="BASARILI"; passed+=1
        else:
            status="UYUSMAZ"; mismatch+=1
        safe_id=re.sub(r"[^A-Za-z0-9_.-]+","_",item.unique_id)[:120]
        rawp=logdir/f"{idx:04d}_{safe_id}.raw.log"; progp=progdir/f"{idx:04d}_{safe_id}.program.txt"
        rawp.write_text(raw,encoding="utf-8",errors="replace"); progp.write_text(program,encoding="utf-8",errors="replace")
        row=ResultRow(idx,status,spec.mode,round(sec,4),code,str(rel),str(erel),item.unique_id,normalize_compact(spec.expected,spec.strip_control),normalize_compact(program,spec.strip_control),msg,str(rawp.relative_to(root)) if rawp.is_relative_to(root) else str(rawp),str(progp.relative_to(root)) if progp.is_relative_to(root) else str(progp),item.source)
        rows.append(row); print(f"[{idx:04d}/{len(items):04d}] {status} {rel} ({sec:.2f} sn) mode={spec.mode}")
        if status!="BASARILI":
            md=mismatchdir/f"{idx:04d}_{safe_id}"; md.mkdir(parents=True,exist_ok=True)
            (md/"expected.txt").write_text(spec.expected,encoding="utf-8",errors="replace")
            (md/"actual.txt").write_text(program,encoding="utf-8",errors="replace")
            (md/"raw.log").write_text(raw,encoding="utf-8",errors="replace")
            print(f"        {msg}"); print(f"        beklenen(compact): {normalize_compact(spec.expected,spec.strip_control)[:140]}"); print(f"        gercek(compact)  : {normalize_compact(program,spec.strip_control)[:140]}")
            if args.stop_on_fail: break
    fields=list(asdict(rows[0]).keys()) if rows else ["index","status","mode","seconds","return_code","test_path","expect_path","unique_id","expected_compact","actual_compact","message","raw_log","program_log","source"]
    def write_csv(path,data):
        with path.open("w",encoding="utf-8-sig",newline="") as f:
            w=csv.DictWriter(f,fieldnames=fields); w.writeheader()
            for r in data:
                d=asdict(r) if hasattr(r,"__dataclass_fields__") else r
                w.writerow({k:safe_cell(d.get(k,"")) for k in fields})
    write_csv(outdir/"expected_results_v3.csv", rows); write_csv(outdir/"mismatches_v3.csv", [r for r in rows if r.status!="BASARILI"])
    if skipped:
        with (outdir/"skipped_v3.csv").open("w",encoding="utf-8-sig",newline="") as f:
            w=csv.DictWriter(f,fieldnames=["index","test_path","expect_path","reason"]); w.writeheader(); w.writerows(skipped)
    summary={"total_selected":len(items),"passed":passed,"mismatch":mismatch,"build_or_run_fail":buildfail,"skipped":skip,"outdir":str(outdir)}
    (outdir/"summary_v3.json").write_text(json.dumps(summary,indent=2,ensure_ascii=False),encoding="utf-8")
    (outdir/"EXPECTED_RUNNER_V3_REPORT.md").write_text("\n".join(["# UXM Expected Runner V5 Summary","",f"- Total selected: {len(items)}",f"- Passed: {passed}",f"- Mismatch: {mismatch}",f"- Build/run fail: {buildfail}",f"- Skipped: {skip}","",f"CSV: `{outdir/'expected_results_v3.csv'}`",f"Mismatches: `{outdir/'mismatches_v3.csv'}`"]),encoding="utf-8")
    print(f"BITTI: passed={passed}, mismatch={mismatch}, build_or_run_fail={buildfail}, skipped={skip}")
    print(f"RAPOR: {outdir}")
    return 0 if mismatch==0 and buildfail==0 else 1
if __name__=="__main__":
    raise SystemExit(main())
