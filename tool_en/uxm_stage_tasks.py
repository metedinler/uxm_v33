# -*- coding: utf-8 -*-
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'araclar'))
from uxm_stage_gorevleri import main
raise SystemExit(main())
