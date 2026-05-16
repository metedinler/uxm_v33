# UXM V33 Final Expected Test Suite

Bu paket, daha once uretilmis test dosyalarini benzersiz adlarla ayirir ve yalniz beklenen degeri kesin olanlari runner'a alir.

## Sayilar

- Kaynak .uxm kopyasi: 1685
- Runner'a alinan beklenenli test: 1054
- Beklenen/belirsiz oldugu icin runner disinda tutulan test: 631

## Klasorler

- `uxm/tests/all_expected_known/`: calistirilacak benzersiz testler ve `.expect` dosyalari
- `uxm/tests/all_expected_excluded/`: beklenen degeri olmayan/belirsiz testler; runner bunlari calistirmaz
- `manifest/`: tum index ve dislama raporlari
- `tools/UXM_ALL_EXPECT_RUNNER.py`: tum beklenenli testleri calistirir

## Calistirma

```powershell
.\run_all_expected_tests.bat
```

Build'i tekrar yapmadan devam etmek icin:

```powershell
.\run_all_expected_tests_no_build.bat
```

Sadece bir bolum:

```powershell
.\run_all_expected_tests.bat --name-contains stage15_16
.\run_all_expected_tests.bat --limit 50
.\run_all_expected_tests.bat --from-index 500
```

## Onemli

Bu runner "derlendi mi" ile yetinmez. Program cikisini `.expect` dosyasi ile karsilastirir. Beklenen degeri olmayan testler manifestte ayrilmistir ve kosulmaz.
