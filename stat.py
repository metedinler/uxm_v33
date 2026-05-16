import pandas as pd
import datetime
import os

def parse_time(time_str):
    """Windows zaman formatını saniyeye çevirir."""
    try:
        time_str = time_str.replace(',', '.').strip()
        h, m, s = time_str.split(':')
        return float(h)*3600 + float(m)*60 + float(s)
    except:
        return 0

def run_analysis():
    log_file = "sonuc.txt"
    history_file = "test_history.csv"
    
    if not os.path.exists(log_file):
        print("Hata: sonuc.txt bulunamadı!")
        return

    current_results = []
    build_start, build_duration = 0, 0
    test_starts = {}
    
    print("Veriler analiz ediliyor...")
    
    with open(log_file, "r", encoding="latin-1") as f:
        for line in f:
            line = line.strip()
            if "START_BUILD:" in line:
                build_start = parse_time(line.split("START_BUILD:")[1])
            elif "END_BUILD:" in line:
                build_duration = parse_time(line.split("END_BUILD:")[1]) - build_start
            elif line.startswith("DATA_START"):
                parts = line.split('|')
                if len(parts) >= 3:
                    test_starts[parts[1]] = parse_time(parts[2])
            elif line.startswith("DATA_END"):
                parts = line.split('|')
                if len(parts) >= 3:
                    name, end_time = parts[1], parse_time(parts[2])
                    duration = end_time - test_starts.get(name, end_time)
                    current_results.append({
                        "Tarih": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
                        "Test_Adi": name,
                        "Sure_Sn": round(duration, 4),
                        "Derleme_Sn": round(build_duration, 4)
                    })

    if not current_results:
        print("Hata: İşlenecek veri bulunamadı!")
        return

    df_now = pd.DataFrame(current_results)

    # Karşılaştırma Analizi
    if os.path.exists(history_file) and os.path.getsize(history_file) > 0:
        try:
            df_hist = pd.read_csv(history_file)
            last_date = df_hist["Tarih"].iloc[-1]
            df_prev = df_hist[df_hist["Tarih"] == last_date]
            df_final = pd.merge(df_now, df_prev[['Test_Adi', 'Sure_Sn']], on='Test_Adi', how='left', suffixes=('', '_Onceki'))
            df_final['Fark'] = df_final['Sure_Sn'] - df_final['Sure_Sn_Onceki']
            df_final['Durum'] = df_final['Fark'].apply(lambda x: "Yavaşladı ⚠" if x > 0.005 else ("Hızlandı ✅" if x < -0.005 else "Aynı"))
        except:
            df_final = df_now.copy()
            df_final['Durum'] = "Yeni Kayıt"
    else:
        df_final = df_now.copy()
        df_final['Durum'] = "İlk Çalıştırma"

    # Kaydet
    df_now.to_csv(history_file, mode='a', index=False, header=not os.path.exists(history_file))

    # Excel Çıktısı
    excel_name = f"Performans_Raporu_{datetime.datetime.now().strftime('%Y%m%d_%H%M')}.xlsx"
    with pd.ExcelWriter(excel_name, engine='openpyxl') as writer:
        df_final.to_excel(writer, sheet_name='Analiz', index=False)
        if os.path.exists(history_file):
            pd.read_csv(history_file).to_excel(writer, sheet_name='Gecmis', index=False)

    print(f"\n--- İSTATİSTİKLER ---")
    print(f"Toplam Test: {len(df_now)} | Excel: {excel_name}")

if __name__ == "__main__":
    run_analysis()