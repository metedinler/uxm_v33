@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_stage19_vscode_temizle.py %*
if errorlevel 1 python araclar\uxm_stage19_vscode_temizle.py %*
endlocal
