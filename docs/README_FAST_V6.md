# UXM V33 Fast Key Scan / Fail-Only Runner V6

Bu paket, 1054 testi baştan sona koşturmak yerine mevcut sonuç CSV'lerinden hatalı anahtarları çıkarır ve sadece gerekli testleri tekrar çalıştırır.

## Amaç

- Tam taramayı CSV üzerinden yap.
- `BASARILI` olanları tekrar çalıştırma.
- Aynı testin farklı stage paketlerinden gelen kopyalarını `semantic_key` ile tekilleştir.
- Önce benzersiz hatalı anahtarları çalıştır; sonra gerekirse aynı anahtarın tüm kopyalarını kontrol et.

## Ana komutlar

```powershell
.\run_09_fast_key_scan.bat
```

Sadece rapor ve manifest üretir. Test çalıştırmaz.

```powershell
.\run_10_rerun_failed_unique.bat
```

Sadece benzersiz hatalı anahtarları tekrar çalıştırır. En hızlı doğrulama budur.

```powershell
.\run_11_rerun_failed_all.bat
```

Unique anahtarlar temizlendikten sonra, hatalı görünen tüm kopyaları tekrar çalıştırır.

```powershell
.\run_12_rerun_buildfail_only.bat
```

Sadece build/runtime fail sınıfını çalıştırır.

```powershell
.\run_13_rerun_mismatch_only.bat
```

Sadece UYUSMAZ/EXIT_MISMATCH sınıfını çalıştırır.

```powershell
.\run_14_rerun_memory_policy_only.bat
```

Sadece data bellek sınırı gibi memory-policy kaynaklı testleri çalıştırır.

## Hızlı kullanım sırası

```powershell
.\run_09_fast_key_scan.bat
.\run_10_rerun_failed_unique.bat --no-build
```

`--no-build` kullanırsan compiler tekrar build edilmez. Compiler/runtime değiştiyse `--no-build` kullanma.

## Çıktılar

```text
fast_results/latest/FAST_KEY_REPORT.md
fast_results/latest/FAST_KEY_SUMMARY.json
fast_results/latest/failed_key_summary.csv
fast_results/latest/failed_unique_manifest.csv
fast_results/latest/failed_all_manifest.csv
fast_results/latest/class_summary.csv
fast_results/runs/<run_id>/expected_results_v2.csv
fast_results/runs/<run_id>/mismatches_v2.csv
```

## Mantık

`failed_unique_manifest.csv`: her hatalı semantic key için tek temsilci test. 1054 test yerine çok daha az test koşar.

`failed_all_manifest.csv`: hatalı görünen tüm kopyalar. Final onayda kullanılır.

## Not

Bu paket compiler/runtime değiştirmez. Sadece tarama/manifest/runner hattıdır.
