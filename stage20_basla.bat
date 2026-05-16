@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_test_kos.py -m manifests\stage20_manifest.csv -o sonuclar_stage20 %*
if errorlevel 1 python araclar\uxm_test_kos.py -m manifests\stage20_manifest.csv -o sonuclar_stage20 %*
endlocal
