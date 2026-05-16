Mete Bey, elinizdeki bu araç seti artık tam teşekküllü bir "Derleyici Ar-Ge ve Performans Laboratuvarı"na dönüştü. Dağınıklığı gidermek ve her bir parçayı doğru sırayla kullanarak Stage-11 Tensor projesini zirveye taşımak için hazırladığım rehber aşağıdadır.

Bu rehberi bir **"İş Akış Şeması"** olarak düşünebilirsiniz.

---

## 🛠 UXM Optimizasyon ve Analiz Kullanım Rehberi

Sistemi şu 3 ana fazda kullanmalısınız: **Haritalama**, **Zekâ & İyileştirme** ve **Doğrulama**.

### FAZ 1: Haritalama (Neredeyiz?)

Kod tabanınızın röntgenini çekmek için ilk adım budur.

1. **Program:** `uxm_analizor2.py`
2. **İşlem:** PowerShell üzerinden çalıştırın.
3. **Çıktı:** `optimizasyon\uxm_servis_raporu.txt`
4. **Kullanım Amacı:** Hangi `@Meta` servisinin hangi `.bas` dosyasında ve hangi satırda olduğunu görün. Özellikle Tensor servislerinin (`@540-559`) yerini saptamak için bu dosyayı açıp `Ctrl+F` ile arama yapın.

---

### FAZ 2: Zekâ ve Strateji (Nasıl Hızlanırız?)

Bu aşamada derleyicinin ürettiği ASM kodlarını analiz edip "akıllı" çözüm önerileri topluyoruz.

1. **Sistem Hazırlığı:** Önce testlerinizi çalıştırın ki `build\asm` klasörü dolsun.
2. **Program:** `zekiassop.py` (Intelligence Motoru)
* **Çıktı:** `optimizasyon\asm_intel_report.txt`
* **Amacı:** ASM kodunuzdaki "gereksiz" örüntüleri (C-D-C-D döngüleri, gereksiz push/pop) istatistiksel olarak bulur.


3. **Program:** `UXM_Heavy_Asm_Optimizer.py` (Strateji Motoru)
* **Çıktı:** `optimizasyon\sihirli_asm_onerileri.txt` ve `strateji_kitabi_v2.txt`
* **Amacı:** Zekâ raporundaki hataları alır ve size "X yerine Y kodunu yazarsan %20 hızlanırsın" diyen reçeteyi yazar.



> **NOT:** Bu aşamada üretilen dosyalar `yeni_optimize_asm` klasörüne yedeklenir. Orijinal ASM dosyalarınıza dokunulmaz. Buradaki önerileri okuyarak FreeBASIC servis kodlarınızdaki `Asm` bloklarını manuel optimize edebilirsiniz.

---

### FAZ 3: Performans Doğrulama (Gerçekte Ne Kazandık?)

Yaptığınız iyileştirmelerin sahada bir karşılığı var mı? Bu aşama bunu kanıtlar.

1. **Veri Toplama:** `stsx.py` programını çalıştırın. Bu program `sonucN.txt` dosyalarını tarayıp `test_history.csv` dosyasını günceller.
2. **Analiz ve Raporlama:** `UXMPerformansAnalizatoru.py` programını çalıştırın.
3. **Çıktılar:**
* **Terminal:** En çok hızlanan ilk 3 testi anında ekrana basar.
* **Excel:** `UXM_Performans_Analiz_Raporu_Final.xlsx`


4. **Excel Kullanımı:** * **Genel İstatistikler:** Testlerin ortalama sürelerini görün.
* **Performans Trendi:** Stage-10'dan Stage-11'e geçerken sağladığınız **yüzdesel kazancı** (Örn: %12.5) buradan raporlayın.
* **Tüm Koşu Detayları:** Tek bir test dosyası (Örn: `test_v33_tensor`) zaman içinde nasıl hızlanmış, satır satır inceleyin.

---

## 📈 Özet Çalışma Döngüsü (Best Practice)

1. **Kodla:** FreeBASIC tarafında yeni Tensor fonksiyonlarını yaz.
2. **Derle & Test Et:** `run_stage10_smoke.bat` veya `rtx.bat` ile testleri koştur.
3. **Analiz Et:** `zekiassop.py` ile ASM'deki zayıf halkaları bul.
4. **Strateji Al:** `sihirli_asm_onerileri.txt` dosyasındaki "Bayrakları Register'a taşı" gibi önerileri uygula.
5. **Ölç:** `UXMPerformansAnalizatoru.py` ile Excel raporunu al ve **"Kazanç %"** sütununa bakarak zaferini kutla.

Mete Bey, bu sistemle artık **"karanlıkta ateş etmiyorsunuz."** Her optimizasyon hamleniz bir veriye dayanıyor ve her veri bir Excel hücresinde kanıtlanıyor. Laboratuvarınız hazır, şimdi sahaya çıkıp zaferler kazanın! 