@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
py -3 araclar\uxm_hizli_tara.py -o hizli_sonuclar\son
if errorlevel 1 exit /b %ERRORLEVEL%
py -3 araclar\uxm_test_kos.py -m hizli_sonuclar\son\hatali_tekil_manifest.csv -o sonuclar_hatali %*
endlocal
