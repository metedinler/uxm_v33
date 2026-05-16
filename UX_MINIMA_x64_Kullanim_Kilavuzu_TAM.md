# UX-MINIMA x64 Kullanım Kılavuzu — 15 Bölümlük Okuma Haritası

Bu paket, UX-MINIMA x64 yani kısa adıyla **UXM** için 15 bölümlük Türkçe kullanım kılavuzudur. Kılavuzun hedef kitlesi, BASIC veya Python gibi bir dili tanıyan ama henüz büyük bir sistem yazmamış 15–25 yaş arası öğrenciler ve hobi geliştiricilerdir.

UXM’yi öğrenirken kafanda şu resmi kur: Program bir yandan **tape** üzerinde yürüyen küçük komutlardan oluşur, diğer yandan `@N` servis çağrılarıyla matematik, dosya, string, matrix, tensor, istatistik ve benzeri büyük işleri runtime servislerine yaptırır.

## Bölüm sırası

| Bölüm | Dosya | Konu |
|---|---|---|
| 2 | 01_GIRIS_DIL_NEDIR.md | Bölüm 1 — UX-MINIMA x64 Nedir, Ne İşe Yarar? |
| 3 | 02_KURULUM_ARACLAR_KLASOR_AGACI.md | Bölüm 2 — Kurulum, Gerekli Araçlar ve Klasör Ağacı |
| 4 | 03_KAYNAK_DOSYA_VE_SOZDIZIMI.md | Bölüm 3 — UXM Kaynak Dosyası, Direktifler ve Temel Sözdizimi |
| 5 | 04_MIMARI_ARTIFACT_AKIS.md | Bölüm 4 — Sistem Mimarisi, Artifact ve Derleme Akışı |
| 6 | 05_BELLEK_MODELI.md | Bölüm 5 — Tape, Data, Stack, FIFO ve 16 MB Bellek Modeli |
| 7 | 06_ADRESLEME_MODLARI.md | Bölüm 6 — Adresleme Modları ve Küçük Komutların Davranışı |
| 8 | 07_SERVISLER_CEKIRDEK_ARITMETIK_IO.md | Bölüm 7 — Çekirdek, Aritmetik, Matematik ve I/O Servisleri |
| 9 | 08_BILIMSEL_SERVISLER_FP_ISTATISTIK_NUMERIC.md | Bölüm 8 — Floating Point, İstatistik, Olasılık, Sayısal Yöntem ve Bilimsel Servisler |
| 10 | 09_MATRIX_TENSOR_LISTE_SOZLUK_KUME.md | Bölüm 9 — Liste, Sözlük, Küme, Matrix ve Tensor Mantığı |
| 11 | 10_STRING_DOSYA_BIO_ML_SERVISLERI.md | Bölüm 10 — String, Dosya, BIO, ML ve Veri Pipeline Servisleri |
| 12 | 11_CLI_VSCODE_KULLANIM.md | Bölüm 11 — CLI, Terminal ve VSCode ile Kullanım |
| 13 | 12_ASM_OBJ_JSON_DOSYA_YAPILARI.md | Bölüm 12 — ASM, OBJ, JSON, CSV ve Rapor Dosyaları |
| 14 | 13_TEST_FRAMEWORK_STAGE_17_20.md | Bölüm 13 — Test Framework, Stage-17/18/19/20 ve Release Kapısı |
| 15 | 14_SERVIS_KATALOGU.md | Bölüm 14 — Tam Servis Kataloğu |
| 16 | 15_ORNEKLER_OGRENME_YOLU.md | Bölüm 15 — Örneklerle Öğrenme Yolu ve Büyük Program Kurma Mantığı |


## Stage görevleri

| Stage | Görev | Bu kılavuzdaki yeri |
|---|---|---|
| Stage-10 | FP, matrix/tensor temel kapısı, 16 MB memory modeli, eski servis regresyonu | Bölüm 5, 9, 13 |
| Stage-17 | .expect mantığı, expected/actual karşılaştırma, status/flags/data/tape kontrolü | Bölüm 13 |
| Stage-18 | Final/ARGE + Native Bridge: eski ayrı parser/runner hattını native çekirdeğe yaklaştırma | Bölüm 4, 13 |
| Stage-19 | VSCode Integration Cleanup: internal interpreter uyarıları, final compiler build hataları, trace/diagnostic hizalama | Bölüm 11, 13 |
| Stage-20 | Performance + Release Cleanup: exe-only timing runner, build cache, dokümantasyon, servis tablosu otomasyonu | Bölüm 13, 14 |


## İlk önerilen okuma

Önce `01_GIRIS_DIL_NEDIR.md`, `03_KAYNAK_DOSYA_VE_SOZDIZIMI.md`, `05_BELLEK_MODELI.md` ve `06_ADRESLEME_MODLARI.md` dosyalarını oku. Sonra örnekleri çalıştır. Servislerin tamamını görmek için `14_SERVIS_KATALOGU.md` dosyasına bak.


---

# Bölüm 1 — UX-MINIMA x64 Nedir, Ne İşe Yarar?

UX-MINIMA x64, kısa adıyla **UXM**, küçük sembollerle yazılan ama x64 assembly üretmeyi hedefleyen deneysel bir compiler/interpreter dilidir. Başlangıç fikri Brainfuck benzeri küçük bir çekirdektir; fakat UXM yalnızca `+`, `-`, `<`, `>`, `[`, `]` gibi komutlardan ibaret değildir. Üzerine tape, data, private stack, FIFO, pointer kontrolü, hücre tipi, overflow modu, adresleme modları ve `@N` servis çağrıları eklenmiştir.

Bu dilin amacı Python gibi her şeyi hazır keyword olarak vermek değildir. Tam tersine, programcıya bilgisayarın içindeki temel fikirleri öğretmektir: bellek nedir, pointer nedir, hücre tipi nedir, stack ne işe yarar, FIFO neden farklıdır, bir servis çağrısı aslında runtime tarafında neyi tetikler, compiler bir kaynak dosyadan nasıl `.asm`, `.obj`, `.exe` ve rapor dosyaları üretir? UXM bu soruları uygulamalı öğretir.

Bir UXM programcısı kod yazarken şunu düşünür: “Elimde aktif bir tape hücresi var. Bu hücreyi artırabilir, azaltabilir, başka bir adrese taşıyabilir, data alanına yazabilir, stack’e koyabilir, FIFO’ya atabilir, sonra runtime servislerinden birini çağırarak bu değerleri işletebilirim.” Yani UXM’de program yazmak, küçük bellek hareketlerinden büyük işlemler kurmayı öğrenmektir.

UXM’nin güçlü tarafı, küçük çekirdek komutlarının çok sayıda adresleme modu ve servisle birleşmesidir. Örneğin `+` komutu yalnızca aktif hücreyi artırmaz; `+(D:10)` yazarsan data alanındaki 10. hücreyi artırırsın, `+(T+1)` yazarsan pointer’ın sağındaki tape hücresini artırırsın. Aynı mantıkla `@20` bir toplama servisi, `@160` matrix alanı, `@400` dosya servis alanı gibi düşünülebilir.

UXM eğitimde, derleyici tasarımı öğrenmede, düşük seviyeli programlama mantığını kavramada, servis tabanlı runtime mimarisi kurmada ve x64 assembly üretme sürecini anlamada kullanılır. Ayrıca bilimsel hesaplama, istatistik, matrix/tensor, string ve dosya işlemleri gibi alanlar için servis tabanlı genişleme yolu sunar.

## UXM’yi kim öğrenmeli?

BASIC veya Python ile değişken, döngü ve fonksiyon fikrini öğrenmiş biri UXM ile daha alttaki katmana iner. Python’da `liste.append(5)` yazarsın; UXM’de aynı mantığı tape/data/stack/FIFO üzerinde düşünürsün. Python’da `sum(liste)` dendiğinde ne olduğunu görmezsin; UXM’de veri nereye yazıldı, servis hangi hücrelerden argüman aldı, sonuç hangi hücreye geldi sorularını takip edersin.

Bu yüzden UXM, “bilgisayar nasıl düşünüyor?” sorusuna yaklaşmak için iyi bir laboratuvardır. Her şey hazır değil; ama öğrenme değeri de buradan gelir.


---

# Bölüm 2 — Kurulum, Gerekli Araçlar ve Klasör Ağacı

UXM x64 hattı Windows üzerinde geliştirilmiş bir projedir. Güncel kullanımda temel araçlar şunlardır: FreeBASIC compiler, NASM assembler, Python 3, PowerShell veya CMD, Visual Studio Code ve proje içindeki `.bat`/`.py` yardımcı araçları. FreeBASIC compiler runtime ve test runner için kullanılır; NASM x64 assembly dosyalarını object dosyasına çevirmek için gereklidir; Python test koşucu, hızlı tarama, rapor üretimi, workspace toparlama ve VSCode kurulum işlerinde kullanılır.

## Bilgisayarda bulunması gereken araçlar

| Araç | Görev | Kontrol komutu |
|---|---|---|
| Python 3.10+ | Test runner, hızlı tarama, rapor, workspace toplama | `python --version` |
| FreeBASIC 1.10.x x64 | Compiler/runtime FreeBASIC kaynaklarını derleme | `fbc.exe -version` |
| NASM | Üretilen `.asm` dosyasını `.obj` dosyasına çevirme | `nasm -v` |
| PowerShell veya CMD | `.bat` dosyalarını çalıştırma | `powershell` |
| VSCode | UXM dosyalarını syntax highlight/snippet ile düzenleme | `code --version` |


## Temel klasör ağacı

```text
UXMv33/
├─ uxm/
│  ├─ core/
│  │  ├─ compiler/native/        # lexer, parser, adresleme, codegen, CLI
│  │  └─ runtime/                # bellek, status/flags, servis dispatch, runtime servisleri
│  └─ tests/                     # bellek, stage17, stage18, stage19, stage20, all_expected_known
├─ araclar/                      # Türkçe Python araçları
├─ tool_en/                      # İngilizce Python ve bat araçları
├─ ortak/                        # ortak runner çekirdeği
├─ vscode/                       # VSCode dil desteği ve kurulum scriptleri
├─ sonuclar_*                    # test rapor klasörleri
├─ hizli_sonuclar/               # hızlı tarama manifestleri
├─ build/                        # asm/obj/exe ara çıktıları
├─ *.bat                         # Türkçe ana komutlar
└─ README/manifest/diff dosyaları
```

## Türkçe komutlar

| Komut | Görev | Sık kullanım |
|---|---|---|
| derleyici_derle.bat | Native compiler/runtime derleme hattını hazırlar | `derleyici_derle.bat` |
| bellek_test.bat | 16 MB bellek modeli ve tape/data/fifo smoke testleri | `bellek_test.bat` |
| tum_test.bat | Test klasörü veya manifest üzerinden toplu test çalıştırır | `tum_test.bat -k -n 100` |
| hizli_tara.bat | Son test CSV dosyasını tarar ve hatalı tekil manifest üretir | `hizli_tara.bat` |
| hatali_test.bat | Hızlı tarama manifestindeki hatalı testleri tekrar koşar | `hatali_test.bat -k -D` |
| rapor_goster.bat | Son RAPOR.md dosyasını terminalde gösterir | `rapor_goster.bat` |
| alan_topla.bat | Çalışma alanını temizler/toparlar; dry-run ve apply destekler | `alan_topla.bat -u -b` |
| stage17_tamamla.bat | Stage-17 test framework ve expect düzeltme kapısı | `stage17_tamamla.bat -k` |
| stage18_tamamla.bat | Stage-18 native bridge/mega corpus tamamlama kapısı | `stage18_tamamla.bat -k` |
| stage19_tamamla.bat | VSCode/diagnostic cleanup kapısı | `stage19_tamamla.bat -k` |
| stage20_tamamla.bat | Release/performance kalite kapısı | `stage20_tamamla.bat -k` |
| stage20_performans.bat | Exe-only timing, build cache ve release raporu üretimi | `stage20_performans.bat` |
| vscode_kur.bat | VSCode dil desteğini kullanıcı eklenti klasörüne kurar | `vscode_kur.bat` |
| stage_gorevleri.bat | Stage görev özetini gösterir | `stage_gorevleri.bat` |


