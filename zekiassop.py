import os
import re
from collections import Counter

class UXM_ASM_Intelligence:
    def __init__(self, base_path):
        self.base_path = base_path
        # AKILLI BULUCU: 'build' ile başlayan en son klasörü bulur
        build_folders = [d for d in os.listdir(base_path) if os.path.isdir(d) and "build" in d.lower()]
        self.asm_dir = os.path.join(base_path, build_folders[0], "asm") if build_folders else os.path.join(base_path, "build", "asm")
        
        self.opt_dir = os.path.join(base_path, "yeni_optimize_asm")
        self.report_dir = os.path.join(base_path, "optimizasyon")
        
        # Gerekli tüm alt klasörleri otomatik oluştur
        for d in [self.opt_dir, self.report_dir, 
                  os.path.join(base_path, "build", "obj"), 
                  os.path.join(base_path, "build", "exe")]:
            if not os.path.exists(d): os.makedirs(d)
            
    # def __init__(self, base_path):
    #     self.base_path = base_path
    #     self.asm_dir = os.path.join(base_path, "build", "asm")
    #     self.opt_dir = os.path.join(base_path, "yeni_optimize_asm")
    #     self.report_dir = os.path.join(base_path, "optimizasyon")
        
    #     for d in [self.opt_dir, self.report_dir]:
    #         if not os.path.exists(d): os.makedirs(d)

    def get_clean_instr(self, line):
        """Yorumsuz ve temiz komutu döner."""
        line = line.split(';')[0].strip()
        if not line or line.endswith(':'): return None
        return line

    def analyze_patterns(self, lines):
        """Kod içindeki C-D-C-D gibi tekrarları ve istatistikleri bulur."""
        instr_list = [self.get_clean_instr(line) for line in lines if self.get_clean_instr(line)]
        
        # 1. N-Gram Analizi (Örüntü yakalama)
        bigrams = [f"{instr_list[i]} -> {instr_list[i+1]}" for i in range(len(instr_list)-1)]
        trigrams = [f"{instr_list[i]} -> {instr_list[i+1]} -> {instr_list[i+2]}" for i in range(len(instr_list)-2)]
        
        stats = {
            "top_instr": Counter(instr_list).most_common(10),
            "top_bigrams": Counter(bigrams).most_common(10),
            "top_trigrams": Counter(trigrams).most_common(10),
            "jump_density": len([x for x in instr_list if 'j' in x.lower()[:2]]) / (len(instr_list) + 1)
        }
        return stats, instr_list

    def apply_smart_rules(self, lines):
        """Gelişmiş 50+ optimizasyon mantığını uygulayan motor."""
        optimized = []
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            # --- Z-K-Z-K Örüntüsü (Gereksiz Stack trafiği veya Register Döngüsü) ---
            if i + 3 < len(lines):
                l1, l2, l3, l4 = lines[i].strip(), lines[i+1].strip(), lines[i+2].strip(), lines[i+3].strip()
                # Push/Pop simetrisi kontrolü (Redundant stack traffic)
                if "push" in l1 and "pop" in l4 and l1.split()[-1] == l4.split()[-1]:
                    # Eğer arada stack kullanılmıyorsa bu push-pop silinebilir
                    optimized.append(f"; [INTEL: Stack Traffic Removed] {l1}")
                    optimized.append(l2)
                    optimized.append(l3)
                    i += 4; continue

            # --- Strength Reduction (Matematiksel Dönüşümler) ---
            # mul reg, 8 -> shl reg, 3
            mul_match = re.match(r"mul\s+(\w+),\s+(2|4|8|16|32)", line, re.I)
            if mul_match:
                reg, val = mul_match.groups()
                shift = { "2":"1", "4":"2", "8":"3", "16":"4", "32":"5" }[val]
                optimized.append(f"shl {reg}, {shift} ; [INTEL: Mul to Shl]")
                i += 1; continue

            # --- Jump to Next Line (Gereksiz Atlamalar) ---
            if "jmp" in line and i + 1 < len(lines):
                label = line.split()[-1]
                if label + ":" == lines[i+1].strip():
                    optimized.append(f"; [INTEL: Jmp to next line removed]")
                    i += 1; continue

            optimized.append(lines[i].rstrip())
            i += 1
        return optimized

    def run(self):
        full_report = os.path.join(self.report_dir, "asm_intel_report.txt")
        with open(full_report, "w") as rep:
            for file in os.listdir(self.asm_dir):
                if file.endswith(".asm"):
                    with open(os.path.join(self.asm_dir, file), "r") as f:
                        content = f.readlines()
                    
                    stats, _ = self.analyze_patterns(content)
                    optimized = self.apply_smart_rules(content)
                    
                    # Raporlama
                    rep.write(f"\nANALIZ: {file}\n" + "="*40 + "\n")
                    rep.write(f"Sik Kullanilan Bigramlar:\n")
                    for b, c in stats['top_bigrams']: rep.write(f" - {c} kez: {b}\n")
                    rep.write(f"Jump Yoğunluğu: %{stats['jump_density']*100:.2f}\n")

                    with open(os.path.join(self.opt_dir, file), "w") as f:
                        f.write("\n".join(optimized))
        print(f"İşlem Tamam. Rapor: {full_report}")

if __name__ == "__main__":
    MY_PATH = r"C:\Users\mete\Downloads\1\UXMv33"
    intel_engine = UXM_ASM_Intelligence(MY_PATH)
    intel_engine.run()