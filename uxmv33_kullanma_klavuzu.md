# UXMv33 Kullanma Kılavuzu — 4 Promptluk Öğretici Ana Belge

Bu belge, önceki mimari analiz raporunun tekrarı değildir. Buradaki amaç, UXMv33 dilini bir programcının gerçekten kullanabilmesi için öğretici, açıklamalı ve uygulamalı bir kılavuz oluşturmaktır. Dil anlatılırken Türkçe ana anlatım korunacak, fakat gerekli teknik kavramlar İngilizce terimleriyle birlikte verilecektir: `compiler`, `runtime`, `addressing`, `stack`, `tape`, `data segment`, `service`, `macro`, `dispatch`, `native backend`, `test corpus`, `expected output` gibi.

İncelenen paket: `UXMv33(6).zip`.

Paket gerçekliği özetle şöyledir:

* Yaklaşık 8986 dosya vardır.
* Yaklaşık 5249 adet `.uxm` program/test dosyası vardır.
* Yaklaşık 3212 adet `.expect` beklenen çıktı dosyası vardır.
* Ana güncel kaynak hattı `uxm/core` altındadır.
* Eski kaynaklar `onceki_src` altında tutulmuştur.
* Daha küçük güncel örnek kaynak hattı `guncel_src` altında ayrıca vardır.
* VSCode tarafı `vscode` altında ayrı tutulmuştur.
* Servis kayıtları `config/uxm/service_registry_merged.csv` altında bulunur.

Bu belge dört büyük bölüm halinde ilerleyecek şekilde planlanmıştır.

---

# 4 Promptluk Kılavuz Planı

## Prompt 1 — Temel Kullanım, Kurulum, Derleme, Mimari ve Dilin Zihniyeti

Bu bölümde UXM'nin ne olduğu, ne olmadığı, nasıl kurulduğu, nasıl derlendiği, nasıl test edildiği, paket dizinlerinin anlamı, programcının bu dile nasıl yaklaşması gerektiği, BASIC/Python bilen birinin UXM'ye nasıl geçeceği anlatılır. Ayrıca UXM'nin paradigması, kökenleri, başka dillerden farkları ve temel çalışma modeli açıklanır.

## Prompt 2 — Komut Seti ve Adresleme Sistemi

Bu bölümde bütün temel komutlar tablo halinde verilir. `>`, `<`, `+`, `-`, `0`, `.`, `,`, `[`, `]`, `$`, `%`, `?`, `!`, `;`, `&`, `|`, `^`, `~`, `{`, `}`, `e`, `@`, `:`, `sN`, `pN`, `mN` gibi komutlar açıklanır. Adresleme sistemi ayrı ayrı anlatılır: aktif hücre, göreli adresleme, mutlak adresleme, data segment adresleme, stack pointer adresleme, pointer register adresleme, dolaylı/indirect adresleme, indexed/base+P adresleme, double indirect benzeri `D@D`, `T@D` yapıları ve branch mantığı örneklerle açıklanır.

## Prompt 3 — Servisler, Runtime API ve Alanlara Göre Kullanım

Bu bölümde servisler tablo halinde anlatılır. Çekirdek servisler, matematik, floating point, matrix, tensor, string, file I/O, probability, statistics, numerical methods, complex, bio, sparse vector, ML/data pipeline servisleri ayrı ayrı verilir. Her servis ailesi için amaç, giriş/çıkış hücre düzeni ve örnek kullanım mantığı açıklanır.

## Prompt 4 — Profesyonel Örnekler, Program Çözümleme, Eğitim Yolu, Üstünlük/Darboğaz Analizi

Bu bölümde basitten profesyonel örneklere gidilir. Python/BASIC örnekleri UXM karşılıklarıyla anlatılır. Dosya okuma-yazma, istatistik hesaplama, matrix/tensor işlem hattı, biyolojik dizi analizi, yem dönüşüm oranı veya su ürünleri hesap örneği gibi alan örnekleri verilir. Sonunda dilin güçlü yanları, zayıf yanları, mimari darboğazları, gelecekte çözülmesi gereken noktalar ve programcının kendini nasıl eğiteceği açıklanır.

Bu metin şu anda Prompt 1 ile başlar.

---

# PROMPT 1 — Temel Kullanım, Kurulum, Derleme, Mimari ve UXM'nin Zihniyeti

## 1. UXM Nedir?

UXM, görünüşte Brainfuck benzeri çok küçük komutlardan oluşan bir dildir. Fakat paket içindeki gerçek kod yapısı incelendiğinde UXM'nin artık basit bir Brainfuck türevi olmaktan çıktığı görülür. UXM daha doğru ifadeyle, küçük komut çekirdeği üzerine kurulmuş, servis tabanlı, deterministic yani öngörülebilir çalışma düzeni olan bir virtual machine / compiler dilidir.

UXM'yi anlamanın en kolay yolu şudur:

Python veya BASIC'te değişken isimleriyle çalışırsın. UXM'de ise bellek hücreleriyle çalışırsın. Python'da `x = x + 1` dersin. UXM'de aktif hücredeki değeri `+` komutuyla artırırsın. Python'da liste veya array kullanırsın. UXM'de tape, data segment, stack ve queue gibi bellek alanlarını kullanırsın. Python'da hazır fonksiyon çağırırsın. UXM'de `@N` şeklinde runtime service çağırırsın.

Yani UXM'de program yazmak, yüksek seviyeli bir dilde cümle yazmaya değil, küçük bir makineyi programlamaya benzer. Ama bu makine artık yalnızca `+ - < >` seviyesinde değildir. İçinde string, dosya, istatistik, matrix, tensor, numerik yöntem, olasılık, biyoinformatik ve ML/data pipeline servisleri vardır.

Bu nedenle UXM'nin en doğru kısa tanımı şudur:

**UXM, minimal komut seti + geniş runtime servisleri + kontrollü bellek modeli üzerine kurulu deneysel bir compiler/runtime dilidir.**

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

Burada en önemli gerçek şudur: güncel ana sistem `uxm/core` altında durur. `onceki_src` eski sürüm parçalarını taşır. `guncel_src` daha küçük bir güncel örnek hat gibi görünür. Bu nedenle gerçek çalışma yapılırken `uxm/core` ana kabul edilmeli, `onceki_src` ise kaynak/karşılaştırma/geri alma deposu gibi düşünülmelidir.

---

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

Bu kılavuzda ileride her örneği bu mantıkla düşüneceğiz.

---

## 6. İlk UXM Programını Düşünmek

UXM'de program yazarken ilk öğrenilecek şey şudur: program bir metin gibi değil, makinenin hücreleri üzerinde yapılan hareketler gibi düşünülür.

En basit bellek modeli:

```text
Tape:

Adres:    0    1    2    3    4    5
        +----+----+----+----+----+----+
Değer:  | 00 | 00 | 00 | 00 | 00 | 00 |
        +----+----+----+----+----+----+
Pointer:  ^
          T
```

`+` komutu aktif hücreyi artırır:

```text
+
```

Sonuç:

```text
Adres:    0    1    2
        +----+----+----+
Değer:  | 01 | 00 | 00 |
        +----+----+----+
Pointer:  ^
          T
```

`>` pointer'ı sağa taşır:

```text
>
```

Sonuç:

```text
Adres:    0    1    2
        +----+----+----+
Değer:  | 01 | 00 | 00 |
        +----+----+----+
Pointer:       ^
               T
```

`+` artık ikinci hücreyi artırır.

Bu BF kökenli mantıktır. Ama UXM burada kalmaz. UXM'de şunu da yazabilirsin:

```text
+(T+5)
```

Bu, aktif pointer'ı oynatmadan aktif hücreden 5 sonraki hücreyi artır demektir.

Yani UXM programcısı için ilk büyük fark şudur:

* `>` ve `<` ile pointer'ı gezdirebilirsin.
* Adresleme paranteziyle pointer'ı gezdirmeden hedef hücreye işlem yapabilirsin.

Bu fark, UXM'yi sıradan Brainfuck'tan ayıran en önemli farklardan biridir.

---

## 7. UXM'de Programcı Nasıl Düşünmeli?

Python bilen birisi genelde şöyle düşünür:

```python
x = 5
y = 7
z = x + y
print(z)
```

BASIC bilen birisi şöyle düşünür:

```basic
LET X = 5
LET Y = 7
LET Z = X + Y
PRINT Z
```

UXM'de ise aynı düşünce şöyle parçalanır:

```text
Hücre 0 = x
Hücre 1 = y
Hücre 2 = z

1. Hücre 0'a 5 koy.
2. Hücre 1'e 7 koy.
3. Hücre 0 ve 1 değerlerini servis veya komutlarla işle.
4. Sonucu hücre 2'ye yaz.
5. Yazdırma servisi veya çıktı komutu kullan.
```

UXM'de isimli değişken yerine bellek planı yapılır. Bu nedenle UXM programı yazmadan önce küçük bir bellek haritası çıkarmak gerekir.

Örnek:

```text
Bellek Planı:

T+0 : x
T+1 : y
T+2 : sonuc
T+3 : geçici alan
T+4 : status
```

Bu mantık assembly, embedded C ve eski BASIC PEEK/POKE mantığına yakındır. Programcı önce veriyi nereye koyacağını düşünür, sonra komutları yazar.

---

## 8. Temel Program Yapısı

UXM dosyası `.uxm` uzantılıdır. Dosyada şunlar bulunabilir:

* Yorum satırları
* String tanımları
* Macro tanımları
* Komut akışı
* Meta service çağrıları
* Branch komutları

Kodda görülen parser davranışına göre yorumlar iki şekilde kullanılabilir:

