# UXM V3.3 Stage-4 — UX-STR V1 Runtime Entegrasyonu

Bu fazda UX-STR V1 temel string servisleri runtime/meta dispatch hattına eklendi.

## Eklenen servis aralığı

```text
@300..@319 = UX-STR V1 temel string servisleri
```

## Servisler

```text
@300 STR_LEN_Z
@301 STR_COPY
@302 STR_CLEAR
@303 STR_FILL
@304 STR_COMPARE
@305 STR_EQUALS
@306 STR_FIND_CHAR
@307 STR_COUNT_CHAR
@308 STR_TO_UPPER
@309 STR_TO_LOWER
@310 STR_TRIM_SPACES
@311 STR_CONCAT
@312 STR_SUBSTR
@313 STR_PRINT
@314 STR_READ_CONSOLE
@315 STR_FROM_INT
@316 STR_TO_INT
@317 STR_APPEND_CHAR
@318 STR_REVERSE
@319 STR_STATUS
```

## Tasarım kararı

String keyword eklenmedi. Servisler runtime/meta üzerinden çalışır; veri data alanında tutulur.

## Ek testler

```text
uxm/tests/v33/test_v33_str_len_print.uxm
uxm/tests/v33/test_v33_str_copy_upper.uxm
uxm/tests/v33/test_v33_str_find_count.uxm
```

## Build log temizliği

Native compiler artık NASM/FBC için `<ad>` placeholder satırlarını basmaz. Link işlemi build script tarafında kalır.
