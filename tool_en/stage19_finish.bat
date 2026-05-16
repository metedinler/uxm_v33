@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
call tool_en\stage19_cleanup.bat -u
call tool_en\vscode_install.bat -u
call tool_en\stage19_check.bat %*
endlocal
