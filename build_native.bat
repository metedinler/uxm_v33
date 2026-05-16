@echo off
setlocal
REM Prefer user-provided FBC64 env var, then common install locations.
if defined FBC64 goto :have_fbc64
if exist "tools\FreeBASIC-1.10.1-win64\fbc.exe" (
    set "FBC64=tools\FreeBASIC-1.10.1-win64\fbc.exe"
    goto :have_fbc64
)
if exist "C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe" (
    set "FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe"
    goto :have_fbc64
)
if exist "C:\Program Files\FreeBASIC\fbc.exe" (
    set "FBC64=C:\Program Files\FreeBASIC\fbc.exe"
    goto :have_fbc64
)
echo ERROR: 64-bit FreeBASIC (fbc.exe) not found. Please set the FBC64 environment variable or install FreeBASIC x64 to tools\FreeBASIC-1.10.1-win64\ or C:\Program Files\FreeBASIC.
exit /b 1
:have_fbc64
set "FBC=%FBC64%"
if not exist build\exe mkdir build\exe
"%FBC%" -lang fb uxm\core\compiler\native\uxm31_compiler_fb.bas -x build\exe\uxm_native.exe
if errorlevel 1 exit /b 1
echo OK: build\exe\uxm_native.exe
endlocal
