# UXM V33 Placeholder Gerçek Kod V17

Bu paket V16’dan sonra kalan placeholder/reserved gruplarının ikinci dalgasını gerçek servis koduna çevirir.

## Gerçek koda çevrilen gruplar

- `@291..@293`: çoklu regresyon, polinom regresyon, lojistik regresyon.
- `@410..@412`: dosya blok okuma/yazma/seek.
- `@416..@419`: dosya silme, yeniden adlandırma, klasör oluşturma, varlık kontrolü.
- `@181..@182`: matrix legacy ND get/set.
- `@190..@191`: 2x2 simetrik eigen ve 2x2 SVD singular değer yardımcıları.
- `@193..@195`: CSR sparse matvec, sparse→dense, dense→sparse.
- `@818..@823`: onehot, split, shuffle, KNN, linear layer, softmax.

## Uygulama

```powershell
stage22_placeholder_test.bat -k
placeholder_tara.bat
placeholder_kapi.bat
```

## Dürüst sınır

Bu paket eski belgelerdeki **disabled/reserved** FP boşluklarını gerçek servis diye açmaz. Onlar kılavuzda “yok/ayrılmış” diye yazılmalıdır. Bu paket yalnız kılavuzda var gibi geçen ve gerçek hesap isteyen ikinci öncelik grubunu kodlar.
