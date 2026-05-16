# UXM Stage 12 Otomatik İşlem Sırası ve Dosya Raporu

Bu belge `UXMv33.zip` içindeki mevcut yapıya göre hazırlanmıştır. Amaç, Stage 12 ve sonraki stage'lerde elle takip edilen süreci programatik hale getirmektir.

## 1. Ana karar

Aktif derleme klasörü yine `build` kalmalı. Çünkü `build_native.bat`, `build_one_native.bat`, NASM/link hattı ve mevcut optimizer araçları doğrudan `build\asm`, `build\obj`, `build\exe` yollarını kullanıyor.

Stage sonunda aktif `build` klasörü otomatik olarak şu adla kopyalanmalı:

```text
build stage 12
```

Eğer aynı klasör varsa güvenli biçimde zaman damgalı kopya açılır:

```text
build stage 12_YYYYMMDD_HHMMSS
```

Bu yüzden eski build klasörlerini elle numaralandırmaya gerek kalmaz.

## 2. Tek hamlelik çalışma sırası

Yeni standart komut:

```bat
run_stage_auto.bat
```

Elle stage vermek istersen:

```bat
run_stage_auto.bat 12
```

Bu komut şunları yapar:

1. Stage numarasını otomatik bulur.
   - `stage_state.json` varsa oradan okur.
   - Yoksa `build stage N` klasörlerinden sonraki stage'i bulur.
   - Bunlar da yoksa en yüksek `run_stageN_smoke.bat` dosyasını kullanır. Bu zip'te `run_stage11_smoke.bat` olduğu için otomatik sıradaki stage `12` kabul edilir.
2. Yeni `sonucN.txt` log dosyasını üretir. Bu sayı stage değildir; koşu/log sayısıdır.
3. `build_native.bat` ile derleyiciyi derler.
4. Bulduğu en güncel smoke testini çalıştırır.
   - Bu zip'te: `run_stage11_smoke.bat`.
   - `--all-smoke` verilirse bütün smoke bat dosyalarını sırasıyla çalıştırır.
5. Smoke başarılıysa `uxm/tests` altındaki `.uxm` testlerinin tamamını çalıştırır.
6. Her test için ayrı log üretir.
7. Derleme/çalışma sürelerini CSV ve XLSX raporlarına döker.
8. ASM optimizer fazını çalıştırır.
   - `build/asm` okunur.
   - `yeni_optimize_asm` üretilir.
   - Optimize ASM dosyaları NASM + FreeBASIC runtime ile `*_opt.exe` olarak derlenir.
   - Orijinal exe ve optimize exe çıktıları karşılaştırılır.
9. Son aktif build klasörü `build stage N` olarak arşivlenir.
10. `stage_state.json` güncellenir.

## 3. Çıktı düzeni

Her koşuda şu klasör oluşur:

```text
stage_runs\stage_12_YYYYMMDD_HHMMSS\
```

İçinde şunlar bulunur:

```text
STAGE_RUN_SUMMARY.md
UXM_Stage_12_Rapor.xlsx          # openpyxl varsa
optimization_results.csv
test_results.csv
logs\build_native.log
logs\run_stage11_smoke.log
logs\tests\001_test_fp01_add_int.log
logs\tests\...
logs\optimizer\...
```

Kök dizinde güncellenen dosyalar:

```text
sonuc18.txt                      # örnek; mevcut sonuc17 olduğundan sıradaki 18 olur
test_history.csv
test_stats_summary.csv
stage_state.json
build stage 12
```

## 4. Mevcut dosya incelemesi

### Kullanılacak ana dosyalar

| Dosya | Durum | Görev |
|---|---|---|
| `build_native.bat` | Kullanılacak | Derleyiciyi üretir: `build\exe\uxm_native.exe`. |
| `build_one_native.bat` | Kullanılacak | Tek `.uxm` dosyasını ASM/OBJ/EXE hattından geçirir ve çalıştırır. |
| `run_stage11_smoke.bat` | Kullanılacak | Stage 11 smoke + beklenen çıktı kontrolü. Stage 12 öncesi güvenlik kapısı olarak doğru. |
| `uxm/tests/**.uxm` | Kullanılacak | Tam test havuzu. Bu zip'te 102 `.uxm` testi var; `_tmp` dosyaları varsayılan olarak atlanır, `--include-tmp` ile alınır. |
| `uxm/core/**.bas` | Kullanılacak | Derleyici/runtime gerçek kaynak katmanı. |
| `UXM_STAGE_RUNNER.py` | Yeni ana dosya | Tüm sırayı tek merkezden yönetir. |
| `run_stage_auto.bat` | Yeni ana giriş | Windows'ta tek komutla stage koşusu başlatır. |

### Düzeltilecek veya emekli edilecek dosyalar

