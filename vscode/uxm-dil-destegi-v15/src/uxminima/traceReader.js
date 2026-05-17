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
exports.readTraceFile = readTraceFile;
exports.ascii = ascii;
const fs = __importStar(require("fs"));
function readTraceFile(filePath) {
    const text = fs.readFileSync(filePath, "utf8");
    const events = [];
    let snapshot;
    let end;
    for (const rawLine of text.split(/\r?\n/)) {
        const line = rawLine.trim();
        if (!line) {
            continue;
        }
        try {
            const obj = JSON.parse(line);
            if (obj.type === "snapshot" || obj.type === "start") {
                snapshot = obj;
            }
            else if (obj.type === "end") {
                end = obj;
            }
            else if (typeof obj.step === "number") {
                events.push(obj);
            }
        }
        catch {
            // Bozuk satırları atla; panel kalan geçerli satırlarla çalışsın.
        }
    }
    return { snapshot, end, events };
}
function ascii(value) {
    if (value >= 32 && value <= 126) {
        return String.fromCharCode(value);
    }
    if (value === 10) {
        return "\\n";
    }
    if (value === 13) {
        return "\\r";
    }
    if (value === 9) {
        return "\\t";
    }
    return "";
}
//# sourceMappingURL=traceReader.js.map