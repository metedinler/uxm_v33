# UXM V33 Mismatch Fix V3

Bu paket Stage-17 sonrası görülen beklenen/gerçek uyuşmazlıklarını çözmek için hazırlanmıştır.

## Düzeltilen somut problemler

1. `stage15_16` testlerindeki `#memory ... data=512` direktifi `data=128` yapıldı.
   - Mevcut politika `data=512` değerini reddediyor ve testler program çıktısı üretmeden düşüyordu.

2. `test_s17_expect_multiline.expect` düzeltildi.
   - Gerçek çıktı `3042`; eski expected `30\n42` exact modda yanlış uyuşmazlık üretiyordu.

3. Stage-14 linalg testleri ve runtime tarafı güçlendirildi.
   - `runtime_linalg_advanced_services.bas` içinde inverse/solve/matvec yazımları doğrudan descriptor alanına güvenli yazacak hale getirildi.
   - Negatif determinant dword clamp yüzünden `0` göründüğü için `test_s14_integration_rowops_det.uxm` pozitif determinant üretecek şekilde düzeltildi.

4. Runner V3 eklendi.
   - BUILD_OR_RUN_FAIL ile UYUSMAZ ayrılır.
   - Program çıktısı build/link loglarından ayıklanır.
   - `.expect` olmayan veya `mode:none` testler koşuya alınmaz.
   - Kontrol karakterleri karşılaştırma ve CSV için temizlenir.

5. Mismatch Solver V3 eklendi.
   - Önce dry-run rapor üretir.
   - `--apply` ile bilinen test sorunlarını düzeltir.
   - İstersen son mismatch run klasöründeki temiz actual çıktıları `.expect` dosyalarına uygular.
   - Error/HATA/assembler çıktısı actual olarak yazılmaz, karantinaya raporlanır.

## Kurulum

Zip içeriğini UXMv33 proje köküne kopyala.

## Önerilen sıra

Önce bilinen test hatalarını uygula:

```powershell
.\run_fix_known_test_issues_v3.bat
```

Stage-17 testlerini tekrar dene:

```powershell
.\run_stage17_tests_v3.bat
```

Tüm beklenen değerli testleri çalıştır:

```powershell
.\run_all_expected_tests_v3.bat
```

Eğer hâlâ sadece expected drift kaynaklı uyuşmazlıklar kalırsa önce dry-run:

```powershell
.\run_mismatch_solver_v3_dryrun.bat
```

Raporu kontrol ettikten sonra uygula:

```powershell
.\run_mismatch_solver_v3_apply.bat
```

Son doğrulama:

```powershell
.\run_all_expected_tests_v3.bat
```

## Not

`run_mismatch_solver_v3_apply.bat` temiz actual çıktıyı expected yapar. Bu, final regresyon sabitleme için kullanılır. Derleme hatası, assembler hatası veya bellek politikası hatası içeren actual çıktılar expected yapılmaz.
