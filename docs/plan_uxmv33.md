NOT (UXM-A sabit standard): Bu dosyada tarihsel notlar bulunabilir.

Gecerli meta cagrisi standardi su sekildedir:

```text
@N
@!N
@#
@!#
@(ADDR)
@!(ADDR)
```

Standart disi (kullanilmaz):

```text
@#N
@@N
@*
@#*
```

Bu dosyadaki tarihsel satirlar, uygulama standardi degil gecmis taslak kaydi olarak degerlendirilmelidir.
Haklısın Mete abi. Burada **benim yazdığım `@!N` karışıklık yaptı**.

Belgelerde iki farklı iz kalmış:

```text
@!N    host meta zorla çağırma
@#     dinamik meta
```

şeklinde geçen yerler var. Hatta Copilot yönergesinde de `@!N` için “host/runtime meta call force” denmiş.  Ama senin son standardın daha net:

```text
@N     normal çağrı
@#N    host servisi zorla çağır
@?     veya başka biçim dinamik meta için ayrılabilir
```

Yani **bu yeni tasarım değil; benim önceki yanıtta eski/alternatif notasyona kaymamdan kaynaklanan karışıklık.** V3.3 için bunu şöyle sabitleyelim:

```text
@N      normal dispatch: önce kullanıcı makrosu, yoksa host servis
@#N     forced host dispatch: kullanıcı makrosunu atla, doğrudan host servis çalıştır
@@N     forced user macro dispatch: sadece kullanıcı makrosu ara, yoksa hata
@*      dynamic dispatch: servis id aktif hücreden / T frame’den okunur
```

Böylece senin örneğin doğru olur:

```uxm
@5      normal çağrı; eğer m5 tanımlıysa onu çalıştırabilir
@#5     kesin host servis @5 çalışır
```
---

# UX-Minima v3.3 ana hedefi

V3.3’ün hedefi yeni bir dil uydurmak değil. Hedef şu olmalı:

```text
Mevcut UX-Minima çekirdeğini bozmadan
servis sistemini genişletmek,
adresleme sistemini standartlaştırmak,
parser/interpreter/native/codegen/VSCode katmanlarını aynı tabloya bağlamak,
gelecekte modül eklemeyi include hook sistemiyle kolaylaştırmak.
```

Senin dediğin “biz yapacağız” mantığı için bu işin yol haritasını böyle kurardım.

---

# 1. Servis ID alanı: 1024 mü, 65536 mı?

Bence doğru karar:

```text
Parser tipi: 0..65535 desteklesin
Resmî v3.3 servis alanı: 0..1023 aktif kullanılsın
1024..65535: vendor / deneysel / kullanıcı / ileride rezerve
```

Neden?

`65536` servis alanı mantıksız değil; CPU mimarisi gibi düşünürsek 16-bit servis adres alanı olur. Ama hepsini tek tek `Select Case 0..65535` yapmak saçma olur. Bunun yerine servis ID tipi genişletilir, dispatcher ise aile bazlı çalışır.

FreeBASIC tarafında:

```freebasic
Type UxmServiceId As UShort  ' 0..65535
```

veya daha güvenlisi:

```freebasic
Type UxmServiceId As ULongInt
```

Ama semantic olarak sınır:

```text
0 <= service_id <= 65535
```

olmalı.

V3.3 için resmi aile tablosu şöyle olabilir:

```text
@0..@127       core host services
@128..@255     user macro legacy / protected macro zone
@256..@299     statistics / AI / ML basic
@300..@339     UX-STR V1 temel string
@340..@379     UX-STR V2 genişletilmiş string/text
@380..@399     numeric/probability bridge
@400..@439     file I/O
@440..@479     complex / numeric advanced
@480..@511     bio/protein/kodon/peptit proxy services
@512..@767     future official extensions
@768..@1023    experimental official extensions
@1024..@65535  vendor/user/research extension
```

String belgelerinde V1 için `@300..@319`, V2 için `@340..@379` aralığı zaten önerilmiş; runtime dispatch için de `metaId>=300 And metaId<=379 Then MetaString metaId` biçimi verilmiş.  

---

# 2. `@#N` standardı kesinleştirilecek

V3.3 dispatch kuralı:

```text
@N:
  1. user macro var mı?
  2. varsa ve mode izin veriyorsa macro çalışır
  3. yoksa host service çalışır
  4. ikisi de yoksa INVALID_SERVICE

@#N:
  1. user macro tablosuna bakma
  2. doğrudan host service N çalıştır
  3. host yoksa INVALID_HOST_SERVICE

@@N:
  1. sadece user macro N ara
  2. host servise düşme
  3. yoksa INVALID_USER_MACRO

@*:
  1. service id tape/frame’den okunur
  2. normal dispatch gibi çalışır

@#*:
  1. service id tape/frame’den okunur
  2. forced host dispatch yapar
```

Böylece çakışma sorunu çözülür.

Örnek:

```uxm
m5={+k1.}

@5      # m5 varsa kullanıcı makrosu çalışır
@#5     # host @5 newline ise newline çalışır
@@5     # yalnız m5 çalışır; host'a düşmez
```

---

# 3. NOP include fikri doğru mu?

Evet, çok doğru. Hatta büyük compiler projelerinde bu “hook noktası” mantığı çok işe yarar.

Senin dediğin şeyin teknik adı bizde şu olabilir:

```text
NOP include hook layer
```

Ama dikkat: Her modülün içine rastgele include koymayacağız. Standart hook noktaları koyacağız.

Önerilen yapı:

```text
src/hooks/
  hook_parser_directives.bas
  hook_parser_addressing.bas
  hook_parser_meta_call.bas
  hook_parser_string_defs.bas
  hook_parser_bio.bas

  hook_runtime_dispatch_pre.bas
  hook_runtime_dispatch_ext.bas
  hook_runtime_dispatch_post.bas

  hook_interpreter_exec_pre.bas
  hook_interpreter_exec_ext.bas
  hook_interpreter_exec_post.bas

  hook_native_codegen_pre.bas
  hook_native_codegen_addressing.bas
  hook_native_codegen_meta.bas
  hook_native_codegen_post.bas

  hook_optimizer_pre.bas
  hook_optimizer_ext.bas
  hook_optimizer_post.bas

  hook_vscode_registry_gen.bas
```

İlk sürümde bu dosyaların içi boş olur:

```freebasic
#ifndef UXM_HOOK_RUNTIME_DISPATCH_EXT_BAS
#define UXM_HOOK_RUNTIME_DISPATCH_EXT_BAS

Function UxmDispatchExtensionService(ByVal metaId As ULongInt) As Long
    Return 0
End Function

#endif
```

Sonra runtime dispatcher içinde:

```freebasic
If UxmDispatchExtensionService(metaId) Then Exit Sub
```

Böylece yeni servis eklemek için ana runtime dosyasını sürekli delmek zorunda kalmayız.

---

# 4. Bütün katmanlara aynı registry bağlanmalı

Şu an risk şu: parser bir şeyi tanıyor, interpreter tanımıyor; runtime tanıyor, VSCode renklendirmiyor; native emitter başka davranıyor.

V3.3’te kaynak gerçekliği tek merkezden gelmeli:

```text
config/uxm/commands.json
config/uxm/meta_services.json
config/uxm/addressing_modes.json
config/uxm/service_families.json
```

Sonra bunlardan şu belgeler ve kodlar türetilmeli:

```text
docs/STANDARD_COMMANDS.md
docs/STANDARD_ADDRESSING.md
docs/STANDARD_SERVICES.md
ide/uxminima-vscode/syntax/snippets/diagnostics
compiler registry tables
runtime dispatch tables
test matrix
```

Komut standardında zaten `@N`, `@#`, `pN`, `mN`, `kN`, adresleme ve branch aileleri belgelerde geçiyor. Ayrıca `.uxm` içinde komut arasında boşluk yasak, `0(T-2)+k10` geçerli, `0 (T-2) + k10` geçersiz kuralı da açık şekilde yazılmış. 

---

# 5. Adresleme v3.3 standardı

Bu kesin korunmalı:

```text
(T)
(T+N)
(T-N)
(T:N)
(D:N)
(S:N)
(SP)
(P)
(E)
(F)
(*T)
(*(T+N))
(*(T-N))
(D@T)
(D@T+N)
(D@T-N)
(D@(T-2)+N)
(D@(T-1)+N)
(D@(T)+N)
```

Belgelerde bu adresleme ailesinin bütün hatlarda aynı anlamla çözülmesi gerektiği, özellikle `D@T`, indirect, stack pointer, status/flags ve dynamic meta alanları dağılırsa sistem güvenilirliğinin kaybolacağı belirtilmiş. 

V3.3 için eklenebilir adresleme modları:

```text
(SP+N)
(SP-N)
(D@S)
(D@SP+N)
(T@D)
```

Ama ilk hamlede hepsini açmayalım. Önce şunları garantiye alalım:

```text
V3.3 zorunlu:
(T), (T+N), (T-N), (T:N), (D:N), (S:N), (SP), (P), (E), (F)
(D@T), (D@T+N), (D@T-N)
(D@(T-2)+N), (D@(T-1)+N), (D@(T)+N)

V3.3 deneysel:
(*T), (*(T+N)), (*(T-N)), (SP+N), (SP-N)
```

Safe/Normal/Wild ayrımı da korunmalı. D@T ailesi normal syntax olmalı; daha önceki yönergede de `(D@...)` formlarının wild değil normal-mode dynamic data addressing olduğu açıkça yazılmış. 

---

# 6. Servis ailelerini yeni düzene koyma

V3.3 resmi servis haritası şöyle olsun:

```text
@0..@31       Core / status / basic IO
@32..@63      Arithmetic / compare / bitwise
@64..@89      Pointer / memory / stack
@90..@127     FIFO / data / tape / sort / wild

@128..@191    User macro legacy zone
@192..@255    User macro extended zone veya protected compatibility

@256..@299    Statistics / AI / ML basic
@300..@319    UX-STR V1 basic string
@320..@339    UX-STR reserved
@340..@379    UX-STR V2 extended text
@380..@399    Probability / numeric bridge
@400..@439    UX-FILE V1
@440..@479    Complex / numeric advanced
@480..@511    Bio / protein / codon / peptide proxy
@512..@767    Matrix advanced / tensor / scientific
@768..@1023   Official experimental
@1024+        Vendor/user/research
```

