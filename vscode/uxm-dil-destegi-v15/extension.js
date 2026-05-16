const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const http = require('http');

let activePanel = null;
let activePanelState = null;
let traceDecoration = null;

const KNOWN_TOOL_INFO = {
	'build_native.bat': {
		name: 'Compiler Build',
		purpose: 'UXM native compiler uretir.',
		input: 'uxm/core/compiler/native/*.bas',
		output: 'build/exe/uxm_native.exe'
	},
	'build_one_native.bat': {
		name: 'Tek Dosya Derleme',
		purpose: 'Bir .uxm dosyasini asm/obj/exe akisiyla derler.',
		input: 'Bir .uxm kaynak dosyasi',
		output: 'build/asm, build/obj, build/exe'
	},
	'rtxz.bat': {
		name: 'Toplu Test (Native)',
		purpose: 'Native test klasorlerini toplu kosar.',
		input: 'uxm/tests altindaki .uxm testleri',
		output: 'sonuc*.txt ve build/logs/*'
	},
	'run_all_expected_tests_no_build.bat': {
		name: 'Expected Runner No-Build',
		purpose: 'Beklenen cikti testlerini no-build kosar.',
		input: 'manifest + expect dosyalari',
		output: 'all_expected_results/*'
	},
	'run_uxm_with_comm_watcher.bat': {
		name: 'Runtime + Comm Watcher',
		purpose: 'Comm watcher ile runtime birlikte baslatir.',
		input: 'komut argumanlari',
		output: 'comm result json + runtime ciktilari'
	}
};

const COMMAND_DOCS = [
	{ token: '>', desc: 'Pointer saga gider.' },
	{ token: '<', desc: 'Pointer sola gider.' },
	{ token: '+', desc: 'Hucreyi artirir.' },
	{ token: '-', desc: 'Hucreyi azaltir.' },
	{ token: '0', desc: 'Hucreyi sifirlar.' },
	{ token: '.', desc: 'Karakter yazdirir.' },
	{ token: ',', desc: 'Karakter okur.' },
	{ token: '[ ]', desc: 'Loop baslatir/bitirir.' },
	{ token: '$ / %', desc: 'Stack push/pop.' },
	{ token: '? ! ;', desc: 'Karsilastirma operasyonlari.' },
	{ token: '& | ^ ~', desc: 'Bit operasyonlari.' },
	{ token: '{ }', desc: 'Shift operasyonlari.' },
	{ token: 'e', desc: 'Status okur/isler.' },
	{ token: '@ID', desc: 'Meta servis cagirir.' },
	{ token: ':', desc: 'Branch ailesi.' },
	{ token: 'sN / pN / mN', desc: 'String yazdirma ve macro tanimlari.' }
];

const ADDRESSING_DOCS = [
	{ mode: '(T)', desc: 'Aktif tape hucre.' },
	{ mode: '(T+N)/(T-N)', desc: 'Tape goreli adresleme.' },
	{ mode: '(T:N)', desc: 'Tape mutlak adresleme.' },
	{ mode: '(D:N)', desc: 'Data segment mutlak adresleme.' },
	{ mode: '(SP)/(SP+N)/(SP-N)', desc: 'Stack pointer adresleme.' },
	{ mode: '(P)/(E)/(F)', desc: 'Pointer/endian/flag register adresleme.' },
	{ mode: '(*T), (*(T+N))', desc: 'Dolayli tape adresleme.' },
	{ mode: '(D@T), (D@T+N)', desc: 'Data indeksleme (tape bazli).' },
	{ mode: '(D:N+P), (T:N+P)', desc: 'Base+P adresleme.' },
	{ mode: '(D@D:N), (T@D:N)', desc: 'Cift dolayli adresleme.' }
];

function getWorkspaceRoot() {
	const folder = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0];
	return folder ? folder.uri.fsPath : null;
}

function resolveVsIntegrationBase(root) {
	const candidates = [
		path.join(root, 'tools', 'vscode_integration'),
		path.join(root, 'vscode', 'uxm-dil-destegi-v15', 'src', 'vscode_integration')
	];
	for (const candidate of candidates) {
		if (fs.existsSync(candidate)) return candidate;
	}
	return candidates[0];
}

function ensureCommDir(root) {
	const comm = path.join(resolveVsIntegrationBase(root), 'comm');
	if (!fs.existsSync(comm)) fs.mkdirSync(comm, { recursive: true });
	return comm;
}

function ensureStateDirs(root) {
	const base = path.join(root, '.uxm', 'vscode');
	const notesDir = path.join(base, 'notes');
	const logsDir = path.join(base, 'logs');
	if (!fs.existsSync(notesDir)) fs.mkdirSync(notesDir, { recursive: true });
	if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir, { recursive: true });
	return { base, notesDir, logsDir };
}

function readTextSafe(filePath) {
	try {
		return fs.readFileSync(filePath, 'utf8');
	} catch (_e) {
		return '';
	}
}

function readJsonSafe(filePath, fallback) {
	try {
		return JSON.parse(fs.readFileSync(filePath, 'utf8'));
	} catch (_e) {
		return fallback;
	}
}

function writeJsonSafe(filePath, value) {
	const parent = path.dirname(filePath);
	if (!fs.existsSync(parent)) fs.mkdirSync(parent, { recursive: true });
	fs.writeFileSync(filePath, JSON.stringify(value, null, 2), 'utf8');
}

function appendJsonl(root, eventType, payload) {
	const { logsDir } = ensureStateDirs(root);
	const file = path.join(logsDir, 'session_events.jsonl');
	const row = {
		schema: 'uxm.v1.event',
		ts: new Date().toISOString(),
		type: eventType,
		payload
	};
	fs.appendFileSync(file, JSON.stringify(row) + '\n', 'utf8');
}

function generateId() {
	return String(Date.now()) + '_' + String(Math.floor(Math.random() * 100000));
}

