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
    summary_file = "test_stats_summary.csv" # Yeni özet dosyası
    
    if not os.path.exists(log_file):
        print("Hata: sonuc.txt bulunamadı!")
        return

    current_results = []
    build_start, build_duration = 0, 0
    test_starts = {}
    test_sayisi = 0

    print("Veriler analiz ediliyor...")
    
    with open(log_file, "r", encoding="latin-1") as f:
        for line in f:
            line = line.strip()
            if "START_BUILD@" in line:
                build_start = parse_time(line.split("START_BUILD@")[1])
            elif "END_BUILD@" in line:
                build_duration = parse_time(line.split("END_BUILD@")[1]) - build_start
            elif line.startswith("DATA_START"):
                parts = line.split('@')
                if len(parts) >= 3:
                    test_starts[parts[1]] = parse_time(parts[2])
            elif line.startswith("DATA_END"):
                parts = line.split('@')
                if len(parts) >= 3:
                    name, end_time = parts[1], parse_time(parts[2])
                    duration = end_time - test_starts.get(name, end_time)
                    test_sayisi += 1
                    current_results.append({
                        "No": test_sayisi,
                        "Tarih": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
                        "Test_Adi": name,
                        "Son_Sure": round(duration, 4),
                        "Derleme_Sn": round(build_duration, 4)
                    })

    if not current_results:
        print("Hata: İşlenecek veri bulunamadı!")
        return

    df_now = pd.DataFrame(current_results)

    # 1. GEÇMİŞ VERİLERİ YÜKLE VE GÜNCELLE
    if os.path.exists(history_file) and os.path.getsize(history_file) > 0:
        df_history = pd.read_csv(history_file)
        # Yeni verileri geçmişe ekle
        df_combined = pd.concat([df_history, df_now], ignore_index=True)
    else:
        df_combined = df_now.copy()

    # 2. İSTATİSTİKSEL ÖZET HESAPLAMA (Her test adı için)
    # Kaç kere çalıştırıldı, Ortalama süre, Son çalışma süresi
    summary_data = df_combined.groupby("Test_Adi").agg(
        Calistirma_Sayisi=("Son_Sure", "count"),
        Ortalama_Sure=("Son_Sure", "mean"),
        Son_Calisma_Suresi=("Son_Sure", "last")
    ).reset_index()
    
    summary_data["Ortalama_Sure"] = summary_data["Ortalama_Sure"].round(4)

    # 3. KARŞILAŞTIRMA ANALİZİ (Son seans ile bir önceki seans)
    if os.path.exists(history_file):
        last_date = df_history["Tarih"].iloc[-1]
        df_prev = df_history[df_history["Tarih"] == last_date]
        df_final = pd.merge(df_now, df_prev[['Test_Adi', 'Son_Sure']], on='Test_Adi', how='left', suffixes=('', '_Onceki'))
        df_final['Fark'] = df_final['Son_Sure'] - df_final['Son_Sure_Onceki']
        df_final['Durum'] = df_final['Fark'].apply(lambda x: "Yavaşladı ⚠" if x > 0.005 else ("Hızlandı ✅" if x < -0.005 else "Aynı"))
    else:
        df_final = df_now.copy()
        df_final['Durum'] = "İlk Çalıştırma"

    # VERİLERİ KAYDET
    df_now.to_csv(history_file, mode='a', index=False, header=not os.path.exists(history_file))
    summary_data.to_csv(summary_file, index=False)

    # EXCEL RAPORU (3 Sekmeli)
    excel_name = f"Performans_Raporu_{datetime.datetime.now().strftime('%Y%m%d_%H%M')}.xlsx"
    with pd.ExcelWriter(excel_name, engine='openpyxl') as writer:
        df_final.to_excel(writer, sheet_name='Anlik_Analiz', index=False)
        summary_data.to_excel(writer, sheet_name='Test_Ozet_Istatistik', index=False)
        df_combined.to_excel(writer, sheet_name='Tum_Gecmis_Loglar', index=False)

    print(f"\n--- İSTATİSTİKLER ---")
    print(f"Toplam Test Sayısı    : {test_sayisi}")
    print(f"Eşsiz Test Dosyası    : {len(summary_data)}")
    print(f"Ortalama Genel Süre   : {df_now['Son_Sure'].mean():.4f} sn")
    print(f"Excel Raporu Hazır    : {excel_name}")
    print(f"İstatistik Özeti      : {summary_file}")

if __name__ == "__main__":
    run_analysis()