# UXM V16 Placeholder -> Gerçek Kod Paketi

Mete abi, bu paket kılavuzda **var** yazılıp önceki registry/kodda placeholder, planned, reserved veya no-op kalan ilk kritik servis grubunu gerçek runtime koduna bağlar.

## Gerçekleştirilenler

- `@270..@273`: quartile, percentile, skewness, excess kurtosis
- `@281..@282`: Spearman rho, Kendall tau-b
- `@760..@769`: hipotez testleri için gerçek hesap bandı
- `@790..@795`: iki grup posthoc karar hattı
- `@810..@817`: AI metrikleri ve mesafe servisleri
- `placeholder_tara.bat`: kalan TODO/dummy/placeholder izlerini CSV/MD raporlar
- `placeholder_kapi.bat`: bulgu varsa release kapısını başarısız döndürür
- `stage21_placeholder_test.bat`: yeni gerçek servislerin regression testi

## Dürüst not

Bu paket tüm UXM evrenindeki her planlanmış ileri matematik fonksiyonunu bitirdim iddiası değildir. Ama kılavuzda var gibi görünen ve doğrudan yalan/placeholder durumuna düşen ana servisleri gerçek hesap yapan runtime case'lerine dönüştürür. Kalanlar `placeholder_tara.bat` ile görünür hale getirilir ve release kapısında saklanamaz.

## Uygulama

ZIP'i UXMv33 köküne aç:

```powershell
placeholder_tara.bat
stage21_placeholder_test.bat -k
placeholder_kapi.bat
```

Eğer `placeholder_kapi.bat` hata verirse rapora bak: `placeholder_raporu/PLACEHOLDER_RAPORU.md`.
