# UXM V3.3 Stage-8 Statistics / Regression V1

Bu aşama, önceki Stage-7 BIO paketinin üzerine temel istatistik ve basit regresyon servislerini ekler.

## Aktif servis aralığı

```text
@260..@299 = Statistics / Correlation / Regression V1
```

## Ölçekleme

Ondalıklı sonuçlar `1_000_000` çarpanıyla tamsayı olarak döner.

Örnek:

```text
30.0      -> 30000000
1.0       -> 1000000
2.0 slope -> 2000000
```

## Servisler

```text
@260 STAT_COUNT
@261 STAT_SUM
@262 STAT_MEAN_SCALED
@263 STAT_MIN
@264 STAT_MAX
@265 STAT_RANGE
@266 STAT_VARIANCE_SAMPLE_SCALED
@267 STAT_STDDEV_SAMPLE_SCALED
@268 STAT_MEDIAN_SCALED
@274 STAT_COVARIANCE_SCALED
@275 STAT_ZSCORE_SCALED
@280 CORR_PEARSON_SCALED
@290 REG_LINEAR
@298 REG_PREDICT
@299 REG_R2
```

## Frame standardı

Temel istatistik servisleri:

```text
T-3 = data start A
T-2 = data start B / opsiyonel
T-1 = count
T   = option
T+1 = result
```

Regresyon:

```text
@290 REG_LINEAR
T-3 = x data start
T-2 = y data start
T-1 = count
T   = output model data start
T+1 = output model data start

Model çıktısı:
D[out+0] = intercept scaled
D[out+1] = slope scaled
D[out+2] = pearson r scaled
```

## Testler

```text
uxm/tests/v33/test_v33_stat_sum_mean_minmax.uxm
uxm/tests/v33/test_v33_stat_median_variance.uxm
uxm/tests/v33/test_v33_corr_regression.uxm
```

## Stage-8 düzeltmesi

Eski `test_v33_dynamic_meta_addr.uxm` testi geçersiz `0(T+1)+k5(T+1)` biçimi kullanıyordu. Bu, `+k5` sonrası ikinci adreslemeyi kaynakta açıkta bıraktığı için `(` karakterinde syntax hatasına düşüyordu. Stage-8 testinde doğru biçim kullanıldı:

```text
0(T+1)+k5
@(T+1)
```
