# UXM All Test Files Archive

Bu arşiv, bu sohbette üretilen UXM stage paketlerinden test dosyalarını isim karışıklığı olmadan ayırmak için hazırlandı.

## Klasörler

- `01_all_tests_by_package/`: Her üretilen paketin içindeki test dosyaları, paket adına göre ayrı klasörde. Aynı isimli dosyalar burada ezilmez.
- `02_latest_unique_by_relative_path/`: Aynı `uxm/tests/...` yolu için en son paketteki sürüm. Projeye geri koymak için en pratik klasör.
- `03_curated_stage_added_tests/`: Stage bazında bilerek eklenen/yazılan testlerin derlenmiş listesi.
- `04_current_uploaded_snapshot_tests/`: Kullanıcının yüklediği `UXMv33(3).zip` içindeki mevcut test snapshot'ı.
- `manifest/`: CSV/JSON raporları.

## Sayılar

```json
{
  "created_at": "2026-05-10T00:55:57.154844",
  "generated_packages_scanned": 19,
  "all_package_test_file_copies": 2205,
  "latest_unique_by_relative_path_count": 1145,
  "curated_stage_added_count": 1071,
  "current_uploaded_snapshot_count": 0,
  "duplicate_basename_count": 102,
  "duplicate_relative_path_count": 102,
  "missing_curated_count": 0
}
```

## Önerilen kullanım

İsim karışıklığını çözmek için önce `manifest/DUPLICATE_BASENAME_REPORT.csv` ve `manifest/LATEST_UNIQUE_BY_RELATIVE_PATH.csv` dosyalarına bak.

Projeye geri test koymak istersen en güvenli kaynak:

```text
02_latest_unique_by_relative_path/
```

Sadece benim stage aşamalarında yazdığım testleri görmek istersen:

```text
03_curated_stage_added_tests/
```
