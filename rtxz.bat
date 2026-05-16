@echo off
setlocal enabledelayedexpansion

:: --- [STAGE SAYACI VE DOSYA ADI AYARI] ---
set "STAGE_NO=1"
:countLoop
if exist "sonuc!STAGE_NO!.txt" (
    set /a STAGE_NO+=1
    goto countLoop
)
set "LOG_FILE=sonuc!STAGE_NO!.txt"
:: -----------------------------------------

echo ========================================
echo "TOPLAM CALISMA ZAMANI BASLANGICI: %date% %time%"
echo ========================================

:: Arka plan log başlığı
echo START_SESSION@%date%@%time% > "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo [1/2] Derleyici hazirlaniyor...
echo START_BUILD@%time% >> "%LOG_FILE%"

:: Derleyiciyi build et
call build_native.bat >> "%LOG_FILE%" 2>&1

echo END_BUILD@%time% >> "%LOG_FILE%"

echo.
echo [2/2] Testler kosturuluyor...

set "TEST_DIRS=uxm\tests\fp uxm\tests\math uxm\tests\matrix uxm\tests\native uxm\tests\v33"

for %%D in (%TEST_DIRS%) do (
    echo.
    echo Klasor Test Ediliyor: %%D
    echo ----------------------------------------
    echo ----------------------------------------
    
    echo. >> "%LOG_FILE%"
    echo KLASOR@%%D >> "%LOG_FILE%"

    if exist "%%D\*.uxm" (
        for %%F in (%%D\*.uxm) do (
            echo DATA_START@%%F@!time! >> "%LOG_FILE%"
            
            :: Derleme ve Linkleme işlemi (-x parametresi eklendi)
            REM Her test icin ayri log dosyasi olustur (hata ayiklama icin)
            set "TEST_LOG=build\logs\%%~nF.build_out.txt"
            if exist "!TEST_LOG!" del /f /q "!TEST_LOG!" >nul 2>&1
            :: Program stdout'u test log dosyasina yazilacak sekilde environment ayarla
            set "UXM_RUN_LOG=!TEST_LOG!"
            call build_one_native.bat "%%F" > "!TEST_LOG!" 2>&1
            set "UXM_RUN_LOG="

            :: Güvenilir hata kontrolü: ERRORLEVEL'i call ile yakalayarak runtime'da al
            call set "BUILD_RC=%%ERRORLEVEL%%"

            :: Kısa debug: BUILD_RC değeri ana loga yazılsın
            echo BUILD_RC=!BUILD_RC! >> "%LOG_FILE%"

            :: Testin ayrintili ciktisini ana loga ekle (ozellikle hata varsa)
            echo === TEST LOG: %%F >> "%LOG_FILE%"
            type "!TEST_LOG!" >> "%LOG_FILE%" 2>&1
            echo === END TEST LOG >> "%LOG_FILE%"

            if not "!BUILD_RC!"=="0" (
                echo Calistirildi: [BASARISIZ] %%F
                echo RESULT@[BASARISIZ]@%%F >> "%LOG_FILE%"
            ) else (
                echo Calistirildi: [BASARILI] %%F
                echo RESULT@[BASARILI]@%%F >> "%LOG_FILE%"
            )
            
            echo DATA_END@%%F@!time! >> "%LOG_FILE%"
            echo ....................................... >> "%LOG_FILE%"
            echo. >> "%LOG_FILE%"
        )
    ) else (
        echo Uyari: %%D klasoru icinde .uxm dosyasi bulunamadi.
    )
)

echo.
echo "TOPLAM CALISMA ZAMANI SONU: %date% %time%"
echo END_SESSION@%date%@%time% >> "%LOG_FILE%"
echo.
echo Rapor Olusturuldu: %LOG_FILE%
pause