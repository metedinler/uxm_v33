#!/usr/bin/env python3
"""
Copy canonical service files from strongestSRC to UXMv33, back up originals, and commit locally.
"""
import os, shutil, subprocess, sys, time

def find_src():
    gwd = os.getcwd()
    candidates = [
        os.path.join(gwd, '..', 'strongestSRC', 'strongestSRC', 'src', 'runtime', 'services'),
        os.path.join(gwd, '..', '..', 'strongestSRC', 'strongestSRC', 'src', 'runtime', 'services'),
        os.path.join('C:\\', 'Users', 'mete', 'Downloads', 'strongestSRC', 'strongestSRC', 'src', 'runtime', 'services'),
        os.path.join(gwd, 'tools', 'tmp_unzip', 'strongestSRC', 'src', 'runtime', 'services'),
    ]
    for p in candidates:
        p2 = os.path.normpath(p)
        if os.path.isdir(p2):
            return p2
    # Fallback: search parent folders for strongestSRC
    for root in [gwd, os.path.dirname(gwd)]:
        try:
            for name in os.listdir(root):
                d = os.path.join(root, name)
                if os.path.isdir(d) and name.lower().startswith('strongestsrc'):
                    maybe = os.path.join(d, 'strongestSRC', 'src', 'runtime', 'services')
                    if os.path.isdir(maybe):
                        return maybe
        except Exception:
            pass
    return None


def main():
    src = find_src()
    if not src:
        print('ERROR: canonical source directory not found', file=sys.stderr)
        sys.exit(2)
    dest = os.path.join(os.getcwd(), 'uxm', 'core', 'runtime', 'services')
    if not os.path.isdir(dest):
        print('ERROR: target services directory not found:', dest, file=sys.stderr)
        sys.exit(3)
    copied = []
    backed = []
    for fname in os.listdir(src):
        if not fname.lower().endswith('.bas'):
            continue
        sfile = os.path.join(src, fname)
        dfile = os.path.join(dest, fname)
        # backup if exists
        if os.path.exists(dfile):
            bak = dfile + '.bak'
            try:
                if os.path.exists(bak):
                    bak = dfile + '.bak_' + time.strftime('%Y%m%d%H%M%S')
                shutil.move(dfile, bak)
                backed.append(bak)
                print('BACKUP', dfile, '->', bak)
            except Exception as e:
                print('ERROR: backup failed for', dfile, '->', e, file=sys.stderr)
                sys.exit(4)
        try:
            shutil.copy2(sfile, dfile)
            copied.append(dfile)
            print('COPIED', sfile, '->', dfile)
        except Exception as e:
            print('ERROR: copy failed for', sfile, '->', e, file=sys.stderr)
            sys.exit(5)
    if copied:
        try:
            subprocess.run(['git', 'add'] + copied, check=False)
            msg = 'TR: Sync canonical services from strongestSRC: ' + ', '.join(os.path.basename(x) for x in copied)
            subprocess.run(['git', 'commit', '-m', msg], check=False)
            rev = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], check=False, capture_output=True, text=True)
            print('GIT_COMMIT', rev.stdout.strip())
        except Exception as e:
            print('WARN: git commit failed:', e, file=sys.stderr)
    else:
        print('No files copied.')
    print('DONE')

if __name__ == '__main__':
    main()
