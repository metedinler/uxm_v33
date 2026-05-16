# UXM V3.3 Stage-11 — Tensor Advanced

Bu aşama Stage-10 Hotfix-1 üzerine kuruludur. Amaç, 2D tensor temelini bozmadan 3D/4D tensor descriptor ve ilk ileri tensor işlemlerini eklemektir.

## Servis aralığı

- `@560..@599` Tensor Advanced V1

## Eklenen servisler

- `@560 TENSOR_INIT3D` — `T-4=base`, `T-3=d0`, `T-2=d1`, `T-1=d2`
- `@561 TENSOR_SET3D` — `T-4=base`, `T-3=i0`, `T-2=i1`, `T-1=i2`, `T=value`
- `@562 TENSOR_GET3D` — sonucu `T+1`
- `@563 TENSOR_INIT4D` — `T-4=base`, `T-3=dimsBase`; dims `data[dimsBase..dimsBase+3]`
- `@564 TENSOR_SET4D` — `T-4=base`, `T-3=idxBase`, `T-2=value`
- `@565 TENSOR_GET4D` — sonucu `T+1`
- `@566 TENSOR_FLAT_INDEX` — `T-4=base`, `T-3=idxBase`; sonucu `T+1`
- `@567 TENSOR_COPY`
- `@568 TENSOR_SLICE3D_AXIS0_TO_2D`
- `@570 TENSOR_ADD_SCALAR`
- `@571 TENSOR_ADD_SAME_SHAPE`
- `@573 TENSOR_ND_SUM`
- `@574 TENSOR_ND_SHAPE`
- `@599 TENSOR_ADV_INFO`

## Descriptor

Stage-11 ND tensor descriptor `data[]` içinde durur:

```text
base+0  magic = 8402
base+1  ndims = 3 veya 4
base+2  dim0
base+3  dim1
base+4  dim2
base+5  dim3; 3D için 1
base+6  total elements
base+7  data offset = 16
base+8  status
base+16 values row-major
```

Stage-10 2D tensor servisleri `@540..@545` korunur.

## Yeni testler

- `uxm/tests/v33/test_v33_tensor3d_index_slice.uxm` → compact output: `772377`
- `uxm/tests/v33/test_v33_tensor4d_flat.uxm` → compact output: `8811`
- `uxm/tests/v33/test_v33_tensor_add_scalar_same.uxm` → compact output: `218142`

## Smoke test

`run_stage11_smoke.bat` hem build hem de beklenen compact çıktı kontrolü yapar.
