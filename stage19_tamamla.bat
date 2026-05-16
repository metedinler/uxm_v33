@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
call stage19_temizle.bat -u
call vscode_kur.bat -u
call stage19_kontrol.bat %*
endlocal
