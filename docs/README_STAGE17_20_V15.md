# UXM V33 Stage 17-20 V15 Düzeltme Paketi

Bu paket, Stage-17/18/19/20 görevlerini Mete abi'nin son tanımına göre yeniden hizalar.

## Türkçe komutlar

```powershell
stage_gorevleri.bat
stage17_tamamla.bat -k
stage18_tamamla.bat -k
stage19_tamamla.bat -k
stage20_tamamla.bat -k
```

## İngilizce komutlar

```powershell
tool_en\stage_tasks.bat
tool_en\stage17_finish.bat -k
tool_en\stage18_finish.bat -k
tool_en\stage19_finish.bat -k
tool_en\stage20_finish.bat -k
```

## Önemli

- Stage-17: `.expect` kaynak/metaveri ön eklerini temizler ve status/flags/data/tape testleri koşar.
- Stage-18: native bridge taraması yapar ve Stage-18 testlerini koşar.
- Stage-19: VSCode eklentisini v15 olarak kurar, log/diagnostic hizalama raporu üretir.
- Stage-20: performans/release raporu, build cache manifesti ve otomatik servis tablosu üretir.
