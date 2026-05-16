# Tools Envanteri ve Yeniden Düzenleme Planı

Tarih: 2026-05-16
Hazırlayan: otomatik kod-tarama aracı

Amaç
- Mevcut yardımcı araçları (`tools/`, `araclar/`, `tools_y/` ve kök dizindeki küçük scriptler) tarayıp sınıflandırmak,
- Her aracın kullanım amacını ve birbirleriyle nasıl etkileştiğini belgelemek,
- Eski/çiftlenmiş veya gereksiz araçları `Emekliler/` altına taşıma önerisi hazırlamak,
- Son olarak tek bir `tools/` yapısında derleme, tek-derleme, karşılaştırma ve istatistik amaçlı alt-kategoriler oluşturmak.

Kısa Özet / Karar
- "Keep" (saklanacak): en güncel, aktif ve bağımlı araçlar (ör. `UXM_EXPECT_RUNNER_V6.py`, `UXM_FAST_KEY_SCAN_V9.py`, `apply_canonical_impls.py`, `generate_meta_service_mapping.py`, `UXM_MISMATCH_SOLVER_V3.py`, `uxm_ops/UXM_WORKSPACE_ORGANIZER_V5.py`, `ortak/uxm_arac_cekirdek.py`).
- "Retire" (emekliye önerilen): aynı işlevin daha eski versiyonları ve placeholder/deneme scriptleri. Aşağıda aday liste ve kısa amaç açıklamaları bulunuyor.
- Taşıma: Emekli edilecek dosyalar `Emekliler/tools_retired_<timestamp>/...` altına taşınacak (varsayılan: dry-run; uygulama için onay gerekli).

Kategoriler ve Dosya Grupları

1) Manifest / Case mapping & apply (bulma ve uygulama)
- `generate_meta_service_mapping.py` : config/uxm/meta_services.json'dan CSV üretir.
- `manifest_impl_finder.py`, `manifest_impl_finder_limited.py` : manifest ile runtime implementasyonlarını tarar ve eksik ID'leri arar.
- `find_case_impl.py`, `aggregate_extension_findings.py`, `search_missing_impls.py`, `scan_zips_for_impls.py` : farklı kaynaklarda Case <id> aramalarını gerçekleştirir ve CSV raporları üretir.
- `apply_canonical_impls.py`, `copy_canonical_services.py` : canonical (strongestSRC/onceki_src) implementasyonları hedef `uxm/core/runtime/services/` altına ekler; yedek alır.

Amaç: Manifest ile runtime arasındaki boşlukları bularak canonical implementasyonları otomatik eklemek; mapping raporları üretmek.

2) Test Koşu / Beklenen karşılaştırma (expect runner)
- `UXM_EXPECT_RUNNER_V6.py` (KEEP): Kompleks expect formatlarını işleyen, build-one/derleme ve karşılaştırma yapan ana test koşucu.
- `UXM_EXPECT_RUNNER_V2.py`..`V5.py` (RETIRE adayları): V6 öncesi sürümler; mantık ve argüman seti V6'da birleştirilmiş.
- `UXM_STAGE17_EXPECT_RUNNER.py`, `UXM_ALL_EXPECT_RUNNER.py` : özel runner'lar / toplu çalıştırıcılar (KEEP/merge önerisi).

Amaç: Tüm test suitlerini derleme, çalıştırma, beklenen-çıktı karşılaştırma, rapor üretme.

3) Hızlı anahtar tarama ve sınıflandırma
- `UXM_FAST_KEY_SCAN_V9.py` (KEEP): Büyük CSV'lerden hızlıca hata anahtarlarını seçer, sınıflandırır ve özet/manifest üretir.
- `UXM_FAST_KEY_SCAN_V6.py`..`V8.py` (RETIRE adayları): Eski sürümler; mantık V9'da toplandı.

Amaç: Hızlı analiz, hatalı-anahtar manifestleri ve sınıf özetleri üretmek.

