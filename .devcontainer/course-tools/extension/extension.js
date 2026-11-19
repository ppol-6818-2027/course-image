// The PPOL 6818 codespace extension. At startup it sets the working layout,
// three columns in VS Code's own arrangement: files on the left, run.R over
// the R console in the middle, Claude Code (with Codex as its second tab) on
// the right. It closes the Welcome page, makes sure there is one R console,
// and brings Claude Code forward. Its panel in the file list holds the course
// commands, which run in the R console.
const vscode = require('vscode');

// VS Code makes a terminal by itself when its terminal view opens visible,
// and the default terminal profile is the R console. Wait for that one, and
// make one only when none comes, so there is never a second R console.
const rConsole = () => new Promise(resolve => {
  if (vscode.window.terminals.length) return resolve(vscode.window.terminals[0]);
  const sub = vscode.window.onDidOpenTerminal(t => { clearTimeout(timer); sub.dispose(); resolve(t); });
  const timer = setTimeout(() => {
    sub.dispose();
    resolve(vscode.window.createTerminal({ name: 'R', shellPath: '/usr/local/bin/ppol6818-console' }));
  }, 3000);
});

// The R console the course commands run in: the one named R, or else the
// newest terminal, or a new R console.
const consoleFor = async () => {
  const ts = vscode.window.terminals;
  return ts.find(t => t.name === 'R') || ts[ts.length - 1] || rConsole();
};

const inConsole = code => async () => {
  const t = await consoleFor();
  t.show(false);
  t.sendText(code, true);
};

const quietly = async (cmd) => {
  try { await vscode.commands.executeCommand(cmd); } catch (e) { /* the agent extension may not be installed yet */ }
};

exports.activate = async context => {
  context.subscriptions.push(
    vscode.commands.registerCommand('ppol6818.setup', inConsole('ppol6818::setup()')),
    vscode.commands.registerCommand('ppol6818.buildSite', inConsole('ppol6818::build_site()')),
    vscode.commands.registerCommand('ppol6818.check', inConsole('ppol6818::check()')),
    // The panel has no items of its own: only its buttons (viewsWelcome).
    vscode.window.registerTreeDataProvider('ppol6818.panel', { getChildren: () => [], getTreeItem: x => x })
  );
  for (const g of vscode.window.tabGroups.all)
    for (const t of g.tabs)
      if (t.label === 'Welcome' || t.label === 'Walkthrough') await vscode.window.tabGroups.close(t);
  const t = await rConsole();
  t.show(false);
  await quietly('claudeVSCodeSidebarSecondary.focus');
};

exports.deactivate = () => {};
