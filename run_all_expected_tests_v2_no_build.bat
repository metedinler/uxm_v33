@echo off
setlocal EnableExtensions
py -3 tools\UXM_EXPECT_RUNNER_V2.py --stage all_expected_v2 --manifest uxm\tests\all_expected_known\ALL_EXPECTED_RUN_LIST.csv --no-build %*
if errorlevel 1 exit /b 1
exit /b 0
