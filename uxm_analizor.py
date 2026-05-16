import os
import re

def analyze_uxm_services(base_path):
    # Senin bilgisayarındaki uxm runtime dizini
    runtime_path = os.path.join(base_path, "uxm", "core", "runtime", "services")
    meta_pattern = re.compile(r"Case\s+(\d+)")
    comment_pattern = re.compile(r"'\s*(.*)")

    results = []

    if not os.path.exists(runtime_path):
        print(f"Hata: {runtime_path} bulunamadı!")
        return

    print(f"--- UX-MINIMA Servis Analizi Başladı ---")
    print(f"Dizin: {runtime_path}\n")

    for root, dirs, files in os.walk(runtime_path):
        for file in files:
            if file.endswith(".bas"):
                file_path = os.path.join(root, file)
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    current_service = None
                    for line in f:
                        # Case ID yakalama
                        meta_match = meta_pattern.search(line)
                        if meta_match:
                            meta_id = meta_match.group(1)
                            # Aynı satırdaki veya bir sonraki satırdaki açıklamayı al
                            comment = ""
                            if "'" in line:
                                comment = line.split("'")[1].strip()
                            
                            results.append({
                                "id": meta_id,
                                "file": file,
                                "desc": comment
                            })

    # ID'ye göre sırala ve yazdır
    results.sort(key=lambda x: int(x["id"]))
    
    print(f"{'MetaID':<8} | {'Dosya':<40} | {'Açıklama'}")
    print("-" * 100)
    for res in results:
        print(f"{res['id']:<8} | {res['file']:<40} | {res['desc']}")

if __name__ == "__main__":
    # Senin path gerçekliğin
    MY_PATH = r"C:\Users\mete\Downloads\1\UXMv33"
    analyze_uxm_services(MY_PATH)