Burada önemli karar şu: eski `@160..@176 matrix`, `@200..@224 FP`, `@240..@254 math` servisleri **compatibility alias** olarak kalabilir. Ama yeni düzende bunların registry karşılığı olmalı.

Yani:

```text
@160 MAT_INIT         legacy
@512 MAT_INIT         canonical v3.3

@200 FP_INIT16        legacy
@560 FP_INIT16        canonical v3.3

@240 POLY_DERIV      legacy
@600 POLY_DERIV      canonical v3.3
```

İlk aşamada servisleri taşımayız; sadece `meta_services.json` içinde `legacy_id` ve `canonical_id` alanları oluştururuz. Böylece eski testler bozulmaz.

---

# 7. String servisleri nereye oturacak?

Senin V1 ve V2 string kodların bence sisteme alınmalı.

Karar:

```text
@300..@319  STR V1 temel
@340..@379  STR V2 genişletilmiş
```

V1 temel servisleri:

```text
STR_LEN_Z
STR_COPY
STR_CLEAR
STR_FILL
STR_COMPARE
STR_EQUALS
STR_FIND_CHAR
STR_COUNT_CHAR
STR_TO_UPPER
STR_TO_LOWER
STR_TRIM_SPACES
STR_CONCAT
STR_SUBSTR
STR_PRINT
STR_READ_CONSOLE
STR_FROM_INT
STR_TO_INT
STR_APPEND_CHAR
STR_REVERSE
STR_STATUS
```

V2 ise substring, replace, tokenize, starts/ends/contains, padding, normalize, hash, UTF-8, JSON/CSV/Base64/Hex/URL, Levenshtein/Hamming/glob/regex-lite gibi geniş servisleri taşıyor. 

Bunlar compiler keyword olmamalı. Senin string belgesindeki karar doğru:

```text
LEFT, RIGHT, MID, CONCAT gibi keyword eklenmez.
Bunlar runtime/meta servis olur.
Kullanıcı isterse macro alias tanımlar.
```

---

# 8. Bio/protein fikri nereye oturacak?

`ux-bio` gibi ayrı syntax uydurmayacağız. Bu önemli.

Bio tarafı sadece servis/makro kütüphanesi olacak:

```text
@480 BIO_BASE_ENCODE
@481 BIO_CODON_ENCODE
@482 BIO_CODON_TO_AA
@483 BIO_TRANSLATE
@484 BIO_GC_CONTENT
@485 BIO_ORF_FIND
@486 BIO_AA_COUNT
@487 BIO_MOTIF_FIND
@488 BIO_HYDROPATHY
@489 BIO_MW_CALC
@490 BIO_CHARGE_CALC
@491 BIO_PEPTIDE_SCORE
@492 BIO_VHH_CDR3_PROXY_SCORE
```

Burada protein dizisini UXM syntax’ına aykırı yazmayacağız. Sayısal temsil kullanacağız.

Senin verdiğin biyoloji fikrinde zaten doğru model var: DNA baz dizisi, kodon dizisi ve protein dizisi üç ayrı katman olarak düşünülmeli; kodonlar 0–63, aminoasitler 0–20 gibi sayısal kodla saklanabilir. 

Bu yüzden VHH/protein işi şu şekilde olmalı:

```text
Data alanında kodon tablosu
Data alanında aminoasit özellik tablosu
Tape üzerinde indeksler
Meta servis ile translate / motif / skor
```

Yeni syntax yok. Sadece UXM’nin mevcut adresleme gücü kullanılacak.

---

# 9. Parser değişiklikleri

V3.3 parser görevleri:

```text
1. @N parser limiti 255 değil 65535 olacak.
2. @#N forced host meta parse edilecek.
3. @@N forced user macro parse edilecek.
4. @* dynamic meta parse edilecek.
5. @#* dynamic forced-host parse edilecek.
6. mN macro tanımı için sınır yeniden tasarlanacak.
7. Adresleme parser tüm standart adresleme ailesini tek fonksiyondan çözecek.
8. Komut-adresleme boşluk kuralı korunacak.
9. Registry tabanlı unknown service uyarısı verilecek.
```

Macro alanı için önerim:

```text
m0..m127       sistem/çekirdek üzerine yazmaya kapalı
m128..m1023    user macro official
m1024..m65535  user/vendor macro extended
```

Ama `@N` çağrısında host servisle çakışma olursa dispatch kuralı çalışır:

```text
@N      macro-first
@#N     host-only
@@N     macro-only
```

Bu yüzden çakışma artık problem değil, bilinçli özellik olur.

---

# 10. Runtime değişiklikleri

Runtime’da ana hedef:

```freebasic
Sub UxmMetaCall(ByVal metaId As ULongInt, ByVal forceHost As Long)
```

gibi bir yapıya geçmek.

Dispatcher kabaca şöyle olmalı:

```freebasic
Sub UxmDispatch(ByVal metaId As ULongInt, ByVal mode As Integer)
    If metaId > 65535 Then
        SetStatus STATUS_INVALID_META
        Exit Sub
    End If

    If mode = DISPATCH_NORMAL Then
        If UserMacroExists(metaId) Then
            RunUserMacro metaId
            Exit Sub
        End If
        If HostServiceExists(metaId) Then
            RunHostService metaId
            Exit Sub
        End If
    End If

    If mode = DISPATCH_FORCE_HOST Then
        If HostServiceExists(metaId) Then
            RunHostService metaId
            Exit Sub
        End If
    End If

    If mode = DISPATCH_FORCE_MACRO Then
        If UserMacroExists(metaId) Then
            RunUserMacro metaId
            Exit Sub
        End If
    End If

    SetStatus STATUS_INVALID_META
End Sub
```

Sonra servis aile dispatch’i:

```freebasic
If metaId <= 127 Then
    MetaCore metaId
ElseIf metaId >= 300 And metaId <= 379 Then
    MetaString metaId
ElseIf metaId >= 400 And metaId <= 439 Then
    MetaFile metaId
ElseIf metaId >= 480 And metaId <= 511 Then
    MetaBio metaId
Else
    If UxmDispatchExtensionService(metaId) Then Exit Sub
    SetStatus STATUS_INVALID_META
End If
```

Boş rezerve servisler de “NOP service”e düşebilir:

```freebasic
Sub UxmReservedService(ByVal metaId As ULongInt)
    SetStatus STATUS_RESERVED_SERVICE
End Sub
```

Ama dikkat: Sessiz NOP yaparsak hata saklanır. O yüzden varsayılan davranış:

```text
reserved service çağrıldıysa status = RESERVED_SERVICE
```

olmalı. Sadece `#mode wild` veya `#allow reserved-nop` gibi özel modda sessiz NOP yapılabilir.

---

# 11. Native compiler / emitter değişiklikleri

Native compiler tarafında her komutun adresleme hedefini tek bir `ResolvedAddress` yapısına çevirmek lazım.

Önerilen yapı:

```freebasic
Type UxmResolvedAddress
    kind As Integer
    baseArea As Integer
    baseIndex As LongInt
    relOffset As LongInt
    indirect As Long
    baseFromTapeRel As LongInt
    postOffset As LongInt
End Type
```

Emitter şunu bilmemeli:

```text
Bu (D@T+N) miydi?
Bu (D@(T-2)+N) miydi?
```

Emitter sadece şunu bilmeli:

```text
area = data
address = tape[ptr + rel] + offset
bounds check = on/off
```

Böylece parser/interpreter/native üçü aynı davranır.

---

# 12. VSCode tarafı

`commands.json` ve `meta_services.json` kesin eklenmeli.

VSCode’da yapılacaklar:

```text
1. Syntax highlight:
   @#N, @@N, @*, @#* tanınacak.

2. Diagnostics:
   @70000 -> servis id sınır dışı.
   + (T+1) -> boşluk hatası.
   @(bozuk) -> adresleme hatası.
   @300 -> STR_LEN_Z hover.
   @#300 -> forced host STR_LEN_Z hover.

3. Autocomplete:
   @300 STR_LEN_Z
   @340 STR_FIND_TEXT
   @400 FILE_OPEN_READ
   @480 BIO_BASE_ENCODE

4. Hover:
   servis adı, frame düzeni, input/output, status kodları.

5. Trace/memory view:
   T frame, data, stack, service call log gösterilecek.
```

`commands.json` içinde zaten primitive komutlar, branch komutları ve adresleme modları listelenmiş; fakat şu an orada `@!N` görünüyor. Bunu V3.3’te `@#N` olarak güncelleyeceğiz. 

---

# 13. NOP include iskeleti nasıl repo içine konur?

Ana dosyalara şu include’lar eklenmeli:

```freebasic
' parser ana dosyası
#Include Once "hooks/hook_parser_directives.bas"
#Include Once "hooks/hook_parser_addressing.bas"
#Include Once "hooks/hook_parser_meta_call.bas"

' runtime ana dosyası
#Include Once "hooks/hook_runtime_dispatch_pre.bas"
#Include Once "hooks/hook_runtime_dispatch_ext.bas"
#Include Once "hooks/hook_runtime_dispatch_post.bas"

' native emitter
#Include Once "hooks/hook_native_codegen_addressing.bas"
#Include Once "hooks/hook_native_codegen_meta.bas"

' optimizer
#Include Once "hooks/hook_optimizer_ext.bas"
```

Her hook dosyası başlangıçta boş çalışacak:

```freebasic
#ifndef UXM_HOOK_PARSER_META_CALL_BAS
#define UXM_HOOK_PARSER_META_CALL_BAS

Function HookParseMetaCall(ByRef src As String, ByRef pos As LongInt) As Long
    Return 0
End Function

#endif
```

Böylece ileride yeni servis/komut eklerken ana dosyayı daha az dolaşırız.

---

# 14. V3.3 çalışma planı

## Hamle 1 — Standart karar belgesi

Üretilecek dosyalar:

```text
docs/STANDARD_DISPATCH_V33.md
docs/STANDARD_ADDRESSING_V33.md
docs/STANDARD_SERVICE_MAP_V33.md
docs/STANDARD_HOOKS_V33.md
```

Bu belgelerde kesin kararlar:

```text
@#N forced host
@@N forced macro
@* dynamic
@#* dynamic forced host
service id 0..65535
official active 0..1023
reserved davranışı
macro/user/host çakışma kuralı
```

## Hamle 2 — Registry dosyaları

Güncellenecek/oluşturulacak:

```text
config/uxm/commands.json
config/uxm/meta_services.json
config/uxm/addressing_modes.json
config/uxm/service_families.json
```

Burada `@!N` kaldırılacak veya legacy alias olarak işaretlenecek:

```json
{
  "token": "@!N",
  "status": "deprecated",
  "replacement": "@#N"
}
```

## Hamle 3 — Parser patch

Değişiklikler:

```text
parseMetaCall()
parseDynamicMeta()
parseForcedHostMeta()
parseForcedMacro()
parseAddressing()
parseServiceId()
```

Sınır:

```text
0..65535
```

Hata:

```text
STATUS_PARSE_SERVICE_ID_RANGE
STATUS_PARSE_BAD_FORCE_META
STATUS_PARSE_BAD_ADDRESS
```

## Hamle 4 — Interpreter patch

Interpreter şu dispatch modlarını tanıyacak:

```text
DISPATCH_NORMAL
DISPATCH_FORCE_HOST
DISPATCH_FORCE_MACRO
DISPATCH_DYNAMIC
DISPATCH_DYNAMIC_FORCE_HOST
```

## Hamle 5 — Runtime service family patch

Eklenecek modüller:

```text
runtime/runtime_string_services.bas
runtime/runtime_string_ext_services.bas
runtime/runtime_file_services.bas
runtime/runtime_bio_services.bas
runtime/runtime_service_registry.bas
runtime/runtime_reserved_services.bas
```

## Hamle 6 — Native codegen patch

Native emitter:

```text
@#N için doğrudan host dispatch call
@N için normal dispatch call
@@N için macro inline veya macro call
@* için runtime dynamic dispatch call
```

Adresleme için:

```text
ResolveAddress()
EmitLoadAddress()
EmitLoadCell()
EmitStoreCell()
EmitBoundsCheck()
```

## Hamle 7 — Test matrisi

Minimum testler:

```text
test_dispatch_001_normal_host.uxm
test_dispatch_002_macro_shadow.uxm
test_dispatch_003_force_host_hash.uxm
test_dispatch_004_force_macro.uxm
test_dispatch_005_dynamic.uxm

test_address_001_T_rel.uxm
test_address_002_D_abs.uxm
test_address_003_D_at_T.uxm
test_address_004_D_at_T_plus.uxm
test_address_005_D_at_Tminus2_plus.uxm

test_string_001_len.uxm
test_string_002_copy.uxm
test_string_003_find_text.uxm

test_file_001_open_write_read.uxm
test_bio_001_codon_encode.uxm
test_bio_002_translate.uxm
```

## Hamle 8 — VSCode güncellemesi

Yapılacaklar:

```text
syntax grammar
diagnostics
hover provider
completion provider
service registry loader
trace service-call display
```

---

# 15. Kritik kararlar

Benim V3.3 için net önerim:

```text
1. @!N kullanılmayacak; legacy/deprecated kalacak.
2. @#N canonical forced host olacak.
3. @# tek başına dynamic meta olmayacak; dynamic için @* kullanılacak.
4. ServiceId 16-bit olacak: 0..65535.
5. Resmî aktif alan şimdilik 0..1023 olacak.
6. Registry dosyaları tek gerçek kaynak olacak.
7. NOP include hook sistemi eklenecek.
8. String V1/V2 servisleri @300..@379 aralığına alınacak.
9. File servisleri @400..@439 aralığına alınacak.
10. Bio/protein servisleri yeni syntax değil, @480..@511 servis ailesi olacak.
11. Eski @160 matrix / @200 FP / @240 math servisleri legacy alias olarak korunacak.
```

Bu planla V3.3, “bir sürü ek yama yapıştırılmış compiler” olmaktan çıkar; **servis kayıt sistemi olan, genişletilebilir, adresleme standardı oturmuş bir bilimsel DSL çekirdeği** olur.

hayir src icindeki parserde olan nedir onemli olan bu
"Belgelerde iki farklı iz kalmış:

@!N    host meta zorla çağırma
@#     dinamik meta

şeklinde geçen yerler var. Hatta Copilot yönergesinde de @!N için “host/runtime meta call force” denmiş. Ama senin son standardın daha net:

@N     normal çağrı
@#N    host servisi zorla çağır
@?     veya başka biçim dinamik meta için ayrılabilir

Yani bu yeni tasarım değil; benim önceki yanıtta eski/alternatif notasyona kaymamdan kaynaklanan karışıklık. V3.3 için bunu şöyle sabitleyelim:

@N      normal dispatch: önce kullanıcı makrosu, yoksa host servis
@#N     forced host dispatch: kullanıcı makrosunu atla, doğrudan host servis çalıştır
@@N     forced user macro dispatch: sadece kullanıcı makrosu ara, yoksa hata
@*      dynamic dispatch: servis id aktif hücreden / T frame’den okunur

Böylece senin örneğin doğru olur:

@5      normal çağrı; eğer m5 tanımlıysa onu çalıştırabilir
@#5     kesin host servis @5 çalışır"

@@N bunotasyionu kabul etmem dogru olmaz yerine @!N olur
@* ve @(T+N)  @(T-N) yada adresleme ler ile ilgili olarak tartismali yiz ve ben belgeleri sana yukleyecegim benim icin once gerceklik onemli

compilerin oncekilere uyumsuzlugu daha benim kendi kendime tasarladigim iste olamaz.
Birde biz zaten bir kisim servisi freebasic ile compilere gomuyoruz
birde calisma aninda olusturulan kullanici tanimli makrolar var
birde ilave modullerle olusturulan ve modullerde tanimlanan makro servisler var ben bunlarin hangisi ne bilmiyorum host ne  vs aciklama yap?
 --- 
bak aslinda benim de bir problemim var
simdi vscode ile tum haklarimi tukettim ve ux-minima yi tum katmanlarda standart bir hale getirdim. 
ama mimari degismis olabilir
4 hat mimarisi hala var mi bilmiyorum.
native compiler varmi , compiler oncesi bir interpreter katmani varmi? vscode sistemi icerisinde basit bir interpreter var onu biliyorum ama aslinda o  katman olmayacakti, o katman uxminima icerisindeki interpreter katmaninin ciktilarindan yararlanacakti, ama olmadi bunu duzeltebiliriz,
birde arge var onu zaten hic anlayamadim. oda soyle oldu ben calisma klasorunu bir ust klasorden baslatinca vscode copilot eski calismayan programlarin tamamini birlestirdi ve karman corman yapti o sirada bu sekilde 4 hat ortaya cikti artik bir noktaya gelince bende bozmadim v3.1 farkli bir 4 hatli mimari 4 ayri yoldan yuruyen compiler oldu, onu kurtarmak isinde biliyorsun standartlastirma projesi ile compileri bitirdim. bu nedenle v3.1 4 ayri hatta calisan compiler.
ama simdi sana bir tane kod verdim. native kod x64 uretip uretmedigini bilmiyorum istersen o source koduda verebilirim ikisini birlestirebilir eklenen tum yeni modulleri bu yeni tasarim v3.3 e ekleriz

evet Data tarafindaki adresleme sistemleri tamamen normal modda acik olmali, pointer flag ve stack adresleme modelleri de var bunlarda yazili belgelerde bunlarin yapilip yapilmadigini bilmiyorum.
bence yapilmali normal mdda da kullanilabilmeli.
deneysel olanlar da acilabilir . standart kullanimda onerlmez tum sorumluluk sende kulanicida ama bunlarda var denir uxminima nin ozelligi bu zaten sorumluluk kullanicida.
bana ingilizce yazma turkce yaz ve hatalar icin e ve E sistemleri icin cok cabaladim cok token harcadim bunlar tamamen cift dilli olsun tukce standart dil, ingilizce yedek. bir sekilde cozulmeli
ayrica program ciktilarini, hata ve compile bilgilerini ayri klasorlere aktariyordu ve bunlar icin normaldeki davraniz program.o program.asm program.uxm vs idi sonra ben -x parametresi koymustum bu sekilde <programadi>.o , <programadi>.asm, <programadi>.exe uretilebiliniyordu. bu durum yanlis standart olan <programadi>.o, <programadi>.asm , <programadi>.exe davranisi olmali, -x program.o program.asm, program.exe uretmeli. bunun sebebide test sirasinda bir milyon dosya oluyor program.exe calistirip sonuc ne bakip test runner ile sonuclari kolayca aliyoruz.

downloads icinde zip ici zipler var. 

simdi her seyi 3 promtta dusunerek tartisarak ve planlayarak yurutelim.

simdi en onemli si sen once belgeleri oku bunlar versiyon 3.1 icin tasarim belgeleri. ama tasarim belgesinin sonuna adresleme modlari ogreticisini ayrica eklemistim. 
adresleme modlarinda gelistirmeler de yaptim. bir tartisma da yasadik. o tartismada senin onerilerini kabul ettim. ama bu sefer adresleme modlarinin olabilecek en esnek ve etkin kullanim alanlarini incelemek istiyorum. tasarim belgesindeki gibi bir sira ile kod gercekligi, mimari yapi, mimari tasarimin grafik gosterimi, mimari yapiyi her a b c d ve lapaci  kaynak kodlari icin ayri ayri tartisalim ortaya koyalim. ben once mimari yapi, dogrusu ne olmali, simdiki sistem ne, hangisi daha dogru, hangisi kolay, en gelismis paken nerede var? detaylari yakala bana aktar. sonra sana verdigim tum yeni servisler icin koda nasil ekleriz her birini kodlari zaten sende var bunlari sadece bir birine en kolay sekilde eklemenin yolunu bulalim. en genis surumu bir kalemde cikartallim. her ozelligi tartisacagimiz promt bu degil bir sonraki olacak.

