# UXM V3.3 Stage-8 — UX-STR V2 Genişletilmiş Text Servisleri

Bu aşamada `@340..@379` aralığına UX-STR V2 servis ailesi bağlandı.

## Eklenen çalışan servisler

```text
@340 STR_FIND_TEXT
@341 STR_COUNT_TEXT
@342 STR_REPLACE_CHAR
@346 STR_STARTS_WITH
@347 STR_ENDS_WITH
@348 STR_CONTAINS
@354 STR_NORMALIZE_SPACES
@355 STR_IS_NUMERIC
@356 STR_PARSE_DECIMAL
@357 STR_FORMAT_INT
@358 STR_HASH8
@359 STR_HASH32
@370 STR_HEX_ENCODE
@371 STR_HEX_DECODE
@372 STR_URL_ENCODE
@373 STR_URL_DECODE
@379 STR_TEXT_STATUS
```

`@343..@345`, `@349..@353`, `@360..@369`, `@374..@378` sonraki alt fazlara ayrıldı. Bu servisler için registry aralığı ayrıdır, fakat bu pakette runtime handler yalnızca yukarıdaki çalışan servisleri açar.

## Not

Stage-8 ayrıca `FirstPassDefinitions` davranışını düzeltti. Eski ilk geçiş, normal kod içindeki `(SP-1)` ifadesinde `S` harfini `sN` string tanımı gibi görüyordu. Artık ilk geçiş yalnızca gerçek `sN` / `mN` satırlarını toplar ve diğer kod satırlarını atlar.
