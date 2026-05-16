@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_test_kos.py -m manifests\stage17_manifest.csv -o sonuclar_stage17 %*
if errorlevel 1 python araclar\uxm_test_kos.py -m manifests\stage17_manifest.csv -o sonuclar_stage17 %*
endlocal
