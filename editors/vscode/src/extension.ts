import * as path from 'path';
import * as fs from 'fs';
import * as cp from 'child_process';
import { workspace, ExtensionContext, window, commands, OutputChannel } from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient | undefined;
let outputChannel: OutputChannel;

const PROVERS = ['auto', 'z3', 'cvc5', 'vampire'];

function findOnPath(name: string): string | undefined {
  for (const dir of (process.env.PATH || '').split(path.delimiter)) {
    if (!dir) {
      continue;
    }
    const cand = path.join(dir, name);
    if (fs.existsSync(cand)) {
      return cand;
    }
  }
  return undefined;
}

// stack installs to .stack-work/install/<platform>/<hash>/<ghc>/bin
function findStackBinary(root: string, name: string): string | undefined {
  const base = path.join(root, '.stack-work', 'install');
  if (!fs.existsSync(base)) {
    return undefined;
  }
  for (const platform of fs.readdirSync(base)) {
    const platformDir = path.join(base, platform);
    for (const hash of fs.readdirSync(platformDir)) {
      const hashDir = path.join(platformDir, hash);
      for (const ghc of fs.readdirSync(hashDir)) {
        const cand = path.join(hashDir, ghc, 'bin', name);
        if (fs.existsSync(cand)) {
          return cand;
        }
      }
    }
  }
  return undefined;
}

function resolveCliBinary(): string {
  const configured = workspace.getConfiguration('ontologic').get<string>('cli.path', '');
  if (configured) {
    return configured;
  }

  // Next to the language server (the release tarball ships bin/ontologic + bin/ontologic-lsp)
  const lspDir = path.dirname(resolveLspBinary());
  for (const name of ['ontologic', 'ontologic-exe']) {
    const sibling = path.join(lspDir, name);
    if (path.isAbsolute(sibling) && fs.existsSync(sibling)) {
      return sibling;
    }
  }

  // A stack build in the workspace
  for (const folder of workspace.workspaceFolders || []) {
    const stackBin = findStackBinary(folder.uri.fsPath, 'ontologic-exe');
    if (stackBin) {
      return stackBin;
    }
  }

  return findOnPath('ontologic') || findOnPath('ontologic-exe') || 'ontologic-exe';
}

