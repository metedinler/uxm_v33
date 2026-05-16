import os
import subprocess
import time
import sqlite3
import difflib
from datetime import datetime

class UXM_Pro_Analyzer:
    def __init__(self, base_path):
        self.base_path = base_path
        # Klasör yapısını garanti altına al
        self.opt_base = os.path.join(base_path, "optimizasyon")
        self.analiz_merkezi = os.path.join(self.opt_base, "analiz_merkezi")
        self.current_run_dir = os.path.join(self.analiz_merkezi, datetime.now().strftime("%Y%m%d_%H%M%S"))
        self.db_path = os.path.join(self.opt_base, "uxm_perf_history.db")
        
        # Klasörleri oluştur
        for d in [self.analiz_merkezi, self.current_run_dir]:
            if not os.path.exists(d): os.makedirs(d)
        
        self._init_db()

    def _init_db(self):
        """SQLite Veritabanını hazırlar."""
        conn = sqlite3.connect(self.db_path)
        conn.execute('''CREATE TABLE IF NOT EXISTS perf_logs 
            (id INTEGER PRIMARY KEY AUTOINCREMENT, 
             test_name TEXT, 
             timestamp TEXT, 
             orig_ms REAL, 
             opt_ms REAL, 
             gain_perc REAL, 
             status TEXT, 
             output_match INTEGER)''')
        conn.close()

    def run_and_measure(self, exe_path):
        """Mikrosaniye (nanosaniye bazlı) hassasiyetinde ölçüm yapar ve çıktıyı alır."""
        if not os.path.exists(exe_path):
            return None, None, -1

        start = time.perf_counter_ns()
        # stdout ve stderr'i yakalıyoruz ki farkları görelim
        proc = subprocess.run(exe_path, capture_output=True, text=True, shell=True)
        end = time.perf_counter_ns()
        
        duration_ms = (end - start) / 1_000_000 # Milisaniyeye çevir
        return duration_ms, proc.stdout.strip(), proc.returncode

    def process_test(self, test_name):
        orig_exe = os.path.join(self.base_path, "build", "exe", f"{test_name}.exe")
        opt_exe = os.path.join(self.base_path, "build", "exe", f"{test_name}_opt.exe")

        # Ölçümleri yap
        t_orig, out_orig, code_orig = self.run_and_measure(orig_exe)
        t_opt, out_opt, code_opt = self.run_and_measure(opt_exe)

        if t_orig is None or t_opt is None:
            return

        # ÇIKTI KARŞILAŞTIRMA (Hepsinden önemlisi)
        is_match = (out_orig == out_opt)
        match_status = "TAM_ESLESME" if is_match else "HATALI_CIKTI"
        
        if not is_match:
            # Fark dosyasını (diff) analiz_merkezi içine yaz
            diff = difflib.unified_diff(
                out_orig.splitlines(keepends=True), 
                out_opt.splitlines(keepends=True), 
                fromfile='Orijinal', tofile='Optimize'
            )
            with open(os.path.join(self.current_run_dir, f"_diff_{test_name}.txt"), "w", encoding="utf-8") as f:
                f.writelines(diff)

        # HIZ KAZANCI HESABI
        gain = ((t_orig - t_opt) / t_orig) * 100
        
        # OPTIMIZASYON DURUM BELİRLEME
        if not is_match:
            status = "KRITIK_HATA_CIKTI_FARKLI"
        elif t_opt < t_orig:
            status = "BASARILI_OPTIMIZASYON"
        else:
            status = "BASARISIZ_YAVASLAMA_VAR"

        # SQL VERİTABANINA KAYDET
        conn = sqlite3.connect(self.db_path)
        conn.execute("""INSERT INTO perf_logs 
            (test_name, timestamp, orig_ms, opt_ms, gain_perc, status, output_match) 
            VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (test_name, datetime.now().isoformat(), t_orig, t_opt, gain, status, 1 if is_match else 0))
        conn.commit()
        conn.close()

        # ÖZET LOG DOSYASINA YAZ (Okunması kolay format)
        log_file = os.path.join(self.current_run_dir, "UXM_orgASM-optASM_analiz_ozeti.txt")
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"TEST: {test_name}\n")
            f.write(f" - Durum: {status}\n")
            f.write(f" - Orijinal Süre: {t_orig:.6f} ms\n")
            f.write(f" - Optimize Süre: {t_opt:.6f} ms\n")
            f.write(f" - Fark (Kazanç): %{gain:.2f}\n")
            f.write(f" - Çıktı Doğruluğu: {'AYNI' if is_match else '!!! FARKLI !!!'}\n")
            f.write("-" * 50 + "\n")

        print(f"[{status}] {test_name}: %{gain:.2f} kazanç")

if __name__ == "__main__":
    MY_PATH = os.getcwd()
    # build/exe klasörünün varlığını kontrol et, Klasör yolunu değişkene alalım
    exe_path = os.path.join(MY_PATH, "build", "exe")
    
    # KONTROL: Klasör var mı?
    if not os.path.exists(exe_path):
        # Klasör yoksa oluştur ki program çökmesin
        os.makedirs(exe_path)
        print(f"Uyarı: {exe_path} klasörü yoktu, oluşturuldu. Lütfen önce derleme yapın.")
    else:
        analyzer = UXM_Pro_Analyzer(MY_PATH)
        print(f"Analiz Başladı. Kayıt Klasörü: {analyzer.current_run_dir}")
        for file in os.listdir(exe_path):
            if file.endswith(".exe") and "_opt" not in file:
                test_name = file.replace(".exe", "")
                analyzer.process_test(test_name)