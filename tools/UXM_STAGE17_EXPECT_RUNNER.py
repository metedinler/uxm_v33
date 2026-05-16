# -*- coding: utf-8 -*-
"""
UXM Stage-17 Expected/Actual Test Runner

Amaç:
- Mevcut build_native.bat ve build_one_native.bat dosyalarını kullanır.
- Test kaynaklarını yeniden üretmez; verilen klasördeki .uxm dosyalarını koşar.
- Her .uxm için aynı adlı .expect dosyasını okuyup çıktı karşılaştırması yapar.
- Ayrı CSV/JSON/MD rapor üretir.
- Raw build loglarını korur.
- İstenirse build klasörünü Emekliler altına taşır.

Expect dosyası örneği:
    # mode: compact
    # exit_code: 0
    30

mode:
- exact   : satır satır normalleştirilmiş program çıktısı tam aynı olmalı
- compact : whitespace kaldırılarak karşılaştırılır
- contains: beklenen metin program çıktısının içinde aranır
"""

from __future__ import annotations

import argparse
import csv
import datetime as _dt
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

CONTROL_CHARS_RE = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")
BUILD_MARKERS = (
    "ASM uretildi:",
    "[V3.3-",
    "NASM:",
    "FreeBASIC runtime ile link:",
    "[UXM program derlendi.]",
    "OK: build\\exe\\uxm_native.exe",
)


def now_stamp() -> str:
    return _dt.datetime.now().strftime("%Y%m%d_%H%M%S")


def safe_text_for_csv(value: object) -> str:
    if value is None:
        return ""
    s = str(value)
    return CONTROL_CHARS_RE.sub(lambda m: "\\x%02X" % ord(m.group(0)), s)


def norm_newlines(s: str) -> str:
    return s.replace("\r\n", "\n").replace("\r", "\n")


def strip_ansi(s: str) -> str:
    return re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", s)


def normalize_exact(s: str, ignore_blank: bool = True) -> str:
    s = strip_ansi(norm_newlines(s))
    lines = [line.rstrip() for line in s.split("\n")]
    if ignore_blank:
        lines = [line for line in lines if line.strip()]
    return "\n".join(lines).strip()


def compact(s: str) -> str:
    s = normalize_exact(s, ignore_blank=True)
    s = CONTROL_CHARS_RE.sub("", s)
    return re.sub(r"\s+", "", s)


def read_text(path: Path) -> str:
    for enc in ("utf-8-sig", "utf-8", "cp1254", "latin-1"):
        try:
            return path.read_text(encoding=enc, errors="strict")
        except UnicodeDecodeError:
            continue
    return path.read_text(encoding="latin-1", errors="replace")


@dataclass
class ExpectSpec:
    mode: str = "compact"
    exit_code: int = 0
    ignore_blank: bool = True
    expected: str = ""


def parse_bool(value: str, default: bool = True) -> bool:
    v = str(value).strip().lower()
    if v in ("1", "true", "yes", "evet", "on"):
        return True
    if v in ("0", "false", "no", "hayir", "hayır", "off"):
        return False
    return default


def read_expect(path: Path) -> ExpectSpec:
    if not path.exists():
        return ExpectSpec(mode="none", exit_code=0, ignore_blank=True, expected="")
    raw = read_text(path)
    spec = ExpectSpec()
    body: List[str] = []
    for line in norm_newlines(raw).split("\n"):
        stripped = line.strip()
        if stripped.startswith("#") and ":" in stripped:
            key, val = stripped[1:].split(":", 1)
            key = key.strip().lower().replace("-", "_")
            val = val.strip()
            if key == "mode":
                spec.mode = val.lower()
            elif key == "exit_code":
                try:
                    spec.exit_code = int(val)
                except ValueError:
                    spec.exit_code = 0
            elif key == "ignore_blank":
                spec.ignore_blank = parse_bool(val, True)
            continue
        if stripped.startswith("#"):
            continue
        body.append(line)
    spec.expected = "\n".join(body).strip()
    if spec.mode not in ("exact", "compact", "contains", "none"):
        spec.mode = "compact"
    return spec


