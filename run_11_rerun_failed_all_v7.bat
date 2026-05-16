@echo off
setlocal
py -3 tools\UXM_FAST_KEY_SCAN_V7.py
py -3 tools\UXM_EXPECT_RUNNER_V4.py --manifest fast_results\latest\failed_all_manifest.csv --stage fast_failed_all_v7 --out-root fast_results\runs %*
endlocal
