@echo off
setlocal
set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (set FBC=%FBC64%) else (set FBC=fbc)
if not exist build\exe mkdir build\exe
%FBC% -lang fb uxm\core\compiler\native\uxm31_compiler_fb.bas -x build\exe\uxm_native.exe
if errorlevel 1 exit /b 1
echo OK: build\exe\uxm_native.exe
endlocal