Tamam Mete abi, **Prompt 2’ye geçiyoruz.** Bu promptun konusu:

```text
V3.3 servis/adresleme entegrasyonu + CLI/çıktı standardı
```

Önce V3.1’de gerçekten ne var onu netleştirdim. Çünkü senin dediğin gibi önemli olan “benim önerdiğim seçenekler” değil, **src içindeki gerçek seçenekler**.

---

# 1. V3.1 mevcut CLI gerçekliği

## A) Split native compiler hattı

`B_V3_SPLIT_NATIVE_COMPILER` içindeki native hat çok sade:

```text
uxm_native.exe kaynak.uxm cikti.asm
```

Kod gerçekliği:

```text
Command(1) = input .uxm
Command(2) = output .asm
Command(2) yoksa = InFile + ".asm"
```

Yani burada şu seçenekler yok:

```text
--trace
--uir
--diag
--opt
--mode
--asm-only
--obj-only
--exe
-x
```

Bu hat sadece **UXM -> ASM** üretir. OBJ/EXE işi `.bat` dosyasında yapılır.

---

## B) Final / ARGE compiler hattı

Final hatta seçenekler daha gelişmiş. Mevcut gerçek seçenekler:

```text
--version / -v
--help / -h
--input / -i
--asm
--uir
--diag
--trace
--opt
--ide-in
--ide-out
--max-steps
--no-opt
--mode compile
--mode interpret
--mode run
--mode step
--mode all
```

Varsayılan değerler de şu mantıkta:

```text
asmFile   = build\program.asm
uirFile   = build\program.uir.json
diagFile  = build\program.diag.json
traceFile = build\program.trace.ndjson
optFile   = build\program.opt.json
runMode   = compile
compileAsm = 1
writeUIR = 1
writeDiagnostics = 1
writeOptimizer = 1
writeTrace = 0
```

Yani Final hatta zaten şu fikir var:

```text
compile / interpret / step / all
ASM / UIR / DIAG / TRACE / OPT çıktıları
IDE request-response
```

Bu V3.3 için ana CLI temeli olmalı. Tasarım belgesi de compiler yanında debug/interpreter yolu olması gerektiğini, compile yolunun `.uxm -> lexer -> UIR -> optimizer -> x64 NASM -> obj/exe`, debug yolunun ise `.uxm -> lexer -> UIR -> interpreter -> JSON trace -> IDE` olması gerektiğini söylüyor. 

---

## C) Full tool / legacy hat

Legacy full tool seçenekleri:

```text
uxm31_full_tool.exe run kaynak.uxm trace.ndjson
uxm31_full_tool.exe uir kaynak.uxm out.uir.json
uxm31_full_tool.exe opt kaynak.uxm opt.json
uxm31_full_tool.exe ide command.json
```

Bu artık V3.3’te ana otorite olmamalı. Sadece uyumluluk / eski test / fallback aracı olarak kalmalı.

---

## D) VSCode toolchain

VSCode tarafında şu işler var:

```text
Final Compiler Run ALL
Final Compiler Interpret Trace
Final Compiler Step Mode
Final Compiler Compile ASM
Final Compiler Export UIR
Final Compiler Export Diagnostics
Final Compiler Export OPT
Build Native EXE
Legacy Run Trace
Legacy Export UIR
Legacy Export OPT
Internal Trace & Memory Watch
```

Burada önemli problem şu:

```text
VSCode hâlâ hem Final compiler’ı hem legacy full tool’u hem de kendi TypeScript interpreter’ını kullanıyor.
```

KG mimari notunda da sistemin birden fazla yürütüm hattına sahip olduğu; klasik native, Final/ARGE, Full Tool ve VSCode internal interpreter’ın ayrı yollar olduğu açıkça belirtilmiş. 

V3.3 hedefi:

```text
VSCode interpreter otorite olmayacak.
VSCode Final/ARGE JSON çıktılarını okuyacak.
```

---

# 2. `-x` meselesi

Kaynaklarda UXM compiler için standart bir `-x` seçeneği görmedim. `-x` daha çok FreeBASIC’in output exe parametresi olarak geçiyor:

```text
fbc ... -x build\exe\program.exe
```

Ama `.bat` tarafında benzer bir davranış var:

```text
build_one.bat kaynak.uxm
```

varsayılan olarak hem gerçek adlı çıktı hem de `program.*` alias dosyalarını üretiyor:

```text
build\<ad>.asm
build\<ad>.o
build\<ad>.exe

program.asm
program.obj
program.exe
```

İkinci parametre `R` verilirse alias kapatılıyor:

```text
build_one.bat kaynak.uxm R
```

Bu şu anki gerçeklik. Ama senin istediğin standart daha mantıklı:

```text
Varsayılan:
  <programadi>.asm
  <programadi>.o / .obj
  <programadi>.exe

-x:
  program.asm
  program.o / program.obj
  program.exe
```

Yani mevcut `R` mantığı tersine çevrilmeli. V3.3’te:

```text
R kaldırılabilir veya legacy alias yapılır.
-x generic output olur.
```

---

# 3. V3.3 CLI standardı

Bence tek ana komut şu olmalı:

```text
uxmc kaynak.uxm [seçenekler]
```

veya:

```text
uxm kaynak.uxm [seçenekler]
```

## Varsayılan davranış

```text
uxmc test.uxm
```

şunu yapmalı:

```text
1. parse
2. validate
3. UIR üret
4. diagnostics üret
5. ASM üret
6. OBJ/O üret
7. EXE üret
```

Varsayılan çıktı:

```text
build/asm/test.asm
build/obj/test.obj
build/exe/test.exe
build/diag/test.diag.json
build/uir/test.uir.json
build/opt/test.opt.json
```

Trace varsayılan üretilmesin. Çünkü trace dosyaları çok büyüyebilir.

---

# 4. V3.3 resmi seçenek listesi

```text
-i, --input <file>        kaynak .uxm
-o, --out <dir>           çıktı kök klasörü
-x, --generic-output      program.asm / program.obj / program.exe üret

--mode compile            sadece derleme hattı
--mode interpret          interpreter çalıştır
--mode step               step/interpreter trace
--mode all                compile + interpret + rapor

--asm <file>              asm çıktı yolu
--obj <file>              obj/o çıktı yolu
--exe <file>              exe çıktı yolu
--uir <file>              UIR json çıktı yolu
--diag <file>             diagnostics json çıktı yolu
--trace <file>            trace ndjson çıktı yolu
--opt <file>              optimizer raporu çıktı yolu

--asm-only                sadece asm üret
--obj-only                asm + obj/o üret, exe yok
--exe-only                asm + obj/o + exe üret; raporları minimum tut
--no-native               native asm/obj/exe üretme
--no-link                 obj/o üret ama exe linkleme
--run                    exe üretildiyse çalıştır
--no-run                 exe çalıştırma

--trace-on                trace üret
--trace-off               trace üretme
--diag-on                 diagnostics üret
--diag-off                diagnostics üretme
--uir-on                  UIR üret
--uir-off                 UIR üretme
--opt-report              optimizer raporu üret
--no-opt                  optimizer kapalı

--max-steps <N>           interpreter/step limit
--ide-in <file>           IDE request json
--ide-out <file>          IDE response json

--safe                    safe mode override
--normal                  normal mode override
--wild                    wild mode override
--allow-native-wild       wild native üretime açık izin

--version, -v
--help, -h
```

---

# 5. Eski V3.1 seçenekleriyle uyumluluk

V3.3 eski komutları bozmayacak.

## Final compiler uyumluluğu

Bunlar aynen çalışmalı:

```text
--input
-i
--asm
--uir
--diag
--trace
--opt
--ide-in
--ide-out
--max-steps
--no-opt
--mode compile
--mode interpret
--mode run
--mode step
--mode all
```

## Full tool legacy uyumluluğu

Bunlar deprecated ama çalışabilir:

```text
run kaynak.uxm trace.ndjson
uir kaynak.uxm out.uir.json
opt kaynak.uxm opt.json
ide command.json
```

V3.3 karşılığı:

```text
run  -> --mode interpret --trace
uir  -> --mode compile --uir --no-native
opt  -> --mode compile --opt --no-native
ide  -> --ide-in / --ide-out
```

## Build script uyumluluğu

Eski:

```text
build_one.bat kaynak.uxm
build_one.bat kaynak.uxm R
```

Yeni:

```text
uxmc kaynak.uxm
uxmc kaynak.uxm -x
```

Ama geçiş için `.bat` dosyası şunu yapabilir:

```text
R verilirse:
  --no-generic-output

R verilmezse:
  eski davranış korunabilir
```

Fakat V3.3 nihai standartta varsayılan gerçek ad, `-x` generic olmalı.

---

# 6. Çıktı klasör standardı

Bence V3.3 klasör standardı şöyle olmalı:

```text
build/
  asm/
    <program>.asm
  obj/
    <program>.obj
  exe/
    <program>.exe
  uir/
    <program>.uir.json
  diag/
    <program>.diag.json
  trace/
    <program>.trace.ndjson
  opt/
    <program>.opt.json
  logs/
    <program>.compile.log
    <program>.nasm.log
    <program>.link.log
    <program>.run.log
```

Generic `-x` verilirse:

```text
build/
  asm/program.asm
  obj/program.obj
  exe/program.exe
  uir/program.uir.json
  diag/program.diag.json
  trace/program.trace.ndjson
  opt/program.opt.json
```

Bu test kolaylığı sağlar.

---

# 7. Prompt 2’nin servis/adresleme tarafı

Prompt 1’de karar vermiştik:

```text
@* yok
@# mevcut dinamik meta
@!N forced host
@!# forced dynamic host
@(ADDR) adresli dinamik meta
@!(ADDR) adresli forced dynamic host
```

Şimdi bunu servis/adresleme entegrasyonuna bağlıyoruz.

## V3.3 servis ID sınırı

```text
0..65535 parse edilecek.
```

Ama resmi alanlar şöyle ayrılacak:

