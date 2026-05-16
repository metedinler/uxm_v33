# UXM Compiler Mimarisi (V33)

Bu dokuman UXM derleme/yurutme hattini grafik olarak gosterir ve katman ciktilarini ozetler.

## Grafik

```mermaid
flowchart TD
    A[UXM Kaynak: .uxm] --> B[Compiler Frontend\nuxm31_compiler_fb.bas\nlexer/parser + pragmas + macro]
    B --> C[IR/Instruction Table\nIOp/IAmt/IAddrKind + branch/meta kayitlari]
    C --> D[ASM Emitter\nnative_asm_emit.bas]
    D --> E[NASM Assembly\nbuild/asm/*.asm]
    E --> F[NASM\nbuild/obj/*.o]
    F --> G[FreeBASIC Link\nuxm31_runtime_fb_full.bas]
    G --> H[Native EXE\nbuild/exe/*.exe]

    H --> I[Runtime Core\nruntime_meta_dispatch + runtime_memory + io]
    I --> J[Meta Service Families\ncore/arithmetic/math/io/...]
    J --> K[Test Runner / CLI / VSCode]

    K --> L[Sonuc dosyalari\nsonuc*.txt, build/logs/*.txt]
    K --> M[Expected test raporlari\nall_expected_results/*]
    K --> N[HTTP + Comm API\ntools/vscode_integration]
```

## Katman Ciktilari

- Kaynak girisi: `uxm/tests/**/*.uxm`
- Frontend parse sonucu: instruction tablolari (bellekte)
- Kod uretimi: `build/asm/<program>.asm`
- Obje dosyasi: `build/obj/<program>.o`
- Linklenmis binary: `build/exe/<program>.exe`
- Derleyici binary: `build/exe/uxm_native.exe`
- Test/ci loglari: `build/logs/*.txt`, `sonuc*.txt`
- Beklenen-test raporlari: `all_expected_results/<run_id>/`

## Kritik Dosyalar

- Compiler giris noktasi: `uxm/core/compiler/native/uxm31_compiler_fb.bas`
- CLI + pragma + memory model: `uxm/core/compiler/native/native_cli.bas`
- Lexer/parser: `uxm/core/compiler/native/native_lexer_parser.bas`
- Adresleme cozumleyici: `uxm/core/compiler/native/native_addressing.bas`
- ASM emit: `uxm/core/compiler/native/native_asm_emit.bas`
- Runtime dispatch: `uxm/core/runtime/runtime_meta_dispatch.bas`
- Servis registry: `config/uxm/service_registry_merged.csv`
