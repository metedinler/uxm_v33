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
exports.UxmDiagnostics = void 0;
const vscode = __importStar(require("vscode"));
const commandBeforeAddress = /([><+\-0\.,\[\]\$%\?!;&\|\^~\{\}eE])\s+\(/g;
const addressWithSpace = /\([^\)]*\s+[^\)]*\)/g;
const metaPattern = /@!?([0-9]+)/g;
const macroPattern = /\bm([0-9]+)\s*=\s*\{/g;
const memoryPattern = /^\s*#memory\s+(.+)$/i;
class UxmDiagnostics {
    constructor(context) {
        this.collection = vscode.languages.createDiagnosticCollection("uxminima");
        context.subscriptions.push(this.collection);
    }
    validate(document) {
        if (document.languageId !== "uxminima" && document.languageId !== "uxm") {
            return;
        }
        const diagnostics = [];
        const text = document.getText();
        for (let lineIndex = 0; lineIndex < document.lineCount; lineIndex++) {
            const line = document.lineAt(lineIndex).text;
            this.validateLine(document, line, lineIndex, diagnostics);
        }
        this.validateGlobal(document, text, diagnostics);
        this.collection.set(document.uri, diagnostics);
    }
    clear(uri) {
        this.collection.delete(uri);
    }
    validateLine(document, line, lineIndex, diagnostics) {
        const trimmed = line.trim();
        if (trimmed.length === 0 || trimmed.startsWith("#")) {
            if (trimmed.toLowerCase().startsWith("#memory")) {
                this.validateMemoryPragma(document, line, lineIndex, diagnostics);
            }
            return;
        }
        for (const match of line.matchAll(commandBeforeAddress)) {
            const start = match.index ?? 0;
            const range = new vscode.Range(lineIndex, start, lineIndex, Math.min(line.length, start + match[0].length));
            diagnostics.push(new vscode.Diagnostic(range, "Komut ile adresleme arasında boşluk yasak. Örnek: 0(T-2)+k10", vscode.DiagnosticSeverity.Error));
        }
        for (const match of line.matchAll(addressWithSpace)) {
            const start = match.index ?? 0;
            const range = new vscode.Range(lineIndex, start, lineIndex, Math.min(line.length, start + match[0].length));
            diagnostics.push(new vscode.Diagnostic(range, "Adresleme parantezi içinde boşluk yasak. Örnek: (T+1), (D:0), (D@T+8), (D@(T-2)+8)", vscode.DiagnosticSeverity.Error));
        }
        const dynamicDataAddress = /\(D@(?:T(?:[+-][0-9]+)?|\(T(?:[+-][0-9]+)?\))(?:[+-][0-9]+)?\)/g;
        for (const match of line.matchAll(dynamicDataAddress)) {
            // Geçerli yeni adresleme modu. Regex burada özellikle bırakıldı ki ileride hover/semantic info eklenebilsin.
            void match;
        }
        for (const match of line.matchAll(metaPattern)) {
            const id = Number(match[1]);
            if (!Number.isInteger(id) || id < 0 || id > 65535) {
                const start = match.index ?? 0;
                diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, start, lineIndex, start + match[0].length), "Meta servis id 0..65535 aralığında olmalı.", vscode.DiagnosticSeverity.Error));
            }
        }
        for (const match of line.matchAll(macroPattern)) {
            const id = Number(match[1]);
            if (id < 128 || id > 255) {
                const start = match.index ?? 0;
                diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, start, lineIndex, start + match[0].length), "Kullanıcı macro id 128..255 aralığında olmalı.", vscode.DiagnosticSeverity.Error));
            }
        }
    }
    validateGlobal(document, text, diagnostics) {
        const loopStack = [];
        for (let i = 0; i < text.length; i++) {
            const c = text[i];
            const pos = document.positionAt(i);
            const lineText = document.lineAt(pos.line).text.trim();
            if (lineText.startsWith("#")) {
                continue;
            }
            if (c === "[") {
                loopStack.push(pos);
            }
            else if (c === "]") {
                if (loopStack.length === 0) {
                    diagnostics.push(new vscode.Diagnostic(new vscode.Range(pos, pos.translate(0, 1)), "Fazla ] bulundu.", vscode.DiagnosticSeverity.Error));
                }
                else {
                    loopStack.pop();
                }
            }
        }
        for (const pos of loopStack) {
            diagnostics.push(new vscode.Diagnostic(new vscode.Range(pos, pos.translate(0, 1)), "Kapanmamış [ döngü başlangıcı.", vscode.DiagnosticSeverity.Error));
        }
    }
    validateMemoryPragma(document, line, lineIndex, diagnostics) {
        const m = line.match(memoryPattern);
        if (!m) {
            return;
        }
        const body = m[1].toLowerCase().replace(/\s+/g, "");
        const getVal = (key) => {
            const r = new RegExp(`${key}=([0-9]+)`).exec(body);
            return r ? Number(r[1]) : undefined;
        };
        const tape = getVal("tape");
        const stack = getVal("stack");
        const data = getVal("data");
        const queue = getVal("queue") ?? getVal("fifo");
        const values = [
            ["tape", tape],
            ["stack", stack],
            ["data", data],
            ["queue", queue]
        ];
        for (const [name, val] of values) {
            if (val !== undefined && (!Number.isFinite(val) || val < 0)) {
                diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, 0, lineIndex, line.length), `#memory ${name} degeri gecersiz.`, vscode.DiagnosticSeverity.Error));
                return;
            }
            if (val !== undefined && val > 16384) {
                diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, 0, lineIndex, line.length), `#memory ${name} 16384 KB ustune cikamaz.`, vscode.DiagnosticSeverity.Error));
            }
        }
        const provided = [tape, stack, data, queue].filter((x) => x !== undefined);
        if (provided.length >= 2) {
            const total = provided.reduce((a, b) => a + Number(b), 0);
            if (total > 16384) {
                diagnostics.push(new vscode.Diagnostic(new vscode.Range(lineIndex, 0, lineIndex, line.length), `#memory toplamı 16384 KB ustune cikamaz. Su an: ${total} KB`, vscode.DiagnosticSeverity.Error));
            }
        }
    }
}
exports.UxmDiagnostics = UxmDiagnostics;
//# sourceMappingURL=diagnostics.js.map