# UXM Nedir?
UXM, BrainFuck temelinde olusturulmus bir compiler sistemidir. Freebasic ile yazilmistir. Mimari tasarimi ilgi cekicidir. Bir compiler tasarimi ile ugrasan yeni programcinin kendi kendine calismasinda oldukca yol gostericidir.
# UXM Ne yapar?
Uxm aslinda bilgisayarin donanim mimarisini veya bir islemciyi temel alir. Yani bir islemcide assembler kod yazmak istediginde nasil kod yazarsin onu ogrenirsin.
Evet sonucta assembler ogrenirsin ama madem cok zor bir dil (uxm) ogreniyorsun ozaman sonrasinda neden assebler ogrenesin ki? yuksek seviyeli bir dilin sana getirdigi kolayliklari bilgisayarin hafiza modeli icinde nasil yapacagini calistiracagini ogrenirsin.
Gunun birinde bir model kurmak istersen bunu hafizada nasil yerlestiririm diye dusundugunde UXM sana hizli prototiplemede yardimci olur. Aslinda Dilin komutlari zor degil, Dusunme bicemini degistirmen dunyaya bakis acini degistirmen zor. Anlaman icin gereken teknik yardimi bir cok yapay zeka kullanici klavuzu ile ve testler ile sagladim.


# Temel Kullanım, Kurulum, Derleme, Mimari ve UXM'nin Zihniyeti
## 1. UXM Nedir?

UXM, görünüşte Brainfuck benzeri çok küçük komutlardan oluşan bir dildir. Fakat paket içindeki gerçek kod yapısı incelendiğinde UXM'nin artık basit bir Brainfuck türevi olmaktan çıktığı görülür. UXM daha doğru ifadeyle, küçük komut çekirdeği üzerine kurulmuş, servis tabanlı, deterministic yani öngörülebilir çalışma düzeni olan bir virtual machine / compiler dilidir.

UXM'yi anlamanın en kolay yolu şudur:

Python veya BASIC'te değişken isimleriyle çalışırsın. UXM'de ise bellek hücreleriyle çalışırsın. Python'da `x = x + 1` dersin. UXM'de aktif hücredeki değeri `+` komutuyla artırırsın. Python'da liste veya array kullanırsın. UXM'de tape, data segment, stack ve queue gibi bellek alanlarını kullanırsın. Python'da hazır fonksiyon çağırırsın. UXM'de `@N` şeklinde runtime service çağırırsın.

Yani UXM'de program yazmak, yüksek seviyeli bir dilde cümle yazmaya değil, küçük bir makineyi programlamaya benzer. Ama bu makine artık yalnızca `+ - < >` seviyesinde değildir. İçinde string, dosya, istatistik, matrix, tensor, numerik yöntem, olasılık, biyoinformatik ve ML/data pipeline servisleri vardır.

Bu nedenle UXM'nin en doğru kısa tanımı şudur:

**UXM, minimal komut seti + geniş runtime servisleri + kontrollü bellek modeli üzerine kurulu deneysel bir compiler/runtime dilidir.**
Önce belleği planlayan, sonra küçük komutlarla ve runtime servisleriyle o belleği işleyen programlama tarzı.
Profesyonel UXM programcısı, hazır servis varsa onu kullanır. Elle loop yalnızca servis yoksa veya özel davranış gerekiyorsa yazılır.
Gerekiyorsa Uxm icin makro tanimlayarak veya alt progrmlarini makrlar halinde yazarak genisletebilir. Uxm, genelde brainfuck turevlerinin yapmadigi dosya erisimine sahiptir.istersen dosya uzerinde canli islemler yapabilirsin
Bu yaptigin isler x64 bit assembler koduna cevrilir ve derlenir, yani yapmak istedigini zor yoldan ve en hizli sekilde yaparsin. usteluk vscode uzerinde canli izleyebilir testleri calistirabilir, copilota dili kisa surede ogretebilir ve calismalarini yapmani saglayabilirsin. ilk bakista hemen ounamamasi ekranina kem gozle bakan is arkadasin yada dusmanininda bu dili ogrenmesi demektir ki, sen ondan bayagi ondesin, yani okumak zordur. bu nedenle dokumantasyonunu, programlama defterini ve kalemini daima bilgisayar yaninda tut.

