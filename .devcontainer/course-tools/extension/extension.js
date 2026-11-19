// The PPOL 6818 codespace extension. At startup it sets the working layout,
// three columns in VS Code's own arrangement: files on the left, run.R over
// the R console in the middle, Claude Code (with Codex as its second tab) on
// the right. It closes the Welcome page, makes sure there is one R console,
// brings Claude Code forward, and offers a rebuild when the course needs a
// newer image. Its panel in the file list holds the course
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

// Bring Claude Code forward. In a new codespace VS Code installs the agent
// extensions about a minute after this one starts (tested 2026-11-18), so
// wait up to three minutes for its view's command to exist.
const AGENT = 'claudeVSCodeSidebarSecondary.focus';
const focusAgent = async () => {
  for (let i = 0; i < 90; i++) {
    if ((await vscode.commands.getCommands(true)).includes(AGENT)) {
      try { await vscode.commands.executeCommand(AGENT); } catch (e) { /* leave the layout as it is */ }
      return;
    }
    await new Promise(r => setTimeout(r, 2000));
  }
};

// Offer a rebuild when the course package (updated by the R console at each
// start) asks for a newer image than this codespace runs: its
// codespace/image.json against the image-version file the image was built
// with. A rebuild keeps /workspaces and resets the rest, so it is the
// student's choice, once per window. It must be a Full Rebuild: a plain
// Rebuild reuses the cached old image (tested 2026-11-19).
const fs = require('fs');
const IMAGE = '/usr/local/share/ppol6818/image-version';
const WANTED = '/usr/local/lib/R/site-library/ppol6818/codespace/image.json';
const older = (a, b) => {
  const x = a.split('.').map(Number), y = b.split('.').map(Number);
  for (let i = 0; i < 3; i++) if ((x[i] || 0) !== (y[i] || 0)) return (x[i] || 0) < (y[i] || 0);
  return false;
};
let offered = false;
const offerRebuild = async () => {
  if (offered) return;
  let wanted, have;
  try { wanted = JSON.parse(fs.readFileSync(WANTED, 'utf8')); } catch (e) { return; }
  try { have = fs.readFileSync(IMAGE, 'utf8').trim(); } catch (e) { have = '0'; }
  if (!wanted.version || !older(have, wanted.version)) return;
  offered = true;
  const go = 'Rebuild now';
  const pick = await vscode.window.showWarningMessage(
    `Course update: ${wanted.note || 'the course codespace has new software.'} Rebuild your codespace to get it: click Rebuild now, then Full Rebuild (a plain Rebuild keeps the old software). It takes about five minutes. Your files are kept, including work not yet committed; afterwards, sign in to your agent again and click Course setup.`,
    go, 'Later');
  if (pick !== go) return;
  try { await vscode.commands.executeCommand('github.codespaces.rebuildEnvironment'); }
  catch (e) { vscode.window.showInformationMessage('Press Cmd+Shift+P (Ctrl+Shift+P on Windows), type Rebuild Container, press Enter and choose Full Rebuild.'); }
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
  focusAgent();
  // The R console updates the package a minute or two after startup.
  offerRebuild();
  const timer = setInterval(offerRebuild, 60000);
  context.subscriptions.push({ dispose: () => clearInterval(timer) });
};

exports.deactivate = () => {};
