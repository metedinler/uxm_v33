@echo off
setlocal EnableExtensions
rem UXM Stage Runner tek komut girisi.
rem Stage otomatik: run_stage_auto.bat
rem Elle stage:      run_stage_auto.bat 12

set "STAGE_ARG=auto"
if not "%~1"=="" set "STAGE_ARG=%~1"

where py >nul 2>nul
if %errorlevel%==0 (
    py -3 UXM_STAGE_RUNNER.py --stage %STAGE_ARG%
) else (
    python UXM_STAGE_RUNNER.py --stage %STAGE_ARG%
)

exit /b %errorlevel%
