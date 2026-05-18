const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const http = require('http');
const { UxmDiagnostics } = require('./src/uxminima/diagnostics');
const { UxmToolchain } = require('./src/uxminima/toolchain');
const { readTraceFile } = require('./src/uxminima/traceReader');
const { MemoryViewPanel } = require('./src/uxminima/views/memoryView');
const { META_SERVICES, metaMarkdown } = require('./src/uxminima/metaServices');

let activePanel = null;
let activePanelState = null;
let traceDecoration = null;
let uxminimaLastTrace = undefined;
let uxminimaDiagnostics = null;
let uxminimaToolchain = null;

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
	{ token: '>', desc: 'Pointer saga 1 adim gider.' },
	{ token: '<', desc: 'Pointer sola 1 adim gider.' },
	{ token: '>kN / <kN', desc: 'Pointeri N adim saga/sola kaydirir.' },
	{ token: '+', desc: 'Hucreyi artirir.' },
	{ token: '-', desc: 'Hucreyi azaltir.' },
	{ token: '+kN / -kN', desc: 'Hedef hucreyi N kez artirir/azaltir.' },
	{ token: '0', desc: 'Hucreyi sifirlar.' },
	{ token: 'kN', desc: 'Tek basina tekrar belirteci; komutla birlikte kullanilir.' },
	{ token: '.', desc: 'Karakter yazdirir.' },
	{ token: ',', desc: 'Karakter okur.' },
	{ token: '[ ]', desc: 'Aktif hucre sifir olana kadar loop calistirir.' },
	{ token: '$ / %', desc: 'Stack push/pop.' },
	{ token: '? ! ;', desc: 'Karsilastirma operasyonlari.' },
	{ token: '& | ^ ~', desc: 'Bit operasyonlari.' },
	{ token: '{ }', desc: 'Shift operasyonlari.' },
	{ token: 'e', desc: 'Status okur/isler.' },
	{ token: '@N', desc: 'Normal dispatch: mN varsa macro, yoksa host servis cagrisi.' },
	{ token: '@!N', desc: 'Forced host dispatch: dogrudan host servis cagrisi.' },
	{ token: '@# / @!#', desc: 'Dinamik dispatch: servis id aktif hucreden okunur.' },
	{ token: '@(ADDR) / @!(ADDR)', desc: 'Dinamik dispatch: servis id verilen adresten okunur.' },
	{ token: ':', desc: 'Branch ailesi. Kosul ve offset ile atlama yapar.' },
	{ token: 'sN / pN / mN', desc: 'String yazdirma ve macro tanimlari.' }
];

const ADDRESSING_DOCS = [
	{ mode: '(T)', desc: 'Aktif tape hucre.' },
	{ mode: '(T+N)/(T-N)', desc: 'Tape goreli adresleme.' },
	{ mode: '(T:N)', desc: 'Tape mutlak adresleme.' },
	{ mode: '(D:N)', desc: 'Data segment mutlak adresleme.' },
	{ mode: '(S:N)', desc: 'Stack segment mutlak adresleme.' },
	{ mode: '(SP)/(SP+N)/(SP-N)', desc: 'Stack pointer adresleme.' },
	{ mode: '(P)/(E)/(F)', desc: 'Pointer/status/flag register adresleme.' },
	{ mode: '(*T), (*(T+N)), (*(T-N))', desc: 'Dolayli tape adresleme.' },
	{ mode: '(D@T), (D@T+N), (D@T-N)', desc: 'Data indeksleme (tape bazli).' },
	{ mode: '(D@(T+K)+N), (D@(T-K)+N)', desc: 'Goreli tape tabanindan data adresleme.' },
	{ mode: '(D:BASE+P), (T:BASE+P)', desc: 'Base+P adresleme.' },
	{ mode: '(D@D:N), (T@D:N)', desc: 'Cift dolayli adresleme.' }
];

const LOOP_TEMPLATE_DOCS = [
	{ token: '[->+<]', desc: 'Degeri sagdaki hucreye tasir, mevcut hucreyi sifirlar.' },
	{ token: '[<+>-]', desc: 'Degeri soldaki hucreye tasir, mevcut hucreyi sifirlar.' },
	{ token: '[>+>+<<-]', desc: 'Degeri iki hucreye kopyalama kalibi (dagitma).' },
	{ token: '[<+>]', desc: 'Iki hucre arasinda transfer/denge kalibi.' },
	{ token: '{<+>-}', desc: 'Shift komutu ile birlikte kullanimlar icin ornek blok kalibi.' },
	{ token: '::+N / ::-N', desc: 'Kosulsuz branch ile instruction offset kadar atlar.' },
	{ token: ':0+N / :+N / :-N', desc: 'Aktif hucreye gore kosullu branch kaliplari.' },
	{ token: ':z :Z :c :C :o :O :s :S', desc: 'Flag tabanli branch kosullari.' }
];

const MEMORY_MODEL_DOC = {
	title: 'UXM Ana Bellek Modeli',
	defaults: {
		tapeKb: 32,
		stackKb: 4,
		dataKb: 16,
		queueKb: 4
	},
	maxTotalKb: 16384,
	desc: 'Toplam bellek modeli 16 MB siniri ile calisir. Tape/Data/Stack/Queue dagilimi #memory ile ayarlanir.'
};

const SERVICE_DOC_CACHE = new Map();

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