## İngilizce komutlar

| Command | Purpose | Typical use |
|---|---|---|
| tool_en\memory_test.bat | Run memory model tests | `tool_en\memory_test.bat` |
| tool_en\all_test.bat | Run all/selected tests | `tool_en\all_test.bat -k -n 100` |
| tool_en\fast_scan.bat | Scan latest result CSV for failures | `tool_en\fast_scan.bat` |
| tool_en\failed_test.bat | Re-run failed manifest only | `tool_en\failed_test.bat -k -D` |
| tool_en\workspace_clean.bat | Organize workspace | `tool_en\workspace_clean.bat -u -b` |
| tool_en\stage17_finish.bat | Finish Stage-17 test framework gate | `tool_en\stage17_finish.bat -k` |
| tool_en\stage18_finish.bat | Finish Stage-18 native bridge gate | `tool_en\stage18_finish.bat -k` |
| tool_en\stage19_cleanup.bat | VSCode/diagnostic cleanup | `tool_en\stage19_cleanup.bat` |
| tool_en\stage20_performance.bat | Performance/release report | `tool_en\stage20_performance.bat` |
| tool_en\vscode_install.bat | Install VSCode extension | `tool_en\vscode_install.bat` |


## CLI seçenekleri

| Kısa seçenek | Uzun karşılık | Anlamı |
|---|---|---|
| `-h` | `--help` | Yardım gösterir. |
| `-k` | `--no-build` | Derleyiciyi yeniden derleme; mevcut derleyiciyle test koş. |
| `-D` | `--stop-on-fail` | İlk hata/uyuşmazlıkta dur. |
| `-n 100` | `--limit 100` | Sadece ilk N testi çalıştır. |
| `-s 50` | `--from-index 50` | Belirli sıradan başla. |
| `-a metin` | `--name-contains metin` | Adında metin geçen testleri çalıştır. |
| `-z 20` | `--timeout-test 20` | Tek test zaman aşımı. |
| `-u` | `--apply` | Dry-run değil, gerçek uygulama. |
| `-b` | `--retire-build` | Build çıktılarını emekli/arsiv alanına taşı. |


## İlk kurulum akışı

```powershell
cd C:/Users/mete/Downloads/1/UXMv33
.\derleyici_derle.bat
.ellek_test.bat
.scode_kur.bat
```

`bellek_test.bat` 5/5 geçiyorsa, temel derleme ve runtime hattı çalışıyor demektir. Ardından `tum_test.bat -k -n 100` ile ilk yüz regression testi denenir. `-k` burada “derleyiciyi tekrar derleme, mevcut compiler ile test koş” anlamına gelir.


---

# Bölüm 3 — UXM Kaynak Dosyası, Direktifler ve Temel Sözdizimi

UXM kaynak dosyası genellikle `.uxm` uzantılı düz metin dosyasıdır. Bu dosyanın içinde iki tür bilgi bulunur: derleyiciye ayar veren **direktifler** ve programın gerçekten çalıştıracağı **komutlar**. Direktifler çoğunlukla `#` ile başlar; örneğin `#cell dword`, `#memory data=4mb`, `#overflow wrap`. Komutlar ise küçük semboller ve servis çağrılarıdır; örneğin `+`, `-`, `>`, `<`, `.`, `[ ]`, `@20`.

Bir UXM dosyasını, BASIC’teki gibi satır satır emirler listesi olarak değil, “bellek üzerinde çalışan küçük bir makine tarifi” olarak düşün. Her sembol bir işlem yapar. `+` aktif hücreyi artırır, `-` azaltır, `>` pointer’ı sağa, `<` sola taşır, `.` aktif değeri yazdırır. `@N` ise N numaralı meta servisi çağırır.

## Basit kaynak dosya iskeleti

```uxm
#cell dword
#memory total=16mb,tape=1mb,stack=256kb,data=4mb,fifo=1mb
#mode normal
#bounds on
#overflow wrap

+++++.
```

Bu örnekte hücre tipi `dword` seçilir. Toplam bellek 16 MB olarak düzenlenir. Tape, stack, data ve FIFO alanları ayrı ayrı ayarlanır. Program kısmındaki `+++++.` ise aktif hücreyi 5 yapar ve yazdırır.

## Direktifler

| Direktif | Görev | Örnek |
|---|---|---|
| `#cell` | Hücre tipini seçer: byte, word, dword | `#cell dword` |
| `#memory` | Tape, stack, data, FIFO ve toplam bellek ayarı | `#memory total=16mb,data=4mb` |
| `#mode` | Safe/normal/wild çalışma modu | `#mode normal` |
| `#bounds` | Pointer sınır kontrolü | `#bounds on` |
| `#overflow` | Taşma davranışı: wrap/check | `#overflow wrap` |
| `#compare` | signed/unsigned karşılaştırma | `#compare signed` |
| `#endian` | little/big endian veri düzeni | `#endian little` |
| `#seed` | random servisleri için başlangıç tohumu | `#seed 1234` |
| `#arge` | trace/watch/json gibi ARGE çıktılarını açar | `#arge trace watch` |

## Programcı gözüyle dosya bölümleri

UXM dosyasında önce “makinem nasıl çalışacak?” sorusunun cevabı verilir. Hücre boyu ne? Bellek ne kadar? Pointer sınırı kontrol edilecek mi? Taşma olursa wrap mi yapılacak hata mı verilecek? Sonra “bu makine ne yapacak?” sorusunun cevabı gelen komutlarla yazılır.

Kaynak dosya derlendiğinde compiler bu ayarları okuyup assembly üretir. Assembly, NASM ile object dosyasına çevrilir. FreeBASIC runtime ile linklenir ve executable dosya oluşur. Test runner da `.expect` dosyasıyla program çıktısını karşılaştırır.


---

# Bölüm 4 — Sistem Mimarisi, Artifact ve Derleme Akışı

UXM mimarisi birden fazla katmandan oluşur. En üstte `.uxm` kaynak dosyası vardır. Bu dosya lexer/parser tarafından okunur. Direktifler configuration alanına, komutlar ise iç temsil veya doğrudan assembly emit hattına gider. Meta servisler runtime tarafındaki dispatch fonksiyonlarına bağlanır. Sonuçta `.asm`, `.obj`, `.exe`, `.json`, `.csv` ve `.md` gibi artifact dosyaları üretilebilir.

## Büyük akış grafiği

```text
UXM kaynak dosyası (.uxm)
        |
        v
Lexer / Parser
        |
        +--> Direktifler: #cell, #memory, #mode, #bounds
        |
        +--> Komutlar: + - < > . [ ] @N @(ADDR)
        |
        v
Native compile planı
        |
        +--> Adresleme çözümü
        +--> Meta servis çözümü
        +--> Güvenlik/validasyon
        |
        v
x64 NASM codegen
        |
        v
ASM çıkışı (.asm)
        |
        v
NASM assembler
        |
        v
OBJ çıkışı (.obj)
        |
        v
FreeBASIC runtime link
        |
        v
EXE programı (.exe)
        |
        +--> çalışma çıktısı
        +--> test CSV
        +--> RAPOR.md
        +--> trace/json/diagnostic artifactleri
```

## Artifact ne demek?

Artifact, derleme veya test sürecinde üretilen ara veya son dosyadır. UXM’de en önemli artifactler şunlardır:

| Artifact | Görev |
|---|---|
| `.uxm` | Kaynak program. Programcı bunu yazar. |
| `.asm` | Compiler’ın ürettiği x64 assembly dosyası. |
| `.obj` | NASM tarafından üretilen object dosyası. |
| `.exe` | Link sonrası çalıştırılabilir program. |
| `.expect` | Testte beklenen çıktı. |
| `.csv` | Test sonucu veya servis tablosu. |
| `.json` | Makinece okunabilir rapor/konfigürasyon. |
| `.md` | İnsan için okunabilir rapor/dokümantasyon. |

## Derleme sırasında görülen bilgi satırları

Runner veya compiler çıktısında şu tip alanlar görülür:

```text
Kaynak dosya:        uxm/tests/ornek.uxm
ASM cikis dosyasi:   build/asm/program.asm
Hucre tipi:          dword
Tape boyutu KB:      1024
Private stack KB:    256
Overflow modu:       wrap
Pointer sinir kontrolu: on
```

Bu alanlar programın nasıl derlendiğini anlamak için kullanılır. Özellikle hata ayıklarken hücre tipi ve memory ayarları çok önemlidir. Byte hücreyle 1048576 yazdırmaya çalışırsan değer kırpılır; dword hücreyle aynı değer doğru görünebilir.

## Mimari katmanlar

| Katman | Görev | Girdi | Çıktı |
|---|---|---|---|
| CLI | Komut satırı seçeneklerini okur | `.uxm`, `--out`, `--cell`, `--memory` | compile config |
| Lexer/Parser | Kaynak metni token ve komutlara böler | `.uxm` metni | komut listesi |
| Directive parser | `#memory`, `#cell`, `#mode` okur | direktif satırları | runtime/compile ayarı |
| Addressing resolver | `(T+1)`, `(D:5)`, `(S:0)` çözer | adresleme metni | hedef adres planı |
| Validation | sınır, mod, izin ve syntax kontrolü | komut planı | hata veya geçiş |
| Codegen | x64 NASM üretir | komut planı | `.asm` |
| Assembler | NASM ile obj üretir | `.asm` | `.obj` |
| Runtime linker | runtime servisleriyle bağlar | `.obj`, runtime | `.exe` |
| Runner | exe çalıştırır ve expect ile karşılaştırır | `.exe`, `.expect` | rapor |

## Beklenen dış fonksiyonlar

Runtime servisleri genelde `ux_meta_call_ex`, memory okuma/yazma, status flag fonksiyonları, FIFO/data/tape yardımcıları ve print yordamları gibi dış fonksiyonlar bekler. Codegen tarafı bu runtime sembollerini çağıracak assembly üretir. Bu yüzden runtime ile codegen aynı ABI üzerinde anlaşmalıdır.


---

# Bölüm 5 — Tape, Data, Stack, FIFO ve 16 MB Bellek Modeli

UXM’de bellek tek bir “değişkenler listesi” değildir. Dört temel alan vardır: **tape**, **data**, **private stack** ve **FIFO**. Bunlar birbirine benzer görünür ama düşünme biçimleri farklıdır. Tape aktif pointer ile yürüdüğün çalışma alanıdır. Data daha çok kalıcı tablo/dizi/string alanıdır. Stack son giren ilk çıkar mantığıyla geçici değer saklar. FIFO ise ilk giren ilk çıkar mantığıyla kuyruk oluşturur.

## Bellek alanları

| Alan | Mantık | Ne için kullanılır? |
|---|---|---|
| Tape | Pointer’ın üzerinde gezdiği hücre dizisi | küçük hesaplar, aktif değer, geçici işlem |
| Data | Adresle doğrudan erişilen veri alanı | string, tablo, matrix/tensor veri blokları |
| Stack | LIFO: son giren ilk çıkar | geçici argüman, ara sonuç, çağrı mantığı |
| FIFO | FIFO: ilk giren ilk çıkar | karakter akışı, kuyruk, buffer |

## Memory direktifi

```uxm
#memory total=16mb,tape=1mb,stack=256kb,data=4mb,fifo=1mb
```

Birimsiz değerler eski uyumluluk için KB kabul edilir:

```uxm
#memory data=4096
```

Bu ifade `data=4096kb`, yani yaklaşık 4 MB anlamına gelir. Byte, KB ve MB biçimleri kullanılabilir:

```uxm
#memory tape=2048b
#memory stack=512kb
#memory data=8mb
```

## Hücre tipi

Hücre tipi her hücrenin kaç bitlik değer taşıyacağını belirler. Byte küçük ve hızlıdır ama büyük sayıları tutamaz. Word orta boydur. Dword büyük sayılar ve bilimsel servis çıktıları için daha uygundur.

| Hücre tipi | Yaklaşık aralık | Kullanım |
|---|---|---|
| `byte` | 0..255 | karakter, küçük sayaç, ham byte |
| `word` | 0..65535 | orta büyüklükte sayaç |
| `dword` | 32-bit | büyük sayı, matrix/tensor indeksleri, servis sonuçları |

