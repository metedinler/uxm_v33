@echo off
setlocal
REM UXM V6 - CSV anahtar tarama. 1054 testi kosmadan hatali anahtarlari cikarir.
py -3 tools\UXM_FAST_KEY_SCAN_V6.py --root . %*
if errorlevel 1 exit /b %errorlevel%
endlocal
