import pandas as pd
import datetime
import os
import glob

def parse_time(time_str):
    try:
        time_str = time_str.replace(',', '.').strip()
        h, m, s = time_str.split(':')
        return float(h)*3600 + float(m)*60 + float(s)
    except:
        return 0

def run_analysis():
    # En son oluşturulan sonucN.txt dosyasını bul
    log_files = glob.glob("sonuc*.txt")
    if not log_files:
        print("Hata: sonucN.txt bulunamadı!")
        return
    
    # En son değiştirilen dosyayı al
    log_file = max(log_files, key=os.path.getmtime)
    history_file = "test_history.csv"
    summary_file = "test_stats_summary.csv"
    
    print(f"Analiz ediliyor: {log_file}...")

    current_results = []
    build_start, build_duration = 0, 0
    test_starts = {}
    current_time_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

    with open(log_file, "r", encoding="latin-1") as f:
        for line in f:
            parts = line.strip().split('@')
            if len(parts) < 2: continue
            
            tag = parts[0]
            if tag == "START_BUILD": build_start = parse_time(parts[1])
            elif tag == "END_BUILD": build_duration = parse_time(parts[1]) - build_start
            elif tag == "DATA_START": test_starts[parts[1]] = parse_time(parts[2])
            elif tag == "DATA_END":
                name = parts[1]
                duration = parse_time(parts[2]) - test_starts.get(name, 0)
                current_results.append({
                    "Tarih": current_time_str,
                    "Test_Adi": name,
                    "Son_Sure": round(duration, 4),
                    "Derleme_Sn": round(build_duration, 4)
                })

    if not current_results:
        print("Hata: İşlenecek veri bulunamadı!")
        return

    df_now = pd.DataFrame(current_results)

    # Geçmiş yükleme
    if os.path.exists(history_file) and os.path.getsize(history_file) > 0:
        df_history = pd.read_csv(history_file)
    else:
        df_history = pd.DataFrame(columns=["Tarih", "Test_Adi", "Son_Sure", "Derleme_Sn"])

    # İstatistiksel özet
    df_combined = pd.concat([df_history, df_now], ignore_index=True)
    summary = df_combined.groupby("Test_Adi").agg(
        Calistirma_Sayisi=("Son_Sure", "count"),
        Ortalama_Sure=("Son_Sure", "mean"),
        Son_Sure=("Son_Sure", "last")
    ).reset_index().round(4)

    # Kayıt
    df_now.to_csv(history_file, mode='a', index=False, header=not os.path.exists(history_file))
    summary.to_csv(summary_file, index=False)
    
    print(f"--- ANALİZ BİTTİ (Dosya: {log_file}) ---")
    print(f"Toplam Test: {len(df_now)} | Özet: {summary_file}")

if __name__ == "__main__":
    run_analysis()