Örnek:

```uxm
#cell dword
#memory data=4mb
```

Bu ayar, data alanında 4 MB büyüklüğünde dword tabanlı çalışma yapmayı sağlar. Programcı, kaç hücre kullanılacağını byte sayısından hücre boyuna göre düşünmelidir.

## Overflow ve bounds

`#overflow wrap` taşan değeri sarar. Byte hücrede 255’ten sonra 0 gelir. `#overflow check` ise taşmayı hata olarak ele almak için kullanılır. `#bounds on` pointer ve adres sınırlarını kontrol eder; güvenli çalışma için önerilir.

```uxm
#overflow wrap
#bounds on
```

Öğrenci için pratik kural: Öğrenirken `dword`, `#bounds on`, `#overflow wrap` ile başla. Byte hücreye ancak karakter veya düşük seviyeli test yazarken geç.


---

# Bölüm 6 — Adresleme Modları ve Küçük Komutların Davranışı

UXM’nin asıl gücü küçük komutları farklı hedeflere uygulayabilmesidir. Normalde `+` aktif tape hücresini artırır. Fakat adresleme modu eklersen aynı komut başka hücreyi veya başka bellek alanını etkiler.

## Temel adresleme düşüncesi

```uxm
+        ; aktif tape hücresini artır
+(T)     ; aynı şey: aktif tape hücresi
+(T+1)   ; pointer'ın bir sağındaki tape hücresi
+(T-1)   ; pointer'ın bir solundaki tape hücresi
+(T:100) ; tape[100]
+(D:5)   ; data[5]
+(S:0)   ; private stack[0]
```

Adresleme komuttan hemen sonra ve boşluksuz yazılır. `+(D:5)` doğru, `+ (D:5)` yanlış kabul edilmelidir. Çünkü UXM parser’ı komut ile adresleme bloğunu tek bir yapı olarak görür.

## Komut ve adresleme tablosu

| Komut | Adressiz davranış | Adresli örnek | Anlam |
|---|---|---|---|
| `+` | aktif hücreyi artırır | `+(D:10)` | data[10] artır |
| `-` | aktif hücreyi azaltır | `-(T+1)` | sağdaki tape hücresini azalt |
| `.` | aktif hücreyi yazdırır | `.(D:5)` | data[5] yazdır |
| `,` | input alır | `,(D:0)` | input’u data[0] alanına al |
| `>` | pointer sağa | genelde adres almaz | tape pointer ilerlet |
| `<` | pointer sola | genelde adres almaz | tape pointer geri al |
| `[` | aktif hücre sıfır değilken döngü | `[ ... ]` | loop başlangıcı |
| `]` | döngü sonu | `[ ... ]` | loop bitişi |
| `@N` | meta servis çağırır | `@20` | toplama servisi |
| `@(ADDR)` | dinamik meta servis | `@(D:0)` | servis id’sini data[0] gibi yerden al |

## Hücreye sayı ekleme ve çıkarma

```uxm
+++++      ; aktif hücre = 5
---        ; aktif hücre = 2
+(T+1)     ; sağdaki hücreyi 1 artır
-(D:10)    ; data[10] değerini 1 azalt
```

Daha büyük sayılar için servis veya tekrar makroları kullanılabilir. Örneğin 65 yazdırmak için byte karakter mantığında 65 kez `+` yazmak mümkündür ama pratik değildir. Daha gelişmiş programlar data alanını ve servisleri kullanır.

## Pointer ileri geri

```uxm
>      ; pointer bir hücre sağa
<      ; pointer bir hücre sola
>>>>>  ; beş hücre sağa
```

Pointer hareketi tape alanı içindir. Data alanı ise genellikle doğrudan adreslenir: `(D:0)`, `(D:1)`, `(D:100)`.

## Döngü mantığı

```uxm
+++++[.-]
```

Bu örnek aktif hücreyi 5 yapar. Döngü içinde değeri yazdırır ve azaltır. Değer sıfır olunca döngü biter. Döngüler UXM’de algoritma kurmanın temel yoludur.

## Meta servis çağırma

```uxm
@20     ; ADD servisi
@21     ; SUB servisi
@60     ; PRINT ARG2 DECIMAL gibi I/O servisi
```

Servisler genellikle tape üzerinde belirli konumlardan argüman bekler. Registry’de sık görülen ABI ifadesi `T-2=Arg1, T-1=Arg2, T=Arg0, T+1=result` biçimindedir. Bu şu demektir: pointer’ın çevresindeki hücrelere argümanları koy, servisi çağır, sonucu `T+1` hücresinden oku veya yazdır.


---

# Bölüm 7 — Çekirdek, Aritmetik, Matematik ve I/O Servisleri

UXM servisleri `@N` biçiminde çağrılır. Servis numarası runtime dispatch tablosunda bir fonksiyona bağlanır. Bu bölüm çekirdek, aritmetik, temel matematik, I/O, pointer/memory, FIFO/data ve flag servislerini anlatır. Servislerin ayrıntılı tam tablosu Bölüm 14’tedir.

Servis kullanırken üç soruyu sor: “Servis hangi hücrelerden argüman bekliyor?”, “Sonucu nereye koyuyor?”, “Status/flag değiştiriyor mu?” Registry’de `frame` ve `result` alanları bunun içindir.

## Örnek: toplama servisi

```uxm
#cell dword
#memory tape=1mb,data=1mb

; T-2 ve T-1 alanlarına argüman koyduğunu düşün.
; @20 ADD servisi sonucu T+1 alanına yazar.
@20
```

Gerçek programda bu argümanları hazırlamak için tape hareketleri, adresleme veya data servisleri kullanılır.

## Çekirdek ailelerin servis tablosu

| ID | Ad | Aile | Frame | Sonuç | Not |
|---|---|---|---|---|---|
| 0 | NOP_STATUS_OK | core | - | - | Set status OK |
| 1 | CLS | core | - | - | Clear screen |
| 2 | LOCATE_HOME | core | - | - | Locate 1,1 |
| 3 | RANDOM_BYTE | core | - | - | T+1=random byte |
| 4 | TIMER_MS | core | - | - | T+1=timer ms masked |
| 5 | NEWLINE | core | - | - | Print newline |
| 6 | PRINT_META_PREFIX | core | - | - | Print [UXM META] |
| 7 | CONST_7 | core | - | - | T+1=7 |
| 8 | CONST_8 | core | - | - | T+1=8 |
| 9 | GET_STATUS | core | - | - | T+1=ux_status |
| 10 | STATUS_OK | core | - | - | Set status OK |
| 11 | SET_STATUS_ARG1 | core | - | - | status=Arg1 low byte |
| 12 | PRINT_STATUS | core | - | - | Print status message |
| 13 | STATUS_ASSERT_NONZERO | core | - | - | If status OK set 1 else keep |
| 14 | CLEAR_STATUS | core | - | - | Set status OK |
| 15 | GET_ERROR_FLAG | core | - | - | T+1=1 if FLAG_ERR else 0 |
| 20 | ADD | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 21 | SUB | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 22 | MUL | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 23 | DIV | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 24 | MOD | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 25 | MIN | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 26 | MAX | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 27 | ABS_ARG2 | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 28 | NEG_ARG2 | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 29 | CMP | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 30 | RANDOM_INT_RANGE | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 31 | RANDOM_SEED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 32 | RANDOM_SCALED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 33 | DIV_UNSIGNED_ALIAS | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 34 | DIV_SIGNED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 35 | MOD_UNSIGNED_ALIAS | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 36 | MOD_SIGNED | arithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - |
| 40 | SIN_SCALED_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 41 | COS_SCALED_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 42 | TAN_SCALED_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 43 | HYPOTENUSE | math | Arg1/Arg2 depending service | T+1=result | - |
| 44 | ASIN_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 45 | ACOS_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 46 | SQRT | math | Arg1/Arg2 depending service | T+1=result | - |
| 47 | SINH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 48 | COSH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 49 | TANH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 52 | ASINH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 53 | ACOSH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 54 | ATANH_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 55 | LN_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 56 | EXP_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 57 | POWER | math | Arg1/Arg2 depending service | T+1=result | - |
| 58 | DEG_TO_RAD_SCALED | math | Arg1/Arg2 depending service | T+1=result | - |
| 59 | RAD_TO_DEG | math | Arg1/Arg2 depending service | T+1=result | - |
| 60 | PRINT_ARG2_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 61 | PRINT_RESULT_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 62 | PRINT_STACK_POP_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 63 | READ_DECIMAL | io | Arg2/result/stack depending service | printed or T+1 | - |
| 64 | PRINT_SPACE | io | Arg2/result/stack depending service | printed or T+1 | - |
| 67 | PRINT_ARG2_HEX | io | Arg2/result/stack depending service | printed or T+1 | - |
| 68 | PRINT_ARG2_BIN | io | Arg2/result/stack depending service | printed or T+1 | - |
| 69 | PRINT_ARG2_CHAR | io | Arg2/result/stack depending service | printed or T+1 | - |
| 80 | PTR_SET | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 81 | PTR_ADD | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 82 | PTR_GET | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 83 | PTR_VALID | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 84 | LAYOUT_TAPE_CELLS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 85 | LAYOUT_DATA_CELLS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 86 | LAYOUT_STACK_CELLS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 87 | LAYOUT_CELL_BITS | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 88 | LAYOUT_CELL_BYTES | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 89 | LAYOUT_PRINT | pointer_memory | T-1=Arg2 mostly | T+1=result/status | - |
| 90 | FIFO_PUSH | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 91 | FIFO_POP | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 92 | FIFO_PEEK | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 93 | FIFO_COUNT | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 94 | FIFO_CLEAR | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 95 | DATA_READ | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 96 | DATA_WRITE | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 97 | DATA_DIGIT_ASCII_TO_NUMBER | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 98 | DATA_BLOCK_COPY | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 99 | DATA_BLOCK_CLEAR | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 100 | TAPE_SORT_ASC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 101 | TAPE_SORT_DESC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 102 | DATA_SORT_ASC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 103 | DATA_SORT_DESC | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 104 | TAPE_LINEAR_SEARCH | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 105 | DATA_LINEAR_SEARCH | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 106 | TAPE_BLOCK_COPY | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 107 | TAPE_BLOCK_CLEAR | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 120 | SIGNED_MODE_OFF | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 121 | SIGNED_MODE_ON | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 122 | SIGNED_MODE_GET | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 123 | ENDIAN_LITTLE | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 124 | ENDIAN_BIG | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 125 | ENDIAN_GET_BIG | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 126 | FLAGS_GET | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 127 | WILD_LAYOUT_CHANGE | fifo_data_sort_wild | Arg0/Arg1/Arg2 depending service | T+1/status | - |
| 130 | CMP_EQ_UNSIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 131 | CMP_GT_UNSIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 132 | CMP_LT_UNSIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 133 | CMP_EQ_SIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 134 | CMP_GT_SIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 135 | CMP_LT_SIGNED | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 140 | GET_CARRY_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 141 | SET_CARRY_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 142 | CLEAR_CARRY_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 143 | GET_OVERFLOW_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 144 | SET_OVERFLOW_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 145 | CLEAR_OVERFLOW_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 146 | GET_ZERO_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 147 | GET_SIGN_FLAG | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 148 | CLEAR_ZCOS_FLAGS | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 149 | FLAGS_GET_ALIAS | flags_compare | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. |
| 150 | ENDIAN_LITTLE_ALIAS | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 151 | ENDIAN_BIG_ALIAS | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 152 | ENDIAN_GET_BIG_ALIAS | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 153 | WRITE_WORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 154 | READ_WORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 155 | WRITE_DWORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |
| 156 | READ_DWORD_ENDIAN | flags_endian | T-1/relative tape cells depending service | T+1/status | - |


## Programcı mantığı

Aritmetik servisler hesaplama yapar; I/O servisleri yazdırır; flag servisleri önceki işlemin durumunu saklar; pointer ve memory servisleri tape/data alanını düzenler. Büyük programlarda önce veri hazırlanır, sonra servis çağrılır, sonra sonuç başka alana aktarılır. Bu, assembly programlamadaki register hazırlama ve fonksiyon çağırma mantığına benzer.