```text
# bu bir yorumdur
REM bu da yorumdur
```

String tanımı şu şekildedir:

```text
s1=0,{Merhaba UXM\n}
```

Burada `s1`, 1 numaralı string tanımıdır. `0` başlangıç hücresidir. `{...}` içindeki metin string içeriğidir. Escape karakterleri desteklenir:

| Yazım | Anlamı          |
| ----- | --------------- |
| `\n`  | yeni satır      |
| `\r`  | carriage return |
| `\t`  | tab             |
| `\{`  | `{` karakteri   |
| `\}`  | `}` karakteri   |
| `\\`  | ters slash      |

String yazdırma komutu:

```text
p1
```

Bu, daha önce tanımlanmış `s1` stringini yazdırır.

İlk örnek program:

```text
# Merhaba UXM örneği
s1=0,{Merhaba UXM\n}
p1
```

Derleme mantığı:

```bat
build_one_native.bat merhaba.uxm
```

Beklenen çıktı:

```text
Merhaba UXM
```

Bu örnek, UXM'de string sisteminin normal karakter yazdırmadan daha pratik olduğunu gösterir.

---

## 9. UXM Komut Akışının Basit Modeli

UXM'de her komut bir instruction olarak compiler tarafından toplanır. Kodda `MAX_INSTR = 200000` tanımı vardır. Yani büyük programlara izin verilmesi hedeflenmiştir.

Basit model:

```text
Kaynak kod:

    +++>++.<.

Parser sonucu instruction list:

    1. INC aktif hücre
    2. INC aktif hücre
    3. INC aktif hücre
    4. RIGHT
    5. INC aktif hücre
    6. INC aktif hücre
    7. PUTC aktif hücre
    8. LEFT
    9. PUTC aktif hücre
```

Compiler daha sonra bu instruction listesini x64 assembly olarak üretir.

Bu tasarımın iyi tarafı, ileride optimizer eklenmesine izin vermesidir. Örneğin `+++++` dizisi tek instruction olarak `+k5` gibi temsil edilebilir. Kodda `+kN` ve `-kN` desteği vardır.

---

## 10. `+kN` ve `-kN` Hızlandırılmış Artırma/Azaltma

Parser içinde `+` ve `-` komutlarının ardından `k` gelirse sayı okunur. Bu şu anlama gelir:

```text
+k10
```

aktif hedefi 10 artırır.

```text
-k5
```

aktif hedefi 5 azaltır.

Bu, uzun uzun `++++++++++` yazmak yerine daha okunur ve daha derlenebilir bir yazımdır.

Örnek:

```text
0+k65.
```

Burada:

* `0` aktif hücreyi sıfırlar.
* `+k65` aktif hücreye 65 değerini koyar.
* `.` aktif hücreyi karakter olarak yazdırır.

ASCII 65, `A` karakteridir. Beklenen çıktı:

```text
A
```

Bu, BASIC/Python bilen biri için şöyle düşünülebilir:

```python
print(chr(65))
```

veya BASIC:

```basic
PRINT CHR$(65)
```

UXM karşılığı:

```text
0+k65.
```

---

## 11. UXM'nin Ana Bellek Alanları

Paket içinde compiler sabitleri şu bellek alanlarını gösterir:

| Alan  | İngilizce Terim | Varsayılan |     Maksimum Mantık | Amaç                                |
| ----- | --------------- | ---------: | ------------------: | ----------------------------------- |
| Tape  | `tape memory`   |      32 KB | 16 MB sınırı içinde | Ana çalışma şeridi                  |
| Stack | `stack memory`  |       4 KB | 16 MB sınırı içinde | Push/pop ve geçici değerler         |
| Data  | `data segment`  |      16 KB | 16 MB sınırı içinde | Büyük veri, matrix, string, dataset |
| Queue | `queue memory`  |       4 KB | 16 MB sınırı içinde | FIFO/akış mantığı                   |

Önemli nokta: sürüm adında `mem16m` ifadesi vardır ve sabitlerde `UXM_MAX_TOTAL_KB = 16384` görülür. Bu, toplamda 16 MB üst sınır fikrinin kodda bulunduğunu gösterir.

Bu bellek alanları şöyle düşünülebilir:

```text
+----------------------------------------------------------+
|                    UXM Runtime Memory                    |
+----------------+----------------+----------------+-------+
| Tape           | Data           | Stack          | Queue |
| Ana hücreler   | Büyük veri     | Geçici yığın   | FIFO  |
+----------------+----------------+----------------+-------+
```

BASIC/Python bilen biri için benzetme:

* Tape: küçük değişkenlerin durduğu ana çalışma alanı.
* Data: array/list/matrix gibi büyük verilerin durduğu alan.
* Stack: fonksiyon çağrısı veya geçici hesap alanı.
* Queue: sıraya alınmış veri akışı.

---

## 12. UXM'nin Runtime Register Mantığı

Runtime tarafında şu register benzeri durum alanları vardır:

