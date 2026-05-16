@echo off
setlocal
py -3 tools\UXM_FAST_KEY_SCAN_V9.py %*
if errorlevel 1 exit /b %ERRORLEVEL%
endlocal