---

# Bölüm 8 — Floating Point, İstatistik, Olasılık, Sayısal Yöntem ve Bilimsel Servisler

Bilimsel programlama için UXM’de hesaplama servisleri kullanılır. Floating point servisleri ondalıklı sayı davranışını, istatistik servisleri ortalama/medyan/varyans gibi özetleri, regression servisleri model kurmayı, probability servisleri olasılık ve random işlemlerini, numeric servisleri türev/integral gibi sayısal yöntemleri taşır.

UXM’de bilimsel servislerin amacı `SIN`, `MEAN`, `REGRESSION` gibi kelimeleri doğrudan dil çekirdeğine eklemek değildir. Bunun yerine küçük çekirdek korunur, büyük iş runtime servislerine verilir. Bu sayede compiler sade kalır, runtime genişler.

## Bilimsel servis aileleri

| ID | Ad | Aile | Frame | Sonuç | Not |
|---|---|---|---|---|---|
| 160 | MAT_INIT | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 161 | MAT_CLEAR | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 162 | MAT_SET | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 163 | MAT_GET | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 164 | MAT_FILL | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 165 | MAT_COPY | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 166 | MAT_PRINT | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 167 | MAT_ADD | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 168 | MAT_SUB | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 169 | MAT_SCALAR_MUL | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 170 | MAT_MUL | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 171 | MAT_TRANSPOSE_COPY | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 172 | MAT_IDENTITY | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 173 | MAT_TRACE | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 174 | MAT_SHAPE | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 175 | MAT_DET2 | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 176 | MAT_PRINT_RAW | matrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - |
| 180 | MAT_ND_INIT | matrix_adv | T-4 rows, T-3 cols, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 181 | MAT_ND_GET | matrix_adv | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 182 | MAT_ND_SET | matrix_adv | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 183 | MAT_DET | matrix_adv | T-4 A, T+1 determinant | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 184 | MAT_INVERSE | matrix_adv | T-4 A, T-2 OUT | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 185 | MAT_LU | matrix_adv | T-4 A, T-2 L, T-3 U | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 186 | MAT_QR | matrix_adv | T-4 A, T-2 Q, T-3 R | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 187 | MAT_RANK | matrix_adv | T-4 A, T+1 rank | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 188 | MAT_COND_EST | matrix_adv | T-4 A, T-2 temp inverse, T+1 cond | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 189 | MAT_EIG_POWER | matrix_adv | T-4 A, T-2 vector out, T-1 iterations, T+1 lambda | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 190 | MAT_EIG_JACOBI_SYM | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 191 | MAT_SVD_SYM_HELPER | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 192 | MAT_SPARSE_CSR_INIT | matrix_adv | T-4 rows, T-3 cols, T-1 nnz, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 193 | MAT_SPARSE_CSR_MV | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 194 | MAT_SPARSE_TO_DENSE | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 195 | MAT_DENSE_TO_SPARSE | matrix_adv | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 196 | MAT_TRACE | matrix_adv | T-4 A, T+1 trace | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 197 | MAT_FROBENIUS | matrix_adv | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 198 | MAT_NORM_INF | matrix_adv | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 199 | MAT_ADV_INFO | matrix_adv | prints info | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. |
| 200 | FP_INIT16 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 201 | FP_INIT32 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 202 | FP_ZERO | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 203 | FP_COPY | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 204 | FP_NORMALIZE_STORE | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 205 | FP_TO_INT | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 206 | FP_IS_ZERO | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 207 | FP_SIGN | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 208 | FP_ABS_TO_INT | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 209 | FP_PRINT_RAW | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 210 | FP_ADD | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 211 | FP_SUB | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 212 | FP_MUL | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 213 | FP_DIV | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 214 | FP_COMPARE | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 215 | FP_ABS | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 216 | FP_NEG | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 217 | FP_ROUND16 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 218 | FP_ROUND32 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 219 | FP_TRUNC | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 220 | FP_FROM_INT | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 221 | FP_FROM_DEC_STRING | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 222 | FP_TO_DEC_STRING | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 223 | FP_PRINT_DECIMAL | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 224 | FP_SCALE10 | floating_point | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - |
| 230 | FP_RESERVED_230 | floating_point | - | - | Reserved/invalid in current source. |
| 231 | FP_RESERVED_231 | floating_point | - | - | Reserved/invalid in current source. |
| 232 | FP_RESERVED_232 | floating_point | - | - | Reserved/invalid in current source. |
| 233 | FP_RESERVED_233 | floating_point | - | - | Reserved/invalid in current source. |
| 234 | FP_RESERVED_234 | floating_point | - | - | Reserved/invalid in current source. |
| 240 | POLY_DERIVATIVE | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 241 | POLY_INTEGRAL | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 242 | POLY_EVAL | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 243 | POLY_PRINT | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 244 | POLY_CLEAR | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 250 | EXPR_RPN_EVAL | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 251 | NUM_DERIV | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 252 | INTEGRAL_TRAPEZOID | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 253 | INTEGRAL_SIMPSON | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 254 | EXPR_RPN_PRINT | math_extra | T-frame/data object depending service | T+1/result/status | - |
| 260 | STAT_COUNT | statistics | - | T+1/status | count values |
| 261 | STAT_SUM | statistics | - | T+1/status | sum values |
| 262 | STAT_MEAN | statistics | - | T+1/status | mean |
| 263 | STAT_MIN | statistics | - | T+1/status | min |
| 264 | STAT_MAX | statistics | - | T+1/status | max |
| 265 | STAT_RANGE | statistics | - | T+1/status | max-min |
| 266 | STAT_VARIANCE | statistics | - | T+1/status | sample variance |
| 267 | STAT_STDDEV | statistics | - | T+1/status | sample stddev |
| 268 | STAT_MEDIAN | statistics | - | T+1/status | median |
| 269 | STAT_MODE | statistics | - | T+1/status | mode first |
| 270 | STAT_QUARTILE | statistics | - | T+1/status | quartile placeholder |
| 271 | STAT_PERCENTILE | statistics | - | T+1/status | percentile placeholder |
| 272 | STAT_SKEWNESS | statistics | - | T+1/status | skewness placeholder |
| 273 | STAT_KURTOSIS | statistics | - | T+1/status | kurtosis placeholder |
| 274 | STAT_COVARIANCE | statistics | - | T+1/status | covariance |
| 275 | STAT_ZSCORE | statistics | - | T+1/status | z score |
| 280 | CORR_PEARSON | correlation | - | T+1/status | pearson r scaled |
| 281 | CORR_SPEARMAN | correlation | - | T+1/status | spearman placeholder |
| 282 | CORR_KENDALL | correlation | - | T+1/status | kendall placeholder |
| 290 | REG_LINEAR | regression | - | T+1/status | simple linear regression |
| 291 | REG_MULTIPLE | regression | - | T+1/status | reserved |
| 292 | REG_POLYNOMIAL | regression | - | T+1/status | reserved |
| 293 | REG_LOGISTIC | regression | - | T+1/status | reserved |
| 298 | REG_PREDICT | regression | - | T+1/status | predict y |
| 299 | REG_R2 | regression | - | T+1/status | r squared |
| 300 | TTEST_ONE | hypothesis | - | T+1/status | one sample t placeholder |
| 301 | TTEST_INDEPENDENT | hypothesis | - | T+1/status | independent t placeholder |
| 302 | TTEST_PAIRED | hypothesis | - | T+1/status | paired t placeholder |
| 303 | ZTEST_ONE | hypothesis | - | T+1/status | one sample z placeholder |
| 304 | ZTEST_TWO | hypothesis | - | T+1/status | two sample z placeholder |
| 305 | FTEST_VARIANCE | hypothesis | - | T+1/status | f variance placeholder |
| 306 | ANOVA_ONEWAY | hypothesis | - | T+1/status | oneway anova placeholder |
| 307 | ANOVA_TWOWAY | hypothesis | - | T+1/status | reserved |
| 308 | CHI_SQUARE | hypothesis | - | T+1/status | chi square placeholder |
| 309 | CHI_GOODNESS | hypothesis | - | T+1/status | goodness placeholder |
| 320 | POSTHOC_TUKEY | posthoc | - | T+1/status | tukey placeholder |
| 321 | POSTHOC_DUNCAN | posthoc | - | T+1/status | duncan placeholder |
| 322 | POSTHOC_DUNNETT | posthoc | - | T+1/status | dunnett placeholder |
| 323 | POSTHOC_BONFERRONI | posthoc | - | T+1/status | bonferroni placeholder |
| 324 | POSTHOC_SCHEFFE | posthoc | - | T+1/status | scheffe placeholder |
| 325 | POSTHOC_LSD | posthoc | - | T+1/status | lsd placeholder |
| 340 | AI_NORMALIZE_MINMAX | ai | - | T+1/status | minmax normalize |
| 341 | AI_NORMALIZE_ZSCORE | ai | - | T+1/status | zscore normalize |
| 342 | AI_ONEHOT | ai | - | T+1/status | reserved |
| 343 | AI_TRAIN_TEST_SPLIT | ai | - | T+1/status | reserved |
| 344 | AI_SHUFFLE | ai | - | T+1/status | reserved |
| 345 | AI_CONFUSION_MATRIX | ai | - | T+1/status | confusion matrix placeholder |
| 346 | AI_ACCURACY | ai | - | T+1/status | accuracy |
| 347 | AI_PRECISION | ai | - | T+1/status | precision |
| 348 | AI_RECALL | ai | - | T+1/status | recall |
| 349 | AI_F1 | ai | - | T+1/status | f1 score |
| 350 | AI_DISTANCE_EUCLIDEAN | ai | - | T+1/status | euclidean distance |
| 351 | AI_DISTANCE_COSINE | ai | - | T+1/status | cosine distance placeholder |
| 352 | AI_KNN_BASIC | ai | - | T+1/status | reserved |
| 353 | AI_LINEAR_LAYER | ai | - | T+1/status | reserved |
| 354 | AI_SIGMOID | ai | - | T+1/status | sigmoid scaled |
| 355 | AI_RELU | ai | - | T+1/status | relu |
| 356 | AI_SOFTMAX | ai | - | T+1/status | reserved |
| 360 | RAND_SEED | probability | - | T+1/status | - |
| 361 | RAND_UNIFORM_01 | probability | - | T+1/status | - |
| 362 | RAND_INT_RANGE | probability | - | T+1/status | - |
| 363 | RAND_NORMAL | probability | - | T+1/status | - |
| 364 | RAND_POISSON | probability | - | T+1/status | - |
| 365 | RAND_BINOMIAL | probability | - | T+1/status | - |
| 366 | RAND_WEIGHTED | probability | - | T+1/status | - |
| 367 | RAND_SECURE_BYTE | probability | - | T+1/status | - |
| 368 | RAND_BERNOULLI | probability | - | T+1/status | - |
| 369 | RAND_SHUFFLE_DATA | probability | - | T+1/status | - |
| 390 | NUM_NEWTON_RAPHSON | numeric | - | T+1/status | - |
| 391 | NUM_BISECTION | numeric | - | T+1/status | - |
| 392 | NUM_SECANT | numeric | - | T+1/status | - |
| 393 | NUM_INTEGRAL_TRAPEZOID | numeric | - | T+1/status | - |
| 394 | NUM_INTEGRAL_SIMPSON | numeric | - | T+1/status | - |
| 395 | NUM_INTERPOLATE_LINEAR | numeric | - | T+1/status | - |
| 396 | NUM_BEZIER_QUADRATIC | numeric | - | T+1/status | - |
| 397 | NUM_RUNGE_KUTTA4_LINEAR | numeric | - | T+1/status | - |
| 398 | NUM_ODE_INFO | numeric | - | T+1/status | - |
| 399 | NUM_PDE_RESERVED | numeric | - | T+1/status | - |
| 400 | NUM_SPLINE_RESERVED | numeric | - | T+1/status | - |
| 401 | NUM_ADAPTIVE_INTEGRAL_RESERVED | numeric | - | T+1/status | - |
| 440 | CPLX_INIT | complex | - | T+1/status | - |
| 441 | CPLX_ADD | complex | - | T+1/status | - |
| 442 | CPLX_SUB | complex | - | T+1/status | - |
| 443 | CPLX_MUL | complex | - | T+1/status | - |
| 444 | CPLX_DIV | complex | - | T+1/status | - |
| 445 | CPLX_CONJ | complex | - | T+1/status | - |
| 446 | CPLX_ABS | complex | - | T+1/status | - |
| 447 | CPLX_ARG | complex | - | T+1/status | - |
| 448 | CPLX_EXP | complex | - | T+1/status | - |
| 449 | CPLX_FROM_POLAR | complex | - | T+1/status | - |
| 450 | CPLX_PRINT_RESERVED | complex | - | T+1/status | - |


