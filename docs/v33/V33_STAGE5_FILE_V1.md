# UX-MINIMA V3.3 Stage-5 — FILE V1 Runtime Servisleri

Bu fazda `@400..@415` aralığına ilk dosya I/O servisleri eklendi. Amaç çekirdek dile `OPEN`, `READ`, `WRITE` gibi yeni keyword eklemek değil; dosya işlemlerini meta servis ailesi olarak runtime tarafına bağlamaktır.

## Servis aralığı

| ID | Ad | Argüman düzeni | Sonuç |
|---:|---|---|---|
| @400 | FILE_OPEN_READ | `(T-1)=pathZ data başlangıcı` | `(T+1)=handle` |
| @401 | FILE_OPEN_WRITE | `(T-1)=pathZ data başlangıcı` | `(T+1)=handle` |
| @402 | FILE_OPEN_APPEND | `(T-1)=pathZ data başlangıcı` | `(T+1)=handle` |
| @403 | FILE_OPEN_BINARY_READ | `(T-1)=pathZ data başlangıcı` | `(T+1)=handle` |
| @404 | FILE_OPEN_BINARY_WRITE | `(T-1)=pathZ data başlangıcı` | `(T+1)=handle` |
| @405 | FILE_CLOSE | `(T-1)=handle` | `(T+1)=1/0` |
| @406 | FILE_READ_BYTE | `(T-1)=handle` | `(T+1)=byte` |
| @407 | FILE_WRITE_BYTE | `(T-2)=handle`, `(T-1)=byte` | `(T+1)=1/0` |
| @408 | FILE_READ_LINE | `(T-3)=handle`, `(T-2)=dst`, `(T-1)=max` | `(T+1)=okunan uzunluk` |
| @409 | FILE_WRITE_LINE | `(T-2)=handle`, `(T-1)=srcZ` | `(T+1)=yazılan uzunluk` |
| @413 | FILE_TELL | `(T-1)=handle` | `(T+1)=pozisyon` |
| @414 | FILE_EOF | `(T-1)=handle` | `(T+1)=1/0` |
| @415 | FILE_STATUS | yok | `(T+1)=son dosya status kodu` |

`@410..@412` blok/seek ailesi için rezerve bırakıldı.

## Eklenen dosyalar

```text
uxm/core/runtime/services/runtime_file_services.bas
```

## Değişen bağlantılar

```text
uxm/core/runtime/uxm31_runtime_fb_full.bas
uxm/core/runtime/runtime_meta_dispatch.bas
```

Runtime dispatcher artık `@400..@415` aralığını `MetaFile` fonksiyonuna yönlendirir.

## Eklenen testler

```text
uxm/tests/v33/test_v33_file_write_read_line.uxm
uxm/tests/v33/test_v33_file_binary_byte.uxm
uxm/tests/v33/test_v33_file_status_bad_handle.uxm
```

## Test komutları

```powershell
.\build_native.bat
.\build_one_native.bat uxm\tests\v33\test_v33_file_write_read_line.uxm -x
.\build_one_native.bat uxm\tests\v33\test_v33_file_binary_byte.uxm -x
.\build_one_native.bat uxm\tests\v33\test_v33_file_status_bad_handle.uxm -x
.\run_tests_native.bat
```

## Not

Bu faz minimum FILE V1 hattıdır. Sonraki fazda `FILE_READ_BLOCK`, `FILE_WRITE_BLOCK`, `FILE_SEEK`, güvenlik politikası, path sandbox/normal/wild davranışı ve log/diagnostics tarafı genişletilmelidir.