4) Mismatch / otomatik düzeltme / karantinaya alma
- `UXM_MISMATCH_SOLVER_V3.py` (KEEP): Bilinen test hatalarını düzeltme, mismatch dizinlerinden güvenli beklenenleri apply etme (dry-run vs apply).
- `UXM_MISMATCH_DIAGNOSER_V4/ V5` (V5 keep, V4 retire): Diagnostik araçlar.

Amaç: Test mismatch'lerini işlemek, otomatik düzeltme ve karantina raporları üretmek.

5) Workspace organizasyon / cleanup / archive
- `uxm_ops/UXM_WORKSPACE_ORGANIZER_V5.py` (KEEP): Root düzeyindeki eski/büyük dosyaları `Emekliler/` altına taşıyan araç.
- `uxm_ops/UXM_WORKSPACE_ORGANIZER_V4.py` (RETIRE)

Amaç: Proje kökünü temizlemek, Emekliler altında arşivlemek.

6) Yardımcı & dönüşüm araçları (format/bridge/convert)
- `uxm_qbasic_to_uxm.py`, `uxm_c64basic_to_uxm.py` (KEEP): QBasic/C64Basic’dan UXM dönüştürücü yardımcıları.
- `resolve_extension_flags.py`, `UXM_TIMING_ANALYZER_V2.py`, `UXM_ALL_EXPECT_RUNNER.py` (KEEP/merge önerisi)

7) Kök ve `araclar/` küçük yardımcı sarmalayıcılar
- `araclar/*` : `uxm_hizli_tara.py`, `uxm_beklenen_duzelt.py`, `uxm_rapor_goster.py`, `uxm_vscode_kur.py`, `uxm_stage*` vb. — bunlar `ortak/uxm_arac_cekirdek.py` içindeki fonksiyonların küçük CLI sarmalayıcılarıdır (KEEP). `placeholder_*` scriptleri (RETIRE) test/placeholder amaçlı.

8) `tools_y/` dizini
- `tools_y/` içindeki araçlar (`*_Y.py`, `run_*.bat`) genelde `tools/`'un yakından ilişkili ama paralel geliştirilmiş varyantlarıdır. Bunları iki seçenekle ele alabilirsiniz:
  - Merge: `tools_y/` içeriğini `tools/`'a entegre edip `*_Y` suffixlerini kaldırmak ve kodu uyumlu hale getirmek.
  - Retire: Eğer `tools_y` sadece eski/alternatif sürümler ise tamamını `Emekliler/tools_y_retired/` altına taşımak.

Emekli Adayları (Önerilen taşıma listesi)
- `tools/UXM_EXPECT_RUNNER_V2.py`
- `tools/UXM_EXPECT_RUNNER_V3.py`
- `tools/UXM_EXPECT_RUNNER_V4.py`
- `tools/UXM_EXPECT_RUNNER_V5.py`
- `tools/UXM_FAST_KEY_SCAN_V6.py`
- `tools/UXM_FAST_KEY_SCAN_V7.py`
- `tools/UXM_FAST_KEY_SCAN_V8.py`
- `tools/uxm_ops/UXM_WORKSPACE_ORGANIZER_V4.py`
- `tools/uxm_ops/UXM_MISMATCH_DIAGNOSER_V4.py`
- `tools/uxm_ops/UXM_FIX_KNOWN_MISMATCHES_V4.py`
- `tools/uxm_ops/UXM_EMEKLI_BUILD_ANALYZER_V4.py`
- `tools/tmp_unzip/` (geçici çıkarma klasörü)
- `araclar/placeholder_tara.py`
- `araclar/placeholder_kesin_tara.py`
- `araclar/placeholder_v19_uygula.py`

