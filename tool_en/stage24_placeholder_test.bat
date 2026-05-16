@echo off
if exist ..\araclar\uxm_kosucu.py (
  python ..\araclar\uxm_kosucu.py --root .. --test-dir uxm\tests\stage24_placeholder_v19 --out-root sonuclar_stage24 %*
) else if exist ..\tools\UXM_EXPECT_RUNNER_V6.py (
  python ..\tools\UXM_EXPECT_RUNNER_V6.py --root .. --test-dir uxm\tests\stage24_placeholder_v19 --out-root sonuclar_stage24 %*
) else (
  echo [ERROR] Runner not found.
  exit /b 2
)
