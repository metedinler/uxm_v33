# UXM V33 Mega Test Corpus + BASIC Dönüştürücüler

Bu paket compiler/runtime değiştirmez. Amaç: mevcut UXM yüzeyini geniş test külliyatı, profesyonel örnekler ve kısmi BASIC -> UXM dönüştürücüleriyle denemektir.

## Klasörler

- `uxm/tests/mega_corpus/`: otomatik koşulabilir yeni UXM testleri.
- `uxm/tests/mega_manual/`: interaktif/manuel servis yüzeyi testleri. Full otomatik koşuya dahil etmeyin.
- `tools/uxm_qbasic_to_uxm.py`: kısmi QBasic -> UXM dönüştürücü.
- `tools/uxm_c64basic_to_uxm.py`: kısmi Commodore 64 BASIC -> UXM dönüştürücü.
- `MEGA_CORPUS_MANIFEST.csv`: her testin kategori, servis, expect modu ve notu.

## Sayılar

- Toplam UXM dosyası: 439
- Otomatik test: 437
- Manuel test: 2
- Profesyonel örnek program: 25
- Alan programı: 5

## Çalıştırma

Stage-17 expect runner varsa:

```powershell
.un_mega_corpus_auto.bat
```

Kendi runner sistemin varsa sadece şu klasörü koştur:

```text
uxm/tests/mega_corpus
```

## BASIC dönüştürücüler

```powershell
py -3 tools/uxm_qbasic_to_uxm.py samples/sample_qbasic.bas -o out_qbasic.uxm
py -3 tools/uxm_c64basic_to_uxm.py samples/sample_c64.bas -o out_c64.uxm
```

POKE/PEEK politikası:

- `POKE adres,deger` -> `0(D:adres)+kdeger`
- `PRINT PEEK(adres)` -> `@95` ile data adresinden oku ve `@61` ile yazdır.

## Not

Bazı servisler platforma, runtime durumuna veya interaktif girdiye bağlıdır. Bunlarda `.expect` modu `none` bırakıldı. Bu dosyalar yine derleme/çalışma yüzeyini kapsar, ancak beklenen çıktı sabitlemez.
