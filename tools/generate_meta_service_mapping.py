import os, json, csv, sys
root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
json_path = os.path.join(root, 'config','uxm','meta_services.json')
out_dir = os.path.join(root, 'reports')
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, 'meta_service_mapping.csv')
with open(json_path, 'r', encoding='utf-8') as f:
    j = json.load(f)
services = j.get('services', [])
with open(out_path, 'w', newline='', encoding='utf-8') as csvf:
    writer = csv.writer(csvf)
    writer.writerow(['id','name','handler','enabled','status','source','notes','frame'])
    for s in services:
        writer.writerow([s.get('id'), s.get('name'), s.get('handler'), s.get('enabled'), s.get('status'), s.get('source'), s.get('notes',''), s.get('frame','')])
print(out_path)
