@echo off
REM Starts comm_watcher as a detached background process and runs UXM command
setlocal
set WATCHER=tools\vscode_integration\comm_watcher.py

where python >nul 2>&1
if %errorlevel% neq 0 (
  echo Python not found in PATH. Skipping comm_watcher startup.
  goto run_cmd
)

echo Starting comm_watcher...
powershell -Command "Start-Process python -ArgumentList '%WATCHER%' -WindowStyle Hidden" 2>nul

REM give watcher a moment to initialize
timeout /t 1 /nobreak >nul

:run_cmd
if "%~1"=="" (
  if exist build\exe\uxm_native.exe (
    echo Running UXM executable...
    build\exe\uxm_native.exe
  ) else (
    echo No command provided and build\\exe\\uxm_native.exe not found.
    echo Usage: %~nx0 [command...]
  )
) else (
  "%*"
)
endlocal
