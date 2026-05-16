@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_test_kos.py -t uxm\tests\bellek_v11 -o sonuclar_bellek %*
endlocal