function csvEscape(v) {
	const text = String(v == null ? '' : v);
	if (!/[",\r\n]/.test(text)) return text;
	return '"' + text.replace(/"/g, '""') + '"';
}

function toTurkishServiceNote(note) {
	if (!note) return '';
	let out = String(note);
	out = out.replace(/\bargument\b/gi, 'arguman');
	out = out.replace(/\breturns?\b/gi, 'donus');
	out = out.replace(/\bhandler\b/gi, 'isleyici');
	out = out.replace(/\bdeprecated\b/gi, 'kullanimi azalan');
	out = out.replace(/\breserved\b/gi, 'ayrilmis');
	out = out.replace(/\bdisabled\b/gi, 'kapali');
	out = out.replace(/\bhook\b/gi, 'kanca');
	out = out.replace(/\bdispatch\b/gi, 'yonlendirme');
	return out;
}

function writeServiceCacheCsv(root, rows) {
	const baseDir = path.join(root, '.uxm', 'vscode');
	fs.mkdirSync(baseDir, { recursive: true });
	const outFile = path.join(baseDir, 'service_docs_cache.csv');
	const header = [
		'id',
		'name',
		'family',
		'handler',
		'status',
		'enabled',
		'frame',
		'result',
		'notes_tr',
		'source'
	];
	const lines = [header.join(',')];
	for (const r of rows) {
		lines.push([
			csvEscape(r.id),
			csvEscape(r.name),
			csvEscape(r.family),
			csvEscape(r.handler),
			csvEscape(r.status),
			csvEscape(r.enabled),
			csvEscape(r.frame),
			csvEscape(r.result),
			csvEscape(r.notesTr),
			csvEscape(r.source)
		].join(','));
	}
	fs.writeFileSync(outFile, lines.join('\n'), 'utf8');
}

function loadServiceDocs(root, limit = 50000) {
	const maxRows = limit > 0 ? limit : Number.MAX_SAFE_INTEGER;
	if (SERVICE_DOC_CACHE.has(root)) {
		const cached = SERVICE_DOC_CACHE.get(root);
		return cached.slice(0, maxRows);
	}
	const file = path.join(root, 'config', 'uxm', 'service_registry_merged.csv');
	if (!fs.existsSync(file)) return [];
	const lines = readTextSafe(file).split(/\r?\n/).filter((x) => x.trim() !== '');
	if (lines.length <= 1) return [];
	const header = parseCsvLine(lines[0]);
	const idIdx = header.indexOf('id');
	const nameIdx = header.indexOf('name');
	const familyIdx = header.indexOf('family');
	const handlerIdx = header.indexOf('handler');
	const enabledIdx = header.indexOf('enabled');
	const statusIdx = header.indexOf('status');
	const frameIdx = header.indexOf('frame');
	const resultIdx = header.indexOf('result');
	const sourceIdx = header.indexOf('source');
	const notesIdx = header.indexOf('notes');
	const rows = [];
	for (let i = 1; i < lines.length && rows.length < maxRows; i += 1) {
		const cols = parseCsvLine(lines[i]);
		const idText = idIdx >= 0 ? cols[idIdx] : cols[0];
		const idNum = Number(idText);
		const notes = notesIdx >= 0 ? cols[notesIdx] : '';
		rows.push({
			id: idText,
			idNum: Number.isFinite(idNum) ? idNum : -1,
			name: nameIdx >= 0 ? cols[nameIdx] : '',
			family: familyIdx >= 0 ? cols[familyIdx] : '',
			handler: handlerIdx >= 0 ? cols[handlerIdx] : '',
			enabled: enabledIdx >= 0 ? cols[enabledIdx] : '',
			status: statusIdx >= 0 ? cols[statusIdx] : '',
			frame: frameIdx >= 0 ? cols[frameIdx] : '',
			result: resultIdx >= 0 ? cols[resultIdx] : '',
			notes,
			notesTr: toTurkishServiceNote(notes),
			source: sourceIdx >= 0 ? cols[sourceIdx] : ''
		});
	}
	rows.sort((a, b) => {
		if (a.idNum >= 0 && b.idNum >= 0) return a.idNum - b.idNum;
		return String(a.id).localeCompare(String(b.id));
	});
	SERVICE_DOC_CACHE.set(root, rows);
	try {
		writeServiceCacheCsv(root, rows);
	} catch (_) {
		// Cache dosyasi yazilamazsa panel calismaya devam etsin.
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

function collectScriptTools(root, absDir, out, seen, depth, maxDepth) {
	if (!fs.existsSync(absDir)) return;
	if (depth > maxDepth) return;
	let entries = [];
	try {
		entries = fs.readdirSync(absDir, { withFileTypes: true });
	} catch (_) {
		return;
	}
	for (const entry of entries) {
		const abs = path.join(absDir, entry.name);
		if (entry.isDirectory()) {
			collectScriptTools(root, abs, out, seen, depth + 1, maxDepth);
			continue;
		}
		if (!/\.(bat|py)$/i.test(entry.name)) continue;
		const rel = path.relative(root, abs).replace(/\\/g, '/');
		if (!rel || rel.startsWith('..') || seen.has(rel.toLowerCase())) continue;
		seen.add(rel.toLowerCase());
		const known = KNOWN_TOOL_INFO[entry.name.toLowerCase()] || {};
		out.push({
			id: rel,
			path: rel,
			name: known.name || entry.name,
			purpose: known.purpose || 'Araci calistirir.',
			input: known.input || 'Araca gore degisir.',
			output: known.output || 'Araca gore degisir.'
		});
	}
}

function loadToolCatalog(root) {
	const out = [];
	const seen = new Set();
	const candidates = [
		{ rel: '.', depth: 0 },
		{ rel: 'tools', depth: 2 },
		{ rel: 'araclar', depth: 2 },
		{ rel: 'tools_y', depth: 2 },
		{ rel: 'tool_en', depth: 2 }
	];
	for (const c of candidates) {
		collectScriptTools(root, path.resolve(root, c.rel), out, seen, 0, c.depth);
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
		commandDocs: COMMAND_DOCS.concat(LOOP_TEMPLATE_DOCS),
		addressingDocs: ADDRESSING_DOCS,
		serviceDocs: loadServiceDocs(root),
		helpDocs: loadHelpDocs(root),
		memoryModel: MEMORY_MODEL_DOC,
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
		activePanel.reveal(vscode.ViewColumn.Beside, false);
		postPanel(activePanel, 'state', buildPanelState(root));
		return;
	}

	activePanel = vscode.window.createWebviewPanel(
		'uxmControlCenter',
		'UXM Kontrol Merkezi',
		vscode.ViewColumn.Beside,
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
				case 'uiReady': {
					postPanel(activePanel, 'state', buildPanelState(currentRoot));
					break;
				}
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
				case 'runRuntime':
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
					appendJsonl(currentRoot, 'run_runtime', result);
					output.appendLine('[runRuntime] ' + JSON.stringify(result));
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
	setTimeout(() => {
		if (activePanel) postPanel(activePanel, 'state', buildPanelState(root));
	}, 250);
	setTimeout(() => {
		if (activePanel) postPanel(activePanel, 'state', buildPanelState(root));
	}, 1000);
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
	<div id="statusLine" class="tiny">Durum: baglanti bekleniyor...</div>

  <div class="toolbar">
    <button id="btnRefresh">Yenile</button>
    <button id="btnCompile">Compile</button>
		<button id="btnRunRuntime">UXM Runtime Calistir (JSON)</button>
    <button id="btnRunTests">Toplu Test</button>
    <button id="btnClearTrace">Trace Isareti Temizle</button>
		<button id="btnJumpPlan">Bellek Plani</button>
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
			<div id="cmdDetail" class="mono tiny" style="margin-top:6px"></div>
    </div>
    <div class="card">
      <h3>Servis Rehberi</h3>
      <input id="svcSearch" placeholder="Servis ara (id/family/name)..." />
      <div id="svcList" class="list tiny"></div>
			<div id="svcDetail" class="mono tiny" style="margin-top:6px"></div>
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

	<div class="card" id="planCard" style="margin-top: 10px;">
		<h3>Bellek Plani (Tablo)</h3>
		<div class="tiny">Segment, hucre, amac ve notlar tek tabloda listelenir. Trace secimi ile satira donulebilir.</div>
		<div id="memoryModelInfo" class="tiny" style="margin-top:6px"></div>
		<div class="toolbar">
			<button id="btnPlanTop">Tabloya Git</button>
			<button id="btnPlanRefresh">Tablo Yenile</button>
		</div>
		<div id="memoryPlanTable" class="list tiny"></div>
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
			memoryModel: null,
      notes: { notes: { tape: [], data: [], stack: [], queue: [] } }
    };

    let traceEntries = [];
    let traceIndex = -1;
    let playTimer = null;

    function esc(s) {
      return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    function setSummary() {
			const program = state.activeProgramRel || 'YOK';
			const activeName = program === 'YOK' ? 'YOK' : program.split('/').pop();
			const txt = 'Root: ' + (state.root || '-') + ' | Aktif Program: ' + program + ' | Dosya: ' + activeName;
      document.getElementById('summary').textContent = txt;
    }

		function setStatus(text, ok) {
			const el = document.getElementById('statusLine');
			el.textContent = 'Durum: ' + text;
			el.className = 'tiny ' + (ok === false ? 'status-err' : 'status-ok');
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
			if (!state.tools || state.tools.length === 0) {
				const op = document.createElement('option');
				op.value = '';
				op.textContent = 'Arac bulunamadi';
				sel.appendChild(op);
				renderToolInfo();
				return;
			}
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
			const detail = document.getElementById('cmdDetail');
      list.innerHTML = '';
			detail.textContent = '';
      const all = (state.commandDocs || []).map(x => ({ k: x.token, d: x.desc, type: 'komut' }))
        .concat((state.addressingDocs || []).map(x => ({ k: x.mode, d: x.desc, type: 'adresleme' })));
			let first = null;
      for (const row of all) {
        const text = (row.k + ' ' + row.d + ' ' + row.type).toLowerCase();
        if (q && !text.includes(q)) continue;
				if (!first) first = row;
        const div = document.createElement('div');
        div.className = 'item';
        div.innerHTML = '<b>[' + esc(row.type) + ']</b> ' + esc(row.k) + ' - ' + esc(row.d);
				div.addEventListener('click', () => {
					detail.textContent = '[' + row.type + '] ' + row.k + '\n' + row.d;
				});
        list.appendChild(div);
      }
			if (!first) {
				detail.textContent = 'Eslesen komut yok.';
			} else if (!detail.textContent) {
				detail.textContent = '[' + first.type + '] ' + first.k + '\n' + first.d;
			}
    }

    function renderServiceDocs() {
      const q = (document.getElementById('svcSearch').value || '').toLowerCase();
      const list = document.getElementById('svcList');
			const detail = document.getElementById('svcDetail');
      list.innerHTML = '';
			detail.textContent = '';
			let first = null;
      for (const s of state.serviceDocs || []) {
				const text = (
					String(s.id) + ' '
					+ String(s.name) + ' '
					+ String(s.family) + ' '
					+ String(s.handler) + ' '
					+ String(s.frame) + ' '
					+ String(s.result) + ' '
					+ String(s.status) + ' '
					+ String(s.notesTr || s.notes)
				).toLowerCase();
        if (q && !text.includes(q)) continue;
				if (!first) first = s;
        const div = document.createElement('div');
        div.className = 'item';
				div.innerHTML = '<b>@' + esc(s.id) + '</b> [' + esc(s.family || '-') + '] ' + esc(s.name || '-')
					+ '<div class="tiny">frame=' + esc(s.frame || '-') + ' | result=' + esc(s.result || '-') + '</div>'
					+ '<div class="tiny">status=' + esc(s.status || '-') + ' | handler=' + esc(s.handler || '-') + '</div>';
				div.addEventListener('click', () => {
					detail.textContent = [
						'id: ' + (s.id || '-'),
						'ad: ' + (s.name || '-'),
						'aile: ' + (s.family || '-'),
						'frame: ' + (s.frame || '-'),
						'result: ' + (s.result || '-'),
						'status: ' + (s.status || '-'),
						'enabled: ' + (s.enabled || '-'),
						'handler: ' + (s.handler || '-'),
						'source: ' + (s.source || '-'),
						'aciklama: ' + (s.notesTr || s.notes || '-')
					].join('\n');
				});
        list.appendChild(div);
      }
			if (!first) {
				detail.textContent = 'Eslesen servis yok. ID, aile, ad veya frame bilgisi ile arayabilirsiniz.';
			} else if (!detail.textContent) {
				detail.textContent = 'id: ' + (first.id || '-') + '\naciklama: ' + (first.notesTr || first.notes || '-');
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
					sendCmd('deleteNote', {
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

		function renderMemoryModel() {
			const box = document.getElementById('memoryModelInfo');
			const m = state.memoryModel;
			if (!m || !m.defaults) {
				box.textContent = 'Bellek modeli bilgisi yuklenemedi.';
				return;
			}
			box.textContent = (
				(m.title || 'Bellek modeli') + ' | '
				+ 'Varsayilan: tape=' + m.defaults.tapeKb + 'KB, '
				+ 'data=' + m.defaults.dataKb + 'KB, '
				+ 'stack=' + m.defaults.stackKb + 'KB, '
				+ 'queue=' + m.defaults.queueKb + 'KB | '
				+ 'Toplam ust sinir=' + (m.maxTotalKb || '-') + 'KB'
			);
		}

		function renderMemoryPlan() {
			const box = document.getElementById('memoryPlanTable');
			const notes = state.notes && state.notes.notes ? state.notes.notes : { tape: [], data: [], stack: [], queue: [] };
			const segs = ['tape', 'data', 'stack', 'queue'];
			const rows = [];
			for (const seg of segs) {
				for (const item of (notes[seg] || [])) {
					rows.push({
						segment: seg,
						cell: item.cell || '-',
						purpose: item.purpose || '-',
						note: item.note || '-',
						createdAt: item.createdAt || '-',
						id: item.id || ''
					});
				}
			}
			rows.sort((a, b) => String(a.segment).localeCompare(String(b.segment)) || String(a.cell).localeCompare(String(b.cell)));
			if (rows.length === 0) {
				box.textContent = 'Bellek plani bos. Not ekledikce tablo dolar.';
				return;
			}
			let html = '';
			html += '<div class="item"><b>segment</b> | <b>hucre</b> | <b>amac</b> | <b>not</b> | <b>tarih</b></div>';
			for (const r of rows) {
				html += '<div class="item" data-note-id="' + esc(r.id) + '">'
					+ esc(r.segment) + ' | '
					+ esc(r.cell) + ' | '
					+ esc(r.purpose) + ' | '
					+ esc(r.note) + ' | '
					+ esc(r.createdAt)
					+ '</div>';
			}
			box.innerHTML = html;
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
			renderMemoryPlan();
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
			renderMemoryPlan();
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
			renderMemoryModel();
			renderMemoryPlan();
    }

		function sendCmd(cmd, payload) {
			setStatus('istek gonderildi: ' + cmd, true);
			vscode.postMessage(Object.assign({ cmd }, payload || {}));
		}

		document.getElementById('btnRefresh').addEventListener('click', () => sendCmd('requestState'));
		document.getElementById('btnCompile').addEventListener('click', () => sendCmd('compile'));
		document.getElementById('btnRunTests').addEventListener('click', () => sendCmd('runTests'));
		document.getElementById('btnRunRuntime').addEventListener('click', () => sendCmd('runRuntime'));
		document.getElementById('btnClearTrace').addEventListener('click', () => sendCmd('traceClear'));
    document.getElementById('btnTraceLoad').addEventListener('click', () => {
      const file = document.getElementById('traceFile').value || 'build/logs/uxm_runtime_trace.log';
			sendCmd('traceFetch', { file });
    });
		document.getElementById('btnJumpPlan').addEventListener('click', () => {
			const card = document.getElementById('planCard');
			if (card) card.scrollIntoView({ behavior: 'smooth', block: 'start' });
		});
		document.getElementById('btnPlanTop').addEventListener('click', () => {
			const box = document.getElementById('memoryPlanTable');
			if (box) box.scrollIntoView({ behavior: 'smooth', block: 'start' });
		});
		document.getElementById('btnPlanRefresh').addEventListener('click', () => {
			renderMemoryPlan();
			setStatus('bellek plani yenilendi', true);
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
			sendCmd('runTool', { toolPath });
    });

    document.getElementById('cmdSearch').addEventListener('input', renderCommandDocs);
    document.getElementById('svcSearch').addEventListener('input', renderServiceDocs);
		document.getElementById('cmdSearch').addEventListener('keydown', (ev) => {
			if (ev.key !== 'Enter') return;
			renderCommandDocs();
			const first = document.querySelector('#cmdList .item');
			if (first) first.click();
		});
		document.getElementById('svcSearch').addEventListener('keydown', (ev) => {
			if (ev.key !== 'Enter') return;
			renderServiceDocs();
			const first = document.querySelector('#svcList .item');
			if (first) first.click();
		});
    document.getElementById('helpSelect').addEventListener('change', renderHelpContent);
    document.getElementById('helpSearch').addEventListener('input', renderHelpContent);
    document.getElementById('btnOpenHelp').addEventListener('click', () => {
      const doc = currentHelpDoc();
      if (!doc) return;
      vscode.postMessage({ cmd: 'openHelpDoc', relPath: doc.relPath });
    });

    document.getElementById('noteSegment').addEventListener('change', renderNotes);
    document.getElementById('btnSaveNote').addEventListener('click', () => {
			sendCmd('saveNote', {
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
				setStatus('hazir', true);
        renderAll();
      } else if (msg.type === 'traceData') {
        traceEntries = (msg.payload && msg.payload.entries) ? msg.payload.entries : [];
        traceIndex = traceEntries.length > 0 ? 0 : -1;
				setStatus('trace yuklendi (' + traceEntries.length + ' satir)', true);
        renderTraceList();
        if (traceEntries.length > 0) {
          const e = traceEntries[traceIndex];
          if (e && e.lineNumber) {
            vscode.postMessage({ cmd: 'traceStep', programRel: state.activeProgramRel, lineNumber: e.lineNumber });
          }
        }
      } else if (msg.type === 'notesUpdated') {
        if (state) state.notes = msg.payload;
				setStatus('notlar guncellendi', true);
        renderNotes();
				renderMemoryPlan();
      } else if (msg.type === 'actionResult') {
				setStatus((msg.payload && msg.payload.ok) ? 'islem tamamlandi' : 'islem hata verdi', !!(msg.payload && msg.payload.ok));
        setJsonOut(msg.payload, msg.payload && msg.payload.ok);
      } else if (msg.type === 'error') {
				setStatus(msg.payload && msg.payload.message ? msg.payload.message : 'Bilinmeyen hata', false);
        setJsonOut({ error: msg.payload && msg.payload.message ? msg.payload.message : 'Bilinmeyen hata' }, false);
      }
    });

		vscode.postMessage({ cmd: 'uiReady' });
		vscode.postMessage({ cmd: 'requestState' });
  </script>
</body>
</html>`;
}

function registerCommandWithGuard(context, output, existingSet, commandId, handler) {
	if (existingSet.has(commandId)) {
		if (output) output.appendLine('[cmd] skip ' + commandId + ' (already registered)');
		return;
	}
	context.subscriptions.push(vscode.commands.registerCommand(commandId, handler));
	existingSet.add(commandId);
}

function activeUxmDocument() {
	const editor = vscode.window.activeTextEditor;
	if (!editor) {
		vscode.window.showWarningMessage('Aktif editor yok.');
		return undefined;
	}
	const languageId = editor.document.languageId;
	const isUxm = languageId === 'uxm' || languageId === 'uxminima';
	const isUxmExt = path.extname(editor.document.fileName).toLowerCase() === '.uxm';
	if (!isUxm && !isUxmExt) {
		vscode.window.showWarningMessage('Aktif dosya .uxm degil.');
		return undefined;
	}
	return editor.document;
}

function isUxmLikeDocument(document) {
	if (!document) return false;
	if (document.languageId === 'uxm' || document.languageId === 'uxminima') return true;
	const fileName = String(document.fileName || '').toLowerCase();
	return fileName.endsWith('.uxm');
}

async function openIfExists(filePath, viewColumn) {
	if (!fs.existsSync(filePath)) {
		vscode.window.showWarningMessage('Dosya bulunamadi: ' + filePath);
		return;
	}
	const uri = vscode.Uri.file(filePath);
	await vscode.window.showTextDocument(uri, { preview: false, viewColumn });
}

function findServiceDoc(root, id) {
	if (!root) return null;
	const rows = loadServiceDocs(root, 0);
	for (const row of rows) {
		if (row.idNum === id) return row;
		if (Number(row.id) === id) return row;
	}
	return null;
}

function buildServiceHoverText(row) {
	if (!row) return 'Servis kaydi bulunamadi. Ayrintilar: config/uxm/service_registry_merged.csv';
	const lines = [];
	lines.push('Servis @' + row.id + ' - ' + (row.name || '-'));
	lines.push('Aile: ' + (row.family || '-'));
	lines.push('Frame: ' + (row.frame || '-'));
	lines.push('Result: ' + (row.result || '-'));
	lines.push('Status: ' + (row.status || '-'));
	lines.push('Enabled: ' + (row.enabled || '-'));
	lines.push('Handler: ' + (row.handler || '-'));
	if (row.notesTr || row.notes) lines.push('Aciklama: ' + (row.notesTr || row.notes));
	if (row.source) lines.push('Kaynak: ' + row.source);
	return lines.join('\n');
}

function metaHelpMarkdown(root) {
	const docs = root ? loadServiceDocs(root, 600) : [];
	if (docs.length > 0) {
		const rows = docs.map((m) => (
			'| @' + m.id + ' | '
			+ (m.name || '-') + ' | '
			+ '`' + (m.frame || '-') + '` | '
			+ '`' + (m.result || '-') + '` | '
			+ (m.status || '-') + ' | '
			+ (m.notesTr || m.notes || '-') + ' |'
		)).join('\n');
		return '# UXM Meta Servisleri (Birlesik Registry)\n\n'
			+ 'Servis ID araligi bu surumde **0..65535** olarak ele alinmalidir.\n\n'
			+ '| Meta | Ad | Frame | Result | Durum | Aciklama |\n'
			+ '|---|---|---|---|---|---|\n'
			+ rows + '\n\n'
			+ 'Tam registry: `config/uxm/service_registry_merged.csv`\n\n'
			+ 'VSCode cache: `.uxm/vscode/service_docs_cache.csv`\n\n'
			+ '## Host meta zorlamasi\n\n'
			+ '`@!N` macro aramasini bypass ederek dogrudan host/runtime servisini cagirir.\n\n'
			+ '## UXM-A standart meta formlari\n\n'
			+ '`@N`, `@!N`, `@#`, `@!#`, `@(ADDR)`, `@!(ADDR)`\n\n'
			+ '`@#N`, `@@N`, `@*` formlari kullanilmaz.\n\n'
			+ '## Kullanici macro alani\n\n'
			+ '@128..@255 kullanici macro alanidir.\n';
	}
	const rows = Object.values(META_SERVICES)
		.sort((a, b) => a.id - b.id)
		.map((m) => '| @' + m.id + ' | ' + m.name + ' | `' + m.frame + '` | ' + m.description + ' |')
		.join('\n');
	return '# UX-MINIMA Meta Servisleri\n\n'
		+ '| Meta | Ad | Frame | Aciklama |\n'
		+ '|---|---|---|---|\n'
		+ rows + '\n\n'
		+ 'Servis ID araligi: 0..65535 (registry tabanli).\n\n'
		+ 'UXM-A standart meta formlari: `@N`, `@!N`, `@#`, `@!#`, `@(ADDR)`, `@!(ADDR)`.\n'
		+ '`@#N`, `@@N`, `@*` kullanilmaz.\n';
}

async function runFinalAndOpen(context, output, mode) {
	const doc = activeUxmDocument();
	if (!doc || !uxminimaToolchain) return;
	await doc.save();
	try {
		const art = mode === 'all'
			? await uxminimaToolchain.finalRunAll(doc.fileName)
			: mode === 'step'
				? await uxminimaToolchain.finalRunStep(doc.fileName)
				: await uxminimaToolchain.finalRunTrace(doc.fileName);
		uxminimaLastTrace = fs.existsSync(art.trace) ? readTraceFile(art.trace) : undefined;
		if (uxminimaLastTrace) {
			MemoryViewPanel.show(context, uxminimaLastTrace);
		}
		output.appendLine('\n[Final ' + mode + '] ' + doc.fileName);
		if (uxminimaLastTrace && uxminimaLastTrace.end && uxminimaLastTrace.end.output) {
			output.appendLine(uxminimaLastTrace.end.output);
		}
		output.show(true);
		vscode.window.showInformationMessage('Final ' + mode + ' tamamlandi: ' + art.trace);
	} catch (err) {
		vscode.window.showErrorMessage(String(err));
	}
}

async function registerLegacyCommands(context, output) {
	const map = {
 		'uxm.bellekTest': 'bellek_test.bat',
 		'uxm.hizliTara': 'hizli_tara.bat',
 		'uxm.hataliTest': 'hatali_test.bat -k -D',
 		'uxm.tumTest': 'tum_test.bat -k',
 		'uxm.derleyiciDerle': 'derleyici_derle.bat',
 		'uxm.alanTopla': 'alan_topla.bat',
 		'uxm.raporGoster': 'rapor_goster.bat'
 	};

	let existing = [];
	try {
		existing = await vscode.commands.getCommands(true);
	} catch (e) {
		if (output) output.appendLine('[legacy] getCommands failed: ' + String(e));
	}

	for (const [cmd, bat] of Object.entries(map)) {
		if (existing.includes(cmd)) {
			if (output) output.appendLine(`[legacy] skip registering ${cmd} (already registered)`);
			continue;
		}
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


async function activate(context) {
	const output = vscode.window.createOutputChannel('UXM');
	output.appendLine('UXM extension active');
	ensureTraceDecoration(context);

	uxminimaDiagnostics = new UxmDiagnostics(context);
	uxminimaToolchain = new UxmToolchain(output, context);
	for (const doc of vscode.workspace.textDocuments) {
		uxminimaDiagnostics.validate(doc);
	}
	context.subscriptions.push(vscode.workspace.onDidOpenTextDocument((doc) => {
		if (uxminimaDiagnostics) uxminimaDiagnostics.validate(doc);
	}));
	context.subscriptions.push(vscode.workspace.onDidChangeTextDocument((e) => {
		if (uxminimaDiagnostics) uxminimaDiagnostics.validate(e.document);
	}));
	context.subscriptions.push(vscode.workspace.onDidCloseTextDocument((doc) => {
		if (uxminimaDiagnostics) uxminimaDiagnostics.clear(doc.uri);
	}));

	await registerLegacyCommands(context, output);

	// Compatibility aliases for legacy/legacy-case command names from uxminima
	const ALIAS_COMMANDS = {
		'uxm.opencontrolpanel': 'uxm.openControlPanel',
		'uxm.controlcenter': 'uxm.controlCenter',
		'uxm.opencontrolcenter': 'uxm.controlCenter'
	};
	let existing = [];
	try { existing = await vscode.commands.getCommands(true); } catch (_) { existing = []; }
	const existingSet = new Set(existing);
	for (const [alias, target] of Object.entries(ALIAS_COMMANDS)) {
		registerCommandWithGuard(context, output, existingSet, alias, (...args) => {
			return vscode.commands.executeCommand(target, ...args);
		});
	}

	// Hover provider: komut, pragma, servis ve adresleme bilgileri
	{
		const HOVER_MAP = new Map();
		for (const it of COMMAND_DOCS) HOVER_MAP.set(it.token, it.desc);
		for (const it of ADDRESSING_DOCS) HOVER_MAP.set(it.mode, it.desc);
		for (const it of LOOP_TEMPLATE_DOCS) HOVER_MAP.set(it.token, it.desc);
		HOVER_MAP.set('@N', 'Meta servis cagirir. Ornek: @20');
		HOVER_MAP.set('@!N', 'Host zorlamali meta servis cagirir. Ornek: @!20');
		HOVER_MAP.set('@#', 'Dinamik meta cagrisi.');
		HOVER_MAP.set('@!#', 'Host zorlamali dinamik meta cagrisi (T hucresindeki id).');
		HOVER_MAP.set('@(addr)', 'Adresten dinamik meta cagrisi.');
		HOVER_MAP.set('@!(addr)', 'Host zorlamali, adresten dinamik meta cagrisi.');
		HOVER_MAP.set(':', 'Branch ailesi (ornek: :0+3, ::-2, :z+1).');
		HOVER_MAP.set('#mode', 'Pragma: #mode safe|normal|wild');
		HOVER_MAP.set('#cell', 'Pragma: #cell byte|word|dword');
		HOVER_MAP.set('#memory', 'Pragma: #memory tape=<KB> data=<KB> stack=<KB> queue=<KB>');

		for (const hoverLang of ['uxm', 'uxminima']) {
			context.subscriptions.push(vscode.languages.registerHoverProvider(hoverLang, {
				provideHover(document, position) {
					const tokenRegex = /\([^\)\s]+\)|@!?\([^\)\s]+\)|@!?#|@!?\d+|@!?#\d+|@@\d+|@\*|:\w[\w\-]*|[><+\-]k\d+|k\d+|s\d+|p\d+|m\d+|#[A-Za-z0-9_\-]+|[><+\-0\.,\[\]\$%\?;!&\|\^~\{\}eE]/;
					const range = document.getWordRangeAtPosition(position, tokenRegex);
					if (!range) return null;
					const word = document.getText(range);

					if (word.startsWith('(') && word.endsWith(')')) {
						const normalized = word.replace(/\d+/g, 'N');
						for (const [k, v] of HOVER_MAP.entries()) {
							if (k === normalized || k.indexOf(normalized) !== -1) {
								return new vscode.Hover(v);
							}
						}
						return new vscode.Hover(ADDRESSING_DOCS.map((x) => x.mode + ' - ' + x.desc).join('\n'));
					}

					if (HOVER_MAP.has(word)) return new vscode.Hover(HOVER_MAP.get(word));

					const repeatMatch = /^([><+\-])k(\d+)$/.exec(word);
					if (repeatMatch) {
						const op = repeatMatch[1];
						const n = Number(repeatMatch[2]);
						if (op === '>') return new vscode.Hover('`>k' + n + '` pointeri saga ' + n + ' adim tasir.');
						if (op === '<') return new vscode.Hover('`<k' + n + '` pointeri sola ' + n + ' adim tasir.');
						if (op === '+') return new vscode.Hover('`+k' + n + '` hedef hucreyi ' + n + ' kez artirir.');
						if (op === '-') return new vscode.Hover('`-k' + n + '` hedef hucreyi ' + n + ' kez azaltir.');
					}

					if (/^k\d+$/.test(word)) {
						return new vscode.Hover('Tekrar belirteci. `kN`, onundeki komutun N kez uygulanacagini belirtir.');
					}

					if (/^s\d+/.test(word)) return new vscode.Hover('String tanimlama: sN=start,{text}');
					if (/^p\d+/.test(word)) return new vscode.Hover('Onceden tanimli string cagrisi: pN');
					if (/^m\d+/.test(word)) return new vscode.Hover('Macro tanimlama: mN={...} (N:128..255)');

					if (/^@!?#\d+$/.test(word)) {
						return new vscode.Hover('Gecersiz UXM-A formu: ' + word + '. Dogrusu: @# veya @!# (N olmadan).');
					}
					if (/^@@\d+$/.test(word)) {
						return new vscode.Hover('Gecersiz UXM-A formu: @@N. Dogrusu: @N veya @!N.');
					}
					if (word === '@*') {
						return new vscode.Hover('Gecersiz UXM-A formu: @*. Dogrusu: @#, @!#, @(ADDR) veya @!(ADDR).');
					}
					if (word === '@#' || word === '@!#') {
						return new vscode.Hover('Dinamik meta cagrisi. Servis id T hucresinden okunur' + (word.startsWith('@!') ? ' ve host zorlamasi uygulanir.' : '.'));
					}
					if (/^@!?\([^\)]+\)$/.test(word)) {
						return new vscode.Hover('Dinamik meta cagrisi. Servis id verilen adresten okunur' + (word.startsWith('@!') ? ' ve host zorlamasi uygulanir.' : '.') + '');
					}

					if (/^@!?\d+$/.test(word)) {
						const raw = word.replace(/^@!/, '@');
						const id = Number(raw.slice(1));
						if (!Number.isNaN(id)) {
							if (id < 0 || id > 65535) {
								return new vscode.Hover('Gecersiz servis ID: ' + id + '. Gecerli aralik 0..65535.');
							}
							const root = getWorkspaceRoot();
							const row = findServiceDoc(root, id);
							if (row) return new vscode.Hover(buildServiceHoverText(row));
							return new vscode.Hover(metaMarkdown(id) + '\n\nRegistry: config/uxm/service_registry_merged.csv');
						}
						return new vscode.Hover('Meta servis cagrisi. Registry: config/uxm/service_registry_merged.csv');
					}

					if (/^#/.test(word)) {
						const key = word.split(/[\s=]/)[0];
						switch (key) {
							case '#mode': return new vscode.Hover('Pragma: #mode safe|normal|wild');
							case '#cell': return new vscode.Hover('Pragma: #cell byte|word|dword');
							case '#bounds': return new vscode.Hover('Pragma: #bounds on|off');
							case '#overflow': return new vscode.Hover('Pragma: #overflow check|wrap');
							case '#endian': return new vscode.Hover('Pragma: #endian big|little');
							case '#memory': {
								const d = MEMORY_MODEL_DOC.defaults;
								return new vscode.Hover(
									'Memory modeli: tape=' + d.tapeKb + 'KB, data=' + d.dataKb + 'KB, stack=' + d.stackKb + 'KB, queue=' + d.queueKb + 'KB. '
									+ 'Toplam ust sinir: ' + MEMORY_MODEL_DOC.maxTotalKb + 'KB.'
								);
							}
							default: return new vscode.Hover('Pragma detayi icin PCK.md ve UXM kilavuzlarina bakin.');
						}
					}
					return null;
				}
			}));
		}

		for (const lang of ['uxm', 'uxminima']) {
			context.subscriptions.push(vscode.languages.registerCompletionItemProvider(lang, {
				provideCompletionItems() {
					const items = [];
					for (const tpl of LOOP_TEMPLATE_DOCS) {
						const ci = new vscode.CompletionItem(tpl.token, vscode.CompletionItemKind.Snippet);
						ci.detail = 'UXM loop/branch kalibi';
						ci.documentation = tpl.desc;
						items.push(ci);
					}
					for (const t of ['+kN', '-kN', '>kN', '<kN', ':0+N', ':0-N', ':+N', ':-N', '::+N', '::-N', ':z+N', ':z-N', ':Z+N', ':Z-N', ':c+N', ':c-N', ':C+N', ':C-N', ':o+N', ':o-N', ':O+N', ':O-N', ':s+N', ':s-N', ':S+N', ':S-N']) {
						const ci = new vscode.CompletionItem(t, vscode.CompletionItemKind.Keyword);
						ci.detail = 'UXM hizli kalip';
						items.push(ci);
					}
					for (const t of ['@N', '@!N', '@#', '@!#', '@(ADDR)', '@!(ADDR)']) {
						const ci = new vscode.CompletionItem(t, vscode.CompletionItemKind.Function);
						ci.detail = 'UXM-A meta kalibi';
						items.push(ci);
					}
					return items;
				}
			}, '[', ':', '@', 'k'));
		}
	}

	registerCommandWithGuard(context, output, existingSet, 'uxm.compile', async () => {
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
	});

	registerCommandWithGuard(context, output, existingSet, 'uxm.runTests', async () => {
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
	});

	registerCommandWithGuard(context, output, existingSet, 'uxm.controlCenter', () => openControlCenter(context, output));
	registerCommandWithGuard(context, output, existingSet, 'uxm.openControlPanel', () => openControlCenter(context, output));

	let autoOpenBusy = false;
	const maybeAutoOpenControlCenter = async (editor) => {
		if (autoOpenBusy) return;
		if (!editor || !isUxmLikeDocument(editor.document)) return;
		if (!getWorkspaceRoot()) return;

		if (activePanel) {
			if (activePanelState && activePanelState.root) {
				postPanel(activePanel, 'state', buildPanelState(activePanelState.root));
			}
			return;
		}

		autoOpenBusy = true;
		try {
			await openControlCenter(context, output);
		} catch (e) {
			output.appendLine('[auto-open] ' + String(e));
		} finally {
			autoOpenBusy = false;
		}
	};

	context.subscriptions.push(vscode.window.onDidChangeActiveTextEditor((editor) => {
		void maybeAutoOpenControlCenter(editor);
	}));

	void maybeAutoOpenControlCenter(vscode.window.activeTextEditor);

	registerCommandWithGuard(context, output, existingSet, 'uxminima.validateFile', () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaDiagnostics) return;
		uxminimaDiagnostics.validate(doc);
		vscode.window.showInformationMessage('UX-MINIMA dosyasi dogrulandi.');
	});

	const runRuntimeJsonTrace = async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.finalRunTrace(doc.fileName);
			uxminimaLastTrace = readTraceFile(art.trace);
			MemoryViewPanel.show(context, uxminimaLastTrace);
			output.appendLine('\n[Runtime JSON Trace] ' + doc.fileName);
			output.appendLine('Kaynak: ' + art.trace);
			output.show(true);
			vscode.window.showInformationMessage('VSCode local interpreter kapali. Runtime JSON trace acildi: ' + art.trace);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	};

	registerCommandWithGuard(context, output, existingSet, 'uxminima.runtimeJsonTrace', runRuntimeJsonTrace);
	registerCommandWithGuard(context, output, existingSet, 'uxminima.internalTrace', runRuntimeJsonTrace);

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalBuildCompiler', async () => {
		if (!uxminimaToolchain) return;
		try {
			const exe = await uxminimaToolchain.buildFinalCompiler();
			vscode.window.showInformationMessage('Final ARGE compiler uretildi: ' + exe);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalRunAll', async () => {
		await runFinalAndOpen(context, output, 'all');
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalRunTrace', async () => {
		await runFinalAndOpen(context, output, 'trace');
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalRunStep', async () => {
		await runFinalAndOpen(context, output, 'step');
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalCompileAsm', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.finalCompileAsm(doc.fileName);
			await openIfExists(art.asm, vscode.ViewColumn.Beside);
			vscode.window.showInformationMessage('ASM uretildi: ' + art.asm);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalExportUIR', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.finalExportUIR(doc.fileName);
			await openIfExists(art.uir, vscode.ViewColumn.Beside);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalExportDiagnostics', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.finalExportDiagnostics(doc.fileName);
			await openIfExists(art.diag, vscode.ViewColumn.Beside);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.finalExportOPT', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.finalExportOPT(doc.fileName);
			await openIfExists(art.opt, vscode.ViewColumn.Beside);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.runTrace', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.runTrace(doc.fileName);
			uxminimaLastTrace = readTraceFile(art.trace);
			MemoryViewPanel.show(context, uxminimaLastTrace);
			vscode.window.showInformationMessage('Trace uretildi: ' + art.trace);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.exportUIR', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.exportUIR(doc.fileName);
			await openIfExists(art.uir, vscode.ViewColumn.Beside);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.exportOPT', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.exportOPT(doc.fileName);
			await openIfExists(art.opt, vscode.ViewColumn.Beside);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.buildNative', async () => {
		const doc = activeUxmDocument();
		if (!doc || !uxminimaToolchain) return;
		await doc.save();
		try {
			const art = await uxminimaToolchain.buildNative(doc.fileName);
			vscode.window.showInformationMessage('Native EXE uretildi: ' + art.exe);
		} catch (err) {
			vscode.window.showErrorMessage(String(err));
		}
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.openMemoryWatch', () => {
		MemoryViewPanel.show(context, uxminimaLastTrace || { events: [] });
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.openMetaHelp', async () => {
		const doc = await vscode.workspace.openTextDocument({
			language: 'markdown',
			content: metaHelpMarkdown(getWorkspaceRoot())
		});
		await vscode.window.showTextDocument(doc, { preview: false, viewColumn: vscode.ViewColumn.Beside });
	});

	registerCommandWithGuard(context, output, existingSet, 'uxminima.openFinalDocs', async () => {
		const root = getWorkspaceRoot();
		const candidates = [path.join(context.extensionPath, 'docs', 'UXM31_FINAL_ARGE_COMPILER.md')];
		if (root) candidates.push(path.join(root, 'docs', 'UXM31_FINAL_ARGE_COMPILER.md'));
		const found = candidates.find((x) => fs.existsSync(x));
		if (!found) {
			vscode.window.showWarningMessage('Final ARGE dokumani bulunamadi.');
			return;
		}
		await openIfExists(found, vscode.ViewColumn.Beside);
	});

}

function deactivate() {
	clearTraceHighlight();
}

module.exports = { activate, deactivate };
