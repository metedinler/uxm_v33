@echo off
setlocal
py -3 araclar\uxm_beklenen_duzelt.py %*
if errorlevel 1 python araclar\uxm_beklenen_duzelt.py %*