Ayrıntılı amaç açıklamaları (emekli adayları)
- `UXM_EXPECT_RUNNER_V2..V5.py` : Tekil test koşucularının gelişmiş geçmiş sürümleri. V6, farklı kriterleri, kontrol karakterlerin güvenli işlemesini ve modern CSV boyut ayarlarını içerir; bu yüzden eski sürümler emekli edilebilir.
- `UXM_FAST_KEY_SCAN_V6..V8.py` : Hızlı anahtar tarayıcılarının eski sürümleri. V9 performans ve sınıflandırma (MEMORY_POLICY, LDAP, LINK_OR_TOOLCHAIN gibi) iyileştirmeleri içerir.
- `UXM_WORKSPACE_ORGANIZER_V4.py` : Workspace temizleme mantığının V5'te geliştirildiği ve taşma/unique isimlendirme gibi iyileştirmelerin V5'te olduğu gözleniyor.
- `UXM_MISMATCH_DIAGNOSER_V4.py` / `UXM_FIX_KNOWN_MISMATCHES_V4.py` : V5 sürümleriyle birleştirilmiş veya geliştirilmiş. V4 sürümleri arşivlenebilir.
- `UXM_EMEKLI_BUILD_ANALYZER_V4.py` : Eski analizci; V5 daha iyi raporlama sağlıyor.
- `tools/tmp_unzip/` : Geçici çalışma alanı; versiyon kontrolü altında tutulmamalı veya Emekliler altına taşınabilir.
- `araclar/placeholder_*.py` : Placeholder/deneme scriptleri; projede karışıklık yaratabilir, Emekliler'e taşınması tavsiye edilir.

Önerilen Hedef Yapı (son hali)

```
tools/
  build/                # derleme yardımcıları (build_native.bat, build_one_native.bat)
  test/                 # test runner (UXM_EXPECT_RUNNER_V6.py -> uxm_test_runner.py)
  scan/                 # fast scan, mismatch solver, analiz (fast_key_scan.py, mismatch_solver.py)
  mapping/              # manifest/case mapping & apply araçları
  ops/                  # workspace organizer, fixer, diagnoser (uygun V5 sürümleri)
  helpers/              # converter, timing analyzer, script launcher
  backups/

araclar/                # küçük CLI sarmalayıcılar (keep: wrappers calling ortak/)
ortak/                  # paylaşılan kütüphane (keep)
Emekliler/
  tools_retired_<ts>/   # taşınmış eski scriptler (dry-run veya onaylı taşıma sonrası)
```

Taşıma Uygulama Adımları (öneri)
1. Dry-run manifest oluştur: `uxm_ops/UXM_WORKSPACE_ORGANIZER_V5.py --root .` (çıktı raporunu incele).
2. Onay sonrası taşıma: aynı aracı `--apply` ile çalıştırarak dosyaları `Emekliler/` altına taşı.
3. Alternatif olarak, emekli aday listesinde belirtilen dosyaları tek tek `Emekliler/tools_retired_<ts>/` altına taşı (otomatik script hazırlanabilir).
4. Yeni `tools/` dizin şemasını oluşturup, saklanacak araçları uygun alt dizinlere taşı.
5. `git add` -> `git commit -m "TR: tools reorg — move retired scripts to Emekliler and restructure"` ve push (push başarısız olursa blok açıklaması verilir).

Riskler / Notlar
- Bazı eski scriptler, diğer scriptler tarafından doğrudan import ediliyor olabilir; taşımadan önce `import` ve çağrı bağımlılıkları kontrol edilmeli.
- `tools_y/` içindeki bazı scriptler alternatif iş akışları sağlıyor olabilir; tam taşımada test edilmeli.
- `tools/tmp_unzip/` gibi geçici dizinlerin taşınması yerine `.gitignore` ile hariç tutulması daha uygun olabilir.

Sonraki Adım
- Onay verirseniz: ben listedeki dosyaları `Emekliler/tools_retired_<ts>/` altına taşıyıp, `docs/TOOLS_INVENTORY_AND_REORG_PLAN.md` dokümanını commit edeceğim. Taşıma sırasında herhangi bir hata/çakışma olursa tam rapor vereceğim.