## Örnek düşünme: bilimsel hesap

Diyelim ki bir deneyde 5 ölçümün ortalamasını bulacaksın. BASIC’te `FOR` döngüsüyle toplar, bölersin. UXM’de ölçümleri data alanına koyarsın, ilgili istatistik servisine başlangıç adresi ve uzunluk verirsin, sonucu tape veya data alanından alırsın.

Pseudo-code:

```text
DATA[0..4] = ölçümler
T-2 = başlangıç adresi
T-1 = eleman sayısı
@MEAN servis çağrısı
sonuç = T+1
```

Bu yapı, UXM’de yüksek seviyeli bilimsel işlemlerin bile bellek ve servis ABI üzerinden düşünülmesini sağlar.


---

# Bölüm 9 — Liste, Sözlük, Küme, Matrix ve Tensor Mantığı

UXM’de Python’daki gibi doğrudan `list`, `dict`, `set` keywordleriyle başlayan yüksek seviyeli veri yapıları yerine, veri yapıları çoğunlukla data alanında düzenlenen bloklar ve servis çağrılarıyla kurulur. Liste ardışık data hücreleri olarak düşünülebilir. Sözlük anahtar-değer çiftlerinin iki paralel blokta veya kayıt yapısında tutulmasıdır. Küme, tekrar etmeyen değerler listesi gibi uygulanabilir. Matrix iki boyutlu, tensor ise çok boyutlu data bloklarının düzenlenmiş halidir.

## Liste mantığı

```text
DATA[base + 0] = eleman 0
DATA[base + 1] = eleman 1
DATA[base + 2] = eleman 2
```

Liste üzerinde toplama, arama, sıralama gibi işler servislerle yapılır. Küçük örneklerde pointer ile tek tek gezmek de mümkündür.

## Sözlük mantığı

```text
KEYS[baseK + i]   = anahtar
VALUES[baseV + i] = değer
```

Bir anahtar arandığında önce key listesinde aranır, bulunan indeks value listesinde kullanılır. UXM’de bu doğrudan keyword değil, programlama tekniği olarak öğretilmelidir.

## Matrix mantığı

Matrix iki boyutlu dizidir. 2x3 matrix, data alanında düz blok olarak tutulabilir:

```text
index = row * column_count + col
DATA[base + index]
```

Örnek 2x2 matrix:

```text
[1 2]
[3 4]
```

Düz data:

```text
DATA[base+0]=1
DATA[base+1]=2
DATA[base+2]=3
DATA[base+3]=4
```

## Tensor mantığı

Tensor çok boyutlu dizidir. 3D için:

```text
index = z*(Y*X) + y*X + x
```

4D için:

```text
index = w*(Z*Y*X) + z*(Y*X) + y*X + x
```

UXM’de Stage-18 tensor4d köprüsünde yapılan düzeltmenin özü de budur: servis çağrısından önce dims ve index bilgisi data alanına doğru yazılmalıdır. Servis veri bulamazsa sıfır döndürmesi normaldir.

## Öğrenci için pratik öneri

Önce 1D listeyi data alanında kur. Sonra 2D matrix indeks formülünü öğren. Ardından 3D/4D tensor için aynı formülü genişlet. UXM’de büyük veri yapısı düşünmek, “verinin düz bellekte nereye düştüğünü” anlamaktır.


---

# Bölüm 10 — String, Dosya, BIO, ML ve Veri Pipeline Servisleri

UXM’de string verisi çoğunlukla data alanında tutulur. String, sıfır byte ile biten karakter dizisi olarak düşünülebilir. Bu BASIC’teki `STRING` veya Python’daki `str` kadar rahat değildir; ama bellekte metnin nasıl durduğunu öğretir. Dosya servisleri de aynı mantıkla çalışır: aç, oku/yaz, kapat; fakat servis ABI ile argüman hazırlanır.

## String servis tasarım tablosu

| Servis | Ad | Görev |
|---|---|---|
| @300 | STR_LEN_Z | 0 byte görene kadar string uzunluğu bulur (tasarım notu: registry çakışması kontrol edilmeli). |
| @301 | STR_COPY | Data alanında string kopyalar. |
| @302 | STR_CLEAR | Data string/bölge temizler. |
| @303 | STR_FILL | Data alanını karakterle doldurur. |
| @304 | STR_COMPARE | İki string karşılaştırır. |
| @305 | STR_EQUALS | String eşitlik kontrolü yapar. |
| @306 | STR_FIND_CHAR | Karakter arar. |
| @307 | STR_COUNT_CHAR | Karakter sayar. |
| @340 | STR_FIND_TEXT | Substring arar. |
| @341 | STR_COUNT_TEXT | Substring sayar. |
| @342 | STR_REPLACE_CHAR | Karakter değiştirir. |
| @343 | STR_REPLACE_TEXT | Metin parçası değiştirir. |
| @344 | STR_SPLIT_NEXT | Metni parçalara ayırma adımı. |


Not: Eski UX-STR belgelerinde `@300..@379` string servis bandı olarak tasarlanmıştır. Birleşik registry tablosunda aynı bandın bazı bölümlerinde istatistik/hypothesis servisleri görünebilir. Kod yazarken her zaman proje içindeki güncel `service_registry_merged.csv` ve runtime dispatch dosyası esas alınmalıdır. Bu çakışma dokümantasyonda ayrıca işaretlenmiştir; saklanmamalıdır.

## Dosya servisleri

| ID | Ad | Aile | Frame | Sonuç | Not |
|---|---|---|---|---|---|
| 400 | FILE_OPEN_READ_TEXT | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 401 | FILE_OPEN_WRITE_TEXT | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 402 | FILE_OPEN_APPEND_TEXT | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 403 | FILE_OPEN_BINARY_READ | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 404 | FILE_OPEN_BINARY_WRITE | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 405 | FILE_CLOSE | file_io | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 406 | FILE_READ_BYTE | file_io | T-1=handle | T+1=byte | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 407 | FILE_WRITE_BYTE | file_io | T-2=handle, T-1=byte | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 408 | FILE_READ_LINE | file_io | T-3=handle, T-2=dst_data_start, T-1=max_len | T+1=len | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 409 | FILE_WRITE_LINE | file_io | T-3=handle, T-2=src_data_start, T-1=len | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 410 | FILE_READ_BLOCK | file_io | T-4=handle, T-3=space, T-2=dst_start, T-1=max_count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 411 | FILE_WRITE_BLOCK | file_io | T-4=handle, T-3=space, T-2=src_start, T-1=count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 412 | FILE_SEEK | file_io | T-2=handle, T-1=position_zero_based | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 413 | FILE_TELL | file_io | T-1=handle | T+1=position | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 414 | FILE_SIZE | file_io | T-1=handle | T+1=size | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 415 | FILE_EXISTS | file_io | T-2=name_start, T-1=name_len | T+1=0/1 | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 416 | FILE_DELETE_RESERVED | file_io | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 417 | FILE_RENAME_RESERVED | file_io | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 418 | FILE_MKDIR_RESERVED | file_io | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 419 | FILE_STATUS | file_io | none | T+1=last_file_status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 420 | FILE_FLUSH | file_io | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |
| 421 | FILE_OPEN_BINARY_APPEND | file_io | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. |


## Dosya işlemi pseudo-code

```text
T-2 = dosya adı adresi
T-1 = mod bilgisi
@FILE_OPEN
T+1 = handle

T-2 = handle
T-1 = buffer adresi
T   = uzunluk
@FILE_READ_BLOCK

T-2 = handle
@FILE_CLOSE
```

## BIO/ML veri pipeline mantığı

BIO, ML ve veri pipeline servisleri yüksek seviyeli bilimsel uygulamalar için düşünülür. Bunlar genelde data alanında tutulan dizileri alır, hesap yapar ve sonucu tape veya data alanına yazar. Örneğin biyoloji örneğinde bir ölçüm serisi data alanına yüklenir; istatistik veya ML servisleriyle sınıflandırılır; sonuç rapor edilir.


---

# Bölüm 11 — CLI, Terminal ve VSCode ile Kullanım

UXM terminal üzerinden çalıştırılan bir compiler/test sistemidir. Günlük kullanımda doğrudan compiler exe’si yerine `.bat` komutları kullanmak daha kolaydır. Bu `.bat` dosyaları Python araçlarını ve build scriptlerini doğru parametrelerle çağırır.

## Türkçe ve İngilizce araç dizinleri

Türkçe araçlar `araclar/` altında, İngilizce karşılıkları `tool_en/` altında tutulur. Bu ayrım önemlidir: Türkçe ana kullanımda terminal çıktıları, seçenek açıklamaları ve raporlar Türkçe olmalıdır; İngilizce dosyalar ise dış kullanıcı veya GitHub/VSCode paylaşımı için hazır tutulur.

| Komut | Görev | Sık kullanım |
|---|---|---|
| derleyici_derle.bat | Native compiler/runtime derleme hattını hazırlar | `derleyici_derle.bat` |
| bellek_test.bat | 16 MB bellek modeli ve tape/data/fifo smoke testleri | `bellek_test.bat` |
| tum_test.bat | Test klasörü veya manifest üzerinden toplu test çalıştırır | `tum_test.bat -k -n 100` |
| hizli_tara.bat | Son test CSV dosyasını tarar ve hatalı tekil manifest üretir | `hizli_tara.bat` |
| hatali_test.bat | Hızlı tarama manifestindeki hatalı testleri tekrar koşar | `hatali_test.bat -k -D` |
| rapor_goster.bat | Son RAPOR.md dosyasını terminalde gösterir | `rapor_goster.bat` |
| alan_topla.bat | Çalışma alanını temizler/toparlar; dry-run ve apply destekler | `alan_topla.bat -u -b` |
| stage17_tamamla.bat | Stage-17 test framework ve expect düzeltme kapısı | `stage17_tamamla.bat -k` |
| stage18_tamamla.bat | Stage-18 native bridge/mega corpus tamamlama kapısı | `stage18_tamamla.bat -k` |
| stage19_tamamla.bat | VSCode/diagnostic cleanup kapısı | `stage19_tamamla.bat -k` |
| stage20_tamamla.bat | Release/performance kalite kapısı | `stage20_tamamla.bat -k` |
| stage20_performans.bat | Exe-only timing, build cache ve release raporu üretimi | `stage20_performans.bat` |
| vscode_kur.bat | VSCode dil desteğini kullanıcı eklenti klasörüne kurar | `vscode_kur.bat` |
| stage_gorevleri.bat | Stage görev özetini gösterir | `stage_gorevleri.bat` |


| Command | Purpose | Typical use |
|---|---|---|
| tool_en\memory_test.bat | Run memory model tests | `tool_en\memory_test.bat` |
| tool_en\all_test.bat | Run all/selected tests | `tool_en\all_test.bat -k -n 100` |
| tool_en\fast_scan.bat | Scan latest result CSV for failures | `tool_en\fast_scan.bat` |
| tool_en\failed_test.bat | Re-run failed manifest only | `tool_en\failed_test.bat -k -D` |
| tool_en\workspace_clean.bat | Organize workspace | `tool_en\workspace_clean.bat -u -b` |
| tool_en\stage17_finish.bat | Finish Stage-17 test framework gate | `tool_en\stage17_finish.bat -k` |
| tool_en\stage18_finish.bat | Finish Stage-18 native bridge gate | `tool_en\stage18_finish.bat -k` |
| tool_en\stage19_cleanup.bat | VSCode/diagnostic cleanup | `tool_en\stage19_cleanup.bat` |
| tool_en\stage20_performance.bat | Performance/release report | `tool_en\stage20_performance.bat` |
| tool_en\vscode_install.bat | Install VSCode extension | `tool_en\vscode_install.bat` |


