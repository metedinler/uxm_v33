@echo off
setlocal
py -3 tools\UXM_EXPECT_RUNNER_V5.py --test-dir uxm\tests\memory_model_v7 --recursive --stage memory_model_v8 --out-root expected_results_v5 %*
endlocal
