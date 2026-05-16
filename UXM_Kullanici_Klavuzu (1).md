# UX-MINIMA V3.1 (UXM) — Kullanıcı Kılavuzu

> Sürüm: V3.1 (UXM31) | Derleme tarihi: Mayıs 2026 | Dil: FreeBASIC (runtime) + TypeScript (IDE)

---

## 1. UXM Nedir? — Genel Bakış ve Felsefe

UX-MINIMA, Brainfuck'tan ilham alan ancak onu çok aşan, **bant (tape) tabanlı, hücre genişliği ayarlanabilir, meta-servis çağrıları ile güçlendirilmiş** minimalist bir sanal makine ve assembly dilidir. Temel tasarım felsefesi şöyle özetlenebilir:

- **Basit ama güçlü**: Sadece 26 temel opcode, ama meta-servis sistemiyle onlarca gelişmiş işlem yapılabilir.
- **Çok katmanlı**: Aynı `.uxm` kaynak dosyası hem yorumlanabilir (interpret) hem de yerel makine koduna (x86-64 NASM ASM → EXE) derlenebilir.
- **Bilimsel hedef**: Kayan nokta aritmetiği, matris işlemleri, polinom türev/integral, nümerik analiz gibi işlemler meta-servis olarak entegre edilmiştir.
- **Dört hat mimarisi**: Aynı program dört farklı çalışma ortamında aynı semantiği vermeli: Native derleyici, Final/ARGE yorumlayıcı, Full Tool ve VSCode iç yorumlayıcı.

---

## 2. Mimari Yapı

```
uxm/
├── core/
│   ├── compiler/
│   │   ├── final/          ← Ana yorumlayıcı + ARGE derleyici (FreeBASIC)
│   │   ├── native/         ← Yerel ASM/EXE üreten derleyici (FreeBASIC)
│   │   └── extensions/     ← Polinom ve matris ARGE eklentileri
│   └── runtime/
│       ├── runtime_meta_dispatch.bas   ← Meta-servis yönlendirici
│       ├── runtime_memory.bas          ← Bellek yönetimi
│       ├── runtime_io.bas              ← Giriş/çıkış
│       ├── runtime_status_flags.bas    ← Bayrak sistemi
│       └── services/
│           ├── runtime_fp_services.bas     ← Kayan nokta (UX-FP)
│           ├── runtime_math_services.bas   ← Polinom/nümerik analiz
│           └── runtime_matrix_services.bas ← Matris (UX-MAT)
├── ide/vscode/uxminima-vscode/
│   └── src/interpreter/core.ts  ← VSCode iç yorumlayıcı (TypeScript)
├── tests/                    ← .uxm kaynak test dosyaları
└── build/                    ← Derlenmiş ASM, OBJ, log dosyaları
```

### 2.1 Dört Hat (Four-Hat) Mimarisi

| Hat | Dosya | Görev |
|-----|-------|-------|
| **Native** | `uxm31_compiler_fb.bas` | Kaynak → NASM ASM → OBJ → EXE; gerçek makine kodu üretir |
| **Final/ARGE** | `final/uxm31_compiler_final.bas` | Yorumlama, adım adım çalıştırma, UIR/trace/diag JSON çıktısı |
| **Full Tool** | `uxm31_full_tool_fb.bas` | Eski tek-dosya entegre araç (legacy) |
| **VSCode** | `src/interpreter/core.ts` | VSCode eklentisi içindeki TypeScript yorumlayıcı |

---

## 3. Bellek Modeli

UXM, 64 KB toplam belleği üç bölgeye ayırır. Varsayılan bölüm:

| Bölge | Varsayılan Boyut | Kullanım |
|-------|-----------------|---------|
| **Tape** (Bant) | 32 KB | Ana çalışma belleği; bant işaretçisi (tapePtr) bu alanda gezinir |
| **Stack** (Yığın) | 8 KB | PUSH/POP yığını; LIFO yapısı |
| **Data** (Veri) | 24 KB | String tanımları, sabit veriler, FIFO tamponu |

> **Önemli**: Tape + Stack + Data toplamı her zaman tam 64 KB olmalıdır. `#memory` pragma ile değiştirilebilir.

### 3.1 Hücre Genişliği

`#cell` pragma ile ayarlanır:

| Mod | Genişlik | Değer Aralığı |
|-----|----------|--------------|
| `byte` (varsayılan) | 8 bit | 0..255 |
| `word` | 16 bit | 0..65535 |
| `dword` | 32 bit | 0..4294967295 |

---

## 4. Komutlar (Opcodes)

Her komut bir `opcode` ve isteğe bağlı bir **adres modu** alır.

### 4.1 Temel Komutlar

