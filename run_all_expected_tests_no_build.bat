@echo off
setlocal
py -3 tools\UXM_ALL_EXPECT_RUNNER.py --root . --manifest uxm\tests\all_expected_known\ALL_EXPECTED_RUN_LIST.csv --no-build %*
if errorlevel 1 exit /b 1
exit /b 0
