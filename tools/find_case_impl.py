import csv, os, re
root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
report_in = os.path.join(root, 'reports', 'extension_resolution.csv')
services_dirs = [os.path.join(root,'uxm'), os.path.join(root,'onceki_src'), os.path.join(root,'guncel_src')]
out = os.path.join(root, 'reports', 'extension_case_finds.csv')

extension_ids = []
with open(report_in, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        try:
            idv = int(row['id'])
        except:
            continue
        extension_ids.append(idv)

results = []
for base in services_dirs:
    if not os.path.exists(base):
        continue
    for dirpath, dirnames, filenames in os.walk(base):
        for fn in filenames:
            if not fn.lower().endswith(('.bas','.inc','.txt','.md')):
                continue
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, root).replace('\\','/')
            try:
                with open(path, encoding='utf-8', errors='ignore') as f:
                    lines = f.readlines()
            except Exception:
                continue
            for i,l in enumerate(lines, start=1):
                for idv in extension_ids:
                    # look for "Case <id>" or "Case <id> '"
                    if re.search(rf"\bCase\s+{idv}\b", l):
                        results.append((idv, rel, i, l.strip()))

# write output
with open(out, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['id','file','line','snippet'])
    for r in sorted(results):
        w.writerow(r)
print('Wrote', out)
