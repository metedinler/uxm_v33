@echo off
setlocal
py -3 tools\UXM_MISMATCH_SOLVER_V3.py --root . --apply --skip-actualize %*
if errorlevel 1 exit /b 1
exit /b 0
