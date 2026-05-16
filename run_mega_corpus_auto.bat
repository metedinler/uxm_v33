@echo off
setlocal
if exist tools\UXM_STAGE17_EXPECT_RUNNER.py (
  py -3 tools\UXM_STAGE17_EXPECT_RUNNER.py --test-dir uxm/tests/mega_corpus --out-dir mega_corpus_results
) else (
  echo Stage17 expect runner bulunamadi. Kendi runner'inizle uxm/tests/mega_corpus klasorunu kosun.
  exit /b 1
)
