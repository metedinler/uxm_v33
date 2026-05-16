# PCK.md - UXM V33 Programcinin Ceb Kitabi

Bu belge UXM compiler + runtime + test + VSCode entegrasyonunu tek yerde toplar.
Hedef: hizli referans + kullanici kilavuzu + nasil program yazilir rehberi.

## 1) Hizli Baslangic

### 1.1 Derleyiciyi derle

```bat
build_native.bat
```

Cikti:

- `build/exe/uxm_native.exe`

### 1.2 Tek UXM dosyasi derle + calistir

```bat
build_one_native.bat uxm\tests\fp\test_fp01_add_int.uxm
```

Ciktilar:

- `build/asm/test_fp01_add_int.asm`
- `build/obj/test_fp01_add_int.o`
- `build/exe/test_fp01_add_int.exe`

### 1.3 Tum yerel testleri kos

```bat
rtxz.bat
```

Log/cikti:

- `sonucNN.txt`
- `build/logs/*.build_out.txt`

### 1.4 Expected testleri build etmeden kos

```bat
run_all_expected_tests_no_build.bat --limit 100
```

Rapor:

- `all_expected_results/<run_id>/ALL_EXPECTED_SUMMARY.md`
- `all_expected_results/<run_id>/all_expected_results.csv`

## 2) Mimari Ozeti

Detayli grafik: `docs/uxm_compiler_mimarisi.md`

Akis:

1. `.uxm` kaynak parser tarafinda token/komut tablosuna doner.
2. Komut tablosu NASM asm'e doner (`build/asm`).
3. NASM ile obje (`build/obj`).
4. FreeBASIC runtime ile linklenir (`build/exe/*.exe`).
5. Runtime icinde `@meta` servis dispatch calisir.

## 3) Dil Komutlari (Instruction Set)

Kaynak: `uxm/core/compiler/native/native_lexer_parser.bas`

Temel komutlar:

- `>` pointer saga
- `<` pointer sola
- `+` hucre arttir
- `-` hucre azalt
- `0` hucre sifirla
- `.` putc/print char
- `,` getc/read char
- `[` loop basla (aktif hucreye gore)
- `]` loop bitir
- `$` push
- `%` pop
- `?` eq
- `!` gt
- `;` lt
- `&` and
- `|` or
- `^` xor
- `~` not
- `{` shl
- `}` shr
- `e` status

Ek komutlar:

- `pN` tanimli string yazdir
- `sN=start,{text}` string tanimla
- `mN={...}` macro tanimla (N: 128..255)
- `@ID` meta servis cagir
- `@#` dinamik meta
- `@(addr)` adresten dinamik meta
- `:...` branch komut ailesi

## Bilgilendirme Kutucuğu (Hızlı Referans)

- Hızlı komut özet: `> < + - 0 . , [ ] $ % ? ! ; & | ^ ~ { } e`
- String/macro: `pN` (çağır), `sN=start,{text}` (tanımla), `mN={...}` (macro, N:128..255)
- Meta çağrılar: `@ID`, `@#` (dinamik), `@(addr)` (adres tabanlı dinamik)
- Pragma örnekleri: `#mode`, `#cell`, `#bounds`, `#overflow`, `#endian`, `#memory`, `#arge`
- Adresleme kısa: `(T) (T+N) (T:N) (D:N) (SP) (SP+N) (P) (*T) (D@T)`
- VSCode: Eklenti hover desteği ile bu sembollere gelince kısa açıklama gösterilir.

## 4) Adresleme Modlari

Kaynak: `uxm/core/compiler/native/native_addressing.bas`

- `(T)` aktif tape hucre
- `(T+N)` / `(T-N)` tape goreli
- `(T:N)` tape mutlak
- `(D:N)` data mutlak
- `(S:N)` stack alani mutlak
- `(SP)` stack pointer
- `(SP+N)` / `(SP-N)` stack pointer goreli
- `(P)` pointer register
- `(E)` endian register
- `(F)` flags register
- `(*T)` tape dolayli
- `(*(T+N))` / `(*(T-N))` tape dolayli goreli
- `(D@T)` data[tape]
- `(D@T+N)` data[tape+N]
- `(D@(T+base)+off)` advanced data indirection
- `(D:N+P)` data base+P
- `(T:N+P)` tape base+P
- `(D@D:N)` double indirect data
- `(T@D:N)` tape adresi data'dan oku

Not:

- Bosluk yasak: `(T + 1)` gecersiz, `(T+1)` dogru.

## 5) Pragma Komutlari

Kaynak: `uxm/core/compiler/native/native_cli.bas`

- `#mode safe|normal|wild`
- `#cell byte|word|dword`
- `#bounds on|off`
- `#overflow check|wrap`
- `#compare signed|unsigned`
- `#endian big|little`
- `#memory tape=.. stack=.. data=.. queue=.. policy=.. total=..`
- `#seed <n>`
- `#arge json interpreter step trace watch`
- `#poly ...` / `#expr-rpn ...`
- `#matrix ...` / `#identity ...` / `#zeros ...` / `#ones ...`

