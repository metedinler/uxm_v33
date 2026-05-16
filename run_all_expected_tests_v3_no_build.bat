@echo off
setlocal
py -3 tools\UXM_EXPECT_RUNNER_V3.py --root . --stage all_expected_v3 --manifest manifest\ALL_EXPECTED_RUN_LIST.csv --no-build %*
if errorlevel 1 exit /b 1
exit /b 0
