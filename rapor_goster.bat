@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_rapor_goster.py %*
endlocal
