@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
call stage18_duzelt.bat
call stage18_native.bat
call stage18_kontrol.bat %*
endlocal
