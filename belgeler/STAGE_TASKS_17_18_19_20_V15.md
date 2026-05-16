# UXM Stage 17-20 Tasks — V15

This document follows the user's exact stage definitions. V14 interpreted Stage-19/20 incorrectly; V15 corrects that.

| Stage | Actual task | V15 deliverables |
|---|---|---|
| Stage-17 | Test Framework Upgrade: `.expect` logic, expected/actual comparison, status/flags/data/tape checks. | `ortak/uxm_arac_cekirdek.py`, `araclar/uxm_beklenen_duzelt.py`, `uxm/tests/stage17`, `manifests/stage17_manifest.csv`, `stage17_tamamla.bat`. |
| Stage-18 | Final/ARGE + Native Bridge: move the final compiler's old separate parser/runner lane closer to the native core. | `araclar/uxm_stage18_native_bridge.py`, `uxm/tests/stage18`, `manifests/stage18_manifest.csv`, `stage18_native.bat`, `stage18_tamamla.bat`. |
| Stage-19 | VSCode Integration Cleanup: old internal-interpreter warnings, final compiler build errors, trace/diagnostic alignment. | `araclar/uxm_stage19_vscode_temizle.py`, `vscode/uxm-dil-destegi-v15`, `uxm/tests/stage19`, `stage19_temizle.bat`, `stage19_tamamla.bat`. |
| Stage-20 | Performance + Release Cleanup: exe-only timing runner, build cache, documentation generation, service-table automation. | `araclar/uxm_stage20_performans_release.py`, `uxm/tests/stage20`, `stage20_performans.bat`, `stage20_release.bat`, automatic service table generation. |

## Run order

```powershell
tool_en\stage_tasks.bat
tool_en\stage17_finish.bat -k
tool_en\stage18_finish.bat -k
tool_en\stage19_finish.bat -k
tool_en\stage20_finish.bat -k
```
