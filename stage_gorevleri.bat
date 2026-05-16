@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_stage_gorevleri.py %*
if errorlevel 1 python araclar\uxm_stage_gorevleri.py %*
endlocal
