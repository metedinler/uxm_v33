@echo off
setlocal
py -3 tools\UXM_EXPECT_RUNNER_V6.py --manifest manifests\tensor4d_v9_manifest.csv --stage tensor4d_v9 --out-root fast_results\runs %*
endlocal
