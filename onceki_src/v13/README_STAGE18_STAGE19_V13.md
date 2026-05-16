# UXM V33 Stage-18 Tamamlama + Stage-19 Bitirme Paketi V13

Bu paket V12/V11 üstüne uygulanır.

## Ana düzeltme

Stage-17 sahte uyuşmazlığının nedeni `.expect` dosyalarında beklenen çıktıya bitişik kalan `#source:embedded_EXPECT_OUTPUT` ön ekidir. V13 runner bu ön eki okuma sırasında temizler; `stage17_duzelt.bat` ve `stage18_duzelt.bat` dosyaları ise `.expect` dosyalarını kalıcı olarak temizler.

## Stage-18

Stage-18 için kalan iş: `all_expected_known` içindeki Stage-18 `.expect` metaverilerini temizlemek ve Stage-18 testlerini ayrı koşmaktır.

```powershell
stage18_tamamla.bat -k
```

## Stage-19

Stage-19, test altyapısı kalite kapısı ve Stage-18 tensor/memory köprüsünü bitiren küçük ama gerçek bir regression stage olarak eklendi. Test klasörü yalnız Stage-19'a aittir:

```text
uxm/tests/stage19/
```

Çalıştırma:

```powershell
stage19_tamamla.bat -k
```

## Not

Eski stage testleri bu pakette tekrar üretilmedi. Stage-19 için 8 ayrı test vardır; iki tanesi birleşik kullanım testidir.
