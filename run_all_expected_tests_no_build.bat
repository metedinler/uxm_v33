@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

if exist "%ROOT%\tools\UXM_ALL_EXPECT_RUNNER.py" (
  py -3 "%ROOT%\tools\UXM_ALL_EXPECT_RUNNER.py" --root "%ROOT%" --manifest "uxm\tests\all_expected_known\ALL_EXPECTED_RUN_LIST.csv" --no-build %*
  if errorlevel 1 exit /b 1
  exit /b 0
)

echo HATA: tools\UXM_ALL_EXPECT_RUNNER.py bulunamadi.
exit /b 1
