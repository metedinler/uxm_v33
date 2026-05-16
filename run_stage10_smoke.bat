@echo off
setlocal EnableExtensions
rem UXM V3.3 Stage-10 hotfix smoke tests
rem Amac: Yeni runtime servisinin include/declaration kirilmasini hizli yakalamak.
rem Bu dosya full test yerine once 4 kritik katmani dener:
rem   1) Compiler build
rem   2) Eski FP testi: runtime genel link kiriliyor mu?
rem   3) Eski native meta testi: dispatch hala calisiyor mu?
rem   4) Yeni Stage-10 matadv/tensor testleri

set FAIL=0
if not exist build mkdir build
if not exist build\logs mkdir build\logs

call build_native.bat > build\logs\stage10_smoke_build.log 2>&1
if errorlevel 1 (
  echo [FAIL] build_native.bat
  type build\logs\stage10_smoke_build.log
  exit /b 1
)
echo [OK] compiler build

call :RUN_ONE uxm\tests\fp\test_fp01_add_int.uxm fp_base
call :RUN_ONE uxm\tests\native\test05_meta_add.uxm native_meta
call :RUN_ONE uxm\tests\v33\test_v33_matadv_det_rank_norm.uxm matadv_det_rank_norm
call :RUN_ONE uxm\tests\v33\test_v33_matadv_inverse_identity.uxm matadv_inverse_identity
call :RUN_ONE uxm\tests\v33\test_v33_tensor_basic.uxm tensor_basic

if not "%FAIL%"=="0" (
  echo [SMOKE FAIL] En az bir Stage-10 smoke testi basarisiz.
  exit /b 1
)
echo [SMOKE OK] Stage-10 hotfix smoke testleri gecti.
exit /b 0

:RUN_ONE
set SRC=%~1
set TAG=%~2
echo ----------------------------------------
echo [TEST] %SRC%
call build_one_native.bat "%SRC%" -x > "build\logs\stage10_smoke_%TAG%.log" 2>&1
if errorlevel 1 (
  echo [FAIL] %SRC%
  type "build\logs\stage10_smoke_%TAG%.log"
  set FAIL=1
) else (
  echo [OK] %SRC%
)
exit /b 0
