@echo off
setlocal
py -3 tools\UXM_FAST_KEY_SCAN_V8.py --only memory
if errorlevel 1 exit /b %ERRORLEVEL%
py -3 tools\UXM_EXPECT_RUNNER_V5.py --manifest fast_results\latest\failed_unique_manifest.csv --stage fast_memory_v8 --out-root fast_results\runs %*
endlocal
