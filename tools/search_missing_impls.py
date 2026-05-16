import os, csv, zipfile, re
root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sum_path = os.path.join(root, 'reports', 'extension_final_summary.csv')
out_path = os.path.join(root, 'reports', 'missing_impl_search.csv')

missing = []
with open(sum_path, encoding='utf-8') as f:
    r = csv.DictReader(f)
    for row in r:
        if row.get('implemented_in_runtime','').strip().lower()=='no':
            missing.append({'id':row['id'],'name':row['name']})

# normalize search tokens
def tokens(name):
    t = name
    t2 = name.replace('_',' ')
    return set([name, name.lower(), t2.lower(), name.replace('_','').lower()])

# search all files and zip archives
matches = []
for dirpath, dirnames, filenames in os.walk(root):
    for fn in filenames:
        path = os.path.join(dirpath, fn)
        rel = os.path.relpath(path, root).replace('\\','/')
        # skip our output files
        if rel.startswith('reports/') and os.path.basename(rel).startswith('missing_impl_search'):
            continue
        # search inside zip
        if fn.lower().endswith('.zip'):
            try:
                with zipfile.ZipFile(path, 'r') as z:
                    for zi in z.namelist():
                        if zi.lower().endswith(('.bas','.inc','.txt','.md','.csv')):
                            try:
                                data = z.read(zi).decode('utf-8', errors='ignore')
                            except Exception:
                                continue
                            for m in missing:
                                for tok in tokens(m['name']):
                                    if tok in data.lower():
                                        matches.append((m['id'], m['name'], rel+':'+zi, 'zip', data.count('\n')))
                                        break
            except Exception:
                continue
            continue
        # normal text files
        if fn.lower().endswith(('.bas','.inc','.txt','.md','.csv')):
            try:
                with open(path, encoding='utf-8', errors='ignore') as f:
                    txt = f.read().lower()
            except Exception:
                continue
            for m in missing:
                for tok in tokens(m['name']):
                    if tok in txt:
                        matches.append((m['id'], m['name'], rel, 'file', txt.count('\n')))
                        break

# write CSV
with open(out_path, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['id','name','location','type','lines'])
    for r in sorted(matches, key=lambda x:(int(x[0]), x[2])):
        w.writerow(r)
print('Wrote', out_path)