| Alan | İngilizce Terim                  | Anlam                                         |
| ---- | -------------------------------- | --------------------------------------------- |
| `T`  | `tape pointer`                   | Aktif tape hücresi                            |
| `SP` | `stack pointer`                  | Stack içindeki aktif konum                    |
| `P`  | `general pointer/index register` | İndisli adreslemede kullanılan pointer        |
| `E`  | `status/error register`          | Hata veya durum kodu                          |
| `F`  | `flags register`                 | Zero, carry, overflow, sign gibi flag mantığı |

Bunlar klasik CPU register'ları gibi düşünülmelidir. UXM küçük bir sanal makine olduğu için programcı bu alanlarla doğrudan çalışabilir.

ASCII model:

```text
        +-------------------+
        | UXM VM Registers  |
        +-------------------+
        | T  : tape pointer |
        | SP : stack ptr    |
        | P  : index ptr    |
        | E  : status       |
        | F  : flags        |
        +-------------------+
```

Bu yüzden UXM'de program yazarken yalnızca hücreleri değil, pointer ve status mantığını da düşünmek gerekir.

---

## 13. UXM Programlama Paradigması

UXM'nin paradigması tek kelimeyle açıklanamaz. Ama birkaç başlıkla tanımlanabilir:

| Paradigma                   | UXM'deki Karşılığı                                 |
| --------------------------- | -------------------------------------------------- |
| Imperative programming      | Komutlar sırayla yürür.                            |
| Stack/tape programming      | Bellek hücreleri ve pointer ana çalışma aracıdır.  |
| Service-oriented runtime    | Büyük işler `@N` servisleriyle yapılır.            |
| Low-level VM programming    | Programcı bellek yerleşimini düşünür.              |
| Macro programming           | Kullanıcı `m128..m255` arası macro tanımlayabilir. |
| Deterministic/sandbox style | Bellek sınırları ve status sistemi vardır.         |

UXM'de programcı şu üç soruyu sürekli sorar:

1. Verim hangi bellek alanında duracak?
2. Hangi komut veya servis bu veriyi işleyecek?
3. Sonuç hangi hücreye veya data bölgesine yazılacak?

Bu üç soru öğrenilmeden UXM programlamak zorlaşır.

---

## 14. BASIC/Python Bilen Biri UXM'ye Nasıl Geçmeli?

BASIC veya Python bilen biri genelde şu kavramlara alışkındır:

* değişken
* döngü
* koşul
* fonksiyon
* liste/array
* dosya
* print/input

UXM'de bunların karşılığı vardır ama adları ve düşünme biçimi farklıdır.

| Python/BASIC Kavramı | UXM Karşılığı                            |
| -------------------- | ---------------------------------------- |
| Değişken             | Tape/Data hücresi                        |
| Array/List           | Data segment veya ardışık tape hücreleri |
| Fonksiyon            | Macro veya service call                  |
| Print                | `.`, `pN`, print servisleri              |
| Input                | `,` veya input service                   |
| If                   | Karşılaştırma + flag + branch            |
| Loop                 | `[` `]` veya branch                      |
| Dosya işlemi         | `@400..@415` file services               |
| Math fonksiyonu      | `@200..@254` ve ilgili servisler         |
| İstatistik           | `@260..@299` servisleri                  |
| Matrix/Tensor        | `@160..@199`, `@512..@599` servisleri    |

Örneğin Python'da:

```python
x = 65
print(chr(x))
```

UXM'de:

```text
0+k65.
```

Python'da:

```python
print("Merhaba")
```

UXM'de:

```text
s1=0,{Merhaba\n}
p1
```

Python'da:

```python
x = x + 10
```

UXM'de aktif hücre için:

```text
+k10
```

Başka hücre için:

```text
+k10(T+3)
```

Bu farkı kavrayan programcı UXM'nin kapısını açmış olur.

---

## 15. Basit Örnek 1 — Karakter Yazdırma

Amaç: Ekrana `A` yazdırmak.

Bellek planı:

```text
T+0 : yazdırılacak ASCII karakter
```

UXM kodu:

```text
# A karakteri yazdır
0+k65.
```

Çözümleme:

| Komut  | Anlamı                                |
| ------ | ------------------------------------- |
| `0`    | Aktif hücreyi sıfırla.                |
| `+k65` | Aktif hücreye 65 ekle.                |
| `.`    | Aktif hücreyi karakter olarak yazdır. |

Python karşılığı:

```python
print(chr(65), end="")
```

BASIC karşılığı:

```basic
PRINT CHR$(65);
```

Burada UXM'nin güçlü tarafı görülür: çok az sembolle doğrudan byte seviyesinde çıktı üretilir. Zayıf tarafı da görülür: `A` yazmak için ASCII kodunu bilmek gerekir. Bu nedenle UXM düşük seviyeli düşünme ister.

---

## 16. Basit Örnek 2 — String Yazdırma

