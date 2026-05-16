const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const http = require('http');

function ensureCommDir(root) {
	const comm = path.join(root, 'tools', 'vscode_integration', 'comm');
	if (!fs.existsSync(comm)) fs.mkdirSync(comm, { recursive: true });
	return comm;
}

function writeCommandFile(root, payload) {
	const comm = ensureCommDir(root);
	const id = payload.id || `${Date.now()}_${Math.floor(Math.random()*10000)}`;
	payload.id = id;
	const file = path.join(comm, `command_${id}.json`);
	fs.writeFileSync(file, JSON.stringify(payload, null, 2), 'utf8');
	return id;
}

function waitForResultFile(root, id, timeoutMs = 15000) {
	const comm = ensureCommDir(root);
	const resFile = path.join(comm, `result_${id}.json`);
	return new Promise((resolve) => {
		const start = Date.now();
		const timer = setInterval(() => {
			if (fs.existsSync(resFile)) {
				try {
					const raw = fs.readFileSync(resFile, 'utf8');
					const data = JSON.parse(raw);
					clearInterval(timer);
					resolve({ ok: true, data });
				} catch (e) {
					clearInterval(timer);
					resolve({ ok: false, error: String(e) });
				}
			} else if (Date.now() - start > timeoutMs) {
				clearInterval(timer);
				resolve({ ok: false, timeout: true });
			}
		}, 400);
	});
}

function httpPostJson(pathname, body) {
	return new Promise((resolve, reject) => {
		const data = JSON.stringify(body || {});
		const opts = {
			hostname: '127.0.0.1',
			port: 8765,
			path: pathname,
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				'Content-Length': Buffer.byteLength(data)
			}
		};
		const req = http.request(opts, (res) => {
			let out = '';
			res.setEncoding('utf8');
			res.on('data', (c) => out += c);
			res.on('end', () => {
				try { resolve(JSON.parse(out)); } catch (e) { resolve({ raw: out }); }
			});
		});
		req.on('error', (err) => reject(err));
		req.write(data);
		req.end();
	});
}

function runTerminalCommand(folder, cmd) {
	const terminal = vscode.window.createTerminal('UXM');
	terminal.show();
	terminal.sendText(`cd /d "${folder.uri.fsPath}" && ${cmd}`);
}

function activate(context) {
	const output = vscode.window.createOutputChannel('UXM');
	output.appendLine('UXM v15 extension active');

	// legacy bat commands (from v11)
	const folder = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0];
	const cmds = {
		'uxm.bellekTest':'bellek_test.bat',
		'uxm.hizliTara':'hizli_tara.bat',
		'uxm.hataliTest':'hatali_test.bat -k -D',
		'uxm.tumTest':'tum_test.bat -k',
		'uxm.derleyiciDerle':'derleyici_derle.bat',
		'uxm.alanTopla':'alan_topla.bat',
		'uxm.raporGoster':'rapor_goster.bat'
	};
	for (const [cmd, bat] of Object.entries(cmds)) {
		context.subscriptions.push(vscode.commands.registerCommand(cmd, () => {
			const f = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0];
			if (!f) { vscode.window.showErrorMessage('UXM çalışma klasörü açık değil'); return; }
			runTerminalCommand(f, bat);
		}));
	}

	// File-based command with fallback to HTTP control server
	context.subscriptions.push(vscode.commands.registerCommand('uxm.compile', async () => {
		const f = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0];
		if (!f) { vscode.window.showErrorMessage('UXM workspace not open'); return; }
		output.show();
		output.appendLine('uxm.compile: attempting file-based command...');
		const payload = { cmd: 'compile', cwd: f.uri.fsPath };
		try {
			const id = writeCommandFile(f.uri.fsPath, payload);
			output.appendLine(`Wrote command file id=${id}`);
			const res = await waitForResultFile(f.uri.fsPath, id, 10000);
			if (res.ok) {
				output.appendLine(`Result: ${JSON.stringify(res.data)}`);
				vscode.window.showInformationMessage('Compile completed (file protocol)');
				return;
			}
			output.appendLine('No file result; falling back to control server...');
			try {
				const httpRes = await httpPostJson('/compile', { });
				output.appendLine('Control server response: ' + JSON.stringify(httpRes));
				vscode.window.showInformationMessage('Compile requested (control server)');
			} catch (e) {
				output.appendLine('Control server error: ' + String(e));
				vscode.window.showErrorMessage('Compile failed: no response from UXM interpreter (file or control server)');
			}
		} catch (e) {
			output.appendLine('uxm.compile error: ' + String(e));
			vscode.window.showErrorMessage('Compile failed: ' + String(e));
		}
	}));

	context.subscriptions.push(vscode.commands.registerCommand('uxm.runTests', async () => {
		const f = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0];
		if (!f) { vscode.window.showErrorMessage('UXM workspace not open'); return; }
		output.show();
		output.appendLine('uxm.runTests: attempting file-based command...');
		const payload = { cmd: 'run_tests', cwd: f.uri.fsPath };
		try {
			const id = writeCommandFile(f.uri.fsPath, payload);
			output.appendLine(`Wrote command file id=${id}`);
			const res = await waitForResultFile(f.uri.fsPath, id, 10000);
			if (res.ok) { output.appendLine(JSON.stringify(res.data)); vscode.window.showInformationMessage('Run tests completed (file protocol)'); return; }
			output.appendLine('No file result; falling back to control server...');
			try {
				const httpRes = await httpPostJson('/run', {});
				output.appendLine('Control server response: ' + JSON.stringify(httpRes));
				vscode.window.showInformationMessage('Run requested (control server)');
			} catch (e) {
				output.appendLine('Control server error: ' + String(e));
				vscode.window.showErrorMessage('Run failed: no response from UXM interpreter (file or control server)');
			}
		} catch (e) {
			output.appendLine('uxm.runTests error: ' + String(e));
		}
	}));

	// Open control panel (webview)
	context.subscriptions.push(vscode.commands.registerCommand('uxm.openControlPanel', () => {
		const panel = vscode.window.createWebviewPanel('uxmControl', 'UXM Control', vscode.ViewColumn.One, {
			enableScripts: true
		});
		const f = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0];
		const root = f ? f.uri.fsPath : process.cwd();
		panel.webview.html = getWebviewHtml(panel.webview, context.extensionUri, root);
		panel.webview.onDidReceiveMessage(async (msg) => {
			if (msg.cmd === 'getAddresses') {
				try {
					const addrFile = path.join(root, 'tools', 'vscode_integration', 'uxm_addresses.json');
					let data = {};
					if (fs.existsSync(addrFile)) data = JSON.parse(fs.readFileSync(addrFile, 'utf8'));
					panel.webview.postMessage({ type: 'addresses', data });
				} catch (e) { panel.webview.postMessage({ type: 'error', error: String(e) }); }
			}
			if (msg.cmd === 'addAlias') {
				try {
					const alias = msg.alias;
					const payload = { cmd: 'add_alias', alias };
					const id = writeCommandFile(root, payload);
					const res = await waitForResultFile(root, id, 8000);
					panel.webview.postMessage({ type: 'aliasResult', id, res });
				} catch (e) { panel.webview.postMessage({ type: 'error', error: String(e) }); }
			}
			if (msg.cmd === 'compile') {
				vscode.commands.executeCommand('uxm.compile');
			}
			if (msg.cmd === 'run') {
				vscode.commands.executeCommand('uxm.runTests');
			}
			if (msg.cmd === 'trace') {
				// ask control server for trace or read file
				const file = msg.file;
				// prefer control server
				try {
					const res = await new Promise((resolve, reject) => {
						const opts = { hostname: '127.0.0.1', port: 8765, path: `/trace?file=${encodeURIComponent(file)}`, method: 'GET' };
						const r = http.request(opts, (s) => {
							let out = '';
							s.setEncoding('utf8');
							s.on('data', (c) => out += c);
							s.on('end', () => { try { resolve(JSON.parse(out)); } catch(e) { resolve({ raw: out }); } });
						});
						r.on('error', (err) => resolve({ error: String(err) }));
						r.end();
					});
					panel.webview.postMessage({ type: 'traceResult', res });
				} catch (e) { panel.webview.postMessage({ type: 'error', error: String(e) }); }
			}
		});
	}));

	// Backwards-compatible alias: uxm.controlCenter -> uxm.openControlPanel
	context.subscriptions.push(vscode.commands.registerCommand('uxm.controlCenter', () => {
		return vscode.commands.executeCommand('uxm.openControlPanel');
	}));

}