| Dosya | Sorun | Karar |
|---|---|---|
| `runalltests.bat` | Parantez yapısı kırık; `if exist` bloğu kapanmıyor. Log adı sabit: `sonuc.s4.txt`. Stage ve istatistik yok. | Emekli et veya tamamen yeni runner'a yönlendir. |
| `run_tests_native.bat` | Yorumda hâlâ `run_stage10_smoke.bat` yazıyor. `-x` ile her testi `program.exe` üstüne yazar; kalıcı test exe seti üretmez. | Hızlı elle kontrol dışında ana hat olmasın. |
| `rtx.bat` | Yeni `sonucN.txt` açabiliyor ama smoke/optimizer/stage build arşiv yok. | Yeni runner tarafından kapsandı. |
| `rtxz.bat` | `rtx.bat` ile neredeyse aynı; tekrar. | Emekli. |
| `run_opt.bat` | `uxm_optimizer_pro.py` çağırıyor ama zip'te bu dosya yok; var olan dosya `uxm_optimizer_pro2.py`. | `run_opt_fixed.bat` ile değiştir veya yeni runner'ın optimizer fazını kullan. |
| `stat.py` | Eski `sonuc.txt` ve `START_BUILD:` / `DATA_START|` formatını bekliyor. Mevcut `sonuc17.txt` formatıyla uyumsuz. | Emekli. |
| `sts.py` | Yalnız `sonuc.txt` bekliyor; `sonucN.txt` mantığı yok. | Emekli. |
| `stsx.py` | En son `sonucN.txt` dosyasını buluyor; mevcut yapıya en yakın dosya. Ama CSV başlığı bozulmuşsa `pandas` grup işlemi kırılabilir. | Yerine runner'ın standart CSV üretimi kullanılmalı. |
| `UXMPerformansAnalizatoru.py` | Çalışıyor ama CSV sütunlarını isim yerine pozisyonla okuyor. Eski header/headersız CSV sorunundan doğmuş geçici çözüm. | Yeni CSV formatı oturunca sadeleştirilmeli. |
| `asmoptimizer.py` | `UXMPerformansAnalizatoru.py` ile büyük ölçüde aynı işlevi yapıyor. | Tekilleştir. |
| `zekiassop.py` | `MY_PATH = C:\Users\mete\Downloads\1\UXMv33` sabit. Ayrıca `build_folders[0]` sırasız olduğu için eski `build stage N` klasörünü yanlış seçebilir. | Yeni runner içinde güvenli karşılığı var. |
| `UXM_Heavy_Asm_Optimizer.py` | `MY_PATH` sabit; `UXM_Heavy_Optimizer` içinde kural listesi boş kalıyor. | Strateji raporu üretici olarak sadeleştir. |
| `build_optimized.py` | FreeBASIC yolu sabit; path quoting zayıf; optimize ölçüm/veritabanı yok. | Yeni runner optimize derlemeyi kendisi yapıyor. |
| `uxm_optimizer_pro2.py` | Faydalı fikir var: orijinal/opt exe karşılaştırma + SQLite. Ama `run_opt.bat` bunu çağırmıyor. | Yeni runner içine entegre edildi. |
| `uxm_analizor.py` / `uxm_analizor2.py` | Sabit eski `MY_PATH` var. | `uxm_analizor(birlesik).py` tercih edilmeli veya argümanlı hale getirilmeli. |

## 5. Eski rapor dosyaları

Aşağıdaki dosyalar kaynak değil, eski çıktı/rapor niteliğinde:

```text
Performans_Raporu_20260508_0746.xlsx
Performans_Raporu_20260508_0820.xlsx
UXM_Performans_Analiz_Raporu_Final.xlsx
UXM_Performans_Raporu_Final.xlsx
test_history.csv
test_stats_summary.csv
sonuc17.txt
```

Bunlar korunabilir ama yeni runner ilk çalışmada eski `test_history.csv` dosyasını yedekleyip temiz başlıklı formata geçer. Yedek adı şu biçimde olur:

```text
test_history.csv.bak_YYYYMMDD_HHMMSS
```

## 6. Önerilen klasör temizliği

Kaynak / test / rapor ayrımı şöyle olmalı:

```text
uxm\                         # gerçek kaynak ve testler
build\                       # aktif derleme alanı
build stage N\               # stage sonu dondurulmuş build kopyası
stage_runs\stage_N_time\     # o koşuya ait rapor/log seti
optimizasyon\                # ASM ve performans analiz merkezi
yeni_optimize_asm\           # optimize ASM kopyaları
legacy_tools\                # emekli edilen eski py/bat dosyaları
```

`legacy_tools` içine taşınması önerilenler:

```text
stat.py
sts.py
rtxz.bat
runalltests.bat
asmoptimizer.py
uxm_analizor.py
uxm_analizor2.py
```

`rtx.bat` ve `stsx.py` bir süre yedekte tutulabilir; ama ana çalışma artık `run_stage_auto.bat` olmalı.

## 7. Stage 12 için net komut

1. Bu paketteki dosyaları UXMv33 kök klasörüne kopyala:

```text
UXM_STAGE_RUNNER.py
run_stage_auto.bat
run_opt_fixed.bat
```

2. Komutu çalıştır:

```bat
run_stage_auto.bat 12
```

3. Bittikten sonra bana şunları gönder:

```text
stage_runs\stage_12_...\STAGE_RUN_SUMMARY.md
sonuc18.txt veya oluşan en yeni sonucN.txt
test_stats_summary.csv
stage_runs\stage_12_...\optimization_results.csv
```

Hata varsa ayrıca şu klasörü gönder:

```text
stage_runs\stage_12_...\logs\
```

## 8. Sonuç değerlendirme ölçütü

Stage geçişi için minimum şartlar:

- Smoke test: 0 hata.
- Tam test: 0 hata.
- Optimizer: `OUTPUT_DIFF` olmamalı.
- Optimize exe yavaşsa bu hata değil; yalnız performans uyarısıdır.
- `build stage 12` klasörü oluşmuş olmalı.
- `STAGE_RUN_SUMMARY.md` içinde final build adı raporlanmış olmalı.