Amaç: Ekrana `Merhaba UXM` yazdırmak.

UXM kodu:

```text
# String tanımı ve yazdırma
s1=0,{Merhaba UXM\n}
p1
```

Çözümleme:

| Satır        | Anlamı                                                        |
| ------------ | ------------------------------------------------------------- |
| `s1=0,{...}` | 1 numaralı stringi 0 hücresinden başlayacak şekilde tanımlar. |
| `p1`         | 1 numaralı stringi yazdırır.                                  |

Bu, karakter karakter ASCII yazmaktan çok daha pratiktir.

Kötü taraf: string tanımında bellek başlangıcını programcı verir. Yani stringler için bellek çakışmasına dikkat etmek gerekir. İyi taraf: programcı stringin nerede durduğunu kontrol eder.

---

## 17. Basit Örnek 3 — Birden Fazla Hücre Kullanmak

Amaç: Hücre 0'a 10, hücre 1'e 20 koymak.

UXM kodu:

```text
0+k10      # T hücresi = 10
0(T+1)+k20 # T+1 hücresi = 20
```

Dikkat: adresleme parantezinde boşluk yasaktır. Bu nedenle gerçek kodda yorumları ayrı satıra almak daha güvenlidir:

```text
# T = 10
0+k10
# T+1 = 20
0(T+1)+k20
```

Burada `0(T+1)` T+1 hücresini sıfırlar. `+k20` ise aynı hedefe otomatik uygulanmazsa ayrı yazımda dikkat gerekir. Parser kodunda `0(addr)+kN` kalıbı desteklenmiştir. Yani şu yazım önemlidir:

```text
0(T+1)+k20
```

Bu, `T+1` hücresini sıfırla ve sonra 20 ekle anlamına gelir.

Bellek görünümü:

```text
Adres:    T+0  T+1  T+2
        +----+----+----+
Değer:  | 10 | 20 | 00 |
        +----+----+----+
```

Python karşılığı:

```python
mem = [0] * 3
mem[0] = 10
mem[1] = 20
```

---

## 18. Macro Sistemi

UXM'de kullanıcı macro tanımlayabilir. Parser kodunda kullanıcı macro ID aralığı `128..255` olarak sınırlandırılmıştır.

Macro tanımı:

```text
m128={0+k65.}
```

Macro çağrısı:

```text
@128
```

Burada önemli nokta şudur: `@N` normalde service call gibi görünür. Ama eğer `N` kullanıcı macro aralığında tanımlıysa ve forced host çağrısı yapılmamışsa, parser macro içeriğini genişletir.

Örnek:

```text
# A yazdıran macro
m128={0+k65.}

# Macro çağır
@128
@128
@128
```

Beklenen çıktı:

```text
AAA
```

Macro expansion derinliği kodda 32 ile sınırlandırılmıştır. Bu iyi bir güvenliktir. Aksi halde macro kendini çağırırsa sonsuz expansion olur.

---

## 19. `@N` Service Call Mantığı

UXM'nin en güçlü yapısı `@N` çağrılarıdır. `@N`, runtime tarafında bir servis çağırır. Örneğin:

```text
@5
```

5 numaralı service çağrısıdır. Servisin ne yaptığı runtime dispatch tablosuna bağlıdır.

Service call mantığı şöyle düşünülebilir:

```text
UXM kodu:        @400
                    |
                    v
Runtime dispatch: metaId = 400
                    |
                    v
File service ailesine yönlendirme
                    |
                    v
FILE_OPEN_READ / FILE_OPEN_WRITE vb.
```

Genel akış:

```text
@N
 |
 v
runtime_meta_dispatch.bas
 |
 +--> core service
 +--> math service
 +--> string service
 +--> file service
 +--> matrix service
 +--> tensor service
 +--> ML/data service
```

Bu yapı çok güçlüdür. Çünkü UXM çekirdeği küçük kalırken servisler büyüyebilir.

Ama bu aynı zamanda tehlikelidir. Servisler iyi belgelenmezse dil anlaşılmaz hale gelir. Bu yüzden Prompt 3'te servis tabloları ayrı ayrı verilecektir.

---

## 20. `@!N`, `@#` ve Dinamik Meta Çağrı

Parser koduna göre `@` sonrasında `!` gelirse `forceHost` aktif olur.

```text
@!128
```

Bu, eğer 128 numaralı kullanıcı macro tanımlı olsa bile host service çağrısını zorlar. Yani macro expansion yerine runtime service çağrısı yapmak için kullanılır.

`@#` ise dinamik meta çağrı mantığı taşır. Parser bunu `metaId = -1`, dynamic flag = 1 gibi işler. Bu yapı, çağrılacak service ID'nin runtime sırasında bir hücreden okunması için düşünülmüş görünür.

Basit anlatım:

| Yazım      | Anlam                                                       |
| ---------- | ----------------------------------------------------------- |
| `@N`       | N numaralı macro varsa macro, yoksa host service.           |
| `@!N`      | Macro'yu atla, kesin host service çağır.                    |
| `@#`       | Dinamik service çağrısı; ID runtime'dan alınır.             |
| `@(adres)` | Service ID veya meta çağrı adresleme üzerinden çalışabilir. |

Bu yapı UXM'nin meta-programlama gücünü artırır.

---

## 21. Branch ve Kontrol Akışı

UXM'de klasik `if`, `while`, `for` yoktur. Bunun yerine iki ana kontrol mekanizması vardır:

1. Brainfuck tarzı loop: `[` ve `]`
2. Branch komutları: `:` ile başlayan dallanma komutları

Branch parser kodunda şu koşullar görülür:

| Branch Kodu | Anlam                                |
| ----------- | ------------------------------------ |
| `::+N`      | Koşulsuz ileri N instruction atla.   |
| `::-N`      | Koşulsuz geri N instruction git.     |
| `:0+N`      | Aktif hücre sıfırsa ileri git.       |
| `:+N`       | Aktif hücre sıfır değilse ileri git. |
| `:-N`       | Aktif hücre sıfır değilse geri git.  |
| `:z+N`      | Zero flag set ise ileri git.         |
| `:Z+N`      | Zero flag clear ise ileri git.       |
| `:c+N`      | Carry flag set ise ileri git.        |
| `:C+N`      | Carry flag clear ise ileri git.      |
| `:o+N`      | Overflow flag set ise ileri git.     |
| `:O+N`      | Overflow flag clear ise ileri git.   |
| `:s+N`      | Sign flag set ise ileri git.         |
| `:S+N`      | Sign flag clear ise ileri git.       |

Branch yapısı instruction mesafesine göre çalışır. Bu nedenle yüksek seviyeli dillerdeki label mantığından daha düşük seviyelidir. Programcı instruction sayısını düşünmek zorunda kalabilir. Bu güçlü ama zor bir yapıdır.

Bu konu Prompt 2'de ayrıntılı işlenecektir.

---

## 22. Test Sistemi Nasıl Düşünülmeli?

Paketin en güçlü taraflarından biri test evrenidir. Çok sayıda `.uxm` ve `.expect` dosyası vardır. Bu şu anlama gelir:

* `.uxm` dosyası çalıştırılır.
* Çıktı alınır.
* Aynı isimli veya ilişkili `.expect` dosyasıyla karşılaştırılır.
* Fark varsa regression veya davranış değişimi vardır.

Bu klasik compiler test yaklaşımıdır. Buna `golden output testing` denir.

ASCII:

```text
ornek.uxm
   |
   v
çalıştır
   |
   v
actual output
   |
   +---- karşılaştır ---- expected output (.expect)
                         |
                         v
                    PASS / FAIL
```

Test klasörlerinde manifest dosyaları vardır:

```text
uxm/tests/manifest/ALL_EXPECTED_RUN_LIST.csv
uxm/tests/manifest/ALL_PACKAGE_TEST_FILES_MANIFEST.csv
uxm/tests/manifest/ALL_UNIQUE_TEST_INDEX.csv
```

Bu dosyalar testlerin düzenlenmesi için önemlidir.

Kullanıcı açısından test çalıştırma mantığı şu olmalıdır:

```text
1. Önce tek bir küçük .uxm dosyası derlenir.
2. Çıktısı elle kontrol edilir.
3. Sonra aynı test için .expect üretilir veya var olan .expect ile kıyaslanır.
4. Sonra stage/toplu test çalıştırılır.
5. En son manifest güncellenir.
```

Bu yaklaşım UXM gibi deneysel dilde şarttır. Çünkü her yeni servis veya komut eski davranışları bozabilir.

---

## 23. Kurulum ve İlk Çalıştırma İçin Pratik Yol

Windows tarafında en pratik akış şudur:

```text
1. Paketi kısa ve boşluksuz bir dizine çıkar.
   Örnek: C:\uxm_v33

2. FreeBASIC kurulu olsun.
   fbc.exe terminalden çalışmalı veya script içinde yolu doğru olmalı.

3. NASM kurulu olsun.
   nasm komutu terminalden çalışmalı.

4. Terminali proje kökünde aç.

5. Basit bir merhaba.uxm dosyası oluştur.

6. build_one_native.bat merhaba.uxm komutunu çalıştır.
```

Örnek `merhaba.uxm`:

```text
s1=0,{Merhaba UXM v33\n}
p1
```

Komut:

```bat
build_one_native.bat merhaba.uxm
```

Beklenen çıktı:

```text
Merhaba UXM v33
```

Eğer hata alınırsa ilk bakılacak yerler:

