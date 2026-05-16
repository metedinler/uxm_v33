@echo off
setlocal
py -3 araclar\uxm_beklenen_duzelt.py -d uxm\tests\all_expected_known -u %*
if errorlevel 1 python araclar\uxm_beklenen_duzelt.py -d uxm\tests\all_expected_known -u %*