export function activate(context: ExtensionContext) {
  outputChannel = window.createOutputChannel('OntoLogic');
  context.subscriptions.push(outputChannel);

  startLanguageClient(context);

  // Command: Restart Language Server
  context.subscriptions.push(
    commands.registerCommand('ontologic.restartServer', async () => {
      outputChannel.appendLine('[Extension] Restarting OntoLogic Language Server...');
      if (client) {
        await client.stop();
        client = undefined;
      }
      startLanguageClient(context);
      window.showInformationMessage('OntoLogic Language Server restarted.');
    })
  );

  // Command: Check SMT Consistency
  context.subscriptions.push(
    commands.registerCommand('ontologic.checkConsistency', async () => {
      const editor = window.activeTextEditor;
      if (!editor || editor.document.languageId !== 'ontologic') {
        window.showWarningMessage('Please open an OntoLogic (.logic) file first.');
        return;
      }

      await editor.document.save();
      const filePath = editor.document.uri.fsPath;
      const config = workspace.getConfiguration('ontologic');
      const prover = config.get<string>('solver.prover', 'auto');

      if (!PROVERS.includes(prover)) {
        window.showErrorMessage(`Invalid ontologic.solver.prover "${prover}". Use one of: ${PROVERS.join(', ')}.`);
        return;
      }

      outputChannel.appendLine(`[SMT Solver] Running consistency check on ${filePath} with prover=${prover}...`);
      outputChannel.show(true);

      const cliPath = resolveCliBinary();

      // execFile, not exec: no shell, so paths and settings cannot inject commands
      cp.execFile(cliPath, ['-i', filePath, '-t', 'solve', '--prover', prover], (err, stdout, stderr) => {
        outputChannel.appendLine(`[SMT Solver Output]\n${stdout}${stderr}`);
        if (!err && stdout.includes('SMT Satisfiable (SAT)')) {
          window.showInformationMessage('OntoLogic: SMT Model is Satisfiable & Consistent (SAT).');
        } else if (stdout.includes('SMT Unsatisfiable (UNSAT)')) {
          window.showErrorMessage('OntoLogic: Logical contradiction detected (UNSAT). See output channel.');
        } else {
          window.showWarningMessage('OntoLogic: SMT check did not prove consistency. See output channel.');
        }
      });
    })
  );

  // Command: Check Concept Satisfiability
  context.subscriptions.push(
    commands.registerCommand('ontologic.findUnsat', async () => {
      const editor = window.activeTextEditor;
      if (!editor || editor.document.languageId !== 'ontologic') {
        window.showWarningMessage('Please open an OntoLogic (.logic) file first.');
        return;
      }

      await editor.document.save();
      const filePath = editor.document.uri.fsPath;

      outputChannel.appendLine(`[SMT Solver] Checking concept satisfiability for ${filePath}...`);
      outputChannel.show(true);

      const cliPath = resolveCliBinary();

      // REPL commands go in on stdin instead of through a shell pipeline
      const child = cp.execFile(cliPath, ['--repl'], (err, stdout, stderr) => {
        outputChannel.appendLine(`[REPL Output]\n${stdout}${stderr}`);
        if (err || stdout.includes('❌')) {
          window.showErrorMessage('OntoLogic: Concept satisfiability check failed. See output channel.');
        } else if (stdout.includes('All concepts are satisfiable')) {
          window.showInformationMessage('OntoLogic: All concepts are logically satisfiable.');
        } else {
          window.showWarningMessage('OntoLogic: Unsatisfiable concept(s) detected. Check output channel.');
        }
      });
      child.stdin?.end(`:load ${filePath}\n:unsat\n:quit\n`);
    })
  );

  // LSP Server-backed SMT Commands for Command Palette
  const executeLspCommand = async (commandName: string, title: string) => {
    const editor = window.activeTextEditor;
    if (!editor || editor.document.languageId !== 'ontologic') {
      window.showWarningMessage('Please open an OntoLogic (.logic) file first.');
      return;
    }
    await editor.document.save();
    if (!client) {
      window.showErrorMessage('OntoLogic Language Server is not running.');
      return;
    }
    try {
      const uri = editor.document.uri.toString();
      outputChannel.appendLine(`[LSP Command] Executing ${commandName} for ${uri}...`);
      outputChannel.show(true);
      const res: any = await client.sendRequest('workspace/executeCommand', {
        command: commandName,
        arguments: [uri]
      });
      outputChannel.appendLine(`[LSP Command Output: ${commandName}]\n` + JSON.stringify(res, null, 2));
      if (res && res.status === 'sat') {
        window.showInformationMessage(`OntoLogic (${title}): Satisfiable (SAT)`);
      } else if (res && res.status === 'unsat') {
        window.showErrorMessage(`OntoLogic (${title}): Unsatisfiable (UNSAT)`);
      } else if (res && res.status === 'error') {
        window.showErrorMessage(`OntoLogic (${title}) Error: ${res.details || 'Unknown error'}`);
      }
    } catch (err) {
      outputChannel.appendLine(`[LSP Command Error] ${err}`);
      window.showErrorMessage(`OntoLogic: Failed to execute ${commandName}`);
    }
  };

  context.subscriptions.push(
    commands.registerCommand('ontologic.solve', () => executeLspCommand('ontologic.solve', 'SMT Consistency')),
    commands.registerCommand('ontologic.explainUnsat', () => executeLspCommand('ontologic.explainUnsat', 'Explain UNSAT')),
    commands.registerCommand('ontologic.inspectModel', () => executeLspCommand('ontologic.inspectModel', 'Inspect Model'))
  );
}

function resolveLspBinary(): string {
  const config = workspace.getConfiguration('ontologic');
  const configuredPath = config.get<string>('lsp.path', 'ontologic-lsp');

  if (configuredPath && path.isAbsolute(configuredPath) && fs.existsSync(configuredPath)) {
    return configuredPath;
  }

  // Check workspace dist/bin or bin
  const workspaceFolders = workspace.workspaceFolders;
  if (workspaceFolders) {
    for (const folder of workspaceFolders) {
      const candidates = [
        path.join(folder.uri.fsPath, 'bin', 'ontologic-lsp'),
        path.join(folder.uri.fsPath, 'dist', 'ontologic-lsp')
      ];
      for (const cand of candidates) {
        if (fs.existsSync(cand)) {
          return cand;
        }
      }
      const stackLsp = findStackBinary(folder.uri.fsPath, 'ontologic-lsp');
      if (stackLsp) {
        return stackLsp;
      }
    }
  }

  // Check ~/.local/bin
  const home = process.env.HOME || process.env.USERPROFILE || '';
  const localBin = path.join(home, '.local', 'bin', 'ontologic-lsp');
  if (fs.existsSync(localBin)) {
    return localBin;
  }

  return configuredPath || 'ontologic-lsp';
}

function startLanguageClient(context: ExtensionContext) {
  const serverExecutable = resolveLspBinary();
  outputChannel.appendLine(`[Extension] Starting LSP server using: ${serverExecutable}`);

  const serverOptions: ServerOptions = {
    run: {
      command: serverExecutable,
      transport: TransportKind.stdio
    },
    debug: {
      command: serverExecutable,
      transport: TransportKind.stdio
    }
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'ontologic' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.logic')
    },
    outputChannel: outputChannel
  };

  client = new LanguageClient(
    'ontologicLanguageServer',
    'OntoLogic Language Server',
    serverOptions,
    clientOptions
  );

  client.start().catch(err => {
    outputChannel.appendLine(`[Extension Error] Failed to start LSP server: ${err}`);
  });
}

export function deactivate(): Thenable<void> | undefined {
  if (!client) {
    return undefined;
  }
  return client.stop();
}
