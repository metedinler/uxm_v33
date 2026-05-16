# UX-Minima V3.3 Stage-8 BIO V1 Servisleri

Bu faz Stage-6 derleme kırılmasını da düzeltir: `runtime_string_ext_services.bas` içindeki `pos` yerel değişkeni FreeBASIC'te isim çakışması yarattığı için kaldırıldı ve `scanIdx` adı kullanıldı.

## Servis aralığı

`@480..@511` BIO / protein / kodon servisleri için ayrıldı.

## Aktif servisler

| Servis | Ad | Girdi | Çıktı |
|---:|---|---|---|
| @480 | BIO_BASE_ENCODE | `T-1 = ASCII base` | `T+1 = A:0 C:1 G:2 T/U:3` |
| @481 | BIO_CODON_ENCODE | `T-3,T-2,T-1 = ASCII bases` | `T+1 = codon id 0..63` |
| @482 | BIO_CODON_TO_AA | `T-1 = codon id` | `T+1 = amino acid ASCII` |
| @483 | BIO_TRANSLATE | `T-4=src, T-3=len, T-2=dst, T-1=max` | data alanına AA dizisi, `T+1=len` |
| @484 | BIO_GC_CONTENT | `T-2=src, T-1=len` | `T+1 = integer GC%` |
| @485 | BIO_ORF_FIND | `T-2=src, T-1=len` | `T+1 = first ATG offset veya CellMask` |
| @486 | BIO_AA_COUNT | `T-3=aaSrc, T-2=len, T-1=AA ASCII` | `T+1=count` |
| @487 | BIO_MOTIF_FIND | `T-4=src, T-3=len, T-2=motif, T-1=motifLen` | `T+1=index veya CellMask` |
| @511 | BIO_STATUS | yok | `T+1=last bio status` |

## Testler

- `uxm/tests/v33/test_v33_bio_base_codon.uxm`
- `uxm/tests/v33/test_v33_bio_translate_gc.uxm`
- `uxm/tests/v33/test_v33_bio_motif_aa_count.uxm`

