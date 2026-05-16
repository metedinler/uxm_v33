@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
call tool_en\stage20_check.bat %*
call tool_en\stage20_release.bat
endlocal
