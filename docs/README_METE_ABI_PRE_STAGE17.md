# UXM V33 Pre-Stage17 Toparlama ve Y Hatti Paketi

Bu paket Stage-17 degildir. Stage-17 bekletildi.

Amaç:

1. Mevcut çalışan `build_native.bat`, `build_one_native.bat`, `run_tests_native.bat` düzenini bozmamak.
2. Yeni test/rapor hattını ayrı dosyalara yazmak.
3. Yeni CSV dosyaları kullanmak.
4. Çalışma dizinini silmeden toparlamak.
5. İş biten `build` / `build stage N` klasörlerini otomatik Emekliler altına almak.
6. Emeklilerdeki build sonuçlarından hata/öğrenme raporu çıkarmak.
7. Sonraki kaynak kod gerçekliği incelemesi için zip/workspace envanteri toplamak.

## Ana dosyalar

```text
tools_y/UXM_STAGE_RUNNER_Y.py
tools_y/run_stage_y.bat
tools_y/run_full_y.bat
```

Ayrı Y sonucu üretir:

```text
y_sonuclar/stage_runs/...
y_sonuclar/csv/test_history_y.csv
y_sonuclar/csv/test_stats_summary_y.csv
```

## Toparlama

Önce dry-run:

```powershell
.\tools_y\run_toparlayici_y_dryrun.bat 16
```

Gerçek taşıma:

```powershell
.\tools_y\run_toparlayici_y_apply.bat 16
```

Taşıma silmez. `Emekliler/` altına alır ve manifest üretir.

## Emekli buildlerden ders çıkarma

```powershell
.\tools_y\run_emekli_build_analyzer_y.bat
```

Çıktılar:

```text
y_sonuclar/emekli_dersleri/<tarih>/emekli_build_inventory_y.csv
y_sonuclar/emekli_dersleri/<tarih>/emekli_error_patterns_y.csv
y_sonuclar/emekli_dersleri/<tarih>/emekli_version_tags_y.csv
y_sonuclar/emekli_dersleri/<tarih>/EMEKLI_BUILD_DERS_RAPORU_Y.md
```

## Zip/workspace audit

```powershell
py -3 tools_y\UXM_ZIP_AUDITOR_Y.py --zip 1.zip
```

veya aktif klasör için:

```powershell
py -3 tools_y\UXM_ZIP_AUDITOR_Y.py --root .
```

## Opsiyonel cache denemesi

Bunlar ana build bat dosyalarının yerine geçmez. Ayrı deney hattıdır.

```text
tools_y/build_native_cache_y.bat
tools_y/build_one_native_cache_y.bat
```

## Uyarı

`build_one_native.bat` her testte runtime `.bas` dosyasını tekrar FreeBASIC ile linkliyorsa testler yavaş kalır. Bu paket önce çalışma düzenini ayırır; asıl mimari hızlandırma bir sonraki kaynak kod gerçekliği incelemesinde runtime obj/cache/link stratejisi netleştirilerek yapılmalıdır.
