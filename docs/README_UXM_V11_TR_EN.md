# UXM V11 Türkçe/İngilizce Komut Seti

Mete abi, bu paket V10'daki tek harfli komutları kaldırır ve anlamlı kısa adlara geçirir.

## Türkçe ana komutlar

```powershell
yardim.bat
derleyici_derle.bat
bellek_test.bat
hizli_tara.bat
hatali_test.bat -k -D
tum_test.bat -k -n 100
alan_topla.bat
alan_topla.bat -u -b
rapor_goster.bat
vscode_kur.bat
```

## English tools

```powershell
tool_en\help.bat
tool_en\memory_test.bat
tool_enast_scan.bat
tool_enailed_test.bat -k -D
tool_enll_test.bat -k -n 100
tool_en\workspace_clean.bat
tool_en\workspace_clean.bat -u -b
tool_eneport_show.bat
tool_enscode_install.bat
```

## Dizin düzeni

- `araclar/`: Türkçe Python araçları.
- `tool_en/`: İngilizce Python ve bat araçları.
- `ortak/`: İki dilin kullandığı ortak çekirdek.
- `onceki_src/`: Yüklediğin çalışma alanından alınmış önceki kaynak kopyaları.
- `guncel_src/` ve `uxm/`: Bu paketin uygulayacağı güncel kaynak/test dosyaları.
- `vscode/`: Türkçe+İngilizce UXM VSCode eklentisi.

## V9 düzeltme özeti

- `tensor4d_flat_logic` düzeltmesi korunur.
- Eski `memory_model_v7` smoke yerine `bellek_v11` testleri kullanılır.
- Büyük bellek değerlerini byte cell içinde yazdırma hatası önlenir.
- CSV field limit ve CSV bulunamadı sorunları giderilir.
- Hızlı tarama eski/stale manifest ile sessizce devam etmez.
