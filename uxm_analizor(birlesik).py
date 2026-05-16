import os
import re

class UXM_Master_Analyzer:
    def __init__(self, base_path):
        self.base_path = base_path
        self.opt_dir = os.path.join(base_path, "optimizasyon")
        # İKİ AYRI RAPOR DOSYASI
        self.full_report_file = os.path.join(self.opt_dir, "uxm_proje_tam_harita.txt")
        self.runtime_report_file = os.path.join(self.opt_dir, "uxm_runtime_servis_ozeti.txt")
        
        self.meta_pattern = re.compile(r"Case\s+(\d+)(?:\s*:\s*)?(?:\s*'\s*(.*))?", re.IGNORECASE)
        
        if not os.path.exists(self.opt_dir):
            os.makedirs(self.opt_dir)

    def run_full_scan(self):
        """[RAPOR 1] Tüm uxm klasörünü tarar ve tam haritayı dosyaya yazar."""
        found_count = 0
        with open(self.full_report_file, "w", encoding="utf-8") as report:
            report.write(f"UX-MINIMA KAPSAMLI PROJE HARITASI (FULL SCAN)\n")
            report.write(f"Tarih: {os.popen('date /t').read().strip()}\n")
            report.write(f"{'='*100}\n")

            uxm_path = os.path.join(self.base_path, "uxm")
            for root, _, files in os.walk(uxm_path):
                for file in files:
                    if file.endswith((".bas", ".inc")):
                        full_path = os.path.join(root, file)
                        report.write(f"\n📂 DOSYA: {full_path}\n")
                        report.write(f"{'-'*80}\n")
                        
                        try:
                            with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                                for i, line in enumerate(f):
                                    match = self.meta_pattern.search(line)
                                    if match:
                                        m_id, desc = match.groups()
                                        report.write(f"   L{i+1:<4} | @{m_id:<3} | {desc or 'Açıklama yok'}\n")
                                        found_count += 1
                        except Exception as e:
                            report.write(f"   !!! HATA: {e}\n")
        print(f"[+] Tam Harita Raporu Hazır: {self.full_report_file}")

    def run_runtime_only_report(self):
        """[RAPOR 2] Sadece runtime/services klasörünü tarar ve özet dosyası yazar."""
        runtime_path = os.path.join(self.base_path, "uxm", "core", "runtime", "services")
        found_count = 0
        
        with open(self.runtime_report_file, "w", encoding="utf-8") as report:
            report.write(f"UX-MINIMA RUNTIME SERVIS OZETI\n")
            report.write(f"{'='*100}\n")
            report.write(f"{'ID':<6} | {'Dosya':<35} | {'Açıklama'}\n")
            report.write(f"{'-'*100}\n")

            results = []
            if os.path.exists(runtime_path):
                for root, _, files in os.walk(runtime_path):
                    for file in files:
                        if file.endswith(".bas"):
                            with open(os.path.join(root, file), "r", encoding="utf-8", errors="ignore") as f:
                                for line in f:
                                    match = self.meta_pattern.search(line)
                                    if match:
                                        m_id, desc = match.groups()
                                        results.append({"id": int(m_id), "file": file, "desc": desc or ""})
                
                results.sort(key=lambda x: x["id"])
                for res in results:
                    report.write(f"@{res['id']:<5} | {res['file']:<35} | {res['desc']}\n")
                    found_count += 1
            else:
                report.write("[!] Runtime yolu bulunamadı!\n")
        
        print(f"[+] Runtime Servis Özeti Hazır: {self.runtime_report_file}")

if __name__ == "__main__":
    MY_PATH = os.getcwd()
    master = UXM_Master_Analyzer(MY_PATH)
    
    # İki ayrı raporu da üret
    master.run_full_scan()
    master.run_runtime_only_report()
    
    print("\n[TAMAMLANDI] Her iki rapor 'optimizasyon' klasörüne kaydedildi.")