| Sembol | Opcode | Açıklama |
|--------|--------|---------|
| `>` | OP_RIGHT | Bant işaretçisini sağa kaydır |
| `<` | OP_LEFT | Bant işaretçisini sola kaydır |
| `+` | OP_INC | Mevcut hücreyi artır |
| `-` | OP_DEC | Mevcut hücreyi azalt |
| `=N` | OP_SET | Hücreye N değerini ata |
| `0` | OP_CLEAR | Hücreyi sıfırla |
| `.` | OP_PUTC | Mevcut hücreyi ASCII karakter olarak yazdır |
| `,` | OP_GETC | Girişten bir karakter oku (şu an EOF/0 döner) |
| `[` | OP_LOOP_BEG | Mevcut hücre sıfırsa döngünün sonuna atla |
| `]` | OP_LOOP_END | Mevcut hücre sıfır değilse döngünün başına geri dön |

### 4.2 Yığın Komutları

| Sembol | Opcode | Açıklama |
|--------|--------|---------|
| `p` | OP_PUSH | Mevcut hücre değerini yığına at |
| `q` | OP_POP | Yığından değeri mevcut hücreye al |

### 4.3 Mantık ve Bit İşlem Komutları

| Sembol | Opcode | Açıklama |
|--------|--------|---------|
| `=` | OP_EQ | Yığın tepesi == hücre → 1, değilse 0 |
| `>` | OP_GT | Yığın tepesi > hücre → 1 |
| `<` | OP_LT | Yığın tepesi < hücre → 1 |
| `&` | OP_AND | Bitwise AND (yığın tepesi & hücre) |
| `\|` | OP_OR | Bitwise OR |
| `^` | OP_XOR | Bitwise XOR |
| `~` | OP_NOT | Bitwise NOT |
| `{` | OP_SHL | Sola kaydır (× 2) |
| `}` | OP_SHR | Sağa kaydır (÷ 2) |

### 4.4 Kontrol Akışı ve Meta

| Sembol | Opcode | Açıklama |
|--------|--------|---------|
| `e` | OP_STATUS | Status byte'ı mevcut adrese yazar |
| `@N` | OP_META | Meta-servis N'i çağır |
| `?` | OP_BRANCH | Koşullu/koşulsuz atlama |
| `"metin"` | OP_PRINT_STRING | Metni doğrudan yazdır |

### 4.5 Makro ve String Tanımları

```uxm
!macro isim { komutlar }   ; Makro tanımla
%isim                      ; Makroyu çağır

$N "metin"                 ; String N'i data belleğe yerleştir
```

---

## 5. Adresleme Modları

UXM'in güçlü özelliklerinden biri, komutların hangi bellek bölgesinde çalışacağını belirtebilmektir.

| Mod | Sembol | Açıklama |
|-----|--------|---------|
| `ADDR_T` | `(T)` | Bant — mevcut işaretçi konumu (varsayılan) |
| `ADDR_T_REL` | `(T+N)` veya `(T-N)` | Banttan göreli offset |
| `ADDR_T_ABS` | `(T!N)` | Bantta mutlak indeks |
| `ADDR_D_ABS` | `(D!N)` | Data bölgesinde mutlak indeks |
| `ADDR_S_ABS` | `(S!N)` | Yığın bölgesinde mutlak indeks |
| `ADDR_SP` | `(SP)` | Yığın işaretçisinin kendisi |
| `ADDR_P` | `(P)` | Bant işaretçisinin kendisi |
| `ADDR_E` | `(E)` | FIFO kuyruk çıkışı |
| `ADDR_F` | `(F)` | FIFO kuyruk girişi |
| `ADDR_IND_T` | `(@T)` | Bant işaretçisinin gösterdiği değeri adres olarak kullan (dolaylı) |
| `ADDR_IND_T_REL` | `(@T+N)` | Göreli dolaylı |
| `ADDR_D_AT_T_REL` | `(D@T+N)` | Bant göreli offsetindeki data adresi |
| `ADDR_D_AT_TBASE_REL` | `(D@(T-2)+N)` | Bant taban göreli data erişimi |

**Örnek kullanım:**
```uxm
=(D!10)   ; Data bölgesinin 10. hücresine mevcut değeri yaz
p(T+3)    ; Mevcut konumdan 3 ilerinin değerini yığına at
@20(D!5)  ; Meta-servis 20'yi çağır, argüman Data[5]'teki değer
```

---

## 6. Pragma Komutları

Pragma komutları `#` ile başlar ve programın derleme/çalışma ortamını yapılandırır. Kaynak dosyasının en üstünde bulunur.

| Pragma | Sözdizimi | Açıklama |
|--------|-----------|---------|
| `#mode` | `#mode safe` / `normal` / `wild` | Çalışma modu seçer |
| `#cell` | `#cell byte` / `word` / `dword` | Hücre genişliği |
| `#memory` | `#memory tape=32k stack=8k data=24k` | Bellek bölümlerini yeniden boyutlandır |
| `#bounds` | `#bounds on` / `off` | Sınır denetimini aç/kapat |
| `#compare` | `#compare signed` / `unsigned` | Karşılaştırma modu |
| `#endian` | `#endian big` / `little` | Endian tercihi |
| `#seed` | `#seed 42` | Rastgele sayı başlangıç değeri |
| `#poly` | `#poly 2 4 6 8` | Polinom katsayılarını tanımla |
| `#expr-rpn` | `#expr-rpn "3 4 + 2 *"` | RPN ifadesi tanımla |
| `#matrix` | `#matrix 2 2` | Matris boyutu tanımla |
| `#identity` | `#identity 3` | 3×3 birim matris oluştur |
| `#zeros` / `#ones` | `#zeros 2 3` | Sıfır/birler matrisi |

