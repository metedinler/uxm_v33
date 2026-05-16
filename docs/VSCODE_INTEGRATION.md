# VSCode Entegrasyonu — UXMv33

Bu doküman VSCode ile proje geliştirme için kısa kılavuz sağlar.

Özet:
- `Terminal → Run Task...` ile `Compile UXM` veya `Run UXM Tests` çalıştırılabilir.
- `Run UXM Control Server` görevi küçük bir HTTP sunucusu başlatır (localhost:8765) — bu sunucu compile/run, alias yönetimi ve trace görüntüleme uç noktaları sağlar.
- `Emekliler/` dizini `.gitignore` içinde saklanır ve explorer'da gizlenir.

Kontrol sunucusu:
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
