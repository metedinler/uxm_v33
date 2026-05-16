@echo off
setlocal
py -3 tools\UXM_EXPECT_RUNNER_V5.py --manifest manifest\ALL_EXPECTED_RUN_LIST.csv --stage all_expected_v8 --out-root expected_results_v5 %*
endlocal
