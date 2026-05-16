@echo off
setlocal
py -3 uxm_test_run.py -m ..\manifests\stage20_manifest.csv -o ..\results_stage20 %*
if errorlevel 1 python uxm_test_run.py -m ..\manifests\stage20_manifest.csv -o ..\results_stage20 %*
