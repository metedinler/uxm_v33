# UXM V3.3 Stage-10 — Matrix Advanced + Tensor Basic

Bu faz, mevcut UX-MAT V1 descriptor sistemini bozmadan yeni servis aralığı ekler.

## Servis aralığı

```text
@512..@519  Matrix Advanced V1
@540..@559  Tensor Basic V1
```

## Matrix Advanced V1

Frame konvansiyonu mevcut matrix servislerine uyumludur:

```text
T-4 = dst/out descriptor base
T-3 = A matrix descriptor base
T-2 = B/aux descriptor base
T-1 = option / row
T   = option / column / value
T+1 = scalar result/status
```

Aktif servisler:

```text
@512 MAT_ADV_DET_N        T-3=A, T+1=determinant, n<=8
@513 MAT_ADV_INVERSE_2    T-4=dst, T-3=A
@514 MAT_ADV_RANK         T-3=A, T+1=rank, rows/cols<=8
@516 MAT_ADV_NORM_INF     T-3=A, T+1=max row abs sum
@517 MAT_ADV_FROBENIUS2   T-3=A, T+1=sum of squares
@518 MAT_ADV_LU2          T-4=L, T-2=U, T-3=A
@519 MAT_ADV_INFO         bilgi satırı basar
```

## Tensor Basic V1

Tensor descriptor `data[]` içinde tutulur:

```text
base+0  magic=8401
base+1  ndims=2
base+2  dim0
base+3  dim1
base+4  total
base+5  data_offset=16
base+16 values row-major
```

Aktif servisler:

```text
@540 TENSOR_INIT2D    T-4=base, T-3=dim0, T-2=dim1
@541 TENSOR_SET2D     T-4=base, T-3=row, T-2=col, T-1=value
@542 TENSOR_GET2D     T-4=base, T-3=row, T-2=col, T+1=value
@543 TENSOR_FILL      T-4=base, T-3=value
@544 TENSOR_SUM       T-4=base, T+1=sum
@545 TENSOR_SHAPE     T-4=base, T+1=dim0, T+2=dim1, T+3=total
@559 TENSOR_INFO      bilgi satırı basar
```

## Testler

```text
uxm/tests/v33/test_v33_matadv_det_rank_norm.uxm
uxm/tests/v33/test_v33_matadv_inverse_identity.uxm
uxm/tests/v33/test_v33_tensor_basic.uxm
```
