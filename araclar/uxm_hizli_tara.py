# -*- coding: utf-8 -*-
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ortak'))
from uxm_arac_cekirdek import fast_scan
raise SystemExit(fast_scan('tr'))