```text
@0..127       core host servisleri
@128..255     kullanıcı/macro legacy alanı
@256..299     istatistik / ML / AI temel
@300..319     string V1
@320..339     string rezerv
@340..379     string V2
@380..399     probability / numeric bridge
@400..439     file I/O
@440..479     complex / numeric advanced
@480..511     bio / protein / codon / peptide
@512..599     tensor / dataflow
@600..699     matrix advanced / linear algebra
@700..799     scientific simulation
@800..1023    resmi deneysel
@1024..65535  kullanıcı / vendor / araştırma
```

Burada eski servisler taşınmayacak; önce alias/registry ile korunacak:

```text
@160 matrix legacy
@200 FP legacy
@240 math-extra legacy
```

Sonra canonical yeni yerler verilebilir.

---

# 8. Adresleme entegrasyonu

V3.3’te parser tüm bu adreslemeleri tanımalı:

```text
Mevcut:
(T)
(T+N)
(T-N)
(T:N)
(D:N)
(S:N)
(SP)
(P)
(E)
(F)
(*T)
(*(T+N))
(*(T-N))
(D@T)
(D@T+N)
(D@T-N)
(D@(T+K)+N)

Yeni:
(SP+N)
(SP-N)
(D:BASE+P)
(T:BASE+P)
(D@D:N)
(T@D:N)
```

Adresleme belgelerinde V3.2 adayları olarak `(SP±N)`, `(D:BASE+P)`, `(T:BASE+P)`, `(D@D:N)`, `(T@D:N)` zaten listelenmiş; ayrıca yeni adresleme eklenirken parser, native, final, full tool, VSCode ve test desteğinin birlikte düşünülmesi gerektiği vurgulanmış. 

V3.3’te mod davranışı:

```text
Safe:
  çalıştırır, sıkı bounds/log, guard yoksa native durur.

Normal:
  çalıştırır, bounds/status kontrolü, native guard üretir.

Wild:
  çalıştırır, uyarı verebilir, native sorgusuz üretir.
```

---

# 9. Tek parser / tek UIR / çok çıktı hedefi

Prompt 2’nin ana mimari kararı şu:

```text
CLI tekleşecek.
Parser tekleşecek.
UIR tekleşecek.
Çıktı hattı ayrılacak.
```

Hedef mimari:

```text
UXM source
  ↓
Lexer
  ↓
Parser + Address Resolver + Meta Resolver
  ↓
UIR
  ├── Interpreter / Step / Trace
  ├── Diagnostics
  ├── Optimizer Report
  ├── Native ASM
  ├── OBJ/O
  └── EXE
```

VSCode sadece bunu çağıracak ve JSON okuyacak.

---

# 10. Prompt 2 için net iş planı

## Hamle 2.1 — CLI standardı

Dosyalar:

```text
uxm/core/compiler/common/uxm_cli.bas
uxm/core/compiler/common/uxm_outputs.bas
```

Amaç:

```text
Final, native, test runner, VSCode aynı CLI mantığını kullansın.
```

## Hamle 2.2 — Output standardı

Dosyalar:

```text
uxm/core/compiler/common/uxm_artifacts.bas
```

Üreteceği yollar:

```text
asm, obj, exe, uir, diag, trace, opt, logs
```

## Hamle 2.3 — Registry standardı

Dosyalar:

```text
config/uxm/commands.json
config/uxm/meta_services.json
config/uxm/addressing_modes.json
config/uxm/service_families.json
```

## Hamle 2.4 — Service ID genişletme

Değişecek:

```text
native_meta_parse.bas
final_meta_parse.bas
full_tool meta parser
VSCode diagnostics
```

Kural:

```text
0..65535
```

## Hamle 2.5 — Adresleme genişletme

Değişecek:

```text
native_addressing.bas
final_addressing.bas
full_tool addressing parser
VSCode grammar/diagnostics
```

## Hamle 2.6 — Runtime dispatch hook

Eklenecek:

```text
runtime/runtime_dispatch_registry.bas
runtime/hooks/runtime_hook_dispatch_ext.bas
```

## Hamle 2.7 — VSCode sadeleştirme

Yapılacak:

```text
internal interpreter deprecated
Final compiler JSON output reader aktif
traceReader/memoryView güçlendirilecek
toolchain.ts yeni CLI’ye göre sadeleşecek
```

---

# 11. Prompt 2’nin kısa hükmü

V3.3 için standart şöyle olsun:

```text
uxmc kaynak.uxm
```

varsayılan olarak gerçek program adına göre tam native build üretir.

```text
uxmc kaynak.uxm -x
```

test için `program.*` generic çıktı üretir.

```text
uxmc kaynak.uxm --mode all --trace-on
```

hem native hem interpreter trace üretir.

```text
uxmc kaynak.uxm --no-native --mode interpret --trace build/trace/test.trace.ndjson
```

sadece interpreter/trace üretir.

```text
uxmc kaynak.uxm --asm-only
```

sadece ASM üretir.

Bu, V3.1’de dağınık olan native/final/full-tool/vscode komutlarını tek mantığa bağlar; ama eski seçenekleri uyumluluk alias’ı olarak korur.

native dedigimiz asm kodun nasm ile derlenip exe kodun uretilmesi ve linker ile baglanmasi, final compiler hattinda ise bizim asm uretim kendi objemizi uretim kendi exemizi uretmemiz hali
full tool legacy hatti ise yine exeyi uretiyor (nasm yada kendi-bilmiyorum?) ve hatlar bu sekilde ilerliyor.

bu konuda bana aciklik sagla
V3.3 resmi seçenek listesi ok. V3.3 servis ID sınırı ok

promt 3 e gec

Haklısın Mete abi. Ben mimari karar cümlesinde **optimizer** ve **IDE yardımcı hattını** eksik söyledim. Doğru V3.3 mimari hedefi şöyle olmalı:

```text
Tek parser
Tek lexer
Tek adresleme çözücü
Tek UIR
Tek diagnostics sistemi
Tek optimizer sistemi
Tek servis registry
Tek artifact/çıktı yöneticisi
Ama birden fazla çalışma ve çıktı hattı
```

Yani sadece “compiler + interpreter” değil. Ortamda şu hatlar var:

```text
1. Compiler / native ASM üretim hattı
2. Native build pipeline: ASM -> OBJ/O -> EXE
3. Interpreter / step / trace hattı
4. Optimizer / opt-report hattı
5. Diagnostics / hata-uyarı hattı
6. UIR export hattı
7. IDE yardımcı JSON hattı
8. VSCode frontend hattı
9. Legacy full tool karşılaştırma hattı
10. Test runner hattı
```

Final/ARGE hattının zaten parser, validator, optimizer, interpreter, step engine, trace exporter, UIR exporter, diagnostics exporter, ASM generator ve IDE protocol backend rollerini taşıdığı belgede açıkça görünüyor. 

---

# Düzeltilmiş V3.3 mimari şeması

```text
UXM SOURCE
   |
   v
Lexer
   |
   v
Parser
   |
   v
Address Resolver + Meta Resolver
   |
   v
UIR / Annotated Instruction Stream
   |
   +--> Validator
   |
   +--> Diagnostics Producer
   |
   +--> Optimizer
   |       |
   |       +--> Optimizer Report
   |
   +--> Interpreter / Step Engine
   |       |
   |       +--> Trace NDJSON
   |       +--> Memory Snapshot JSON
   |
   +--> Native ASM Emitter
   |       |
   |       +--> NASM ASM
   |       +--> NASM OBJ/O
   |       +--> Runtime Link
   |       +--> EXE
   |
   +--> IDE JSON Backend
   |       |
   |       +--> VSCode okuyacak
   |
   +--> Test Runner
           |
           +--> interpreter sonucu
           +--> native sonucu
           +--> karşılaştırma raporu
```

Tasarım belgesinde de UIR’in interpreter trace ve x64 ASM üretiminin ortak temeli olması gerektiği yazıyor; yani doğru yön “aynı UIR’den hem interpreter hem native çıktı” almak. 

---

# Native, Final, Full Tool ayrımını netleştiriyoruz

## 1. Native compiler hattı

Mevcut native compiler’ın ana işi:

```text
UXM -> NASM x64 ASM
```

Sonra build script / toolchain:

```text
ASM -> NASM -> OBJ/O -> Runtime + FreeBASIC link -> EXE
```

Yani native compiler’ın kendisi doğrudan OBJ/EXE üretmiyor; **native build pipeline** tamamı EXE’ye gidiyor.

## 2. Final / ARGE hattı

Final/ARGE hattı V3.3’te “beyin” olacak:

```text
Parser
Validator
UIR
Optimizer
Diagnostics
Interpreter
Trace
IDE protocol
ASM üretim
```

Ama belgede de görüldüğü gibi Final hattın ASM emitter tarafı “ana native hat kadar oturmuş” değil; interpreter/analysis/IDE tarafı daha güçlü, ASM emitter daha minimal/ARGE karakterinde. 

Bu yüzden V3.3’te:

```text
Final/ARGE = ortak frontend + analiz + interpreter + JSON merkezi
Native compiler = üretim ASM emitter
```

şeklinde ilerlemek daha doğru.

## 3. Full Tool legacy

Full Tool şimdilik:

```text
trace
UIR
OPT
interpreter tarzı yardımcı işler
legacy IDE işleri
```

için kalacak. Belgede de legacy full tool’un VSCode tarafından “Legacy Run Trace”, “Legacy Export UIR”, “Legacy Export OPT” gibi işlerde kullanıldığı belirtilmiş. 

Yeni V3.3 özellikleri için ana hat olmayacak.

## 4. VSCode

VSCode içinde interpreter olmayacak ya da otorite olmayacak.

VSCode’un görevi:

```text
Final/ARGE çıktısını oku
trace göster
memory view göster
diagnostics göster
UIR göster
optimizer report göster
build komutlarını çalıştır
```

olacak.

---

# Bat dosyaları kalsın

Evet, `.bat` dosyaları kalsın. Onlara çok emek harcandı; çöpe atmayacağız.

Ama davranışı standartlaştıracağız:

```text
build_all.bat
build_one.bat
run_tests.bat
build_final_compiler.bat
run_final_probe.bat
```

kalacak.

Değişecek şey:

