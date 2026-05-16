# UXM V12 - Stage-17 Düzeltme ve Stage-18 Geçiş Paketi

Bu paket V11 üzerine uygulanır. Ana hedef Stage-17 test framework kaynaklı sahte uyuşmazlıkları temizlemek ve Stage-18 mega corpus hattına geçişi düzenlemektir.

## Çözülen Stage-17 Sorunu

Önceki koşuda beklenen değerler `#source:embedded_EXPECT_OUTPUT...` ile başlıyor, gerçek değer aynı olduğu halde testler `UYUSMAZ` görünüyordu. Bu compiler/runtime hatası değil, test framework `.expect` okuyucu hatasıdır.

V12 ile:

- Runner `.expect` gövdesindeki `#source:*`, `#expect_output*`, `#embedded_EXPECT_OUTPUT*` metaverilerini çıktıdan ayırır.
- `beklenen_duzelt.bat` veya `stage17_duzelt.bat` mevcut `.expect` dosyalarını temizler.
- Türkçe ve İngilizce komut setleri korunur.

## Önerilen Sıra

```powershell
cd C:\Users\mete\Downloads\1\UXMv33
.\stage17_duzelt.bat
.\stage17_kontrol.bat -k
.\hizli_tara.bat
.\hatali_test.bat -k -D
.\stage18_basla.bat -k -n 50
```

## İngilizce Karşılıklar

```powershell
tool_en\stage17_fix.bat
tool_en\stage17_check.bat -k
tool_en\fast_scan.bat
tool_en\failed_test.bat -k -D
tool_en\stage18_start.bat -k -n 50
```

## Not

`stage18_basla.bat` önce küçük limit ile denenmelidir. Tüm Stage-18 mega corpus uzun sürebilir.
