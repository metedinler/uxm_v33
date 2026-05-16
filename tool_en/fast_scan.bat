@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
py -3 tool_en\uxm_fast_scan.py -o fast_results\latest %*
endlocal