| Hata Alanı                  | Kontrol                                                          |
| --------------------------- | ---------------------------------------------------------------- |
| FreeBASIC bulunamadı        | `fbc` path içinde mi? Scriptteki `FBC64` yolu doğru mu?          |
| NASM bulunamadı             | `nasm -v` çalışıyor mu?                                          |
| Runtime bulunamadı          | `uxm/core/runtime/uxm31_runtime_fb_full.bas` doğru yerde mi?     |
| ASM üretildi ama OBJ olmadı | NASM syntax hatası veya path sorunu olabilir.                    |
| OBJ oldu ama EXE olmadı     | FreeBASIC link aşaması sorunludur.                               |
| EXE açılıp kapanıyor        | Program çıktı verip bitiyordur; terminalden çalıştırmak gerekir. |

Özellikle EXE'ye çift tıklanınca pencerenin hemen kapanması normaldir. Bu hata değildir. Terminalden çalıştırılmalıdır veya program içine bekleme/input eklenmelidir.

---

## 24. UXM'nin Mimari Haritası

UXM'nin sade mimari haritası şöyledir:

```text
+-------------------------------------------------------+
|                    UXM Source (.uxm)                  |
+----------------------------+--------------------------+
                             |
                             v
+-------------------------------------------------------+
|                  Lexer / Parser Layer                 |
|  native_lexer_parser.bas                              |
|  native_addressing.bas                                |
|  native_meta_parse.bas                                |
+----------------------------+--------------------------+
                             |
                             v
+-------------------------------------------------------+
|                 Instruction List / IR                 |
|  OP_INC, OP_DEC, OP_META, OP_BRANCH, OP_PRINT_STRING  |
+----------------------------+--------------------------+
                             |
                             v
+-------------------------------------------------------+
|                   Native ASM Emitter                  |
|  native_asm_emit.bas                                  |
+----------------------------+--------------------------+
                             |
                             v
+-------------------------------------------------------+
|                    NASM x64 Output                    |
+----------------------------+--------------------------+
                             |
                             v
+-------------------------------------------------------+
|                   Runtime Link Layer                  |
|  uxm31_runtime_fb_full.bas                            |
|  runtime_meta_dispatch.bas                            |
|  runtime/services/*.bas                               |
+----------------------------+--------------------------+
                             |
                             v
+-------------------------------------------------------+
|                    Windows EXE Output                 |
+-------------------------------------------------------+
```

Bu mimari aslında iki ana gövdeden oluşur:

1. Compiler gövdesi
2. Runtime/service gövdesi

Compiler kaynak kodu okur, komutları çözer, assembly üretir. Runtime ise program çalışırken `@N` servislerini, bellek sistemini, I/O işlemlerini ve geniş hesaplama servislerini sağlar.

---

## 25. UXM'nin Şu Anki Üstünlükleri

UXM'nin en güçlü yanları şunlardır:

### 25.1 Minimal Çekirdek

Komut seti küçük olduğu için dilin çekirdeği anlaşılabilir. Bu, embedded ve VM tarzı sistemler için avantajdır.

### 25.2 Geniş Runtime Service Sistemi

String, file, math, statistics, matrix, tensor, bio, ML/data pipeline gibi servis aileleri vardır. Bu, küçük syntax ile büyük işler yapma imkânı verir.

### 25.3 Adresleme Gücü

`(T+N)`, `(D:N)`, `(SP-N)`, `(D@T)`, `(D@(T-2)+N)`, `(T:BASE+P)` gibi adresleme biçimleri dilin gücünü ciddi artırır.

### 25.4 Test Evreni

Binlerce `.uxm` ve `.expect` dosyası vardır. Bu, dilin davranışını sabitlemek için büyük avantajdır.

### 25.5 Native x64 Hedefi

NASM üzerinden x64 assembly üretmesi, dilin yalnızca interpreter oyuncağı olmadığını gösterir.

### 25.6 Deterministic Memory Model

Tape, data, stack, queue alanlarının sınırları ve total memory policy yaklaşımı vardır. Bu sandbox ve güvenli çalışma için değerlidir.

---

## 26. UXM'nin Şu Anki Darboğazları

UXM'nin zayıf tarafları da açıkça görülmelidir.

### 26.1 Öğrenme Eğrisi Sert

Python veya BASIC bilen biri için UXM doğrudan kolay değildir. Çünkü değişken yerine hücre, fonksiyon yerine service, if yerine branch, array yerine data segment düşünmek gerekir.

### 26.2 Servis Belgelemesi Zorunlu

Servisler çok sayıda olduğu için tablo ve örnek olmadan dil kullanılamaz hale gelir. Bu yüzden Prompt 3 kritik olacaktır.

### 26.3 Type Sistemi Zayıf

Dil byte/cell ve memory üzerinden güçlüdür ama yüksek seviyeli type sistemi henüz tam oturmuş değildir. Tensor, matrix, float, string gibi alanlar servislerle yürür. Compile-time type checking zayıf kalabilir.

### 26.4 MIR / Optimizer Katmanı Belirsiz

