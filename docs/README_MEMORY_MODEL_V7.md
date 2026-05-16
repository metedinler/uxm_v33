# UXM V33 Memory Model V7 + Fast Runner Fix

Bu paket iki sorunu birlikte giderir:

1. `#memory data=4096` gibi testler 256 KB per-area sınırına takılıyordu. V7 ile toplam UXM bellek sınırı 16 MB oldu ve tape/stack/data/fifo alanları kullanıcı tarafından byte/kb/mb birimleriyle ayarlanabilir.
2. İki terminalde test koşunca `build\asm\program.asm`, `build\exe\program.exe` ve FreeBASIC runtime ara dosyaları çakışıyordu. V7 runner her test için `UXM_BUILD_ID` verir; `build_one_native.bat` runtime object cache kullanır ve runtime cache derleme sırasında lock alır.

## Yeni memory örnekleri

```uxm
#memory total=16mb,tape=1mb,stack=512kb,data=8mb,fifo=2mb
#memory tape=2048b,stack=1024b,data=4096kb,queue=1mb
#memory policy=total,total=16mb,tape=2mb,stack=1mb,data=12mb,fifo=1mb
```

Bare sayı legacy uyumluluk için KB sayılır: `data=4096` => 4096 KB.

## Çalıştırma

```powershell
.\run_15_memory_model_smoke.bat
.\run_09_fast_key_scan_v7.bat
.\run_10_rerun_failed_unique_v7.bat --no-build
```

Tam final doğrulama:

```powershell
.\run_02_all_expected_v7.bat
```

## Not

Aynı anda iki eski runner çalıştırılırsa yine çakışma yaşanabilir. Paralel/hızlı kontrol için V7 runner bat dosyalarını kullan.
