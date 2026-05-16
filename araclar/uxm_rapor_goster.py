# -*- coding: utf-8 -*-
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'ortak'))
from uxm_arac_cekirdek import show_report
raise SystemExit(show_report('tr'))