---

## 2. UXM'nin Kökeni ve Başka Dillerden Farkı

UXM'nin kökeninde Brainfuck benzeri tape mantığı vardır. Brainfuck'ta bir bellek şeridi vardır. Pointer sağa sola gider, hücre artırılır, azaltılır, okunur, yazılır. UXM bu kökü korur ama onu birkaç yönden büyütür.

Brainfuck yalnızca aktif hücreyle çok sınırlı işlem yapar. UXM ise aktif hücreye ek olarak adresleme sistemi kurar. Yani `+` komutu yalnızca aktif hücrede değil, örneğin `(T+3)`, `(D:100)`, `(SP-1)`, `(D@T)` gibi hedeflerde de çalışabilir. Bu fark çok büyüktür. Çünkü bu sayede dil, tek boyutlu oyuncak tape modelinden gerçek bellek modeli kullanan bir VM yapısına yaklaşır.

Forth ile benzerliği, küçük komutlar ve stack/tape merkezli düşünme biçimidir. Assembly ile benzerliği, programcının bellek adresleri ve register benzeri alanlarla doğrudan ilgilenmesidir. WebAssembly ile benzerliği, sandbox edilebilir ve servis çağrılarıyla host dünyaya bağlanabilir bir runtime fikridir. Python ve BASIC'ten farkı ise yüksek seviyeli sözdizimi yerine düşük seviyeli ama genişletilebilir bir çekirdek sunmasıdır.

ASCII olarak dilin zihniyeti şöyle gösterilebilir:

```text
Python / BASIC tarzı:

    değişkenler  -> ifadeler -> fonksiyonlar -> çıktı

UXM tarzı:

    bellek hücreleri -> pointer -> komut -> servis -> çıktı

Daha teknik:

    Tape / Data / Stack / Queue
              |
              v
       UXM komut akışı
              |
              v
       Runtime service call
              |
              v
       Native ASM / EXE / test output
```

UXM'nin farkı, syntax büyütmek yerine runtime servislerini büyütmesidir. Bu çok özgün bir seçimdir. C, C++, Python, BASIC gibi dillerde dilin kendisi büyür. UXM'de ise çekirdek küçük kalır, fakat `@N` servisleri büyür. Bu hem büyük avantajdır hem de kontrol edilmezse büyük risk yaratır.

---

## 3. Paket Dizin Yapısı

Paketin gerçek dizin yapısı sadeleştirilmiş olarak şöyledir:

```text
UXMv33(6)/
|
+-- uxm/
|   +-- core/
|   |   +-- compiler/
|   |   |   +-- native/
|   |   |   |   +-- uxm31_compiler_fb.bas
|   |   |   |   +-- native_cli.bas
|   |   |   |   +-- native_lexer_parser.bas
|   |   |   |   +-- native_addressing.bas
|   |   |   |   +-- native_meta_parse.bas
|   |   |   |   +-- native_validation.bas
|   |   |   |   +-- native_asm_emit.bas
|   |   |   |   +-- native_main.bas
|   |   |   +-- extensions/
|   |   |       +-- arge_parse_math_additions.bas
|   |   |       +-- arge_parse_matrix_additions.bas
|   |   |
|   |   +-- runtime/
|   |       +-- uxm31_runtime_fb_full.bas
|   |       +-- runtime_memory.bas
|   |       +-- runtime_meta_dispatch.bas
|   |       +-- runtime_status_flags.bas
|   |       +-- runtime_io.bas
|   |       +-- runtime_host.bas
|   |       +-- services/
|   |           +-- runtime_file_services.bas
|   |           +-- runtime_string_services.bas
|   |           +-- runtime_statistics_services.bas
|   |           +-- runtime_matrix_services.bas
|   |           +-- runtime_fp_services.bas
|   |           +-- runtime_probability_services.bas
|   |           +-- runtime_numeric_methods_services.bas
|   |           +-- runtime_complex_services.bas
|   |           +-- runtime_bio_services.bas
|   |           +-- runtime_ml_data_pipeline_services.bas
|   |
|   +-- tests/
|       +-- manifest/
|       +-- all_expected_known/
|       +-- all_expected_results/
|       +-- all_expected_excluded/
|
+-- config/
|   +-- uxm/
|       +-- service_registry_merged.csv
|
+-- vscode/
|   +-- kurulum/
|       +-- vscode_kur.bat
|
+-- onceki_src/
|
+-- guncel_src/
    +-- build_one_native.bat
```

