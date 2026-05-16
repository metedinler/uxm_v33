UXM VSCode <-> Interpreter JSON iletişim protokolü

Konum: `tools/vscode_integration/comm/`

Protokol (basit):

- Extension, UXM runtime'a istek göndermek için `command_<id>.json` dosyası yazar.
  - Örnek içerik: `{ "id": "12345", "cmd": "compile", "cwd": "C:\\path\\to\\workspace" }`

- UXM interpreter (runtime içindeki bir izleyici) bu dizini izler, `command_*.json` dosyasını işler ve sonucu `result_<id>.json` olarak yazar.
  - Örnek sonuç: `{ "id": "12345", "ok": true, "stdout": "...", "stderr": "..." }`

- Uzantı 10s süre boyunca `result_<id>.json` dosyasını bekler; bulunamazsa kontrol sunucusuna (http://127.0.0.1:8765) fallback yapar.

Geliştirme notları:
- UXM runtime içinde bir "comm watcher" ekleyerek bu protokole cevap verebilirsiniz.
- Dosya isimleri `command_<id>.json` / `result_<id>.json` şeklinde olmalıdır.
