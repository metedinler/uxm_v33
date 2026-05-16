# UXM V3.3 Expected Runner V2 + Timing Diagnosis Fix

Bu paket derleyici/runtime kodunu değiştirmez. Amaç test sonuçlarını doğru sınıflandırmak ve süreleri ölçmektir.

## Neyi düzeltir?

1. Derleme/link hatasını `UYUSMAZ` değil `BUILD_FAIL` olarak ayırır.
2. `exact` ve `contains` modlarında CRLF, boş satır ve compact fallback sorunlarını düzeltir.
3. Program çıktısını `build_one_native.bat` logundan daha güvenli ayıklar.
4. `.expect` olmayan, boş veya `mode:none` testleri koşuya almaz; `skipped_v2.csv` içine yazar.
5. Mismatch için `expected.txt`, `actual.txt`, `raw.log` üretir.

## Kullanım

Stage-17 test framework testlerini tekrar dene:

```powershell
.\run_stage17_tests_v2.bat
```

Final expected suite varsa:

```powershell
.\run_all_expected_tests_v2.bat
```

Parça parça koş:

```powershell
.\run_all_expected_tests_v2.bat --limit 50
.\run_all_expected_tests_v2.bat --from-index 500
.\run_all_expected_tests_v2.bat --name-contains stage15_16
```

Build'i tekrar yapmadan:

```powershell
.\run_all_expected_tests_v2_no_build.bat --limit 20
```

## Süre analizi

Elindeki bir console logunu analiz etmek için:

```powershell
py -3 tools\UXM_TIMING_ANALYZER_V2.py Yapıştırılan_metin_61.txt --out timing_v2.csv
```

## 4 saniye/test neden olur?

`build_native.bat` sadece compiler'ı derler; bu 1 saniye civarı olabilir. Her `.uxm` testi ise ayrı süreçtir:

1. `uxm_native.exe` ile `.uxm -> .asm`
2. `nasm` ile `.asm -> .o`
3. `fbc` ile runtime + `.o -> .exe`
4. EXE çalıştırma

Pahalı kısım çoğunlukla 3. adımdır. Bu yüzden compiler build 1 saniye görünürken tek test 4 saniye sürebilir.