```text
R kullanılmayacak.
Test sırasında generic output için -x kullanılacak.
```

Yeni standart:

```text
Varsayılan:
  <programadi>.asm
  <programadi>.obj
  <programadi>.exe

-x:
  program.asm
  program.obj
  program.exe
```

Yani test runner `-x` ile çalışırsa her testten sonra aynı generic dosyayı üretip çalıştırabilir. Normal kullanıcı ise program adına göre dosya alır.

---

# Safe / Normal / Wild kesin davranış

Senin verdiğin son karar doğru. Bunu V3.3 standardı olarak yazalım.

## Safe

```text
sıkı bounds check
status/E sistemi
ayrıntılı uyarı/log
guard üretilemiyorsa native EXE durur
```

Safe mode yasakçı değil; ama native üretimde güvenlik garantisi istiyor.

## Normal

```text
bounds check
status/E sistemi
ayrıntılı uyarı/log
guard’lı native üretim
```

Normal mode ana çalışma modu olacak. Pointer, stack, flags, E adreslemeleri açık olacak. Sadece kontrol ve raporlama yapılacak.

## Wild

```text
ayrıntılı uyarı/log verilir
kullanıcının bilgisine sunulur
ama karışılmaz
native sorgusuz ASM üretir
programcı sorumludur
```

Bu, UX-Minima’nın düşük seviyeli karakterine daha uygun.

---

# Prompt 4 — eklenecek sistemleri inceleme planı

Evet, Prompt 4’te artık **tüm eklenecek sistemleri** tek tek inceleyeceğiz. Ama her servisi tek tek kodlamadan önce, hangi sistemin hangi katmana bağlanacağını netleştireceğiz.

Prompt 4’ün ana başlıkları:

```text
1. Adresleme genişletmeleri
2. Servis registry düzeni
3. String V1/V2 servisleri
4. File I/O servisleri
5. FP servisleri
6. Math servisleri
7. Matrix servisleri
8. Statistics / probability / numeric servisleri
9. Complex servisleri
10. Bio / protein / kodon servisleri
11. Tensor / dataflow servisleri
12. Optimizer genişletmesi
13. Diagnostics ve TR/EN hata sistemi
14. JSON çıktı standardı
15. VSCode entegrasyonu
16. Test runner ve bat standardı
```

---

# 1. Adresleme sistemleri

V3.3’e şu yeni adresleme modları alınacak:

```text
(SP+N)
(SP-N)
(D:BASE+P)
(T:BASE+P)
(D@D:N)
(T@D:N)
(D@(T+K)+N)
```

Bunlar zaten V3.2 aday adresleme patch belgelerinde geçiyor ve özellikle stack frame, data tablosunda pointer indeksli okuma, tape buffer, data pointer table ve data tablosundan tape hedefi seçme için önerilmiş. 

Ayrıca patch notunda native, final ve full tool tarafında bu yeni adresleme modlarının düşünülmüş olduğu; Final interpreter’ın aynı syntax’ı yorumlaması ve UIR/trace çıktısında adresleme metninin kaybolmaması gerektiği özellikle yazılmış. 

V3.3 kararı:

```text
Adresleme sadece native hatta değil,
Final interpreter,
UIR,
trace,
diagnostics,
VSCode,
test runner
tarafında da aynı anlamı taşıyacak.
```

---

# 2. String servisleri

String V1 doğrudan sisteme alınmalı.

V1 servis aralığı:

```text
@300..@319
```

Belgede string verisinin data alanında durması, LEFT/RIGHT/MID/CONCAT gibi keywordlerin compiler çekirdeğine eklenmemesi, string işlemlerinin runtime/meta servis olarak çalışması kararlaştırılmış. 

V2 servis aralığı:

```text
@340..@379
```

V2 tarafında substring, replace, tokenize, starts/ends/contains, padding, normalize, hash, UTF-8, JSON/CSV/Base64/Hex/URL, Levenshtein, Hamming, glob ve regex-lite gibi genişletilmiş servisler var. 

V3.3 kararı:

```text
String keyword yok.
String servis var.
Data alanı string belleği olarak kullanılacak.
Macro alias istenirse lib dosyalarında verilecek.
```

---

# 3. File I/O servisleri

File I/O henüz V3.1’de tam standart kapanmamış. Belgelerde compiler/toolchain dosya okuyor, trace/UIR/OPT/ASM/OBJ/EXE çıktıları var; ama kullanıcı UXM programı içinden FILE_OPEN, FILE_READ, FILE_WRITE gibi standart servis ailesi yok denmiş. 

V3.3’te File I/O:

```text
@400..@439
```

aralığına alınmalı.

İlk aile:

```text
FILE_OPEN_READ
FILE_OPEN_WRITE
FILE_OPEN_APPEND
FILE_OPEN_BINARY_READ
FILE_OPEN_BINARY_WRITE
FILE_CLOSE
FILE_READ_BYTE
FILE_WRITE_BYTE
FILE_READ_LINE
FILE_WRITE_LINE
FILE_READ_BLOCK
FILE_WRITE_BLOCK
FILE_SEEK
FILE_TELL
FILE_EOF
FILE_STATUS
```

File servisleri Safe/Normal/Wild farkına göre log ve izin davranışı taşımalı. Ama çekirdek dile yeni keyword eklemeyeceğiz.

---

# 4. FP, Math, Matrix

Bunlar belge değil, gerçekten runtime/test tarafı olan sistemler.

FP için belgede `runtime_fp_services.bas`, `lib/ux_fp_v1.uxm` ve `tests_fp` dosyaları olduğu; meta aralığının `@200..@224` olduğu yazıyor. 

Math için `runtime_math_services.bas`, `ux_math_v1.uxm`, `tests_math` ve polinom türev/integral, sayısal türev/integral servisleri var; `@240..@254` aralığı kullanılıyor. 

Matrix için de runtime ve testler var; ayrıca native runtime sonunda FP + Matrix + Math servislerinin include edildiği belirtilmiş. 

V3.3 kararı:

```text
@200..@224 FP legacy/canonical korunacak.
@160..@199 Matrix legacy korunacak.
@240..@254 Math legacy korunacak.
```

Daha geniş bilimsel servis haritasına taşımak istiyorsak önce alias mantığı kuracağız; eski testler bozulmayacak.

---

# 5. Bio / protein / kodon servisleri

Protein fikri ayrı syntax olmayacak. UX-Bio diye dil uydurulmayacak.

Bio tarafı servis ailesi olacak:

```text
@480..@511
```

Temel servisler:

```text
BIO_BASE_ENCODE
BIO_CODON_ENCODE
BIO_CODON_TO_AA
BIO_TRANSLATE
BIO_GC_CONTENT
BIO_ORF_FIND
BIO_AA_COUNT
BIO_MOTIF_FIND
BIO_HYDROPATHY
BIO_MW_CALC
BIO_CHARGE_CALC
BIO_PEPTIDE_SCORE
BIO_VHH_CDR3_PROXY_SCORE
```

Senin kodon fikrindeki ana model doğru: DNA baz düzeyi, kodon düzeyi ve protein/aminoasit düzeyi ayrı saklanmalı. Kodonlar 0–63, aminoasitler 0–20 gibi sayısal temsil edilebilir. Belgede de bu model küçük/orta ölçekli dizi analizi, peptit motif tarama, kodon/protein dönüşümü ve mutasyon etkisi için uygun görülmüş. 

---

# 6. Optimizer hattı

Optimizer V3.3 mimarisine açıkça eklenecek.

Optimizer sadece kodu değiştiren kara kutu olmayacak. Her optimizasyon olayını raporlayacak:

```text
hangi pattern eşleşti
hangi instruction değişti
hangi adresleme korundu
pointer etkisi değişti mi
branch barrier var mı
safe/wild engeli var mı
```

Tasarım belgesinde pattern optimizer olaylarının raporlanması, branch ve meta çağrıların trace içinde ayrıntılı görünmesi, IDE’nin pattern ve ASM panelleri göstermesi gerektiği zaten belirtilmiş. 

V3.3 optimizer çıktısı:

```text
build/opt/<program>.opt.json
```

olacak.

---

# 7. Diagnostics / hata sistemi

Hata sistemi iki dilli olacak:

```text
tr = ana dil
en = yedek açıklama
```

Örnek:

```json
{
  "code": "E_ADDR_007",
  "severity": "error",
  "tr": "Geçersiz adresleme modu.",
  "en": "Invalid addressing mode.",
  "line": 12,
  "col": 4
}
```

Runtime kısa durum için `e` ve `(E)` sistemi korunacak. Compiler diagnostics ise JSON dosyasına ayrıntılı yazılacak.

---

# 8. Test runner

V3.3 test runner iki sonucu karşılaştırmalı:

```text
Interpreter sonucu
Native EXE sonucu
```

Tasarım belgesinde test runner’ın parse/UIR, interpreter trace, beklenen output/status/memory/flags karşılaştırması, isteğe bağlı native ASM/EXE üretimi ve native çıktı ile interpreter çıktısını karşılaştırması gerektiği yazıyor. 

Bu yüzden test runner:

```text
run_tests.bat
```

içinde kalacak ama yeni `uxmc` standardına bağlanacak.

Test sırasında:

```text
-x
```

kullanılacak.

---

# Prompt 4’ün net hedefi

Prompt 4 sonunda elimizde şu belge oluşmalı:

```text
V3.3_EKLENTI_ENTEGRASYON_PLANI.md
```

Bu belgede her sistem için şu alanlar olacak:

```text
1. Sistemin adı
2. Mevcut kod/belge gerçekliği
3. Servis aralığı
4. Runtime dosyası
5. Parser etkisi
6. Interpreter etkisi
7. Native emitter etkisi
8. UIR/trace/diag etkisi
9. VSCode etkisi
10. Test dosyaları
11. Risk
12. İlk uygulanacak minimum sürüm
```

---

# Prompt 4 için ilk kesin karar listesi

