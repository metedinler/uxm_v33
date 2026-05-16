@echo off
setlocal EnableExtensions
set "STAGE_ARG=%~1"
if "%STAGE_ARG%"=="" set "STAGE_ARG=16"
py -3 tools_y\UXM_WORKSPACE_TOPARLAYICI_Y.py --stage %STAGE_ARG%
exit /b %errorlevel%
