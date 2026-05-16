@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_hizli_tara.py -o hizli_sonuclar\son %*
endlocal
