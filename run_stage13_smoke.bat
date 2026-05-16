@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem UXM V3.3 Stage-13 smoke runner
rem Only Stage-13 tests are executed. Existing older tests are not regenerated or rerun here.

set "TESTDIR=uxm\tests\v33\stage13"
set "LOGDIR=build\logs\stage13"
set FAIL=0
set COUNT=0

if not exist build mkdir build
if not exist build\logs mkdir build\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

call build_native.bat > "%LOGDIR%\stage13_build.log" 2>&1
if errorlevel 1 (
  echo [FAIL_BUILD] build_native.bat
  type "%LOGDIR%\stage13_build.log"
  exit /b 1
)
echo [OK] compiler build

if not exist "%TESTDIR%\*.uxm" (
  echo [FAIL] Stage-13 test klasoru bulunamadi: %TESTDIR%
  exit /b 1
)

for %%F in ("%TESTDIR%\*.uxm") do (
  call :RUN_ONE "%%~fF"
)

if not "%FAIL%"=="0" (
  echo [STAGE13_SMOKE_FAIL] %COUNT% test calisti, hata var.
  exit /b 1
)

echo [STAGE13_SMOKE_OK] %COUNT% test basarili.
exit /b 0

:RUN_ONE
set /a COUNT+=1
set "SRC=%~1"
set "NAME=%~n1"
set "LOG=%LOGDIR%\%NAME%.log"
set "EXPECT=%~dpn1.expect"

echo ----------------------------------------
echo [TEST] %SRC%

if not exist "%EXPECT%" (
  echo [FAIL_EXPECT_MISSING] %EXPECT%
  set FAIL=1
  exit /b 0
)

call build_one_native.bat "%SRC%" -x > "%LOG%" 2>&1
if errorlevel 1 (
  echo [FAIL_BUILD_TEST] %SRC%
  type "%LOG%"
  set FAIL=1
  exit /b 0
)

set "EXPECT_FILE=%EXPECT%"
set "LOG_FILE=%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$e=(Get-Content -Raw $env:EXPECT_FILE).Trim(); $l=Get-Content -Raw $env:LOG_FILE; $ec=($e -replace '\s+',''); $lc=($l -replace '\s+',''); if($lc.Contains($ec)){exit 0}else{Write-Host '[EXPECT_MISMATCH] expected=' $e; exit 1}"
if errorlevel 1 (
  echo [FAIL_OUTPUT] %SRC%
  type "%LOG%"
  set FAIL=1
) else (
  echo [OK] %SRC%
)
exit /b 0
