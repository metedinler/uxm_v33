import zipfile
from pathlib import Path
import sys
root = Path('.')
patterns = ['Case 450','CPLX_PRINT','CPLX_PRINT_RESERVED','Case 398','Case 399','NUM_ODE_INFO','NUM_PDE_RESERVED','NUM_ODE','NUM_PDE']
out_lines = []
for z in root.rglob('*.zip'):
    try:
        with zipfile.ZipFile(z, 'r') as zf:
            for name in zf.namelist():
                # search in any text-based file inside the zip
                if not (name.lower().endswith('.bas') or name.lower().endswith('.txt') or name.lower().endswith('.md') or name.lower().endswith('.csv') or name.lower().endswith('.json')):
                    continue
                try:
                    data = zf.read(name)
                    try:
                        s = data.decode('utf-8')
                    except:
                        try:
                            s = data.decode('latin-1')
                        except:
                            continue
                    for pat in patterns:
                        if pat.lower() in s.lower():
                            # find first matching line
                            for i,l in enumerate(s.splitlines(),1):
                                if pat.lower() in l.lower():
                                    snippet = l.strip()
                                    out_lines.append(f'{z}|{name}|{pat}|{i}|{snippet}')
                                    break
                except Exception as e:
                    out_lines.append(f'{z}|{name}|READ_ERROR|0|{e}')
    except Exception as e:
        out_lines.append(f'{z}|ZIP_OPEN_ERROR|0|{e}')
# write report
outp = Path('reports/zip_impl_findings.csv')
outp.parent.mkdir(parents=True, exist_ok=True)
with outp.open('w', encoding='utf-8') as f:
    f.write('zip,internal_path,pattern,line,snippet\n')
    for l in out_lines:
        parts = l.split('|',4)
        f.write(','.join('"'+p.replace('"','""')+'"' for p in parts) + '\n')
print(f'Found {len(out_lines)} matches, written to {outp}')
for l in out_lines[:200]:
    print(l)
