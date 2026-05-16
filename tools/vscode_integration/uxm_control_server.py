#!/usr/bin/env python3
"""
Minimal UXM control server for VSCode integration.

Endpoints (HTTP):
- GET /ping -> {"status":"ok"}
- GET /addresses -> returns uxm_addresses.json
- POST /alias -> add alias JSON {name,address,desc}
- POST /compile -> runs build_native.bat and returns output
- POST /run -> runs run_all_expected_tests_no_build.bat and returns output
- GET /trace?file=path -> returns last 200 lines of path (if readable)

This is intentionally lightweight and uses only the stdlib so it can be used without extra installs.
"""
import http.server
import json
import os
import subprocess
import urllib.parse
from http import HTTPStatus

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ADDR_FILE = os.path.join(os.path.dirname(__file__), 'uxm_addresses.json')


def run_command(cmd, timeout=300):
    try:
        completed = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=ROOT, timeout=timeout)
        return {'returncode': completed.returncode, 'stdout': completed.stdout, 'stderr': completed.stderr}
    except Exception as e:
        return {'error': str(e)}


class Handler(http.server.BaseHTTPRequestHandler):
    def _send_json(self, data, status=200):
        raw = json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)
        if path == '/ping' or path == '/':
            self._send_json({'status': 'ok'})
            return
        if path == '/addresses':
            try:
                with open(ADDR_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                self._send_json(data)
            except Exception as e:
                self._send_json({'error': str(e)}, status=500)
            return
        if path == '/trace':
            file = qs.get('file', [None])[0]
            if not file:
                self._send_json({'error': 'file parameter required'}, status=400)
                return
            # sanitize path: don't allow escaping above workspace
            full = os.path.abspath(os.path.join(ROOT, file))
            if not full.startswith(ROOT):
                self._send_json({'error': 'path outside workspace not allowed'}, status=403)
                return
            if not os.path.exists(full):
                self._send_json({'error': 'file not found', 'path': full}, status=404)
                return
            try:
                with open(full, 'r', encoding='utf-8', errors='ignore') as f:
                    lines = f.readlines()
                tail = lines[-200:]
                self._send_json({'path': full, 'lines': tail})
            except Exception as e:
                self._send_json({'error': str(e)}, status=500)
            return

        self._send_json({'error': 'unknown endpoint'}, status=404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        length = int(self.headers.get('content-length', 0))
        body = self.rfile.read(length) if length else b''
        if path == '/alias':
            try:
                obj = json.loads(body.decode('utf-8') or '{}')
                with open(ADDR_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                name = obj.get('name')
                if not name:
                    self._send_json({'error': 'name required'}, status=400)
                    return
                data[name] = {'address': obj.get('address'), 'desc': obj.get('desc')}
                with open(ADDR_FILE, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                self._send_json({'ok': True, 'alias': data[name]})
            except Exception as e:
                self._send_json({'error': str(e)}, status=500)
            return
        if path == '/compile':
            # run build script
            cmd = '"%s\\build_native.bat"' % ROOT
            res = run_command(cmd)
            self._send_json(res)
            return
        if path == '/run':
            cmd = '"%s\\run_all_expected_tests_no_build.bat"' % ROOT
            res = run_command(cmd)
            self._send_json(res)
            return

        self._send_json({'error': 'unknown endpoint'}, status=404)


def run(server_class=http.server.ThreadingHTTPServer, handler_class=Handler, port=8765):
    server_address = ('127.0.0.1', port)
    httpd = server_class(server_address, handler_class)
    print('UXM control server running on http://127.0.0.1:%d' % port)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('Shutting down')
        httpd.server_close()


if __name__ == '__main__':
    run()