def extract_program_output(raw: str) -> str:
    """build_one_native.bat çıktısından program çıktısını ayırmaya çalışır.

    Mevcut bat dosyası derleme komutlarını da stdout'a yazdığı için program çıktısı
    çoğunlukla echo edilen fbc komutundan sonra ve '[UXM program derlendi.]'
    marker'ından önce kalır. Bu fonksiyon marker yoksa güvenli fallback yapar.
    """
    text = strip_ansi(norm_newlines(raw))
    lines = text.split("\n")
    # 1) FBC komut satırını bul: 'fbc.exe ... -x ...'
    start = None
    for i, line in enumerate(lines):
        low = line.lower()
        if ("fbc" in low and "uxm31_runtime_fb_full.bas" in low and " -x " in low):
            start = i + 1
    if start is None:
        # 2) Link markerından sonraki ilk satırı atla.
        for i, line in enumerate(lines):
            if line.strip().lower().startswith("freebasic runtime ile link"):
                start = i + 2
    if start is None:
        return text.strip()

    end = None
    for j in range(start, len(lines)):
        if lines[j].strip() == "[UXM program derlendi.]":
            end = j
            break
    if end is None:
        end = len(lines)

    out_lines = []
    for line in lines[start:end]:
        if any(line.strip().startswith(m) for m in BUILD_MARKERS):
            continue
        out_lines.append(line)
    return "\n".join(out_lines).strip()


def compare_output(spec: ExpectSpec, actual_program: str, returncode: int) -> Tuple[bool, str]:
    if returncode != spec.exit_code:
        return False, f"exit_code expected={spec.exit_code} actual={returncode}"
    if spec.mode == "none":
        return True, "expect yok; sadece exit_code kontrol edildi"
    expected = spec.expected
    if spec.mode == "exact":
        e = normalize_exact(expected, spec.ignore_blank)
        a = normalize_exact(actual_program, spec.ignore_blank)
        return (e == a, "exact")
    if spec.mode == "contains":
        e = normalize_exact(expected, spec.ignore_blank)
        a = normalize_exact(actual_program, spec.ignore_blank)
        return (e in a, "contains")
    e = compact(expected)
    a = compact(actual_program)
    return (e == a, "compact")


@dataclass
class TestResult:
    test: str
    expect: str
    status: str
    seconds: float
    mode: str
    returncode: int
    expected_compact: str
    actual_compact: str
    message: str
    raw_log: str
    program_log: str


