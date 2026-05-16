#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kısmi Commodore 64 BASIC -> UXM kod üreteci.
Destek: PRINT, REM, LET/sayı atama, POKE, PEEK. POKE/PEEK için istenen politika:
POKE adres,değer -> o data adresine değer yazılır. PEEK(adres) -> o adresten oku/yazdır.
"""
import argparse, re
from pathlib import Path
from uxm_qbasic_to_uxm import QBToUXM

class C64ToUXM(QBToUXM):
    def translate_line(self, raw):
        line = self.strip_lineno(raw).strip()
        # C64 kısayolları
        line = re.sub(r'^\?', 'PRINT ', line)
        up=line.upper()
        if up.startswith('SYS'):
            self.out.append('# TODO_C64_SYS_IGNORED: '+line); return
        if up.startswith('GOTO') or up.startswith('GOSUB') or up.startswith('RETURN'):
            self.out.append('# TODO_C64_FLOW_UNSUPPORTED: '+line); return
        super().translate_line(line)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('input')
    ap.add_argument('-o','--output')
    ns=ap.parse_args()
    src=Path(ns.input).read_text(encoding='utf-8', errors='replace')
    out=C64ToUXM().translate(src)
    if ns.output: Path(ns.output).write_text(out, encoding='utf-8')
    else: print(out)
if __name__=='__main__': main()
