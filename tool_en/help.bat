@echo off
setlocal
echo UXM V14 English commands:
echo   stage_tasks.bat                      Stage 10/17/18/20 task summary
echo   memory_test.bat                      Memory model tests
echo   stage17_fix.bat                      Clean expected-output metadata
echo   stage17_check.bat -k                 Stage17/framework check
echo   stage18_finish.bat -k                Finish/check Stage18
echo   stage19_finish.bat -k                Stage19 quality tests
echo   stage20_finish.bat -k                Stage20 release quality gate
echo   fast_scan.bat                        Scan latest results
echo   failed_test.bat -k -D                Run unique failing tests
echo   report_show.bat                      Show latest report
echo.
echo Short options:
echo   -k no-build, -D stop-on-fail, -n limit, -s from-index, -a contains, -z timeout, -u apply
