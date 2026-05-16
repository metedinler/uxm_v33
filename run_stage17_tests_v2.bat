@echo off
setlocal EnableExtensions
py -3 tools\UXM_EXPECT_RUNNER_V2.py --stage stage17_fixed --test-dir uxm\tests\stage17 %*
if errorlevel 1 exit /b 1
exit /b 0
