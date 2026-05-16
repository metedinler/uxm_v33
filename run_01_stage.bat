@echo off
setlocal
if "%~1"=="" (
  echo Kullanim: run_01_stage.bat STAGE [ek_argumanlar]
  echo Ornek:   run_01_stage.bat 17 --scope full
  exit /b 2
)
py -3 uxm_stage_runner_y.py --stage %*
endlocal
