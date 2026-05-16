# UXM V33 Stage-20 V14 Paketi

Bu paket Stage-17/18 kalanlarını temizler ve Stage-20 kalite kapısını ekler.

## Hızlı görev özeti

- Stage-10: FP + matrix/tensor temel + 16 MB memory regresyon kapısı.
- Stage-17: Test runner, `.expect` parser, compact/exact/contains, hızlı hata tekrar koşusu.
- Stage-18: Mega corpus, translator/domain örnekleri, tensor 4D köprüsü.
- Stage-20: Yukarıdaki yolları tek sürüm kalite kapısında doğrular.

## Çalıştırma

```powershell
stage_gorevleri.bat
stage17_duzelt.bat
stage17_kontrol.bat -k
stage18_tamamla.bat -k
stage20_tamamla.bat -k
```

İngilizce:

```powershell
tool_en\stage_tasks.bat
tool_en\stage20_finish.bat -k
```
