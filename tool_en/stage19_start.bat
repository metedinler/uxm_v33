@echo off
setlocal
py -3 tool_en\uxm_test_run.py -m manifests\stage19_manifest.csv -o results_stage19 %*
if errorlevel 1 python tool_en\uxm_test_run.py -m manifests\stage19_manifest.csv -o results_stage19 %*
