@echo off
setlocal EnableExtensions EnableDelayedExpansion
if "%~1"=="" (
  echo Kullanim: build_one_native.bat kaynak.uxm [-x]
  exit /b 1
)

REM Usage: build_one_native.bat kaynak.uxm [-x86|-x64] [-link]
REM Default: x64 full build (assemble + link). If -x86 is given, only ASM+OBJ are produced by default; add -link to attempt linking with available 32-bit fbc.

set NASM=nasm

REM Determine requested architecture (default x64). Can be forced via UXM_BUILD_X86=1 environment var.
set ARCH=x64
if defined UXM_BUILD_X86 set ARCH=x86
echo %* | findstr /I /C:"-x86" >nul
if %errorlevel%==0 set ARCH=x86
echo %* | findstr /I /C:"-x64" >nul
if %errorlevel%==0 set ARCH=x64

REM Determine whether to link (default: link for x64, no link for x86)
set LINK=0
if "%ARCH%"=="x64" set LINK=1
echo %* | findstr /I /C:"-link" >nul
if %errorlevel%==0 set LINK=1

REM Locate FreeBASIC compilers (prefer tools/ copies if present)
if not defined FBC64 set "FBC64="
if not defined FBC32 set "FBC32="
if not defined FBC64 if exist "tools\FreeBASIC-1.10.1-win64\fbc.exe" set "FBC64=tools\FreeBASIC-1.10.1-win64\fbc.exe"
if not defined FBC64 if exist "C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe" set "FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe"
if not defined FBC64 if exist "C:\Program Files\FreeBASIC\fbc.exe" set "FBC64=C:\Program Files\FreeBASIC\fbc.exe"
if not defined FBC32 if exist "C:\Program Files (x86)\FreeBASIC\fbc.exe" set "FBC32=C:\Program Files (x86)\FreeBASIC\fbc.exe"

REM Enforce using 64-bit FreeBASIC for x64 builds — fail fast if missing
if "%ARCH%"=="x64" (
  if defined FBC64 (
    set "FBC=!FBC64!"
  ) else (
    echo ERROR: 64-bit FreeBASIC (fbc.exe) not found. Set FBC64 env var or install to tools\FreeBASIC-1.10.1-win64\ or C:\Program Files\FreeBASIC.
    exit /b 1
  )
) else (
  REM For x86 builds prefer FBC32, fall back to FBC64 if explicitly available; otherwise fail.
  if defined FBC32 (
    set "FBC=!FBC32!"
  ) else if defined FBC64 (
    set "FBC=!FBC64!"
  ) else (
    echo ERROR: No FreeBASIC compiler found for x86 build. Set FBC32 or FBC64 env var.
    exit /b 1
  )
)

if not exist build\exe mkdir build\exe
if not exist build\asm mkdir build\asm
if not exist build\obj mkdir build\obj
if not exist build\logs mkdir build\logs

if not exist build\exe\uxm_native.exe call build_native.bat
if errorlevel 1 exit /b 1

set NAME=%~n1
if /I "%~2"=="-x" (
  if not "%UXM_BUILD_ID%"=="" (
    set NAME=%UXM_BUILD_ID%
  ) else (
    set NAME=program
  )
)

set RUNTIME_SRC=uxm\core\runtime\uxm31_runtime_fb_full.bas
set ASM_OUT=build\asm\%NAME%.asm
set OBJ_OUT=build\obj\%NAME%.o
set EXE_OUT=build\exe\%NAME%.exe

build\exe\uxm_native.exe "%~1" "%ASM_OUT%"
if errorlevel 1 exit /b 1
REM Generate assembly (uxm_native) already created ASM_OUT above
echo NASM:
if "%ARCH%"=="x64" (
  echo %NASM% -f win64 "%ASM_OUT%" -o "%OBJ_OUT%"
  %NASM% -f win64 "%ASM_OUT%" -o "%OBJ_OUT%"
  if errorlevel 1 exit /b 1
) else (
  echo %NASM% -f win32 "%ASM_OUT%" -o "%OBJ_OUT%"
  %NASM% -f win32 "%ASM_OUT%" -o "%OBJ_OUT%"
  if errorlevel 1 exit /b 1
)

if "%LINK%"=="1" (
  echo FreeBASIC runtime kaynak ile link:
  echo %FBC% "%RUNTIME_SRC%" "%OBJ_OUT%" -x "%EXE_OUT%"
  "%FBC%" "%RUNTIME_SRC%" "%OBJ_OUT%" -x "%EXE_OUT%"
  if errorlevel 1 exit /b 1
  "%EXE_OUT%"
) else (
  echo Skipping linking step (LINK=%LINK%). ASM and OBJ generated at "%ASM_OUT%" and "%OBJ_OUT%".
)
endlocal
