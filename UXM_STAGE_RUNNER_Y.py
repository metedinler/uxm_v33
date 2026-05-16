# -*- coding: utf-8 -*-
r"""
UXM_STAGE_RUNNER_Y.py
---------------------
Mete abi icin AYRI SONUC HATTI.

Amaç:
- Mevcut build_native.bat ve build_one_native.bat dosyalarini kullanir.
- Eski test/bat dosyalarini yeniden uretmez.
- Sonuclari ana dosyalara degil y_sonuclar/ altindaki yeni CSV/log dosyalarina yazar.
- Stage bazli test klasoru varsa sadece onu calistirabilir.
- Full test istenirse mevcut test klasorlerini de calistirabilir.
- Istenirse is bitince aktif build klasorunu Emekliler/builds altina tasimak icin toparlayiciyi cagirir.

Kullanim:
  py -3 tools_y\UXM_STAGE_RUNNER_Y.py --stage 15 --scope stage
  py -3 tools_y\UXM_STAGE_RUNNER_Y.py --stage 15 --scope full
  py -3 tools_y\UXM_STAGE_RUNNER_Y.py --stage 15 --test-dir uxm\tests\stage15_16
  py -3 tools_y\UXM_STAGE_RUNNER_Y.py --stage 15 --scope stage --retire-build
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Iterable, List, Optional, Tuple

ILLEGAL_XLSX_CHARS_RE = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")


def stamp() -> str:
    return dt.datetime.now().strftime("%Y%m%d_%H%M%S")


def human() -> str:
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def safe_cell(value) -> str:
    if value is None:
        return ""
    s = str(value)
    return ILLEGAL_XLSX_CHARS_RE.sub(lambda m: "\\x%02X" % ord(m.group(0)), s)


def ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)


def rel(p: Path, root: Path) -> str:
    try:
        return str(p.resolve().relative_to(root.resolve())).replace("/", "\\")
    except Exception:
        return str(p).replace("/", "\\")


def write_csv(path: Path, header: List[str], rows: Iterable[List]) -> None:
    ensure_dir(path.parent)
    exists = path.exists() and path.stat().st_size > 0
    with path.open("a", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        if not exists:
            w.writerow(header)
        for row in rows:
            w.writerow([safe_cell(x) for x in row])


def decode_bytes(data: bytes) -> str:
    for enc in ("utf-8", "cp1254", "cp1252", "latin-1"):
        try:
            return data.decode(enc)
        except UnicodeDecodeError:
            pass
    return data.decode("utf-8", errors="replace")


def run_cmd(cmd: str, cwd: Path, timeout: Optional[int] = None) -> Tuple[int, str, str, float]:
    t0 = time.perf_counter()
    try:
        p = subprocess.run(cmd, cwd=str(cwd), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
        return p.returncode, decode_bytes(p.stdout), decode_bytes(p.stderr), time.perf_counter() - t0
    except subprocess.TimeoutExpired as exc:
        out = decode_bytes(exc.stdout or b"")
        err = decode_bytes(exc.stderr or b"") + f"\n[TIMEOUT] {timeout} saniye asildi."
        return 124, out, err, time.perf_counter() - t0


def compact_output(text: str) -> str:
    # Beklenen/gerceklesen karsilastirma icin sade cikti.
    # UXM derleme/link gurultusunu atar, kalan program ciktilarini sikistirir.
    lines = []
    skip_markers = (
        "ASM uretildi:", "[V3.3-", "NASM:", "nasm -f", "FreeBASIC runtime", "C:\\", "[UXM program derlendi.]",
    )
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if any(line.startswith(m) for m in skip_markers):
            continue
        if "fbc.exe" in line or "build\\obj" in line or "build\\exe" in line:
            continue
        if line.startswith("error ") or " error " in line.lower():
            lines.append(line)
            continue
        lines.append(line)
    out = "".join(lines)
    # Kontrol karakterleri logda dursun ama compact beklenen icin silinsin.
    return "".join(ch for ch in out if (ord(ch) >= 32 and not ch.isspace()))


def detect_stage_tests(root: Path, stage: int) -> List[Path]:
    candidates = [
        root / "uxm" / "tests" / f"stage{stage}",
        root / "uxm" / "tests" / f"stage{stage}_16" if stage == 15 else root / "__never__",
        root / "uxm" / "tests" / "stage15_16" if stage in (15, 16) else root / "__never2__",
        root / "uxm" / "tests" / "v33" / f"stage{stage}",
        root / "uxm" / "tests" / "v33" / "stage15_16" if stage in (15, 16) else root / "__never3__",
    ]
    tests: List[Path] = []
    seen = set()
    for d in candidates:
        if d.exists() and d.is_dir():
            for p in sorted(d.glob("*.uxm"), key=lambda x: x.name.lower()):
                rp = p.resolve()
                if rp not in seen:
                    seen.add(rp)
                    tests.append(p)
    return tests


def detect_full_tests(root: Path) -> List[Path]:
    base = root / "uxm" / "tests"
    priority = [base / "fp", base / "math", base / "matrix", base / "native", base / "v33"]
    tests: List[Path] = []
    seen = set()
    for d in priority:
        if d.exists():
            for p in sorted(d.glob("*.uxm"), key=lambda x: x.name.lower()):
                if p.name.startswith("_"):
                    continue
                rp = p.resolve()
                if rp not in seen:
                    seen.add(rp); tests.append(p)
    if base.exists():
        for p in sorted(base.rglob("*.uxm"), key=lambda x: rel(x, root).lower()):
            if p.name.startswith("_"):
                continue
            rp = p.resolve()
            if rp not in seen:
                seen.add(rp); tests.append(p)
    return tests


def load_expect(test: Path) -> str:
    exp = test.with_suffix(".expect")
    if exp.exists():
        return compact_output(exp.read_text(encoding="utf-8", errors="replace"))
    return ""


class RunnerY:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.root = Path(args.root).resolve()
        self.stage = int(args.stage)
        self.run_stamp = stamp()
        self.out_root = self.root / "y_sonuclar"
        self.run_dir = self.out_root / "stage_runs" / f"stage_{self.stage}_{self.run_stamp}"
        self.log_dir = self.run_dir / "logs"
        self.csv_dir = self.out_root / "csv"
        ensure_dir(self.log_dir); ensure_dir(self.csv_dir)
        self.result_rows = []

    def build_compiler(self) -> bool:
        bat = self.root / "build_native.bat"
        if not bat.exists():
            print(f"[HATA] build_native.bat yok: {bat}")
            return False
        code, out, err, sec = run_cmd(str(bat), self.root, timeout=self.args.timeout_build)
        (self.log_dir / "build_native_y.log").write_text(out + err, encoding="utf-8", errors="replace")
        print(f"[BUILD] code={code} sure={sec:.2f} sn")
        return code == 0

    def choose_tests(self) -> List[Path]:
        if self.args.test_dir:
            d = (self.root / self.args.test_dir).resolve()
            return sorted(d.glob("*.uxm"), key=lambda x: x.name.lower()) if d.exists() else []
        if self.args.scope == "stage":
            return detect_stage_tests(self.root, self.stage)
        return detect_full_tests(self.root)

    def run_one(self, idx: int, total: int, test: Path) -> None:
        bat = self.root / "build_one_native.bat"
        if not bat.exists():
            raise FileNotFoundError(bat)
        rtest = rel(test, self.root)
        log_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", test.stem) + ".log"
        log_file = self.log_dir / log_name
        cmd = f'"{bat}" "{test}" -x'
        code, out, err, sec = run_cmd(cmd, self.root, timeout=self.args.timeout_test)
        full = out + err
        log_file.write_text(full, encoding="utf-8", errors="replace")
        actual = compact_output(full)
        expected = load_expect(test)
        status = "BASARILI" if code == 0 and "error " not in full.lower() else "BASARISIZ"
        if expected:
            status = "BASARILI" if actual == expected and status == "BASARILI" else "UYUSMAZ"
        print(f"[{idx:03d}/{total:03d}] {status} {rtest} ({sec:.2f} sn)")
        self.result_rows.append([
            human(), self.stage, rtest, test.name, status, code, f"{sec:.4f}", expected, actual, rel(log_file, self.root)
        ])

    def write_reports(self) -> None:
        hist = self.csv_dir / "test_history_y.csv"
        summary = self.csv_dir / "test_stats_summary_y.csv"
        write_csv(hist,
                  ["Tarih", "Stage", "Test_Yolu", "Test_Adi", "Durum", "ReturnCode", "Sure_Sn", "Beklenen", "Gerceklesen", "Log"],
                  self.result_rows)
        # Ozet son kosu + tarihce birlikte okunur.
        rows = []
        if hist.exists():
            with hist.open("r", encoding="utf-8-sig", errors="replace", newline="") as f:
                rd = csv.DictReader(f)
                groups = {}
                for row in rd:
                    name = row.get("Test_Yolu", "")
                    if not name:
                        continue
                    try:
                        sec = float((row.get("Sure_Sn") or "0").replace(",", "."))
                    except Exception:
                        sec = 0.0
                    groups.setdefault(name, []).append((sec, row.get("Durum", "")))
                for name, vals in sorted(groups.items()):
                    secs = [x[0] for x in vals]
                    rows.append([name, len(vals), f"{sum(secs)/len(secs):.4f}", f"{min(secs):.4f}", f"{max(secs):.4f}", vals[-1][1]])
        with summary.open("w", encoding="utf-8-sig", newline="") as f:
            w = csv.writer(f)
            w.writerow(["Test_Yolu", "Kosma_Sayisi", "Ortalama_Sure", "Min_Sure", "Max_Sure", "Son_Durum"])
            w.writerows(rows)
        md = self.run_dir / "RUN_SUMMARY_Y.md"
        ok = sum(1 for r in self.result_rows if r[4] == "BASARILI")
        bad = len(self.result_rows) - ok
        md.write_text(f"# UXM Y Hatti Kosu Ozeti\n\nStage: {self.stage}\nTest: {len(self.result_rows)}\nBASARILI: {ok}\nSorunlu: {bad}\nCSV: y_sonuclar/csv/test_history_y.csv\n", encoding="utf-8")

    def retire_build(self) -> None:
        tool = self.root / "tools_y" / "UXM_WORKSPACE_TOPARLAYICI_Y.py"
        if not tool.exists():
            print("[UYARI] toparlayici bulunamadi; build emekliligi atlandi.")
            return
        cmd = f'"{sys.executable}" "{tool}" --stage {self.stage} --apply --retire-current-build --only-builds'
        code, out, err, sec = run_cmd(cmd, self.root, timeout=180)
        (self.log_dir / "retire_build_y.log").write_text(out + err, encoding="utf-8", errors="replace")
        print(f"[EMEKLI BUILD] code={code} sure={sec:.2f} sn")

    def run(self) -> int:
        print(f"UXM Y Runner basladi: stage={self.stage}, scope={self.args.scope}")
        print(f"Run dir: {self.run_dir}")
        build_ok = True if self.args.no_build else self.build_compiler()
        if not build_ok and not self.args.continue_on_build_fail:
            return 2
        tests = self.choose_tests()
        if not tests:
            print("[HATA] Calistirilacak test bulunamadi.")
            return 3
        for i, test in enumerate(tests, 1):
            self.run_one(i, len(tests), test)
        self.write_reports()
        if self.args.retire_build:
            self.retire_build()
        return 0 if all(r[4] == "BASARILI" for r in self.result_rows) else 1


def main() -> int:
    ap = argparse.ArgumentParser(description="UXM ayri sonuc hatti runner")
    ap.add_argument("--root", default=".")
    ap.add_argument("--stage", required=True)
    ap.add_argument("--scope", choices=["stage", "full"], default="stage")
    ap.add_argument("--test-dir", default="")
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("--continue-on-build-fail", action="store_true")
    ap.add_argument("--retire-build", action="store_true")
    ap.add_argument("--timeout-build", type=int, default=180)
    ap.add_argument("--timeout-test", type=int, default=240)
    return RunnerY(ap.parse_args()).run()


if __name__ == "__main__":
    raise SystemExit(main())
