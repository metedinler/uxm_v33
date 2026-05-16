@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
call stage17_duzelt.bat
call stage17_kontrol.bat %*
endlocal
