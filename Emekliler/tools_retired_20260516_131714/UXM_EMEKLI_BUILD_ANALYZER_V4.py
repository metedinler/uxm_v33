#!/usr/bin/env python3
import argparse, csv, datetime, re, json
from pathlib import Path
from collections import Counter
PATTERNS=['Duplicated definition','Argument count mismatch','ld.exe','data bellek ust siniri','HATA:','error 1:','error 4:','UYUSMAZ','BUILD_FAIL']
def main():
 ap=argparse.ArgumentParser(); ap.add_argument('--root',default='.'); args=ap.parse_args()
 root=Path(args.root).resolve(); em=root/'Emekliler'; ts=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
 out=root/'y_sonuclar'/'emekli_dersleri_v4'/ts; out.mkdir(parents=True,exist_ok=True)
 rows=[]; cnt=Counter()
 for p in em.rglob('*') if em.exists() else []:
  if p.is_file() and p.suffix.lower() in {'.log','.txt','.csv','.md'}:
   try: s=p.read_text(encoding='utf-8',errors='replace')[:200000]
   except Exception: continue
   hits=[pat for pat in PATTERNS if pat.lower() in s.lower()]
   if hits:
    for h in hits: cnt[h]+=1
    rows.append({'file':str(p.relative_to(root)),'hits':'|'.join(hits),'sample':s[:180].replace('\n','\\n')})
 with open(out/'emekli_issue_inventory_v4.csv','w',encoding='utf-8-sig',newline='') as f:
  w=csv.DictWriter(f,fieldnames=['file','hits','sample']); w.writeheader(); w.writerows(rows)
 with open(out/'emekli_issue_summary_v4.csv','w',encoding='utf-8-sig',newline='') as f:
  w=csv.writer(f); w.writerow(['pattern','count']); [w.writerow([k,v]) for k,v in cnt.most_common()]
 (out/'SUMMARY.json').write_text(json.dumps({'files_with_hits':len(rows),'patterns':cnt},default=dict,indent=2,ensure_ascii=False),encoding='utf-8')
 print('[EMEKLI] out=',out,' files_with_hits=',len(rows))
if __name__=='__main__': main()
