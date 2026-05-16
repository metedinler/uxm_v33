# UXM V3.3 Stage-17 Patch

Bu paket Stage-17 test framework yükseltmesidir.

## Kurulum

Paket içeriğini proje köküne kopyala.

## Çalıştırma

```powershell
.\run_stage17_tests.bat
```

İsteğe bağlı build emekliliği:

```powershell
.\run_stage17_tests_retire_build.bat
```

## Paket politikası

- Eski testler yok.
- Eski smoke setleri yok.
- Testler `uxm/tests/stage17/` içindedir.
- Bu klasörün içinde alt klasör yoktur.
- Her testin yanında `.expect` vardır.
- Runner expected/actual kontrolü yapar.
- Sonuçları ayrı CSV/JSON/MD dosyalarına yazar.
