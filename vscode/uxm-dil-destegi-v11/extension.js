
const vscode = require('vscode');
function runBat(name) {
  const folder = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0];
  if (!folder) { vscode.window.showErrorMessage('UXM çalışma klasörü açık değil / No UXM workspace folder is open'); return; }
  const terminal = vscode.window.createTerminal('UXM');
  terminal.show();
  terminal.sendText(`cd /d "${folder.uri.fsPath}" && ${name}`);
}
function activate(context) {
  const cmds = {
    'uxm.bellekTest':'bellek_test.bat',
    'uxm.hizliTara':'hizli_tara.bat',
    'uxm.hataliTest':'hatali_test.bat -k -D',
    'uxm.tumTest':'tum_test.bat -k',
    'uxm.derleyiciDerle':'derleyici_derle.bat',
    'uxm.alanTopla':'alan_topla.bat',
    'uxm.raporGoster':'rapor_goster.bat'
  };
  for (const [cmd, bat] of Object.entries(cmds)) context.subscriptions.push(vscode.commands.registerCommand(cmd, () => runBat(bat)));
}
function deactivate() {}
module.exports = { activate, deactivate };
