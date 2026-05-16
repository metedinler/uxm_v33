@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_test_kos.py -t uxm\tests\all_expected_known -o sonuclar_tum %*
endlocal
