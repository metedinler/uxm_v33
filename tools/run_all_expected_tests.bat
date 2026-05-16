@echo off
REM Run all expected tests using available UXM_EXPECT runner (v4 preferred)
if exist tools\UXM_EXPECT_RUNNER_V4.py (
  py -3 tools\UXM_EXPECT_RUNNER_V4.py --manifest manifest\ALL_EXPECTED_RUN_LIST.csv --stage all_expected_v7 --out-root expected_results_v4 %%*
) else if exist tools\UXM_EXPECT_RUNNER_V3.py (
  py -3 tools\UXM_EXPECT_RUNNER_V3.py --test-dir uxm\tests\all_expected_known %%*
) else (
  echo UXM expect runner bulunamadi. Lütfen tools\ dizininde UXM_EXPECT_RUNNER_*.py'yi kontrol edin.
  exit /b 1
)