Burada en önemli gerçek şudur: güncel ana sistem `uxm/core` altında durur. ---

## 4. UXM'nin Derleme Zinciri

Paket içinde FreeBASIC ile yazılmış bir compiler hattı vardır. Derleme zinciri kabaca şöyledir:

```text
.uxm kaynak program
        |
        v
FreeBASIC ile yazılmış UXM native compiler
        |
        v
NASM x64 assembly çıktısı
        |
        v
NASM ile OBJ üretimi
        |
        v
FreeBASIC runtime ile link
        |
        v
Windows EXE
```

Daha basit söylersek, UXM dosyası doğrudan EXE olmaz. Önce UXM compiler bunu assembly dosyasına çevirir. Sonra NASM bunu object dosyasına çevirir. Sonra FreeBASIC runtime ile birleştirilerek EXE üretilir.

ASCII akış:

```text
program.uxm
    |
    |  UXM compiler
    v
program.asm
    |
    |  NASM
    v
program.o
    |
    |  FreeBASIC runtime link
    v
program.exe
```

Bu tasarımın iyi tarafı şudur: dil native x64 tarafına bağlanmıştır. Kötü tarafı ise kurulum zinciri hassastır. FreeBASIC, NASM, path ayarları, Windows link davranışı ve runtime dosyalarının doğru yerde olması gerekir.

---

## 5. Kurulum Mantığı

UXM'yi çalıştırmak için temel ihtiyaçlar şunlardır:

| Bileşen           | İngilizce Terim            | Amaç                                                                    |
| ----------------- | -------------------------- | ----------------------------------------------------------------------- |
| FreeBASIC         | `FreeBASIC compiler / fbc` | UXM compiler ve runtime kaynaklarını derlemek için gerekir.             |
| NASM              | `Netwide Assembler`        | Üretilen x64 assembly dosyasını object dosyasına çevirmek için gerekir. |
| Windows terminal  | `cmd / PowerShell`         | Build scriptlerini çalıştırmak için gerekir.                            |
| UXM kaynak paketi | `source tree`              | `uxm/core` ve test dosyalarını içerir.                                  |
| Test corpus       | `test corpus`              | `.uxm` ve `.expect` dosyalarıyla regresyon testi yapılır.               |

Paket içindeki `build_one_native.bat` dosyasının mantığı şudur:

```bat
build_one_native.bat kaynak.uxm [-x]
```

Script önce `build/exe`, `build/asm`, `build/obj`, `build/logs` klasörlerini hazırlar. Sonra `uxm_native.exe` yoksa native compiler'ı derlemeye çalışır. Sonra verilen `.uxm` dosyasından `.asm` üretir. NASM ile `.o` üretir. En son FreeBASIC runtime ile link edip `.exe` üretir ve çalıştırır.

Kısaca:

```text
build_one_native.bat test.uxm
```

komutu şu işleri yapar:

```text
1. UXM compiler var mı kontrol eder.
2. Yoksa compiler'ı derler.
3. test.uxm -> test.asm üretir.
4. test.asm -> test.o üretir.
5. test.o + runtime -> test.exe üretir.
6. test.exe çalıştırılır.
```
---

# UXM'nin En Güçlü Yanları

## Küçük Çekirdek, Büyük Runtime

UXM'nin en özgün gücü budur. Dil çekirdeği küçük kalır, yetenekler servislerle büyür.

## Adresleme Gücü

Relative, absolute, indirect, indexed ve stack-relative adresleme UXM'yi ciddi biçimde güçlendirir.

## Bilimsel Servis Potansiyeli

Statistics, matrix, tensor, bio, numerical methods ve ML servisleri, UXM'yi bilimsel mini runtime haline getirebilir.

