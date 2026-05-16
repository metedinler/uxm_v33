@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
py -3 tool_en\uxm_workspace_clean.py %*
endlocal
