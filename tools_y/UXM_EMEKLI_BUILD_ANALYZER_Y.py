# -*- coding: utf-8 -*-
r"""
UXM_EMEKLI_BUILD_ANALYZER_Y.py
-----------------------------
Emekliler altindaki tum build ciktilarindan ders cikarir.
- asm/obj/exe/log sayar
- loglardan hata kaliplari toplar
- stage/version etiketlerini yakalar
- CSV + Markdown rapor yazar

Kullanim:
  py -3 tools_y\UXM_EMEKLI_BUILD_ANALYZER_Y.py
  py -3 tools_y\UXM_EMEKLI_BUILD_ANALYZER_Y.py --root . --include-active-build
"""
from __future__ import annotations

import argparse
import csv
import re
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Iterable

ERROR_PATTERNS = [
    ("fb_arg_mismatch", re.compile(r"Argument count mismatch", re.I)),
    ("fb_duplicate_definition", re.compile(r"Duplicated definition", re.I)),
    ("fb_variable_not_declared", re.compile(r"Variable not declared", re.I)),
    ("ld_missing", re.compile(r"ld\.exe|Executable not found", re.I)),
    ("syntax_error", re.compile(r"SYNTAX ERROR", re.I)),
    ("nasm_error", re.compile(r"nasm.*error|NASM HATASI", re.I)),
    ("link_error", re.compile(r"LINK HATASI|FreeBASIC runtime ile link", re.I)),
]
VERSION_RE = re.compile(r"\[V(?P<ver>[^\]]+)\]")
STAGE_RE = re.compile(r"stage[ _-]?(\d+)", re.I)


def stamp() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def rel(p: Path, root: Path) -> str:
    try:
        return str(p.resolve().relative_to(root.resolve())).replace("/", "\\")
    except Exception:
        return str(p).replace("/", "\\")


def safe_read(path: Path, limit: int = 300000) -> str:
    try:
        data = path.read_bytes()[:limit]
    except Exception:
        return ""
    for enc in ("utf-8", "cp1254", "cp1252", "latin-1"):
        try:
            return data.decode(enc)
        except UnicodeDecodeError:
            continue
    return data.decode("utf-8", errors="replace")


def find_build_dirs(root: Path, include_active: bool) -> list[Path]:
    dirs = []
    em = root / "Emekliler"
    if em.exists():
        for p in em.rglob("*"):
            if p.is_dir() and ((p / "asm").exists() or (p / "obj").exists() or (p / "exe").exists() or (p / "logs").exists()):
                dirs.append(p)
    if include_active:
        for p in root.iterdir():
            if p.is_dir() and p.name.lower().startswith("build"):
                dirs.append(p)
    # En alt build klasorlerini tekillestir.
    uniq = []
    seen = set()
    for p in sorted(dirs, key=lambda x: str(x).lower()):
        rp = p.resolve()
        if rp not in seen:
            seen.add(rp); uniq.append(p)
    return uniq


def count_files(d: Path, pattern: str) -> int:
    return sum(1 for _ in d.rglob(pattern))


def analyze(root: Path, include_active: bool) -> Path:
    tag = stamp()
    out = root / "y_sonuclar" / "emekli_dersleri" / tag
    out.mkdir(parents=True, exist_ok=True)
    build_rows = []
    error_counter = Counter()
    version_counter = Counter()
    per_build_errors = defaultdict(Counter)

    for b in find_build_dirs(root, include_active):
        text_all = []
        for log in list((b / "logs").rglob("*.log")) + list(b.rglob("*.txt")):
            text = safe_read(log)
            if text:
                text_all.append(text)
                for key, rx in ERROR_PATTERNS:
                    c = len(rx.findall(text))
                    if c:
                        error_counter[key] += c
                        per_build_errors[rel(b, root)][key] += c
                for m in VERSION_RE.finditer(text):
                    version_counter[m.group("ver")] += 1
        joined = "\n".join(text_all[:20])
        stage_guess = ""
        m = STAGE_RE.search(b.name)
        if m:
            stage_guess = m.group(1)
        else:
            m = STAGE_RE.search(joined)
            if m:
                stage_guess = m.group(1)
        build_rows.append([
            rel(b, root), stage_guess, count_files(b, "*.asm"), count_files(b, "*.o") + count_files(b, "*.obj"),
            count_files(b, "*.exe"), count_files(b, "*.log") + count_files(b, "*.txt"),
            "; ".join(f"{k}:{v}" for k, v in per_build_errors[rel(b, root)].most_common())
        ])

    with (out / "emekli_build_inventory_y.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Build_Klasoru", "Stage_Tahmini", "ASM", "OBJ", "EXE", "LOG_TXT", "Hata_Ozeti"])
        w.writerows(build_rows)

    with (out / "emekli_error_patterns_y.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Hata_Kalibi", "Adet"])
        for k, v in error_counter.most_common():
            w.writerow([k, v])

    with (out / "emekli_version_tags_y.csv").open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Version_Tag", "Adet"])
        for k, v in version_counter.most_common():
            w.writerow([k, v])

    md = out / "EMEKLI_BUILD_DERS_RAPORU_Y.md"
    lines = ["# Emekli Build Ders Raporu Y\n\n", f"Toplam build klasoru: {len(build_rows)}\n\n"]
    lines.append("## En Sik Hata Kaliplari\n")
    for k, v in error_counter.most_common(20):
        lines.append(f"- {k}: {v}\n")
    lines.append("\n## Kural\n")
    lines.append("- Aynı hata bütün testlerde görünüyorsa kaynak testler değil runtime include/link katmanıdır.\n")
    lines.append("- Her testte FreeBASIC runtime yeniden derleniyorsa süre katlanır; mümkünse runtime cache veya sadece stage testi kullan.\n")
    lines.append("- ld.exe eksikliği kod hatası değil toolchain kurulum/yol problemidir.\n")
    md.write_text("".join(lines), encoding="utf-8")
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Emekli build ders analizatoru")
    ap.add_argument("--root", default=".")
    ap.add_argument("--include-active-build", action="store_true")
    args = ap.parse_args()
    out = analyze(Path(args.root).resolve(), args.include_active_build)
    print(f"[OK] Rapor klasoru: {out}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