```text
1. Optimizer mimariden eksik değil; V3.3’te ayrı resmi hat olacak.
2. IDE yardımcı hattı mimaride açıkça yer alacak.
3. VSCode interpreter otorite olmayacak.
4. Bat dosyaları kalacak.
5. R yerine -x kullanılacak.
6. Safe/Normal/Wild yasaklama değil, kontrol ve native üretim davranışı farkı olacak.
7. Adresleme genişletmeleri tüm hatlarda aynı anlama gelecek.
8. String V1/V2 servisleri runtime/meta olarak eklenecek.
9. File I/O yeni standart servis ailesi olacak.
10. FP/Math/Matrix mevcut legacy aralıklarıyla korunacak.
11. Bio/protein ayrı syntax değil, servis ailesi olacak.
12. Test runner interpreter ve native çıktıyı karşılaştıracak.
```

Bundan sonraki adımda Prompt 4’ü **sistem sistem** yürütebiliriz: önce adresleme + servis registry, sonra string/file, sonra FP/math/matrix, sonra bio/protein/tensor, en son optimizer/IDE/test runner entegrasyonu.

o halde artik eldeki kodlari kullanarak v3.3 u yapmaya baslayabiliriz.
sadece bir kac noktaya takildim. kararim
seceneklere
Belgede de legacy full tool’un VSCode tarafından “Legacy Run Trace”, “Legacy Export UIR”, “Legacy Export OPT” gibi işlerde kullanmak icin anahtarlar koyalim

2. standardizasyon sebebi ile "Ama belgede de görüldüğü gibi Final hattın ASM emitter tarafı “ana native hat kadar oturmuş” değil; interpreter/analysis/IDE tarafı daha güçlü, ASM emitter daha minimal/ARGE karakterinde"
cumlende final hattinin asm emiter tarafi bence native ana hatti koyalim yada kopyalayalim. bu sekilde final hattinin kodlarindaki kendi gorevlerine yonelik isler yapilirken ana hattin kodlarindan yararlanabilir. bunu kes kopyala mantigindan ziyade include ve class lari miras alarak yapmak mantikli olabilir.
3
bence guclu ve oturmus modulleri sifirdan yazmadan wrapper, miras include ler ile kisa ve daha az efor ile birlestirmek mantikli.
senin onerilerinnedir ?sifirdan kod yazmak zahmetli olacaktir.

Evet Mete abi, **sıfırdan yazmak en yanlış yol olur.** Eldeki kodların içinde çalışan güçlü parçalar var. V3.3’te hedef bunları çöpe atmak değil; **ortak çekirdeğe bağlamak, wrapper/include/hook ile birleştirmek** olmalı.

Kod gerçekliğinde zaten sistem birden fazla hatla çalışıyor: klasik native compiler, Final/ARGE, Full Tool legacy ve VSCode iç yardımcı hattı ayrı ayrı mevcut. Belgede de bu durum açıkça “aynı UX-Minima dilini işleyen birden fazla yürütüm/derleme hattı” olarak anlatılmış. 

# 1. Önerim: sıfırdan değil, “V3.3 refactor-köprü” yöntemi

V3.3 için yöntem şu olmalı:

```text id="pu0dpn"
1. Çalışan kodu koru.
2. Güçlü modülleri ayır.
3. Ortak include / wrapper / hook katmanı oluştur.
4. Final hattını native emitter’dan yararlandır.
5. VSCode’u JSON okuyucu hâline getir.
6. Full Tool’u legacy/fallback olarak koru.
7. Yeni servisleri registry + runtime hook ile ekle.
```

FreeBASIC’te klasik anlamda modern OOP miras sistemiyle ilerlemek biraz sınırlı ve zahmetli olabilir. Ama senin “miras” dediğin fikri şu üç yöntemle çok iyi uygularız:

```text id="j48zgs"
#Include Once
ortak Type / Function / Sub modülleri
wrapper fonksiyonlar
```

Yani “class inheritance” yerine UX-Minima için daha gerçekçi yapı:

```text id="aztfay"
common module inheritance
```

olur.

---

# 2. Final hattının ASM emitter’ı native emitter’dan yararlansın

Bu kararına katılıyorum.

Şu an Final/ARGE hattı analiz, interpreter, trace, UIR, diagnostics, optimizer ve IDE tarafında güçlü; ama ASM emitter tarafı daha minimal/ARGE karakterinde görünüyor. Mimari notta final emitter için “ana native hat kadar oturmuş görünmüyor” denmiş; ayrıca Final hattın IDE, trace, UIR ve optimizer için değerli olduğu belirtilmiş. 

Bunu düzeltmenin en doğru yolu:

```text id="77smln"
Final hattına ayrı ASM emitter yazmak değil,
native hattaki emitter’ı ortak modül yapmak.
```

Yeni yapı:

```text id="i1w15v"
compiler/common/
  uxm_instr_types.bas
  uxm_addressing.bas
  uxm_meta_parse.bas
  uxm_uir.bas
  uxm_diagnostics.bas

compiler/native/
  uxm_native_asm_emit.bas

compiler/final/
  uxm_final_driver.bas
  uxm_final_interpreter.bas
  uxm_final_trace.bas
  uxm_final_optimizer.bas
```

Final hattı ASM üretmek istediğinde:

```freebasic id="ux1ajx"
#Include Once "../native/uxm_native_asm_emit.bas"
```

veya daha temiz:

```freebasic id="ge80po"
#Include Once "../common/uxm_emit_interface.bas"
#Include Once "../native/uxm_native_asm_emit.bas"
```

kullanır.

Böylece:

```text id="whlry5"
Native hat = üretim kalitesinde ASM emitter
Final hat = analiz/interpreter/IDE/optimizer merkezi
```

ama ikisi aynı UIR ve aynı emitter arayüzünü kullanır.

---

# 3. “Kes-kopyala” değil, include-wrapper modeli

Senin dediğin çok doğru: kes-kopyala yaparsak aynı sorun tekrar çıkar. Çünkü bir dosyadaki bug düzelir, diğer kopyada kalır.

Doğru yöntem:

```text id="md4sen"
Kopyalama yok.
Ortak modül var.
Hangi hat isterse include eder.
Hatta özel davranış gerekiyorsa wrapper yazar.
```

Örnek:

```freebasic id="ualoee"
' compiler/common/uxm_addressing.bas
Function UxmParseAddress(...) As UxmAddress
    ' tek gerçek adresleme parser'ı
End Function
```

Native kullanır:

```freebasic id="rrm479"
#Include Once "../common/uxm_addressing.bas"
```

Final kullanır:

```freebasic id="rcoh5h"
#Include Once "../common/uxm_addressing.bas"
```

Full Tool legacy isterse doğrudan kullanmaz; ama V3.3 uyumluluk testi için wrapper’dan çağırabilir.

---

# 4. Legacy Full Tool için seçenekler ekleyelim

Bu da doğru karar.

VSCode paketinde zaten hem Final komutları hem legacy komutları var: `Run Trace with Toolchain`, `Export UIR`, `Export Optimizer Report`, ayrıca Final tarafında `Final Compiler Run ALL`, `Final Compiler Interpret Trace`, `Final Compiler Export UIR`, `Final Compiler Export Diagnostics`, `Final Compiler Export OPT` gibi komutlar tanımlı. 

V3.3 CLI içine legacy anahtarları şöyle ekleyelim:

```text id="34b9av"
--legacy-run-trace
--legacy-export-uir
--legacy-export-opt
--legacy-ide
```

Kısa alias gerekirse:

```text id="6l1rf3"
--legacy-trace
--legacy-uir
--legacy-opt
```

Bunların görevi:

```text id="3yl9wm"
V3.3 ana hattını bozmaz.
Eski Full Tool'u çağırır.
Karşılaştırma / fallback / eski test için kullanılır.
```

Full Tool’un kendisi zaten parser, interpreter, trace exporter, UIR exporter, optimizer, IDE command reader ve meta-runtime benzeri motor taşıyor; bu yüzden legacy/fallback için çok değerli. 

---

# 5. V3.3 ana CLI’ye eklenecek legacy seçenekler

Resmî listeye şunları ekleyelim:

```text id="v7q0ol"
--legacy-run-trace <file>
    Full Tool ile trace üretir.

--legacy-export-uir <file>
    Full Tool ile UIR JSON üretir.

--legacy-export-opt <file>
    Full Tool ile optimizer raporu üretir.

--legacy-ide <command.json>
    Full Tool IDE command modunu çalıştırır.

--compare-legacy
    V3.3 final/interpreter çıktısı ile legacy çıktısını karşılaştırır.
```

Örnek:

```bat id="u2az0k"
uxmc test.uxm --trace-on --compare-legacy
```

Bu şunu yapar:

```text id="28bb7v"
1. V3.3 Final interpreter trace üretir.
2. Legacy Full Tool trace üretir.
3. İki trace dosyasını karşılaştırır.
4. Fark varsa diag/log üretir.
```

Bu, V3.3 geçişinde çok işimize yarar.

---

# 6. Bat dosyaları kalsın, ama yeni CLI’ye bağlansın

Evet, `.bat` dosyaları kesinlikle kalsın.

Ama içleri artık doğrudan dağınık komutlar yerine yeni standardı çağırmalı:

```bat id="dqshql"
uxmc "%SRC%" --exe
```

Test için:

```bat id="hjks74"
uxmc "%SRC%" --exe -x --trace-on --diag-on
```

Eski `R` kullanımı kaldırılır veya deprecated yapılır:

```text id="4bbppk"
R = legacy, artık kullanılmaz.
-x = generic output standardı.
```

---

# 7. Güçlü modülleri sıfırdan yazmadan nasıl birleştirelim?

Bence V3.3 için en doğru sıralama:

## Aşama 1 — Ortak tipler

```text id="3l3t8q"
compiler/common/uxm_types.bas
```

İçinde:

```freebasic id="nqrrx0"
Type UxmInstr
Type UxmAddress
Type UxmMetaCall
Type UxmDiagnostic
Type UxmArtifactPaths
Type UxmCompileOptions
```

Bu dosya hem Native hem Final hem test runner tarafından include edilir.

## Aşama 2 — Ortak adresleme parser

```text id="pq7d6a"
compiler/common/uxm_addressing.bas
```

Tüm adreslemeler burada çözülür:

