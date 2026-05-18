"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UxmInterpreter = void 0;

// Retired compatibility shim.
// Do not use local VSCode interpreter execution in UXM-A.
// Kept to avoid hard-delete of module; authoritative runtime is UXM JSON trace outputs.
class UxmInterpreter {
    run() {
        throw new Error("UxmInterpreter retired: use uxminima.runtimeJsonTrace and UXM runtime/compiler JSON outputs.");
    }
}
exports.UxmInterpreter = UxmInterpreter;
