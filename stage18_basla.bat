@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_test_kos.py -m manifests\stage18_manifest.csv -o sonuclar_stage18 %*
if errorlevel 1 python araclar\uxm_test_kos.py -m manifests\stage18_manifest.csv -o sonuclar_stage18 %*
endlocal
