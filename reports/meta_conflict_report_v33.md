# UXM v3.3 Meta Conflict Report

Tarih: 2026-05-18
Kapsam: parser canonical formlar, runtime dispatch ve service registry tutarliligi.

## Bulgu 1 - Registry duplicate ID cakismasi (kritik)
- `400` iki farkli satirda tanimli:
  - `FILE_OPEN_READ_TEXT` (file_io)
  - `NUM_SPLINE_RESERVED` (numeric)
- `401` iki farkli satirda tanimli:
  - `FILE_OPEN_WRITE_TEXT` (file_io)
  - `NUM_ADAPTIVE_INTEGRAL_RESERVED` (numeric)
- Kaynak: `config/uxm/service_registry_merged.csv` satir 275-278.

## Bulgu 2 - File/Numeric aralik cakismasi (kritik)
- Dispatcher su an:
  - `400..415 -> MetaFile`
  - `420..439 -> MetaNumericMethods`
- Registry ise ayni anda:
  - `400..421 -> file_io` (FILE_FLUSH ve FILE_OPEN_BINARY_APPEND dahil)
  - `420..439 -> numeric`
- Sonuc: `420` ve `421` icin canonical aile tek degil.
- Kaynaklar:
  - `uxm/core/runtime/runtime_meta_dispatch.bas` satir 36-38
  - `config/uxm/service_registry_merged.csv` satir 297-298 ve 352-360

## Bulgu 3 - Reserved/implemented uyumsuzlugu (yuksek)
- Registry `416..418` degerlerini `reserved` olarak etiketliyor.
- Runtime hook tarafinda `416..419` gercek dosya islemleri olarak implement:
  - `416 delete`
  - `417 rename`
  - `418 mkdir`
  - `419 exists`
- Ayrica registry `419` satirinda isim `FILE_STATUS`, runtime implementasyonu ise `exists`.
- Kaynaklar:
  - `config/uxm/service_registry_merged.csv` satir 293-296
  - `uxm/core/runtime/services/runtime_real_ext_services_v18.bas` satir 284-336
  - `uxm/core/runtime/runtime_meta_dispatch.bas` satir 54

## Bulgu 4 - Canonical syntax metadata drift (orta)
- Daha onceki metadata dosyalarinda `128..255` macro araligi ve legacy formlar (`@#N`, `@@N`, `@*`) kalintilari vardi.
- Bu tur drift lint/IDE yardiminda yanlis yonlendirmeye neden olur.
- Durum: bu tur drift bu patch setinde guncellendi.

## Onerilen kararlar
1. `400..439` bandi icin tek canonical aile tablosu secilsin (file mi numeric mi).
2. Registry duplicate satirlari temizlensin; her meta id tek satir ilkesine cekilsin.
3. `416..419` satirlari runtime davranisiyla birebir esitlenecek sekilde `reserved` etiketinden cikarilsin.
4. Secilen canonicale gore dispatcher ve servis dosyalari ayni committe birlikte dondurulsun.
