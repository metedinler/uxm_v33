#!/usr/bin/env python3
"""UXM Tool Launcher V5
Kök klasörü kalabalıklaştırmadan tools/uxm_ops altındaki aracı geçici kopya ile çalıştırır.
V4 hatası düzeltildi: --apply gibi alt araç argümanları artık launcher tarafından yenmez.
"""
import argparse
import subprocess
import sys
import shutil
from pathlib import Path

TOOLS = {
    "fix_mismatch": "tools/uxm_ops/UXM_FIX_KNOWN_MISMATCHES_V5.py",
    "diag_mismatch": "tools/uxm_ops/UXM_MISMATCH_DIAGNOSER_V5.py",
    "workspace": "tools/uxm_ops/UXM_WORKSPACE_ORGANIZER_V5.py",
    "emekli": "tools/uxm_ops/UXM_EMEKLI_BUILD_ANALYZER_V5.py",
}


def main() -> int:
    parser = argparse.ArgumentParser(description="UXM V5 tool launcher")
    parser.add_argument("--tool", required=True, choices=sorted(TOOLS), help="Çalıştırılacak alt araç")
    # parse_known_args: V4'teki kritik düzeltme. --apply/--retire-build alt araca iletilir.
    ns, rest = parser.parse_known_args()

    # Kullanıcı bat üzerinden yanlışlıkla tekrar --tool gönderirse sessizce temizle.
    cleaned = []
    skip_next = False
    for i, arg in enumerate(rest):
        if skip_next:
            skip_next = False
            continue
        if arg == "--tool":
            skip_next = True
            continue
        if arg.startswith("--tool="):
            continue
        cleaned.append(arg)

    root = Path.cwd()
    src = root / TOOLS[ns.tool]
    if not src.exists():
        print("Tool bulunamadi:", src)
        return 2

    tmp_dir = root / ".uxm_active_tool_tmp"
    tmp_dir.mkdir(exist_ok=True)
    tmp = tmp_dir / (src.stem + "__active.py")
    shutil.copy2(src, tmp)
    try:
        cmd = [sys.executable, str(tmp)] + cleaned
        return subprocess.call(cmd)
    finally:
        try:
            tmp.unlink()
        except OSError:
            pass
        try:
            tmp_dir.rmdir()
        except OSError:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
