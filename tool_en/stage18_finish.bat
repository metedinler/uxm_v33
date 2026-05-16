@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0\.."
call tool_en\expect_fix.bat
call tool_en\stage18_native.bat
call tool_en\stage18_check.bat %*
endlocal
