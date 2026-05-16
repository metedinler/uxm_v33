@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
py -3 tool_en\uxm_fast_scan.py -o fast_results\latest
if errorlevel 1 exit /b %ERRORLEVEL%
py -3 tool_en\uxm_test_run.py -m fast_results\latest\failed_unique_manifest.csv -o failed_results %*
endlocal
