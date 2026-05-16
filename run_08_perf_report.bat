@echo off
setlocal
if exist tools\UXM_TIMING_ANALYZER_V2.py (
  py -3 tools\UXM_TIMING_ANALYZER_V2.py %*
) else (
  echo HATA: tools\UXM_TIMING_ANALYZER_V2.py bulunamadi.
  exit /b 2
)
endlocal
