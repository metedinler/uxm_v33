# UX-Minima V3.3 Stage-1 Uygulama Notları

Bu paket V3.1 split native compiler kodunu bozmadan V3.3 başlangıç yamalarını içerir.

## Eklenen/Değiştirilenler

1. `UXM_VERSION = 3.3-stage1`.
2. Meta servis ID parse sınırı `0..255` yerine `0..65535` yapıldı.
3. Mevcut gerçek syntax korundu:
   - `@N` sabit normal çağrı
   - `@!N` forced host çağrı
   - `@#` aktif hücreden dinamik çağrı
   - `@!#` aktif hücreden forced-host dinamik çağrı
4. Yeni V3.3 dinamik adresli meta çağrı eklendi:
   - `@(ADDR)`
   - `@!(ADDR)`
5. Yeni adresleme modları native parser/emitter tarafına eklendi:
   - `(SP+N)`, `(SP-N)`
   - `(D:BASE+P)`
   - `(T:BASE+P)`
   - `(D@D:N)`
   - `(T@D:N)`
6. Registry dosyaları `config/uxm/` altına kondu.
7. Boş hook iskeletleri eklendi:
   - `uxm/core/hooks/hook_parser_ext.bas`
   - `uxm/core/runtime/hooks/runtime_hook_dispatch_ext.bas`

## Bilinçli Sınırlar

Bu Stage-1 paketi tüm V3.3 dönüşümünü bitirmez. İlk hedef, çalışan split native hatta V3.3 sözdizimi ve adresleme genişlemesini sokmaktır.

Henüz yapılmayanlar:

- Final/ARGE hattının aynı common parser'a bağlanması.
- VSCode iç interpreter'ın devreden çıkarılıp Final JSON tüketicisine çevrilmesi.
- String/File/Bio servislerinin runtime dispatch'e tamamen bağlanması.
- Full tool legacy seçeneklerinin yeni `uxmc` CLI standardına bağlanması.

## Test Önerileri

Yeni syntax örnekleri için `uxm/tests/v33/` altındaki test dosyalarını kullanın.