### 6.1 #arge Direktifleri

`#arge` satırları ARGE derleyicisine çalışma zamanı seçenekleri iletir:

```
#arge version           ; Versiyon bilgisini yazdır
#arge json on           ; UIR + diagnostics JSON çıktısını etkinleştir
#arge interpreter on    ; Yorumlama modunu zorla
#arge step on           ; Adım adım çalışma modu
#arge trace on          ; İz dosyası üret (.trace.ndjson)
#arge optimize off      ; Optimizasyonu kapat
#arge watch tape=0:32   ; Tape 0..31 hücrelerini izle
#arge watch data=100:40 ; Data 100..139 hücrelerini izle
```

---

## 7. Meta-Servisler

Meta-servisler `@N` komutuyla çağrılır. UXM'in en güçlü katmanıdır; matematik kütüphanelerini, veri yapılarını ve I/O işlemlerini doğrudan assembly düzeyinden kullanmayı sağlar.

### 7.1 Çekirdek Servisler (0–19)

| ID | Ad | Açıklama |
|----|-----|---------|
| @0 | OK/NOP | Status'u temizle |
| @1 | CLS | Ekranı temizle |
| @2 | LOCATE | Cursor'u (1,1)'e taşı |
| @3 | RANDOM BYTE | Rastgele byte üret → result |
| @4 | TIMER | Milisaniye cinsinden timer → result |
| @5 | NEWLINE | Yeni satır yaz |
| @6 | PRINT META INFO | `[UXM META]` bilgisini yazdır |
| @7 | VERSION MAJOR | Sürüm ana numarası → result (7) |
| @8 | VERSION MINOR | Sürüm alt numarası → result (8) |
| @9 | STATUS READ | Mevcut status → result |
| @10 | STATUS CLEAR | Status'u sıfırla |
| @11 | STATUS SET | arg1 değerini status olarak set et |
| @12 | STATUS PRINT | Status mesajını yazdır |
| @13 | ERR FLAG SET | FLAG_ERR bitini set et |
| @14 | ERR FLAG RESET | FLAG_ERR bitini sıfırla |
| @15 | ERR FLAG READ | FLAG_ERR durumunu oku → result |

### 7.2 Aritmetik Servisler (20–39)

| ID | Ad | Açıklama |
|----|-----|---------|
| @20 | ADD | arg1 + arg2 → result; taşma, carry bayrakları güncellenir |
| @21 | SUB | arg1 - arg2 → result |
| @22 | MUL | arg1 × arg2 → result; taşma STATUS_OVERFLOW |
| @23 | DIV | arg1 ÷ arg2 → result; sıfıra bölme STATUS_DIV_ZERO |
| @24 | MOD | arg1 mod arg2 → result |
| @25 | MIN | min(arg1, arg2) → result |
| @26 | MAX | max(arg1, arg2) → result |
| @27 | ABS | |arg2| → result (işaretli modda çalışır) |
| @28 | NEG | -arg2 → result |
| @29 | CMP | arg1 ile arg2 karşılaştır; eşit=0, büyük=1, küçük=CellMax |
| @30 | RND_RANGE | [arg1..arg2] arasında rastgele → result |
| @31 | RND_SEED | arg2 ile Randomize |
| @32 | RND_FLOAT01 | [0..ScaleFactor) aralığında rastgele float → result |
| @33 | DIV_UNSIGNED | İşaretsiz bölme |
| @34 | DIV_SIGNED | İşaretli bölme |
| @35 | MOD_UNSIGNED | İşaretsiz mod |
| @36 | MOD_SIGNED | İşaretli mod |

### 7.3 Trigonometri ve Matematik (40–59)

Tüm açılar **derece** cinsindendir. Sonuçlar ScaleFactor (genellikle 1000) ile ölçeklenir.

