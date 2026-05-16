@echo off
setlocal
py -3 araclar\uxm_test_kos.py -m manifests\stage20_manifest.csv -a stage10 -o sonuclar_stage10_kapi %*
if errorlevel 1 python araclar\uxm_test_kos.py -m manifests\stage20_manifest.csv -a stage10 -o sonuclar_stage10_kapi %*
