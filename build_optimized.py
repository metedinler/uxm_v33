import os
import subprocess
import time

def run_command(cmd):
    start = time.time()
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    end = time.time()
    return end - start, result.returncode, result.stdout, result.stderr

def build_and_monitor():
    base_path = os.getcwd()
    opt_asm_dir = os.path.join(base_path, "yeni_optimize_asm")
    fbc = r"C:\Users\mete\Downloads\BasicOyunSource\uXBasic_repo\tools\FreeBASIC-1.10.1-win64\fbc.exe"
    nasm = "nasm"
    
    print(f"=== UXM OPTIMIZE DERLEME VE IZLEME SISTEMI ===")
    
    if not os.path.exists(opt_asm_dir):
        print("Hata: yeni_optimize_asm klasoru bulunamadi!")
        return

    for file in os.listdir(opt_asm_dir):
        if file.endswith(".asm"):
            name = file.replace(".asm", "")
            asm_path = os.path.join(opt_asm_dir, file)
            obj_path = os.path.join(base_path, "build", "obj", f"{name}.o")
            exe_path = os.path.join(base_path, "build", "exe", f"{name}_opt.exe")
            
            print(f"\n[ISLENIYOR]: {name}")
            
            # 1. NASM Aşaması
            cmd_nasm = f"{nasm} -f win64 {asm_path} -o {obj_path}"
            t_nasm, code_nasm, _, err_nasm = run_command(cmd_nasm)
            if code_nasm == 0:
                print(f"  > NASM Basarili ({t_nasm:.2f} sn)")
            else:
                print(f"  > NASM HATASI: {err_nasm}")
                continue

            # 2. Link Aşaması (FreeBASIC Runtime)
            runtime = os.path.join(base_path, "uxm", "core", "runtime", "uxm31_runtime_fb_full.bas")
            cmd_link = f"{fbc} {runtime} {obj_path} -x {exe_path}"
            t_link, code_link, _, err_link = run_command(cmd_link)
            
            if code_link == 0:
                print(f"  > LINK Basarili ({t_link:.2f} sn)")
                # 3. Calistirma ve Performans Olcumu
                t_exec, _, out_exec, _ = run_command(exe_path)
                print(f"  > CALISMA SURESI: {t_exec:.4f} sn")
                print(f"  > CIKTI: {out_exec.strip()}")
            else:
                print(f"  > LINK HATASI: {err_link}")

if __name__ == "__main__":
    build_and_monitor()