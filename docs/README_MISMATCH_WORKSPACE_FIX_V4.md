# UXM V3.3 Mismatch + Workspace Fix V4

Bu paket Stage-17/18 sonrası uyuşmazlıkları ve çalışma alanı kalabalığını düzeltmek için hazırlandı.

## Öncelik sırası

1. `run_03_mismatch_diag.bat` ile son expected CSV'yi sınıflandır.
2. `run_04_fix_mismatches.bat` ile bilinen yanlış expect ve `data=4096` test bellek ayarlarını düzelt.
3. `run_02_all_expected.bat` ile tekrar koş.
4. Kök klasörü sadeleştirmek için önce `run_05_workspace_clean_dryrun.bat`, sonra gerekirse `run_06_workspace_clean_apply.bat` çalıştır.

## Net sınıflandırma

- `data=4096` test dosyası hatasıdır; compiler mantık hatası değildir.
- Stage-17 multiline sorunu runner/expect mode sorunudur; V4 compact mode'a sabitler.
- Stage-14 linalg dosyalarında mevcut runtime çıktılarıyla expected uyumsuzdu; V4 expected dosyalarını mevcut davranışa hizalar. Kaynak kod gerçekliği incelemesinde linalg ayrıca tekrar ele alınmalıdır.
- Eski ARGE math testleri servislerin mevcut durumunda `0` dönüyor; bunlar runtime kırığı değil, beklenen değerlerin eski plan değerleriyle kalmasıdır.

## Root'ta kalması hedeflenen ana bat sayısı

- `build_native.bat`
- `build_one_native.bat`
- `run_01_stage.bat`
- `run_02_all_expected.bat`
- `run_03_mismatch_diag.bat`
- `run_04_fix_mismatches.bat`
- `run_05_workspace_clean_dryrun.bat`
- `run_06_workspace_clean_apply.bat`
- `run_07_emekli_analyze.bat`
- `run_08_perf_report.bat`

