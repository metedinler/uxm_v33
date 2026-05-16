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

extension_ids_set = set(extension_ids)
results = []
seen = set()
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
                    text = f.read()
            except Exception:
                continue
            lines = text.splitlines()
            # detect remap patterns like: If localMeta >= 360 And localMeta <= 369 Then localMeta += 20
            remap_reverse = {}
            for mremap in re.finditer(r"If\s+localMeta\s*>=\s*(\d+)\s+And\s+localMeta\s*<=\s*(\d+)\s+Then\s+localMeta\s*(?:\+=|=\s*localMeta\s*\+\s*)\s*(\d+)", text, flags=re.I):
                a = int(mremap.group(1)); b = int(mremap.group(2)); c = int(mremap.group(3))
                if a <= b:
                    for x in range(a, b+1):
                        remap_reverse.setdefault(x + c, []).append(x)
                else:
                    for x in range(b, a+1):
                        remap_reverse.setdefault(x + c, []).append(x)
            for i,l in enumerate(lines, start=1):
                # detect 'Case' blocks and extract numbers and ranges after it
                mcase = re.search(r"\bCase\b", l, flags=re.I)
                found_ids = set()
                if mcase:
                    sub = l[mcase.end():]
                    # expand ranges like '320 To 325'
                    for rm in re.finditer(r"(\d+)\s*[Tt][Oo]\s*(\d+)", sub):
                        a = int(rm.group(1)); b = int(rm.group(2))
                        if a <= b:
                            found_ids.update(range(a, b+1))
                        else:
                            found_ids.update(range(b, a+1))
                    # capture individual numbers (including comma-separated lists)
                    for nm in re.finditer(r"\b(\d+)\b", sub):
                        found_ids.add(int(nm.group(1)))

                # if this line contains remapped case ids, also report original ids
                remapped_hits = set(found_ids) & set(remap_reverse.keys())
                for rh in remapped_hits:
                    for original_id in remap_reverse.get(rh, []):
                        keyr = (original_id, rel, i)
                        if keyr not in seen:
                            results.append((original_id, rel, i, l.strip()+"  # remapped from %d"%rh))
                            seen.add(keyr)

                # also fall back to exact 'Case <id>' search for compatibility
                for idv in extension_ids:
                    key = (idv, rel, i)
                    if key in seen:
                        continue
                    if idv in found_ids or re.search(rf"\bCase\s+{idv}\b", l, flags=re.I):
                        results.append((idv, rel, i, l.strip()))
                        seen.add(key)

# write output
with open(out, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['id','file','line','snippet'])
    for r in sorted(results):
        w.writerow(r)
print('Wrote', out)
