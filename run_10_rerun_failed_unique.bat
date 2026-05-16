@echo off
setlocal
REM UXM V6 - Sadece benzersiz hatali anahtarlari tekrar kosar.
py -3 tools\UXM_FAST_KEY_SCAN_V6.py --root .
if errorlevel 1 exit /b %errorlevel%
py -3 tools\UXM_EXPECT_RUNNER_V2.py --root . --manifest fast_results\latest\failed_unique_manifest.csv --stage fast_failed_unique_v6 --out-root fast_results\runs %*
exit /b %errorlevel%