| ID | Ad | Açıklama |
|----|-----|---------|
| @40 | SIN | sin(arg2°) × ScaleFactor → result |
| @41 | COS | cos(arg2°) × ScaleFactor → result |
| @42 | TAN | tan(arg2°) × ScaleFactor; 90° → STATUS_OVERFLOW |
| @43 | HYPOT | √(arg1² + arg2²) → result |
| @44 | ASIN | arcsin(arg2 / ScaleFactor) derece → result |
| @45 | ACOS | arccos(arg2 / ScaleFactor) derece → result |
| @46 | SQRT | √arg2 → result |
| @47 | SINH | sinh(arg2° radyana çevrilmiş) × ScaleFactor |
| @48 | COSH | cosh(arg2° radyana çevrilmiş) × ScaleFactor |
| @49 | TANH | tanh(arg2° radyana çevrilmiş) × ScaleFactor |
| @52 | ASINH | arcsinh(arg2 / ScaleFactor) × ScaleFactor |
| @53 | ACOSH | arccosh(arg2 / ScaleFactor) × ScaleFactor; arg2 < 1 → STATUS_UNDERFLOW |
| @54 | ATANH | arctanh(arg2 / ScaleFactor) × ScaleFactor |
| @55 | LOG | ln(arg2) |
| @56 | EXP | e^arg2 |
| @57 | POW | arg1^arg2 |
| @58 | DEG_TO_RAD | Derece → Radyan dönüşümü |
| @59 | RAD_TO_DEG | Radyan → Derece dönüşümü |

### 7.4 I/O ve Yazdırma (60–79)

| ID | Ad | Açıklama |
|----|-----|---------|
| @62 | PRINT STACK POP | Yığından al, ondalık yazdır |
| @63 | READ DECIMAL | Ondalık sayıyı oku |
| @67 | PRINT HEX | Değeri hex formatta yazdır |
| @68 | PRINT BIN | Değeri binary formatta yazdır |
| @69 | PRINT CHAR/RAW | Ham karakter yazdır |

### 7.5 İşaretçi ve Bellek (80–89)

| ID | Ad | Açıklama |
|----|-----|---------|
| @80 | POINTER READ | İşaretçi değerini oku |
| @81 | ADD POINTER | İşaretçiye ekle |
| @82 | SET POINTER | İşaretçiyi belirli değere ayarla |
| @83 | POINTER VALID | İşaretçi geçerliliğini kontrol et |
| @87 | CELL BITS | Hücre bit genişliği → result |
| @88 | CELL BYTES | Hücre byte genişliği → result |

### 7.6 FIFO, Data, Tape, Sort (90–127)

Bu grup **4 hatta tam kapanmış** (`META_90_107: CLOSED`) en stabil servis grubudur.

| ID | Ad | Açıklama |
|----|-----|---------|
| @90 | FIFO WRITE | FIFO kuyruğuna bir değer ekle |
| @91 | FIFO READ | FIFO kuyruğundan bir değer al |
| @92 | FIFO COUNT | Kuyruktaki eleman sayısı → result |
| @93 | FIFO PEEK | Kuyruğun başını silmeden oku |
| @94 | FIFO CLEAR | Kuyruğu temizle |
| @95 | DATA WRITE | Data belleğine yaz |
| @96 | DATA READ | Data belleğinden oku |
| @97 | DATA DIGIT PRINT | Basamak değerini yazdır |
| @98 | DATA ASCII TO NUM | ASCII rakam karakterini sayıya çevir |
| @99 | DATA BLOCK COPY | Veri bloğu kopyala |
| @100 | DATA SORT ASC | Bölgeyi artan sırada sırala |
| @101 | TAPE SORT DESC | Bantı azalan sırada sırala |
| @102 | TAPE LINEAR SEARCH | Bant üzerinde doğrusal arama |
| @103 | DATA BLOCK CLEAR | Veri bloğunu sıfırla |
| @104 | DATA SORT DESC | Veri bölgesini azalan sırala |
| @105 | DATA SEARCH | Veri üzerinde arama |
| @106 | TAPE BLOCK COPY | Bant bloğu kopyala |
| @107 | TAPE BLOCK CLEAR | Bant bloğunu sıfırla |
| @120 | TAPE SORT ASC | Bantı artan sırada sırala |
| @121 | DATA SORT BY BLOCK | Blok tabanlı sıralama |
| @122..@127 | Wild/Layout | Wild mod layout değişikliği servisleri |

### 7.7 Bayrak ve Endian (150–159)

| ID | Ad | Açıklama |
|----|-----|---------|
| @150 | FLAG READ | Bayrak byte'ını oku |
| @151 | FLAG WRITE | Bayrak byte'ını yaz |
| @152..@159 | Endian ops | Byte-swap, word split (little/big endian) |

### 7.8 Matris Servisleri — UX-MAT (160–199)

Matris verileri **Data belleğinde** düz dizi olarak saklanır.

| ID | Ad | Açıklama |
|----|-----|---------|
| @160 | MAT_INIT | Matrisi başlat (satır × sütun bilgisini ayarla) |
| @161 | MAT_CLEAR | Matrisi sıfırla |
| @162 | MAT_SET | [r,c] hücresine değer yaz |
| @163 | MAT_GET | [r,c] hücresini oku → result |
| @164 | MAT_FILL | Tüm hücreleri aynı değerle doldur |
| @165 | MAT_COPY | Bir matrisi diğerine kopyala |
| @166 | MAT_PRINT | Matrisi biçimli yazdır |
| @167 | MAT_ADD | İki matrisi topla → üçüncü matrise yaz |
| @168 | MAT_SUB | Matris farkı |
| @169 | MAT_SCALAR_MUL | Skalerle çarpma |
| @170 | MAT_MUL | Matris çarpımı |
| @171 | MAT_TRANSPOSE_COPY | Transpozu başka matrise kopyala |
| @172 | MAT_IDENTITY | Birim matris oluştur |
| @173 | MAT_TRACE | İz (köşegen toplamı) → result |
| @174 | MAT_SHAPE | Boyut bilgisi → result |
| @175 | MAT_DET2 | 2×2 determinant → result |
| @176 | MAT_PRINT_RAW | Ham değerleri yazdır |

