@echo off
setlocal EnableExtensions
rem Opsiyonel hiz hatti: ana build_native.bat dosyasini degistirmez.
rem Runtime cache object uretmeyi dener. Basarisizsa mevcut build_native.bat'a duser.

set "ROOT=%cd%"
set "FBC=%UXM_FBC%"
if "%FBC%"=="" set "FBC=C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe"
set "RUNTIME=uxm\core\runtime\uxm31_runtime_fb_full.bas"
set "CACHE_OBJ=build\obj\uxm_runtime_fb_full_cache_y.o"

if not exist build\obj mkdir build\obj
if not exist build\exe mkdir build\exe

if not exist "%FBC%" (
  echo [UYARI] FBC bulunamadi: %FBC%
  echo [FALLBACK] build_native.bat calistiriliyor.
  call build_native.bat
  exit /b %errorlevel%
)

echo [Y-CACHE] Runtime cache deneniyor...
"%FBC%" -c "%RUNTIME%" -o "%CACHE_OBJ%"
if errorlevel 1 (
  echo [UYARI] Runtime cache olusturulamadi. Fallback build_native.bat.
  call build_native.bat
  exit /b %errorlevel%
)

echo [OK] Runtime cache: %CACHE_OBJ%
call build_native.bat
exit /b %errorlevel%
