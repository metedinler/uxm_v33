# UXM V33 Stage 12 — Mevcut Dosyaları Sıraya Koyan Paket

Mete abi, bu paket yeni `build_*.bat` veya yeni test batları üretmez. Ana fikir şudur:

1. Senin mevcut `build_native.bat` dosyanı kullanır.
2. Senin mevcut `build_one_native.bat` dosyanı kullanır.
3. Varsa mevcut `run_stageN_smoke.bat` dosyasını önce çalıştırır.
4. Smoke içindeki `RUN_EXPECT` satırlarından beklenen çıktıları otomatik okur.
5. `uxm/tests/**.uxm` testlerini dinamik bulur; 102, 104 veya ileride kaç test varsa kendisi görür.
6. Her testin süresini ölçer ve `test_history.csv` eski formatını bozmadan ekler.
7. `test_stats_summary.csv`, `build_time_history.csv`, `stage_runs/stage_N_.../test_results.csv` üretir.
8. XLSX yazarken kontrol karakteri varsa raw logu bozmaz, Excel hücresinde `\x00` gibi güvenli metne çevirir.
9. Optimizer zincirini mevcut Python dosyalarını import ederek çalıştırır; `run_opt.bat` içindeki `uxm_optimizer_pro.py`/`uxm_optimizer_pro2.py` karışıklığını raporlar.
10. İş bitince istenirse eski rapor/log/build dosyalarını `_UXM_EMEKLI` altına taşır.

## 1) Önce denetim yap

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py audit --stage 12
```

Çıktı:

```text
stage_runs\stage_12_audit_...\MEVCUT_DOSYA_AKIS_RAPORU.md
stage_runs\stage_12_audit_...\existing_file_audit.csv
```

## 2) Stage 12 koşusu

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py run --stage 12
```

Varsayılan davranış:

- En yeni smoke dosyasını önce çalıştırır. Stage 12 smoke yoksa Stage 11 smoke'u üretim kapısı gibi kullanır.
- Testleri named exe modunda çalıştırır. Böylece `build\exe\test05_meta_add.exe` gibi dosyalar kalır ve sonra optimizer kıyaslayabilir.
- `sonucN.txt` numarasını otomatik seçer.

Program.exe gibi tek dosya moduna dönmek istersen:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py run --stage 12 --test-exe-mode program
```

## 3) Optimizer zinciri

Sadece analiz ve kural raporu:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py opt --stage 12 --analyze-only
```

Mevcut optimizer zincirini tam çalıştır:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py opt --stage 12 --continue-on-error
```

Bu komut sırayla şunları kullanır:

1. `zekiassop.py` içindeki `UXM_ASM_Intelligence`
2. `UXM_Heavy_Asm_Optimizer.py` içindeki rapor sınıfları
3. `build_optimized.py`
4. `uxm_optimizer_pro2.py`

Not: `run_opt.bat` mevcut zipte `uxm_optimizer_pro.py` çağırıyor; dosya adı ise `uxm_optimizer_pro2.py`. Bu yüzden manager bu adımı doğrudan doğru dosyayla yürütür.

## 4) EXE sonunda tuş bekleme patch'i

Önce sadece plan:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py pause-patch --dry-run
```

Uygula:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py pause-patch --apply
call build_native.bat
```

Manuel sonuç görmek için:

```bat
call build_one_native.bat "uxm\tests\native\test05_meta_add.uxm" -x --pause
```

Otomatik testlerde `--pause` kullanma. Yoksa 100+ test tek tek tuş bekler.

Kaynak içine manuel pragma da eklenebilir:

```text
#pause
```

Kapatmak için:

```text
#nopause
```

## 5) Toparlayıcı

Önce plan:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py toparla --stage 12 --dry-run --move-build
```

Gerçek taşıma:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py toparla --stage 12 --apply --move-build
```

Legacy scriptleri de taşımak istersen:

```bat
python UXM_V33_EXISTING_FLOW_MANAGER.py toparla --stage 12 --apply --move-build --include-scripts
```

Bu işlem dosyaları silmez; `_UXM_EMEKLI` altına taşır ve manifest yazar.

## Mevcut zipte net görünen sorunlar

- `runalltests.bat`: parantez kapanışı hatalı görünüyor; aktif hatta alınmamalı.
- `run_opt.bat`: `uxm_optimizer_pro.py` çağırıyor ama zipte `uxm_optimizer_pro2.py` var.
- `zekiassop.py`: `__main__` içinde eski sabit yol var. Manager sınıfı import ederek mevcut klasörde çalıştırır.
- `UXM_Heavy_Asm_Optimizer.py`: ikinci motorun `rules=[]` alanı boş; bu yüzden `Kural Sayısı: 0` raporu üretiyor.
- `stat.py`: `sonuc.txt` arıyor; senin yeni `sonucN.txt` mantığınla uyumsuz.
- `asmoptimizer.py`: adına rağmen ASM optimizer değil; performans Excel raporlayıcının kopyası gibi duruyor.

## Stage sonunda bana göndermen gerekenler

```text
stage_runs\stage_12_...\STAGE_RUN_SUMMARY.md
stage_runs\stage_12_...\test_results.csv
stage_runs\stage_12_...\test_results.xlsx  (oluştuysa)
build_time_history.csv
test_stats_summary.csv
sonucN.txt
optimizasyon\asm_optimizer_rulebook_expanded.md
```
