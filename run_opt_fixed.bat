@echo off
setlocal EnableExtensions
rem Eski run_opt.bat yerine: hard-coded path ve eksik uxm_optimizer_pro.py sorununu asar.
rem Tavsiye: Artik dogrudan run_stage_auto.bat kullan; bu dosya yalnizca optimizer fazini elle calistirmak icindir.

where py >nul 2>nul
if %errorlevel%==0 (
    py -3 -c "import os; from UXM_STAGE_RUNNER import StageRunner, build_arg_parser; a=build_arg_parser().parse_args(['--stage','auto']); r=StageRunner(a); r.init_log(); r.optimizer_phase(); r.write_optimization_reports(); print('Optimizer fazi bitti.')"
) else (
    python -c "import os; from UXM_STAGE_RUNNER import StageRunner, build_arg_parser; a=build_arg_parser().parse_args(['--stage','auto']); r=StageRunner(a); r.init_log(); r.optimizer_phase(); r.write_optimization_reports(); print('Optimizer fazi bitti.')"
)

exit /b %errorlevel%
