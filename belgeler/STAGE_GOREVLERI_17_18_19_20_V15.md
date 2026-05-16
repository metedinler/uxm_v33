# UXM Stage 17-20 Görevleri — V15

Bu belge Mete abi'nin verdiği görev tanımını esas alır. Önceki V14'te Stage-19 ve Stage-20 yanlış yorumlanmıştı; V15 bu düzeltmedir.

| Stage | Gerçek görev | V15'te eklenen/tamamlanan parçalar |
|---|---|---|
| Stage-17 | Test Framework Upgrade: `.expect` mantığı, expected/actual karşılaştırma, status/flags/data/tape kontrolü. | `ortak/uxm_arac_cekirdek.py`, `araclar/uxm_beklenen_duzelt.py`, `uxm/tests/stage17`, `manifests/stage17_manifest.csv`, `stage17_tamamla.bat`. |
| Stage-18 | Final/ARGE + Native Bridge: final compiler'ın eski ayrı parser/runner hattını native çekirdeğe yaklaştırma. | `araclar/uxm_stage18_native_bridge.py`, `uxm/tests/stage18`, `manifests/stage18_manifest.csv`, `stage18_native.bat`, `stage18_tamamla.bat`. |
| Stage-19 | VSCode Integration Cleanup: eski internal interpreter uyarıları, final compiler build hataları, trace/diagnostic hizalama. | `araclar/uxm_stage19_vscode_temizle.py`, `vscode/uxm-dil-destegi-v15`, `uxm/tests/stage19`, `stage19_temizle.bat`, `stage19_tamamla.bat`. |
| Stage-20 | Performance + Release Cleanup: exe-only timing runner, build cache, dokümantasyon üretimi, servis tablosu otomasyonu. | `araclar/uxm_stage20_performans_release.py`, `uxm/tests/stage20`, `stage20_performans.bat`, `stage20_release.bat`, otomatik servis tablosu üretimi. |

## Çalıştırma sırası

```powershell
stage_gorevleri.bat
stage17_tamamla.bat -k
stage18_tamamla.bat -k
stage19_tamamla.bat -k
stage20_tamamla.bat -k
```

## Not

Bu paket Python dosyalarının syntax kontrolünden geçirildi. FreeBASIC/NASM derlemesi bu ortamda çalıştırılamadığı için son doğrulama Windows terminalinde yapılmalıdır.
