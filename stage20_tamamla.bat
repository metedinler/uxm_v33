@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
call stage20_kontrol.bat %*
call stage20_release.bat
endlocal
