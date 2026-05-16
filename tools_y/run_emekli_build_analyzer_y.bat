@echo off
setlocal EnableExtensions
py -3 tools_y\UXM_EMEKLI_BUILD_ANALYZER_Y.py --include-active-build
exit /b %errorlevel%