function buildCommandPayload(cmd, cwd, extra = {}) {
	return {
		schema: 'uxm.v1.command',
		id: generateId(),
		ts: new Date().toISOString(),
		cmd,
		cwd,
		...extra
	};
}

function writeCommandFile(root, payload) {
	const comm = ensureCommDir(root);
	const id = payload.id || generateId();
	payload.id = id;
	const file = path.join(comm, 'command_' + id + '.json');
	fs.writeFileSync(file, JSON.stringify(payload, null, 2), 'utf8');
	return id;
}

function waitForResultFile(root, id, timeoutMs = 15000) {
	const comm = ensureCommDir(root);
	const resFile = path.join(comm, 'result_' + id + '.json');
	return new Promise((resolve) => {
		const start = Date.now();
		const timer = setInterval(() => {
			if (fs.existsSync(resFile)) {
				try {
					const raw = fs.readFileSync(resFile, 'utf8');
					const data = JSON.parse(raw);
					clearInterval(timer);
					resolve({ ok: true, protocol: 'file', data });
				} catch (e) {
					clearInterval(timer);
					resolve({ ok: false, protocol: 'file', error: String(e) });
				}
			} else if (Date.now() - start > timeoutMs) {
				clearInterval(timer);
				resolve({ ok: false, protocol: 'file', timeout: true });
			}
		}, 350);
	});
}

function httpRequestJson(method, pathname, body) {
	return new Promise((resolve, reject) => {
		const data = body ? JSON.stringify(body) : '';
		const opts = {
			hostname: '127.0.0.1',
			port: 8765,
			path: pathname,
			method,
			headers: {
				'Content-Type': 'application/json',
				'Content-Length': Buffer.byteLength(data)
			}
		};
		const req = http.request(opts, (res) => {
			let out = '';
			res.setEncoding('utf8');
			res.on('data', (chunk) => {
				out += chunk;
			});
			res.on('end', () => {
				try {
					resolve(JSON.parse(out));
				} catch (_e) {
					resolve({ raw: out });
				}
			});
		});
		req.on('error', (err) => reject(err));
		if (data) req.write(data);
		req.end();
	});
}

function httpPostJson(pathname, body) {
	return httpRequestJson('POST', pathname, body || {});
}

function httpGetJson(pathname) {
	return httpRequestJson('GET', pathname, null);
}

function runTerminalCommand(root, cmd) {
	const terminal = vscode.window.createTerminal('UXM Tools');
	terminal.show();
	terminal.sendText('cd /d "' + root + '" && ' + cmd);
}

function parseCsvLine(line) {
	const out = [];
	let cur = '';
	let quoted = false;
	for (let i = 0; i < line.length; i += 1) {
		const ch = line[i];
		if (ch === '"') {
			if (quoted && i + 1 < line.length && line[i + 1] === '"') {
				cur += '"';
				i += 1;
			} else {
				quoted = !quoted;
			}
		} else if (ch === ',' && !quoted) {
			out.push(cur);
			cur = '';
		} else {
			cur += ch;
		}
	}
	out.push(cur);
	return out;
}

function loadServiceDocs(root, limit = 300) {
	const file = path.join(root, 'config', 'uxm', 'service_registry_merged.csv');
	if (!fs.existsSync(file)) return [];
	const lines = readTextSafe(file).split(/\r?\n/).filter((x) => x.trim() !== '');
	if (lines.length <= 1) return [];
	const header = parseCsvLine(lines[0]);
	const idIdx = header.indexOf('id');
	const nameIdx = header.indexOf('name');
	const familyIdx = header.indexOf('family');
	const notesIdx = header.indexOf('notes');
	const rows = [];
	for (let i = 1; i < lines.length && rows.length < limit; i += 1) {
		const cols = parseCsvLine(lines[i]);
		rows.push({
			id: idIdx >= 0 ? cols[idIdx] : cols[0],
			name: nameIdx >= 0 ? cols[nameIdx] : '',
			family: familyIdx >= 0 ? cols[familyIdx] : '',
			notes: notesIdx >= 0 ? cols[notesIdx] : ''
		});
	}
	return rows;
}

function loadHelpDocs(root) {
	const candidates = [
		{ id: 'pck', title: 'PCK', relPath: 'pck.md' },
		{ id: 'mimari', title: 'Compiler Mimarisi', relPath: 'docs/uxm_compiler_mimarisi.md' },
		{ id: 'kilavuz', title: 'UX Minima Kilavuz', relPath: 'UX_MINIMA_x64_Kullanim_Kilavuzu_TAM.md' },
		{ id: 'readme', title: 'README_V19', relPath: 'README_V19.md' }
	];
	const docs = [];
	for (const c of candidates) {
		const abs = path.join(root, c.relPath);
		if (fs.existsSync(abs)) {
			docs.push({
				id: c.id,
				title: c.title,
				relPath: c.relPath,
				content: readTextSafe(abs)
			});
		}
	}
	return docs;
}

function loadToolCatalog(root) {
	const toolsDir = path.join(root, 'tools');
	const out = [];
	if (fs.existsSync(toolsDir)) {
		for (const entry of fs.readdirSync(toolsDir)) {
			if (!/\.(bat|py)$/i.test(entry)) continue;
			const abs = path.join(toolsDir, entry);
			const rel = path.relative(root, abs).replace(/\\/g, '/');
			const known = KNOWN_TOOL_INFO[entry.toLowerCase()] || {};
			out.push({
				id: rel,
				path: rel,
				name: known.name || entry,
				purpose: known.purpose || 'Araci calistirir.',
				input: known.input || 'Araca gore degisir.',
				output: known.output || 'Araca gore degisir.'
			});
		}
	}
	out.sort((a, b) => a.path.localeCompare(b.path));
	return out;
}

function getActiveProgramRel(root) {
	const editor = vscode.window.activeTextEditor;
	if (!editor || !editor.document) return '';
	const fsPath = editor.document.uri.fsPath;
	if (!fsPath.toLowerCase().endsWith('.uxm')) return '';
	const rel = path.relative(root, fsPath);
	if (rel.startsWith('..')) return '';
	return rel.replace(/\\/g, '/');
}

