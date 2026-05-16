@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_stage20_performans_release.py --sadece-rapor %*
if errorlevel 1 python araclar\uxm_stage20_performans_release.py --sadece-rapor %*
endlocal
