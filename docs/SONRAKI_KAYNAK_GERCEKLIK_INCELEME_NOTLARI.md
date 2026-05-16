# Sonraki Kaynak Kod Gerçekliği İncelemesi İçin Notlar

İncelemede özellikle şu dosya ve katmanlara bakılmalı:

1. `uxm/core/runtime/uxm31_runtime_fb_full.bas`
   - Runtime include sırası
   - Declare merkezi
   - Her yeni servis için tek merkez standardı

2. `uxm/core/runtime/runtime_meta_dispatch.bas`
   - Servis aralıkları çakışıyor mu?
   - Stage 15/16 servisleri `@700..@759` doğru yönleniyor mu?

3. `uxm/core/runtime/services/runtime_ml_data_pipeline_services.bas`
   - `MatInit` imza uyumu düzeltildi mi?
   - Dataset/vector/matrix köprüleri gerçek runtime descriptor standardıyla uyumlu mu?

4. `build_one_native.bat`
   - Her testte runtime `.bas` tekrar derleniyor mu?
   - Runtime cache/object link mümkün mü?
   - `ld.exe not found` hatası toolchain yolu mu, PATH mi?

5. `UXM_STAGE_RUNNER.py` ve Y hattı
   - Ana runner ile Y runner aynı dosyaları kullanıyor mu?
   - CSV ayrımı temiz mi?
   - XLSX kontrol karakteri temizliği kalıcı mı?

6. `Emekliler/build*`
   - Hatalar tek testten mi geliyor, runtime include kırılmasından mı?
   - Stage kırılmaları hangi dosyada yoğunlaşıyor?

7. Optimizer hattı
   - Şimdilik üretim kritik değil.
   - `yeni_optimize_asm` ayrı deney hattı olarak tutulmalı.
   - ASM optimizer kaynak kodu otomatik bozacak moda alınmamalı; önce analyze-only.
