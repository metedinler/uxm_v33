# Stage 12 İçin Net İşlem Sırası

1. `audit`
   - Mevcut `.bat/.py/.csv/.xlsx` dosyalarının görevini çıkar.
   - Aynı işi yapan dosyaları değil, aktif sırayı belirler.

2. `pause-patch --dry-run`
   - EXE sonunda tuş bekleme patch planını gösterir.
   - Test runner kilitlenmesin diye varsayılan bekleme yoktur.

3. İstersen `pause-patch --apply`
   - Sadece manuel `--pause` veya `#pause` durumunda EXE sonunda tuş bekler.
   - `build_one_native.bat` aynı kalır ama üçüncü argümandan sonrasını compiler'a geçirir.

4. `run --stage 12`
   - Smoke önce.
   - Build sonra.
   - Full test sonra.
   - Süre istatistiği ve expected-output kontrolü sonra.

5. `opt --stage 12 --analyze-only`
   - ASM raporlarını ve geniş kural kitabını üretir.
   - Riskli otomatik değişim yapmaz.

6. `opt --stage 12 --continue-on-error`
   - Mevcut optimizer zincirini çalıştırır.
   - Orijinal/optimize EXE karşılaştırmasını `uxm_optimizer_pro2.py` ile yapar.

7. `toparla --stage 12 --dry-run --move-build`
   - Nelerin emekliye taşınacağını gösterir.

8. `toparla --stage 12 --apply --move-build`
   - Build ve eski rapor/logları `_UXM_EMEKLI` altına taşır.
