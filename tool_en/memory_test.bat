@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
py -3 tool_en\uxm_test_run.py -t uxm\tests\bellek_v11 -o memory_results %*
endlocal
