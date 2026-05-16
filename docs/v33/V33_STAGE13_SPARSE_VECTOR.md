# UXM V3.3 Stage-13 — Sparse Matrix + Vector Ops

Bu stage yalnızca yeni Stage-13 katmanını ekler. Eski test dosyaları yeniden üretilmez.

## Servis aralıkları

```text
@600..@619  Vector Ops V1
@640..@649  Sparse Matrix V1
```

## Vector Ops V1

```text
@600 VEC_INIT
@601 VEC_SET
@602 VEC_GET
@603 VEC_FILL
@604 VEC_SUM
@605 VEC_DOT
@606 VEC_NORM1
@607 VEC_NORM2_SQ
@608 VEC_ADD
@609 VEC_SCALE
@610 VEC_FROM_DATA
@611 VEC_TO_DATA
@619 VEC_INFO
```

Vector descriptor `data[]` içinde tutulur:

```text
base+0 = 8601 magic
base+1 = length
base+2 = data offset = 8
base+3 = status
base+8... vector values
```

## Sparse Matrix V1

```text
@640 SPARSE_INIT
@641 SPARSE_SET_NNZ
@642 SPARSE_SET_ENTRY
@643 SPARSE_GET_ENTRY_VALUE
@644 SPARSE_MATVEC
@645 SPARSE_TO_DENSE
@646 SPARSE_NNZ
@647 SPARSE_SUM_VALUES
@648 SPARSE_TRACE
@649 SPARSE_INFO
```

Sparse descriptor `data[]` içinde COO benzeri triple alanı kullanır:

```text
base+0  = 8602 magic
base+1  = rows
base+2  = cols
base+3  = nnz
base+4  = capacity
base+5  = triples offset = 16
base+6  = status
base+16 + k*3 + 0 = row
base+16 + k*3 + 1 = col
base+16 + k*3 + 2 = value
```

## Test politikası

Stage-13 ile gelen testler yalnızca:

```text
uxm/tests/v33/stage13/
```

altındadır. Her yeni servis için ayrı `.uxm` + `.expect` dosyası vardır. Ayrıca iki birleşik kullanım testi eklenmiştir:

```text
test_s13_integration_sparse_matvec_dot.uxm
test_s13_integration_vector_data_pipeline.uxm
```

Smoke çalıştırıcı:

```powershell
.\run_stage13_smoke.bat
```

Bu smoke yalnızca Stage-13 testlerini çalıştırır ve `.expect` dosyalarıyla expected/actual karşılaştırması yapar.
