@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
py -3 tool_en\uxm_stage20_performance_release.py --report-only %*
if errorlevel 1 python tool_en\uxm_stage20_performance_release.py --report-only %*
endlocal
