@echo off
setlocal
py -3 tools\UXM_FAST_KEY_SCAN_V9.py
if errorlevel 1 exit /b %ERRORLEVEL%
py -3 tools\UXM_EXPECT_RUNNER_V6.py --manifest fast_results\latest\failed_unique_manifest.csv --stage fast_failed_unique_v9 --out-root fast_results\runs %*
endlocal
