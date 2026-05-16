@echo off
setlocal EnableExtensions EnableDelayedExpansion
if "%~1"=="" (
  echo Kullanim: build_one_native.bat kaynak.uxm [-x]
  endlocal & exit /b 1
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

if defined FBC64 goto :fbc_detect_done
if exist "tools\FreeBASIC-1.10.1-win64\fbc.exe" (
  set "FBC64=tools\FreeBASIC-1.10.1-win64\fbc.exe"
  goto :fbc_detect_done
)
if exist "C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe" (
    set "FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe"
    goto :fbc_detect_done
)
if exist "C:\Program Files\FreeBASIC\fbc.exe" (
  set "FBC64=C:\Program Files\FreeBASIC\fbc.exe"
  goto :fbc_detect_done
)
:fbc_detect_done

if defined FBC32 goto :fbc32_detect_done
if exist "C:\Program Files (x86)\FreeBASIC\fbc.exe" (
  set "FBC32=C:\Program Files (x86)\FreeBASIC\fbc.exe"
)
:fbc32_detect_done

REM Choose compiler according to requested ARCH. Use goto-based flow to avoid nested IF parentheses parsing issues.
if /I "%ARCH%"=="x64" goto :use_fbc64

REM x86 path: prefer FBC32, else fallback to FBC64
if defined FBC32 (
  set "FBC=%FBC32%"
  goto :after_fbc_select
)
if defined FBC64 (
  set "FBC=%FBC64%"
  goto :after_fbc_select
)
echo ERROR: No FreeBASIC compiler found for x86 build. Set FBC32 or FBC64 environment variable.
endlocal & exit /b 1

:use_fbc64
if defined FBC64 (
  set "FBC=%FBC64%"
  goto :after_fbc_select
)
echo ERROR: 64-bit FreeBASIC (fbc.exe) not found. Set FBC64 env var or install to tools\FreeBASIC-1.10.1-win64\ or C:\Program Files\FreeBASIC.
endlocal & exit /b 1

:after_fbc_select

if not exist build\exe mkdir build\exe
if not exist build\asm mkdir build\asm
if not exist build\obj mkdir build\obj
if not exist build\logs mkdir build\logs

set RUNTIME_SRC=uxm\core\runtime\uxm31_runtime_fb_full.bas

if not exist build\exe\uxm_native.exe (
  call build_native.bat
  if errorlevel 1 endlocal & exit /b 1
)

REM Precompile FreeBASIC runtime to object to avoid recompiling it for every test.
set "RUNTIME_OBJ=build\obj\uxm31_runtime_fb_full.o"
if not defined UXM_SKIP_RUNTIME_COMPILE (
  if not exist "%RUNTIME_OBJ%" (
    echo Compiling FreeBASIC runtime to object: "!FBC!" -lang fb -c "%RUNTIME_SRC%" -o "%RUNTIME_OBJ%"
    "!FBC!" -lang fb -c "%RUNTIME_SRC%" -o "%RUNTIME_OBJ%"
    if errorlevel 1 (
      echo WARNING: runtime precompile failed; link step will compile from source.
    )
  )
) else (
  echo Skipping runtime precompile because UXM_SKIP_RUNTIME_COMPILE is set
)

set NAME=%~n1
if /I "%~2"=="-x" (
  if not "%UXM_BUILD_ID%"=="" (
    set NAME=%UXM_BUILD_ID%
  ) else (
    set NAME=program
  )
)
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
  if errorlevel 1 endlocal & exit /b 1
) else (
  echo %NASM% -f win32 "%ASM_OUT%" -o "%OBJ_OUT%"
  %NASM% -f win32 "%ASM_OUT%" -o "%OBJ_OUT%"
  if errorlevel 1 exit /b 1
)

if "%LINK%"=="1" (
  echo FreeBASIC runtime kaynak ile link:
  echo "!FBC!" "%RUNTIME_SRC%" "%OBJ_OUT%" -x "%EXE_OUT%"
  "!FBC!" "%RUNTIME_SRC%" "%OBJ_OUT%" -x "%EXE_OUT%"
  if errorlevel 1 (
    endlocal & exit /b 1
  )
  if defined UXM_RUN_LOG (
    "%EXE_OUT%" > "%UXM_RUN_LOG%" 2>&1
  ) else (
    "%EXE_OUT%"
  )
) else (
  echo Skipping linking step ^(LINK=%LINK%^). ASM and OBJ generated at "%ASM_OUT%" and "%OBJ_OUT%".
)

set "RET=%ERRORLEVEL%"
endlocal & exit /b %RET%
