# UXM V3.3 Stage-13 Patch Package

Bu paket yalnızca Stage-13 değişen/eklenen dosyaları içerir.
Eski test klasörleri ve eski smoke bat dosyaları bu pakete dahil edilmemiştir.

## Kurulum

Paket içeriğini mevcut UXMv33 proje kökünün üzerine kopyalayın.

## Smoke test

```powershell
.\run_stage13_smoke.bat
```

Bu smoke yalnızca `uxm\tests\v33\stage13\*.uxm` dosyalarını çalıştırır ve `.expect` dosyalarıyla çıktı kontrolü yapar.

## Full test

Mevcut kendi test sisteminizle çalıştırın. Bu paket mevcut bat/test sisteminizin yerine geçmez.
