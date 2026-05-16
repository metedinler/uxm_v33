@echo off
setlocal EnableExtensions
rem Opsiyonel hiz hatti: mevcut build_one_native.bat yerine gecmez.
rem UXM kaynak -> ASM/OBJ, sonra runtime cache varsa cache ile link dener; olmazsa mevcut build_one_native.bat'a duser.

set "SRC=%~1"
set "ARG2=%~2"
if "%SRC%"=="" (
  echo Kullanim: tools_y\build_one_native_cache_y.bat test.uxm -x
  exit /b 2
)

set "FBC=%UXM_FBC%"
if "%FBC%"=="" set "FBC=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe"
set "CACHE_OBJ=build\obj\uxm_runtime_fb_full_cache_y.o"

if not exist "%CACHE_OBJ%" (
  echo [Y-CACHE] Cache yok; once tools_y\build_native_cache_y.bat calistiriliyor.
  call tools_y\build_native_cache_y.bat
)

rem Guvenli davranis: mevcut build_one_native.bat'i kullan.
rem Cache link hattinin derleyici ic yapisina gore degismesi gerekirse burada ayrilacak.
call build_one_native.bat "%SRC%" %ARG2%
exit /b %errorlevel%
