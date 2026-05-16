# UXM V33 Memory Model V8 Hotfix

Bu paket V7 memory model fikrini korur ama V7 uygulama hatalarını düzeltir.

## Düzeltilenler

1. `uxm31_runtime_fb_full.bas` dosyasının başına yanlışlıkla gelen `Extern "C"` kaldırıldı. `#Lang "fb"` yeniden ilk satırdır. Bu, `run_15_memory_model_smoke` build=1 hatasının ana sebebiydi.
2. Runtime cache link denemesi geri alındı. `build_one_native.bat` artık güvenli eski kaynak link hattını kullanır ama test başına benzersiz asm/obj/exe adı destekler.
3. `UXM_FAST_KEY_SCAN_V8.py` büyük CSV alanları için `csv.field_size_limit` ayarlar. `_csv.Error: field larger than field limit` çözülür.
4. V8 bat dosyaları scan başarısız olursa runner çalıştırmaz; stale manifest ile 37 sahte buildfail üretmez.

## Çalıştırma

```powershell
.\run_15_memory_model_smoke_v8.bat
.\run_09_fast_key_scan_v8.bat
.\run_10_rerun_failed_unique_v8.bat --no-build
```

Aynı anda eski V6/V7 runner çalıştırma. Paralel test için yalnız V8 hattını kullan.