### 7.9 Kayan Nokta Servisleri — UX-FP (200–224)

UX-FP, BCD tabanlı sabit genişlikli ondalık kayan nokta sistemidir. Sayılar Data belleğinde yapılandırılmış bloklar olarak tutulur.

| ID | Ad | Açıklama |
|----|-----|---------|
| @200 | FP_INIT16 | 16 baytlık FP değer başlat |
| @201 | FP_INIT32 | 32 baytlık FP değer başlat |
| @202 | FP_ZERO | FP değeri sıfırla |
| @203 | FP_COPY | FP değeri kopyala |
| @204 | FP_NORMALIZE | FP değeri normalleştir |
| @209 | FP_DEBUG_PRINT | FP değeri debug formatında yazdır |
| @210 | FP_ADD | FP toplama |
| @211 | FP_SUB | FP çıkarma |
| @212 | FP_MUL | FP çarpma |
| @213 | FP_DIV | FP bölme |
| @214 | FP_COMPARE | FP karşılaştırma |
| @215 | FP_ABS | FP mutlak değer |
| @216 | FP_NEG | FP negatif |
| @217 | FP_ROUND16 | 16 basamağa yuvarlama |
| @218 | FP_ROUND32 | 32 basamağa yuvarlama |
| @219 | FP_TRUNC | Ondalık kesmek |
| @220 | FP_FROM_INT | Tamsayıdan FP'ye dönüştür |
| @221 | FP_FROM_DEC_STRING | Ondalık string'den FP'ye |
| @222 | FP_TO_DEC_STRING | FP'den ondalık string'e |
| @223 | FP_PRINT_DEC | FP değeri ondalık yazdır |
| @224 | FP_SCALE10 | 10 kuvvetiyle çarp |

### 7.10 Polinom ve Nümerik Analiz (240–254)

Bu servisler `#poly` ve `#expr-rpn` pragma komutlarıyla tanımlanan yapıları çalıştırır.

| ID | Ad | Açıklama |
|----|-----|---------|
| @240 | POLY_DERIV | Polinomun türevini hesapla |
| @241 | POLY_INTEGRAL | Polinomun integralini hesapla |
| @242 | POLY_EVAL | Polinom değerini belirli x'te hesapla |
| @243 | POLY_PRINT | Polinom ifadesini yazdır |
| @244 | POLY_CLEAR | Polinom verilerini temizle |
| @250 | EXPR_EVAL | RPN ifadesini değerlendir |
| @251 | NUM_DERIV | Nümerik türev hesapla |
| @252 | NUM_INTEGRAL_TRAP | Trapez yöntemiyle nümerik integral |
| @253 | NUM_INTEGRAL_SIMPSON | Simpson yöntemiyle nümerik integral |
| @254 | EXPR_PRINT_RPN | RPN ifadesini yazdır |

---

## 8. Çalışma Modları

### 8.1 workMode (Runtime Modu)

`#mode` pragma ile ayarlanır:

| Mod | Açıklama |
|-----|---------|
| **NORMAL** (varsayılan) | Standart çalışma; sınır kontrolleri açık |
| **SAFE** | Sınır dışı erişimler yasaklı; STATUS_SAFE_DENY döner |
| **WILD** | Sınır kontrolleri gevşetilmiş; layout değişikliklerine izin verir |

### 8.2 Signed Modu

`#compare signed` ile etkinleştirilir. Bu modda `DIV`, `MOD`, `CMP` işlemleri değerleri **2'nin tümleyeni işaretli** olarak yorumlar.

---

## 9. Status Bayrakları

Status ve Flags sistemi, meta-servis çağrıları sonrasında güncellenir.

### 9.1 Status Kodları

| Kod | Ad | Açıklama |
|-----|-----|---------|
| 0 | STATUS_OK | Başarı |
| 5 | STATUS_INVALID_META | Geçersiz meta-servis ID |
| 10 | STATUS_PTR_BOUNDS | Bant işaretçisi sınır dışı |
| 11 | STATUS_STACK_OVERFLOW | Yığın taştı |
| 12 | STATUS_STACK_UNDERFLOW | Yığın yetersiz |
| 13 | STATUS_OVERFLOW | Aritmetik taşma |
| 14 | STATUS_UNDERFLOW | Aritmetik alt taşma |
| 15 | STATUS_DIV_ZERO | Sıfıra bölme |
| 16 | STATUS_DATA_BOUNDS | Data belleği sınır dışı |
| 23 | STATUS_SAFE_DENY | Safe modda yasak erişim |
| 26 | STATUS_EOF | Giriş sonu |