```text id="vf20rx"
(T)
(T+N)
(T-N)
(T:N)
(D:N)
(S:N)
(SP)
(SP+N)
(SP-N)
(P)
(E)
(F)
(*T)
(*(T+N))
(D@T)
(D@T+N)
(D@(T+K)+N)
(D:BASE+P)
(T:BASE+P)
(D@D:N)
(T@D:N)
```

## Aşama 3 — Ortak meta parser

```text id="oisq4t"
compiler/common/uxm_meta_parse.bas
```

Standart:

```text id="ytyo0v"
@N
@!N
@#
@!#
@(ADDR)
@!(ADDR)
```

## Aşama 4 — Ortak UIR

```text id="u407te"
compiler/common/uxm_uir.bas
```

Native emitter da Final interpreter da aynı UIR’den beslenecek.

## Aşama 5 — Native emitter’ı ortak backend hâline getirme

Mevcut native emitter taşınacak:

```text id="hlad78"
compiler/native/uxm_native_asm_emit.bas
```

Final hattı bunu çağıracak:

```text id="2h1erx"
Final -> UIR -> NativeAsmEmit()
```

## Aşama 6 — Final hattı analiz/trace/IDE merkezi olarak kalacak

Final’in güçlü olduğu taraflar korunacak:

```text id="kvab0u"
interpreter
step
trace
diagnostics
UIR export
optimizer report
IDE JSON response
```

Yani Final hattı “ikinci native compiler” olmaktan çıkar; **V3.3 merkezi analiz/yorumlama motoru** olur.

---

# 8. Runtime servisleri için wrapper sistemi

Servisler için de sıfırdan yazmayalım.

Runtime tarafında:

```text id="g34zvw"
runtime/runtime_core_services.bas
runtime/runtime_string_services.bas
runtime/runtime_string_ext_services.bas
runtime/runtime_file_services.bas
runtime/runtime_fp_services.bas
runtime/runtime_matrix_services.bas
runtime/runtime_math_services.bas
runtime/runtime_bio_services.bas
runtime/runtime_dispatch_registry.bas
```

Dispatcher:

```freebasic id="mwc7nq"
Sub UxmDispatchHostService(ByVal metaId As ULongInt)
    Select Case metaId
    Case 0 To 127
        MetaCore metaId
    Case 150 To 159
        MetaFlagsEndian metaId
    Case 160 To 199
        MetaMatrix metaId
    Case 200 To 239
        MetaFP metaId
    Case 240 To 254
        MetaMathExtra metaId
    Case 300 To 379
        MetaString metaId
    Case 400 To 439
        MetaFile metaId
    Case 480 To 511
        MetaBio metaId
    Case Else
        If RuntimeHookDispatchExt(metaId) Then Exit Sub
        SetStatus STATUS_INVALID_META
    End Select
End Sub
```

Böylece yeni servis eklerken ana runtime’ı parçalamayız.

---

# 9. Include hook fikrini V3.3’e kesin ekleyelim

Her ana katmanda boş hook dosyası olsun.

```text id="9fxroc"
hooks/
  hook_parser_ext.bas
  hook_addressing_ext.bas
  hook_meta_ext.bas
  hook_runtime_dispatch_ext.bas
  hook_native_emit_ext.bas
  hook_final_trace_ext.bas
  hook_optimizer_ext.bas
```

Başta boş:

```freebasic id="o4ys2x"
#ifndef UXM_HOOK_RUNTIME_DISPATCH_EXT_BAS
#define UXM_HOOK_RUNTIME_DISPATCH_EXT_BAS

Function RuntimeHookDispatchExt(ByVal metaId As ULongInt) As Long
    Return 0
End Function

#endif
```

Bu ileride eklemeyi çok hızlandırır.

---

# 10. Benim net önerim

V3.3’ü şöyle başlatalım:

```text id="ra1z8q"
Sıfırdan compiler yazma yok.
Çalışan native emitter korunacak.
Final hattı analiz/interpreter merkezi olacak.
Native emitter ortak backend yapılacak.
Full Tool legacy/fallback olacak.
VSCode JSON okuyucu olacak.
Bat dosyaları kalacak.
R yerine -x gelecek.
Servisler registry + runtime hook ile eklenecek.
Adresleme tek ortak parser’a bağlanacak.
```

Bu en az eforla en sağlam yol.

# 11. İlk gerçek çalışma manifesti

V3.3 başlangıç dosya manifesti şöyle olmalı:

```text id="30piws"
compiler/common/
  uxm_types.bas
  uxm_cli.bas
  uxm_artifacts.bas
  uxm_diagnostics.bas
  uxm_addressing.bas
  uxm_meta_parse.bas
  uxm_uir.bas

compiler/native/
  uxm_native_driver.bas
  uxm_native_asm_emit.bas

compiler/final/
  uxm_final_driver.bas
  uxm_final_interpreter.bas
  uxm_final_trace.bas
  uxm_final_optimizer.bas
  uxm_final_ide.bas

runtime/
  runtime_dispatch_registry.bas
  runtime_core_services.bas
  runtime_string_services.bas
  runtime_string_ext_services.bas
  runtime_file_services.bas
  runtime_bio_services.bas

hooks/
  hook_parser_ext.bas
  hook_addressing_ext.bas
  hook_meta_ext.bas
  hook_runtime_dispatch_ext.bas
  hook_native_emit_ext.bas
  hook_optimizer_ext.bas

config/uxm/
  commands.json
  meta_services.json
  addressing_modes.json
  service_families.json
```

İlk patch bu iskeleti kursun; sonra mevcut çalışan kodları bu dosyalara **taşıma değil, bağlama** yöntemiyle alalım.

Başladım Mete abi. İlk çalışan **V3.3 Stage-1 patch paketini** hazırladım.

İndir:

* [UXM_V33_STAGE1_patch_package.zip](sandbox:/mnt/data/UXM_V33_STAGE1_patch_package.zip)
* [UXM_V33_STAGE1_changes.diff](sandbox:/mnt/data/UXM_V33_STAGE1_changes.diff)

Bu ilk paket, eldeki **B_V3_SPLIT_NATIVE_COMPILER** hattını temel aldı. Sıfırdan yazmadım; çalışan split native yapının üstüne V3.3 başlangıç yamalarını ekledim.

## Bu hamlede yapılanlar

1. `UXM_VERSION` değeri `3.3-stage1` yapıldı.

2. Native parser’da meta servis sınırı:

```text
0..255
```

yerine:

```text
0..65535
```

yapıldı.

3. Mevcut gerçek syntax korundu:

```text
@N      normal meta çağrı
@!N     forced host çağrı
@#      aktif hücreden dinamik meta çağrı
@!#     aktif hücreden forced-host dinamik çağrı
```

4. Yeni V3.3 dinamik adresli meta çağrı eklendi:

```text
@(ADDR)
@!(ADDR)
```

Örnek:

```uxm
0(T+1)+k5(T+1)
@(T+1)
```

Bu `T+1` hücresindeki servis id’yi okur ve çağırır.

5. Yeni adresleme modları native parser/emitter tarafına eklendi:

```text
(SP+N)
(SP-N)
(D:BASE+P)
(T:BASE+P)
(D@D:N)
(T@D:N)
```

6. Runtime dispatch için boş extension hook eklendi:

```text
uxm/core/runtime/hooks/runtime_hook_dispatch_ext.bas
```

ve dispatcher’a bağlandı. Böylece ileride string/file/bio/stat/tensor servislerini ana dispatch dosyasını parçalamadan ekleyebiliriz.

7. Parser hook iskeleti eklendi:

```text
uxm/core/hooks/hook_parser_ext.bas
```

8. Registry dosyaları eklendi:

```text
config/uxm/meta_services.json
config/uxm/commands.json
config/uxm/service_registry_merged.csv
```

9. Test dosyaları eklendi:

```text
uxm/tests/v33/test_v33_dynamic_meta_addr.uxm
uxm/tests/v33/test_v33_address_base_p.uxm
uxm/tests/v33/test_v33_stack_pointer_relative.uxm
```

10. `build_one_native.bat` içinde `-x` standardı başlatıldı:

```bat
build_one_native.bat kaynak.uxm
```

çıktı:

```text
build/asm/<programadi>.asm
build/obj/<programadi>.obj
build/exe/<programadi>.exe
```

```bat
build_one_native.bat kaynak.uxm -x
```

çıktı:

```text
build/asm/program.asm
build/obj/program.obj
build/exe/program.exe
```

## Bilinçli sınır

Bu paket **V3.3’ün tamamı değil**, ilk kod hamlesidir.

Henüz yapılmayanlar:

```text
Final/ARGE hattını aynı parser/emitter’a bağlama
VSCode internal interpreter’ı devreden çıkarma
String V1/V2 servislerini dispatch’e bağlama
File I/O servislerini dispatch’e bağlama
Bio/protein servislerini ekleme
Tam uxmc CLI yazma
Full Tool legacy seçeneklerini yeni CLI’ye bağlama
```

## Test durumu

Bu ortamda `fbc` ve `nasm` yoktu, bu yüzden derleme testi koşturamadım. Ama patch paketinde değişen dosyaların diff’ini ayrıca verdim; VSCode/Windows tarafında ilk test şu olmalı:

```bat
build_native.bat
build_one_native.bat uxm\tests\v33\test_v33_dynamic_meta_addr.uxm -x
build_one_native.bat uxm\tests\v33\test_v33_address_base_p.uxm -x
build_one_native.bat uxm\tests\v33\test_v33_stack_pointer_relative.uxm -x
```

Bundan sonraki kod hamlesinde **Final/ARGE hattını native emitter’a bağlayan ortak include/wrapper katmanına** geçelim.

 Yani kaynakta:

+k65

yazınca compiler bunu içeride şu hale getirecek:

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Aynı mantık diğer işaretlerde de çalışacak:

-k10   → ----------  
>k8    → >>>>>>>>  
<k4    → <<<<  
$k3    → $$$  
.k5    → .....  
0k4    → 0000

Bu yama, daha önce kurduğumuz UX-MINIMA lexer/pattern/compiler mantığına eklenir; pattern optimizer yine en uzun patternleri yakalamaya devam eder.

