@echo off
setlocal
py -3 tool_en\uxm_expect_fix.py %*
if errorlevel 1 python tool_en\uxm_expect_fix.py %*
