# UXM V33 Mismatch + Workspace Fix V5

Bu paket V4'teki komut satırı hatasını düzeltir.

## Ana düzeltme

V4'te `UXM_TOOL_LAUNCHER.py`, `--apply` ve `--retire-build` gibi alt araç argümanlarını kendi argümanı sanıyordu. V5 launcher `parse_known_args()` kullanır ve argümanları alt araca geçirir.

## Çalıştırma sırası

Önce yeni mismatch tanısı:

```powershell
.\run_03_mismatch_diag.bat
```

Düzeltmelerin listesini görmek için dry-run:

```powershell
.\run_04_fix_mismatches.bat
```

Gerçek uygulama:

```powershell
.\run_04_fix_mismatches.bat --apply
```

Sonra expected test:

```powershell
.\run_02_all_expected.bat
```

Çalışma alanı temizliği dry-run:

```powershell
.\run_05_workspace_clean_dryrun.bat
```

Gerçek taşıma:

```powershell
.\run_06_workspace_clean_apply.bat
```

## Net teşhis

- `data=4096` belleği compiler mantık hatası değildir; mega test dosyalarında yanlış bellek direktifidir. Bounded policy altında `data=256` kullanılmalı.
- Stage-17 exact uyuşmazlığı compiler hatası değildir; exact/compact mode sorunudur.
- ARGE math testlerinde mevcut runtime 0 dönüyor; eski expected değerleri plan değerlerinden kalmış.
- Stage-14 linalg testleri ayrıca kaynak gerçekliği incelemesinde kontrol edilmeli; final expected suite için mevcut tutarlı çıktı değerleriyle hizalanır.

## Kök klasörde kalması hedeflenen bat dosyaları

- build_native.bat
- build_one_native.bat
- run_01_stage.bat
- run_02_all_expected.bat
- run_03_mismatch_diag.bat
- run_04_fix_mismatches.bat
- run_05_workspace_clean_dryrun.bat
- run_06_workspace_clean_apply.bat
- run_07_emekli_analyze.bat
- run_08_perf_report.bat
