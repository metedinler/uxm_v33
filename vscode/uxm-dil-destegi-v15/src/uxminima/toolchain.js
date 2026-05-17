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
exports.UxmToolchain = void 0;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const fs = __importStar(require("fs"));
const child_process_1 = require("child_process");
class UxmToolchain {
    constructor(output, context) {
        this.output = output;
        this.context = context;
    }
    getPaths() {
        const cfg = vscode.workspace.getConfiguration("uxminima");
        const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? process.cwd();
        const buildDirSetting = cfg.get("buildDirectory", "build");
        return {
            fullTool: this.resolveTool(cfg.get("fullToolPath", "uxm31_full_tool.exe"), root),
            compiler: this.resolveTool(cfg.get("compilerPath", "uxm31_compiler_full.exe"), root),
            finalCompiler: this.resolveTool(cfg.get("finalCompilerPath", "uxm31_compiler_final.exe"), root),
            finalCompilerSource: this.resolveTool(cfg.get("finalCompilerSourcePath", "uxm31_compiler_final.bas"), root),
            runtime: this.resolveTool(cfg.get("runtimePath", "uxm31_runtime_fb_full.bas"), root),
            nasm: cfg.get("nasmPath", "nasm"),
            fbc: cfg.get("fbcPath", "fbc"),
            buildDir: path.isAbsolute(buildDirSetting) ? buildDirSetting : path.join(root, buildDirSetting),
            autoBuildFinalCompiler: cfg.get("autoBuildFinalCompiler", true),
            maxSteps: cfg.get("maxSteps", 1000)
        };
    }
    artifactsFor(sourceFile) {
        const paths = this.getPaths();
        const baseName = path.basename(sourceFile, path.extname(sourceFile));
        if (!fs.existsSync(paths.buildDir)) {
            fs.mkdirSync(paths.buildDir, { recursive: true });
        }
        return {
            source: sourceFile,
            baseName,
            buildDir: paths.buildDir,
            asm: path.join(paths.buildDir, `${baseName}.asm`),
            obj: path.join(paths.buildDir, `${baseName}.obj`),
            exe: path.join(paths.buildDir, `${baseName}.exe`),
            trace: path.join(paths.buildDir, `${baseName}.trace.ndjson`),
            uir: path.join(paths.buildDir, `${baseName}.uir.json`),
            opt: path.join(paths.buildDir, `${baseName}.opt.json`),
            diag: path.join(paths.buildDir, `${baseName}.diag.json`),
            ideRequest: path.join(paths.buildDir, `${baseName}.ide.request.json`),
            ideResponse: path.join(paths.buildDir, `${baseName}.ide.response.json`)
        };
    }
    async buildFinalCompiler() {
        const paths = this.getPaths();
        if (!fs.existsSync(paths.finalCompilerSource)) {
            throw new Error(`Final compiler source bulunamadı: ${paths.finalCompilerSource}`);
        }
        await this.run(paths.fbc, [paths.finalCompilerSource, "-x", paths.finalCompiler], "Build Final ARGE Compiler");
        return paths.finalCompiler;
    }
    async ensureFinalCompiler() {
        const paths = this.getPaths();
        if (!paths.autoBuildFinalCompiler) {
            return paths.finalCompiler;
        }
        const exeExists = fs.existsSync(paths.finalCompiler);
        const srcExists = fs.existsSync(paths.finalCompilerSource);
        if (!srcExists) {
            throw new Error(`Final compiler source bulunamadı: ${paths.finalCompilerSource}`);
        }
        let shouldBuild = !exeExists;
        if (exeExists) {
            const srcMtime = fs.statSync(paths.finalCompilerSource).mtimeMs;
            const exeMtime = fs.statSync(paths.finalCompiler).mtimeMs;
            shouldBuild = srcMtime > exeMtime;
        }
        if (shouldBuild) {
            await this.buildFinalCompiler();
        }
        return paths.finalCompiler;
    }
    async finalRunAll(sourceFile) {
        const art = this.artifactsFor(sourceFile);
        const compiler = await this.ensureFinalCompiler();
        await this.run(compiler, ["--input", art.source, "--mode", "all", "--asm", art.asm, "--uir", art.uir, "--diag", art.diag, "--trace", art.trace, "--opt", art.opt], "Final Compiler ALL");
        return art;
    }
    async finalRunTrace(sourceFile) {
        const art = this.artifactsFor(sourceFile);
        const compiler = await this.ensureFinalCompiler();
        await this.run(compiler, ["--input", art.source, "--mode", "interpret", "--trace", art.trace, "--uir", art.uir, "--diag", art.diag, "--opt", art.opt], "Final Compiler Interpret Trace");
        return art;
    }
    async finalRunStep(sourceFile) {
        const art = this.artifactsFor(sourceFile);
        const paths = this.getPaths();
        const compiler = await this.ensureFinalCompiler();
        await this.run(compiler, ["--input", art.source, "--mode", "step", "--trace", art.trace, "--uir", art.uir, "--diag", art.diag, "--opt", art.opt, "--max-steps", String(paths.maxSteps)], "Final Compiler Step Mode");
        return art;
    }
    async finalCompileAsm(sourceFile) {
        const art = this.artifactsFor(sourceFile);
        const compiler = await this.ensureFinalCompiler();
        await this.run(compiler, ["--input", art.source, "--mode", "compile", "--asm", art.asm, "--uir", art.uir, "--diag", art.diag, "--opt", art.opt], "Final Compiler Compile ASM");
        return art;
    }
    async finalExportUIR(sourceFile) {
        const art = this.artifactsFor(sourceFile);
        const compiler = await this.ensureFinalCompiler();
        await this.run(compiler, ["--input", art.source, "--mode", "compile", "--uir", art.uir, "--diag", art.diag, "--opt", art.opt], "Final Compiler Export UIR");
        return art;
    }
    async finalExportDiagnostics(sourceFile) {
        const art = this.artifactsFor(sourceFile);
        const compiler = await this.ensureFinalCompiler();
        await this.run(compiler, ["--input", art.source, "--mode", "compile", "--diag", art.diag, "--uir", art.uir, "--opt", art.opt], "Final Compiler Export Diagnostics");
        return art;
    }
    async finalExportOPT(sourceFile) {
        const art = this.artifactsFor(sourceFile);
        const compiler = await this.ensureFinalCompiler();
        await this.run(compiler, ["--input", art.source, "--mode", "compile", "--opt", art.opt, "--uir", art.uir, "--diag", art.diag], "Final Compiler Export OPT");
        return art;
    }
    async finalIde(sourceFile, command) {
        const art = this.artifactsFor(sourceFile);
        const compiler = await this.ensureFinalCompiler();
        const req = { command, source: art.source, asm: art.asm, uir: art.uir, diag: art.diag, trace: art.trace, opt: art.opt };
        fs.writeFileSync(art.ideRequest, JSON.stringify(req, null, 2), "utf8");
        await this.run(compiler, ["--ide-in", art.ideRequest, "--ide-out", art.ideResponse], `Final Compiler IDE ${command}`);
        return art;
    }
    async runTrace(sourceFile) {
        const paths = this.getPaths();
        const art = this.artifactsFor(sourceFile);
        await this.run(paths.fullTool, ["run", art.source, art.trace], "Legacy Run Trace");
        return art;
    }
    async exportUIR(sourceFile) {
        const paths = this.getPaths();
        const art = this.artifactsFor(sourceFile);
        await this.run(paths.fullTool, ["uir", art.source, art.uir], "Legacy Export UIR");
        return art;
    }
    async exportOPT(sourceFile) {
        const paths = this.getPaths();
        const art = this.artifactsFor(sourceFile);
        await this.run(paths.fullTool, ["opt", art.source, art.opt], "Legacy Export OPT");
        return art;
    }
    async buildNative(sourceFile) {
        const paths = this.getPaths();
        const art = await this.finalCompileAsm(sourceFile);
        if (!fs.existsSync(paths.runtime)) {
            throw new Error(`Runtime bulunamadı: ${paths.runtime}. Native EXE için uxm31_runtime_fb_full.bas dosyasını tools/ içine koy veya uxminima.runtimePath ayarını düzelt.`);
        }
        await this.run(paths.nasm, ["-f", "win64", art.asm, "-o", art.obj], "ASM -> OBJ");
        await this.run(paths.fbc, [paths.runtime, art.obj, "-x", art.exe], "Runtime + OBJ -> EXE");
        return art;
    }
    resolveTool(toolPath, root) {
        if (path.isAbsolute(toolPath)) {
            return toolPath;
        }
        const fromRoot = path.join(root, toolPath);
        if (fs.existsSync(fromRoot)) {
            return fromRoot;
        }
        const fromRootTools = path.join(root, "tools", toolPath);
        if (fs.existsSync(fromRootTools)) {
            return fromRootTools;
        }
        const fromExtensionTools = path.join(this.context.extensionPath, "tools", toolPath);
        if (fs.existsSync(fromExtensionTools)) {
            return fromExtensionTools;
        }
        return toolPath;
    }
    run(command, args, title) {
        this.output.appendLine(`\n[${title}] ${command} ${args.map(a => JSON.stringify(a)).join(" ")}`);
        const cwd = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? this.context.extensionPath;
        return new Promise((resolve, reject) => {
            (0, child_process_1.execFile)(command, args, { cwd }, (error, stdout, stderr) => {
                if (stdout) {
                    this.output.appendLine(stdout);
                }
                if (stderr) {
                    this.output.appendLine(stderr);
                }
                if (error) {
                    this.output.show(true);
                    reject(new Error(`${title} başarısız: ${error.message}`));
                    return;
                }
                resolve();
            });
        });
    }
}
exports.UxmToolchain = UxmToolchain;
//# sourceMappingURL=toolchain.js.map