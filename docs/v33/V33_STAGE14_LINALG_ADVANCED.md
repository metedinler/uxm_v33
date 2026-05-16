# UXM V3.3 Stage-14 Linear Algebra Advanced

Bu paket Stage-13 uzerinde calisir ve Stage-13 runtime_sparse_vector_services.bas icindeki fazla MetaSparseVector declare satirini de duzeltir.

## Servis araligi

- @520..@539: Linear Algebra Advanced V1

## Aktif servisler

- @520 LINALG_DET_N
- @521 LINALG_RANK
- @522 LINALG_UPPER_TRIANGULAR
- @523 LINALG_DIAG_PRODUCT
- @524 LINALG_INVERSE_NXN
- @525 LINALG_SOLVE_NXN
- @526 LINALG_MATVEC
- @527 LINALG_IS_IDENTITY
- @528 LINALG_IS_SYMMETRIC
- @529 LINALG_ROW_SUM
- @530 LINALG_COL_SUM
- @531 LINALG_SWAP_ROWS
- @532 LINALG_SCALE_ROW
- @533 LINALG_ADD_ROW_MULTIPLE
- @539 LINALG_INFO

## Test politikasi

Bu pakette eski testler tekrar uretilmez. Sadece Stage-14 klasoru vardir:

```text
uxm/tests/v33/stage14/
```

Her servis icin tekil test ve en az iki birlesik test bulunur. Smoke dosyasi sadece Stage-14 testlerini calistirir:

```powershell
.\run_stage14_smoke.bat
```
