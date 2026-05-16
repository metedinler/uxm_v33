import os
import re

import os
import re

class UXM_Final_Optimizer:
    def __init__(self, base_path):
        self.base_path = base_path
        self.opt_dir = os.path.join(base_path, "optimizasyon")
        self.intel_report = os.path.join(self.opt_dir, "asm_intel_report.txt")
        self.service_report = os.path.join(self.opt_dir, "uxm_servis_raporu.txt")
        self.output_file = os.path.join(self.opt_dir, "sihirli_asm_onerileri.txt")

    def analyze_and_suggest(self):
        if not os.path.exists(self.intel_report):
            return "Hata: Önce Intelligence raporu çalışmalı!"

        with open(self.intel_report, "r") as f: intel_data = f.read()
        
        suggestions = []
        suggestions.append("=== UXM STAGE-11 ASM OPTIMIZASYON STRATEJI KITABI ===")
        suggestions.append("Durum: Orijinal kodlar korunarak öneriler üretilmiştir.\n")

        # --- KRITIK ANALIZ 1: Bayrak (Flags) Trafiği ---
        if "mov dx, word [ux_flags]" in intel_data:
            suggestions.append("[KRITIK ÖNERİ #1] Bayrak İşlemlerini Register'a Taşı")
            suggestions.append("Tespit: 'ux_flags' bellek erişimi döngü içinde çok fazla.")
            suggestions.append("Çözüm: Döngü başında 'mov r15w, word [ux_flags]' yapın,")
            suggestions.append("      işlemleri r15 üzerinde bitirip döngü sonunda bir kez yazın.")
            suggestions.append("Tahmini Kazanç: %15 CPU hızı.\n")

        # --- KRITIK ANALIZ 2: Sınır Kontrolü (Boundary) ---
        if "cmp r10, TAPE_CELLS" in intel_data:
            suggestions.append("[KRITIK ÖNERİ #2] Sınır Kontrolünü (Hoisting) Dışarı Çıkar")
            suggestions.append("Tespit: Her hücre erişiminde 'jae __ux_err_ptr' kontrolü yapılıyor.")
            suggestions.append("Çözüm: Tensor operasyonlarında toplam boyutu döngü öncesi tek seferde")
            suggestions.append("      kontrol edin. İçerideki 'cmp/jae' bloklarını temizleyin.")
            suggestions.append("Tahmini Kazanç: %20 döngü performansı.\n")

        # --- KRITIK ANALIZ 3: Redundant Stack (Push/Pop) ---
        if "push rax" in intel_data and "pop rax" in intel_data:
            suggestions.append("[KRITIK ÖNERİ #3] Register Gölgeleme (Shadowing)")
            suggestions.append("Tespit: 'push rax' ve 'pop rax' ikilisi gereksiz yere stack kullanıyor.")
            suggestions.append("Çözüm: r8-r11 arasındaki boş registerları 'geçici depo' olarak kullanın.")
            suggestions.append("Tahmini Kazanç: Bellek gecikmesinde azalma.\n")

        # --- Örüntü İstatistiğine Dayalı "Sihirli" Değişim Tablosu ---
        suggestions.append("=== OTOMATIK DEGISIM REHBERI (SEARCH & REPLACE) ===")
        patterns = {
            "mov rax, 0": "xor rax, rax",
            "add rax, 1": "inc rax",
            "sub rax, 1": "dec rax",
            "mul (.*), 8": "shl \\1, 3",
            "div (.*), 4": "shr \\1, 2"
        }
        
        for old, new in patterns.items():
            suggestions.append(f"Bul: {old:<15} -> Değiştir: {new}")

        with open(self.output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(suggestions))
        
        return f"Sihirli öneriler hazırlandı: {self.output_file}"



class UXM_Heavy_Optimizer:
    def __init__(self, base_path):
        self.base_path = base_path
        self.opt_dir = os.path.join(base_path, "optimizasyon")
        self.output_file = os.path.join(self.opt_dir, "strateji_kitabi_v2.txt")
        
        # --- KURALLAR BANKASI (Burayı her prompt ile dolduracağız) ---
        self.rules = []

    def add_rule(self, title, detect, solve, gain):
        self.rules.append({
            "title": title,
            "detect": detect,
            "solve": solve,
            "gain": gain
        })

    def build_report(self):
        content = ["=== UXM STAGE-11 AGIR SIKLET OPTIMIZASYON MOTORU ==="]
        content.append(f"Kural Sayısı: {len(self.rules)}\n")
        
        for idx, rule in enumerate(self.rules, 1):
            content.append(f"[{idx}] {rule['title']}")
            content.append(f"Analiz: {rule['detect']}")
            content.append(f"Kod Onarımı: {rule['solve']}")
            content.append(f"Verim: {rule['gain']}\n" + "-"*30)

        with open(self.output_file, "w", encoding="utf-8") as f:
            f.write("\n".join(content))
        return f"Rapor {self.output_file} konumuna yazıldı."

# --- KURULUM ---


if __name__ == "__main__":
    MY_PATH = r"C:\Users\mete\Downloads\1\UXMv33"
    final_boss = UXM_Final_Optimizer(MY_PATH)
    print(final_boss.analyze_and_suggest())
    engine = UXM_Heavy_Optimizer(MY_PATH)
    print(engine.build_report())
    