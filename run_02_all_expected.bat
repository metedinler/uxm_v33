@echo off
setlocal
if exist tools\UXM_EXPECT_RUNNER_V3.py (
  py -3 tools\UXM_EXPECT_RUNNER_V3.py --test-dir uxm\tests\all_expected_known %*
) else if exist tools\UXM_EXPECT_RUNNER_V2.py (
  py -3 tools\UXM_EXPECT_RUNNER_V2.py --test-dir uxm\tests\all_expected_known %*
) else if exist tools\UXM_ALL_EXPECT_RUNNER.py (
  py -3 tools\UXM_ALL_EXPECT_RUNNER.py %*
) else (
  echo HATA: expected runner bulunamadi.
  exit /b 2
)
endlocal
