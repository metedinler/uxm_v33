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

## 20. `@!N`, `@#`, `@!#`, `@(adres)`, `@!(adres)`

Parser koduna göre `@` sonrasında `!` gelirse `forceHost` aktif olur.

```text
@!128
```

Bu, eğer 128 numaralı kullanıcı macro tanımlı olsa bile host service çağrısını zorlar. Yani macro expansion yerine runtime service çağrısı yapmak için kullanılır.

`@#` ise dinamik meta çağrı mantığı taşır. Parser bunu `metaId = -1`, dynamic flag = 1 gibi işler. Bu yapı, çağrılacak service ID'nin runtime sırasında bir hücreden okunması için düşünülmüş görünür.

Basit anlatım (UXM-A standardı):

| Yazım       | Anlam                                                                    |
| ----------- | ------------------------------------------------------------------------ |
| `@N`        | N numaralı macro varsa macro, yoksa host service.                        |
| `@!N`       | Macro'yu atla, kesin host service çağır.                                 |
| `@#`        | Dinamik service çağrısı; servis ID aktif `T` hücresinden alınır.         |
| `@!#`       | Dinamik service çağrısı; servis ID aktif hücreden alınır, host zorlanır. |
| `@(adres)`  | Servis ID verilen adresten okunur, dinamik çağrı yapılır.                |
| `@!(adres)` | Servis ID verilen adresten okunur, host servis zorla çağrılır.           |

Standart disi formlar: `@#N`, `@@N`, `@*`.

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

---

# PROMPT 2 — Komut Seti ve Adresleme Sistemi

Bu bölüm UXM'nin en kritik kısmıdır. Çünkü UXM'nin gerçek gücü yalnızca `+ - < >` komutlarında değil, adresleme sisteminde ortaya çıkar. Birçok kişi UXM'yi ilk bakışta Brainfuck benzeri sanır. Fakat adresleme sistemi incelendiğinde bunun çok daha gelişmiş bir VM dili olduğu anlaşılır.

Bu bölüm dikkatli okunmalıdır.

Çünkü UXM'de program yazmayı gerçekten mümkün kılan şey:

* bellek düşünme,
* adresleme kurma,
* pointer mantığını anlama,
* doğru hedef hücreyi seçebilme

becerisidir.

---

# 1. UXM Komutlarının Genel Mantığı

UXM'de komutlar küçük sembollerden oluşur. Fakat bu semboller üç farklı seviyede çalışabilir:

| Seviye                            | Açıklama                   |
| --------------------------------- | -------------------------- |
| Aktif hücre üzerinde              | Varsayılan davranış        |
| Adreslenmiş hedef üzerinde        | `(T+N)` gibi adresleme ile |
| Runtime service çağrısı üzerinden | `@N` ile                   |

En önemli nokta şudur:

UXM'de komut ile adresleme birbirinden ayrıdır.

Örneğin:

```text
+
```

aktif hücreyi artırır.

Ama:

```text
+(T+5)
```

aktif pointer'ı hareket ettirmeden T+5 hücresini artırır.

Bu fark çok önemlidir.

---

# 2. Temel Komutlar Tablosu

Aşağıdaki tablo parser ve compiler kaynakları incelenerek oluşturulmuştur.

| Komut | İngilizce         | Anlam                           |            |
| ----- | ----------------- | ------------------------------- | ---------- |
| `>`   | move right        | Pointer'ı sağa kaydır           |            |
| `<`   | move left         | Pointer'ı sola kaydır           |            |
| `+`   | increment         | Hücreyi artır                   |            |
| `-`   | decrement         | Hücreyi azalt                   |            |
| `0`   | clear             | Hücreyi sıfırla                 |            |
| `.`   | output char       | Karakter yazdır                 |            |
| `,`   | input char        | Karakter oku                    |            |
| `[`   | loop start        | Döngü başlangıcı                |            |
| `]`   | loop end          | Döngü sonu                      |            |
| `;`   | nop/comment style | Boş/no-op amaçlı kullanılabilir |            |
| `:`   | branch            | Dallanma/koşullu atlama         |            |
| `@`   | meta/service call | Macro veya service çağrısı      |            |
| `!`   | force host        | Service çağrısını zorla         |            |
| `#`   | dynamic meta      | Dinamik service/macro çağrısı   |            |
| `sN`  | define string     | String tanımla                  |            |
| `pN`  | print string      | String yazdır                   |            |
| `mN`  | define macro      | Macro tanımla                   |            |
| `{}`  | block             | Macro/string gövdesi            |            |
| `+kN` | fast increment    | N kadar artır                   |            |
| `-kN` | fast decrement    | N kadar azalt                   |            |
| `?`   | compare/test      | Flag/condition işlemleri için   |            |
| `&`   | and               | Bitwise AND                     |            |
| `     | `                 | or                              | Bitwise OR |
| `^`   | xor               | Bitwise XOR                     |            |
| `~`   | not               | Bitwise NOT                     |            |
| `$`   | stack op          | Stack ilişkili işlemler         |            |
| `%`   | modulo/math       | Math/runtime ilişkili işlemler  |            |
| `e`   | status/error      | Status register erişimi         |            |

Bazı komutların anlamı runtime sürümüne göre genişleyebilir.

---

# 3. Aktif Hücre Mantığı

UXM'nin temel çalışma noktası aktif hücredir.

ASCII model:

```text
Tape:

Adres:    0    1    2    3    4
        +----+----+----+----+----+
Değer:  | 00 | 00 | 00 | 00 | 00 |
        +----+----+----+----+----+
Pointer:            ^
                    T
```

Burada aktif hücre `T+2` adresidir.

Şu komut:

```text
+
```

şunu yapar:

```text
Tape[2] = Tape[2] + 1
```

Şu komut:

```text
>
```

pointer'ı kaydırır:

```text
T = T + 1
```

Şu komut:

```text
<
```

pointer'ı sola kaydırır:

```text
T = T - 1
```

Bu BF kökenli ana mantıktır.

---

# 4. UXM Adresleme Sistemi Neden Gereklidir?

Sıradan Brainfuck'ta bir hücreye ulaşmak için pointer sürekli hareket eder.

Örneğin:

```text
>>>>>>+
```

Bu yaklaşım büyük programlarda çok kötü hale gelir.

Sorunlar:

* Kod okunamaz olur.
* Pointer kayar.
* Hangi hücrede olduğun unutulur.
* Büyük veri erişimi yavaşlar.
* Compiler optimizasyonu zorlaşır.

UXM bunu çözmek için adresleme sistemi getirir.

Bu nedenle UXM'de iki farklı düşünme biçimi vardır:

| Yaklaşım         | Açıklama                            |
| ---------------- | ----------------------------------- |
| Pointer moving   | `>>>><<<` tarzı klasik BF yaklaşımı |
| Addressed access | `(T+N)` gibi doğrudan hedef erişimi |

Gerçek UXM programlarında ikinci yaklaşım daha profesyoneldir.

---

# 5. Adresleme Parantezi Mantığı

UXM'de adresleme parantez içinde yazılır:

```text
( ... )
```

Komut hangi hedefe uygulanacaksa parantez içinde o hedef belirtilir.

Örnek:

```text
+(T+5)
```

Anlam:

```text
Tape[T+5] = Tape[T+5] + 1
```

Aktif pointer değişmez.

Bu çok önemlidir.

---

# 6. Adresleme Türleri Genel Tablosu

UXM'de görülen adresleme türleri:

| Tür              | İngilizce           | Örnek         |
| ---------------- | ------------------- | ------------- |
| Aktif hücre      | current cell        | `+`           |
| Göreli adresleme | relative addressing | `(T+5)`       |
| Negatif göreli   | negative relative   | `(T-3)`       |
| Mutlak tape      | absolute tape       | `(T:100)`     |
| Data relative    | data relative       | `(D+8)`       |
| Data absolute    | absolute data       | `(D:200)`     |
| Stack relative   | stack relative      | `(SP-1)`      |
| Pointer indexed  | indexed/base+index  | `(T:BASE+P)`  |
| Tape indirect    | tape indirect       | `(T@D)`       |
| Data indirect    | data indirect       | `(D@T)`       |
| Double indirect  | double indirect     | `(D@(T-2)+4)` |
| Pointer register | pointer register    | `(P)`         |
| Status register  | status register     | `(E)`         |
| Flag register    | flags register      | `(F)`         |

Bu sistem UXM'yi sıradan BF'den tamamen ayırır.

---

# 7. Göreli Adresleme (Relative Addressing)

Bu en temel UXM adresleme türüdür.

Biçim:

```text
(T+N)
(T-N)
```

Anlam:

aktif pointer'ın sağındaki veya solundaki hücre.

Örnek:

```text
+(T+1)
```

Anlam:

```text
Tape[T+1]++
```

Bellek görünümü:

```text
Adres:    T-1  T+0  T+1  T+2
        +----+----+----+----+
Değer:  | 00 | 10 | 05 | 00 |
        +----+----+----+----+
                 ^
                 T
```

Komut:

```text
+(T+1)
```

Sonuç:

```text
Adres:    T-1  T+0  T+1  T+2
        +----+----+----+----+
Değer:  | 00 | 10 | 06 | 00 |
        +----+----+----+----+
                 ^
                 T
```

Pointer hareket etmedi.

Bu, UXM'nin en güçlü taraflarından biridir.

---

# 8. Mutlak Adresleme (Absolute Addressing)

Biçim:

```text
(T:100)
```

Anlam:

Tape içindeki kesin 100 numaralı hücre.

Bu pointer'dan bağımsızdır.

Örnek:

```text
0(T:100)+k65.
```

Bu yapı özellikle:

* global veri,
* sabit tablolar,
* font verisi,
* lookup table,
* matrix başlangıç adresi,
* tensor descriptor

alanlarında kullanılır.

Python benzetmesi:

```python
mem[100] = 65
```

---

# 9. Data Segment Adresleme

UXM'de Tape dışında Data segment vardır.

Bu büyük veriler için düşünülmüştür.

Biçimler:

```text
(D+N)
(D:100)
```

Örnek:

```text
0(D:200)+k10
```

Anlam:

```text
Data[200] = 10
```

Data segment özellikle:

* matrix,
* tensor,
* dataset,
* string buffer,
* file buffer,
* AI vector,
* sparse structure

alanları için uygundur.

ASCII:

```text
Tape  -> küçük hızlı çalışma alanı
Data  -> büyük yapılandırılmış veri alanı
```

---

# 10. Stack Relative Addressing

Biçim:

```text
(SP)
(SP-1)
(SP+2)
```

Burada `SP` stack pointer'dır.

Örnek:

```text
+(SP-1)
```

Anlam:

stack üzerindeki son elemanın bir altındaki hücreyi artır.

Bu özellikle:

* function frame,
* geçici değişken,
* recursive macro,
* expression evaluation

alanlarında önemlidir.

BASIC/Python bilen biri için stack mantığı başta zor olabilir.

Basit anlatım:

```text
Stack:

SP -> son eklenen veri
```

`SP-1` bir önceki veridir.

---

# 11. Pointer Register Adresleme

UXM'de `P` genel amaçlı pointer/index register gibi kullanılabilir.

Biçim:

```text
(P)
(T:BASE+P)
(D:BASE+P)
```

Örnek:

```text
+(T:100+P)
```

Anlam:

```text
Tape[100 + P]++
```

Bu gerçek indexed addressing'dir.

Assembly benzeri düşün:

```asm
MOV [BASE + INDEX], value
```

UXM bunu düşük seviyede sağlayabilir.

Bu yapı özellikle:

* array dolaşma,
* matrix satır/sütun erişimi,
* tensor indexing,
* string parsing,
* CSV işleme

alanlarında çok güçlüdür.

---

# 12. Dolaylı Adresleme (Indirect Addressing)

Bu UXM'nin ileri seviye özelliklerinden biridir.

Biçim:

```text
(D@T)
(T@D)
```

Mantık:

Bir hücrede adres tutulur.
Sonra gerçek veri o adresten okunur.

Örnek:

```text
Tape[T] = 200
```

Şimdi:

```text
+(D@T)
```

şu anlama gelir:

```text
Data[ Tape[T] ]++
```

Yani:

```text
Data[200]++
```

Bu pointer-to-pointer mantığıdır.

Python benzetmesi:

```python
addr = mem[T]
data[addr] += 1
```

Bu çok güçlüdür.

Çünkü:

* linked list,
* sparse matrix,
* graph,
* dynamic structure,
* AI graph node,
* runtime object table

kurulabilir.

---

# 13. Çift Dolaylı Adresleme (Double Indirect)

Parser örneklerinde görülen:

```text
(D@(T-2)+N)
```

Bu çok ileri seviye yapıdır.

Anlam:

1. Önce `(T-2)` hücresini oku.
2. Oradaki değeri adres olarak kullan.
3. Data segment içinde o adrese git.
4. Üzerine N ekle.

Bu neredeyse gerçek pointer arithmetic seviyesidir.

ASCII:

```text
Tape[T-2] -> 500

Gerçek hedef:

Data[500 + N]
```

Bu yapı:

* object table,
* runtime descriptor,
* tensor block,
* sparse row,
* graph edge list

kurmak için çok değerlidir.

---

# 14. İndisli Adresleme (Indexed Addressing)

İndisli adresleme özellikle array ve matrix için önemlidir.

Biçim:

```text
(T:BASE+P)
(D:BASE+P)
```

Örnek:

```text
0(D:100+P)+k1
```

Anlam:

```text
Data[100 + P] = 1
```

Şimdi düşün:

```text
P = 0
P = 1
P = 2
...
```

Bu şekilde array dolaşılır.

Python karşılığı:

```python
arr[100 + i] = 1
```

UXM karşılığı:

```text
0(D:100+P)+k1
```

Bu yüzden `P` register'ı çok önemlidir.

---

# 15. İvedi / Immediate Mantığı

Senin tarif ettiğin “ivedi” kavramı assembly'deki immediate value mantığına yakındır.

UXM'de bunun karşılığı genelde:

```text
+kN
-kN
```

şeklinde görülür.

Örneğin:

```text
+k65
```

Doğrudan sabit değer ekler.

Bu:

```asm
ADD CELL, 65
```

benzeri düşünülmelidir.

BASIC/Python tarafında:

```python
x += 65
```

Immediate yani ivedi değer, doğrudan kod içinde yazılan sabittir.

---

# 16. Flag ve Status Mantığı

UXM'de `E` ve `F` alanları vardır.

| Alan | Amaç                     |
| ---- | ------------------------ |
| `E`  | status/error code        |
| `F`  | arithmetic/compare flags |

Karşılaştırma sonrası branch bunlara göre çalışabilir.

Örnek:

```text
:z+5
```

Zero flag set ise 5 instruction ileri git.

Bu assembly mantığına yakındır:

```asm
JZ +5
```

---

# 17. Branch Sistemi Detaylı Açıklama

UXM'de branch instruction offset ile çalışır.

Bu şu demektir:

```text
::+5
```

5 instruction ileri atlar.

Bu label değil, offset mantığıdır.

ASCII:

```text
0: +
1: +
2: ::+3
3: -
4: -
5: -
6: .
```

Instruction 2 çalışınca:

```text
2 + 3 = 5
```

hedefine gider.

Bu çok güçlü ama dikkat ister.

---

# 18. Loop Sistemi

Klasik BF loop yapısı korunmuştur.

```text
[
]
```

Mantık:

```text
[
  aktif hücre sıfır değilse devam et
]
```

Örnek:

```text
+k5
[
  .
  -
]
```

Bu:

* hücre sıfır olana kadar karakter yazdırır.

Gerçek kullanımlarda loop genellikle adresleme ve servislerle birlikte kullanılır.

---

# 19. String Komutları

String sistemi parser içinde özel işlenir.

Tanım:

```text
s1=0,{Merhaba}
```

Yazdırma:

```text
p1
```

String ID:

```text
1..255
```

arasında olabilir.

Escape destekleri:

| Escape | Anlam           |
| ------ | --------------- |
| `      |                 |
| `      | newline         |
| `      |                 |
| `      | carriage return |
| `	`    | tab             |
| `\`    | backslash       |
| `\{`   | `{`             |
| `\}`   | `}`             |

---

# 20. Macro Sistemi Detaylı

Macro sistemi UXM'nin gücünü ciddi artırır.

Tanım:

```text
m128={...}
```

Çağrı:

```text
@128
```

Önemli:

* Macro expansion compile-time çalışır.
* Runtime service call çalışma zamanında çalışır.

Bu fark çok önemlidir.

---

# 21. Komutların Birleşik Kullanımı

Gerçek UXM programları küçük komutlardan büyük yapı kurar.

Örnek:

```text
# Data[100] = 65
0(D:100)+k65

# Data[100] yazdır
.(D:100)
```

Başka örnek:

```text
# Array doldurma
0(P)

0(D:100+P)+k1
0(D:101+P)+k2
0(D:102+P)+k3
```

Bu şekilde array/matrix düşünülür.

---

# 22. BASIC ve Python ile Adresleme Karşılaştırması

Python:

```python
arr[5] += 1
```

UXM:

```text
+(D:5)
```

Python:

```python
arr[i] += 1
```

UXM:

```text
+(D:BASE+P)
```

Python:

```python
x = arr[indexes[i]]
```

UXM:

```text
+(D@T)
```

Bu nedenle UXM öğrenirken programcı:

* array indexing,
* pointer arithmetic,
* memory layout

konularını öğrenmiş olur.

---

# 23. UXM Adresleme Sisteminin Güçlü Yanları

### 23.1 Pointer Hareketi Azalır

Bu hem okunabilirlik hem performans açısından iyidir.

### 23.2 Büyük Veri Yapıları Kurulabilir

Matrix/tensor/sparse yapı mümkün olur.

### 23.3 Runtime Daha Akıllı Çalışabilir

Compiler doğrudan hedef adresi bilir.

### 23.4 Assembly Benzeri Güç Sağlar

Ama syntax daha küçüktür.

---

# 24. UXM Adresleme Sisteminin Riskleri

### 24.1 Öğrenmesi Zordur

Yeni başlayan için `(D@(T-2)+4)` korkutucu görünür.

### 24.2 Pointer Hataları Olabilir

Yanlış adres büyük hata yaratabilir.

### 24.3 Güçlü Ama Karmaşık

Dil küçük görünür ama semantiği büyüktür.

### 24.4 Belgeleme Şarttır

Adresleme tabloları olmadan büyük program okunamaz.

---

# 25. UXM'de Profesyonel Programcı Nasıl Çalışır?

Gerçek UXM programcısı:

1. Önce bellek haritası çizer.
2. Sonra adresleme planı yapar.
3. Sonra servisleri seçer.
4. Sonra küçük testler yazar.
5. Sonra branch/loop kurar.
6. Sonra `.expect` dosyası üretir.

Yani UXM'de önce kod yazılmaz.
Önce veri düzeni tasarlanır.

Bu çok önemli zihniyet farkıdır.

---

# 26. Prompt 2 Sonucu

Bu bölümde UXM'nin gerçek gücünün adresleme sisteminden geldiği görüldü.

Özellikle:

* relative,
* absolute,
* data-relative,
* stack-relative,
* indexed,
* indirect,
* double-indirect

adresleme türleri UXM'yi sıradan BF türevlerinden ayırır.

Bu sistem sayesinde UXM:

* array,
* matrix,
* tensor,
* sparse structure,
* graph,
* runtime descriptor,
* AI execution graph

kurabilecek seviyeye yaklaşır.

Bir sonraki bölüm yani Prompt 3'te runtime servis sistemi ayrıntılı olarak anlatılacaktır. Özellikle file I/O, string, statistics, matrix, floating point, probability, numerical methods, complex numbers, bio ve ML/data pipeline servisleri tablolar ve örneklerle işlenecektir.

---

# PROMPT 3 — Runtime Service Sistemi, Servis Tabloları ve Kullanım Mantığı

Bu bölüm UXM kılavuzunun en kritik ikinci bölümüdür. Prompt 2'de komutları ve adresleme sistemini anlattık. Fakat UXM'yi gerçekten güçlü yapan şey yalnızca komutlar değildir. UXM'nin asıl genişleme gücü `@N` ile çağrılan runtime service sistemidir.

Bu bölümde servisler ezbere değil, paketteki gerçek `config/uxm/service_registry_merged.csv`, `uxm/core/runtime/runtime_meta_dispatch.bas`, `uxm/core/runtime/hooks/runtime_hook_dispatch_ext.bas` ve `uxm/core/runtime/services/*.bas` dosyalarının yapısına göre anlatılır.

Önce dürüst bir tespit yapılmalıdır: UXMv33 içinde servis kayıt sistemi oldukça geniştir, ancak bazı servis aralıklarında çakışma, patch gereksinimi veya dispatcher erişim sorunu vardır. Bu kötü bir şey değildir; deneysel dil geliştirmede normaldir. Ama kullanım kılavuzunda bu açıkça yazılmazsa programcı yanlış servis ID'si çağırır ve dili bozuk zanneder.

Bu nedenle bu bölümde her servis ailesi şu dört gözle okunmalıdır:

| Durum                                                  | Anlamı                                                                                             |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| `current`                                              | Ana dispatcher tarafından doğrudan çalışan mevcut servis.                                          |
| `stage9`, `v3.3-stage10-active`, `v3.3-stage12-active` | Belirli stage ile aktif hale gelmiş servis ailesi.                                                 |
| `extension_requires_meta_id_range_patch`               | Registry'de var ama dispatcher/range entegrasyonu dikkat ister.                                    |
| `reserved`                                             | İsim ayrılmış ama gerçek işlev henüz yok veya kullanılmamalı.                                      |
| `unreachable_current_bug`                              | Kodda case var ama dispatcher o ID aralığını ilgili fonksiyona göndermiyor.                        |
| `active`                                               | Registry aktif diyor; fakat frame/result boşsa gerçek kullanım için servis dosyası incelenmelidir. |

UXM programcısı için en sağlıklı yaklaşım şudur:

```text
1. Önce servis ID'sini registry'den kontrol et.
2. Sonra runtime_meta_dispatch.bas içinde o ID nereye gidiyor bak.
3. Sonra ilgili runtime/services/*.bas dosyasındaki frame düzenini kontrol et.
4. En son küçük bir .uxm + .expect testi yaz.
```

Bu kural özellikle UXMv33 için çok önemlidir.

---

# 1. Runtime Service Çağrısı Nedir?

UXM'de service çağrısı şu biçimdedir:

```text
@N
```

Burada `N` servis numarasıdır.

Örnek:

```text
@5
```

5 numaralı servisi çağırır. Registry'ye göre `@5` `NEWLINE` servisidir ve ekrana yeni satır basar.

Daha büyük örnek:

```text
@160
```

160 numaralı servisi çağırır. Bu `MAT_INIT` servisidir ve matrix başlatmak için kullanılır.

Service call mantığı şöyle çalışır:

```text
UXM kaynak kodu
     |
     v
@N görülür
     |
     v
metaId = N
     |
     v
ux_meta_call_ex(metaId)
     |
     v
runtime dispatcher
     |
     +--> core
     +--> arithmetic
     +--> math
     +--> file
     +--> matrix
     +--> tensor
     +--> bio
     +--> ML/data pipeline
```

ASCII şema:

```text
+------------------+
| UXM kodu: @160   |
+--------+---------+
         |
         v
+------------------+
| metaId = 160     |
+--------+---------+
         |
         v
+-----------------------------+
| runtime_meta_dispatch.bas   |
+--------+--------------------+
         |
         v
+------------------+
| MetaMatrix(160)  |
+--------+---------+
         |
         v
+------------------+
| MAT_INIT         |
+------------------+
```

---

# 2. UXM Service Calling Convention

Bir servis çağrılmadan önce giriş değerleri tape üzerinde belirli hücrelere yerleştirilir. Çoğu servis şu çerçeveyi kullanır:

```text
T-4 : parametre 1
T-3 : parametre 2
T-2 : parametre 3
T-1 : parametre 4
T   : parametre 5 veya aktif değer
T+1 : sonuç veya status
```

Bu yüzden servis kullanımı, fonksiyon çağırmaya benzer ama argümanlar değişken isimleriyle değil, hücrelerle verilir.

Python'da şöyle yazılan şey:

```python
sonuc = add(a, b)
```

UXM'de şu mantığa döner:

```text
T-2 = a
T-1 = b
@20
T+1 = sonuc
```

Örnek:

```text
# 7 + 8 hesapla
0(T-2)+k7
0(T-1)+k8
@20
@61
```

Çözümleme:

| Satır       | Anlamı                            |
| ----------- | --------------------------------- |
| `0(T-2)+k7` | Birinci sayıyı T-2 hücresine koy. |
| `0(T-1)+k8` | İkinci sayıyı T-1 hücresine koy.  |
| `@20`       | ADD servisini çağır.              |
| `@61`       | Sonucu decimal yazdır.            |

Bu örnek Python'daki şu koda karşılık gelir:

```python
print(7 + 8)
```

UXM'de önemli olan şey şudur: servis çağrısından önce hücreleri doğru doldurmazsan servis yanlış çalışır.

---

# 3. Dispatcher Haritası

UXMv33 ana dispatcher kabaca şu aralıkları kullanır:

| ID Aralığı | Dispatcher Hedefi                           | Ana Aile                              |
| ---------: | ------------------------------------------- | ------------------------------------- |
|    `0..19` | `MetaCore`                                  | core                                  |
|   `20..39` | `MetaArithmetic`                            | arithmetic                            |
|   `40..59` | `MetaMath`                                  | math                                  |
|   `60..79` | `MetaIO`                                    | input/output                          |
|   `80..89` | `MetaPointerMemory`                         | pointer/memory layout                 |
|  `90..127` | `MetaFifoDataSortWild`                      | FIFO, data, sort, mode                |
| `150..159` | `MetaFlagsEndian`                           | endian/word/dword                     |
| `160..199` | `MetaMatrix`                                | matrix ve matrix advanced patch alanı |
| `200..239` | `MetaFloatingPoint`                         | floating point                        |
| `240..254` | `MetaMathExtra`                             | polynomial / numerical small set      |
| `260..299` | `MetaStatistics` veya `MetaStatsNumericV19` | statistics                            |
| `300..319` | `MetaString`                                | string temel servisleri               |
| `320..325` | hook üzerinden `MetaPosthocRealV18`         | posthoc                               |
| `340..356` | hook üzerinden `MetaAIRealV18`              | AI metrics / normalize                |
| `357..359` | `MetaStringExt`                             | string extra                          |
| `360..369` | `MetaProbability`                           | probability v1                        |
| `370..379` | `MetaStringExt`                             | string extra                          |
| `380..389` | `MetaProbability`                           | probability stage9                    |
| `390..399` | `MetaNumericMethods`                        | numeric methods                       |
| `400..415` | `MetaFile`                                  | file I/O canonical range              |
| `416..419` | hook üzerinden `MetaFileExtRealV18`         | file reserved/status ext              |
| `420..439` | `MetaNumericMethods`                        | numerical stage9                      |
| `440..459` | `MetaComplex`                               | complex                               |
| `480..511` | `MetaBio`                                   | bio/codon/protein                     |
| `512..519` | `MetaMatrixAdvancedTensor`                  | matrix advanced                       |
| `520..539` | `MetaLinalgAdvanced`                        | linalg advanced                       |
| `540..599` | `MetaMatrixAdvancedTensor`                  | tensor basic/advanced                 |
| `600..679` | `MetaSparseVector`                          | sparse vector                         |
| `700..759` | `MetaMLDataPipeline`                        | ML/data pipeline                      |
| `760..769` | hook üzerinden hypothesis                   | hypothesis tests                      |
| `790..795` | hook üzerinden posthoc                      | posthoc aliases                       |
| `810..823` | hook üzerinden AI                           | AI aliases/metrics                    |

Burada dikkat edilmesi gereken çakışmalar vardır:

1. `@130..@149` registry'de compare/flag olarak görünür, fakat dispatcher bu aralığı `MetaFlagsEndian` fonksiyonuna göndermiyor. Bu yüzden registry bu aralık için `unreachable_current_bug` demektedir.
2. `@300..@309` registry'de hypothesis gibi görünse de dispatcher `@300..@319` aralığını string servisine yollar. Hypothesis'in güvenli çalışan hook aralığı `@760..@769` görünmektedir.
3. `@400..@401` registry'de numeric reserved satırları da vardır ama dispatcher `@400..@415` aralığını file servisine gönderir. Bu nedenle `@400` ve `@401` file open servisleri olarak düşünülmelidir.
4. `@420` ve `@421` registry'de file flush / binary append gibi görünse de dispatcher `@420..@439` aralığını numeric methods'a gönderir. Bu yüzden `@420` ve `@421` için file anlamına güvenilmemelidir; numeric anlamı baskındır.

Bu gerçekleri saklamamak gerekir. UXMv33 için en doğru kullanım, dispatcher gerçekliğine uygun servis kullanmaktır.

---

# 4. Core Servisleri — `@0..@15`

Core servisleri sistem durumu, ekran temizleme, newline, random byte, timer ve status işlemleri için kullanılır.

|    ID | Ad                      | Amaç                                | Sonuç                 |
| ----: | ----------------------- | ----------------------------------- | --------------------- |
|  `@0` | `NOP_STATUS_OK`         | İş yapmadan status OK yapar.        | status OK             |
|  `@1` | `CLS`                   | Ekranı temizler.                    | çıktı etkisi          |
|  `@2` | `LOCATE_HOME`           | Cursor'ı 1,1 konumuna alır.         | çıktı etkisi          |
|  `@3` | `RANDOM_BYTE`           | Rastgele byte üretir.               | `T+1=random byte`     |
|  `@4` | `TIMER_MS`              | Milisaniye timer değeri üretir.     | `T+1=timer ms masked` |
|  `@5` | `NEWLINE`               | Yeni satır basar.                   | çıktı                 |
|  `@6` | `PRINT_META_PREFIX`     | `[UXM META]` prefix basar.          | çıktı                 |
|  `@7` | `CONST_7`               | Sabit 7 üretir.                     | `T+1=7`               |
|  `@8` | `CONST_8`               | Sabit 8 üretir.                     | `T+1=8`               |
|  `@9` | `GET_STATUS`            | Runtime status değerini okur.       | `T+1=ux_status`       |
| `@10` | `STATUS_OK`             | Status OK yapar.                    | status OK             |
| `@11` | `SET_STATUS_ARG1`       | Arg1 düşük byte ile status ayarlar. | status değişir        |
| `@12` | `PRINT_STATUS`          | Status mesajı basar.                | çıktı                 |
| `@13` | `STATUS_ASSERT_NONZERO` | Status kontrolü yapar.              | status/result         |
| `@14` | `CLEAR_STATUS`          | Status OK yapar.                    | status OK             |
| `@15` | `GET_ERROR_FLAG`        | Hata flag durumunu okur.            | `T+1=1/0`             |

Örnek:

```text
# İki satır yazdırma
s1=0,{Birinci satir}
s2=32,{Ikinci satir}
p1
@5
p2
@5
```

Burada `@5` Python'daki `print()` sonundaki newline gibi düşünülebilir.

---

# 5. Arithmetic Servisleri — `@20..@36`

Bu servisler temel tamsayı işlemleridir.

Genel frame:

```text
T-2 = Arg1
T-1 = Arg2
T   = Arg0 veya ek parametre
T+1 = result
```

|    ID | Ad                   | Amaç                    |
| ----: | -------------------- | ----------------------- |
| `@20` | `ADD`                | Toplama                 |
| `@21` | `SUB`                | Çıkarma                 |
| `@22` | `MUL`                | Çarpma                  |
| `@23` | `DIV`                | Bölme                   |
| `@24` | `MOD`                | Mod alma                |
| `@25` | `MIN`                | Küçük olanı seçme       |
| `@26` | `MAX`                | Büyük olanı seçme       |
| `@27` | `ABS_ARG2`           | Mutlak değer            |
| `@28` | `NEG_ARG2`           | Negatifini alma         |
| `@29` | `CMP`                | Karşılaştırma           |
| `@30` | `RANDOM_INT_RANGE`   | Aralıkta random integer |
| `@31` | `RANDOM_SEED`        | Random seed ayarlama    |
| `@32` | `RANDOM_SCALED`      | Ölçekli random üretme   |
| `@33` | `DIV_UNSIGNED_ALIAS` | Unsigned bölme alias    |
| `@34` | `DIV_SIGNED`         | Signed bölme            |
| `@35` | `MOD_UNSIGNED_ALIAS` | Unsigned mod alias      |
| `@36` | `MOD_SIGNED`         | Signed mod              |

Örnek: 12 * 5 hesaplama.

```text
# 12 * 5 = 60
0(T-2)+k12
0(T-1)+k5
@22
@61
@5
```

Python karşılığı:

```python
print(12 * 5)
```

BASIC karşılığı:

```basic
PRINT 12 * 5
```

UXM'de `@22` doğrudan çarpma fonksiyonu gibi davranır, fakat argümanlar hücrelerden alınır.

---

# 6. Math Servisleri — `@40..@59`

Bu servisler trigonometrik ve matematiksel fonksiyonlar içindir. Bazıları scaled yani ölçeklenmiş değerlerle çalışır.

|    ID | Ad                  | Amaç                                 |
| ----: | ------------------- | ------------------------------------ |
| `@40` | `SIN_SCALED_DEG`    | Derece cinsinden sinüs, scaled sonuç |
| `@41` | `COS_SCALED_DEG`    | Derece cinsinden kosinüs             |
| `@42` | `TAN_SCALED_DEG`    | Derece cinsinden tanjant             |
| `@43` | `HYPOTENUSE`        | Hipotenüs hesabı                     |
| `@44` | `ASIN_DEG`          | Ark sinüs derece                     |
| `@45` | `ACOS_DEG`          | Ark kosinüs derece                   |
| `@46` | `SQRT`              | Karekök                              |
| `@47` | `SINH_SCALED`       | Hiperbolik sinüs                     |
| `@48` | `COSH_SCALED`       | Hiperbolik kosinüs                   |
| `@49` | `TANH_SCALED`       | Hiperbolik tanjant                   |
| `@52` | `ASINH_SCALED`      | Inverse hiperbolik sinüs             |
| `@53` | `ACOSH_SCALED`      | Inverse hiperbolik kosinüs           |
| `@54` | `ATANH_SCALED`      | Inverse hiperbolik tanjant           |
| `@55` | `LN_SCALED`         | Doğal logaritma                      |
| `@56` | `EXP_SCALED`        | Üstel fonksiyon                      |
| `@57` | `POWER`             | Kuvvet alma                          |
| `@58` | `DEG_TO_RAD_SCALED` | Dereceyi radyana çevirme             |
| `@59` | `RAD_TO_DEG`        | Radyanı dereceye çevirme             |

Örnek: karekök.

```text
# sqrt(81)
0(T-1)+k81
@46
@61
@5
```

Bu servislerde kesin frame bazı servislerde değişebilir. Kılavuz açısından ana kullanım şudur: giriş değerini uygun argüman hücresine yerleştir, `@46` gibi servisi çağır, sonucu `T+1` üzerinden oku.

---

# 7. I/O Servisleri — `@60..@69`

Bu servisler sayı yazdırma, sayı okuma ve formatlı çıktı içindir.

|    ID | Ad                        | Amaç                                 |
| ----: | ------------------------- | ------------------------------------ |
| `@60` | `PRINT_ARG2_DECIMAL`      | Arg2 değerini decimal yazdırır.      |
| `@61` | `PRINT_RESULT_DECIMAL`    | Sonuç değerini decimal yazdırır.     |
| `@62` | `PRINT_STACK_POP_DECIMAL` | Stack'ten pop edip decimal yazdırır. |
| `@63` | `READ_DECIMAL`            | Decimal sayı okur.                   |
| `@64` | `PRINT_SPACE`             | Boşluk basar.                        |
| `@67` | `PRINT_ARG2_HEX`          | Arg2 değerini hex yazdırır.          |
| `@68` | `PRINT_ARG2_BIN`          | Arg2 değerini binary yazdırır.       |
| `@69` | `PRINT_ARG2_CHAR`         | Arg2 değerini karakter yazdırır.     |

Örnek:

```text
0(T-2)+k65
@69
@5
```

Bu `A` karakterini basmalıdır. Çünkü ASCII 65 `A` karakteridir.

---

# 8. Pointer ve Memory Layout Servisleri — `@80..@89`

Bu servisler pointer ve runtime bellek yapısı hakkında bilgi verir veya pointer ayarlar.

|    ID | Ad                   | Amaç                             |
| ----: | -------------------- | -------------------------------- |
| `@80` | `PTR_SET`            | Pointer değerini ayarlama        |
| `@81` | `PTR_ADD`            | Pointer'a ekleme                 |
| `@82` | `PTR_GET`            | Pointer değerini okuma           |
| `@83` | `PTR_VALID`          | Pointer geçerli mi kontrol etme  |
| `@84` | `LAYOUT_TAPE_CELLS`  | Tape hücre sayısını okuma        |
| `@85` | `LAYOUT_DATA_CELLS`  | Data hücre sayısını okuma        |
| `@86` | `LAYOUT_STACK_CELLS` | Stack hücre sayısını okuma       |
| `@87` | `LAYOUT_CELL_BITS`   | Hücre bit sayısını okuma         |
| `@88` | `LAYOUT_CELL_BYTES`  | Hücre byte sayısını okuma        |
| `@89` | `LAYOUT_PRINT`       | Bellek layout bilgisini yazdırma |

Bu servisler özellikle debug için değerlidir. Bir UXM programının hangi bellek modeliyle çalıştığını anlamak için `@89` kullanılabilir.

Örnek:

```text
# Runtime bellek yerleşimini yazdır
@89
@5
```

---

# 9. FIFO, Data, Sort ve Mode Servisleri — `@90..@127`

Bu servis ailesi UXM runtime'ın veri taşıma ve basit veri işleme tarafıdır.

|     ID | Ad                           | Amaç                                     |
| -----: | ---------------------------- | ---------------------------------------- |
|  `@90` | `FIFO_PUSH`                  | Queue/FIFO içine veri atar.              |
|  `@91` | `FIFO_POP`                   | FIFO'dan veri alır.                      |
|  `@92` | `FIFO_PEEK`                  | FIFO başını silmeden okur.               |
|  `@93` | `FIFO_COUNT`                 | FIFO eleman sayısını verir.              |
|  `@94` | `FIFO_CLEAR`                 | FIFO'yu temizler.                        |
|  `@95` | `DATA_READ`                  | Data segment'ten okur.                   |
|  `@96` | `DATA_WRITE`                 | Data segment'e yazar.                    |
|  `@97` | `DATA_DIGIT_ASCII_TO_NUMBER` | ASCII rakamı sayıya çevirir.             |
|  `@98` | `DATA_BLOCK_COPY`            | Data blok kopyalama.                     |
|  `@99` | `DATA_BLOCK_CLEAR`           | Data blok temizleme.                     |
| `@100` | `TAPE_SORT_ASC`              | Tape aralığını küçükten büyüğe sıralar.  |
| `@101` | `TAPE_SORT_DESC`             | Tape aralığını büyükten küçüğe sıralar.  |
| `@102` | `DATA_SORT_ASC`              | Data aralığını küçükten büyüğe sıralar.  |
| `@103` | `DATA_SORT_DESC`             | Data aralığını büyükten küçüğe sıralar.  |
| `@104` | `TAPE_LINEAR_SEARCH`         | Tape üzerinde linear search.             |
| `@105` | `DATA_LINEAR_SEARCH`         | Data üzerinde linear search.             |
| `@106` | `TAPE_BLOCK_COPY`            | Tape blok kopyalama.                     |
| `@107` | `TAPE_BLOCK_CLEAR`           | Tape blok temizleme.                     |
| `@120` | `SIGNED_MODE_OFF`            | Signed modu kapatır.                     |
| `@121` | `SIGNED_MODE_ON`             | Signed modu açar.                        |
| `@122` | `SIGNED_MODE_GET`            | Signed mode durumunu okur.               |
| `@123` | `ENDIAN_LITTLE`              | Little endian seçer.                     |
| `@124` | `ENDIAN_BIG`                 | Big endian seçer.                        |
| `@125` | `ENDIAN_GET_BIG`             | Big endian aktif mi okur.                |
| `@126` | `FLAGS_GET`                  | Flags değerini alır.                     |
| `@127` | `WILD_LAYOUT_CHANGE`         | Bellek layout değişimi için wild servis. |

FIFO mantığı Python'daki `queue.Queue` veya liste kuyruğuna benzer.

Python:

```python
q.append(65)
x = q.pop(0)
```

UXM mantığı:

```text
T-1 = 65
@90   # FIFO_PUSH
@91   # FIFO_POP -> T+1
```

---

# 10. Flags Compare Sorunu — `@130..@149`

Registry'de `@130..@149` arasında compare ve flag servisleri görünür:

|   ID Aralığı | Amaç                                    | Durum                     |
| -----------: | --------------------------------------- | ------------------------- |
| `@130..@135` | signed/unsigned compare                 | `unreachable_current_bug` |
| `@140..@149` | carry/overflow/zero/sign flag işlemleri | `unreachable_current_bug` |

Bu şu anlama gelir: ilgili `Case` blokları kodda var gibi görünse de dispatcher `@130..@149` aralığını `MetaFlagsEndian` fonksiyonuna göndermiyor. Bu yüzden bu servisler doğrudan güvenilir kullanım listesine alınmamalıdır.

Doğru yaklaşım:

```text
@130..@149 kullanma.
Önce dispatcher patch yapılmalı.
Sonra test yazılmalı.
```

Bu kılavuzda bu alan bilinçli olarak problemli alan olarak işaretlenmiştir.

---

# 11. Endian Servisleri — `@150..@156`

Bu servisler byte sırası, word/dword okuma-yazma için kullanılır.

|     ID | Ad                     | Amaç                      |
| -----: | ---------------------- | ------------------------- |
| `@150` | `ENDIAN_LITTLE_ALIAS`  | Little endian seçer.      |
| `@151` | `ENDIAN_BIG_ALIAS`     | Big endian seçer.         |
| `@152` | `ENDIAN_GET_BIG_ALIAS` | Big endian durumunu okur. |
| `@153` | `WRITE_WORD_ENDIAN`    | Word yazar.               |
| `@154` | `READ_WORD_ENDIAN`     | Word okur.                |
| `@155` | `WRITE_DWORD_ENDIAN`   | DWord yazar.              |
| `@156` | `READ_DWORD_ENDIAN`    | DWord okur.               |

Bu servis ailesi binary file, network data, packed structure ve low-level memory işlemleri için önemlidir.

---

# 12. Matrix Servisleri — `@160..@176`

Matrix servisleri UXM'nin bilimsel hesap tarafının temelidir.

Genel frame:

```text
T-4 = dst veya matrix base
T-3 = a veya row
T-2 = b veya col
T-1 = p1 veya value
T   = p2
T+1 = status/result
```

|     ID | Ad                   | Amaç                             |
| -----: | -------------------- | -------------------------------- |
| `@160` | `MAT_INIT`           | Matrix başlatır.                 |
| `@161` | `MAT_CLEAR`          | Matrix temizler.                 |
| `@162` | `MAT_SET`            | Matrix hücresine değer yazar.    |
| `@163` | `MAT_GET`            | Matrix hücresinden değer okur.   |
| `@164` | `MAT_FILL`           | Matrix'i sabit değerle doldurur. |
| `@165` | `MAT_COPY`           | Matrix kopyalar.                 |
| `@166` | `MAT_PRINT`          | Matrix yazdırır.                 |
| `@167` | `MAT_ADD`            | Matrix toplama.                  |
| `@168` | `MAT_SUB`            | Matrix çıkarma.                  |
| `@169` | `MAT_SCALAR_MUL`     | Skaler çarpma.                   |
| `@170` | `MAT_MUL`            | Matrix çarpımı.                  |
| `@171` | `MAT_TRANSPOSE_COPY` | Transpose kopyalama.             |
| `@172` | `MAT_IDENTITY`       | Birim matrix üretme.             |
| `@173` | `MAT_TRACE`          | Trace hesabı.                    |
| `@174` | `MAT_SHAPE`          | Matrix boyut bilgisi.            |
| `@175` | `MAT_DET2`           | 2x2 determinant.                 |
| `@176` | `MAT_PRINT_RAW`      | Ham matrix yazdırma.             |

Örnek: 2x2 matrix oluşturma ve yazdırma.

```text
# A = D:100, 2x2 integer matrix
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# Matrix init: base=100, rows=2, cols=2
0(T-4)+k100
0(T-3)+k2
0(T-2)+k2
0(T-1)
0(T)
@160

# A[0,0]=1
0(T-4)+k100
0(T-3)
0(T-2)
0(T-1)+k1
@162

# A[0,1]=2
0(T-4)+k100
0(T-3)
0(T-2)+k1
0(T-1)+k2
@162

# A[1,0]=3
0(T-4)+k100
0(T-3)+k1
0(T-2)
0(T-1)+k3
@162

# A[1,1]=4
0(T-4)+k100
0(T-3)+k1
0(T-2)+k1
0(T-1)+k4
@162

# Print A
0(T-3)+k100
@166
```

Beklenen çıktı:

```text
[1 2]
[3 4]
```

Bu örnekte görülen en önemli şey şudur: matrix bile aslında data segment içinde base adresiyle temsil edilir. Yani UXM'de matrix bir “yüksek seviye nesne” gibi değil, data segment üzerinde descriptor + veri bloğu gibi düşünülmelidir.

---

# 13. Matrix Advanced Patch Alanı — `@180..@199`

Registry'de bu aralık matrix advanced için ayrılmıştır ve `extension_patch_available` olarak görünür.

|     ID | Ad                    | Amaç                     | Durum           |
| -----: | --------------------- | ------------------------ | --------------- |
| `@180` | `MAT_ND_INIT`         | N-boyutlu matrix init    | patch available |
| `@183` | `MAT_DET`             | Genel determinant        | patch available |
| `@184` | `MAT_INVERSE`         | Matrix inverse           | patch available |
| `@185` | `MAT_LU`              | LU decomposition         | patch available |
| `@186` | `MAT_QR`              | QR decomposition         | patch available |
| `@187` | `MAT_RANK`            | Rank hesabı              | patch available |
| `@188` | `MAT_COND_EST`        | Condition number tahmini | patch available |
| `@189` | `MAT_EIG_POWER`       | Power method eigenvalue  | patch available |
| `@192` | `MAT_SPARSE_CSR_INIT` | Sparse CSR init          | patch available |
| `@193` | `MAT_SPARSE_CSR_MV`   | Sparse matrix-vector     | patch available |
| `@199` | `MAT_ADV_INFO`        | Bilgi yazdırma           | patch available |

Burada dikkat: Bu alan ana matrix dispatcher aralığı içindedir ama registry “patch available” demektedir. Bu, fonksiyonların fikir/kod parçası olarak bulunduğunu ama tam canonical hale getirilmesi gerektiğini gösterir.

Bu alan bilimsel hesap için çok değerlidir ama kullanımda önce test edilmelidir.

---

# 14. Floating Point Servisleri — `@200..@234`

UXM'nin ilk çekirdeği cell/tamsayı ağırlıklıdır. Floating point servisleri gerçek sayılar için eklenmiştir.

|           ID | Ad                   | Amaç                            |
| -----------: | -------------------- | ------------------------------- |
|       `@200` | `FP_INIT16`          | 16-bit FP alanı başlatma        |
|       `@201` | `FP_INIT32`          | 32-bit FP alanı başlatma        |
|       `@202` | `FP_ZERO`            | FP sıfırlama                    |
|       `@203` | `FP_COPY`            | FP kopyalama                    |
|       `@204` | `FP_NORMALIZE_STORE` | Normalize ederek saklama        |
|       `@205` | `FP_TO_INT`          | FP → integer                    |
|       `@206` | `FP_IS_ZERO`         | Sıfır mı kontrolü               |
|       `@207` | `FP_SIGN`            | İşaret alma                     |
|       `@208` | `FP_ABS_TO_INT`      | Mutlak değeri integer'a çevirme |
|       `@209` | `FP_PRINT_RAW`       | Ham FP yazdırma                 |
|       `@210` | `FP_ADD`             | FP toplama                      |
|       `@211` | `FP_SUB`             | FP çıkarma                      |
|       `@212` | `FP_MUL`             | FP çarpma                       |
|       `@213` | `FP_DIV`             | FP bölme                        |
|       `@214` | `FP_COMPARE`         | FP karşılaştırma                |
|       `@215` | `FP_ABS`             | FP mutlak değer                 |
|       `@216` | `FP_NEG`             | FP negatif alma                 |
|       `@217` | `FP_ROUND16`         | 16-bit yuvarlama                |
|       `@218` | `FP_ROUND32`         | 32-bit yuvarlama                |
|       `@219` | `FP_TRUNC`           | Kesme/truncate                  |
|       `@220` | `FP_FROM_INT`        | Integer → FP                    |
|       `@221` | `FP_FROM_DEC_STRING` | Decimal string → FP             |
|       `@222` | `FP_TO_DEC_STRING`   | FP → decimal string             |
|       `@223` | `FP_PRINT_DECIMAL`   | FP decimal yazdırma             |
|       `@224` | `FP_SCALE10`         | 10 tabanlı ölçekleme            |
| `@230..@234` | reserved             | Kullanma                        |

Floating point servisleri UXM için önemlidir ama bunlar yüksek seviyeli Python `float` rahatlığında düşünülmemelidir. Daha çok data segment üzerinde saklanan FP yapıları gibi düşünülmelidir.

---

# 15. Math Extra Servisleri — `@240..@254`

Bu servisler polynomial ve küçük numerik işlem alanıdır.

|     ID | Ad                   | Amaç                     |
| -----: | -------------------- | ------------------------ |
| `@240` | `POLY_DERIVATIVE`    | Polinom türevi           |
| `@241` | `POLY_INTEGRAL`      | Polinom integrali        |
| `@242` | `POLY_EVAL`          | Polinom değeri hesaplama |
| `@243` | `POLY_PRINT`         | Polinom yazdırma         |
| `@244` | `POLY_CLEAR`         | Polinom temizleme        |
| `@250` | `EXPR_RPN_EVAL`      | RPN ifade değerlendirme  |
| `@251` | `NUM_DERIV`          | Sayısal türev            |
| `@252` | `INTEGRAL_TRAPEZOID` | Trapez integrali         |
| `@253` | `INTEGRAL_SIMPSON`   | Simpson integrali        |
| `@254` | `EXPR_RPN_PRINT`     | RPN ifade yazdırma       |

Bu alan UXM'nin bilimsel hesap hedefi için çok değerlidir. Özellikle polinom, türev ve integral servisleri dilin basit runtime'dan bilimsel runtime'a geçiş noktasıdır.

---

# 16. Statistics Servisleri — `@260..@299`

Statistics servisleri iki durumlu görünür: bazı registry satırları `extension_requires_meta_id_range_patch`, bazıları `stage9` olarak görünür. Dispatcher içinde `@274..@280` ve `@283..@289` için özel `MetaStatsNumericV19` yönlendirmesi de vardır. Bu yüzden bu alan dikkatli kullanılmalıdır.

Temel istatistik servisleri:

|           ID | Ad                | Amaç              |
| -----------: | ----------------- | ----------------- |
|       `@260` | `STAT_COUNT`      | Eleman sayısı     |
|       `@261` | `STAT_SUM`        | Toplam            |
|       `@262` | `STAT_MEAN`       | Ortalama          |
|       `@263` | `STAT_MIN`        | Minimum           |
|       `@264` | `STAT_MAX`        | Maksimum          |
|       `@265` | `STAT_RANGE`      | Aralık            |
|       `@266` | `STAT_VARIANCE`   | Varyans           |
|       `@267` | `STAT_STDDEV`     | Standart sapma    |
|       `@268` | `STAT_MEDIAN`     | Medyan            |
|       `@269` | `STAT_MODE`       | Mod               |
|       `@270` | `STAT_QUARTILE`   | Quartile          |
|       `@271` | `STAT_PERCENTILE` | Percentile        |
|       `@272` | `STAT_SKEWNESS`   | Çarpıklık         |
|       `@273` | `STAT_KURTOSIS`   | Basıklık          |
|       `@274` | `STAT_COVARIANCE` | Kovaryans         |
|       `@275` | `STAT_ZSCORE`     | Z-score           |
| `@280..@282` | correlation       | Korelasyon ailesi |
| `@290..@299` | regression        | Regresyon ailesi  |

Programcı için öneri: İstatistik servislerini kullanırken küçük veri dizisiyle başlayıp her servis için ayrı `.expect` oluşturulmalıdır.

Bellek mantığı genelde şöyledir:

```text
D:100..D:109 = veri dizisi
T-3 = start/base
T-1 = count
@262 = mean
T+1 = result
```

Python karşılığı:

```python
mean = sum(data) / len(data)
```

UXM mantığı:

```text
D segmentine veriyi yaz
T frame'e base ve count koy
@262 çağır
T+1 sonucunu oku
```

---

# 17. String Servisleri — `@300..@319`, `@357..@359`, `@370..@379`

String sistemi iki parçaya ayrılır:

1. Temel string servisleri: `@300..@319`
2. Genişletilmiş string servisleri: `@357..@359` ve `@370..@379`

Registry'de `@300..@309` bazı hypothesis adlarıyla çakışmış görünse de dispatcher gerçekliği `@300..@319` aralığını `MetaString` olarak gönderir. Bu yüzden bu aralık string için düşünülmelidir.

Genişletilmiş string servisleri:

|     ID | Ad                | Amaç                                 |
| -----: | ----------------- | ------------------------------------ |
| `@357` | `STR_FORMAT_INT`  | Integer'ı data string'e çevirme      |
| `@358` | `STR_HASH8`       | 8-bit additive hash                  |
| `@359` | `STR_HASH32`      | FNV-1a 32-bit hash                   |
| `@370` | `STR_HEX_ENCODE`  | Byte dizisini hex ASCII'ye çevirme   |
| `@371` | `STR_HEX_DECODE`  | Hex ASCII'yi byte dizisine çevirme   |
| `@372` | `STR_URL_ENCODE`  | URL percent encode                   |
| `@373` | `STR_URL_DECODE`  | URL percent decode                   |
| `@379` | `STR_TEXT_STATUS` | Son string/text status değerini alma |

Örnek: string hex/url pipeline test mantığı.

```text
#memory tape=128,stack=16,data=4096,queue=16
#cell dword
#mode normal
>>>>>
s1=0,{A B}

# Hex encode veya string servis örneği
0(T-4)+k0
0(T-3)+k100
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@370
@61

# URL encode örneği
0(T-4)+k0
0(T-3)+k100
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@372
@61
```

Burada `s1=0,{A B}` stringi data/tape alanına yerleştirilir. Sonra `@370` ve `@372` gibi servisler bu metni dönüştürür.

---

# 18. Probability Servisleri — `@380..@389` Güvenli Stage9 Aralığı

Registry'de `@360..@369` probability için de görünür, ancak dispatcher `@360..@369` aralığını probability'ye yollar. Stage9 açık ve daha net frame bilgisi veren aralık `@380..@389` olarak görünmektedir.

|     ID | Ad                   | Frame                           | Sonuç           |
| -----: | -------------------- | ------------------------------- | --------------- |
| `@380` | `RAND_SEED`          | `T-1=seed`                      | `T+1=0`         |
| `@381` | `RAND_UNIFORM_01`    | none                            | `T+1=0..999999` |
| `@382` | `RAND_INT_RANGE`     | `T-2=min,T-1=max`               | random integer  |
| `@383` | `RAND_BERNOULLI`     | `T-1=p_scaled`                  | `T+1=0/1`       |
| `@384` | `RAND_POISSON`       | `T-1=lambda_scaled`             | count           |
| `@385` | `RAND_BINOMIAL`      | `T-2=n,T-1=p_scaled`            | count           |
| `@386` | `RAND_WEIGHTED`      | `T-2=weights_start,T-1=count`   | index           |
| `@387` | `RAND_SHUFFLE_DATA`  | `T-2=start,T-1=count`           | status          |
| `@388` | `RAND_NORMAL_SCALED` | `T-2=mean_scaled,T-1=sd_scaled` | scaled value    |
| `@389` | `RAND_STATUS`        | none                            | status          |

Örnek: 1 ile 10 arasında random integer.

```text
0(T-1)+k123
@380

0(T-2)+k1
0(T-1)+k10
@382
@61
@5
```

Python karşılığı:

```python
import random
random.seed(123)
print(random.randint(1, 10))
```

---

# 19. Numeric Methods Servisleri — `@390..@399`, `@420..@439`

Numeric methods iki parçalı görünür. Eski/patch isteyen alan `@390..@399`, stage9 çalışan alan ise `@420..@439` olarak daha net frame bilgisi taşır.

Stage9 numerical servisleri:

|     ID | Ad                     | Frame                                                   | Sonuç          |
| -----: | ---------------------- | ------------------------------------------------------- | -------------- |
| `@420` | `NUM_POLY_EVAL`        | `T-2=polyBase,T-1=x_scaled`                             | `T+1=y_scaled` |
| `@421` | `NUM_NEWTON`           | `T-4=polyBase,T-3=x0_scaled,T-2=maxIter,T-1=eps_scaled` | root           |
| `@422` | `NUM_BISECTION`        | `T-4=polyBase,T-3=a_scaled,T-2=b_scaled,T-1=maxIter`    | root           |
| `@423` | `NUM_TRAPEZOID_POLY`   | `T-4=polyBase,T-3=a_scaled,T-2=b_scaled,T-1=n`          | area           |
| `@424` | `NUM_SIMPSON_POLY`     | `T-4=polyBase,T-3=a_scaled,T-2=b_scaled,T-1=n`          | area           |
| `@425` | `NUM_INTERP_LINEAR`    | `T-4=xBase,T-3=yBase,T-2=count,T-1=x_raw`               | y              |
| `@426` | `NUM_BEZIER_QUADRATIC` | `T-4=p0,T-3=p1,T-2=p2,T-1=t_scaled`                     | value          |
| `@427` | `NUM_RK4_LINEAR`       | `T-4=y0,T-3=a_scaled,T-2=dt_scaled,T-1=steps`           | y              |
| `@439` | `NUM_STATUS`           | none                                                    | status         |

Örnek: polinom trapez integrali.

```text
#memory tape=128,stack=16,data=4096,queue=16
#cell dword
#mode normal
>>>>>

# D:100 polinom katsayıları gibi kullanılıyor
0(D:100)+k2
0(D:101)+k0
0(D:102)+k0
0(D:103)+k1

# polyBase=100, a=0, b=10, n=0, derece/param=2 gibi örnek frame
0(T-4)+k100
0(T-3)+k0
0(T-2)+k10
0(T-1)+k0
0(T)+k2
@423
@61
```

Burada önemli olan şey şudur: numerik servislerde veri genellikle data segment içinde polinom veya dizi olarak tutulur, tape frame ise o verinin adresini ve parametrelerini taşır.

---

# 20. File I/O Servisleri — `@400..@415` Canonical Aralık

Dosya servisleri UXM'nin pratik program yazma açısından en önemli ailelerinden biridir.

Canonical kabul edilmesi gereken aralık `@400..@415` görünmektedir.

|     ID | Ad                       | Frame                                              | Sonuç        |
| -----: | ------------------------ | -------------------------------------------------- | ------------ |
| `@400` | `FILE_OPEN_READ_TEXT`    | `T-3=name_start,T-2=name_len,T-1=reserved`         | `T+1=handle` |
| `@401` | `FILE_OPEN_WRITE_TEXT`   | `T-3=name_start,T-2=name_len,T-1=reserved`         | `T+1=handle` |
| `@402` | `FILE_OPEN_APPEND_TEXT`  | `T-3=name_start,T-2=name_len,T-1=reserved`         | `T+1=handle` |
| `@403` | `FILE_OPEN_BINARY_READ`  | `T-3=name_start,T-2=name_len,T-1=reserved`         | `T+1=handle` |
| `@404` | `FILE_OPEN_BINARY_WRITE` | `T-3=name_start,T-2=name_len,T-1=reserved`         | `T+1=handle` |
| `@405` | `FILE_CLOSE`             | `T-1=handle`                                       | status       |
| `@406` | `FILE_READ_BYTE`         | `T-1=handle`                                       | `T+1=byte`   |
| `@407` | `FILE_WRITE_BYTE`        | `T-2=handle,T-1=byte`                              | status       |
| `@408` | `FILE_READ_LINE`         | `T-3=handle,T-2=dst_data_start,T-1=max_len`        | `T+1=len`    |
| `@409` | `FILE_WRITE_LINE`        | `T-3=handle,T-2=src_data_start,T-1=len`            | status       |
| `@410` | `FILE_READ_BLOCK`        | `T-4=handle,T-3=space,T-2=dst_start,T-1=max_count` | count        |
| `@411` | `FILE_WRITE_BLOCK`       | `T-4=handle,T-3=space,T-2=src_start,T-1=count`     | count        |
| `@412` | `FILE_SEEK`              | `T-2=handle,T-1=position_zero_based`               | status       |
| `@413` | `FILE_TELL`              | `T-1=handle`                                       | position     |
| `@414` | `FILE_SIZE`              | `T-1=handle`                                       | size         |
| `@415` | `FILE_EXISTS`            | `T-2=name_start,T-1=name_len`                      | `0/1`        |

Dikkat: Registry'de `@420 FILE_FLUSH` ve `@421 FILE_OPEN_BINARY_APPEND` görünüyor ama ana dispatcher `@420..@439` aralığını numeric methods'a gönderiyor. Bu nedenle bu iki file ID'si güvenli canonical file aralığına dahil edilmemelidir.

Örnek: Dosyaya satır yazıp okuma.

```text
# V3.3 FILE V1: text write/read line smoke test
# Expected output: HELLO
#memory tape=64,stack=8,data=128,queue=4
#cell byte
#mode normal

s1=0,{uxm_stage5_line.tmp}
s2=32,{HELLO}
s3=64,{EMPTY}
>>>>

# open write: filename start=0
0(T-1)+k0
@401
$(T+1)
%(T-2)

# write line from string/data start 32
0(T-1)+k32
@409

# close
$(T-2)
%(T-1)
@405

# open read
0(T-1)+k0
@400
$(T+1)
%(T-3)

# read line into buffer at 64, max len 32
0(T-2)+k64
0(T-1)+k32
@408

# print string/data at 64
0(T-1)+k64
@313
@!5

# close
$(T-3)
%(T-1)
@405
```

Bu örnek profesyonel açıdan çok değerlidir. Çünkü file handle, stack taşıma, data buffer ve string print servisi birlikte kullanılır.

---

# 21. Complex Number Servisleri — `@440..@459`

Complex servisleri stage9 ile net frame kazanmış görünür.

|     ID | Ad                | Frame                                      | Sonuç            |
| -----: | ----------------- | ------------------------------------------ | ---------------- |
| `@440` | `CPLX_INIT`       | `T-2=out,T-1=real_scaled,T=imag_scaled`    | status           |
| `@441` | `CPLX_ADD`        | `T-2=out,T-1=a,T=b`                        | status           |
| `@442` | `CPLX_SUB`        | `T-2=out,T-1=a,T=b`                        | status           |
| `@443` | `CPLX_MUL`        | `T-2=out,T-1=a,T=b`                        | status           |
| `@444` | `CPLX_DIV`        | `T-2=out,T-1=a,T=b`                        | status           |
| `@445` | `CPLX_CONJ`       | `T-2=out,T-1=a`                            | status           |
| `@446` | `CPLX_ABS`        | `T-1=a`                                    | magnitude_scaled |
| `@447` | `CPLX_ARG`        | `T-1=a`                                    | angle_scaled     |
| `@448` | `CPLX_EXP`        | `T-2=out,T-1=a`                            | status           |
| `@449` | `CPLX_FROM_POLAR` | `T-2=out,T-1=radius_scaled,T=theta_scaled` | status           |
| `@459` | `CPLX_STATUS`     | none                                       | status           |

Complex servisleri sinyal işleme, FFT hazırlığı, sayısal analiz ve mühendislik hesapları için gereklidir.

---

# 22. Bio Servisleri — `@480..@511`

Bio servisleri UXM'nin en özgün alanlarından biridir. DNA/RNA/codon/protein mantığına yöneliktir.

|     ID | Ad                 | Frame                                    | Sonuç                       |
| -----: | ------------------ | ---------------------------------------- | --------------------------- |
| `@480` | `BIO_BASE_ENCODE`  | `T-1=ASCII base`                         | `0..3 or 255`               |
| `@481` | `BIO_CODON_ENCODE` | `T-3/T-2/T-1=ASCII bases`                | codon id                    |
| `@482` | `BIO_CODON_TO_AA`  | `T-1=codon id`                           | amino acid ASCII            |
| `@483` | `BIO_TRANSLATE`    | `T-4=src,T-3=len,T-2=dst,T-1=dstMax`     | AA output length            |
| `@484` | `BIO_GC_CONTENT`   | `T-2=src,T-1=len`                        | integer GC percent          |
| `@485` | `BIO_ORF_FIND`     | `T-2=src,T-1=len`                        | first ATG index or CellMask |
| `@486` | `BIO_AA_COUNT`     | `T-3=aaSrc,T-2=len,T-1=AA ASCII`         | count                       |
| `@487` | `BIO_MOTIF_FIND`   | `T-4=src,T-3=len,T-2=motif,T-1=motifLen` | index or CellMask           |
| `@511` | `BIO_STATUS`       | none                                     | last bio status             |

Örnek kullanım fikri: GC content.

```text
# DNA dizisi D:100'de, uzunluk 20
0(T-2)+k100
0(T-1)+k20
@484
@61
@5
```

Python karşılığı:

```python
gc = (seq.count('G') + seq.count('C')) * 100 // len(seq)
print(gc)
```

UXM bu alanda özellikle su ürünleri, biyoinformatik ve bilimsel veri işleme için genişletilebilir.

---

# 23. Matrix Advanced ve Tensor Basic — `@512..@559`

Stage10 ile aktif görünen servislerdir.

Matrix advanced:

|     ID | Ad                   | Frame               | Sonuç           |
| -----: | -------------------- | ------------------- | --------------- |
| `@512` | `MAT_ADV_DET_N`      | `T-3=A`             | determinant     |
| `@513` | `MAT_ADV_INVERSE_2`  | `T-4=dst,T-3=A`     | status          |
| `@514` | `MAT_ADV_RANK`       | `T-3=A`             | rank            |
| `@516` | `MAT_ADV_NORM_INF`   | `T-3=A`             | max row abs sum |
| `@517` | `MAT_ADV_FROBENIUS2` | `T-3=A`             | sum squares     |
| `@518` | `MAT_ADV_LU2`        | `T-4=L,T-2=U,T-3=A` | status          |
| `@519` | `MAT_ADV_INFO`       | none                | info output     |

Tensor basic:

|     ID | Ad              | Frame                                | Sonuç             |
| -----: | --------------- | ------------------------------------ | ----------------- |
| `@540` | `TENSOR_INIT2D` | `T-4=base,T-3=dim0,T-2=dim1`         | status            |
| `@541` | `TENSOR_SET2D`  | `T-4=base,T-3=row,T-2=col,T-1=value` | status            |
| `@542` | `TENSOR_GET2D`  | `T-4=base,T-3=row,T-2=col`           | value             |
| `@543` | `TENSOR_FILL`   | `T-4=base,T-3=value`                 | status            |
| `@544` | `TENSOR_SUM`    | `T-4=base`                           | sum               |
| `@545` | `TENSOR_SHAPE`  | `T-4=base`                           | dim0, dim1, total |
| `@559` | `TENSOR_INFO`   | none                                 | info output       |

Örnek: 2x3 tensor oluştur, bir elemanı 99 yap, sonra tensor'ü 5 ile doldurup toplam al.

```text
# V3.3 Stage-10 Tensor Basic: init/set/get/fill/sum
# EXPECT_OUTPUT: 99 30
#memory tape=64,stack=8,data=256,queue=4
#cell dword
#mode normal
>>>>>

# init tensor D:500 shape 2x3
0(T-4)+k500
0(T-3)+k2
0(T-2)+k3
@540

# set [1,2]=99
0(T-4)+k500
0(T-3)+k1
0(T-2)+k2
0(T-1)+k99
@541

# get [1,2]
0(T-4)+k500
0(T-3)+k1
0(T-2)+k2
@542
@61

# fill all six cells with 5 and sum=30
0(T-4)+k500
0(T-3)+k5
@543
0(T-4)+k500
@544
@61
```

Bu örnek UXM'nin AI/tensor hedefi için neden önemli olduğunu gösterir. Tensor descriptor data segment içinde tutulur, servisler de bu descriptor üzerinden çalışır.

---

# 24. Tensor Advanced2 — `@575..@584`

Stage12 ile aktif görünen gelişmiş tensor servisleridir.

|     ID | Ad                           | Frame                                 | Amaç                                  |
| -----: | ---------------------------- | ------------------------------------- | ------------------------------------- |
| `@575` | `TENSOR_RESHAPE`             | `T-4=dst,T-3=src,T-2=dimsBase,T-1=nd` | total eleman sayısı korunarak reshape |
| `@576` | `TENSOR_FLATTEN_TO_2D`       | `T-4=dst,T-3=src,T-2=rows`            | ND tensor'ü 2D'ye açma                |
| `@577` | `TENSOR_SLICE3D_AXIS1_TO_2D` | `T-4=dst,T-3=src,T-1=idx1`            | 3D slice                              |
| `@578` | `TENSOR_SLICE3D_AXIS2_TO_2D` | `T-4=dst,T-3=src,T-1=idx2`            | 3D slice                              |
| `@581` | `TENSOR_BROADCAST_ADD`       | `T-4=dst,T-3=A,T-2=B`                 | broadcast add                         |
| `@582` | `TENSOR_BROADCAST_SHAPE`     | `T-4=outData,T-3=A,T-2=B`             | broadcast shape hesabı                |
| `@583` | `TENSOR_RESHAPE_INFER`       | `T-4=dst,T-3=src,T-2=dimsBase,T-1=nd` | tek sıfırlı inferred reshape          |
| `@584` | `TENSOR_FLATTEN_TO_1D`       | `T-4=dst,T-3=src`                     | 1D flatten                            |

Bu servisler UXM'yi klasik matrix sisteminden AI tensor sistemine yaklaştırır.

---

# 25. Linalg Advanced — `@520..@539`

Registry'de linalg advanced isimleri vardır ama enabled sayısı sıfır görünmektedir. Yani bu alan şimdilik plan/rezerv/gelecek genişleme alanı gibi değerlendirilmelidir.

|     ID | Ad                        | Amaç                  | Durum                  |
| -----: | ------------------------- | --------------------- | ---------------------- |
| `@520` | `LINALG_DET_N`            | N x N determinant     | etkin değil/geliştirme |
| `@521` | `LINALG_RANK`             | rank                  | etkin değil/geliştirme |
| `@522` | `LINALG_UPPER_TRIANGULAR` | üst üçgensel dönüşüm  | etkin değil/geliştirme |
| `@523` | `LINALG_DIAG_PRODUCT`     | diagonal çarpım       | etkin değil/geliştirme |
| `@524` | `LINALG_INVERSE_NXN`      | genel inverse         | etkin değil/geliştirme |
| `@525` | `LINALG_SOLVE_NXN`        | lineer sistem çözümü  | etkin değil/geliştirme |
| `@526` | `LINALG_MATVEC`           | matrix-vector çarpımı | etkin değil/geliştirme |
| `@527` | `LINALG_IS_IDENTITY`      | identity kontrol      | etkin değil/geliştirme |
| `@528` | `LINALG_IS_SYMMETRIC`     | simetrik kontrol      | etkin değil/geliştirme |
| `@529` | `LINALG_ROW_SUM`          | satır toplamı         | etkin değil/geliştirme |
| `@530` | `LINALG_COL_SUM`          | sütun toplamı         | etkin değil/geliştirme |
| `@531` | `LINALG_SWAP_ROWS`        | satır değiştirme      | etkin değil/geliştirme |
| `@532` | `LINALG_SCALE_ROW`        | satır ölçekleme       | etkin değil/geliştirme |
| `@533` | `LINALG_ADD_ROW_MULTIPLE` | satır kombinasyonu    | etkin değil/geliştirme |
| `@539` | `LINALG_INFO`             | bilgi                 | etkin değil/geliştirme |

Bu alan ileri bilimsel hesap için gereklidir ama mevcut kılavuzda aktif ana kullanım alanı olarak değil, geliştirme hedefi olarak görülmelidir.

---

# 26. ML/Data Pipeline Servisleri — `@700..@759`

Registry'de `active` görünen ML/data pipeline servisleri vardır. Ancak frame/result alanları boş olduğu için bu servisler kullanılırken mutlaka `runtime_ml_data_pipeline_services.bas` dosyası ve ilgili testler incelenmelidir.

ML servisleri:

|     ID | Ad                      | Amaç                          |
| -----: | ----------------------- | ----------------------------- |
| `@700` | `ML_RELU`               | ReLU aktivasyon               |
| `@701` | `ML_STEP`               | Step aktivasyon               |
| `@702` | `ML_SIGMOID_FAST1000`   | Hızlı sigmoid scaled          |
| `@703` | `ML_DOT_BIAS`           | Dot product + bias            |
| `@704` | `ML_PERCEPTRON_PREDICT` | Perceptron tahmini            |
| `@705` | `ML_MSE`                | Mean squared error            |
| `@706` | `ML_MAE`                | Mean absolute error           |
| `@707` | `ML_ARGMAX`             | En büyük indeks               |
| `@708` | `ML_PERCEPTRON_UPDATE`  | Perceptron ağırlık güncelleme |
| `@709` | `ML_LINEAR_GRAD_STEP`   | Linear model gradient step    |
| `@710` | `ML_CLAMP`              | Değer sınırlandırma           |
| `@719` | `ML_INFO`               | Bilgi                         |

Dataset servisleri:

|     ID | Ad                    | Amaç                             |
| -----: | --------------------- | -------------------------------- |
| `@730` | `DATASET_INIT`        | Dataset başlatma                 |
| `@731` | `DATASET_SET_X`       | X değeri yazma                   |
| `@732` | `DATASET_GET_X`       | X değeri okuma                   |
| `@733` | `DATASET_SET_Y`       | Y değeri yazma                   |
| `@734` | `DATASET_GET_Y`       | Y değeri okuma                   |
| `@735` | `DATASET_ROW_TO_VEC`  | Dataset satırını vector'e taşıma |
| `@736` | `DATASET_ROW_DOT_VEC` | Satır ile vector dot product     |
| `@737` | `DATASET_COL_SUM`     | Kolon toplamı                    |
| `@738` | `DATASET_Y_SUM`       | Y toplamı                        |
| `@739` | `DATASET_INFO`        | Dataset bilgisi                  |

Pipeline servisleri:

|     ID | Ad                         | Amaç                           |
| -----: | -------------------------- | ------------------------------ |
| `@740` | `PIPE_DATA_TO_VEC`         | Data'dan vector'e taşıma       |
| `@741` | `PIPE_VEC_TO_DATA`         | Vector'den data'ya taşıma      |
| `@742` | `PIPE_LINEAR_PREDICT_DATA` | Data üzerinden linear predict  |
| `@743` | `PIPE_EVAL_MSE_DATASET`    | Dataset MSE hesaplama          |
| `@744` | `PIPE_BATCH_Y_SUM`         | Batch Y toplamı                |
| `@745` | `PIPE_BATCH_ROW_TO_VEC`    | Batch satırını vector'e taşıma |
| `@746` | `PIPE_FEATURE_SCALE_CONST` | Feature sabit ölçekleme        |
| `@747` | `PIPE_DATASET_TO_DENSE`    | Dataset'i dense formata taşıma |
| `@748` | `PIPE_STATUS`              | Pipeline status                |
| `@759` | `PIPE_INFO`                | Pipeline bilgisi               |

Bu alan UXM'nin gelecekte AI runtime olma potansiyelini gösterir. Ama programcı açısından şu anda dikkat edilmesi gereken nokta şudur: ML servisleri kullanılırken frame sözleşmesi boş bırakıldığı için doğrudan registry yeterli değildir. Kaynak dosya ve test örnekleri birlikte okunmalıdır.

---

# 27. Hypothesis, Posthoc ve AI Hook Servisleri

Dispatcher hook sistemi bazı servisleri ana aralık dışından yakalar.

Hypothesis güvenli hook aralığı:

|     ID | Ad                        | Amaç                         |
| -----: | ------------------------- | ---------------------------- |
| `@760` | `HYP_TTEST_ONE`           | Tek örneklem t testi         |
| `@761` | `HYP_TTEST_INDEPENDENT`   | Bağımsız iki örnek t testi   |
| `@762` | `HYP_TTEST_PAIRED`        | Eşleştirilmiş t testi        |
| `@763` | `HYP_ZTEST_ONE`           | Tek örneklem z testi         |
| `@764` | `HYP_ZTEST_TWO_APPROX`    | İki örnek z testi yaklaşık   |
| `@765` | `HYP_FTEST_VARIANCE`      | Varyans F testi              |
| `@766` | `HYP_ANOVA_ONEWAY_SIMPLE` | Basit one-way ANOVA          |
| `@768` | `HYP_CHI_SQUARE`          | Chi-square                   |
| `@769` | `HYP_CHI_GOODNESS_EQUAL`  | Eşit beklenen iyi uyum testi |

Posthoc hook aralıkları:

|                 ID | Ad         |
| -----------------: | ---------- |
| `@320` veya `@790` | Tukey      |
| `@321` veya `@791` | Duncan     |
| `@322` veya `@792` | Dunnett    |
| `@323` veya `@793` | Bonferroni |
| `@324` veya `@794` | Scheffe    |
| `@325` veya `@795` | LSD        |

AI hook aralıkları:

|     ID | Ad                         | Amaç                       |
| -----: | -------------------------- | -------------------------- |
| `@810` | `AI_ACCURACY`              | Accuracy                   |
| `@811` | `AI_CONFUSION_BINARY`      | Binary confusion matrix    |
| `@812` | `AI_PRECISION_BINARY`      | Precision                  |
| `@813` | `AI_RECALL_BINARY`         | Recall                     |
| `@814` | `AI_F1_BINARY`             | F1                         |
| `@815` | `AI_DISTANCE_EUCLIDEAN_SQ` | Euclidean distance squared |
| `@816` | `AI_DISTANCE_MANHATTAN`    | Manhattan distance         |
| `@817` | `AI_DISTANCE_COSINE`       | Cosine distance            |

Bu hook sisteminin avantajı, servisleri ana dispatcher'ı bozmeden genişletmesidir. Dezavantajı ise servislerin iki farklı yerde aranması gerektiğidir.

---

# 28. Bir Servis Nasıl Kullanılır? Genel Reçete

UXM'de herhangi bir servisi kullanmak için şu şablon takip edilir:

```text
1. Servis ID'sini seç.
2. Giriş frame'ini oku.
3. T-4, T-3, T-2, T-1, T hücrelerini hazırla.
4. @ID çağır.
5. T+1 veya belirtilen result hücresini oku.
6. Gerekirse @61, @60, @69, pN veya string servisleriyle çıktı ver.
7. Status kontrol et.
```

Örnek şablon:

```text
# Frame hazırla
0(T-4)+k...
0(T-3)+k...
0(T-2)+k...
0(T-1)+k...
0(T)+k...

# Servis çağır
@ID

# Sonucu yazdır
@61
@5
```

Bu UXM'nin fonksiyon çağırma biçimidir.

---

# 29. Servis Kullanırken Bellek Haritası Yazma Zorunluluğu

Profesyonel UXM programı için servis çağırmadan önce bellek haritası yazmak gerekir.

Örnek matrix programı için:

```text
BELLEK HARİTASI

D:100  -> Matrix A descriptor + data
D:200  -> Matrix B descriptor + data
D:300  -> Matrix C descriptor + data
T-4    -> dst base
T-3    -> A base veya row
T-2    -> B base veya col
T-1    -> value veya parametre
T      -> ek parametre
T+1    -> status/result
```

Dosya programı için:

```text
BELLEK HARİTASI

s1 / D:0   -> dosya adı
D:32       -> yazılacak satır
D:64       -> okuma buffer
T-3        -> handle veya name_start
T-2        -> len/dst
T-1        -> max_len/handle
T+1        -> handle/result
```

Bu bellek planı yapılmazsa servisler birbirinin verisini ezer.

---

# 30. Prompt 3 Sonucu

Bu bölümde UXM'nin runtime service sistemi ayrıntılı olarak kuruldu. En önemli sonuçlar şunlardır:

1. UXM'nin gerçek gücü `@N` service call sistemidir.
2. Servis çağrıları tape frame üzerinden yapılır.
3. `T-4..T` giriş alanı, `T+1` sonuç/status alanı olarak düşünülmelidir.
4. Core, arithmetic, math, I/O, pointer, FIFO, matrix, FP, numeric, file, complex, bio, tensor ve ML/data pipeline servisleri vardır.
5. Bazı servis aralıkları çakışmalı veya patch gerektirir; özellikle `@130..@149`, `@300..@309`, `@400..@421` alanları dikkatli okunmalıdır.
6. Profesyonel UXM kullanımı için her servis çağrısında bellek haritası, frame sözleşmesi ve `.expect` testi şarttır.

Bir sonraki bölüm yani Prompt 4'te artık sadece liste değil, gerçek program tasarlama anlatılacaktır. Python/BASIC bilen birinin problemi nasıl UXM programına çevireceği, profesyonel örneklerin nasıl kurulacağı, file + string + matrix + statistics + bio/tensor pipeline örneklerinin nasıl çözümleneceği ve UXM'nin güçlü/zayıf yönlerinin nihai yorumu yazılacaktır.

---

# PROMPT 4 — Profesyonel Program Yazma, Problem Çözümleme, Eğitim Yolu ve Nihai Değerlendirme

Bu son bölüm, UXM'yi yalnızca komut ezberleyen biri için değil, gerçekten program yazmak isteyen biri için hazırlar. Burada hedef şudur: Python veya BASIC bilen bir programcı, UXM'de nasıl düşünecek, problemi nasıl parçalara ayıracak, bellek haritasını nasıl çıkaracak, servisleri nasıl seçecek, testi nasıl yazacak ve programı nasıl büyütecek?

UXM'de program yazmak, Python'daki gibi “fikri doğrudan cümleye dökmek” değildir. UXM'de önce makinenin belleğini tasarlarsın, sonra komutları ve servis çağrılarını bu bellek tasarımına göre yerleştirirsin.

Bu nedenle bu bölümün ana cümlesi şudur:

```text
UXM'de program yazmak = problem çözümleme + bellek haritası + servis seçimi + test disiplini.
```

---

# 1. UXM'de Program Tasarlamanın Ana Yöntemi

Bir UXM programı yazmadan önce şu form doldurulmalıdır:

```text
UXM PROGRAM TASARIM FORMU

1. Problem:
   Program ne yapacak?

2. Girdi:
   Veri sabit mi, klavyeden mi, dosyadan mı, data segment'ten mi gelecek?

3. Çıktı:
   Ekrana mı yazılacak, dosyaya mı kaydedilecek, data segment'e mi dönecek?

4. Bellek alanları:
   Tape ne için kullanılacak?
   Data ne için kullanılacak?
   Stack ne için kullanılacak?
   Queue gerekiyor mu?

5. Hücre haritası:
   T-4, T-3, T-2, T-1, T, T+1 ne taşıyacak?
   D:100, D:200 gibi sabit alanlar ne için ayrılacak?

6. Servisler:
   Hangi @N servisleri çağrılacak?

7. Kontrol akışı:
   Döngü, branch, macro gerekiyor mu?

8. Test:
   Beklenen çıktı nedir?
   .expect dosyası ne içermeli?
```

Bu form gereksiz görünmemelidir. UXM'de bu form yoksa program büyüdüğünde kimin neyi ezdiği anlaşılmaz.

---

# 2. UXM'de Bellek Haritası Nasıl Çizilir?

Python'da değişken adları vardır:

```python
x = 10
y = 20
sonuc = x + y
```

UXM'de ise değişken adları yerine hücre yerleşimi vardır:

```text
T-2 : x
T-1 : y
T+1 : sonuc
```

Bunu programın başında yorum olarak yazmak en doğru alışkanlıktır:

```text
# BELLEK HARİTASI
# T-2 = x
# T-1 = y
# T+1 = sonuc
```

Sonra kod yazılır:

```text
0(T-2)+k10
0(T-1)+k20
@20
@61
@5
```

Bu küçük örnekte:

* `T-2` birinci sayıdır.
* `T-1` ikinci sayıdır.
* `@20` ADD servisidir.
* `T+1` sonucu taşır.
* `@61` sonucu decimal yazdırır.
* `@5` yeni satır basar.

Bu örnek Python'daki `print(10 + 20)` karşılığıdır.

---

# 3. UXM'de Programcı Tipleri

UXM'yi kullanan programcı üç seviyede gelişir.

## 3.1 Başlangıç Seviyesi

Bu kişi şunları kullanır:

* `+`, `-`, `>`, `<`, `0`, `.`, `,`
* `sN`, `pN`
* basit `@20`, `@21`, `@61`, `@5`

Bu seviyede amaç dili tanımaktır.

## 3.2 Orta Seviye

Bu kişi şunları kullanır:

* `(T+N)`, `(D:N)`, `(SP-N)` adresleme
* macro `m128={...}`
* file I/O
* string servisleri
* statistics servisleri
* matrix servisleri

Bu seviyede programcı artık bellek haritası yapmayı öğrenmiştir.

## 3.3 İleri Seviye

Bu kişi şunları kullanır:

* indirect addressing: `(D@T)`, `(D@(T-2)+N)`
* tensor servisleri
* numeric methods
* bio servisleri
* ML/data pipeline
* branch offset
* test corpus yönetimi
* servis registry kontrolü

Bu seviyede UXM artık oyuncak değil, küçük bir VM üzerinde sistem programlama aracıdır.

---

# 4. Örnek 1 — Basit Toplama Programı

## Amaç

İki sayıyı topla ve sonucu yazdır.

## Python Karşılığı

```python
x = 7
y = 8
print(x + y)
```

## BASIC Karşılığı

```basic
LET X = 7
LET Y = 8
PRINT X + Y
```

## UXM Bellek Haritası

```text
T-2 : x
T-1 : y
T+1 : sonuc
```

## UXM Kodu

```text
# 7 + 8 = 15
#memory tape=64,stack=8,data=128,queue=4
#cell byte
#mode normal
>>>>>

0(T-2)+k7
0(T-1)+k8
@20
@61
@5
```

## Çözümleme

| Satır        | Anlamı                                 |
| ------------ | -------------------------------------- |
| `#memory...` | Runtime bellek boyutlarını bildirir.   |
| `#cell byte` | Hücre tipi byte olarak düşünülür.      |
| `>>>>>`      | Pointer'ı güvenli frame alanına taşır. |
| `0(T-2)+k7`  | x = 7                                  |
| `0(T-1)+k8`  | y = 8                                  |
| `@20`        | ADD servisi                            |
| `@61`        | T+1 sonucunu decimal yazdır            |
| `@5`         | newline                                |

## Beklenen Çıktı

```text
15
```

Burada programcının öğrenmesi gereken şey, UXM'de toplama yapmanın yalnızca `+` komutuyla değil, servis frame'i üzerinden de yapılabileceğidir. `+` hücre artırma komutudur; `@20` iki sayıyı toplama servisidir.

---

# 5. Örnek 2 — ASCII Karakter ve String Yazdırma

## Amaç

Ekrana önce `A`, sonra `Merhaba UXM` yazdır.

## Python Karşılığı

```python
print(chr(65))
print("Merhaba UXM")
```

## UXM Kodu

```text
# A karakteri ve string yazdırma
#memory tape=64,stack=8,data=128,queue=4
#cell byte
#mode normal

0+k65.
@5

s1=0,{Merhaba UXM
}
p1
```

## Çözümleme

`0+k65.` bölümü klasik düşük seviyeli karakter yazdırmadır. `s1` ve `p1` ise daha yüksek seviyeli string yazdırmadır.

Bu örnek UXM'nin iki yüzünü gösterir:

* byte/ASCII seviyesinde çalışabilir,
* string tanımıyla daha rahat metin basabilir.

---

# 6. Örnek 3 — Basit İstatistik: Ortalama ve Varyans

Bu örnek paketteki `example_06_stats_mean_variance.uxm` mantığına dayanır.

## Amaç

Data segment'e şu veri dizisini yaz:

```text
2, 4, 6, 8
```

Sonra ortalama ve varyans hesapla.

## Python Karşılığı

```python
data = [2, 4, 6, 8]
mean = sum(data) / len(data)
variance = sum((x - mean) ** 2 for x in data) / len(data)
print(mean)
print(variance)
```

## UXM Bellek Haritası

```text
D:100 = 2
D:101 = 4
D:102 = 6
D:103 = 8

T-4 = data base
T-3 = count
T-2 = reserved
T-1 = reserved
T   = reserved
T+1 = result
```

## UXM Kodu

```text
# Ortalama ve varyans örneği
#memory tape=128,stack=16,data=4096,queue=16
#cell dword
#mode normal
>>>>>

# Data dizisi: 2,4,6,8
0(D:100)+k2
0(D:101)+k4
0(D:102)+k6
0(D:103)+k8

# mean(data[100..103])
0(T-4)+k100
0(T-3)+k4
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@262
@61
@5

# variance(data[100..103])
0(T-4)+k100
0(T-3)+k4
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@266
@61
@5
```

## Çözümleme

Bu örnekte Data segment gerçek bir array gibi kullanılır.

```text
D:100  D:101  D:102  D:103
  2      4      6      8
```

`@262` ortalama servisidir. `@266` varyans servisidir. Her iki servis de aynı frame'i kullanır:

```text
T-4 = başlangıç adresi
T-3 = eleman sayısı
```

## Programcının Çıkarması Gereken Ders

Python'da liste doğrudan dilin içindedir. UXM'de liste, Data segment üzerinde kurulur. İstatistik fonksiyonu da Data segment adresini ve eleman sayısını alır. Bu, C'deki pointer + length mantığına çok yakındır.

---

# 7. Örnek 4 — Matrix Oluşturma ve Yazdırma

Bu örnek paketteki `test_matrix01_init_set_print.uxm` mantığına dayanır.

## Amaç

Şu 2x2 matrix'i oluştur ve yazdır:

```text
[1 2]
[3 4]
```

## Python Karşılığı

```python
A = [[1, 2], [3, 4]]
for row in A:
    print(row)
```

## UXM Bellek Haritası

```text
D:100 = Matrix A base

T-4 = matrix base
T-3 = row veya rows
T-2 = col veya cols
T-1 = value
T   = ek parametre
T+1 = status/result
```

## UXM Kodu

```text
# TEST: UX-MAT init/set/print
# EXPECT_OUTPUT:
# [1 2]
# [3 4]

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# A = D:100, 2x2 integer
0(T-4)+k100
0(T-3)+k2
0(T-2)+k2
0(T-1)
0(T)
@160

# A[0,0]=1
0(T-4)+k100
0(T-3)
0(T-2)
0(T-1)+k1
@162

# A[0,1]=2
0(T-4)+k100
0(T-3)
0(T-2)+k1
0(T-1)+k2
@162

# A[1,0]=3
0(T-4)+k100
0(T-3)+k1
0(T-2)
0(T-1)+k3
@162

# A[1,1]=4
0(T-4)+k100
0(T-3)+k1
0(T-2)+k1
0(T-1)+k4
@162

# print A
0(T-3)+k100
@166
```

## Çözümleme

Burada `@160` matrix init servisidir. Matrix'in data segment içinde `D:100` adresinden başlayacağı söylenir. `T-3=2` rows, `T-2=2` cols anlamındadır.

Sonra `@162` ile tek tek hücreler yazılır.

Matrix set frame'i şu mantıkla okunabilir:

```text
T-4 = matrix base
T-3 = row
T-2 = col
T-1 = value
@162 = MAT_SET
```

Yazdırma için:

```text
T-3 = matrix base
@166 = MAT_PRINT
```

## Programcının Çıkarması Gereken Ders

Python'da `A[1][0] = 3` çok kolaydır. UXM'de aynı işlem servis frame'iyle yapılır. Bunun karşılığında UXM programcıya matrix'in bellekte tam olarak nerede durduğunu kontrol etme gücü verir.

---

# 8. Örnek 5 — Tensor 2D Toplamı

Bu örnek paketteki `example_11_tensor2d_sum.uxm` mantığına dayanır.

## Amaç

2x3 tensor oluştur, bütün elemanları 5 yap ve toplamını yazdır.

Beklenen mantık:

```text
2 x 3 = 6 eleman
6 * 5 = 30
```

## Python Karşılığı

```python
import numpy as np
T = np.full((2, 3), 5)
print(T.sum())
```

## UXM Bellek Haritası

```text
D:500 = Tensor descriptor + data

T-4 = tensor base
T-3 = dim0 veya value
T-2 = dim1
T-1 = reserved
T   = reserved
T+1 = result/status
```

## UXM Kodu

```text
# Tensor 2D sum örneği
#memory tape=128,stack=16,data=4096,queue=16
#cell dword
#mode normal
>>>>>

# Tensor init: base=500, shape=2x3
0(T-4)+k500
0(T-3)+k2
0(T-2)+k3
0(T-1)+k0
0(T)+k0
@540

# Tensor fill: bütün elemanlar 5
0(T-4)+k500
0(T-3)+k5
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@543

# Tensor sum
0(T-4)+k500
0(T-3)+k0
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@544
@61
@5
```

## Çözümleme

Burada UXM'nin tensor sistemi doğrudan Python/Numpy konforunda değildir. Fakat veri düzeni nettir:

```text
Tensor base = D:500
Shape = 2 x 3
Fill value = 5
Sum = 30
```

Bu UXM için çok önemli bir aşamadır. Çünkü tensor descriptor sistemi oturursa:

* 3D tensor,
* 4D tensor,
* broadcasting,
* slice,
* flatten,
* AI layer,
* graph execution

kurulabilir.

## Programcının Çıkarması Gereken Ders

UXM'de tensor bir nesne gibi değil, data segment içinde descriptor ile yönetilen bellek bloğu gibi düşünülmelidir. Python'da `T.sum()` yazılan şey UXM'de `base` adresini hazırlayıp `@544` çağırmaktır.

---

# 9. Örnek 6 — DNA Çeviri ve GC İçeriği

Bu örnek paketteki `test_v33_bio_translate_gc.uxm` mantığına dayanır.

## Amaç

DNA dizisi:

```text
ATGTTTTAA
```

Bu dizi üç codon içerir:

```text
ATG -> M
TTT -> F
TAA -> * stop
```

Beklenen protein çıktısı:

```text
MF*
```

GC yüzdesi:

```text
G ve C sayısı = 2
Toplam uzunluk = 9
GC% = 22
```

## Python Karşılığı

```python
seq = "ATGTTTTAA"
protein = translate(seq)
gc = (seq.count("G") + seq.count("C")) * 100 // len(seq)
print(protein)
print(gc)
```

## UXM Bellek Haritası

```text
s1 / D:0  = DNA stringi
D:32      = protein çıktı buffer

T-4 = src start
T-3 = src len
T-2 = dst start
T-1 = dst max len
T+1 = result length veya result
```

## UXM Kodu

```text
# V3.3 BIO V1: translate DNA and GC percent
# Expected output includes: MF* and 22
# ATG TTT TAA -> M F * ; GC% = 2/9 -> 22
#memory tape=64,stack=8,data=64,queue=4
#cell byte
#mode normal

s1=0,{ATGTTTTAA}
>>>>>

# translate DNA: src=0, len=9, dst=32, max=16
0(T-4)+k0
0(T-3)+k9
0(T-2)+k32
0(T-1)+k16
@483

# print translated protein at D:32
0(T-1)+k32
@313
@!5

# GC content: src=0, len=9
0(T-2)+k0
0(T-1)+k9
@484
@61
@5
```

## Çözümleme

`@483` DNA dizisini amino acid dizisine çevirir. Sonuç `D:32` alanına yazılır. Sonra `@313` string/data yazdırma servisiyle protein çıktısı basılır.

`@484` GC content servisidir. `T-2` başlangıç adresini, `T-1` uzunluğu taşır.

## Programcının Çıkarması Gereken Ders

UXM'nin bio servisleri doğrudan bilimsel iş akışı kurmaya adaydır. Fakat burada da temel mantık aynıdır: veri data segment'tedir, servis adres ve uzunluk alır, sonucu başka bir buffer'a yazar.

---

# 10. Örnek 7 — Motif Arama ve Peptit Tarama Mantığı

Bu örnek paketteki `program_domain_01_biology_gc_peptide_screen.uxm` tarzına dayanır.

## Amaç

DNA dizisi içinde `CG` motifini ara ve GC yüzdesi hesapla.

Dizi:

```text
ATGCGCGTAA
```

Motif:

```text
CG
```

## Python Karşılığı

```python
seq = "ATGCGCGTAA"
motif = "CG"
print(gc_percent(seq))
print(seq.find(motif))
```

## UXM Kodu

```text
# Biology GC + motif screen
#memory tape=128,stack=16,data=4096,queue=16
#cell dword
#mode normal
>>>>>

s1=0,{ATGCGCGTAA}
s2=64,{CG}

# GC content
0(T-4)+k0
0(T-3)+k0
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@484
@61
@5

# motif find: src=0, motif=64
0(T-4)+k0
0(T-3)+k64
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@487
@61
@5
```

## Uyarı

Bu örnekte frame kullanımı test corpus içindeki biçime dayanır. Bio servislerinde bazı çağrılar string uzunluğunu kendisi algılıyor gibi davranabilir. Profesyonel kullanımda `runtime_bio_services.bas` dosyası ve ilgili `.expect` dosyası mutlaka kontrol edilmelidir.

## Programcının Çıkarması Gereken Ders

UXM'de domain-specific yani alan odaklı servislerin gücü büyüktür. DNA, motif, peptide, codon gibi işler doğrudan runtime servislerine bağlanabilir. Bu, UXM'nin sıradan bir dil değil, servis tabanlı bilimsel mini runtime olabileceğini gösterir.

---

# 11. Örnek 8 — Dosyaya Yazma ve Dosyadan Okuma

Bu örnek paketteki `test_v33_file_write_read_line.uxm` dosyasının öğretici düzenlenmiş açıklamasıdır.

## Amaç

Bir dosyaya `HELLO` yaz, sonra aynı dosyadan oku ve ekrana bas.

## Python Karşılığı

```python
with open("uxm_stage5_line.tmp", "w") as f:
    f.write("HELLO
")

with open("uxm_stage5_line.tmp", "r") as f:
    line = f.readline().strip()

print(line)
```

## UXM Bellek Haritası

```text
s1 / D:0   = dosya adı: uxm_stage5_line.tmp
s2 / D:32  = yazılacak satır: HELLO
s3 / D:64  = okuma buffer: EMPTY

T-3 = handle veya name_start
T-2 = dst/src start veya name_len
T-1 = handle/max_len/start
T+1 = handle/result
```

## UXM Kodu

```text
# FILE V1: text write/read line smoke test
# Expected output: HELLO
#memory tape=64,stack=8,data=128,queue=4
#cell byte
#mode normal

s1=0,{uxm_stage5_line.tmp}
s2=32,{HELLO}
s3=64,{EMPTY}
>>>>

# open write: filename at 0
0(T-1)+k0
@401
$(T+1)
%(T-2)

# write line from string/data start 32
0(T-1)+k32
@409

# close write handle
$(T-2)
%(T-1)
@405

# open read
0(T-1)+k0
@400
$(T+1)
%(T-3)

# read line into buffer at 64, max len 32
0(T-2)+k64
0(T-1)+k32
@408

# print string/data at 64
0(T-1)+k64
@313
@!5

# close read handle
$(T-3)
%(T-1)
@405
```

## Çözümleme

Bu örnek UXM'de gerçek program yazmanın nasıl göründüğünü çok iyi gösterir.

Burada yalnızca file servisleri yoktur. Aynı anda:

* string tanımı,
* dosya adı buffer'ı,
* dosya handle'ı,
* stack üzerinden handle saklama,
* data buffer,
* read line,
* string print,
* close

işlemleri vardır.

`@401` dosyayı yazmak için açar. Sonuç handle olarak `T+1` hücresine gelir. Bu handle sonra stack/memory üzerinden korunur. `@409` satır yazar. `@405` dosyayı kapatır. Sonra `@400` okuma için açar. `@408` satır okur. `@313` buffer'ı yazdırır.

## Programcının Çıkarması Gereken Ders

UXM'de dosya işlemleri mümkündür ama yüksek seviyeli dillerdeki gibi otomatik güvenli değildir. Handle saklama ve doğru kapatma programcının sorumluluğundadır. Bu nedenle dosya programlarında bellek haritası ve yorum satırları zorunlu hale gelir.

---

# 12. Örnek 9 — Polinom Hesaplama ve Sayısal İntegral

Bu örnek paketteki `test_v33_numeric_poly_integral.uxm` mantığına dayanır.

## Amaç

Polinom:

```text
f(x) = x^2
```

1. `x=3` için hesapla.
2. 0 ile 2 arasında trapez yöntemiyle integralini hesapla.

Scaled değer kullanıldığı için testte `3` değeri `3000000` gibi ölçekli temsil edilir.

## Python Karşılığı

```python
def f(x):
    return x * x

print(f(3))

# trapezoid integral 0..2
n = 10
h = (2 - 0) / n
area = 0
for i in range(n):
    x0 = i * h
    x1 = (i + 1) * h
    area += (f(x0) + f(x1)) * h / 2
print(area)
```

## UXM Bellek Haritası

```text
D:100 = polynomial metadata / degree
D:101 = coefficient 0
D:102 = coefficient 1
D:103 = coefficient 2

T-4 = polyBase
T-3 = a_scaled
T-2 = b_scaled
T-1 = n veya x_scaled
T+1 = result
```

## UXM Kodu

```text
# Numeric V1: polynomial eval and integration
# Polynomial: f(x)=x^2 at data[100]
#memory tape=64,stack=8,data=256,queue=4
#cell dword
#mode normal
>>>>>

# D:100..D:103 polinom bilgisi
0(T-2)+k100
0(T-1)+k2
@96
0(T-2)+k101
0(T-1)+k0
@96
0(T-2)+k102
0(T-1)+k0
@96
0(T-2)+k103
0(T-1)+k1
@96

# f(3) = 9, scaled 3_000_000
0(T-2)+k100
0(T-1)+k3000000
@420
@61
@5

# integral 0..2 with n=10
0(T-4)+k100
0(T-3)+k0
0(T-2)+k2000000
0(T-1)+k10
@423
@61
@5
```

## Çözümleme

Bu örnekte `@96` data write servisidir. Polinom katsayıları data segment'e yazılır. `@420` polinom evaluate servisidir. `@423` trapezoid integral servisidir.

Bu program bilimsel hesap için UXM'nin potansiyelini gösterir. Fakat aynı zamanda scaled integer mantığına dikkat etmek gerektiğini de gösterir. UXM'de floating point ve scaled integer ayrımı iyi belgelenmelidir.

---

# 13. Örnek 10 — ML ReLU Aktivasyon

Bu örnek paketteki `test_s15_ml_relu.uxm` mantığına dayanır.

## Amaç

ReLU aktivasyon fonksiyonunu uygula.

Python'da:

```python
def relu(x):
    return max(0, x)

print(relu(7))
```

UXM'de:

```text
# ML ReLU örneği
#memory tape=64,stack=8,data=128,queue=4
#cell dword
#mode normal
>>>>>

0(T-4)+k7
0(T-3)+k0
0(T-2)+k0
0(T-1)+k0
0(T)+k0
@700
@61
@5
```

## Çözümleme

`@700` ML_RELU servisidir. Giriş değeri testte `T-4` üzerinden verilir. Sonuç `T+1` veya servis result hücresi üzerinden yazdırılır.

## Programcının Çıkarması Gereken Ders

UXM'de ML tarafı başlangıç aşamasında ama çok önemli bir yöne işaret ediyor: model operasyonları servis olarak eklenebilir. Fakat bu alanın frame/result sözleşmesi daha net belgelenmelidir.

---

# 14. Büyük Program Tasarlama Örneği — Su Ürünleri İçin Yem Dönüşüm Oranı

Şimdi UXM'yi kullanarak gerçek alana yakın bir örnek tasarlayalım. Bu örnek, su ürünleri veya üretim takibi için yararlı olabilir.

## Problem

Bir balık üretim partisinde:

* başlangıç biyokütlesi: 1000 kg
* son biyokütle: 1450 kg
* verilen yem: 720 kg

FCR yani feed conversion ratio hesaplanacak:

```text
FCR = verilen yem / canlı ağırlık artışı
Ağırlık artışı = son biyokütle - başlangıç biyokütlesi
```

Python:

```python
start = 1000
end = 1450
feed = 720
gain = end - start
fcr = feed / gain
print(gain)
print(fcr)
```

BASIC:

```basic
START = 1000
ENDW = 1450
FEED = 720
GAIN = ENDW - START
FCR = FEED / GAIN
PRINT GAIN
PRINT FCR
```

UXM'de byte cell yetmez. Bu nedenle `dword` kullanmak gerekir.

## Bellek Haritası

```text
T-4 = start biomass
T-3 = end biomass
T-2 = feed
T-1 = gain
T+1 = result
```

## UXM Tasarım Mantığı

1. `end - start` hesapla.
2. Sonucu gain olarak sakla.
3. `feed / gain` hesapla.
4. Sonucu yazdır.

## UXM Kodu Taslağı

```text
# FCR hesaplama örneği
#memory tape=128,stack=16,data=256,queue=16
#cell dword
#mode normal
>>>>>

# start=1000, end=1450, feed=720
0(T-4)+k1000
0(T-3)+k1450
0(T-2)+k720

# gain = end - start
# SUB servisi için Arg1/Arg2 düzeni runtime'a göre doğrulanmalıdır.
# Burada T-2/T-1 frame mantığına göre end ve start hazırlanır.
0(T-2)+k1450
0(T-1)+k1000
@21
@61
@5

# FCR = feed / gain
# gain sonucu korunacaksa T+1 başka hücreye alınmalıdır.
# Basit örnekte gain=450 bilindiği için direkt frame kuruluyor.
0(T-2)+k720
0(T-1)+k450
@23
@61
@5
```

## Önemli Yorum

Bu örnek bilinçli olarak bir tasarım örneğidir. Gerçek profesyonel sürümde gain değerini `T+1`'den başka bir hücreye veya stack'e almak gerekir. Çünkü ikinci servis çağrısına hazırlanırken `T-2`, `T-1` değişir.

Daha profesyonel yaklaşım:

```text
1. Gain hesapla.
2. Gain'i D:100 veya stack'e kaydet.
3. Feed / gain için D:100'den geri oku.
4. Bölme sonucunu yazdır.
```

## Ders

UXM'de ara sonuçları korumak önemlidir. Python'da `gain` adında değişken vardır. UXM'de bu değişkenin karşılığı bir hücre veya data adresidir. Programcı onu açıkça belirlemelidir.

---

# 15. Profesyonel UXM Programı Nasıl Klasörlenir?

Bir UXM projesi büyüdüğünde şu klasör sistemi önerilir:

```text
my_uxm_project/
|
+-- src/
|   +-- main.uxm
|   +-- macros.uxm
|   +-- file_io.uxm
|   +-- math_pipeline.uxm
|
+-- tests/
|   +-- smoke/
|   |   +-- test_hello.uxm
|   |   +-- test_add.uxm
|   |
|   +-- service/
|   |   +-- test_file_write_read.uxm
|   |   +-- test_matrix_basic.uxm
|   |
|   +-- integration/
|       +-- test_fcr_report.uxm
|
+-- expected/
|   +-- test_hello.expect
|   +-- test_add.expect
|   +-- test_file_write_read.expect
|
+-- build/
|   +-- asm/
|   +-- obj/
|   +-- exe/
|   +-- logs/
|
+-- reports/
    +-- test_results.csv
    +-- coverage_matrix.md
```

Bu düzen UXM için çok önemlidir. Çünkü dilde servisler çok olduğu için test ve belge olmadan proje yönetilemez.

---

# 16. UXM İçin Test Yazma Disiplini

Her yeni UXM programı için en az iki dosya düşünülmelidir:

```text
program.uxm
program.expect
```

Örnek:

`test_add.uxm`:

```text
# EXPECT_OUTPUT: 15
#memory tape=64,stack=8,data=128,queue=4
#cell byte
#mode normal
>>>>>
0(T-2)+k7
0(T-1)+k8
@20
@61
@5
```

`test_add.expect`:

```text
15
```

Test çalıştırma mantığı:

```text
1. .uxm dosyasını derle.
2. EXE çıktısını al.
3. stdout'u yakala.
4. .expect ile karşılaştır.
5. PASS/FAIL üret.
```

ASCII:

```text
test_add.uxm
     |
     v
build / run
     |
     v
actual output ---- compare ---- test_add.expect
                         |
                         v
                     PASS / FAIL
```

UXM geliştirmede test yalnızca doğrulama değildir; aynı zamanda dil davranışını belgeleyen canlı kılavuzdur.

---

# 17. UXM'de Macro Kullanarak Programı Temizlemek

UXM kodu çok sembolik olduğu için macro kullanmak okunabilirliği artırır.

Örneğin sürekli newline basmak için:

```text
m128={@!5}
```

Sonra:

```text
@128
```

kullanılabilir.

Sürekli sonucu yazdırmak için:

```text
m129={@61@!5}
```

Sonra:

```text
@129
```

Bu, UXM'de küçük DSL benzeri yapı kurar.

Örnek:

```text
# Macro örneği
m128={@!5}
m129={@61@!5}

>>>>>
0(T-2)+k7
0(T-1)+k8
@20
@129
```

Burada `@129`, result print + newline yapar.

Dikkat: Macro ID aralığı kullanıcı için `128..255` olarak düşünülmelidir. Host servisi zorlamak için `@!N` kullanılmalıdır.

---

# 18. UXM ile BASIC/Python Programını Çevirmeye Yöntem

Bir Python programını UXM'ye çevirmek için şu adımlar izlenir:

## Adım 1 — Değişkenleri Bellek Hücrelerine Çevir

Python:

```python
x = 10
y = 20
z = x + y
```

UXM bellek:

```text
T-2 = x
T-1 = y
T+1 = z/result
```

## Adım 2 — Fonksiyonları Servislere Çevir

Python:

```python
z = math.sqrt(x)
```

UXM:

```text
T-1 = x
@46
T+1 = sqrt(x)
```

## Adım 3 — Listeleri Data Segment'e Çevir

Python:

```python
data = [2,4,6,8]
```

UXM:

```text
D:100=2
D:101=4
D:102=6
D:103=8
```

## Adım 4 — Döngüleri Loop veya Servisle Çöz

Python:

```python
sum(data)
```

UXM'de iki seçenek:

```text
1. Elle loop yaz.
2. @261 STAT_SUM servisini kullan.
```

Profesyonel UXM programcısı, hazır servis varsa onu kullanır. Elle loop yalnızca servis yoksa veya özel davranış gerekiyorsa yazılır.

---

# 19. UXM'de Paradigma: “Memory-first Programming”

UXM'nin gerçek paradigması şu şekilde adlandırılabilir:

```text
Memory-first service-oriented VM programming
```

Türkçe anlatımı:

```text
Önce belleği planlayan, sonra küçük komutlarla ve runtime servisleriyle o belleği işleyen programlama tarzı.
```

Bu paradigma Python'dan farklıdır.

Python:

```text
nesne / değişken / fonksiyon / kütüphane
```

UXM:

```text
hücre / pointer / frame / service / status
```

BASIC:

```text
satır / değişken / GOTO / PRINT
```

UXM:

```text
instruction / address / branch / output service
```

Bu yüzden UXM öğrenen kişi aslında yalnızca yeni bir dil değil, makineye yakın düşünme biçimi öğrenir.

---

# 20. UXM'nin Başka Dillerden Farkları

## 20.1 Python'dan Farkı

Python yüksek seviyeli, dinamik, nesne tabanlı ve kütüphane merkezlidir. UXM düşük seviyeli, hücre tabanlı, servis merkezli ve deterministic runtime odaklıdır.

Python'da kolay olan şeyler:

* string işlemleri,
* listeler,
* dosya işlemleri,
* exception,
* object,
* module sistemi.

UXM'de güçlü olan şeyler:

* bellek üzerinde tam kontrol,
* küçük çekirdek,
* servis ID tabanlı genişleme,
* native x64 hedefi,
* sandbox edilebilir çalışma,
* testle sabitlenmiş davranış.

## 20.2 BASIC'ten Farkı

BASIC okunaklı satır komutlarına dayanır. UXM sembolik instruction yapısına dayanır. BASIC'te `PRINT`, `INPUT`, `FOR` gibi kelimeler vardır. UXM'de `@61`, `@63`, branch ve loop vardır.

BASIC daha kolay öğrenilir. UXM daha makineye yakındır.

## 20.3 C'den Farkı

C pointer ve bellek kontrolü verir ama syntax geniştir. UXM de bellek kontrolü verir ama syntax daha küçüktür. C'de type sistemi daha güçlüdür. UXM'de type sistemi runtime service ve cell mode üzerinden ilerler.

## 20.4 Assembly'den Farkı

Assembly CPU register'larına bağlıdır. UXM sanal register ve runtime service modeline bağlıdır. Assembly daha hızlı ve daha donanıma yakındır. UXM daha taşınabilir VM semantiği kurabilir.

## 20.5 Brainfuck'tan Farkı

Brainfuck yalnızca minimal tape dilidir. UXM ise:

* geniş adresleme,
* data segment,
* stack,
* queue,
* macro,
* service registry,
* file I/O,
* matrix,
* tensor,
* bio,
* ML/data pipeline

olan çok daha büyük bir sistemdir.

---

# 21. UXM'nin En Güçlü Yanları

## 21.1 Küçük Çekirdek, Büyük Runtime

UXM'nin en özgün gücü budur. Dil çekirdeği küçük kalır, yetenekler servislerle büyür.

## 21.2 Adresleme Gücü

Relative, absolute, indirect, indexed ve stack-relative adresleme UXM'yi ciddi biçimde güçlendirir.

## 21.3 Bilimsel Servis Potansiyeli

Statistics, matrix, tensor, bio, numerical methods ve ML servisleri, UXM'yi bilimsel mini runtime haline getirebilir.

## 21.4 Test Corpus Zenginliği

Binlerce `.uxm` ve `.expect` dosyası, dilin davranışını belgelemeye başlamıştır.

## 21.5 Native Backend Yönü

NASM x64 assembly üretimi, dilin yalnızca interpreter oyuncağı olmadığını gösterir.

## 21.6 Öğretici Değer

UXM, programcıya bellek, pointer, frame, service, status, test, runtime gibi temel bilgisayar bilimi konularını öğretebilir.

---

# 22. UXM'nin Zayıf Yanları ve Darboğazları

## 22.1 Öğrenme Eğrisi Serttir

Python bilen biri UXM'yi ilk başta zor bulur. Çünkü UXM'de değişken adı yerine hücre planı vardır.

## 22.2 Servis Çakışmaları Vardır

Bazı registry servisleri dispatcher gerçekliğiyle çakışmaktadır. Bu mutlaka düzeltilmelidir.

Özellikle:

```text
@130..@149  compare/flag unreachable bug
@300..@309  hypothesis/string çakışması
@400..@421  file/numeric çakışması
@420..@421  file gibi görünse de numeric dispatcher'a gider
```

## 22.3 Type Sistemi Zayıftır

Cell byte/dword ve servisler var ama compile-time type sistemi güçlü değildir. Tensor shape, matrix type, string buffer type gibi konular daha netleşmelidir.

## 22.4 MIR Katmanı Gerekir

İleri optimizer, WebAssembly backend, JS transpiler, x64/native parity ve static analysis için MIR şarttır.

## 22.5 Branch Sistemi Zordur

Offset tabanlı branch güçlüdür ama okunabilir değildir. Label destekli branch sistemi ileride gerekli olabilir.

## 22.6 Runtime Şişme Riski

Her özellik service olarak eklenirse runtime devasa ve yönetilemez hale gelebilir. Service registry, otomatik dokümantasyon ve kategori disiplini şarttır.

## 22.7 Debugger / Trace Standardı Henüz Tam Oturmamıştır

VSCode ve JSON trace fikri çok değerlidir ama schema, event modeli, timeline ve replay sistemi belirginleşmelidir.

---

# 23. UXM İçin Canonical Geliştirme Kuralları

UXM geliştirirken şu kurallar uygulanmalıdır:

```text
1. Her servis için tek gerçek ID olmalı.
2. Registry ile dispatcher aynı şeyi söylemeli.
3. Her servis için frame/result sözleşmesi yazılmalı.
4. Her servis için en az bir smoke test olmalı.
5. Her servis için bir .expect dosyası olmalı.
6. Patch servisleri canonical hale getirilmeden ana kılavuza aktif diye alınmamalı.
7. Eski kod onceki_src altında kalmalı ama ana runtime'a karışmamalı.
8. Matrix/tensor/string/file gibi servis aileleri ayrı dosyalarda tutulmalı.
9. Testler stage bazında ayrılmalı.
10. CLI, compiler, runtime ve VSCode hatları birbirine karıştırılmamalı.
```

Bu kurallar uygulanmazsa UXM'nin en büyük riski olan “servis kaosu” büyür.

---

# 24. UXM Öğrenme Programı

UXM öğrenmek isteyen biri için 14 günlük yoğun bir yol önerilebilir.

## Gün 1 — Tape ve Pointer

* `+`, `-`, `>`, `<`, `0`, `.` öğren.
* ASCII karakter yazdır.

## Gün 2 — String ve Print

* `sN`, `pN`, escape karakterleri öğren.
* Basit metin çıktıları yaz.

## Gün 3 — Addressing

* `(T+N)`, `(T-N)`, `(D:N)` öğren.
* Aynı işi pointer hareketiyle ve adreslemeyle yaz.

## Gün 4 — Arithmetic Services

* `@20..@29` kullan.
* Toplama, çıkarma, çarpma, bölme testleri yaz.

## Gün 5 — I/O ve Status

* `@5`, `@60`, `@61`, `@69`, `@9`, `@12` öğren.

## Gün 6 — Macro

* `m128` ile küçük yardımcı macro yaz.
* Macro ile tekrarı azalt.

## Gün 7 — Data Segment

* D:100 gibi alanlara veri yaz.
* Data array mantığını öğren.

## Gün 8 — Statistics

* Ortalama, toplam, min, max servislerini kullan.

## Gün 9 — File I/O

* Dosya aç, yaz, oku, kapat.
* Handle mantığını öğren.

## Gün 10 — Matrix

* 2x2 matrix oluştur.
* Matrix set/get/print kullan.

## Gün 11 — Tensor

* 2D tensor init/fill/sum kullan.

## Gün 12 — Bio

* DNA translate, GC content, motif find dene.

## Gün 13 — Numeric Methods

* Polynomial eval ve trapezoid integral kullan.

## Gün 14 — Mini Proje

* File'dan veri oku.
* Data segment'e yaz.
* Ortalama veya matrix/tensor hesapla.
* Sonucu yazdır.
* `.expect` testi oluştur.

Bu eğitim sırası UXM'nin doğal öğrenme yoludur.

---

# 25. UXM Programcısı İçin Kontrol Listesi

Her programdan önce:

```text
[ ] Bellek modeli seçildi mi?
[ ] #memory satırı yazıldı mı?
[ ] #cell byte/dword doğru mu?
[ ] Tape frame güvenli yere taşındı mı?
[ ] T-4..T+1 hücrelerinin anlamı yazıldı mı?
[ ] Data segment alanları çakışıyor mu?
[ ] Kullanılan servis ID'leri dispatcher ile uyumlu mu?
[ ] Patch/çakışmalı servis kullanılmadı mı?
[ ] Beklenen çıktı yazıldı mı?
[ ] .expect dosyası hazır mı?
[ ] Dosya handle'ları kapatıldı mı?
[ ] String buffer'lar üst üste binmiyor mu?
[ ] Ara sonuçlar korunuyor mu?
```

Bu liste uygulanırsa UXM programları daha az hata verir.

---

# 26. UXM ile Profesyonel Bir Program Nasıl Büyütülür?

Küçük programdan profesyonel programa geçiş şöyle olmalıdır:

```text
1. Tek dosyalı smoke test
2. Aynı işin .expect dosyası
3. Bellek haritası yorumları
4. Macro ile tekrar azaltma
5. Servisleri küçük bloklara ayırma
6. Data segment standardı oluşturma
7. Integration test
8. Regression test
9. Coverage matrix
10. Kılavuz güncellemesi
```

Örneğin file + statistics programı şöyle büyütülür:

```text
Aşama 1: D:100..D:103 içine sabit veri yaz.
Aşama 2: @262 ile mean hesapla.
Aşama 3: Veriyi dosyadan oku.
Aşama 4: Her satırı sayıya çevir.
Aşama 5: Data segment'e yaz.
Aşama 6: Statistics servislerini çağır.
Aşama 7: Sonucu dosyaya yaz.
Aşama 8: .expect ile test et.
```

Bu UXM'nin gerçek uygulama geliştirme yoludur.

---

# 27. UXM'nin En Uygun Kullanım Alanları

UXM her iş için doğru dil değildir. Ama bazı alanlarda çok anlamlıdır.

## 27.1 Eğitim ve Bilgisayar Mimarisi

Pointer, memory, stack, service, runtime, status öğrenmek için çok değerlidir.

## 27.2 Embedded / Deterministic Runtime

Sınırlı bellek, kontrollü execution ve küçük komut seti nedeniyle uygundur.

## 27.3 Scientific Mini Runtime

Statistics, matrix, tensor, numeric methods ve bio servisleri nedeniyle bilimsel mikro runtime olabilir.

## 27.4 AI Graph Deneyleri

Tensor, ML/data pipeline ve service dispatch sistemi AI graph execution için kullanılabilir.

## 27.5 Compiler Araştırması

Lexer, parser, addressing, native asm emit, runtime dispatch, test corpus gibi birçok compiler konusu tek projede görülebilir.

---

# 28. UXM'nin Uygun Olmadığı Alanlar

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

# 29. UXM'nin Geleceği İçin En Kritik 10 İş

UXM'yi ciddi bir dile dönüştürmek için öncelik sırası şu olmalıdır:

## 1. Service Registry ve Dispatcher Eşitleme

Registry ne diyorsa dispatcher onu yapmalı. Çakışmalar temizlenmeli.

## 2. Frame Sözleşmeleri Belgesi

Her servis için:

```text
Input: T-4, T-3, T-2, T-1, T
Output: T+1 / Data / Status
Errors: E/status
```

net yazılmalı.

## 3. Label Tabanlı Branch

Offset branch korunabilir ama label branch eklenmelidir:

```text
:label loop_start
:jz loop_end
```

gibi daha okunur yapı gerekir.

## 4. MIR Katmanı

Instruction list ile native asm arasında açık MIR olmalı.

## 5. Type ve Shape Sistemi

Matrix/tensor için shape inference ve type metadata gerekir.

## 6. Service Auto-doc Generator

`service_registry_merged.csv` üzerinden otomatik markdown kılavuzu üretilmeli.

## 7. Test Runner Standardı

Tek komutla:

```text
run_tests --stage 12 --scope smoke
run_tests --stage 12 --scope full
```

çalışmalı.

## 8. VSCode Trace Schema

Runtime event JSON standardı oluşturulmalı.

## 9. Error/Status Kod Kitabı

Her status kodu belgelenmeli.

## 10. Canonical Source Tree

`uxm/core` ana kaynak olmalı. `onceki_src` arşiv olmalı. `guncel_src` demo/bootstrapping olarak tanımlanmalı.

---

# 30. Nihai Yorum

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

Bu dört şart sağlanırsa UXM ciddi bir deneysel compiler/runtime dili olur. Sağlanmazsa çok güçlü fikirlerin olduğu ama kullanımı zor, servisleri çakışan, testleri takip edilemeyen bir araştırma çöplüğüne dönüşür.

Bu nedenle UXM için doğru yol:

```text
1. Canonical kaynak ağacı
2. Temiz service registry
3. Frame/result belgeleri
4. Stage bazlı test sistemi
5. MIR + native backend standardı
6. VSCode trace/debug arayüzü
7. Bilimsel/tensor/bio/ML servislerinin kontrollü büyütülmesi
```

şeklindedir.

---

# 31. Son Kullanıcıya Kısa Öğüt

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
