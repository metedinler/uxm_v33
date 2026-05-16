import os, re, csv
root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
manifests_dir = os.path.join(root, 'manifests')
manifest_files = [f for f in os.listdir(manifests_dir) if f.lower().endswith('.csv')]
manifest_ids = set()
for mf in manifest_files:
    path = os.path.join(manifests_dir, mf)
    with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
        for line in fh:
            line=line.strip()
            if not line: continue
            if line.lower().startswith(('id,','test_path','service','unique_test_path')): continue
            first = line.split(',')[0].strip()
            m = re.search(r'@?(\d+)', first)
            if m:
                manifest_ids.add(int(m.group(1)))

# read extension final summary
ext_file = os.path.join(root, 'reports', 'extension_final_summary.csv')
ext_ids = set()
if os.path.exists(ext_file):
    with open(ext_file, 'r', encoding='utf-8', errors='ignore') as fh:
        next(fh)
        for line in fh:
            line=line.strip()
            if not line: continue
            parts=line.split(',')
            try:
                ext_ids.add(int(parts[0]))
            except:
                pass

missing = sorted(manifest_ids - ext_ids)
print('Manifest IDs count:', len(manifest_ids))
print('Extension implemented IDs count:', len(ext_ids))
print('Missing count:', len(missing))

search_roots = [r'c:\\Users\\mete\\Downloads\\UXMC', r'c:\\Users\\mete\\Downloads\\UXM XMX', r'c:\\Users\\mete\\Downloads\\strongestSRC']
results = {}
for mid in missing:
    pat = re.compile(r'\\bCase\\s+%d\\b' % mid)
    found = []
    for root_search in search_roots:
        if not os.path.exists(root_search):
            continue
        for dirpath, dirnames, filenames in os.walk(root_search):
            for fn in filenames:
                if not fn.lower().endswith(('.bas','.inc','.md','.txt','.uxm')):
                    continue
                fp = os.path.join(dirpath, fn)
                try:
                    with open(fp, 'r', encoding='utf-8', errors='ignore') as f:
                        for i,l in enumerate(f,1):
                            if pat.search(l):
                                rel = os.path.relpath(fp, root_search).replace('\\\\','/')
                                found.append(f"{root_search}/{rel}:{i}")
                                break
                except Exception:
                    continue
    results[mid]=found

out_dir = os.path.join(root, 'reports')
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, 'missing_manifest_impls_limited.csv')
with open(out_path, 'w', newline='', encoding='utf-8') as outf:
    w=csv.writer(outf)
    w.writerow(['id','found_paths'])
    for mid in missing:
        w.writerow([mid, ';'.join(results.get(mid, []))])

print('Wrote', out_path)
