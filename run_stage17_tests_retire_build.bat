@echo off
setlocal
REM Stage-17 testlerinden sonra build klasorunu Emekliler altina tasir.
call run_stage17_tests.bat --retire-build %*
exit /b %ERRORLEVEL%
