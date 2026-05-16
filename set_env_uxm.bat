@echo off
set "UXM_ROOT=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo"
set "FBC64=%UXM_ROOT%\tools\FreeBASIC-1.10.1-win64\fbc.exe"
set "FBC=%FBC64%"
set "NASM=nasm"

echo UXM_ROOT=%UXM_ROOT%
echo FBC64=%FBC64%
echo NASM=%NASM%

if not exist "%FBC64%" (
  echo ERROR: fbc.exe bulunamadi:
  echo %FBC64%
  exit /b 1
)

"%FBC64%" -version
nasm -v

echo Ortam hazir.
