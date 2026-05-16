# UXM V3.3 Stage-15/16 Hotfix-1

## Amaç
Stage-15/16 paketinde FreeBASIC runtime link aşamasında oluşan `MatInit` argüman sayısı hatasını düzeltir.

## Hata

```text
runtime_ml_data_pipeline_services.bas(435) error 1: Argument count mismatch in 'MatInit matBase,DsRows(dsBase),DsCols(dsBase)'
```

## Düzeltme

`DsToDenseMatrix` içinde `MatInit` çağrısı mevcut matrix runtime imzasıyla uyumlu hale getirildi:

```freebasic
MatInit matBase,DsRows(dsBase),DsCols(dsBase),0,0
```

Matrix runtime imzası:

```freebasic
MatInit(baseAddr, rows, cols, typ, scale)
```

## Etki
Bu hata runtime include derlemesini düşürdüğü için eski FP/math/matrix/native testleri bile link aşamasında başarısız oluyordu. Düzeltme sonrası önce mevcut runner ile Stage-15/16 klasörü, ardından full test çalıştırılmalıdır.
