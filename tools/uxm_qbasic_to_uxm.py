#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kısmi QBasic -> UXM dönüştürücü.
Destek: REM, PRINT "...", PRINT sayı, LET/değişken=sayı, PRINT değişken,
CLS, POKE addr,val, PRINT PEEK(addr). Döngü/IF/GOTO satırlarını güvenli yorum olarak bırakır.
"""
import argparse, re
from pathlib import Path

class QBToUXM:
    def __init__(self):
        self.var_slot = {}
        self.next_slot = 1000
        self.string_id = 1
        self.out = ["#memory tape=256,stack=32,data=8192,queue=16", "#cell dword", "#mode normal", ">>>>>"]
    def slot(self, name):
        name = name.upper().rstrip('$')
        if name not in self.var_slot:
            self.var_slot[name] = self.next_slot
            self.next_slot += 1
        return self.var_slot[name]
    def strip_lineno(self, line):
        return re.sub(r"^\s*\d+\s+", "", line.rstrip())
    def emit_print_string(self, text):
        sid = self.string_id; self.string_id += 1
        text = text.replace('}', ')').replace('\n', '\\n')
        self.out.append(f"s{sid}=0,{{{text}\\n}}")
        self.out.append(f"p{sid}")
    def emit_print_number(self, n):
        self.out.append(f"0(T)+k{int(n)}")
        self.out.append("@61")
    def emit_print_var(self, v):
        self.out.append(f"0(T-1)+k{self.slot(v)}")
        self.out.append("@95")
        self.out.append("@61")
    def translate_line(self, raw):
        line = self.strip_lineno(raw).strip()
        if not line: return
        up = line.upper()
        if up.startswith("REM") or line.startswith("'"):
            self.out.append("# " + line)
            return
        if up == "CLS":
            self.out.append("@1")
            return
        m = re.match(r'PRINT\s+"(.*)"\s*$', line, re.I)
        if m:
            self.emit_print_string(m.group(1)); return
        m = re.match(r'PRINT\s+(-?\d+)\s*$', line, re.I)
        if m:
            self.emit_print_number(m.group(1)); return
        m = re.match(r'PRINT\s+PEEK\((\d+)\)\s*$', line, re.I)
        if m:
            self.out.append(f"0(T-1)+k{m.group(1)}")
            self.out.append("@95")
            self.out.append("@61")
            return
        m = re.match(r'PRINT\s+([A-Za-z][A-Za-z0-9\$]*)\s*$', line, re.I)
        if m:
            self.emit_print_var(m.group(1)); return
        m = re.match(r'(?:LET\s+)?([A-Za-z][A-Za-z0-9\$]*)\s*=\s*(-?\d+)\s*$', line, re.I)
        if m:
            self.out.append(f"0(D:{self.slot(m.group(1))})+k{m.group(2)}")
            return
        m = re.match(r'POKE\s+(\d+)\s*,\s*(-?\d+)\s*$', line, re.I)
        if m:
            self.out.append(f"0(D:{m.group(1)})+k{m.group(2)}")
            return
        self.out.append("# TODO_QBASIC_UNSUPPORTED: " + line)
    def translate(self, text):
        for raw in text.splitlines(): self.translate_line(raw)
        return "\n".join(self.out) + "\n"

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('input')
    ap.add_argument('-o','--output')
    ns=ap.parse_args()
    src=Path(ns.input).read_text(encoding='utf-8', errors='replace')
    out=QBToUXM().translate(src)
    if ns.output: Path(ns.output).write_text(out, encoding='utf-8')
    else: print(out)
if __name__=='__main__': main()
