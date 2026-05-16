@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
py -3 tool_en\uxm_stage_tasks.py %*
if errorlevel 1 python tool_en\uxm_stage_tasks.py %*
endlocal
