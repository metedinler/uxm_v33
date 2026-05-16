#!/usr/bin/env python3
"""
Forwarder for UXM comm watcher under VSCode extension src tree.

This keeps runtime behavior centralized in tools/vscode_integration/comm_watcher.py
while allowing source placement under vscode/.../src.
"""
from pathlib import Path
import runpy
import sys


def find_workspace_root(start_file: Path):
    for p in [start_file.parent, *start_file.parents]:
        target = p / "tools" / "vscode_integration" / "comm_watcher.py"
        if target.exists():
            return p
    return None


here = Path(__file__).resolve()
root = find_workspace_root(here)
if root is None:
    sys.stderr.write("HATA: tools/vscode_integration/comm_watcher.py bulunamadi.\n")
    raise SystemExit(1)

target = root / "tools" / "vscode_integration" / "comm_watcher.py"
sys.argv[0] = str(target)
runpy.run_path(str(target), run_name="__main__")