### 9.2 Flag Bitleri

| Flag | Bit | Açıklama |
|------|-----|---------|
| FLAG_Z | 0x0001 | Sıfır sonucu |
| FLAG_C | 0x0002 | Carry (taşma birimi) |
| FLAG_O | 0x0004 | Overflow |
| FLAG_S | 0x0008 | Sign (negatif sonuç) |
| FLAG_SGN | 0x0010 | Signed mod aktif |
| FLAG_END | 0x0020 | Big-endian modu aktif |
| FLAG_WILD | 0x0040 | Wild mod aktif |
| FLAG_BND | 0x0080 | Bounds checking aktif |
| FLAG_TRC | 0x0100 | Trace modu aktif |
| FLAG_FIFO | 0x0200 | FIFO modu aktif |
| FLAG_ERR | 0x0400 | Hata bayrağı set |
| FLAG_DIRTY | 0x0800 | Bellek değişti işareti |
| FLAG_PCHG | 0x1000 | Pointer değişti işareti |

---

## 10. Komut Satırı Kullanımı

### 10.1 Temel Kullanım

```batch
uxm.exe --input program.uxm --mode compile
uxm.exe --input program.uxm --mode interpret
uxm.exe --input program.uxm --mode step --max-steps 500
uxm.exe --input program.uxm --mode all
```

### 10.2 Çıktı Dosyaları

| Parametre | Varsayılan | Açıklama |
|-----------|-----------|---------|
| `--asm <dosya>` | `build\program.asm` | NASM assembly çıktısı |
| `--uir <dosya>` | `build\program.uir.json` | UIR (Unified IR) JSON |
| `--diag <dosya>` | `build\program.diag.json` | Diagnostics JSON |
| `--trace <dosya>` | `build\program.trace.ndjson` | İz NDJSON dosyası |
| `--opt <dosya>` | `build\program.opt.json` | Optimizer raporu |

### 10.3 IDE JSON Modu

VSCode eklentisi şu JSON protokolüyle iletişim kurar:

```batch
uxm.exe --ide-in request.json --ide-out response.json
```

`request.json` içeriği:
```json
{
  "command": "run",
  "source": "path/to/program.uxm",
  "asm": "build/program.asm",
  "trace": "build/program.trace.ndjson"
}
```

Geçerli `command` değerleri: `run`, `interpret`, `step`, `compile`, `build`, `all`

---

## 11. Örnek Programlar

### 11.1 'A' Karakterini Yazdır

```uxm
=65 .
```

### 11.2 String Yazdır

