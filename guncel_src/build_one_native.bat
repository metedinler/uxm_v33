@echo off
setlocal EnableExtensions EnableDelayedExpansion
if "%~1"=="" (
  echo Kullanim: build_one_native.bat kaynak.uxm [-x]
  exit /b 1
)

set FBC64=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe
if exist "%FBC64%" (set FBC=%FBC64%) else (set FBC=fbc)
set NASM=nasm

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

echo NASM:
echo %NASM% -f win64 "%ASM_OUT%" -o "%OBJ_OUT%"
%NASM% -f win64 "%ASM_OUT%" -o "%OBJ_OUT%"
if errorlevel 1 exit /b 1

echo FreeBASIC runtime kaynak ile link:
echo %FBC% "%RUNTIME_SRC%" "%OBJ_OUT%" -x "%EXE_OUT%"
"%FBC%" "%RUNTIME_SRC%" "%OBJ_OUT%" -x "%EXE_OUT%"
if errorlevel 1 exit /b 1

"%EXE_OUT%"
endlocal
