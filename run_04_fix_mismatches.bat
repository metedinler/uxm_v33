@echo off
setlocal
rem Varsayilan dry-run. Gercek uygulama icin: .\run_04_fix_mismatches.bat --apply
py -3 tools\uxm_ops\UXM_TOOL_LAUNCHER.py --tool fix_mismatch %*
endlocal