## Test Corpus Zenginliği

Binlerce `.uxm` ve `.expect` dosyası, dilin davranışını belgelemeye başlamıştır.

## Native Backend Yönü

NASM x64 assembly üretimi, dilin yalnızca interpreter oyuncağı olmadığını gösterir.

## Öğretici Değer

UXM, programcıya bellek, pointer, frame, service, status, test, runtime gibi temel bilgisayar bilimi konularını öğretebilir.

# UXM'nin En Uygun Kullanım Alanları

UXM her iş için doğru dil değildir. Ama bazı alanlarda çok anlamlıdır.

## Eğitim ve Bilgisayar Mimarisi

Pointer, memory, stack, service, runtime, status öğrenmek için çok değerlidir.

## Embedded / Deterministic Runtime

Sınırlı bellek, kontrollü execution ve küçük komut seti nedeniyle uygundur.

## Scientific Mini Runtime

Statistics, matrix, tensor, numeric methods ve bio servisleri nedeniyle bilimsel mikro runtime olabilir.

## AI Graph Deneyleri

Tensor, ML/data pipeline ve service dispatch sistemi AI graph execution için kullanılabilir.

## Compiler Araştırması

Lexer, parser, addressing, native asm emit, runtime dispatch, test corpus gibi birçok compiler konusu tek projede görülebilir.

---

# UXM'nin Uygun Olmadığı Alanlar

UXM bazı işler için doğru tercih değildir.

| Alan                             | Neden Uygun Değil?                          |
| -------------------------------- | ------------------------------------------- |
| Hızlı web app geliştirme         | Syntax ve runtime bunun için tasarlanmamış. |
| Büyük GUI uygulaması             | UI abstraction yok.                         |
| Genel amaçlı script              | Python daha uygun.                          |
| Büyük ekip projesi               | Dil standardı ve tooling henüz erken.       |
| Güvenlik kritik üretim           | Service/dispatcher çakışmaları çözülmeli.   |
| Kolay öğrenilecek başlangıç dili | Öğrenme eğrisi sert.                        |

Bu kötü bir şey değildir. Her dilin doğru kullanım alanı vardır. UXM'nin alanı daha çok VM, compiler, scientific runtime ve düşük seviyeli eğitim/deneysel sistemdir.

---

# Nihai Yorum

UXM şu anda küçük bir sembolik dil olarak başlamış ama artık çok daha geniş bir şeye dönüşmüş durumda. En doğru tanım şudur:

```text
UXM = Minimal syntax + adreslenebilir VM memory + runtime service ecosystem + native backend hedefi.
```

Bu dilin en büyük gücü, küçük komut çekirdeğiyle çok geniş servis dünyasını birleştirmesidir. Bu dilin en büyük zayıflığı da yine budur. Çünkü servisler disiplinli yönetilmezse sistem hızla karışır.

UXM, Python gibi kolay ve konforlu olmak zorunda değildir. UXM'nin değeri başka yerdedir. UXM, programcıya makineyi, belleği, pointer'ı, servisi, compiler'ı ve runtime'ı aynı anda düşündürür. Bu yönüyle hem öğretici hem deneysel hem de doğru toparlanırsa bilimsel/AI runtime platformuna dönüşebilecek bir sistemdir.

Bu dilin geleceği için en kritik ilke şudur:

```text
Komut çekirdeği küçük kalmalı.
Servis sistemi belgeli olmalı.
Dispatcher ve registry aynı gerçeği söylemeli.
Her özellik testle sabitlenmeli.
```

# Son Kullanıcıya Kısa Öğüt

UXM öğrenirken kendine şunu söyle:

```text
Ben değişken yazmıyorum, bellek haritası kuruyorum.
Ben fonksiyon çağırmıyorum, runtime service çağırıyorum.
Ben liste oluşturmuyorum, data segment yerleşimi yapıyorum.
Ben print yazmıyorum, çıktı servisi çağırıyorum.
Ben hata yakalamıyorum, status register okuyorum.
```

Bu düşünce oturduğunda UXM anlaşılır hale gelir.

Bitti.
