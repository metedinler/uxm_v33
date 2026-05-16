@echo off
setlocal enabledelayedexpansion

:: Çıktı dosyası ayarı
set LOG_FILE=runallbatsonuc.txt
echo ======================================== > %LOG_FILE%
echo TEST BASLATILDI: %date% %time% >> %LOG_FILE%
echo ======================================== >> %LOG_FILE%

:: 1. ADIM: Derleyiciyi Derle (Build Compiler)
echo [1/2] Derleyici hazirlaniyor...
call build_native.bat >> %LOG_FILE% 2>&1
if errorlevel 1 (
    echo DERLEME HATASI! Compiler olusturulamadi.
    echo DERLEME HATASI! >> %LOG_FILE%
    exit /b 1
)
echo Derleyici hazir. >> %LOG_FILE%

:: 2. ADIM: Test Klasörlerini Sırayla Çalıştır
echo [2/2] Testler kosturuluyor...
set TEST_DIRS=uxm\tests\fp uxm\tests\math uxm\tests\matrix uxm\tests\native uxm\tests\v33

for %%D in (%TEST_DIRS%) do (
    echo.
    echo Klasor Test Ediliyor: %%D
    echo ---------------------------------------- >> %LOG_FILE%
    echo KLASOR: %%D >> %LOG_FILE%
    echo ---------------------------------------- >> %LOG_FILE%

    if exist "%%D\*.uxm" (
        echo .uxm dosyalari bulundu. Calistiriliyor...
        echo +++++++++++++++++++++++++++++++++++++ >> %LOG_FILE%
        for %%F in ("%%D\*.uxm") do (
            echo Calistiriliyor: %%F
            echo TEST: %%F >> %LOG_FILE%
            
            call :run_test "%%F"
            
            if !errorlevel! neq 0 (
                echo [BASARISIZ...] %%F >> %LOG_FILE%
            ) else (
                echo [BASARILI....] %%F >> %LOG_FILE%
            )
            echo ........................................ >> %LOG_FILE%
        )
    ) else (
        echo Uyari: %%D klasoru icinde .uxm dosyasi bulunamadi.
    )
)

:: DÖNGÜ DIŞI - BİTİŞ MESAJLARI
echo.
echo ========================================
echo TUM TESTLER BITTI. Sonuclar %LOG_FILE% dosyasina kaydedildi.
echo ========================================
echo TEST BITTI: %date% %time% >> %LOG_FILE%
pause

goto :eof

:run_test
call build_one_native.bat "%~1" -x >> %LOG_FILE% 2>&1
exit /b %errorlevel%