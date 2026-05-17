"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.MemoryViewPanel = void 0;
const vscode = __importStar(require("vscode"));
class MemoryViewPanel {
    constructor(panel) {
        this.panel = panel;
        this.panel.onDidDispose(() => { MemoryViewPanel.current = undefined; });
    }
    static show(context, trace) {
        if (MemoryViewPanel.current) {
            MemoryViewPanel.current.panel.reveal(vscode.ViewColumn.Beside);
            if (trace) {
                MemoryViewPanel.current.update(trace);
            }
            return MemoryViewPanel.current;
        }
        const panel = vscode.window.createWebviewPanel("uxminimaMemoryWatch", "UX-MINIMA Memory Watch", vscode.ViewColumn.Beside, { enableScripts: true, retainContextWhenHidden: true });
        const instance = new MemoryViewPanel(panel);
        MemoryViewPanel.current = instance;
        instance.update(trace ?? { events: [] });
        return instance;
    }
    update(trace) {
        this.trace = trace;
        this.panel.webview.html = this.html(trace);
    }
    html(trace) {
        const events = trace.events;
        const encoded = JSON.stringify(events).replace(/</g, "\\u003c");
        const first = events[0];
        const summary = trace.snapshot ? JSON.stringify(trace.snapshot) : "No snapshot";
        const endOutput = trace.end?.output ?? "";
        const encodedEndOutput = JSON.stringify(endOutput).replace(/</g, "\\u003c");
        return `<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<style>
  body { font-family: var(--vscode-font-family); color: var(--vscode-foreground); background: var(--vscode-editor-background); padding: 12px; }
  h2 { margin: 0 0 8px 0; }
  .bar { display: flex; gap: 8px; align-items: center; margin: 8px 0 12px 0; flex-wrap: wrap; }
  button { color: var(--vscode-button-foreground); background: var(--vscode-button-background); border: 0; padding: 6px 10px; border-radius: 3px; cursor: pointer; }
  button:hover { background: var(--vscode-button-hoverBackground); }
  input[type=range] { width: 280px; }
  .grid { display: grid; grid-template-columns: repeat(2, minmax(260px, 1fr)); gap: 12px; }
  .card { border: 1px solid var(--vscode-panel-border); border-radius: 6px; padding: 10px; background: var(--vscode-sideBar-background); }
  .mono { font-family: var(--vscode-editor-font-family); font-size: var(--vscode-editor-font-size); white-space: pre-wrap; }
  table { width: 100%; border-collapse: collapse; font-family: var(--vscode-editor-font-family); font-size: 12px; }
  th, td { border-bottom: 1px solid var(--vscode-panel-border); padding: 3px 5px; text-align: left; }
  .ptr { background: var(--vscode-editor-selectionBackground); }
  .bad { color: var(--vscode-errorForeground); font-weight: bold; }
  .ok { color: var(--vscode-testing-iconPassed); }
  .small { opacity: .8; font-size: 12px; }
</style>
</head>
<body>
  <h2>UX-MINIMA Memory Watch</h2>
  <div class="small">Snapshot: ${escapeHtml(summary)}</div>
  <div class="bar">
    <button id="first">⏮</button>
    <button id="prev">◀</button>
    <button id="next">▶</button>
    <button id="last">⏭</button>
    <input id="slider" type="range" min="0" max="${Math.max(0, events.length - 1)}" value="0" />
    <span id="stepLabel">0 / ${events.length}</span>
  </div>
  <div id="empty" ${first ? "style='display:none'" : ""}>Trace yok. Önce <b>UX-MINIMA: Internal Trace & Memory Watch</b> veya <b>Run Trace with Toolchain</b> çalıştır.</div>
  <div class="grid" id="content" ${first ? "" : "style='display:none'"}>
    <div class="card"><h3>Current Step</h3><div id="current" class="mono"></div></div>
    <div class="card"><h3>Flags / Status</h3><div id="flags" class="mono"></div></div>
    <div class="card"><h3>Tape Window</h3><div id="tape"></div></div>
    <div class="card"><h3>Stack</h3><div id="stack"></div></div>
    <div class="card"><h3>FIFO</h3><div id="fifo"></div></div>
    <div class="card"><h3>Data Non-Zero</h3><div id="data"></div></div>
    <div class="card" style="grid-column: 1 / -1"><h3>Output</h3><div id="output" class="mono"></div></div>
  </div>
<script>
const events = ${encoded};
const endOutput = ${encodedEndOutput};
let idx = 0;
const byId = id => document.getElementById(id);
function esc(s) { return String(s ?? '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch])); }
function ascii(v) { if (v >= 32 && v <= 126) return String.fromCharCode(v); if (v === 10) return '\\n'; if (v === 13) return '\\r'; if (v === 9) return '\\t'; return ''; }
function table(cells, ptr) {
  if (!cells || !cells.length) return '<div class="small">Bu trace satırında hücre snapshot yok. Final compiler trace satırında current/ptr bilgisi varsa Current Step kartını kullan.</div>';
  return '<table><thead><tr><th>Index</th><th>Value</th><th>ASCII</th></tr></thead><tbody>' + cells.map(c =>
    '<tr class="' + (c.index === ptr ? 'ptr' : '') + '"><td>' + c.index + '</td><td>' + c.value + '</td><td>' + esc(c.ascii || ascii(c.value)) + '</td></tr>'
  ).join('') + '</tbody></table>';
}
function flagsText(flags) {
  const names = [['Z',1],['C',2],['O',4],['S',8],['SGN',16],['END',32],['WILD',64],['BND',128],['TRC',256],['FIFO',512],['ERR',1024],['DIRTY',2048],['PCHG',4096]];
  return names.map(([n,b]) => n + '=' + ((flags & b) ? '1' : '0')).join('  ');
}
function render() {
  if (!events.length) return;
  if (idx < 0) idx = 0; if (idx >= events.length) idx = events.length - 1;
  const e = events[idx];
  byId('slider').value = String(idx);
  byId('stepLabel').textContent = (idx + 1) + ' / ' + events.length;
  byId('current').textContent = 'step=' + e.step + '\\nip=' + e.ip + '\\nop=' + e.op + '\\nsrc=' + (e.src || '') + '\\nptr=' + e.ptr + '\\nsp=' + e.sp + '\\nfifo_count=' + e.fifo_count + '\\ncurrent=' + e.current + (e.meta_id !== undefined ? '\\nmeta_id=' + e.meta_id : '');
  byId('flags').innerHTML = '<div>Status: <span class="' + (e.status ? 'bad' : 'ok') + '">' + e.status + '</span></div><div class="mono">' + esc(flagsText(e.flags || 0)) + '</div>';
  const syntheticTape = e.tape || [{ index: e.ptr, value: e.current, ascii: ascii(e.current) }];
  byId('tape').innerHTML = table(syntheticTape, e.ptr);
  byId('stack').innerHTML = table(e.stack, -1);
  byId('fifo').innerHTML = table(e.fifo, -1);
  byId('data').innerHTML = table(e.data, -1);
  byId('output').textContent = e.output || endOutput || '';
}
byId('first').onclick = () => { idx = 0; render(); };
byId('prev').onclick = () => { idx--; render(); };
byId('next').onclick = () => { idx++; render(); };
byId('last').onclick = () => { idx = events.length - 1; render(); };
byId('slider').oninput = e => { idx = Number(e.target.value); render(); };
render();
</script>
</body>
</html>`;
    }
}
exports.MemoryViewPanel = MemoryViewPanel;
function escapeHtml(s) {
    return s.replace(/[&<>"']/g, ch => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[ch] ?? ch));
}
//# sourceMappingURL=memoryView.js.map