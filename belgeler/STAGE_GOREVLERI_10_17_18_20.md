# UXM Stage Görevleri: 10 / 17 / 18 / 20

## Stage-10
Görev: FP temel testleri, matrix advanced başlangıcı, tensor temel kapısı, bellek modeli ve eski servislerin regresyon güvenliği.
Durum: Kod yazıldı; V11 ile 16 MB memory modeli ayrıca doğrulandı. Eksik kalan kısım runner kaynaklı sahte uyuşmazlıktı; Stage-20 kapısı bunu tekrar kontrol eder.

## Stage-17
Görev: Test framework, `.expect` okuma, exact/compact/contains kipleri, hızlı hatalı test tekrar koşusu ve Türkçe raporlama.
Durum: Kod yazıldı; fakat eski koşuda `#source:embedded_EXPECT_OUTPUT` metaverisi beklenen çıktı sayılıyordu. V14 runner ve `beklenen_duzelt` bunu kalıcı temizler.

## Stage-18
Görev: Mega corpus / translator örnekleri, domain mini programları, tensor 2D/3D/4D köprüleri ve servis gerçekçiliği.
Durum: Kalan ana hata tensor4d testinin DATA dims/index yazmadan servis çağırmasıydı; V13/V14 ile düzeltildi. Stage-20 içinde tekrar doğrulanır.

## Stage-20
Görev: Sürüm kalite kapısı. Stage-10 bellek, Stage-17 runner, Stage-18 tensor köprüsü ve temel DATA/FIFO/native yollarını tek temiz kapıda doğrulamak.
Durum: V14 ile yazıldı ve tamamlandı. Testler `uxm/tests/stage20/` altındadır.
