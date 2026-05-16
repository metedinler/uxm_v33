import argparse, subprocess, sys, pathlib
p=argparse.ArgumentParser(description="UXM Türkçe koşucu sarmalayıcı")
p.add_argument("--kok", default=".")
p.add_argument("--test-klasoru", required=True)
p.add_argument("--cikti", default="sonuclar")
p.add_argument("args", nargs="*")
a=p.parse_args()
root=pathlib.Path(a.kok)
for cand in [root/'araclar'/'uxm_kosucu_tr.py', root/'tools'/'UXM_EXPECT_RUNNER_V6.py', root/'tools'/'UXM_EXPECT_RUNNER_V5.py', root/'tools'/'UXM_EXPECT_RUNNER_V4.py']:
    if cand.exists() and cand.resolve()!=pathlib.Path(__file__).resolve():
        cmd=[sys.executable,str(cand),'--root',str(root),'--test-dir',a.test_klasoru,'--out-root',a.cikti]+a.args
        raise SystemExit(subprocess.call(cmd))
print('Uygun UXM runner bulunamadı.', file=sys.stderr)
sys.exit(2)
