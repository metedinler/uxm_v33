import csv, os
root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
res_in = os.path.join(root, 'reports', 'extension_resolution.csv')
finds_in = os.path.join(root, 'reports', 'extension_case_finds.csv')
out = os.path.join(root, 'reports', 'extension_final_summary.csv')

# read resolution
res = {}
with open(res_in, newline='', encoding='utf-8') as f:
    r = csv.DictReader(f)
    for row in r:
        try:
            idv = int(row['id'])
        except:
            continue
        res[idv] = row

# aggregate finds
finds = {}
with open(finds_in, newline='', encoding='utf-8') as f:
    r = csv.DictReader(f)
    for row in r:
        try:
            idv = int(row['id'])
        except:
            continue
        finds.setdefault(idv, []).append(row['file'])

# write summary
with open(out, 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(['id','name','registry_status','meta_source','registry_source','implemented_in_runtime','files'])
    ids = sorted(set(list(res.keys())+list(finds.keys())))
    for idv in ids:
        r = res.get(idv, {})
        name = r.get('name','')
        reg_status = r.get('registry_status','')
        meta_source = r.get('meta_source','')
        reg_src = r.get('registry_source','')
        files = finds.get(idv, [])
        impl = 'yes' if files else 'no'
        w.writerow([idv,name,reg_status,meta_source,reg_src,impl,';'.join(sorted(set(files)))])
print('Wrote', out)
