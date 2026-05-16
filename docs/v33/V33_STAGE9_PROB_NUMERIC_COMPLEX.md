# UXM V3.3 Stage-9 Probability / Numeric / Complex Services

Bu faz Stage-8 istatistik hattı başarılı olduktan sonra eklenmiştir.

## Service ranges

```text
@380..@389  Probability / random V1
@420..@439  Numerical methods V1
@440..@459  Complex numbers V1
```

`@340..@379` aralığı UX-STR V2 tarafından kullanıldığı için probability servisleri eski V35 taslağındaki `@360..@389` yerine `@380..@389` aralığına taşındı. `@400..@415` FILE V1 tarafından kullanıldığı için numeric servisleri `@420..@439` aralığında başlatıldı.

## Probability V1

- `@380 RAND_SEED`
- `@381 RAND_UNIFORM_01`
- `@382 RAND_INT_RANGE`
- `@383 RAND_BERNOULLI`
- `@384 RAND_POISSON`
- `@385 RAND_BINOMIAL`
- `@386 RAND_WEIGHTED`
- `@387 RAND_SHUFFLE_DATA`
- `@388 RAND_NORMAL_SCALED`
- `@389 RAND_STATUS`

## Numeric V1

- `@420 NUM_POLY_EVAL`
- `@421 NUM_NEWTON`
- `@422 NUM_BISECTION`
- `@423 NUM_TRAPEZOID_POLY`
- `@424 NUM_SIMPSON_POLY`
- `@425 NUM_INTERP_LINEAR`
- `@426 NUM_BEZIER_QUADRATIC`
- `@427 NUM_RK4_LINEAR`
- `@439 NUM_STATUS`

Polynomial data layout:

```text
data[base+0] = degree
data[base+1+i] = coefficient for x^i
```

## Complex V1

- `@440 CPLX_INIT`
- `@441 CPLX_ADD`
- `@442 CPLX_SUB`
- `@443 CPLX_MUL`
- `@444 CPLX_DIV`
- `@445 CPLX_CONJ`
- `@446 CPLX_ABS`
- `@447 CPLX_ARG`
- `@448 CPLX_EXP`
- `@449 CPLX_FROM_POLAR`
- `@459 CPLX_STATUS`

Complex data layout:

```text
data[base+0] = 67 magic marker
data[base+1] = real scaled 1e6
data[base+2] = imag scaled 1e6
data[base+3] = status
```

## Tests

```text
uxm/tests/v33/test_v33_probability_random.uxm
uxm/tests/v33/test_v33_numeric_poly_integral.uxm
uxm/tests/v33/test_v33_complex_basic.uxm
```
