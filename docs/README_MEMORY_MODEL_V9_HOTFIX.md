# UXM V33 Memory Model V9 Hotfix

Bu paket V8 üzerine uygulanır.

## Düzeltilenler

1. `uxm/core/compiler/native/native_cli.bas` içinde byte -> KB çevirisindeki bozuk satır düzeltildi:
   `kb=CLng((bytesVal+1023)B4)` -> `kb=CLng((bytesVal+1023) \ 1024)`

2. Stage-18 `example_13_tensor4d_flat_logic` testi düzeltildi. Önceki test @563/@564/@565 çağırmadan önce 4D tensor dims/index bilgilerini DATA alanına yazmıyordu. Bu nedenle gerçek 0 geliyordu. Yeni test dimsBase ve idxBase alanlarını @96 ile yazar, sonra @563/@564/@565 çağırır.

## Çalıştırma sırası

```powershell
.\run_15_memory_model_smoke_v9.bat
.\run_16_tensor4d_single_v9.bat --no-build
.\run_09_fast_key_scan_v9.bat
.\run_10_rerun_failed_unique_v9.bat --no-build --stop-on-fail
```

Eğer tekil tensor4d testi geçerse, V8'de kalan tek gerçek uyuşmazlık temizlenmiş olur.
