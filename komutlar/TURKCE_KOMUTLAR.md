# UXM Türkçe komut seti V13

## Temel

```powershell
yardim.bat
derleyici_derle.bat
bellek_test.bat
hizli_tara.bat
hatali_test.bat -k -D
tum_test.bat -k -n 100
rapor_goster.bat
alan_topla.bat -u -b
vscode_kur.bat
```

## Stage-17 düzeltme

```powershell
stage17_duzelt.bat
stage17_kontrol.bat -k
```

## Stage-18 tamamlama

```powershell
stage18_duzelt.bat
stage18_kontrol.bat -k
stage18_tamamla.bat -k
```

## Stage-19 başlatma ve bitirme

```powershell
stage19_basla.bat -k
stage19_test.bat -k
stage19_tamamla.bat -k
```

## Kısa seçenekler

- `-k`: derleme yok / mevcut derleyiciyi kullan
- `-D`: ilk hatada dur
- `-n N`: en fazla N test
- `-s N`: N. testten başla
- `-a METIN`: test adında metin ara
- `-u`: uygula
- `-b`: build klasörünü emekliye al
- `-h`: yardım
