# UXM V3.3 Stage-10 Hotfix-1

## Kırılma nedeni

Stage-10 paketinde `runtime_meta_dispatch.bas`, `@512..@559` aralığını `MetaMatrixAdvancedTensor` fonksiyonuna yönlendiriyordu. Ancak `uxm31_runtime_fb_full.bas` içinde bu fonksiyon için `Declare Sub MetaMatrixAdvancedTensor(ByVal metaId As ULongInt)` bildirimi eksikti.

FreeBASIC bu yüzden runtime link aşamasında şu hatayı verdi:

```text
runtime_meta_dispatch.bas(40) error 42: Variable not declared, MetaMatrixAdvancedTensor
```

Bu hata runtime ortak dosyasında oluştuğu için sadece Stage-10 testleri değil, FP/math/matrix/native dahil bütün testler başarısız oldu.

## Düzeltme

`uxm/core/runtime/uxm31_runtime_fb_full.bas` içine şu bildirim eklendi:

```freebasic
Declare Sub MetaMatrixAdvancedTensor(ByVal metaId As ULongInt)
```

## Ek bat dosyası

Yeni dosya:

```text
run_stage10_smoke.bat
```

Bu dosya tam testten önce kısa kırılma testi yapar:

1. compiler build
2. eski FP testi
3. eski native meta testi
4. yeni matrix advanced testi
5. yeni tensor testi

Önerilen sıra:

```bat
run_stage10_smoke.bat
run_tests_native.bat
```
