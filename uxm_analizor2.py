import os
import re

def create_service_report(base_path):
    opt_dir = os.path.join(base_path, "optimizasyon")
    if not os.path.exists(opt_dir):
        os.makedirs(opt_dir)
    
    report_file = os.path.join(opt_dir, "uxm_servis_raporu.txt")
    meta_pattern = re.compile(r"Case\s+(\d+)(?:\s*:\s*)?(?:\s*'\s*(.*))?", re.IGNORECASE)
    comment_pattern = re.compile(r"'\s*(.*)")
    
    
    with open(report_file, "w", encoding="utf-8") as report:
        report.write(f"UX-MINIMA SERVIS ANALIZ RAPORU\n")
        report.write(f"Tarih: {os.popen('date /t').read().strip()} {os.popen('time /t').read().strip()}\n")
        report.write(f"{'='*80}\n\n")

        uxm_path = os.path.join(base_path, "uxm")
        for root, _, files in os.walk(uxm_path):
            for file in files:
                if file.endswith((".bas", ".inc")):
                    full_path = os.path.join(root, file)
                    report.write(f"\n[DOSYA]: {full_path}\n")
                    report.write(f"{'-'*80}\n")
                    
                    with open(full_path, "r", encoding="utf-8", errors="ignore") as f:
                        for i, line in enumerate(f):
                            match = meta_pattern.search(line)
                            if match:
                                m_id, desc = match.groups()
                                report.write(f"Satir {i+1:<4} | ID: @{m_id:<3} | Bilgi: {desc or 'Açıklama yok'}\n")

    print(f"Rapor başarıyla oluşturuldu: {report_file}")
# Programın gerçekten çalışması için bu bloğun en altta olması gerekir:
if __name__ == "__main__":
    # Kendi dizin yolunuzu buraya yazın
    MY_PATH = r"C:\Users\mete\Downloads\1\UXMv33"
    
    print(f"Sistem başlatılıyor: {MY_PATH}")
    create_service_report(MY_PATH)
    print("İşlem tamamlandı.")
# Kullanım:
# create_service_report(r"C:\Users\mete\Downloads\1\UXMv33")