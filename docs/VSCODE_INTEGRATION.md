# VSCode Entegrasyonu — UXMv33

Bu doküman VSCode ile proje geliştirme için kısa kılavuz sağlar.

Özet:
- `Terminal → Run Task...` ile `Compile UXM` veya `Run UXM Tests` çalıştırılabilir.
- Dosya-tabanlı iletişim: tercih edilen yöntem, uzantının `tools/vscode_integration/comm/` dizinine `command_<id>.json` dosyası yazmasıdır. UXM runtime bu dosyayı işleyip `result_<id>.json` ile yanıtlar.
- `Run UXM Control Server` görevi küçük bir HTTP sunucusu başlatır (localhost:8765) — bu sunucu fallback ve bazı etkileşim uç noktaları sağlar.
- `Emekliler/` dizini `.gitignore` içinde saklanır ve explorer'da gizlenir.

Dosya-tabanlı iletişim (tercih):
- Uzantı `tools/vscode_integration/comm/` içine `command_<id>.json` yazar.
- UXM runtime bir dinleyici ile bu dosyayı okuyup `result_<id>.json` yazar.
- Uzantı ~10s içinde sonucu bekler; bulunmazsa fallback olarak kontrol sunucusuna (http://127.0.0.1:8765) istek atar.

Kontrol sunucusu (fallback):
- Başlatma: `Python: Run UXM Control Server` veya `Start UXM Control Server` görevi.
- API örnekleri:
  - `POST /compile` — `build_native.bat` çalıştırır.
  - `POST /run` — `run_all_expected_tests_no_build.bat` çalıştırır.
  - `GET /addresses` — tanımlı alias/isimleri ve adresleri döner.
  - `POST /alias` — yeni alias ekler (JSON gövde: `{ "name": "TAPE", "address": "0x1000", "desc": "Tape memory" }`).
  - `GET /trace?file=<path>` — verilen dosyanın son satırlarını döner (interpreter trace log'larına bağlanmak için).

Geliştirme akışı önerisi:
1. `Compile UXM` ile derleme.
2. `Run UXM Tests` ile smoke test.
3. `Start UXM Control Server` başlat ve `http://localhost:8765/` üzerinden kontrol panelini kullan.

Detaylı kullanım ve entegrasyon `tools/vscode_integration/README.md` dosyasında bulunur.
