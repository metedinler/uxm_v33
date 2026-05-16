@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem UXM V3.3 Stage-11 smoke + expected-output checks
rem Bu smoke test sadece derleniyor mu diye bakmaz; yeni Stage-11 testlerinde beklenen compact çıktıyı da arar.

set FAIL=0
if not exist build mkdir build
if not exist build\logs mkdir build\logs

call build_native.bat > build\logs\stage11_smoke_build.log 2>&1
if errorlevel 1 (
  echo [FAIL] build_native.bat
  type build\logs\stage11_smoke_build.log
  exit /b 1
)
echo [OK] compiler build

call :RUN_EXPECT uxm\tests\fp\test_fp01_add_int.uxm fp_base 46
call :RUN_EXPECT uxm\tests\native\test05_meta_add.uxm native_meta 30
call :RUN_EXPECT uxm\tests\v33\test_v33_tensor3d_index_slice.uxm tensor3d_index_slice 772377
call :RUN_EXPECT uxm\tests\v33\test_v33_tensor4d_flat.uxm tensor4d_flat 8811
call :RUN_EXPECT uxm\tests\v33\test_v33_tensor_add_scalar_same.uxm tensor_add_scalar_same 218142

if not "%FAIL%"=="0" (
  echo [SMOKE FAIL] Stage-11 smoke/expected kontrolunde hata var.
  exit /b 1
)
echo [SMOKE OK] Stage-11 smoke + expected-output testleri gecti.
exit /b 0

:RUN_EXPECT
set SRC=%~1
set TAG=%~2
set EXPECT=%~3
echo ----------------------------------------
echo [TEST] %SRC%
call build_one_native.bat "%SRC%" -x > "build\logs\stage11_smoke_%TAG%.log" 2>&1
if errorlevel 1 (
  echo [FAIL_BUILD] %SRC%
  type "build\logs\stage11_smoke_%TAG%.log"
  set FAIL=1
  exit /b 0
)
findstr /C:"%EXPECT%" "build\logs\stage11_smoke_%TAG%.log" >nul
if errorlevel 1 (
  echo [FAIL_OUTPUT] %SRC% expected compact output: %EXPECT%
  type "build\logs\stage11_smoke_%TAG%.log"
  set FAIL=1
) else (
  echo [OK] %SRC% expected=%EXPECT%
)
exit /b 0