## 6) Servisler (Meta @ID)

Kaynaklar:

- `uxm/core/runtime/runtime_meta_dispatch.bas`
- `config/uxm/service_registry_merged.csv`

Ana ID araliklari:

- `0..19` core
- `20..39` arithmetic
- `40..59` math
- `60..79` io
- `80..89` pointer/memory
- `90..127` fifo/data/sort/wild
- `150..159` flags/endian
- `160..199` matrix
- `200..239` floating point
- `240..254` math extra (poly/rpn/numerik)
- `260..299` statistics (kismi extension bagimliligi notlari var)
- `300..379` string/string ext/hypothesis vs (registry tarafinda)
- `360..389` probability
- `390..439` numeric methods/file
- `440..459` complex
- `480..511` bio
- `512..599` tensor/matrix advanced
- `600..679` sparse vector
- `700..759` ml data pipeline

Ornek:

- `@20` ADD
- `@23` DIV
- `@40` SIN
- `@46` SQRT
- `@160` MAT_INIT
- `@210` FP_ADD

## 7) Compiler / Interpreter / Runner CLI

### 7.1 Compiler binary

Kaynak: `uxm/core/compiler/native/native_main.bas`

Kullanim:

```txt
uxm_native.exe <in.uxm> [out.asm]
```

### 7.2 Batch derleme komutlari

- `build_native.bat` -> compiler derler
- `build_one_native.bat <test.uxm> [-x86|-x64] [-link]`
- `run_tests_native.bat` -> klasor bazli native test kosusu
- `rtxz.bat` -> coklu klasor test ve sonuc logu

### 7.3 Expected runner

Kaynak: `tools/UXM_ALL_EXPECT_RUNNER.py`

```txt
--root
--manifest
--no-build
--stop-on-fail
--timeout-build
--timeout-test
--limit
--from-index
--name-contains
```

Ornek:

```bat
py -3 tools\UXM_ALL_EXPECT_RUNNER.py --root . --manifest uxm\tests\all_expected_known\ALL_EXPECTED_RUN_LIST.csv --no-build --limit 50
```

## 8) VSCode Sistemi

### 8.1 HTTP kontrol sunucusu

Kaynak: `tools/vscode_integration/uxm_control_server.py`

Calistir:

```bat
python tools\vscode_integration\uxm_control_server.py
```

Endpointler:

- `GET /ping`
- `GET /addresses`
- `POST /alias` JSON: `{name,address,desc}`
- `POST /compile` -> `build_native.bat`
- `POST /run` -> `run_all_expected_tests_no_build.bat`
- `GET /trace?file=...` -> son 200 satir

### 8.2 Comm watcher (dosya tabanli komut)

Kaynak: `tools/vscode_integration/comm_watcher.py`

Komut dosyalari:

- Giris: `tools/vscode_integration/comm/command_<id>.json`
- Cikis: `tools/vscode_integration/comm/result_<id>.json`

Komut tipleri:

- `compile`
- `run_tests` / `run`
- `add_alias`
- `trace`
- `shell`

## 9) Katman Bazli Ciktilar (Ne Nereden Cikar?)

- Compiler stdout:
  - `ASM uretildi: ...`
  - `[V3.3-stage...] Native ASM hazir...`
- Build artefaktlari:
  - `build/asm/*.asm`
  - `build/obj/*.o`
  - `build/exe/*.exe`
- Test artefaktlari:
  - `build/logs/*.build_out.txt`
  - `sonuc*.txt`
- Expected test raporlari:
  - `all_expected_results/<run_id>/ALL_EXPECTED_SUMMARY.md`
  - `all_expected_results/<run_id>/all_expected_results.csv`
  - `all_expected_results/<run_id>/mismatches/*`

## 10) Programlama Nasil Yapilir? (Kisa Yol)

### Adim 1: Kucuk bir `.uxm` dosyasi yaz

Ornek (mantik): iki deger topla, yazdir.

```txt
#mode normal
#cell dword
@20
@61
```

Not: Gercek argumani tape/data/stack duzeni ile yuklemelisin; test dosyalarini referans al.

### Adim 2: Derle

```bat
build_one_native.bat my_test.uxm
```

### Adim 3: Ciktiyi dogrula

- Console output
- `build/asm/my_test.asm`
- `build/exe/my_test.exe`

### Adim 4: Expected test yaz

- `my_test.expect` olustur
- mode: `exact|compact|contains`
- Runner ile toplu dogrula

## 11) Saha Notlari (Pratik)

- Adresleme ifadelerinde bosluk birakma.
- `build/logs` klasorunu koru; test hata analizi hizlanir.
- `rtxz.bat` sonucu tek dosyada oldugu icin her testin `BUILD_RC` satirini kontrol et.
- Servis ID kullanirken `service_registry_merged.csv` ile runtime dispatch araligini birlikte kontrol et.

## 12) Tek Komutta Gunluk Is Akisi

```bat
build_native.bat && rtxz.bat
```

Expected test odakli akis:

```bat
build_native.bat && run_all_expected_tests_no_build.bat --limit 200
```