function getWebviewHtml(webview, extensionUri, root) {
	const nonce = Date.now();
	return `<!doctype html>
<html>
<head>
	<meta charset="utf-8" />
	<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline' 'unsafe-eval' http: https:; style-src 'unsafe-inline';">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>UXM Control</title>
</head>
<body>
	<h3>UXM Control Panel</h3>
	<div>
		<button id="compile">Compile</button>
		<button id="run">Run Tests</button>
	</div>
	<h4>Aliases</h4>
	<div id="aliases"></div>
	<form id="aliasForm">
		<input id="aname" placeholder="name" />
		<input id="aaddr" placeholder="address" />
		<input id="adesc" placeholder="desc" />
		<button type="submit">Add</button>
	</form>
	<h4>Trace</h4>
	<input id="tracefile" placeholder="relative/path/to/trace.log" style="width:60%" /> <button id="traceBtn">Get Trace</button>
	<pre id="output" style="height:300px;overflow:auto;background:#f7f7f7;padding:8px;border:1px solid #ddd"></pre>

	<script>
		const vscode = acquireVsCodeApi();
		document.getElementById('compile').addEventListener('click', ()=> vscode.postMessage({ cmd: 'compile' }));
		document.getElementById('run').addEventListener('click', ()=> vscode.postMessage({ cmd: 'run' }));
		document.getElementById('aliasForm').addEventListener('submit', (e)=>{
			e.preventDefault();
			const alias = { name: document.getElementById('aname').value, address: document.getElementById('aaddr').value, desc: document.getElementById('adesc').value };
			vscode.postMessage({ cmd: 'addAlias', alias });
		});
		document.getElementById('traceBtn').addEventListener('click', ()=>{
			const file = document.getElementById('tracefile').value;
			vscode.postMessage({ cmd: 'trace', file });
		});
		window.addEventListener('message', event => {
			const msg = event.data;
			const out = document.getElementById('output');
			if (msg.type === 'addresses') out.textContent = JSON.stringify(msg.data, null, 2);
			if (msg.type === 'aliasResult') out.textContent = JSON.stringify(msg.res, null, 2);
			if (msg.type === 'traceResult') out.textContent = JSON.stringify(msg.res, null, 2);
			if (msg.type === 'error') out.textContent = 'ERROR: '+msg.error;
		});
		// request current addresses
		vscode.postMessage({ cmd: 'getAddresses' });
	</script>
</body>
</html>`;
}

function deactivate() {}

module.exports = { activate, deactivate };
