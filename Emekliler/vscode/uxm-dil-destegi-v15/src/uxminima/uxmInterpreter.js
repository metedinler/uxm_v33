"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UxmInterpreter = void 0;

// Retired on 2026-05-18.
// UXM policy: VSCode local interpreter is deprecated.
// Runtime/trace must come from UXM runtime/compiler JSON outputs.
class UxmInterpreter {
    run() {
        throw new Error("Retired module: use UXM runtime/compiler JSON trace outputs instead of VSCode local interpreter.");
    }
}
exports.UxmInterpreter = UxmInterpreter;
