# UXM VSCode integration helper

Start the control server and use the HTTP API from VSCode tasks or extensions.

Examples:

Start server (from workspace root):

```powershell
python tools\\vscode_integration\\uxm_control_server.py
```

Compile UXM via HTTP:

```powershell
curl -X POST http://127.0.0.1:8765/compile
```

Add alias:

```powershell
curl -X POST http://127.0.0.1:8765/alias -H "Content-Type: application/json" -d '{"name":"TAPE","address":"0x1000","desc":"Tape"}'
```