## VSCode kurulumu

```powershell
cd C:/Users/mete/Downloads/1/UXMv33
.scode_kur.bat
```

Kurulumdan sonra VSCode açıksa pencereyi yeniden yükle:

```text
Ctrl+Shift+P -> Developer: Reload Window
```

VSCode eklentisi `.uxm` dosyalarını tanır, temel syntax renklendirme ve snippet desteği verir. Snippet örnekleri `#memory`, `#cell`, `@N` servis çağrısı ve bellek test iskeletleri içerebilir.

## Terminalden compiler çalıştırma

Genel akış:

```powershell
.\derleyici_derle.bat
.ellek_test.bat
.	um_test.bat -k -n 100
.\hizli_tara.bat
.\hatali_test.bat -k -D
```

Eğer ilk 100 test temizse daha geniş test koşulur:

```powershell
.	um_test.bat -k
```

## Seçenekler

| Kısa seçenek | Uzun karşılık | Anlamı |
|---|---|---|
| `-h` | `--help` | Yardım gösterir. |
| `-k` | `--no-build` | Derleyiciyi yeniden derleme; mevcut derleyiciyle test koş. |
| `-D` | `--stop-on-fail` | İlk hata/uyuşmazlıkta dur. |
| `-n 100` | `--limit 100` | Sadece ilk N testi çalıştır. |
| `-s 50` | `--from-index 50` | Belirli sıradan başla. |
| `-a metin` | `--name-contains metin` | Adında metin geçen testleri çalıştır. |
| `-z 20` | `--timeout-test 20` | Tek test zaman aşımı. |
| `-u` | `--apply` | Dry-run değil, gerçek uygulama. |
| `-b` | `--retire-build` | Build çıktılarını emekli/arsiv alanına taşı. |


## Yeni başlayan için güvenli çalışma disiplini

Bir defada tüm sistemi koşturma. Önce `bellek_test.bat`, sonra 20–100 arası sınırlı test, sonra hızlı tarama, sonra sadece hatalı testler. Bu yöntem hem zamanı azaltır hem de gerçek hata ile test framework hatasını ayırmayı kolaylaştırır.


---

# Bölüm 12 — ASM, OBJ, JSON, CSV ve Rapor Dosyaları

UXM compiler yalnızca `.exe` üretmez; derleme ve test sürecinde çok sayıda ara dosya üretir. Bu dosyaları anlamak, compiler geliştiren biri için çok önemlidir.

## ASM dosyası

`.asm` dosyası NASM syntax’ına yakın x64 assembly metnidir. Codegen katmanı UXM komutlarını buraya çevirir. Örnek olarak `+` komutu aktif tape hücresini artıran bir instruction dizisine dönüşür; `@N` servis çağrısı runtime’daki meta dispatch fonksiyonuna çağrı üretir.

ASM dosyasında şunlar bulunabilir:

```text
section .data
section .bss
section .text
global main
call ux_meta_call_ex
```

## OBJ dosyası

`.obj`, NASM’in assembly dosyasından ürettiği object dosyasıdır. İnsan tarafından okunmaz; linker tarafından kullanılır. FreeBASIC runtime ve UXM runtime sembolleriyle bağlanınca `.exe` oluşur.

## JSON dosyası

JSON dosyaları test/diagnostic/trace gibi yapılandırılmış raporlar için kullanılır. Örneğin bir test koşusunun toplam kaç test koştuğu, kaçının geçtiği, hangi manifestin kullanıldığı JSON olarak saklanabilir. Bu, otomasyon için daha kullanışlıdır.

## CSV dosyası

CSV dosyaları servis tablosu ve test sonuçları için kullanılır. Test CSV’sinde genellikle şu alanlar olur:

```text
test_path,status,mode,expected,actual,seconds,exit_code
```

Hızlı tarama aracı bu CSV’yi okuyup yalnız hatalı testleri seçer. Böylece 1000 testi tekrar koşmak yerine 37 veya 83 tekil hatalı test tekrar çalıştırılır.

## RAPOR.md

`RAPOR.md` insan için okunur. Terminalde `rapor_goster.bat` ile gösterilir. Bu raporda toplam test, başarılı test, uyuşmazlık, build fail ve skipped sayısı bulunur.

## Artifact üretme akışı

```text
.uxm -> .asm -> .obj -> .exe -> stdout -> .csv -> RAPOR.md / JSON
```

Bu zincirde hata nerede çıktıysa çözüm de ona göre yapılır. `.asm` oluşmuyorsa compiler/codegen; `.obj` oluşmuyorsa NASM; `.exe` oluşmuyorsa link; çıktı yanlışsa runtime/servis/test beklenen değeri incelenir.


---

# Bölüm 13 — Test Framework, Stage-17/18/19/20 ve Release Kapısı

UXM projesinde test framework artık dilin kendisi kadar önemlidir. Çünkü compiler doğru olsa bile `.expect` okuyucu hatalıysa gerçek ve beklenen aynı olduğu halde test `UYUSMAZ` görünebilir. Stage-17’nin ana görevi bu yüzden expected/actual karşılaştırma mantığını sağlamlaştırmaktır.

## Stage görevleri

| Stage | Görev | Bu kılavuzdaki yeri |
|---|---|---|
| Stage-10 | FP, matrix/tensor temel kapısı, 16 MB memory modeli, eski servis regresyonu | Bölüm 5, 9, 13 |
| Stage-17 | .expect mantığı, expected/actual karşılaştırma, status/flags/data/tape kontrolü | Bölüm 13 |
| Stage-18 | Final/ARGE + Native Bridge: eski ayrı parser/runner hattını native çekirdeğe yaklaştırma | Bölüm 4, 13 |
| Stage-19 | VSCode Integration Cleanup: internal interpreter uyarıları, final compiler build hataları, trace/diagnostic hizalama | Bölüm 11, 13 |
| Stage-20 | Performance + Release Cleanup: exe-only timing runner, build cache, dokümantasyon, servis tablosu otomasyonu | Bölüm 13, 14 |


## .expect formatları

`.expect` dosyasında beklenen çıktı tutulur. Mode satırları olabilir:

```text
# mode: compact
46.0000000000000000
```

Bazı eski dosyalarda `#source:embedded_EXPECT_OUTPUT` ön eki beklenen çıktıya yapışmış olabilir. Runner bu metaveriyi çıktı saymamalıdır. Stage-17 düzeltmesinin özü budur.

## Test modları

| Mod | Anlam |
|---|---|
| exact | Çıktı birebir aynı olmalı. |
| compact | Boşluk/satır farklarını temizleyip karşılaştır. |
| contains | Gerçek çıktı beklenen parçayı içeriyorsa başarılı. |
| contains_compact | Compact temizlenmiş içerme kontrolü. |

## Stage-18 native bridge

Stage-18, eski parser/runner hattı ile native çekirdek arasındaki farkları azaltır. Özellikle mega corpus, domain örnekleri ve tensor4d gibi köprü testleri burada önemlidir. Bir servis doğru çalışıyor gibi görünse bile gerekli dims/index bilgisi data alanına yazılmadan çağrılırsa sonuç `0` dönebilir; bu compiler hatası değil test hazırlama hatasıdır.

## Stage-19 VSCode cleanup

Stage-19, VSCode eklentisinin eski internal interpreter uyarılarını, final compiler build hatalarını, trace ve diagnostic hizalamasını temizler. Amaç editörün kullanıcıyı yanlış yönlendirmemesidir.

## Stage-20 performance/release cleanup

Stage-20, exe-only timing runner, build cache, dokümantasyon üretimi ve servis tablosu otomasyonunu kapsar. Release öncesi “bu paket çalışıyor mu?” sorusuna cevap verir.

## Çalıştırma örneği

```powershell
.\stage17_tamamla.bat -k
.\stage18_tamamla.bat -k
.\stage19_tamamla.bat -k
.\stage20_tamamla.bat -k
.\stage20_performans.bat
```


---

# Bölüm 14 — Tam Servis Kataloğu

Bu bölüm, eldeki `service_registry_merged.csv` dosyasından üretilmiş servis kataloğudur. Kod yazarken servis numarası, aile, handler, frame ve result alanlarına bakılmalıdır. `frame` alanı servisin hangi tape konumlarından argüman beklediğini, `result` alanı sonucu nereye koyduğunu anlatır.

Toplam kayıt: **308**

## Aile özeti

| Aile | Servis sayısı | ID aralığı |
|---|---|---|
| core | 16 | 0..15 |
| arithmetic | 17 | 20..36 |
| math | 18 | 40..59 |
| io | 8 | 60..69 |
| pointer_memory | 10 | 80..89 |
| fifo_data_sort_wild | 26 | 90..127 |
| flags_compare | 16 | 130..149 |
| flags_endian | 7 | 150..156 |
| matrix | 17 | 160..176 |
| matrix_adv | 20 | 180..199 |
| floating_point | 30 | 200..234 |
| math_extra | 10 | 240..254 |
| statistics | 16 | 260..275 |
| correlation | 3 | 280..282 |
| regression | 6 | 290..299 |
| hypothesis | 10 | 300..309 |
| posthoc | 6 | 320..325 |
| ai | 17 | 340..356 |
| probability | 10 | 360..369 |
| numeric | 12 | 390..401 |
| file_io | 22 | 400..421 |
| complex | 11 | 440..450 |



## core
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 0 | NOP_STATUS_OK | MetaCore | - | - | Set status OK | runtime_meta_dispatch.bas |
| 1 | CLS | MetaCore | - | - | Clear screen | runtime_meta_dispatch.bas |
| 2 | LOCATE_HOME | MetaCore | - | - | Locate 1,1 | runtime_meta_dispatch.bas |
| 3 | RANDOM_BYTE | MetaCore | - | - | T+1=random byte | runtime_meta_dispatch.bas |
| 4 | TIMER_MS | MetaCore | - | - | T+1=timer ms masked | runtime_meta_dispatch.bas |
| 5 | NEWLINE | MetaCore | - | - | Print newline | runtime_meta_dispatch.bas |
| 6 | PRINT_META_PREFIX | MetaCore | - | - | Print [UXM META] | runtime_meta_dispatch.bas |
| 7 | CONST_7 | MetaCore | - | - | T+1=7 | runtime_meta_dispatch.bas |
| 8 | CONST_8 | MetaCore | - | - | T+1=8 | runtime_meta_dispatch.bas |
| 9 | GET_STATUS | MetaCore | - | - | T+1=ux_status | runtime_meta_dispatch.bas |
| 10 | STATUS_OK | MetaCore | - | - | Set status OK | runtime_meta_dispatch.bas |
| 11 | SET_STATUS_ARG1 | MetaCore | - | - | status=Arg1 low byte | runtime_meta_dispatch.bas |
| 12 | PRINT_STATUS | MetaCore | - | - | Print status message | runtime_meta_dispatch.bas |
| 13 | STATUS_ASSERT_NONZERO | MetaCore | - | - | If status OK set 1 else keep | runtime_meta_dispatch.bas |
| 14 | CLEAR_STATUS | MetaCore | - | - | Set status OK | runtime_meta_dispatch.bas |
| 15 | GET_ERROR_FLAG | MetaCore | - | - | T+1=1 if FLAG_ERR else 0 | runtime_meta_dispatch.bas |

## arithmetic
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 20 | ADD | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 21 | SUB | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 22 | MUL | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 23 | DIV | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 24 | MOD | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 25 | MIN | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 26 | MAX | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 27 | ABS_ARG2 | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 28 | NEG_ARG2 | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 29 | CMP | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 30 | RANDOM_INT_RANGE | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 31 | RANDOM_SEED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 32 | RANDOM_SCALED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 33 | DIV_UNSIGNED_ALIAS | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 34 | DIV_SIGNED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 35 | MOD_UNSIGNED_ALIAS | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |
| 36 | MOD_SIGNED | MetaArithmetic | T-2=Arg1, T-1=Arg2, T=Arg0 | T+1=result | - | runtime_meta_dispatch.bas |

