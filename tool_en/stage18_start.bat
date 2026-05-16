@echo off
setlocal
py -3 tool_en\uxm_test_run.py -t uxm\tests\mega_corpus -o stage18_results %*
if errorlevel 1 python tool_en\uxm_test_run.py -t uxm\tests\mega_corpus -o stage18_results %*
