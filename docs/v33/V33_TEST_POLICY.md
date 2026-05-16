# UX-MINIMA V3.3 Test Politikası

V3.3 ile birlikte her yeni özellik kendi test dosyasıyla eklenecektir. Testler `uxm/tests/v33/` altında tutulur ve `run_tests_native.bat` tarafından `-x` generic çıktı modu ile çalıştırılır.

## Kural

Yeni eklenen her servis/adresleme/CLI davranışı için en az üç test hedeflenir:

1. **Smoke test**: servis veya syntax derlenip çalışıyor mu?
2. **Sonuç testi**: görünür çıktı veya result hücresi doğru mu?
3. **Status testi**: hata/EOF/bounds/bad handle gibi durum status/E sistemine düşüyor mu?

## Test adı şablonu

```text
test_v33_<aile>_<özellik>.uxm
```

Örnek:

```text
test_v33_file_write_read_line.uxm
test_v33_file_binary_byte.uxm
test_v33_file_status_bad_handle.uxm
```

## Run standardı

```powershell
.\build_one_native.bat uxm\tests\v33\<test>.uxm -x
.\run_tests_native.bat
```

`-x` testte generic dosya üretir:

```text
build/asm/program.asm
build/obj/program.o
build/exe/program.exe
```

Bu sayede test runner her testte aynı exe adını kullanabilir.