class UXMStage17Runner:
    def __init__(self, root: Path, test_dir: Path, out_root: Path, stage: str,
                 build_one: str, build_compiler: bool, stop_on_fail: bool,
                 retire_build: bool):
        self.root = root.resolve()
        self.test_dir = test_dir.resolve()
        self.out_root = out_root.resolve()
        self.stage = str(stage)
        self.build_one = build_one
        self.build_compiler = build_compiler
        self.stop_on_fail = stop_on_fail
        self.retire_build = retire_build
        self.run_id = f"stage_{self.stage}_{now_stamp()}"
        self.run_dir = self.out_root / "stage_runs" / self.run_id
        self.log_dir = self.run_dir / "logs"
        self.program_dir = self.run_dir / "program_outputs"
        self.csv_dir = self.out_root / "csv"
        for d in (self.run_dir, self.log_dir, self.program_dir, self.csv_dir):
            d.mkdir(parents=True, exist_ok=True)
        self.results: List[TestResult] = []

    def run_cmd(self, args: List[str]) -> Tuple[int, str, float]:
        start = time.perf_counter()
        proc = subprocess.run(args, cwd=str(self.root), capture_output=True, text=True,
                              encoding="utf-8", errors="replace", shell=False)
        elapsed = time.perf_counter() - start
        raw = (proc.stdout or "")
        if proc.stderr:
            raw += ("\n" if raw else "") + proc.stderr
        return proc.returncode, raw, elapsed

    def run_build(self) -> bool:
        if not self.build_compiler:
            return True
        bat = self.root / "build_native.bat"
        if not bat.exists():
            print(f"[BUILD FAIL] build_native.bat yok: {bat}")
            return False
        code, raw, sec = self.run_cmd(["cmd", "/c", str(bat)])
        (self.run_dir / "compiler_build.log").write_text(raw, encoding="utf-8", errors="replace")
        print(f"[BUILD] code={code} seconds={sec:.2f}")
        return code == 0

    def find_tests(self) -> List[Path]:
        if not self.test_dir.exists():
            raise FileNotFoundError(f"Test klasoru yok: {self.test_dir}")
        # Sadece tek klasör seviyesi; alt klasör yok.
        return sorted([p for p in self.test_dir.glob("*.uxm") if p.is_file()])

    def run_test(self, test_path: Path, idx: int, total: int) -> TestResult:
        rel = test_path.relative_to(self.root) if test_path.is_relative_to(self.root) else test_path
        expect_path = test_path.with_suffix(".expect")
        spec = read_expect(expect_path)
        safe_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", test_path.stem)
        raw_log = self.log_dir / f"{idx:03d}_{safe_name}.raw.log"
        prog_log = self.program_dir / f"{idx:03d}_{safe_name}.program.txt"
        args = ["cmd", "/c", self.build_one, str(rel), "-x"]
        code, raw, sec = self.run_cmd(args)
        actual_program = extract_program_output(raw)
        ok, message = compare_output(spec, actual_program, code)
        status = "BASARILI" if ok else "BASARISIZ"
        raw_log.write_text(raw, encoding="utf-8", errors="replace")
        prog_log.write_text(actual_program, encoding="utf-8", errors="replace")
        print(f"[{idx:03d}/{total:03d}] {status} {rel} ({sec:.2f} sn) mode={spec.mode}")
        if not ok:
            print(f"        {message}")
            print(f"        beklenen: {compact(spec.expected)[:120]}")
            print(f"        gercek   : {compact(actual_program)[:120]}")
        return TestResult(
            test=str(rel),
            expect=str(expect_path.relative_to(self.root)) if expect_path.exists() and expect_path.is_relative_to(self.root) else str(expect_path),
            status=status,
            seconds=round(sec, 4),
            mode=spec.mode,
            returncode=code,
            expected_compact=compact(spec.expected),
            actual_compact=compact(actual_program),
            message=message,
            raw_log=str(raw_log.relative_to(self.root)) if raw_log.is_relative_to(self.root) else str(raw_log),
            program_log=str(prog_log.relative_to(self.root)) if prog_log.is_relative_to(self.root) else str(prog_log),
        )

    def write_reports(self) -> None:
        results_csv = self.run_dir / f"stage{self.stage}_results.csv"
        history_csv = self.csv_dir / f"test_history_stage{self.stage}_expected.csv"
        summary_json = self.run_dir / f"stage{self.stage}_summary.json"
        report_md = self.run_dir / f"STAGE{self.stage}_EXPECTED_TEST_REPORT.md"
        fields = list(asdict(self.results[0]).keys()) if self.results else [
            "test", "expect", "status", "seconds", "mode", "returncode", "expected_compact", "actual_compact", "message", "raw_log", "program_log"
        ]
        for path, append in ((results_csv, False), (history_csv, True)):
            exists = path.exists() and path.stat().st_size > 0
            with path.open("a" if append else "w", newline="", encoding="utf-8-sig") as f:
                w = csv.DictWriter(f, fieldnames=fields)
                if not append or not exists:
                    w.writeheader()
                for r in self.results:
                    row = {k: safe_text_for_csv(v) for k, v in asdict(r).items()}
                    w.writerow(row)
        total = len(self.results)
        passed = sum(1 for r in self.results if r.status == "BASARILI")
        failed = total - passed
        payload = {
            "stage": self.stage,
            "run_id": self.run_id,
            "root": str(self.root),
            "test_dir": str(self.test_dir),
            "total": total,
            "passed": passed,
            "failed": failed,
            "seconds_total": round(sum(r.seconds for r in self.results), 4),
            "results_csv": str(results_csv),
            "history_csv": str(history_csv),
        }
        summary_json.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
        lines = [
            f"# UXM Stage {self.stage} Expected/Actual Test Report",
            "",
            f"- Run ID: `{self.run_id}`",
            f"- Test klasörü: `{self.test_dir}`",
            f"- Toplam: **{total}**",
            f"- Başarılı: **{passed}**",
            f"- Başarısız: **{failed}**",
            f"- Toplam süre: **{payload['seconds_total']} sn**",
            "",
            "| Durum | Süre | Test | Mod | Not |",
            "|---|---:|---|---|---|",
        ]
        for r in self.results:
            lines.append(f"| {r.status} | {r.seconds:.4f} | `{r.test}` | {r.mode} | {safe_text_for_csv(r.message)} |")
        report_md.write_text("\n".join(lines), encoding="utf-8")
        print(f"[RAPOR] {report_md}")
        print(f"[CSV] {results_csv}")
        print(f"[HISTORY] {history_csv}")

    def retire_build_dir(self) -> None:
        if not self.retire_build:
            return
        build = self.root / "build"
        if not build.exists():
            return
        retired = self.root / "Emekliler" / f"build_stage{self.stage}_{now_stamp()}"
        retired.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(build), str(retired))
        manifest = self.run_dir / "retired_build_manifest.txt"
        rows = [f"RETIRED_BUILD@{retired}"]
        for p in sorted(retired.rglob("*")):
            if p.is_file():
                rows.append(str(p.relative_to(retired)))
        manifest.write_text("\n".join(rows), encoding="utf-8")
        print(f"[EMEKLI] build -> {retired}")

    def run(self) -> int:
        if not self.run_build():
            return 2
        tests = self.find_tests()
        if not tests:
            print(f"[HATA] Test bulunamadi: {self.test_dir}")
            return 3
        total = len(tests)
        for idx, test in enumerate(tests, 1):
            res = self.run_test(test, idx, total)
            self.results.append(res)
            if res.status != "BASARILI" and self.stop_on_fail:
                break
        self.write_reports()
        failed = any(r.status != "BASARILI" for r in self.results)
        self.retire_build_dir()
        return 1 if failed else 0


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="UXM Stage-17 expected/actual test runner")
    parser.add_argument("--stage", default="17")
    parser.add_argument("--root", default=".")
    parser.add_argument("--test-dir", default="uxm/tests/stage17")
    parser.add_argument("--out-root", default="stage17_results")
    parser.add_argument("--build-one", default="build_one_native.bat")
    parser.add_argument("--no-build", action="store_true")
    parser.add_argument("--stop-on-fail", action="store_true")
    parser.add_argument("--retire-build", action="store_true")
    args = parser.parse_args(argv)

    root = Path(args.root)
    test_dir = Path(args.test_dir)
    if not test_dir.is_absolute():
        test_dir = root / test_dir
    out_root = Path(args.out_root)
    if not out_root.is_absolute():
        out_root = root / out_root
    runner = UXMStage17Runner(
        root=root,
        test_dir=test_dir,
        out_root=out_root,
        stage=args.stage,
        build_one=args.build_one,
        build_compiler=not args.no_build,
        stop_on_fail=args.stop_on_fail,
        retire_build=args.retire_build,
    )
    return runner.run()


if __name__ == "__main__":
    raise SystemExit(main())
