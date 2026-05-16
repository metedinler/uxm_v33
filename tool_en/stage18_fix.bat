@echo off
setlocal
py -3 tool_en\uxm_expect_fix.py -d uxm\tests\all_expected_known -a STAGE18 -u %*
if errorlevel 1 python tool_en\uxm_expect_fix.py -d uxm\tests\all_expected_known -a STAGE18 -u %*
