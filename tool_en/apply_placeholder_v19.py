
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""UXM V19 gerçek kod uygulayıcı.
Bu araç dosyaları kopyalar ve runtime include/dispatch bağlantısını güvenli biçimde ekler.
"""
from pathlib import Path
import argparse, shutil, re, datetime, sys

MARK = "UXM_V19_STATS_NUMERIC"

def read(p): return p.read_text(encoding="utf-8", errors="replace")
def write(p, s): p.write_text(s, encoding="utf-8")

def backup(path: Path):
    if path.exists():
        bdir = path.parents[3] / "onceki_src" / "v19_otomatik_yedek"
        bdir.mkdir(parents=True, exist_ok=True)
        stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        dst = bdir / (path.name + "." + stamp + ".bak")
        shutil.copy2(path, dst)
        return dst
    return None

def patch_runtime_full(root: Path):
    p = root / "uxm" / "core" / "runtime" / "uxm31_runtime_fb_full.bas"
    if not p.exists():
        raise FileNotFoundError(p)
    s = read(p)
    changed = False
    decl = "Declare Sub MetaStatsNumericV19(ByVal metaId As ULongInt)"
    if decl not in s:
        target = "Declare Sub MetaMatrix(ByVal metaId As ULongInt)"
        if target in s:
            s = s.replace(target, target + "\n" + decl + " ' " + MARK, 1)
            changed = True
        else:
            s = decl + " ' " + MARK + "\n" + s
            changed = True
    inc = '#Include Once "services/runtime_stats_numeric_v19.bas"'
    if inc not in s:
        target = '#Include Once "services/runtime_math_services.bas"'
        if target in s:
            s = s.replace(target, target + "\n" + inc + " ' " + MARK, 1)
            changed = True
        else:
            s += "\n" + inc + " ' " + MARK + "\n"
            changed = True
    if changed:
        backup(p); write(p, s)
    return changed

def patch_dispatch(root: Path):
    p = root / "uxm" / "core" / "runtime" / "runtime_meta_dispatch.bas"
    if not p.exists():
        raise FileNotFoundError(p)
    s = read(p)
    route = "ElseIf ((metaId>=274 And metaId<=280) Or (metaId>=283 And metaId<=289)) Then\nMetaStatsNumericV19 metaId ' " + MARK
    if "MetaStatsNumericV19 metaId" in s:
        return False
    needle = "Else\nSetStatus STATUS_INVALID_META"
    if needle not in s:
        raise RuntimeError("runtime_meta_dispatch.bas icinde ana Else/invalid-meta noktasi bulunamadi")
    s = s.replace(needle, route + "\n" + needle, 1)
    backup(p); write(p, s)
    return True

def copy_service(src_root: Path, dst_root: Path):
    src = src_root / "uxm" / "core" / "runtime" / "services" / "runtime_stats_numeric_v19.bas"
    dst = dst_root / "uxm" / "core" / "runtime" / "services" / "runtime_stats_numeric_v19.bas"
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists(): backup(dst)
    shutil.copy2(src, dst)

def main():
    ap = argparse.ArgumentParser(description="UXM V19 placeholder real-code applier")
    ap.add_argument("--root", default=".", help="UXMv33 proje kökü")
    ap.add_argument("--dry-run", action="store_true", help="Show actions without writing")
    args = ap.parse_args()
    dst_root = Path(args.root).resolve()
    src_root = Path(__file__).resolve().parents[1]
    print(f"[V19] hedef={dst_root}")
    if args.dry_run:
        print("[V19] dry-run: servis dosyası kopyalanacak, runtime include ve dispatch route eklenecek.")
        return 0
    copy_service(src_root, dst_root)
    ch1 = patch_runtime_full(dst_root)
    ch2 = patch_dispatch(dst_root)
    print(f"[V19] servis kopyalandı; runtime_full_degisti={ch1}; dispatch_degisti={ch2}")
    print("[V19] Sonraki adım: derleyici_derle.bat ve stage24_placeholder_test.bat -k")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
