@echo off
setlocal
py -3 tools\UXM_EXPECT_RUNNER_V4.py --manifest manifest\ALL_EXPECTED_RUN_LIST.csv --stage all_expected_v7 --out-root expected_results_v4 %*
endlocal
