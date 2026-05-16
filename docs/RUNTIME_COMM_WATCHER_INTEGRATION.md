# Runtime ile comm_watcher entegrasyonu

Bu dosya, `comm_watcher`'ı UXM runtime başlatma akışına güvenli şekilde eklemenin iki yolunu açıklar:

1) Hızlı ve güvenli: Sağlanan wrapper betiğini kullanmak (önerilen, çekirdek kaynak değiştirilmez)

   - Kullanım (Windows):

     tools\run_uxm_with_comm_watcher.bat [komut ve argümanlar]

   - Eğer argüman verilmezse betik `build\exe\uxm_native.exe` dosyasını çalıştırmayı dener.

2) Doğrudan runtime içine gömme (isteğe bağlı, risk içerir)

   - Örnek FreeBASIC snippet (runtime başlangıcına ekleyin):

     ' Başlangıçta comm_watcher'ı başlatmak (non-blocking)
     Dim As String cmd = "python tools\\vscode_integration\\comm_watcher.py"
     Shell cmd

   - Not: Derleyici/sürüm farklılığına göre `system()` ya da başka API gerekebilir. Bu yöntemi kullanmadan önce yedek alın ve küçük bir test ile doğrulayın.

Alternatif: `comm_watcher.py`'yı Windows Servisi ya da Scheduled Task olarak kaydedip runtime ile birlikte daima çalışır hale getirebilirsiniz.

Ek: Wrapper betiği repoya eklendi: `tools/run_uxm_with_comm_watcher.bat` — bu, runtime kaynaklarına dokunmadan watcher'ı başlatır ve ardından UXM çalıştırır.