function noteFileName(programRel) {
	if (!programRel) return '__workspace__.notes.json';
	const safe = programRel.replace(/[\\/:*?"<>|]/g, '_');
	return safe + '.notes.json';
}

function loadProgramNotes(root, programRel) {
	const { notesDir } = ensureStateDirs(root);
	const file = path.join(notesDir, noteFileName(programRel));
	const base = {
		schema: 'uxm.v1.memoryNotes',
		program: programRel,
		updatedAt: new Date().toISOString(),
		notes: {
			tape: [],
			data: [],
			stack: [],
			queue: []
		}
	};
	const existing = readJsonSafe(file, base);
	if (!existing.notes) existing.notes = base.notes;
	for (const key of ['tape', 'data', 'stack', 'queue']) {
		if (!Array.isArray(existing.notes[key])) existing.notes[key] = [];
	}
	return existing;
}

function saveProgramNotes(root, programRel, data) {
	const { notesDir } = ensureStateDirs(root);
	const file = path.join(notesDir, noteFileName(programRel));
	data.schema = 'uxm.v1.memoryNotes';
	data.program = programRel;
	data.updatedAt = new Date().toISOString();
	writeJsonSafe(file, data);
	return file;
}

function extractLineNumber(line) {
	if (!line) return null;
	const patterns = [
		/"line"\s*:\s*(\d+)/i,
		/\bline\s*[:=]\s*(\d+)/i,
		/\bsatir\s*[:=]\s*(\d+)/i,
		/\bL(\d+)\b/
	];
	for (const p of patterns) {
		const m = line.match(p);
		if (m) {
			const n = Number(m[1]);
			if (!Number.isNaN(n) && n > 0) return n;
		}
	}
	return null;
}

function extractCommandToken(line) {
	if (!line) return '';
	let m = line.match(/\b(?:cmd|command|op|token)\s*[:=]\s*([^\s,]+)/i);
	if (m) return m[1];
	m = line.match(/\b(@\d+|[><+\-0.,\[\]$%?!;&|^~{}eE])\b/);
	if (m) return m[1];
	return '';
}

function normalizeTrace(rawText) {
	const lines = String(rawText || '').split(/\r?\n/).filter((x) => x.trim() !== '');
	return lines.map((line, i) => ({
		index: i,
		raw: line,
		lineNumber: extractLineNumber(line),
		command: extractCommandToken(line)
	}));
}

async function resolveEditorForTrace(root, programRel) {
	const wanted = programRel ? path.join(root, programRel) : null;
	const active = vscode.window.activeTextEditor;
	if (active && active.document && active.document.uri && active.document.uri.fsPath) {
		if (!wanted || path.normalize(active.document.uri.fsPath) === path.normalize(wanted)) {
			return active;
		}
	}
	if (wanted) {
		for (const ed of vscode.window.visibleTextEditors) {
			if (path.normalize(ed.document.uri.fsPath) === path.normalize(wanted)) return ed;
		}
		if (fs.existsSync(wanted)) {
			const doc = await vscode.workspace.openTextDocument(wanted);
			return vscode.window.showTextDocument(doc, { preview: false, preserveFocus: true });
		}
	}
	return active || null;
}

function ensureTraceDecoration(context) {
	if (traceDecoration) return traceDecoration;
	const markerPath = path.join(context.extensionPath, 'resources', 'trace-marker.svg');
	const options = {
		isWholeLine: true,
		backgroundColor: 'rgba(255, 188, 60, 0.18)',
		borderWidth: '0 0 0 3px',
		borderStyle: 'solid',
		borderColor: 'rgba(255, 153, 0, 0.95)',
		overviewRulerColor: 'rgba(255, 153, 0, 0.95)',
		overviewRulerLane: vscode.OverviewRulerLane.Right
	};
	if (fs.existsSync(markerPath)) {
		options.gutterIconPath = vscode.Uri.file(markerPath);
		options.gutterIconSize = 'contain';
	}
	traceDecoration = vscode.window.createTextEditorDecorationType(options);
	return traceDecoration;
}

async function applyTraceHighlight(context, root, programRel, lineNumber) {
	if (!lineNumber || lineNumber < 1) return;
	const editor = await resolveEditorForTrace(root, programRel);
	if (!editor) return;
	const doc = editor.document;
	const idx = Math.max(0, Math.min(lineNumber - 1, doc.lineCount - 1));
	const line = doc.lineAt(idx);
	const range = line.range;
	editor.selection = new vscode.Selection(range.start, range.end);
	editor.revealRange(range, vscode.TextEditorRevealType.InCenterIfOutsideViewport);
	editor.setDecorations(ensureTraceDecoration(context), [range]);
}

function clearTraceHighlight() {
	for (const ed of vscode.window.visibleTextEditors) {
		if (traceDecoration) ed.setDecorations(traceDecoration, []);
	}
}

async function runCommandViaCommThenHttp(root, cmdPayload, httpPath, httpBody) {
	const id = writeCommandFile(root, cmdPayload);
	const fileRes = await waitForResultFile(root, id, 12000);
	if (fileRes.ok) {
		return {
			schema: 'uxm.v1.result',
			ts: new Date().toISOString(),
			id,
			cmd: cmdPayload.cmd,
			protocol: 'file',
			ok: true,
			result: fileRes.data
		};
	}
	if (!httpPath) {
		return {
			schema: 'uxm.v1.result',
			ts: new Date().toISOString(),
			id,
			cmd: cmdPayload.cmd,
			protocol: 'file',
			ok: false,
			error: fileRes.error || 'No file result and no HTTP fallback.'
		};
	}
	try {
		const httpRes = await httpPostJson(httpPath, httpBody || {});
		return {
			schema: 'uxm.v1.result',
			ts: new Date().toISOString(),
			id,
			cmd: cmdPayload.cmd,
			protocol: 'http',
			ok: true,
			result: httpRes
		};
	} catch (e) {
		return {
			schema: 'uxm.v1.result',
			ts: new Date().toISOString(),
			id,
			cmd: cmdPayload.cmd,
			protocol: 'http',
			ok: false,
			error: String(e)
		};
	}
}

function postPanel(panel, type, payload) {
	if (!panel) return;
	panel.webview.postMessage({ type, payload });
}

function buildPanelState(root) {
	const base = resolveVsIntegrationBase(root);
	const addrFile = path.join(base, 'uxm_addresses.json');
	const addresses = readJsonSafe(addrFile, {});
	const programRel = getActiveProgramRel(root);
	const notes = loadProgramNotes(root, programRel);
	return {
		schema: 'uxm.v1.panelState',
		ts: new Date().toISOString(),
		root,
		integrationBase: base,
		activeProgramRel: programRel,
		addresses,
		tools: loadToolCatalog(root),
		commandDocs: COMMAND_DOCS,
		addressingDocs: ADDRESSING_DOCS,
		serviceDocs: loadServiceDocs(root),
		helpDocs: loadHelpDocs(root),
		notes
	};
}

async function openHelpPreview(root, relPath) {
	const full = path.join(root, relPath || '');
	if (!fs.existsSync(full)) {
		vscode.window.showErrorMessage('Belge bulunamadi: ' + relPath);
		return;
	}
	const uri = vscode.Uri.file(full);
	await vscode.commands.executeCommand('vscode.open', uri);
	await vscode.commands.executeCommand('markdown.showPreview', uri);
}

async function openControlCenter(context, output) {
	const root = getWorkspaceRoot();
	if (!root) {
		vscode.window.showErrorMessage('UXM workspace acik degil.');
		return;
	}

	if (activePanel) {
		activePanel.reveal(vscode.ViewColumn.One, false);
		postPanel(activePanel, 'state', buildPanelState(root));
		return;
	}

	activePanel = vscode.window.createWebviewPanel(
		'uxmControlCenter',
		'UXM Kontrol Merkezi',
		vscode.ViewColumn.One,
		{
			enableScripts: true,
			retainContextWhenHidden: true
		}
	);

	activePanel.webview.html = getControlCenterHtml();
	activePanelState = { root };

	const editorWatcher = vscode.window.onDidChangeActiveTextEditor(() => {
		if (!activePanel || !activePanelState) return;
		postPanel(activePanel, 'state', buildPanelState(activePanelState.root));
	});

	activePanel.onDidDispose(() => {
		editorWatcher.dispose();
		clearTraceHighlight();
		activePanel = null;
		activePanelState = null;
	});

	activePanel.webview.onDidReceiveMessage(async (msg) => {
		const currentRoot = activePanelState ? activePanelState.root : root;
		try {
			switch (msg.cmd) {
				case 'requestState': {
					postPanel(activePanel, 'state', buildPanelState(currentRoot));
					break;
				}
				case 'compile': {
					const cmdPayload = buildCommandPayload('compile', currentRoot);
					const result = await runCommandViaCommThenHttp(currentRoot, cmdPayload, '/compile', {});
					appendJsonl(currentRoot, 'compile', result);
					output.appendLine('[compile] ' + JSON.stringify(result));
					postPanel(activePanel, 'actionResult', result);
					break;
				}
				case 'runTests': {
					const cmdPayload = buildCommandPayload('run_tests', currentRoot);
					const result = await runCommandViaCommThenHttp(currentRoot, cmdPayload, '/run', {});
					appendJsonl(currentRoot, 'run_tests', result);
					output.appendLine('[runTests] ' + JSON.stringify(result));
					postPanel(activePanel, 'actionResult', result);
					break;
				}
				case 'runInterpreter': {
					const state = buildPanelState(currentRoot);
					if (!state.activeProgramRel) {
						postPanel(activePanel, 'error', { message: 'Aktif .uxm dosyasi yok.' });
						break;
					}
					const shell = 'cmd /c "call build_one_native.bat \"' + state.activeProgramRel + '\" -x"';
					const cmdPayload = buildCommandPayload('shell', currentRoot, { shell });
					const result = await runCommandViaCommThenHttp(currentRoot, cmdPayload, null, null);
					if (!result.ok) {
						runTerminalCommand(currentRoot, 'call build_one_native.bat "' + state.activeProgramRel + '" -x');
					}
					appendJsonl(currentRoot, 'run_interpreter', result);
					output.appendLine('[runInterpreter] ' + JSON.stringify(result));
					postPanel(activePanel, 'actionResult', result);
					break;
				}
				case 'traceFetch': {
					const relFile = msg.file || 'build/logs/uxm_runtime_trace.log';
					let response = null;
					try {
						response = await httpGetJson('/trace?file=' + encodeURIComponent(relFile));
					} catch (e) {
						response = { error: String(e) };
					}
					let rawText = '';
					if (response && Array.isArray(response.lines)) rawText = response.lines.join('\n');
					else if (response && typeof response.raw === 'string') rawText = response.raw;
					else rawText = JSON.stringify(response, null, 2);
					const entries = normalizeTrace(rawText);
					const packet = {
						schema: 'uxm.v1.trace',
						ts: new Date().toISOString(),
						source: relFile,
						entryCount: entries.length,
						entries
					};
					const { logsDir } = ensureStateDirs(currentRoot);
					writeJsonSafe(path.join(logsDir, 'trace_last.json'), packet);
					appendJsonl(currentRoot, 'trace_fetch', { source: relFile, entryCount: entries.length });
					postPanel(activePanel, 'traceData', packet);
					break;
				}
				case 'traceStep': {
					await applyTraceHighlight(context, currentRoot, msg.programRel || getActiveProgramRel(currentRoot), msg.lineNumber);
					appendJsonl(currentRoot, 'trace_step', {
						programRel: msg.programRel || getActiveProgramRel(currentRoot),
						lineNumber: msg.lineNumber
					});
					break;
				}
				case 'traceClear': {
					clearTraceHighlight();
					break;
				}
				case 'runTool': {
					const rel = msg.toolPath || '';
					if (!rel) {
						postPanel(activePanel, 'error', { message: 'Arac secilmedi.' });
						break;
					}
					const abs = path.join(currentRoot, rel);
					if (!fs.existsSync(abs)) {
						postPanel(activePanel, 'error', { message: 'Arac dosyasi yok: ' + rel });
						break;
					}
					let shell = '';
					if (rel.toLowerCase().endsWith('.py')) shell = 'py -3 "' + rel + '"';
					else shell = 'call "' + rel + '"';
					const cmdPayload = buildCommandPayload('shell', currentRoot, { shell });
					const result = await runCommandViaCommThenHttp(currentRoot, cmdPayload, null, null);
					if (!result.ok) runTerminalCommand(currentRoot, shell);
					appendJsonl(currentRoot, 'run_tool', { tool: rel, result });
					postPanel(activePanel, 'actionResult', result);
					break;
				}
				case 'saveNote': {
					const state = buildPanelState(currentRoot);
					const programRel = msg.programRel || state.activeProgramRel;
					if (!programRel) {
						postPanel(activePanel, 'error', { message: 'Not kaydi icin aktif .uxm dosyasi gerekli.' });
						break;
					}
					const notes = loadProgramNotes(currentRoot, programRel);
					const segment = String(msg.segment || '').toLowerCase();
					if (!['tape', 'data', 'stack', 'queue'].includes(segment)) {
						postPanel(activePanel, 'error', { message: 'Segment gecersiz.' });
						break;
					}
					const item = {
						id: generateId(),
						cell: String(msg.cell || '').trim(),
						purpose: String(msg.purpose || '').trim(),
						note: String(msg.note || '').trim(),
						createdAt: new Date().toISOString()
					};
					notes.notes[segment].push(item);
					const file = saveProgramNotes(currentRoot, programRel, notes);
					appendJsonl(currentRoot, 'save_note', { programRel, segment, id: item.id, file });
					postPanel(activePanel, 'notesUpdated', notes);
					postPanel(activePanel, 'state', buildPanelState(currentRoot));
					break;
				}
				case 'deleteNote': {
					const state = buildPanelState(currentRoot);
					const programRel = msg.programRel || state.activeProgramRel;
					if (!programRel) {
						postPanel(activePanel, 'error', { message: 'Silme icin aktif .uxm dosyasi gerekli.' });
						break;
					}
					const segment = String(msg.segment || '').toLowerCase();
					const id = String(msg.id || '');
					const notes = loadProgramNotes(currentRoot, programRel);
					if (Array.isArray(notes.notes[segment])) {
						notes.notes[segment] = notes.notes[segment].filter((x) => String(x.id) !== id);
						saveProgramNotes(currentRoot, programRel, notes);
						appendJsonl(currentRoot, 'delete_note', { programRel, segment, id });
						postPanel(activePanel, 'notesUpdated', notes);
						postPanel(activePanel, 'state', buildPanelState(currentRoot));
					}
					break;
				}
				case 'openHelpDoc': {
					await openHelpPreview(currentRoot, msg.relPath);
					break;
				}
				default:
					postPanel(activePanel, 'error', { message: 'Bilinmeyen komut: ' + String(msg.cmd) });
					break;
			}
		} catch (e) {
			const err = String(e);
			output.appendLine('[error] ' + err);
			postPanel(activePanel, 'error', { message: err });
		}
	});

	postPanel(activePanel, 'state', buildPanelState(root));
}

function getControlCenterHtml() {
	return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline';" />
  <title>UXM Kontrol Merkezi</title>
  <style>
    body { font-family: Segoe UI, Arial, sans-serif; padding: 10px; color: #222; }
    h2, h3 { margin: 8px 0; }
    .muted { color: #666; font-size: 12px; }
    .toolbar { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 10px; }
    button { padding: 6px 10px; border: 1px solid #999; background: #f5f5f5; cursor: pointer; }
    button:hover { background: #ececec; }
    input, select, textarea { width: 100%; box-sizing: border-box; margin: 4px 0; padding: 6px; border: 1px solid #999; }
    textarea { min-height: 72px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
    .card { border: 1px solid #ccc; border-radius: 6px; padding: 8px; background: #fff; }
    .list { max-height: 220px; overflow: auto; border: 1px solid #ddd; padding: 4px; }
    .item { padding: 4px 6px; border-bottom: 1px solid #eee; cursor: pointer; }
    .item:hover { background: #f7f7f7; }
    .item.current { background: #fff2c9; border-left: 4px solid #f5a000; }
    .mono { font-family: Consolas, monospace; white-space: pre-wrap; word-break: break-word; }
    .row { display: flex; gap: 8px; }
    .row > div { flex: 1; }
    .tiny { font-size: 11px; color: #444; }
    .status-ok { color: #0b7a0b; }
    .status-err { color: #b00020; }
    .helpbox { max-height: 280px; overflow: auto; border: 1px solid #ddd; padding: 8px; background: #fcfcfc; }
    .tag { display: inline-block; padding: 1px 6px; border: 1px solid #bbb; border-radius: 10px; margin-right: 4px; font-size: 11px; }
  </style>
</head>
<body>
  <h2>UXM Kontrol Merkezi</h2>
  <div id="summary" class="muted">Yukleniyor...</div>

  <div class="toolbar">
    <button id="btnRefresh">Yenile</button>
    <button id="btnCompile">Compile</button>
    <button id="btnRunInterpreter">Interpreter Calistir</button>
    <button id="btnRunTests">Toplu Test</button>
    <button id="btnClearTrace">Trace Isareti Temizle</button>
  </div>

  <div class="grid">
    <div class="card">
      <h3>Trace Izleme</h3>
      <div class="row">
        <div><input id="traceFile" value="build/logs/uxm_runtime_trace.log" /></div>
        <div style="max-width:140px"><button id="btnTraceLoad">Trace Yukle</button></div>
      </div>
      <div class="toolbar">
        <button id="btnPrev">Geri</button>
        <button id="btnNext">Ileri</button>
        <button id="btnPlay">Play</button>
        <label class="tiny">Hiz(ms)<input id="playSpeed" type="number" value="600" min="100" step="100" /></label>
      </div>
      <div id="traceList" class="list"></div>
      <div id="traceCurrent" class="mono tiny"></div>
    </div>

    <div class="card">
      <h3>JSON / Cikti</h3>
      <div class="tiny">Standart kayit: schema=uxm.v1.*</div>
      <pre id="jsonOut" class="mono"></pre>
    </div>
  </div>

  <div class="grid" style="margin-top: 10px;">
    <div class="card">
      <h3>Arac Secici</h3>
      <select id="toolSelect"></select>
      <div id="toolInfo" class="tiny"></div>
      <button id="btnRunTool">Secili Araci Calistir</button>
    </div>

    <div class="card">
      <h3>Adres / Segment Bilgisi</h3>
      <div id="addrBox" class="mono tiny"></div>
    </div>
  </div>

  <div class="grid" style="margin-top: 10px;">
    <div class="card">
      <h3>Komut + Adresleme Rehberi</h3>
      <input id="cmdSearch" placeholder="Komut ara..." />
      <div id="cmdList" class="list tiny"></div>
    </div>
    <div class="card">
      <h3>Servis Rehberi</h3>
      <input id="svcSearch" placeholder="Servis ara (id/family/name)..." />
      <div id="svcList" class="list tiny"></div>
    </div>
  </div>

  <div class="card" style="margin-top: 10px;">
    <h3>Help / Kilavuzlar (MD)</h3>
    <div class="row">
      <div><select id="helpSelect"></select></div>
      <div style="max-width:160px"><button id="btnOpenHelp">VSCode MD Preview</button></div>
    </div>
    <input id="helpSearch" placeholder="Help iceriginde ara..." />
    <div id="helpContent" class="helpbox mono tiny"></div>
  </div>

  <div class="card" style="margin-top: 10px;">
    <h3>Programa Bagli Bellek Notlari</h3>
    <div class="tiny">Notlar aktif .uxm dosyasina bagli kaydedilir.</div>
    <div class="row">
      <div><select id="noteSegment"><option value="tape">tape</option><option value="data">data</option><option value="stack">stack</option><option value="queue">queue</option></select></div>
      <div><input id="noteCell" placeholder="hucre/index (or: 42, 10-20, ptr@8)" /></div>
    </div>
    <input id="notePurpose" placeholder="amac/gorev" />
    <textarea id="noteText" placeholder="programla ilgili not"></textarea>
    <button id="btnSaveNote">Not Kaydet</button>
    <div id="notesList" class="list tiny" style="margin-top:6px"></div>
  </div>

  <script>
    const vscode = acquireVsCodeApi();

    let state = {
      root: '',
      activeProgramRel: '',
      tools: [],
      addresses: {},
      commandDocs: [],
      addressingDocs: [],
      serviceDocs: [],
      helpDocs: [],
      notes: { notes: { tape: [], data: [], stack: [], queue: [] } }
    };

    let traceEntries = [];
    let traceIndex = -1;
    let playTimer = null;

    function esc(s) {
      return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    function setSummary() {
      const txt = 'Root: ' + (state.root || '-') + ' | Aktif Program: ' + (state.activeProgramRel || 'YOK');
      document.getElementById('summary').textContent = txt;
    }

    function setJsonOut(obj, ok) {
      const el = document.getElementById('jsonOut');
      el.textContent = typeof obj === 'string' ? obj : JSON.stringify(obj, null, 2);
      el.className = 'mono ' + (ok === false ? 'status-err' : 'status-ok');
    }

    function renderAddresses() {
      document.getElementById('addrBox').textContent = JSON.stringify(state.addresses || {}, null, 2);
    }

    function renderTools() {
      const sel = document.getElementById('toolSelect');
      sel.innerHTML = '';
      for (const t of state.tools || []) {
        const op = document.createElement('option');
        op.value = t.path;
        op.textContent = t.path;
        sel.appendChild(op);
      }
      renderToolInfo();
    }

    function renderToolInfo() {
      const sel = document.getElementById('toolSelect');
      const info = document.getElementById('toolInfo');
      const tool = (state.tools || []).find(x => x.path === sel.value);
      if (!tool) {
        info.textContent = 'Arac bulunamadi.';
        return;
      }
      info.innerHTML = ''
        + '<div><span class="tag">Ad</span> ' + esc(tool.name) + '</div>'
        + '<div><span class="tag">Amac</span> ' + esc(tool.purpose) + '</div>'
        + '<div><span class="tag">Girdi</span> ' + esc(tool.input) + '</div>'
        + '<div><span class="tag">Cikti</span> ' + esc(tool.output) + '</div>';
    }

    function renderCommandDocs() {
      const q = (document.getElementById('cmdSearch').value || '').toLowerCase();
      const list = document.getElementById('cmdList');
      list.innerHTML = '';
      const all = (state.commandDocs || []).map(x => ({ k: x.token, d: x.desc, type: 'komut' }))
        .concat((state.addressingDocs || []).map(x => ({ k: x.mode, d: x.desc, type: 'adresleme' })));
      for (const row of all) {
        const text = (row.k + ' ' + row.d + ' ' + row.type).toLowerCase();
        if (q && !text.includes(q)) continue;
        const div = document.createElement('div');
        div.className = 'item';
        div.innerHTML = '<b>[' + esc(row.type) + ']</b> ' + esc(row.k) + ' - ' + esc(row.d);
        list.appendChild(div);
      }
    }

    function renderServiceDocs() {
      const q = (document.getElementById('svcSearch').value || '').toLowerCase();
      const list = document.getElementById('svcList');
      list.innerHTML = '';
      for (const s of state.serviceDocs || []) {
        const text = (String(s.id) + ' ' + String(s.name) + ' ' + String(s.family) + ' ' + String(s.notes)).toLowerCase();
        if (q && !text.includes(q)) continue;
        const div = document.createElement('div');
        div.className = 'item';
        div.innerHTML = '<b>@' + esc(s.id) + '</b> [' + esc(s.family || '-') + '] ' + esc(s.name || '-')
          + '<div class="tiny">' + esc(s.notes || '') + '</div>';
        list.appendChild(div);
      }
    }

    function currentHelpDoc() {
      const sel = document.getElementById('helpSelect');
      return (state.helpDocs || []).find(x => x.id === sel.value) || null;
    }

    function renderHelpDocs() {
      const sel = document.getElementById('helpSelect');
      const prev = sel.value;
      sel.innerHTML = '';
      for (const d of state.helpDocs || []) {
        const op = document.createElement('option');
        op.value = d.id;
        op.textContent = d.title + ' (' + d.relPath + ')';
        sel.appendChild(op);
      }
      if (prev) sel.value = prev;
      if (!sel.value && sel.options.length > 0) sel.value = sel.options[0].value;
      renderHelpContent();
    }

    function renderHelpContent() {
      const box = document.getElementById('helpContent');
      const doc = currentHelpDoc();
      if (!doc) {
        box.textContent = 'Belge bulunamadi.';
        return;
      }
      const q = (document.getElementById('helpSearch').value || '').toLowerCase();
      let lines = String(doc.content || '').split(/\r?\n/);
      if (q) {
        lines = lines.filter(x => x.toLowerCase().includes(q));
      }
      box.textContent = lines.join('\n');
    }

    function getNotesForSegment(seg) {
      const n = state.notes && state.notes.notes ? state.notes.notes : { tape: [], data: [], stack: [], queue: [] };
      return Array.isArray(n[seg]) ? n[seg] : [];
    }

    function renderNotes() {
      const wrap = document.getElementById('notesList');
      const seg = document.getElementById('noteSegment').value;
      wrap.innerHTML = '';
      const rows = getNotesForSegment(seg);
      for (const r of rows) {
        const div = document.createElement('div');
        div.className = 'item';
        div.innerHTML = '<b>' + esc(r.cell || '-') + '</b> | ' + esc(r.purpose || '-')
          + '<div class="tiny">' + esc(r.note || '') + '</div>';
        const del = document.createElement('button');
        del.textContent = 'Sil';
        del.addEventListener('click', () => {
          vscode.postMessage({
            cmd: 'deleteNote',
            programRel: state.activeProgramRel,
            segment: seg,
            id: r.id
          });
        });
        div.appendChild(del);
        wrap.appendChild(div);
      }
      if (rows.length === 0) {
        wrap.textContent = 'Bu segmentte not yok.';
      }
    }

    function renderTraceList() {
      const list = document.getElementById('traceList');
      list.innerHTML = '';
      for (let i = 0; i < traceEntries.length; i += 1) {
        const e = traceEntries[i];
        const div = document.createElement('div');
        div.className = 'item' + (i === traceIndex ? ' current' : '');
        let label = '[' + i + '] ';
        if (e.lineNumber) label += 'L' + e.lineNumber + ' ';
        if (e.command) label += e.command + ' | ';
        label += e.raw;
        div.textContent = label;
        div.addEventListener('click', () => moveTrace(i));
        list.appendChild(div);
      }
      updateTraceCurrent();
    }

    function updateTraceCurrent() {
      const cur = document.getElementById('traceCurrent');
      if (traceIndex < 0 || traceIndex >= traceEntries.length) {
        cur.textContent = 'Trace secimi yok.';
        return;
      }
      const e = traceEntries[traceIndex];
      cur.textContent = 'Aktif: index=' + traceIndex + ', line=' + (e.lineNumber || '-') + ', cmd=' + (e.command || '-') + '\n' + (e.raw || '');
    }

    function moveTrace(i) {
      if (traceEntries.length === 0) return;
      traceIndex = Math.max(0, Math.min(i, traceEntries.length - 1));
      renderTraceList();
      const e = traceEntries[traceIndex];
      if (e && e.lineNumber) {
        vscode.postMessage({ cmd: 'traceStep', programRel: state.activeProgramRel, lineNumber: e.lineNumber });
      }
    }

    function startPlay() {
      stopPlay();
      const ms = Math.max(100, Number(document.getElementById('playSpeed').value || 600));
      playTimer = setInterval(() => {
        if (traceEntries.length === 0) return;
        if (traceIndex >= traceEntries.length - 1) {
          stopPlay();
          return;
        }
        moveTrace(traceIndex + 1);
      }, ms);
      document.getElementById('btnPlay').textContent = 'Pause';
    }

    function stopPlay() {
      if (playTimer) clearInterval(playTimer);
      playTimer = null;
      document.getElementById('btnPlay').textContent = 'Play';
    }

    function renderAll() {
      setSummary();
      renderAddresses();
      renderTools();
      renderCommandDocs();
      renderServiceDocs();
      renderHelpDocs();
      renderNotes();
    }

    document.getElementById('btnRefresh').addEventListener('click', () => vscode.postMessage({ cmd: 'requestState' }));
    document.getElementById('btnCompile').addEventListener('click', () => vscode.postMessage({ cmd: 'compile' }));
    document.getElementById('btnRunTests').addEventListener('click', () => vscode.postMessage({ cmd: 'runTests' }));
    document.getElementById('btnRunInterpreter').addEventListener('click', () => vscode.postMessage({ cmd: 'runInterpreter' }));
    document.getElementById('btnClearTrace').addEventListener('click', () => vscode.postMessage({ cmd: 'traceClear' }));
    document.getElementById('btnTraceLoad').addEventListener('click', () => {
      const file = document.getElementById('traceFile').value || 'build/logs/uxm_runtime_trace.log';
      vscode.postMessage({ cmd: 'traceFetch', file });
    });
    document.getElementById('btnPrev').addEventListener('click', () => moveTrace(traceIndex - 1));
    document.getElementById('btnNext').addEventListener('click', () => moveTrace(traceIndex + 1));
    document.getElementById('btnPlay').addEventListener('click', () => {
      if (playTimer) stopPlay();
      else startPlay();
    });

    document.getElementById('toolSelect').addEventListener('change', renderToolInfo);
    document.getElementById('btnRunTool').addEventListener('click', () => {
      const toolPath = document.getElementById('toolSelect').value;
      vscode.postMessage({ cmd: 'runTool', toolPath });
    });

    document.getElementById('cmdSearch').addEventListener('input', renderCommandDocs);
    document.getElementById('svcSearch').addEventListener('input', renderServiceDocs);
    document.getElementById('helpSelect').addEventListener('change', renderHelpContent);
    document.getElementById('helpSearch').addEventListener('input', renderHelpContent);
    document.getElementById('btnOpenHelp').addEventListener('click', () => {
      const doc = currentHelpDoc();
      if (!doc) return;
      vscode.postMessage({ cmd: 'openHelpDoc', relPath: doc.relPath });
    });

    document.getElementById('noteSegment').addEventListener('change', renderNotes);
    document.getElementById('btnSaveNote').addEventListener('click', () => {
      vscode.postMessage({
        cmd: 'saveNote',
        programRel: state.activeProgramRel,
        segment: document.getElementById('noteSegment').value,
        cell: document.getElementById('noteCell').value,
        purpose: document.getElementById('notePurpose').value,
        note: document.getElementById('noteText').value
      });
      document.getElementById('noteText').value = '';
    });

    window.addEventListener('message', (event) => {
      const msg = event.data || {};
      if (msg.type === 'state') {
        state = msg.payload || state;
        renderAll();
      } else if (msg.type === 'traceData') {
        traceEntries = (msg.payload && msg.payload.entries) ? msg.payload.entries : [];
        traceIndex = traceEntries.length > 0 ? 0 : -1;
        renderTraceList();
        if (traceEntries.length > 0) {
          const e = traceEntries[traceIndex];
          if (e && e.lineNumber) {
            vscode.postMessage({ cmd: 'traceStep', programRel: state.activeProgramRel, lineNumber: e.lineNumber });
          }
        }
      } else if (msg.type === 'notesUpdated') {
        if (state) state.notes = msg.payload;
        renderNotes();
      } else if (msg.type === 'actionResult') {
        setJsonOut(msg.payload, msg.payload && msg.payload.ok);
      } else if (msg.type === 'error') {
        setJsonOut({ error: msg.payload && msg.payload.message ? msg.payload.message : 'Bilinmeyen hata' }, false);
      }
    });

    vscode.postMessage({ cmd: 'requestState' });
  </script>
</body>
</html>`;
}

function registerLegacyCommands(context) {
	const map = {
		'uxm.bellekTest': 'bellek_test.bat',
		'uxm.hizliTara': 'hizli_tara.bat',
		'uxm.hataliTest': 'hatali_test.bat -k -D',
		'uxm.tumTest': 'tum_test.bat -k',
		'uxm.derleyiciDerle': 'derleyici_derle.bat',
		'uxm.alanTopla': 'alan_topla.bat',
		'uxm.raporGoster': 'rapor_goster.bat'
	};
	for (const [cmd, bat] of Object.entries(map)) {
		context.subscriptions.push(vscode.commands.registerCommand(cmd, () => {
			const root = getWorkspaceRoot();
			if (!root) {
				vscode.window.showErrorMessage('UXM workspace acik degil.');
				return;
			}
			runTerminalCommand(root, bat);
		}));
	}
}

function activate(context) {
	const output = vscode.window.createOutputChannel('UXM');
	output.appendLine('UXM extension active');
	ensureTraceDecoration(context);

	registerLegacyCommands(context);

	// Compatibility aliases for legacy/legacy-case command names from uxminima
	const ALIAS_COMMANDS = {
		'uxm.opencontrolpanel': 'uxm.openControlPanel',
		'uxm.controlcenter': 'uxm.controlCenter',
		'uxm.opencontrolcenter': 'uxm.controlCenter'
	};
	for (const [alias, target] of Object.entries(ALIAS_COMMANDS)) {
		context.subscriptions.push(vscode.commands.registerCommand(alias, (...args) => {
			return vscode.commands.executeCommand(target, ...args);
		}));
	}

	context.subscriptions.push(vscode.commands.registerCommand('uxm.compile', async () => {
		const root = getWorkspaceRoot();
		if (!root) {
			vscode.window.showErrorMessage('UXM workspace acik degil.');
			return;
		}
		const payload = buildCommandPayload('compile', root);
		const result = await runCommandViaCommThenHttp(root, payload, '/compile', {});
		appendJsonl(root, 'compile', result);
		output.show();
		output.appendLine('[compile] ' + JSON.stringify(result));
		if (activePanel) postPanel(activePanel, 'actionResult', result);
	}));

	context.subscriptions.push(vscode.commands.registerCommand('uxm.runTests', async () => {
		const root = getWorkspaceRoot();
		if (!root) {
			vscode.window.showErrorMessage('UXM workspace acik degil.');
			return;
		}
		const payload = buildCommandPayload('run_tests', root);
		const result = await runCommandViaCommThenHttp(root, payload, '/run', {});
		appendJsonl(root, 'run_tests', result);
		output.show();
		output.appendLine('[runTests] ' + JSON.stringify(result));
		if (activePanel) postPanel(activePanel, 'actionResult', result);
	}));

	context.subscriptions.push(vscode.commands.registerCommand('uxm.controlCenter', () => openControlCenter(context, output)));
	context.subscriptions.push(vscode.commands.registerCommand('uxm.openControlPanel', () => openControlCenter(context, output)));
}

function deactivate() {
	clearTraceHighlight();
}

module.exports = { activate, deactivate };
