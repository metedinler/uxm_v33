# UXM V3.3 Stage-17 — Expected/Actual Test Framework

Stage-17 kaynak/runtime servisi eklemez. Amaç, mevcut derleme hattını değiştirmeden test doğruluğunu daha iyi ölçmektir.

## Eklenen dosyalar

- `tools/UXM_STAGE17_EXPECT_RUNNER.py`
- `run_stage17_tests.bat`
- `run_stage17_tests_retire_build.bat`
- `uxm/tests/stage17/*.uxm`
- `uxm/tests/stage17/*.expect`

## Test klasörü kuralı

Stage-17 testleri tek klasörde durur:

```text
uxm/tests/stage17/
```

Alt klasör yoktur. Eski testler yeniden üretilmemiştir.

## Expect formatı

```text
# mode: compact
# exit_code: 0
30
```

Desteklenen mode değerleri:

- `compact`: whitespace silinerek karşılaştırır.
- `exact`: satır bazlı beklenen/gerçekleşen karşılaştırır.
- `contains`: beklenen çıktı gerçek program çıktısı içinde aranır.
- `none`: sadece exit code kontrol eder.

## Çalıştırma

```bat
run_stage17_tests.bat
```

Build klasörü testten sonra Emekliler altına taşınsın istenirse:

```bat
run_stage17_tests_retire_build.bat
```

## Çıktılar

```text
stage17_results/stage_runs/<run_id>/stage17_results.csv
stage17_results/stage_runs/<run_id>/stage17_summary.json
stage17_results/stage_runs/<run_id>/STAGE17_EXPECTED_TEST_REPORT.md
stage17_results/csv/test_history_stage17_expected.csv
```

## Not

Runner, mevcut `build_native.bat` ve `build_one_native.bat` dosyalarını kullanır. Bu dosyaların yerine geçmez.
