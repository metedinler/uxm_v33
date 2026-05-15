import csv, os
root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
reg_path = os.path.join(root, 'config', 'uxm', 'service_registry_merged.csv')
meta_map_path = os.path.join(root, 'reports', 'meta_service_mapping.csv')
out_path = os.path.join(root, 'reports', 'extension_resolution.csv')

# read registry
registry = {}
with open(reg_path, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        try:
            idv = int(row['id'])
        except:
            continue
        registry[idv] = row

# read meta mapping
meta = {}
with open(meta_map_path, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        try:
            idv = int(row['id'])
        except:
            continue
        meta[idv] = row

# helper to find file
def find_file(fname):
    # search common locations under uxm
    search_paths = [os.path.join(root,'uxm'), os.path.join(root,'uxm','core'), os.path.join(root,'uxm','core','runtime'), os.path.join(root,'uxm','core','runtime','services')]
    for base in search_paths:
        p = os.path.join(base, fname)
        if os.path.exists(p):
            return os.path.relpath(p, root).replace('\\','/')
    # fallback search (walk)
    for dirpath,dirnames,filenames in os.walk(os.path.join(root,'uxm')):
        if fname in filenames:
            return os.path.relpath(os.path.join(dirpath,fname), root).replace('\\','/')
    return ''

# produce report
with open(out_path, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['id','name','registry_status','registry_source','meta_status','meta_source','implemented','implementation_path','notes'])
    for idv, row in sorted(registry.items()):
        if 'extension_requires_meta_id_range_patch' in row.get('status',''):
            m = meta.get(idv)
            meta_status = m.get('status') if m else ''
            meta_source = m.get('source') if m else ''
            impl_path = find_file(meta_source) if meta_source else ''
            implemented = 'yes' if impl_path else 'no'
            writer.writerow([idv, m.get('name') if m else row.get('name'), row.get('status'), row.get('source'), meta_status, meta_source, implemented, impl_path, row.get('notes')])
print('Wrote', out_path)
