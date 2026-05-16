# UXM Runtime — Koddan Türetilmiş Kullanım Kılavuzu (Özet)

Bu belge, çalışma zamanındaki (runtime) servis çağrı modeli, adresleme, servis aileleri, dallanma/döngü davranışı, hook/wrapper pattern ve proje içinde gözlenen `pragma`/build-flag kullanımını kodu tarayarak özetler. Kaynaklara dayalı hızlı referans amaçlıdır.

**Özet**
- UXM runtime servisleri meta-ID ile çağrılır; dispatcher içinde `Select Case metaId` şeklinde Case blokları bulunur (ana dispatcher: `uxm/core/runtime/runtime_meta_dispatch.bas`).
- Uzantılar ve remap'ler hook dispatcher'lar aracılığıyla yönlendirilir (ör. `uxm/core/runtime/hooks/runtime_hook_dispatch_ext.bas`).
- Argümanlar ve sonuçlar "T-register" (top-of-stack) tabanlı bir çerçevede taşınır: `T-4`, `T-3`, `T-2`, `T-1`, `T`, dönüş `T+1`.

**Çağrı modeli / nasıl servis çağırılır**
- Adım 1: Hizmetin beklediği T-frame'i hazırla (dokümanda her servisin beklediği frame örnekleri var, örn. mat servisleri `T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2`).
- Adım 2: Meta çağrısı yap (compiler/bytecode bu çağrıyı runtime dispatcher'a iletir). Dispatcher metaId'ye göre ilgili `Case <id>` bloğunu çalıştırır.
- Adım 3: Dönüşte `T+1` sonucu veya runtime `status`'u (GET_STATUS / STATUS_OK gibi) kontrol et.

Örnek (pseudocode):

```
# örnek: ADD (meta 20)
push Arg1 -> T-2
push Arg2 -> T-1
push Arg0 -> T
call meta(20)
# on return: result at T+1
```

**T-register ve adresleme**
- `T` : çağrı anındaki üst yığına (top) işaret eden register.
- `T-1, T-2, ...`: gerideki argüman hücreleri. `T+1` dönüş hücresi.
- Bazı servisler sabit olarak `T-4..T` aralığını kullanır (ör. mat init/ops). Pointer/pmem servisleri hücre adresleri (base/offset) ile çalışır; `PTR_SET/GET` serisi (`80..83`) bunların manipülasyonunu sağlar.

**Önemli servis aileleri (kısa)**
- core: ekran, durum, sabitler (IDs 0..15)
- arithmetic: toplama/çıkarma/çarpma/bölme (20..39)
- math: trig/hipotenüs/square-root vb. (40..59)
- io: yazma/okuma, formatlama (60..69+)
- pointer/memory: pointer set/get/valid (80..89)
- fifo/data/tape: veri okuma/yazma/sıralama (90..109)
- matrix & matrix_adv: mat işlemleri (160..199 ve 180..199 alt gruplar)
- floating point: FP ops (200..224)
- statistics/regression: (260..299)
- ai/normalize/metrics: (340..356 ve 810..823 için ext hook'lar) — raporlarda görüldü
- probability, numeric methods, complex gibi diğer aileler de dosyalarda tanımlı.

(Ayrıntılı ID tablosu için: [UX_MINIMA Kullanım Kılavuzu](../UX_MINIMA_x64_Kullanim_Kilavuzu_TAM.md) veya `reports/meta_service_mapping.csv`.)

**Dallanma ve döngü — servislerin kontrol akışına etkisi**
- Runtime servisleri genelde sonucu `T+1` veya `status` ile bildirir. Kontrol akışı genelde şu şekilde kullanılır:
  - `GET_STATUS` (9) ile `ux_status` okunur.
  - `STATUS_OK` (10) ile durum set edilebilir.
  - `STATUS_ASSERT_NONZERO` (13) gibi servisler koşullu davranış sağlar.
- Flags/compare servisleri (130..149 gibi Case'ler) var ancak dispatcher'ların bazıları farklı aralıklara gönderiyor — yani conditional uygulamalar yazarken dispatcher-remap tablolarını kontrol edin.

**Hook / Wrapper / Extension pattern**
- Extension ID aralıkları `runtime_hook_dispatch_ext.bas` içinde yönlendiriliyor. Tarama çıktısında şu remap blokları gözlendi: `Case 320 To 325`, `Case 340 To 356`, `Case 760 To 769`, `Case 790 To 795` ve `Case 810 To 823`.
- Yeni bir makro/servis eklenecekse iki yol:
  1. Kendi `Case <id>` bloğunu ilgili `uxm/core/runtime/services/*.bas` dosyasına eklemek (ve dispatcher'ı güncellemek).
  2. Hızlı yol: hook wrapper kullanmak — `uxm/core/runtime/hooks/runtime_hook_dispatch_ext.bas` içine Case ekleyip wrapper ile mevcut servisleri çağırmak.
- 794 ve 795 şu anda rezerv/ayrılmış: istek üzerine hook veya wrapper ile uygulanabilir.

**Pragma / build-flags**
- Repo içinde build/asm dosyalarında `ux_pragma_*` isimli global değişkenler gözlendi. Örnekler (derlenen asm içinde):
  - `ux_pragma_seed_enabled`, `ux_pragma_seed_value` — rastgele tohumlama kontrolü
  - `ux_pragma_arge_json`, `ux_pragma_arge_interpreter`, `ux_pragma_arge_step`, `ux_pragma_arge_trace`, `ux_pragma_arge_watch` — runtime/arge (instrumentation) ayarları
- Bu `pragma`-benzeri bayraklar derleme/başlatma aşamasında asm içinde set ediliyor; kullanımları debug/repl/trace fonksiyonları için tasarlanmış gibi görünüyor.

**Yeni makro/servis yazma (önerilen adımlar)**
1. Hedef meta ID'yi seç (manifest ve `reports/meta_service_mapping.csv` ile çakışma kontrolü).
2. Eğer ext aralığıysa wrapper ekle: `uxm/core/runtime/hooks/runtime_hook_dispatch_ext.bas` içinde `Case <id>` blok oluştur.
3. Alternatif: doğrudan `uxm/core/runtime/services/<family>.bas` içinde uygun `Case <id>` bloğunu ekle.
4. `tools/apply_canonical_impls.py` ve `tools/generate_meta_service_mapping.py` ile mapping'i güncelle.
5. Smoke-test: `python tools/search_missing_impls.py` ardından ilgili raporları kontrol et.

**Yararlı komutlar (repoda çalıştırılabilir)**

```bash
python tools/generate_meta_service_mapping.py
python tools/find_case_impl.py
python tools/search_missing_impls.py
python tools/apply_canonical_impls.py
```

## 1. Komutlar, Adresleme Modları ve Pragma Komutları

- **Komutlar (kısa referans):**
  - **Meta çağrı / servis çağrısı:** Servisler meta-ID ile çağrılır; çağrı öncesi argümanlar T-frame'e yerleştirilir ve dispatcher `Case <id>` bloğunu çalıştırır. Dönüş her zaman `T+1` hücresine yazılır.
  - **Durum/denetim servisleri:** `GET_STATUS`, `STATUS_OK`, `STATUS_ASSERT_NONZERO` gibi servisler sık kullanılır (raporlarda gözlenen tipik ID'ler: 9, 10, 13).
  - **Pointer/Memory ops:** Pointer set/get/valid operasyonları tipik olarak bir pointer aralığında bulunur (ör. yaklaşık `80..89`). Kullanım: `T-1=addr, T=value -> call meta(PTR_SET)`.
  - **Aileye göre servisler:** Arithmetic (20..39), IO (60..69), Matrix (160..199) vb. Aile bazlı aralıklar için `reports/meta_service_mapping.csv`'e bakın.
  - **Hook/extension çağrıları:** Eğer ID'ler `runtime_hook_dispatch_ext.bas` tarafından remap ediliyorsa, wrapper kullanarak hook üzerinden çağırmak çoğul ortamda daha güvenlidir (ör. 320..356, 760..795, 810..823 gibi aralıklar).

- **Adresleme Modları:**
  - **T-register (çağrı çerçevesi):** Birincil mod. Argümanlar `T-4..T` aralığına yerleştirilir; dönüş `T+1`. Örnek:

    ```text
    # Hazırla
    T-4 = dst
    T-3 = a
    T-2 = b
    T-1 = p1
    T  = p2
    call meta(201)  # örnek meta-id
    # sonuç -> T+1
    ```

  - **Immediate / Literal:** Sabit değerler doğrudan T hücrelerine yazılır (küçük yardımcı servisler immediate bekleyebilir).
  - **Pointer (base+offset) / İndirekt:** Adresin kendisi bir T hücresinde tutulur; servis içi okuma/yazma indirgenir. Örnek: `PTR_SET` için `T-1=addr, T=value`.
  - **Memory-cell addressing (pmem):** pmem erişimleri adres hücresinin kendisini alır; base/offset kombinasyonu sık kullanılır.
  - **Relative vs Absolute:** Bazı hooklar/dispatcher'lar ID aralıklarını relative mapping ile yeniden yönlendirir — yeni implementasyonlarda mapping tablosunu kontrol edin.

- **Pragma komutları (build/asm içinde global bayraklar):**
  - **ux_pragma_seed_enabled** : dword, varsayılan `0`. RNG deterministikse `1` yapılır.
  - **ux_pragma_seed_value**   : dword, varsayılan `1`. RNG tohum değeri.
  - **ux_pragma_arge_json**     : dword, varsayılan `0`. ARGE çıktısını JSON formatına çevirir.
  - **ux_pragma_arge_interpreter** : dword, varsayılan `0`. ARGE interpreter modunu açar.
  - **ux_pragma_arge_step**     : dword, varsayılan `0`. Adım adım çalışma modu.
  - **ux_pragma_arge_trace**    : dword, varsayılan `0`. Detaylı trace logunu açar.
  - **ux_pragma_arge_watch**    : dword, varsayılan `0`. Watch/observe modu.

  Kullanım (assembly/başlatma sırasında):

  ```asm
  ; örnek init
  mov dword [ux_pragma_seed_enabled], 1
  mov dword [ux_pragma_seed_value], 123456
  mov dword [ux_pragma_arge_trace], 1
  ```

  Not: Bu global bayraklar `build/asm/t0001_*.asm` gibi dosyalarda tanımlı ve runtime başlatılırken set ediliyor. Dinamik olarak değiştirmek için runtime içinde uygun bir `Case`/init-servis yazmak gerekir.

**Hızlı kontrol komutları** (tekrar — kısa):

```bash
python tools/search_missing_impls.py
python tools/apply_canonical_impls.py
```

**İlgili dosyalar (kod referansları)**
- `uxm/core/runtime/runtime_meta_dispatch.bas` — ana dispatcher
- `uxm/core/runtime/hooks/runtime_hook_dispatch_ext.bas` — extension/hook dispatcher
- `uxm/core/runtime/services/*` — servis implementasyon dosyaları (ör. runtime_statistics_services.bas, runtime_real_ext_services_v18.bas, runtime_file_services.bas, vb.)
- `tools/*.py` — tarama ve apply araçları (`generate_meta_service_mapping.py`, `apply_canonical_impls.py` vb.)

---

Bu taslak temel hatlarıyla hazırlandı; isterseniz şimdi ayrıntılı bölüm (ör. tüm core/arithmetic/matrix servisleri için örnek çağrı-snippet'leri) ekleyeyim veya 794/795 için önerilen wrapper kodu örneğini yazayım.
