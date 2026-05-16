# UXM Tool Smoke Test Report

Generated for workspace: C:\Users\mete\Downloads\1\UXMv33

| File | Size (bytes) | Tools found | Env vars | Interactive | Destructive | Suitability | Notes |
|---|---:|---|---|---|---|---|---|
| alan_topla.bat | 99 |  |  | no | no | yes - lightweight | references files: py |
| asmoptimizer.py | 4207 |  |  | no | no | yes - lightweight |  |
| beklenen_duzelt.bat | 120 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| bellek_test.bat | 140 |  |  | no | no | yes - lightweight | references files: py |
| build_native.bat | 373 | fbc,uxm31_compiler,uxm_native | %FBC%,%FBC64% | no | no | yes - needs: fbc,fbc64,uxm31_compiler,uxm_native | references files: exe; examples: fbc(fbc.exe),uxm_native(uxm_native.exe),uxm31_compiler(uxm31_compiler) |
| build_one_native.bat | 1242 | fbc,nasm,uxm_native | %ASM_OUT%,%EXE_OUT%,%FBC%,%FBC64%,%NAME%,%NASM%,%OBJ_OUT%,%RUNTIME_SRC%,%UXM_BUILD_ID% | no | no | yes - needs: fbc,fbc64,nasm,uxm_build_id,uxm_native | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| build_optimized.py | 2248 | fbc,nasm |  | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: exe; examples: fbc(fbc),nasm(nasm) |
| derleyici_derle.bat | 89 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| hatali_test.bat | 257 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| hizli_tara.bat | 121 |  |  | no | no | yes - lightweight | references files: py |
| placeholder_kapi.bat | 76 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| placeholder_kapi_sert.bat | 107 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| placeholder_kesin_tara.bat | 100 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| placeholder_tara.bat | 57 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| placeholder_test.bat | 200 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| placeholder_v19_uygula.bat | 63 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| plan_durumu.bat | 34 |  |  | no | no | yes - lightweight |  |
| rapor_goster.bat | 101 |  |  | no | no | yes - lightweight | references files: py |
| rtx.bat | 2622 | python_cmd | %LOG_FILE%,%TEST_DIRS%,%date%,%time% | yes | no | no | calls subprocess APIs; references files: bat; examples: python_cmd(Python); interactive prompt |
| rtxz.bat | 2214 |  | %LOG_FILE%,%TEST_DIRS%,%date%,%time% | yes | no | no | calls subprocess APIs; references files: bat; interactive prompt |
| runalltests.bat | 2057 |  | %LOG_FILE%,%TEST_DIRS%,%date%,%errorlevel%,%time% | yes | no | no | calls subprocess APIs; references files: bat; interactive prompt |
| run_01_stage.bat | 201 |  |  | no | no | yes - lightweight | references files: bat,py |
| run_02_all_expected.bat | 434 |  |  | no | no | yes - lightweight | references files: py |
| run_02_all_expected_v7.bat | 168 |  |  | no | no | yes - lightweight | references files: py |
| run_02_all_expected_v8.bat | 172 |  |  | no | no | yes - lightweight | references files: py |
| run_03_mismatch_diag.bat | 93 |  |  | no | no | yes - lightweight | references files: py |
| run_04_fix_mismatches.bat | 174 |  |  | no | no | yes - lightweight | references files: bat,py |
| run_05_workspace_clean_dryrun.bat | 89 |  |  | no | no | yes - lightweight | references files: py |
| run_07_emekli_analyze.bat | 86 |  |  | no | no | yes - lightweight | references files: py |
| run_08_perf_report.bat | 194 |  |  | no | no | yes - lightweight | references files: py |
| run_09_fast_key_scan.bat | 194 |  | %errorlevel% | no | no | yes - lightweight | references files: py |
| run_09_fast_key_scan_v7.bat | 67 |  |  | no | no | yes - lightweight | references files: py |
| run_09_fast_key_scan_v8.bat | 83 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| run_09_fast_key_scan_v9.bat | 104 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| run_10_rerun_failed_unique.bat | 350 |  | %errorlevel% | no | no | yes - lightweight | references files: py |
| run_10_rerun_failed_unique_v7.bat | 220 |  |  | no | no | yes - lightweight | references files: py |
| run_10_rerun_failed_unique_v8.bat | 263 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| run_10_rerun_failed_unique_v9.bat | 257 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| run_11_rerun_failed_all.bat | 373 |  | %errorlevel% | no | no | yes - lightweight | references files: py |
| run_11_rerun_failed_all_v7.bat | 214 |  |  | no | no | yes - lightweight | references files: py |
| run_11_rerun_failed_all_v8.bat | 257 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| run_14_rerun_memory_policy_only_v7.bat | 227 |  |  | no | no | yes - lightweight | references files: py |
| run_14_rerun_memory_policy_only_v8.bat | 270 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| run_15_memory_model_smoke.bat | 171 |  |  | no | no | yes - lightweight | references files: py |
| run_15_memory_model_smoke_v8.bat | 175 |  |  | no | no | yes - lightweight | references files: py |
| run_15_memory_model_smoke_v9.bat | 171 |  |  | no | no | yes - lightweight | references files: py |
| run_16_tensor4d_single_v9.bat | 162 |  |  | no | no | yes - lightweight | references files: py |
| run_all_expected_tests.bat | 175 |  |  | no | no | yes - lightweight | references files: py |
| run_all_expected_tests_no_build.bat | 186 |  |  | no | no | yes - lightweight | references files: py |
| run_all_expected_tests_v2.bat | 201 |  |  | no | no | yes - lightweight | references files: py |
| run_all_expected_tests_v2_no_build.bat | 212 |  |  | no | no | yes - lightweight | references files: py |
| run_all_expected_tests_v3.bat | 173 |  |  | no | no | yes - lightweight | references files: py |
| run_all_expected_tests_v3_no_build.bat | 184 |  |  | no | no | yes - lightweight | references files: py |
| run_emekli_build_analyzer_y.bat | 125 |  | %errorlevel% | no | no | yes - lightweight | references files: py |
| run_fix_known_test_issues_v3.bat | 130 |  |  | no | no | yes - lightweight | references files: py |
| run_full_y.bat | 398 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| run_mega_corpus_auto.bat | 294 |  |  | no | no | yes - lightweight | references files: py |
| run_mismatch_solver_v3_dryrun.bat | 105 |  |  | no | no | yes - lightweight | references files: py |
| run_opt.bat | 642 | python_cmd |  | yes | no | no | references files: py; examples: python_cmd(python); interactive prompt |
| run_opt_fixed.bat | 828 | python_cmd | %errorlevel% | no | no | yes - lightweight | references files: bat,py; examples: python_cmd(python) |
| run_stage10_smoke.bat | 1523 |  | %FAIL%,%SRC%,%TAG% | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| run_stage11_smoke.bat | 1655 |  | %EXPECT%,%FAIL%,%SRC%,%TAG% | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| run_stage12_smoke.bat | 1763 |  | %EXPECT%,%FAIL%,%SRC%,%TAG% | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| run_stage13_smoke.bat | 1765 |  | $e,$ec,$env,$l,$lc,%COUNT%,%EXPECT%,%FAIL%,%LOG%,%LOGDIR%,%NAME%,%SRC%,%TESTDIR% | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| run_stage14_smoke.bat | 1765 |  | $e,$ec,$env,$l,$lc,%COUNT%,%EXPECT%,%FAIL%,%LOG%,%LOGDIR%,%NAME%,%SRC%,%TESTDIR% | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| run_stage17_tests.bat | 151 |  |  | no | no | yes - lightweight | references files: py |
| run_stage17_tests_retire_build.bat | 157 |  | %ERRORLEVEL% | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| run_stage17_tests_v2.bat | 162 |  |  | no | no | yes - lightweight | references files: py |
| run_stage17_tests_v3.bat | 151 |  |  | no | no | yes - lightweight | references files: py |
| run_stage_auto.bat | 392 | python_cmd | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: bat,py; examples: python_cmd(python) |
| run_stage_y.bat | 413 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| run_tests_native.bat | 372 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| run_toparlayici_y_apply.bat | 213 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| run_toparlayici_y_dryrun.bat | 182 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| stage10_kontrol.bat | 242 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage17_duzelt.bat | 190 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage17_kontrol.bat | 249 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage17_tamamla.bat | 110 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| stage18_basla.bat | 249 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage18_duzelt.bat | 212 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage18_kontrol.bat | 249 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage18_native.bat | 167 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage18_tamamla.bat | 134 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| stage19_basla.bat | 249 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage19_kontrol.bat | 249 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage19_tamamla.bat | 137 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| stage19_temizle.bat | 169 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage19_test.bat | 48 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| stage20_basla.bat | 249 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage20_kontrol.bat | 249 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage20_performans.bat | 177 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage20_release.bat | 207 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage20_tamamla.bat | 111 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| stage20_test.bat | 45 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| stage21_placeholder_test.bat | 200 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage22_gercek_servis_test.bat | 119 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage22_placeholder_test.bat | 119 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage23_placeholder_test.bat | 205 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage24_placeholder_test.bat | 492 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stage_gorevleri.bat | 155 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| stat.py | 3447 |  | %Y%,%d_% | no | no | yes - lightweight |  |
| sts.py | 4576 |  | %Y%,%d_% | no | no | yes - lightweight |  |
| stsx.py | 2808 |  |  | no | no | yes - lightweight |  |
| tum_test.bat | 145 |  |  | no | no | yes - lightweight | references files: py |
| UXMPerformansAnalizatoru.py | 13199 |  |  | no | no | yes - lightweight |  |
| uxm_analizor(birlesik).py | 4138 | uxminima |  | no | no | yes - lightweight | examples: uxminima(UX-MINIMA) |
| uxm_analizor.py | 1987 | uxminima |  | no | no | yes - lightweight | examples: uxminima(UX-MINIMA) |
| uxm_analizor2.py | 1947 | uxminima |  | no | no | yes - lightweight | examples: uxminima(UX-MINIMA) |
| UXM_EMEKLI_BUILD_ANALYZER_Y.py | 6073 | nasm | %M%,%Y%,%d_% | no | no | yes - needs: nasm | references files: exe,py; examples: nasm(nasm) |
| UXM_EXPECT_RUNNER_V2.py | 15822 | fbc,nasm,uxm_native | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm,uxm_native | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| UXM_Heavy_Asm_Optimizer.py | 4848 |  |  | no | no | yes - lightweight |  |
| uxm_optimizer_pro2.py | 5194 |  | %M%,%Y%,%d_% | no | yes | no | calls subprocess APIs; references files: exe; destructive operations |
| UXM_STAGE_RUNNER.py | 39553 | fbc,nasm,python_cmd | %M%,%Y%,%d_% | no | yes | no | calls subprocess APIs; references files: bat,exe,py,sh; examples: fbc(fbc),nasm(nasm),python_cmd(Python); destructive operations; and needs: fbc,nasm |
| UXM_STAGE_RUNNER_Y.py | 12023 | fbc,nasm | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: bat,exe,py; examples: fbc(fbc.exe),nasm(NASM) |
| UXM_V33_EXISTING_FLOW_MANAGER.py | 45214 | fbc,nasm,python_cmd,uxm31_compiler,uxm_native,zip | %EXTRA_ARGS%,%M%,%NAME%,%Y%,%d_% | yes | yes | no | calls subprocess APIs; references files: bat,exe,py; examples: fbc(fbc),nasm(NASM),uxm_native(uxm_native.exe),uxm31_compiler(uxm31_compiler),zip(zip),python_cmd(Python); interactive prompt; destructive operations; and needs: fbc,nasm,uxm31_compiler,uxm_native |
| UXM_WORKSPACE_TOPARLAYICI_Y.py | 7400 | zip | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: bat,py; examples: zip(zip) |
| UXM_ZIP_AUDITOR_Y.py | 3777 | zip | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: py; examples: zip(zip) |
| vscode_kur.bat | 99 |  |  | no | no | yes - lightweight | references files: py |
| yardim.bat | 876 |  |  | no | no | yes - lightweight | references files: bat |
| zekiassop.py | 5425 |  |  | no | no | yes - lightweight |  |
| araclar\uxm_alan_topla.py | 217 |  |  | no | no | yes - lightweight |  |
| araclar\uxm_beklenen_duzelt.py | 3102 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| araclar\uxm_hizli_tara.py | 205 |  |  | no | no | yes - lightweight |  |
| araclar\uxm_kosucu_tr.py | 798 |  |  | no | no | yes - lightweight | references files: exe,py |
| araclar\uxm_rapor_goster.py | 209 |  |  | no | no | yes - lightweight |  |
| araclar\uxm_stage18_native_bridge.py | 3779 |  | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: bat,py |
| araclar\uxm_stage19_vscode_temizle.py | 4869 |  | %M%,%Y%,%d_% | yes | no | no | references files: exe; interactive prompt |
| araclar\uxm_stage20_performans_release.py | 4290 |  | %M%,%Y%,%d_% | yes | no | no | calls subprocess APIs; references files: exe,sh; interactive prompt |
| araclar\uxm_stage_gorevleri.py | 3340 | nasm |  | no | no | yes - needs: nasm | references files: bat,py; examples: nasm(NASM) |
| araclar\uxm_test_kos.py | 205 |  |  | no | no | yes - lightweight |  |
| araclar\uxm_vscode_kur.py | 966 |  |  | no | no | yes - lightweight |  |
| Emekliler\analysis_artifacts\20260510_031351\PATCHED_EXISTING_FILES\build_optimizedy.py | 2659 | fbc,nasm |  | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: exe; examples: fbc(FBC),nasm(nasm) |
| Emekliler\analysis_artifacts\20260510_031351\PATCHED_EXISTING_FILES\run_opty.bat | 732 | python_cmd |  | yes | no | no | references files: py; examples: python_cmd(python); interactive prompt |
| Emekliler\analysis_artifacts\20260510_031351\PATCHED_EXISTING_FILES\stsxy.py | 5390 |  |  | no | yes | no | destructive operations |
| Emekliler\analysis_artifacts\20260510_031351\PATCHED_EXISTING_FILES\UXMPerformansAnalizatoruy.py | 5060 |  |  | no | no | yes - lightweight |  |
| Emekliler\analysis_artifacts\20260510_031351\PATCHED_EXISTING_FILES\UXM_Heavy_Asm_Optimizery.py | 4515 |  |  | no | no | yes - lightweight |  |
| Emekliler\analysis_artifacts\20260510_031351\PATCHED_EXISTING_FILES\zekiassopy.py | 4018 |  |  | no | no | yes - lightweight | calls subprocess APIs |
| Emekliler\asmoptimizer\cfg.py | 9857 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: py |
| Emekliler\asmoptimizer\core.py | 7121 |  |  | no | no | yes - lightweight | references files: py |
| Emekliler\asmoptimizer\duzeltme.py | 3952 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: py |
| Emekliler\asmoptimizer\klasoragaci.py | 1308 |  |  | no | no | yes - lightweight | references files: py |
| Emekliler\asmoptimizer\mainoptimizer.py | 1693 |  |  | no | no | yes - lightweight | references files: py |
| Emekliler\asmoptimizer\parser.py | 11881 |  |  | no | yes | no | references files: py; destructive operations |
| Emekliler\asmoptimizer\report.py | 6301 |  |  | no | yes | no | calls subprocess APIs; references files: py; destructive operations |
| Emekliler\asmoptimizer\rules.py | 39063 |  |  | no | no | yes - lightweight | references files: py |
| Emekliler\asmoptimizer\safety.py | 6058 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: py |
| Emekliler\asmoptimizer\utils.py | 4407 |  |  | no | yes | no | references files: py; destructive operations |
| Emekliler\onceki_duzeltmeler\PATCH_XLSX_SANITIZE_SNIPPET.py | 523 |  |  | no | no | yes - lightweight | references files: py |
| Emekliler\retired_srcs_20260516_140306\guncel_src\build_one_native.bat | 1242 | fbc,nasm,uxm_native | %ASM_OUT%,%EXE_OUT%,%FBC%,%FBC64%,%NAME%,%NASM%,%OBJ_OUT%,%RUNTIME_SRC%,%UXM_BUILD_ID% | no | no | yes - needs: fbc,fbc64,nasm,uxm_build_id,uxm_native | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| Emekliler\retired_srcs_20260516_140306\onceki_src\build_native.bat | 373 | fbc,uxm31_compiler,uxm_native | %FBC%,%FBC64% | no | no | yes - needs: fbc,fbc64,uxm31_compiler,uxm_native | references files: exe; examples: fbc(fbc.exe),uxm_native(uxm_native.exe),uxm31_compiler(uxm31_compiler) |
| Emekliler\retired_srcs_20260516_140306\onceki_src\build_one_native.bat | 1056 | fbc,nasm,uxm_native | %FBC%,%FBC64%,%NAME%,%NASM% | no | no | yes - needs: fbc,fbc64,nasm,uxm_native | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| Emekliler\retired_srcs_20260516_140306\onceki_src\stage17_runner_v11\uxm_arac_cekirdek_v11.py | 20343 | fbc,nasm,zip | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: bat,exe,sh; examples: fbc(fbc.exe),nasm(NASM),zip(zip) |
| Emekliler\retired_srcs_20260516_140306\onceki_src\v12\araclar\uxm_beklenen_duzelt.py | 2359 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| Emekliler\retired_srcs_20260516_140306\onceki_src\v12\ortak\uxm_arac_cekirdek.py | 21614 | fbc,nasm,zip | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: bat,exe,sh; examples: fbc(fbc.exe),nasm(NASM),zip(zip) |
| Emekliler\retired_srcs_20260516_140306\onceki_src\v12\tool_en\uxm_expect_fix.py | 2284 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| Emekliler\retired_srcs_20260516_140306\onceki_src\v13\stage19_tamamla.bat | 98 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| Emekliler\retired_srcs_20260516_140306\onceki_src\v13\araclar\uxm_expect_temizleme.py | 3102 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| Emekliler\retired_srcs_20260516_140306\onceki_src\v13\araclar\uxm_test_kos.py | 205 |  |  | no | no | yes - lightweight |  |
| Emekliler\retired_srcs_20260516_140306\onceki_src\v13\ortak\uxm_arac_cekirdek.py | 22545 | fbc,nasm,zip | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: bat,exe,sh; examples: fbc(fbc.exe),nasm(NASM),zip(zip) |
| Emekliler\tools_retired_20260516_131714\placeholder_kesin_tara.py | 2580 |  |  | no | no | yes - lightweight |  |
| Emekliler\tools_retired_20260516_131714\placeholder_tara.py | 2178 | zip |  | no | no | yes - lightweight | examples: zip(zip) |
| Emekliler\tools_retired_20260516_131714\placeholder_v19_uygula.py | 3708 |  | %M%,%Y%,%d_% | yes | no | no | references files: bat; interactive prompt |
| Emekliler\tools_retired_20260516_131714\UXM_EMEKLI_BUILD_ANALYZER_V4.py | 1629 |  | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: exe |
| Emekliler\tools_retired_20260516_131714\UXM_EXPECT_RUNNER_V2.py | 15822 | fbc,nasm,uxm_native | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm,uxm_native | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| Emekliler\tools_retired_20260516_131714\UXM_EXPECT_RUNNER_V3.py | 15330 | fbc,nasm,uxm_native | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm,uxm_native | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| Emekliler\tools_retired_20260516_131714\UXM_EXPECT_RUNNER_V4.py | 15676 | fbc,nasm,uxm_native | %04d_%,%M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm,uxm_native | calls subprocess APIs; references files: bat,exe,sh; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| Emekliler\tools_retired_20260516_131714\UXM_EXPECT_RUNNER_V5.py | 15783 | fbc,nasm,uxm_native | %04d_%,%M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm,uxm_native | calls subprocess APIs; references files: bat,exe,sh; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| Emekliler\tools_retired_20260516_131714\UXM_FAST_KEY_SCAN_V6.py | 16428 |  | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: bat |
| Emekliler\tools_retired_20260516_131714\UXM_FAST_KEY_SCAN_V7.py | 5300 |  |  | no | no | yes - lightweight | references files: exe |
| Emekliler\tools_retired_20260516_131714\UXM_FAST_KEY_SCAN_V8.py | 5407 |  |  | no | no | yes - lightweight | references files: exe |
| Emekliler\tools_retired_20260516_131714\UXM_FIX_KNOWN_MISMATCHES_V4.py | 4666 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| Emekliler\tools_retired_20260516_131714\UXM_MISMATCH_DIAGNOSER_V4.py | 4319 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| Emekliler\tools_retired_20260516_131714\UXM_WORKSPACE_ORGANIZER_V4.py | 2745 |  | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: bat |
| Emekliler\y_denemeleri\20260510_031351\build_native_cache_y.bat | 999 | fbc | %CACHE_OBJ%,%FBC%,%RUNTIME%,%UXM_FBC%,%cd%,%errorlevel% | no | no | yes - needs: fbc,uxm_fbc | calls subprocess APIs; references files: bat,exe; examples: fbc(FBC) |
| Emekliler\y_denemeleri\20260510_031351\build_one_native_cache_y.bat | 909 | fbc | %ARG2%,%CACHE_OBJ%,%FBC%,%SRC%,%UXM_FBC%,%errorlevel% | no | no | yes - needs: fbc,uxm_fbc | calls subprocess APIs; references files: bat,exe; examples: fbc(FBC) |
| Emekliler\y_denemeleri\20260510_185908\run_06_workspace_clean_apply.bat | 193 |  |  | no | no | yes - lightweight | references files: py |
| Emekliler\y_denemeleri\20260510_185908\run_12_rerun_buildfail_only.bat | 534 |  | %errorlevel% | no | no | yes - lightweight | references files: bat,py |
| Emekliler\y_denemeleri\20260510_185908\run_13_rerun_mismatch_only.bat | 401 |  | %errorlevel% | no | no | yes - lightweight | references files: py |
| Emekliler\y_denemeleri\20260510_185908\run_14_rerun_memory_policy_only.bat | 536 |  | %errorlevel% | no | no | yes - lightweight | references files: py |
| Emekliler\y_denemeleri\20260510_185908\run_mismatch_solver_v3_apply.bat | 113 |  |  | no | no | yes - lightweight | references files: py |
| Emekliler\_UXM_EMEKLI\toparlama_raporlari\20260510_031359\UNDO_toparlama_y.bat | 135 |  |  | no | no | yes - lightweight |  |
| Emekliler\_UXM_EMEKLI\toparlama_raporlari\20260510_185908\UNDO_toparlama_y.bat | 135 |  |  | no | no | yes - lightweight |  |
| Emekliler\_UXM_EMEKLI\toparlama_raporlari\20260510_185928\UNDO_toparlama_y.bat | 135 |  |  | no | no | yes - lightweight |  |
| ortak\uxm_arac_cekirdek.py | 22545 | fbc,nasm,zip | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: bat,exe,sh; examples: fbc(fbc.exe),nasm(NASM),zip(zip) |
| tools\aggregate_extension_findings.py | 1510 |  |  | no | no | yes - lightweight |  |
| tools\apply_canonical_impls.py | 6239 |  |  | no | no | yes - lightweight | references files: py |
| tools\copy_canonical_services.py | 3337 | git | %M%,%Y%,%d% | no | no | yes - lightweight | calls subprocess APIs; examples: git(git) |
| tools\find_case_impl.py | 4026 |  |  | no | no | yes - lightweight |  |
| tools\generate_meta_service_mapping.py | 804 |  |  | no | no | yes - lightweight |  |
| tools\manifest_impl_finder.py | 2888 |  |  | no | no | yes - lightweight |  |
| tools\manifest_impl_finder_limited.py | 2901 |  |  | no | no | yes - lightweight |  |
| tools\resolve_extension_flags.py | 2366 |  |  | no | no | yes - lightweight |  |
| tools\run_c64basic_to_uxm.bat | 49 |  |  | no | no | yes - lightweight | references files: py |
| tools\run_qbasic_to_uxm.bat | 47 |  |  | no | no | yes - lightweight | references files: py |
| tools\run_uxm_with_comm_watcher.bat | 778 | powershell,python_cmd,uxm_native | %WATCHER%,%errorlevel% | no | no | yes - needs: uxm_native | references files: exe,py; examples: uxm_native(uxm_native.exe),python_cmd(python),powershell(Start-Process) |
| tools\scan_test_scripts.py | 5871 | 7z,fbc,git,nasm,npx,powershell,python_cmd,robocopy,tar,uxm31_compiler,uxm31_compiler_final,uxm_native,uxminima,vsce,zip | %FBC% | yes | yes | no | references files: exe,ps1; examples: fbc(fbc),nasm(nasm),uxm_native(uxm_native),uxm31_compiler(uxm31_compiler),uxm31_compiler_final(uxm31_compiler_final),uxminima(uxminima),vsce(vsce),npx(npx),robocopy(robocopy),7z(7z),zip(zip),tar(tar),git(git),python_cmd(python),powershell(Read-Host); interactive prompt; destructive operations; and needs: fbc,nasm,npx,robocopy,uxm31_compiler,uxm31_compiler_final,uxm_native,vsce |
| tools\scan_zips_for_impls.py | 2073 | zip |  | yes | no | no | examples: zip(zip); interactive prompt |
| tools\search_missing_impls.py | 2740 | zip |  | yes | no | no | examples: zip(zip); interactive prompt |
| tools\UXM_ALL_EXPECT_RUNNER.py | 6816 | fbc,nasm | %M%,%Y%,%d_% | no | yes | no | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc.exe),nasm(NASM); destructive operations; and needs: fbc,nasm |
| tools\uxm_c64basic_to_uxm.py | 1225 |  |  | no | no | yes - lightweight |  |
| tools\UXM_EXPECT_RUNNER_V6.py | 15783 | fbc,nasm,uxm_native | %04d_%,%M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm,uxm_native | calls subprocess APIs; references files: bat,exe,sh; examples: fbc(fbc.exe),nasm(NASM),uxm_native(uxm_native.exe) |
| tools\UXM_FAST_KEY_SCAN_V9.py | 5407 |  |  | no | no | yes - lightweight | references files: exe |
| tools\UXM_MISMATCH_SOLVER_V3.py | 7618 |  | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: exe |
| tools\uxm_qbasic_to_uxm.py | 3211 |  |  | no | no | yes - lightweight |  |
| tools\UXM_STAGE17_EXPECT_RUNNER.py | 15746 | fbc,nasm,uxm_native | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm,uxm_native | calls subprocess APIs; references files: bat,exe; examples: fbc(fbc),nasm(NASM),uxm_native(uxm_native.exe) |
| tools\UXM_TIMING_ANALYZER_V2.py | 1452 |  |  | no | no | yes - lightweight |  |
| tools\uxm_ops\UXM_EMEKLI_BUILD_ANALYZER_V5.py | 2205 |  | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: exe |
| tools\uxm_ops\UXM_FIX_KNOWN_MISMATCHES_V5.py | 9196 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| tools\uxm_ops\UXM_MISMATCH_DIAGNOSER_V5.py | 4148 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| tools\uxm_ops\UXM_TOOL_LAUNCHER.py | 1972 |  |  | no | no | yes - lightweight | references files: exe,py |
| tools\uxm_ops\UXM_WORKSPACE_ORGANIZER_V5.py | 3320 | git,zip | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: bat; examples: zip(zip),git(git) |
| tools\vscode_integration\comm_watcher.py | 5089 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| tools\vscode_integration\uxm_control_server.py | 5167 |  |  | yes | no | no | calls subprocess APIs; references files: bat; interactive prompt |
| tools_y\build_native_cache_y.bat | 999 | fbc | %CACHE_OBJ%,%FBC%,%RUNTIME%,%UXM_FBC%,%cd%,%errorlevel% | no | no | yes - needs: fbc,uxm_fbc | calls subprocess APIs; references files: bat,exe; examples: fbc(FBC) |
| tools_y\build_one_native_cache_y.bat | 909 | fbc | %ARG2%,%CACHE_OBJ%,%FBC%,%SRC%,%UXM_FBC%,%errorlevel% | no | no | yes - needs: fbc,uxm_fbc | calls subprocess APIs; references files: bat,exe; examples: fbc(FBC) |
| tools_y\run_emekli_build_analyzer_y.bat | 125 |  | %errorlevel% | no | no | yes - lightweight | references files: py |
| tools_y\run_full_y.bat | 398 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| tools_y\run_stage_y.bat | 413 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| tools_y\run_toparlayici_y_apply.bat | 213 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| tools_y\run_toparlayici_y_dryrun.bat | 182 |  | %STAGE_ARG%,%errorlevel% | no | no | yes - lightweight | references files: py |
| tools_y\UXM_EMEKLI_BUILD_ANALYZER_Y.py | 6073 | nasm | %M%,%Y%,%d_% | no | no | yes - needs: nasm | references files: exe,py; examples: nasm(nasm) |
| tools_y\UXM_STAGE_RUNNER_Y.py | 12023 | fbc,nasm | %M%,%Y%,%d_% | no | no | yes - needs: fbc,nasm | calls subprocess APIs; references files: bat,exe,py; examples: fbc(fbc.exe),nasm(NASM) |
| tools_y\UXM_WORKSPACE_TOPARLAYICI_Y.py | 7400 | zip | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: bat,py; examples: zip(zip) |
| tools_y\UXM_ZIP_AUDITOR_Y.py | 3777 | zip | %M%,%Y%,%d_% | no | no | yes - lightweight | references files: py; examples: zip(zip) |
| tool_en\all_test.bat | 147 |  |  | no | no | yes - lightweight | references files: py |
| tool_en\apply_placeholder_v19.bat | 62 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\apply_placeholder_v19.py | 3695 |  | %M%,%Y%,%d_% | yes | no | no | references files: bat; interactive prompt |
| tool_en\expect_fix.bat | 110 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\failed_test.bat | 261 |  | %ERRORLEVEL% | no | no | yes - lightweight | references files: py |
| tool_en\fast_scan.bat | 124 |  |  | no | no | yes - lightweight | references files: py |
| tool_en\help.bat | 853 |  |  | no | no | yes - lightweight | references files: bat |
| tool_en\memory_test.bat | 142 |  |  | no | no | yes - lightweight | references files: py |
| tool_en\placeholder_audit.bat | 83 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\placeholder_audit.py | 2178 | zip |  | no | no | yes - lightweight | examples: zip(zip) |
| tool_en\placeholder_strict_scan.bat | 102 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\placeholder_strict_scan.py | 2577 |  |  | no | no | yes - lightweight |  |
| tool_en\placeholder_test.bat | 131 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\plan_status.bat | 37 |  |  | no | no | yes - lightweight |  |
| tool_en\report_show.bat | 103 |  |  | no | no | yes - lightweight | references files: py |
| tool_en\stage17_check.bat | 250 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage17_finish.bat | 123 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| tool_en\stage17_fix.bat | 180 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage18_check.bat | 250 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage18_finish.bat | 155 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| tool_en\stage18_fix.bat | 202 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage18_native.bat | 170 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage18_start.bat | 194 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage19_check.bat | 250 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage19_cleanup.bat | 172 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage19_finish.bat | 166 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| tool_en\stage19_start.bat | 212 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage19_test.bat | 56 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| tool_en\stage20_check.bat | 250 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage20_finish.bat | 128 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| tool_en\stage20_performance.bat | 182 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage20_release.bat | 210 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage20_start.bat | 204 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage20_test.bat | 45 |  |  | no | no | yes - lightweight | calls subprocess APIs; references files: bat |
| tool_en\stage22_placeholder_test.bat | 121 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage24_placeholder_test.bat | 401 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\stage_tasks.bat | 150 | python_cmd |  | no | no | yes - lightweight | references files: py; examples: python_cmd(python) |
| tool_en\uxm_expect_fix.py | 3081 |  | %M%,%Y%,%d_% | no | no | yes - lightweight |  |
| tool_en\uxm_fast_scan.py | 205 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_report_show.py | 209 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_stage18_native_bridge.py | 201 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_stage19_vscode_cleanup.py | 202 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_stage20_performance_release.py | 206 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_stage_tasks.py | 195 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_test_run.py | 205 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_vscode_install.py | 998 |  |  | no | no | yes - lightweight |  |
| tool_en\uxm_workspace_clean.py | 217 |  |  | no | no | yes - lightweight |  |
| tool_en\vscode_install.bat | 106 |  |  | no | no | yes - lightweight | references files: py |
| tool_en\workspace_clean.bat | 107 |  |  | no | no | yes - lightweight | references files: py |
| vscode\kurulum\vscode_kur.bat | 92 |  |  | no | no | yes - lightweight | references files: ps1 |
| vscode\kurulum\vscode_kur.ps1 | 469 |  | $ErrorActionPreference,$MyInvocation,$dest,$env,$root,$src | no | no | yes - lightweight |  |
