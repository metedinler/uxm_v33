# 1.zip Ön İnceleme Notu

`1.zip` içinde aktif proje kökü olarak `UXMv33/` bulundu. Aynı zip içinde ayrıca geçmiş stage paketleri, stage runner paketleri, eski plan dokümanları, Emekliler klasörü, build çıktıları, eski loglar, optimizer denemeleri ve raporlar aynı genel arşiv altında duruyor.

Görülen ana kümeler:

- `UXMv33/`: aktif çalışma kökü.
- `UXMv33/uxm/`: aktif kaynak/test omurgası.
- `UXMv33/build`, `UXMv33/build stage 15`: aktif/son build çıktıları.
- `UXMv33/Emekliler/`: önceki build ve sonuçların bir kısmı zaten emekliye alınmış.
- `UXMv33/yeni_optimize_asm/`: optimize ASM hattı çıktıları.
- `UXMv33/PATCHED_EXISTING_FILES`, `PATCH_INSTRUCTIONS`, `sample_stage12_*`: önceki analiz/yama ara ürünleri.
- `uxm dosyalari/UXM_V33_STAGE*`: geçmiş stage paket kopyaları.

Bu paket bu karmaşayı silmeden ayırmak için `UXM_WORKSPACE_TOPARLAYICI_Y.py` ve emekli buildlerden ders çıkaran `UXM_EMEKLI_BUILD_ANALYZER_Y.py` dosyalarını verir.

Ayrıntılı ham envanter `sample_reports/zip_or_workspace_inventory_y.csv` içindedir.