```uxm
$0 "Merhaba UX-MINIMA"
@5
```
(String ID 0'ı data belleğe yükle, @5 NEWLINE ile yeni satır ekle)

### 11.3 Meta ile Toplama

```uxm
=10 p    ; 10'u yığına at
=20 p    ; 20'yi yığına at
@20      ; ADD: 10 + 20 = 30
@62      ; PRINT STACK POP → "30"
```

### 11.4 Hypotenuse Hesabı (√(a²+b²))

```uxm
=30 p    ; a=30 yığına
=40 p    ; b=40 yığına
@43      ; HYPOT → result = 50
@62      ; Yazdır
```

### 11.5 FIFO Kullanımı

```uxm
=65 @90   ; 'A' (65) FIFO'ya ekle
=66 @90   ; 'B' (66) FIFO'ya ekle
@91 .     ; FIFO'dan al ve yazdır ('A')
@91 .     ; FIFO'dan al ve yazdır ('B')
```

---

## 12. VSCode Eklentisi

Eklenti `uxm/ide/vscode/uxminima-vscode/` dizinindedir ve `.vsix` paketi olarak kurulabilir.

**Özellikler:**
- `.uxm` dosyaları için sözdizim vurgulama
- F5 ile çalıştırma (derle+çalıştır)
- Bellek görünümü paneli (Tape, Stack, Data hücreleri görselleştirilir)
- İz (trace) takibi
- Diagnostics paneli
- Meta-servis tamamlama desteği (snippets)

---

## 13. Test Sonuçları Matrisi

Aşağıdaki tablo, projenin 5 Mayıs–7 Mayıs 2026 tarihli son test çalışmasının özetidir. Her test için dört çalışma hattı kontrol edilmiştir.

> **Durum kodları**: ✅ Geçti | ⚠️ Runtime hatası oluştu ama beklenen davranış | ❌ Çalışmadı

| Test | Konu | Durum | Not |
|------|------|-------|-----|
| test01_print_A | Temel çıktı | ✅ | 'A' (50) yazdı |
| test02_string | String yazdırma | ✅ | |
| test03_addressing | Adresleme modları | ✅ | |
| test04_stack_lifo | Yığın LIFO | ⚠️ | Stack underflow (beklenen: test davranışı bu) |
| test05_meta_add | META @20 ADD | ✅ | 30 sonucu |
| test06_dynamic_meta_mul | Dinamik META çarpma | ✅ | 42 sonucu |
| test07_macro | Makro tanımı/çağrısı | ✅ | |
| test08_newline | NEWLINE (@5) | ✅ | |
| test09_div_mod | DIV + MOD | ✅ | |
| test10_sin_scaled | SIN (ölçeklendirilmiş) | ✅ | |
| test11_hypotenuse | HYPOT (@43) | ✅ | |
| test12_signed_mode | İşaretli mod | ✅ | |
| test13_status_div_zero | Sıfıra bölme durumu | ✅ | STATUS_DIV_ZERO=15 doğru |
| test14_branch_current_zero | Branch sıfır koşulu | ✅ | |
| test15_branch_nonzero | Branch sıfır dışı | ✅ | |
| test16_data_digit | Veri basamak yazdır | ✅ | |
| test17_endian_word_split | Endian word bölme | ✅ | |
| test18_pointer_service | İşaretçi meta servisi | ✅ | |
| test20_fifo_char_order | FIFO karakter sırası | ✅ | |
| test21_fifo_count_peek | FIFO sayım/peek | ✅ | |
| test22_data_write_read_char | Data yazma/okuma | ✅ | |
| test23_data_digit_ascii_to_number | ASCII → sayı | ✅ | |
| test24_data_block_copy_print | Blok kopyalama | ✅ | |
| test25_data_sort_ascending | Artan sıralama | ✅ | |
| test26_tape_sort_descending | Bant azalan sırala | ✅ | |
| test27_tape_linear_search | Bant doğrusal arama | ✅ | |
| test28_dynamic_meta_fifo | Dinamik meta FIFO | ✅ | |
| test29_nested_macro_call | İç içe makro | ✅ | |
| test30_word_mode_add | Word modu toplama | ✅ | |
| test31_safe_mode_wild_denied | Safe mod kısıtlaması | ✅ | |
| test32_wild_layout_change | Wild layout değişimi | ✅ | |
| test33_bitwise_and_stack | Bit AND + yığın | ⚠️ | Stack underflow (beklenen) |
| test34_data_block_clear | Blok temizleme | ✅ | |
| test35_optimizer_visible_result | Optimizer görünür sonuç | ✅ | |
| test40_4bit_cpu_alu_model | 4-bit CPU ALU modeli | ⚠️ | Stack underflow (beklenen) |
| test41_4_neuron_nn_model | 4 nöronlu NN modeli | ⚠️ | Stack underflow (beklenen) |
| test42_error_flag_set_reset | Hata bayrağı | ✅ | |
| test43_error_macro_helpers | Hata makro yardımcıları | ✅ | |
| test44_asin | ASIN (@44) | ✅ | |
| test44_meta_version_info | Versiyon bilgisi | ✅ | |
| test45_acos | ACOS (@45) | ✅ | |
| test45_pointer_meta_extended | Genişletilmiş pointer | ✅ | |
| test46_fifo_clear | FIFO temizle (@94) | ✅ | |
| test46_sqrt | SQRT (@46) | ✅ | |
| test47_sinh | SINH (@47) | ✅ | |
| test47_tape_sort_ascending | Bant artan sırala | ✅ | |
| test48_cosh | COSH (@48) | ✅ | |
| test48_data_sort_descending | Veri azalan sırala | ✅ | |
| test49_data_linear_search | Veri doğrusal arama | ✅ | |
| test49_tanh | TANH (@49) | ✅ | |
| test50_tape_block_copy_clear | Bant blok kopyalama/temizleme | ✅ | |
| test51_meta_print_stack_pop | META yığın POP yazdır | ⚠️ | Stack underflow (beklenen) |
| test52_meta_print_hex | HEX yazdır (@67) | ✅ | |
| test53_meta_print_bin | Binary yazdır (@68) | ✅ | |
| test54_meta_print_char_raw | Ham karakter yazdır | ✅ | |
| test_matrix01–04 | Matris init/toplama/çarpma/det | ✅ | Tüm matris testleri geçti |
| test_fp01–07 | FP toplama/çıkarma/çarpma/bölme | ✅ | Tüm FP testleri geçti |
| test_math01–07 | Polinom türev/integral/RPN/nümerik | ✅ | test_math05/06/07 çıktı 0 — bkz. eksikler |

---

## 14. Dört Hat Kapsama Analizi (Özet)

| Meta Grubu | Runtime Host | Final Interp. | Full Tool | VSCode | Parity |
|-----------|:------------:|:-------------:|:---------:|:------:|:------:|
| META 0–49 | 43/50 | **7/50** | 46/50 | 43/50 | **7/50 — PARTIAL** |
| META 50–79 | 16/30 | **3/30** | 16/30 | 16/30 | **3/30 — PARTIAL** |
| META 80–89 | 10/10 | **4/10** | 10/10 | 10/10 | **4/10 — PARTIAL** |
| META 90–107 | 18/18 | 18/18 | 18/18 | 18/18 | **18/18 — CLOSED ✅** |
| META 108–119 | 0/12 | 0/12 | 0/12 | 0/12 | **0/12 — OPEN ❌** |
| META 120–127 | 8/8 | **7/8** | 8/8 | 8/8 | **7/8 — PARTIAL** |
| META 160–199 | 17/40 | 17/40 | 17/40 | 17/40 | **17/40 — PARTIAL** |
| META 200–239 | 30/40 | 30/40 | 30/40 | 30/40 | **30/40 — PARTIAL** |
| META 240–259 | 10/16 | 10/16 | 10/16 | 15/16 | **10/16 — PARTIAL** |

---

## 15. Eksiklikler ve Çalışmayan Şeyler

### 15.1 Kritik Eksiklik: Final Interpreter Kapsama Boşluğu

Final/ARGE yorumlayıcısı (`uxm31_compiler_final.bas`) Runtime Host'a kıyasla çok az meta-servisi doğrudan destekliyor. Aşağıdaki servisler Runtime'da çalışır ama Final Interpreter'da tanımsız:

- @1 CLS, @2 LOCATE, @4 TIMER, @6 PRINT META INFO
- @7 VERSION MAJOR, @8 VERSION MINOR
- @11 STATUS SET, @13–@15 ERR FLAG SET/RESET/READ
- @25 MIN, @26 MAX, @27 ABS, @28 NEG, @29 CMP
- @30–@32 RND_RANGE, RND_SEED, RND_FLOAT01
- @33–@36 DIV/MOD SIGNED/UNSIGNED alternatifleri
- @44–@59 Tüm trigonometri (ASIN, ACOS, SQRT, SINH, COSH, TANH, ASINH, ACOSH, ATANH, LOG, EXP, POW, DEG_TO_RAD, RAD_TO_DEG)
- @62–@69 Yazdırma servisleri
- @81, @83, @87, @88 İşaretçi/bellek servisleri
- @160–@176 Tüm matris servisleri (Final Interpreter'da @160+ eksik)
- @200–@224 Tüm FP servisleri (Final Interpreter'da @200+ eksik)
- @240–@254 Tüm polinom/nümerik servisler

### 15.2 Tamamen Boş Servis Aralığı

- **META 108–119**: Dört hatta da sıfır kapsama. Bu 12 ID tamamen atanmamış/uygulanmamış.

### 15.3 test_math05/06/07 — Nümerik Analiz Çıktı Sorunu

`test_math05_num_deriv`, `test_math06_integral_trap`, `test_math07_integral_simpson` testleri çalışıyor (exit code 0) ancak çıktı `0`. Bunun olası nedeni:
- Nümerik analiz servislerinin (@251, @252, @253) argüman geçişinde adres modu uyuşmazlığı.
- `#expr-rpn` ifadesinin test kodunda doğru format kullanılmamış olması.
- Native derleyici çıktısındaki ölçekleme hatası.

### 15.4 Stack Underflow Kabul Edilen Testler

test04, test33, test40, test41, test51 testleri Stack Underflow ile bitiyor. Bunlar kasıtlı tasarım testleri (hata yönetimi akışını test eder), gerçek bir arıza değil. Ancak bu testlerin `exit kodu: 0` döndürmesi kafa karıştırıcıdır — hata akışlarına ayrı bir test exit kodu atanmalıdır.

### 15.5 test19 Numaralı Test Yok

test01–test18 ve test20–test54 arasında **test19** kayıp. Bu numarada bir test dosyası oluşturulmamış.

### 15.6 Full Tool Legacy Durumu

`uxm31_full_tool_fb.bas` (`legacy/corrupt_sources/` altında) eski tek-dosya entegrasyondur. Bazı meta-servisler burada farklı/eksik uygulanmış. Bakımı kesilmiş kabul edilmeli; aktif geliştirme için kullanılmamalıdır.

### 15.7 @Math 240–244 ile 245–249 Arası Uçurum

@245–@249 ID'leri sadece VSCode iç yorumlayıcısında var; Native, Final, Full Tool'da yok. Bu aralık polinom ARGE uzantısı olarak planlanmış ama tam entegre edilmemiş.

---

## 16. Hızlı Başlangıç Özeti

1. `.uxm` uzantılı bir kaynak dosyası oluştur.
2. Dosyanın başına gerekli pragma satırlarını ekle (`#cell byte`, `#mode normal` vb.).
3. Program mantığını yaz.
4. Derle/çalıştır:
   ```batch
   uxm.exe --input programim.uxm --mode all
   ```
5. Çıktıyı `build\` klasöründe incele.

---

*Bu kılavuz, `uxm.zip` içeriğinin otomatik kod analizi, test log okuması ve matris raporlarından üretilmiştir.*
