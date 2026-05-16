#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""UXM log süre analizörü: neden 4 sn/test görüldüğünü raporlar."""
import argparse, re, csv, statistics
from pathlib import Path
LINE_RE=re.compile(r"\[(\d+)/(\d+)\]\s+(\S+)\s+(.+?)\s+\((\d+(?:\.\d+)?)\s+sn\)")
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('logfile'); ap.add_argument('--out',default='uxm_timing_report.csv')
    args=ap.parse_args(); p=Path(args.logfile); rows=[]
    text=p.read_text(encoding='utf-8',errors='replace')
    for line in text.splitlines():
        m=LINE_RE.search(line)
        if m:
            rows.append({'index':int(m.group(1)),'total':int(m.group(2)),'status':m.group(3),'test':m.group(4).strip(),'seconds':float(m.group(5))})
    out=Path(args.out)
    with out.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['index','total','status','test','seconds']); w.writeheader(); w.writerows(rows)
    vals=[r['seconds'] for r in rows]
    if vals:
        slow=sorted(rows,key=lambda r:r['seconds'],reverse=True)[:20]
        print('Test sayisi:',len(rows))
        print('Ortalama sn/test:',round(statistics.mean(vals),4))
        print('Median sn/test:',round(statistics.median(vals),4))
        print('Toplam sn:',round(sum(vals),2))
        print('En yavas 20:')
        for r in slow: print(f"  {r['seconds']:.2f} sn  {r['status']}  {r['test']}")
    print('CSV:',out)
if __name__=='__main__': main()
