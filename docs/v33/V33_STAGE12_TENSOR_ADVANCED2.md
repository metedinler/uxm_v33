# UXM V3.3 Stage-12 Tensor Advanced-2

Bu faz Stage-11 tensor ND omurgasını genişletir. Amaç yalnızca yeni servis eklemek değil, yeni servislerin beklenen/gerçekleşen çıktı uyumunu smoke test ile kontrol etmektir.

## Servis aralığı

`@575..@584` Stage-12 Tensor Advanced-2 servisleri olarak kullanılır.

| Meta | Ad | Kısa açıklama |
|---:|---|---|
| @575 | TENSOR_RESHAPE | Toplam eleman sayısı aynı kalmak şartıyla 3D/4D tensor reshape |
| @576 | TENSOR_FLATTEN_TO_2D | ND tensorü 2D tensore düzleştirir; satır sayısı parametre olarak verilir |
| @577 | TENSOR_SLICE3D_AXIS1_TO_2D | 3D tensorden axis=1 düzlem kesiti alır |
| @578 | TENSOR_SLICE3D_AXIS2_TO_2D | 3D tensorden axis=2 düzlem kesiti alır |
| @581 | TENSOR_BROADCAST_ADD | NumPy benzeri temel broadcast uyumluluğuyla iki ND tensorü toplar |
| @582 | TENSOR_BROADCAST_SHAPE | İki ND tensorün broadcast çıktı şeklini data alanına yazar |
| @583 | TENSOR_RESHAPE_INFER | Dims içinde tek `0` değerini otomatik çıkarılan boyut olarak yorumlar |
| @584 | TENSOR_FLATTEN_TO_1D | ND tensorü 1 x total biçimindeki 2D tensore düzleştirir |

## Frame düzeni

Mevcut tensor frame düzeni korunur:

```text
T-4 = dst / output base
T-3 = A / src base
T-2 = B / dimsBase / rows / aux
T-1 = p1 / nd / slice index
T   = p2
```

## Yeni testler

```text
uxm/tests/v33/test_v33_tensor_reshape_infer_flatten.uxm
uxm/tests/v33/test_v33_tensor_slice_axes.uxm
uxm/tests/v33/test_v33_tensor_broadcast_add.uxm
```

Beklenen compact çıktılar:

```text
test_v33_tensor_reshape_infer_flatten.uxm -> 82777782
test_v33_tensor_slice_axes.uxm            -> 77667755
test_v33_tensor_broadcast_add.uxm         -> 223127225
```

## Smoke test

```powershell
.\run_stage12_smoke.bat
```

Bu smoke test hem eski temel hattı hem de Stage-12 tensor servislerinin beklenen compact çıktılarını kontrol eder.