## math
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 40 | SIN_SCALED_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 41 | COS_SCALED_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 42 | TAN_SCALED_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 43 | HYPOTENUSE | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 44 | ASIN_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 45 | ACOS_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 46 | SQRT | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 47 | SINH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 48 | COSH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 49 | TANH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 52 | ASINH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 53 | ACOSH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 54 | ATANH_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 55 | LN_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 56 | EXP_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 57 | POWER | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 58 | DEG_TO_RAD_SCALED | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |
| 59 | RAD_TO_DEG | MetaMath | Arg1/Arg2 depending service | T+1=result | - | runtime_meta_dispatch.bas |

## io
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 60 | PRINT_ARG2_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 61 | PRINT_RESULT_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 62 | PRINT_STACK_POP_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 63 | READ_DECIMAL | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 64 | PRINT_SPACE | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 67 | PRINT_ARG2_HEX | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 68 | PRINT_ARG2_BIN | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |
| 69 | PRINT_ARG2_CHAR | MetaIO | Arg2/result/stack depending service | printed or T+1 | - | runtime_meta_dispatch.bas |

## pointer_memory
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 80 | PTR_SET | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 81 | PTR_ADD | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 82 | PTR_GET | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 83 | PTR_VALID | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 84 | LAYOUT_TAPE_CELLS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 85 | LAYOUT_DATA_CELLS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 86 | LAYOUT_STACK_CELLS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 87 | LAYOUT_CELL_BITS | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 88 | LAYOUT_CELL_BYTES | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |
| 89 | LAYOUT_PRINT | MetaPointerMemory | T-1=Arg2 mostly | T+1=result/status | - | runtime_meta_dispatch.bas |

## fifo_data_sort_wild
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 90 | FIFO_PUSH | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 91 | FIFO_POP | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 92 | FIFO_PEEK | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 93 | FIFO_COUNT | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 94 | FIFO_CLEAR | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 95 | DATA_READ | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 96 | DATA_WRITE | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 97 | DATA_DIGIT_ASCII_TO_NUMBER | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 98 | DATA_BLOCK_COPY | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 99 | DATA_BLOCK_CLEAR | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 100 | TAPE_SORT_ASC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 101 | TAPE_SORT_DESC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 102 | DATA_SORT_ASC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 103 | DATA_SORT_DESC | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 104 | TAPE_LINEAR_SEARCH | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 105 | DATA_LINEAR_SEARCH | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 106 | TAPE_BLOCK_COPY | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 107 | TAPE_BLOCK_CLEAR | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 120 | SIGNED_MODE_OFF | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 121 | SIGNED_MODE_ON | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 122 | SIGNED_MODE_GET | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 123 | ENDIAN_LITTLE | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 124 | ENDIAN_BIG | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 125 | ENDIAN_GET_BIG | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 126 | FLAGS_GET | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 127 | WILD_LAYOUT_CHANGE | MetaFifoDataSortWild | Arg0/Arg1/Arg2 depending service | T+1/status | - | runtime_meta_dispatch.bas |

## flags_compare
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 130 | CMP_EQ_UNSIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 131 | CMP_GT_UNSIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 132 | CMP_LT_UNSIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 133 | CMP_EQ_SIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 134 | CMP_GT_SIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 135 | CMP_LT_SIGNED | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 140 | GET_CARRY_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 141 | SET_CARRY_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 142 | CLEAR_CARRY_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 143 | GET_OVERFLOW_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 144 | SET_OVERFLOW_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 145 | CLEAR_OVERFLOW_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 146 | GET_ZERO_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 147 | GET_SIGN_FLAG | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 148 | CLEAR_ZCOS_FLAGS | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |
| 149 | FLAGS_GET_ALIAS | MetaFlagsEndian | - | T+1/status | Case exists in MetaFlagsEndian but dispatcher only sends 150..159 there; @130..149 currently invalid unless dispatch is fixed. | runtime_meta_dispatch.bas |

## flags_endian
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 150 | ENDIAN_LITTLE_ALIAS | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 151 | ENDIAN_BIG_ALIAS | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 152 | ENDIAN_GET_BIG_ALIAS | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 153 | WRITE_WORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 154 | READ_WORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 155 | WRITE_DWORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |
| 156 | READ_DWORD_ENDIAN | MetaFlagsEndian | T-1/relative tape cells depending service | T+1/status | - | runtime_meta_dispatch.bas |

## matrix
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 160 | MAT_INIT | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 161 | MAT_CLEAR | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 162 | MAT_SET | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 163 | MAT_GET | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 164 | MAT_FILL | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 165 | MAT_COPY | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 166 | MAT_PRINT | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 167 | MAT_ADD | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 168 | MAT_SUB | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 169 | MAT_SCALAR_MUL | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 170 | MAT_MUL | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 171 | MAT_TRANSPOSE_COPY | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 172 | MAT_IDENTITY | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 173 | MAT_TRACE | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 174 | MAT_SHAPE | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 175 | MAT_DET2 | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |
| 176 | MAT_PRINT_RAW | MetaMatrix | T-4=dst, T-3=a, T-2=b, T-1=p1, T=p2 | T+1=result/status | - | runtime_matrix_services.bas |

## matrix_adv
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 180 | MAT_ND_INIT | UXMMatAdvancedDispatch | T-4 rows, T-3 cols, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 181 | MAT_ND_GET | UXMMatAdvancedDispatch | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 182 | MAT_ND_SET | UXMMatAdvancedDispatch | reserved | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 183 | MAT_DET | UXMMatAdvancedDispatch | T-4 A, T+1 determinant | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 184 | MAT_INVERSE | UXMMatAdvancedDispatch | T-4 A, T-2 OUT | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 185 | MAT_LU | UXMMatAdvancedDispatch | T-4 A, T-2 L, T-3 U | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 186 | MAT_QR | UXMMatAdvancedDispatch | T-4 A, T-2 Q, T-3 R | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 187 | MAT_RANK | UXMMatAdvancedDispatch | T-4 A, T+1 rank | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 188 | MAT_COND_EST | UXMMatAdvancedDispatch | T-4 A, T-2 temp inverse, T+1 cond | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 189 | MAT_EIG_POWER | UXMMatAdvancedDispatch | T-4 A, T-2 vector out, T-1 iterations, T+1 lambda | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 190 | MAT_EIG_JACOBI_SYM | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 191 | MAT_SVD_SYM_HELPER | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 192 | MAT_SPARSE_CSR_INIT | UXMMatAdvancedDispatch | T-4 rows, T-3 cols, T-1 nnz, T-2 outbase | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 193 | MAT_SPARSE_CSR_MV | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 194 | MAT_SPARSE_TO_DENSE | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 195 | MAT_DENSE_TO_SPARSE | UXMMatAdvancedDispatch | planned | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 196 | MAT_TRACE | UXMMatAdvancedDispatch | T-4 A, T+1 trace | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 197 | MAT_FROBENIUS | UXMMatAdvancedDispatch | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 198 | MAT_NORM_INF | UXMMatAdvancedDispatch | T-4 A, T+1 norm | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |
| 199 | MAT_ADV_INFO | UXMMatAdvancedDispatch | prints info | T+1/status | Within matrix dispatcher range; add cases to MetaMatrix or subdispatch. | service_registry_matrix_v34.csv |

## floating_point
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 200 | FP_INIT16 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 201 | FP_INIT32 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 202 | FP_ZERO | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 203 | FP_COPY | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 204 | FP_NORMALIZE_STORE | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 205 | FP_TO_INT | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 206 | FP_IS_ZERO | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 207 | FP_SIGN | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 208 | FP_ABS_TO_INT | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 209 | FP_PRINT_RAW | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 210 | FP_ADD | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 211 | FP_SUB | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 212 | FP_MUL | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 213 | FP_DIV | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 214 | FP_COMPARE | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 215 | FP_ABS | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 216 | FP_NEG | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 217 | FP_ROUND16 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 218 | FP_ROUND32 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 219 | FP_TRUNC | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 220 | FP_FROM_INT | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 221 | FP_FROM_DEC_STRING | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 222 | FP_TO_DEC_STRING | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 223 | FP_PRINT_DECIMAL | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 224 | FP_SCALE10 | MetaFloatingPoint | T-2=rBase, T-1=aBase, T=bBase pattern | T+1/status | - | runtime_fp_services.bas |
| 230 | FP_RESERVED_230 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 231 | FP_RESERVED_231 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 232 | FP_RESERVED_232 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 233 | FP_RESERVED_233 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |
| 234 | FP_RESERVED_234 | MetaFloatingPoint | - | - | Reserved/invalid in current source. | runtime_fp_services.bas |

## math_extra
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 240 | POLY_DERIVATIVE | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 241 | POLY_INTEGRAL | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 242 | POLY_EVAL | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 243 | POLY_PRINT | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 244 | POLY_CLEAR | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 250 | EXPR_RPN_EVAL | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 251 | NUM_DERIV | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 252 | INTEGRAL_TRAPEZOID | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 253 | INTEGRAL_SIMPSON | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |
| 254 | EXPR_RPN_PRINT | MetaMathExtra | T-frame/data object depending service | T+1/result/status | - | runtime_math_services.bas |

## statistics
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 260 | STAT_COUNT | MetaStatistics | - | T+1/status | count values | service_registry_v33.csv |
| 261 | STAT_SUM | MetaStatistics | - | T+1/status | sum values | service_registry_v33.csv |
| 262 | STAT_MEAN | MetaStatistics | - | T+1/status | mean | service_registry_v33.csv |
| 263 | STAT_MIN | MetaStatistics | - | T+1/status | min | service_registry_v33.csv |
| 264 | STAT_MAX | MetaStatistics | - | T+1/status | max | service_registry_v33.csv |
| 265 | STAT_RANGE | MetaStatistics | - | T+1/status | max-min | service_registry_v33.csv |
| 266 | STAT_VARIANCE | MetaStatistics | - | T+1/status | sample variance | service_registry_v33.csv |
| 267 | STAT_STDDEV | MetaStatistics | - | T+1/status | sample stddev | service_registry_v33.csv |
| 268 | STAT_MEDIAN | MetaStatistics | - | T+1/status | median | service_registry_v33.csv |
| 269 | STAT_MODE | MetaStatistics | - | T+1/status | mode first | service_registry_v33.csv |
| 270 | STAT_QUARTILE | MetaStatistics | - | T+1/status | quartile placeholder | service_registry_v33.csv |
| 271 | STAT_PERCENTILE | MetaStatistics | - | T+1/status | percentile placeholder | service_registry_v33.csv |
| 272 | STAT_SKEWNESS | MetaStatistics | - | T+1/status | skewness placeholder | service_registry_v33.csv |
| 273 | STAT_KURTOSIS | MetaStatistics | - | T+1/status | kurtosis placeholder | service_registry_v33.csv |
| 274 | STAT_COVARIANCE | MetaStatistics | - | T+1/status | covariance | service_registry_v33.csv |
| 275 | STAT_ZSCORE | MetaStatistics | - | T+1/status | z score | service_registry_v33.csv |

## correlation
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 280 | CORR_PEARSON | MetaStatistics | - | T+1/status | pearson r scaled | service_registry_v33.csv |
| 281 | CORR_SPEARMAN | MetaStatistics | - | T+1/status | spearman placeholder | service_registry_v33.csv |
| 282 | CORR_KENDALL | MetaStatistics | - | T+1/status | kendall placeholder | service_registry_v33.csv |

## regression
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 290 | REG_LINEAR | MetaRegression | - | T+1/status | simple linear regression | service_registry_v33.csv |
| 291 | REG_MULTIPLE | MetaRegression | - | T+1/status | reserved | service_registry_v33.csv |
| 292 | REG_POLYNOMIAL | MetaRegression | - | T+1/status | reserved | service_registry_v33.csv |
| 293 | REG_LOGISTIC | MetaRegression | - | T+1/status | reserved | service_registry_v33.csv |
| 298 | REG_PREDICT | MetaRegression | - | T+1/status | predict y | service_registry_v33.csv |
| 299 | REG_R2 | MetaRegression | - | T+1/status | r squared | service_registry_v33.csv |

