@echo off
setlocal EnableExtensions
rem AYRI Y HATTI: Tum mevcut testleri calistirir, ana sonuc*.txt dosyalarina dokunmaz.
set "STAGE_ARG=%~1"
if "%STAGE_ARG%"=="" set "STAGE_ARG=15"
if exist "%~dp0UXM_STAGE_RUNNER_Y.py" (
  py -3 "%~dp0UXM_STAGE_RUNNER_Y.py" --stage %STAGE_ARG% --scope full
) else (
  py -3 "tools_y\UXM_STAGE_RUNNER_Y.py" --stage %STAGE_ARG% --scope full
)
exit /b %errorlevel%