Instruction list vardır ama daha gelişmiş bir middle IR / MIR katmanı net değildir. Bu, büyük optimizer ve çoklu backend için darboğazdır.

### 26.5 Branch Kullanımı Zor

Instruction mesafesine göre branch güçlüdür ama programcı için hataya açıktır. Label tabanlı branch sistemi ileride gerekebilir.

### 26.6 Runtime Şişme Riski

Her yeni özellik service olarak eklenirse runtime çok büyüyebilir. Bu durumda servis registry, namespace disiplini ve otomatik belge üretimi şart olur.

---

## 27. Programcı İçin İlk Eğitim Sırası

UXM öğrenmek isteyen biri sırayla şunları öğrenmelidir:

```text
1. Tape nedir?
2. Pointer nasıl hareket eder?
3. Hücre nasıl artırılır, azaltılır, sıfırlanır?
4. Karakter nasıl yazdırılır?
5. String nasıl tanımlanır ve yazdırılır?
6. Adresleme parantezi nasıl çalışır?
7. Stack push/pop nasıl kullanılır?
8. Macro nasıl tanımlanır?
9. @N service call nasıl çalışır?
10. Branch ve loop nasıl kurulur?
11. File/string/stat/matrix servisleri nasıl kullanılır?
12. Test nasıl yazılır?
13. Beklenen çıktı nasıl kontrol edilir?
14. Büyük program için bellek haritası nasıl hazırlanır?
```

Bu sırayı bozarsan UXM karmaşık görünür. Ama bu sırayla öğrenilirse dilin mantığı oturur.

---

## 28. Küçükten Büyüğe Program Tasarlama Yöntemi

UXM'de program yazarken şu form kullanılmalıdır:

```text
PROGRAM TASARIM FORMU

1. Amaç:
   Program ne yapacak?

2. Girdi:
   Veri nereden gelecek?
   Klavye mi, dosya mı, data segment mi, sabit değer mi?

3. Bellek Haritası:
   T+0 ne?
   T+1 ne?
   D:100 ne?
   SP ne için kullanılacak?

4. Servisler:
   Hangi @N servisleri gerekecek?

5. Çıktı:
   Sonuç nereye yazılacak?
   Ekrana mı, dosyaya mı, data segment'e mi?

6. Test:
   Beklenen çıktı ne?
   .expect dosyası ne olmalı?
```

Örnek:

```text
Amaç: A harfi yazdır.
Girdi: Yok.
Bellek: T+0 = ASCII kod.
Servis: Yok.
Çıktı: Ekran.
Test: çıktı A olmalı.
```

Kod:

```text
0+k65.
```

Büyük programlarda bu form çok daha önemlidir.

---

## 29. UXM'yi Yanlış Kullanma Biçimleri

UXM'de en sık yapılacak hatalar şunlardır:

| Hata                                       | Neden Kötü?                            | Doğru Yaklaşım                          |
| ------------------------------------------ | -------------------------------------- | --------------------------------------- |
| Bellek haritası yapmadan kod yazmak        | Hücreler çakışır.                      | Önce T/Data planı çıkar.                |
| Her şeyi tape üzerinde tutmak              | Büyük veri yönetimi zorlaşır.          | Büyük veri için Data segment kullan.    |
| Servis ID'lerini ezbere kullanmak          | Yanlış servis yanlış veriyle çağrılır. | Servis tablosu ve hücre sözleşmesi yaz. |
| Branch mesafesini elle tahmin etmek        | Hata üretir.                           | Küçük bloklarla test et.                |
| Stringleri aynı başlangıç hücresine koymak | Bellek çakışır.                        | String alanlarını ayır.                 |
| Test yazmadan servis eklemek               | Eski davranış bozulur.                 | Her servis için `.uxm + .expect` yaz.   |
| Runtime'ı sürekli büyütmek                 | Kaos yaratır.                          | Registry ve kategori disiplini kur.     |

---

## 30. Prompt 1 Sonucu

Bu ilk bölümde UXM'nin temel çalışma biçimi kuruldu. Buradan çıkan ana sonuç şudur:

UXM, Python veya BASIC gibi değişken isimleriyle rahat yazılan bir dil değildir. UXM, daha çok bir virtual machine üzerinde çalışan düşük seviyeli ama servislerle güçlendirilmiş bir programlama sistemidir. Programcı bellek haritası yapar, hücreleri planlar, komutları yazar, servisleri çağırır ve sonucu test eder.

Bu nedenle UXM öğrenmenin anahtarı şudur:

```text
Önce bellek düşün.
Sonra komut düşün.
Sonra servis düşün.
Sonra test et.
```

Bir sonraki bölüm yani Prompt 2'de komut seti ve adresleme sistemi en ince ayrıntısına kadar açıklanacaktır. Özellikle mutlak, göreli, dolaylı, indisli, stack-relative, data-relative ve pointer-register tabanlı adresleme biçimleri programcı gözüyle anlatılacaktır.