## hypothesis
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 300 | TTEST_ONE | MetaHypothesis | - | T+1/status | one sample t placeholder | service_registry_v33.csv |
| 301 | TTEST_INDEPENDENT | MetaHypothesis | - | T+1/status | independent t placeholder | service_registry_v33.csv |
| 302 | TTEST_PAIRED | MetaHypothesis | - | T+1/status | paired t placeholder | service_registry_v33.csv |
| 303 | ZTEST_ONE | MetaHypothesis | - | T+1/status | one sample z placeholder | service_registry_v33.csv |
| 304 | ZTEST_TWO | MetaHypothesis | - | T+1/status | two sample z placeholder | service_registry_v33.csv |
| 305 | FTEST_VARIANCE | MetaHypothesis | - | T+1/status | f variance placeholder | service_registry_v33.csv |
| 306 | ANOVA_ONEWAY | MetaHypothesis | - | T+1/status | oneway anova placeholder | service_registry_v33.csv |
| 307 | ANOVA_TWOWAY | MetaHypothesis | - | T+1/status | reserved | service_registry_v33.csv |
| 308 | CHI_SQUARE | MetaHypothesis | - | T+1/status | chi square placeholder | service_registry_v33.csv |
| 309 | CHI_GOODNESS | MetaHypothesis | - | T+1/status | goodness placeholder | service_registry_v33.csv |

## posthoc
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 320 | POSTHOC_TUKEY | MetaPosthoc | - | T+1/status | tukey placeholder | service_registry_v33.csv |
| 321 | POSTHOC_DUNCAN | MetaPosthoc | - | T+1/status | duncan placeholder | service_registry_v33.csv |
| 322 | POSTHOC_DUNNETT | MetaPosthoc | - | T+1/status | dunnett placeholder | service_registry_v33.csv |
| 323 | POSTHOC_BONFERRONI | MetaPosthoc | - | T+1/status | bonferroni placeholder | service_registry_v33.csv |
| 324 | POSTHOC_SCHEFFE | MetaPosthoc | - | T+1/status | scheffe placeholder | service_registry_v33.csv |
| 325 | POSTHOC_LSD | MetaPosthoc | - | T+1/status | lsd placeholder | service_registry_v33.csv |

## ai
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 340 | AI_NORMALIZE_MINMAX | MetaAI | - | T+1/status | minmax normalize | service_registry_v33.csv |
| 341 | AI_NORMALIZE_ZSCORE | MetaAI | - | T+1/status | zscore normalize | service_registry_v33.csv |
| 342 | AI_ONEHOT | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 343 | AI_TRAIN_TEST_SPLIT | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 344 | AI_SHUFFLE | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 345 | AI_CONFUSION_MATRIX | MetaAI | - | T+1/status | confusion matrix placeholder | service_registry_v33.csv |
| 346 | AI_ACCURACY | MetaAI | - | T+1/status | accuracy | service_registry_v33.csv |
| 347 | AI_PRECISION | MetaAI | - | T+1/status | precision | service_registry_v33.csv |
| 348 | AI_RECALL | MetaAI | - | T+1/status | recall | service_registry_v33.csv |
| 349 | AI_F1 | MetaAI | - | T+1/status | f1 score | service_registry_v33.csv |
| 350 | AI_DISTANCE_EUCLIDEAN | MetaAI | - | T+1/status | euclidean distance | service_registry_v33.csv |
| 351 | AI_DISTANCE_COSINE | MetaAI | - | T+1/status | cosine distance placeholder | service_registry_v33.csv |
| 352 | AI_KNN_BASIC | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 353 | AI_LINEAR_LAYER | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |
| 354 | AI_SIGMOID | MetaAI | - | T+1/status | sigmoid scaled | service_registry_v33.csv |
| 355 | AI_RELU | MetaAI | - | T+1/status | relu | service_registry_v33.csv |
| 356 | AI_SOFTMAX | MetaAI | - | T+1/status | reserved | service_registry_v33.csv |

## probability
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 360 | RAND_SEED | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 361 | RAND_UNIFORM_01 | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 362 | RAND_INT_RANGE | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 363 | RAND_NORMAL | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 364 | RAND_POISSON | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 365 | RAND_BINOMIAL | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 366 | RAND_WEIGHTED | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 367 | RAND_SECURE_BYTE | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 368 | RAND_BERNOULLI | MetaProbability | - | T+1/status | - | service_registry_v35.csv |
| 369 | RAND_SHUFFLE_DATA | MetaProbability | - | T+1/status | - | service_registry_v35.csv |

## numeric
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 390 | NUM_NEWTON_RAPHSON | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 391 | NUM_BISECTION | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 392 | NUM_SECANT | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 393 | NUM_INTEGRAL_TRAPEZOID | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 394 | NUM_INTEGRAL_SIMPSON | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 395 | NUM_INTERPOLATE_LINEAR | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 396 | NUM_BEZIER_QUADRATIC | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 397 | NUM_RUNGE_KUTTA4_LINEAR | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 398 | NUM_ODE_INFO | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 399 | NUM_PDE_RESERVED | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 400 | NUM_SPLINE_RESERVED | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |
| 401 | NUM_ADAPTIVE_INTEGRAL_RESERVED | MetaNumericMethods | - | T+1/status | - | service_registry_v35.csv |

## file_io
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 400 | FILE_OPEN_READ_TEXT | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 401 | FILE_OPEN_WRITE_TEXT | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 402 | FILE_OPEN_APPEND_TEXT | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 403 | FILE_OPEN_BINARY_READ | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 404 | FILE_OPEN_BINARY_WRITE | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 405 | FILE_CLOSE | MetaFileServices | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 406 | FILE_READ_BYTE | MetaFileServices | T-1=handle | T+1=byte | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 407 | FILE_WRITE_BYTE | MetaFileServices | T-2=handle, T-1=byte | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 408 | FILE_READ_LINE | MetaFileServices | T-3=handle, T-2=dst_data_start, T-1=max_len | T+1=len | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 409 | FILE_WRITE_LINE | MetaFileServices | T-3=handle, T-2=src_data_start, T-1=len | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 410 | FILE_READ_BLOCK | MetaFileServices | T-4=handle, T-3=space, T-2=dst_start, T-1=max_count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 411 | FILE_WRITE_BLOCK | MetaFileServices | T-4=handle, T-3=space, T-2=src_start, T-1=count | T+1=count | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 412 | FILE_SEEK | MetaFileServices | T-2=handle, T-1=position_zero_based | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 413 | FILE_TELL | MetaFileServices | T-1=handle | T+1=position | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 414 | FILE_SIZE | MetaFileServices | T-1=handle | T+1=size | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 415 | FILE_EXISTS | MetaFileServices | T-2=name_start, T-1=name_len | T+1=0/1 | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 416 | FILE_DELETE_RESERVED | MetaFileServices | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 417 | FILE_RENAME_RESERVED | MetaFileServices | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 418 | FILE_MKDIR_RESERVED | MetaFileServices | - | reserved | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 419 | FILE_STATUS | MetaFileServices | none | T+1=last_file_status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 420 | FILE_FLUSH | MetaFileServices | T-1=handle | status | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |
| 421 | FILE_OPEN_BINARY_APPEND | MetaFileServices | T-3=name_start, T-2=name_len, T-1=reserved | T+1=handle | Full UXM_FILE_V1 file service set. Smaller v32 file patch also uses @400..@406 with different frame; use this full version as canonical. | UXM_FILE_IO_SERVICES.md |

## complex
| ID | Ad | Handler | Frame | Sonuç | Not | Kaynak |
|---|---|---|---|---|---|---|
| 440 | CPLX_INIT | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 441 | CPLX_ADD | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 442 | CPLX_SUB | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 443 | CPLX_MUL | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 444 | CPLX_DIV | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 445 | CPLX_CONJ | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 446 | CPLX_ABS | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 447 | CPLX_ARG | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 448 | CPLX_EXP | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 449 | CPLX_FROM_POLAR | MetaComplex | - | T+1/status | - | service_registry_v35.csv |
| 450 | CPLX_PRINT_RESERVED | MetaComplex | - | T+1/status | - | service_registry_v35.csv |


---

# Bölüm 15 — Örneklerle Öğrenme Yolu ve Büyük Program Kurma Mantığı

UXM öğrenmenin doğru yolu küçük programlardan başlayıp servisleri birleştirmektir. Önce tape üzerinde sayı artırmayı öğren. Sonra data alanına geç. Sonra stack ve FIFO kullan. Daha sonra servis çağır. En sonunda bilimsel veya muhasebe benzeri küçük görevler kur.

## Örnek 1: aktif hücreyi artır ve yazdır

```uxm
#cell byte
+++++.
```

Bu program aktif hücreyi 5 yapar ve yazdırır. Byte hücre kullandığı için küçük sayılarla çalışır.

## Örnek 2: dword ile büyük sayı düşünmek

```uxm
#cell dword
#memory tape=1mb,data=4mb
```

Bu ayar, büyük sayılar ve bilimsel hesaplar için daha güvenlidir. Dword seçmek, byte kırpılmalarını önler.

## Örnek 3: data alanını tablo gibi düşünmek

```text
DATA[0] = öğrenci notu 1
DATA[1] = öğrenci notu 2
DATA[2] = öğrenci notu 3
```

Daha sonra istatistik servisiyle ortalama alınabilir. UXM’de gerçek kod servis ABI’ye göre yazılır; pseudo-code mantığı şöyledir:

```text
T-2 = data başlangıcı
T-1 = eleman sayısı
@MEAN
sonuç = T+1
```

## Örnek 4: muhasebe KDV hesabı

Bir ürünün fiyatı 100, KDV oranı 20 ise sonuç 120’dir. UXM’de bu iş için data alanına fiyat ve oran yazılır; çarpma/bölme/toplama servisleriyle sonuç elde edilir. Büyük programda bu adımlar fonksiyon gibi küçük bloklara ayrılır.

```text
fiyat = 100
kdv = fiyat * 20 / 100
toplam = fiyat + kdv
```

UXM düşüncesi:

```text
DATA[0]=100
DATA[1]=20
@MUL
@DIV
@ADD
PRINT sonuç
```

## Örnek 5: fen/kimya mol kütlesi

CH4O için C=12, H=1, O=16 alınırsa:

```text
12 + 4*1 + 16 = 32
```

Bu tür hesaplar UXM’de data alanına sabitler konarak ve arithmetic servisleriyle yapılabilir. Programcı her ara sonucu nereye koyduğunu bilmelidir.

## Örnek 6: biyoloji ölçüm serisi

Bir Chlorella deneyinde 5 OD ölçümü alındığını düşün:

```text
0.21, 0.24, 0.29, 0.31, 0.35
```

UXM’de floating point servisleri string veya scaled integer biçimiyle kullanılabilir. Başlangıçta scaled integer önerilir:

```text
21, 24, 29, 31, 35   ; 100 ile çarpılmış değerler
```

Sonra ortalama servisi veya manuel toplam/bölme kullanılır.

## Örnek 7: matrix ile küçük sistem

2x2 matrix:

```text
[1 2]
[3 4]
```

Data düz dizisi:

```text
1, 2, 3, 4
```

Index hesabı:

```text
index = row * 2 + col
```

Matrix servisleri bu düzen üzerinden çalışır. Determinant, inverse, rank gibi gelişmiş işlemler runtime servislerine bırakılır.

## Büyük program yazarken düşünme sırası

1. Verilerin hangi alanda duracağını seç: tape mi data mı?
2. Hücre tipini seç: byte mı dword mü?
3. Bellek boyutunu ayarla.
4. Girdi verisini data alanına yerleştir.
5. Servislerin beklediği argüman hücrelerini hazırla.
6. Servisi çağır.
7. Sonucu oku/yazdır/kaydet.
8. Test için `.expect` dosyası yaz.
9. `tum_test`, `hizli_tara`, `hatali_test` döngüsüyle doğrula.

## Profesyonel kaliteye geçiş

Başlangıçta her şeyi tek UXM dosyasında yazabilirsin. Daha sonra veri hazırlama, servis çağırma ve raporlama kısımlarını ayrı bloklar olarak düşün. Kullandığın her servis için küçük test yaz. Büyük programı küçük testlerin toplamı haline getir. Compiler geliştirme projelerinde güvenilirlik böyle sağlanır.


---

