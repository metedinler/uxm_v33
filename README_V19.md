# UXM Placeholder Gerçek Kod Planı — V19 Durum

Bu belge testlerin geçtiğini iddia etmez. Bu paket yeni kod ve test dosyası verir; gerçek derleme/çalıştırma Mete abi'nin Windows ortamında yapılacaktır.

## 8 Maddelik Plan

| No | Madde | Durum |
|---:|---|---|
| 1 | Kılavuzda “var” yazan ama kodda karşılığı belirsiz servislerin envanteri | Yapıldı |
| 2 | Stage-17 runner/.expect metaveri hatalarının temizlenmesi | Yapıldı, yeniden doğrulama kullanıcıda |
| 3 | Registry/dispatch adres çakışmalarının raporlanması | Yapıldı, sert kapı devam ediyor |
| 4 | İstatistik/hipotez/AI ilk placeholder dalgasının gerçek koda çevrilmesi | V16 ile başlatıldı |
| 5 | File/matrix/AI ikinci dalga ve reserved alan ayrımı | V17/V18 ile başlatıldı |
| 6 | Reserved/dummy/TODO kapısının sertleştirilmesi | V18 ile başlatıldı |
| 7 | Kalan ileri istatistik + olasılık/numeric helper placeholderlarının gerçek koda çevrilmesi | **V19: Şu an bu adımdayız** |
| 8 | Son release kapısı: kılavuz/servis tablosu/kod/runner uyum kontrolü | Sıradaki adım |

## V19 Kapsamı

V19 şu servisleri gerçek hesap kodu olarak ekler:

- `@274 STAT_MODE`
- `@275 STAT_RANGE`
- `@276 STAT_IQR`
- `@277 STAT_MAD`
- `@278 STAT_GEOMEAN`
- `@279 STAT_HARMEAN`
- `@280 STAT_COVARIANCE`
- `@283 NORMAL_PDF_SCALED`
- `@284 NORMAL_CDF_SCALED`
- `@285 BINOM_PMF_SCALED`
- `@286 POISSON_PMF_SCALED`
- `@287 LERP_PERMILLE`
- `@288 CLAMP_VALUE`
- `@289 MAP_RANGE_DATA`

List/Dict/Set eklenmedi; bunlar UXM projesine dahil değildir.

## Çalıştırma

```powershell
placeholder_v19_uygula.bat
stage24_placeholder_test.bat -k
placeholder_kesin_tara.bat
placeholder_kapi_sert.bat
```

