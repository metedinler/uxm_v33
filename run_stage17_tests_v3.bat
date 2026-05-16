@echo off
setlocal
py -3 tools\UXM_EXPECT_RUNNER_V3.py --root . --stage stage17_v3 --test-dir uxm\tests\stage17 %*
if errorlevel 1 exit /b 1
exit /b 0
