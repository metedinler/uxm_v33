@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem UXM V3.3 Stage-12 smoke + expected-output checks
rem Bu smoke test Stage-10/11 temelini ve Stage-12 reshape/slice/broadcast servislerini kontrol eder.

set FAIL=0
if not exist build mkdir build
if not exist build\logs mkdir build\logs

call build_native.bat > build\logs\stage12_smoke_build.log 2>&1
if errorlevel 1 (
  echo [FAIL] build_native.bat
  type build\logs\stage12_smoke_build.log
  exit /b 1
)
echo [OK] compiler build

call :RUN_EXPECT uxm\tests\fp\test_fp01_add_int.uxm fp_base 46
call :RUN_EXPECT uxm\tests\native\test05_meta_add.uxm native_meta 30
call :RUN_EXPECT uxm\tests\v33\test_v33_tensor3d_index_slice.uxm tensor3d_index_slice 772377
call :RUN_EXPECT uxm\tests\v33\test_v33_tensor_reshape_infer_flatten.uxm tensor_reshape_infer_flatten 82777782
call :RUN_EXPECT uxm\tests\v33\test_v33_tensor_slice_axes.uxm tensor_slice_axes 77667755
call :RUN_EXPECT uxm\tests\v33\test_v33_tensor_broadcast_add.uxm tensor_broadcast_add 223127225

if not "%FAIL%"=="0" (
  echo [SMOKE FAIL] Stage-12 smoke/expected kontrolunde hata var.
  exit /b 1
)
echo [SMOKE OK] Stage-12 smoke + expected-output testleri gecti.
exit /b 0

:RUN_EXPECT
set SRC=%~1
set TAG=%~2
set EXPECT=%~3
echo ----------------------------------------
echo [TEST] %SRC%
call build_one_native.bat "%SRC%" -x > "build\logs\stage12_smoke_%TAG%.log" 2>&1
if errorlevel 1 (
  echo [FAIL_BUILD] %SRC%
  type "build\logs\stage12_smoke_%TAG%.log"
  set FAIL=1
  exit /b 0
)
findstr /C:"%EXPECT%" "build\logs\stage12_smoke_%TAG%.log" >nul
if errorlevel 1 (
  echo [FAIL_OUTPUT] %SRC% expected compact output: %EXPECT%
  type "build\logs\stage12_smoke_%TAG%.log"
  set FAIL=1
) else (
  echo [OK] %SRC% expected=%EXPECT%
)
exit /b 0
