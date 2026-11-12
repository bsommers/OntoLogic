# Editor and LSP

OntoLogic ships a Language Server (`ontologic-lsp`, or `ontologic-exe --lsp`) that speaks LSP over stdin/stdout, and a VS Code extension (`editors/vscode`) that wraps it. You get live diagnostics from the same linter the CLI uses, hover, completion, go-to-definition, rename, formatting, semantic highlighting, and commands that run the solver on the open file. Any LSP-capable editor can use the server directly.

## What the server provides

Capabilities reported by `initialize`:

| Feature | Detail |
|---------|--------|
| Diagnostics | Published on open and on every change. Parse errors, plus all linter findings with line and column (`source: ontologic-linter`). Imports are resolved first, so a concept defined in an imported file is not reported as undeclared; problems that belong to the imported files are not shown on yours |
| Completion | Triggered on `(`, space, and `"`. Offers keywords, primitive types, and the concepts, properties, and relations of the document and its imports |
| Hover | Concepts (parent, properties), properties (domain, type, cardinality, default), relations, and keywords (syntax summary). Comment lines directly above a `def-concept` or `def-property` appear as documentation |
| Go to definition | Jumps to the `def-concept`, `def-property`, or `def-relation` line for the symbol under the cursor, in the open document (not into imported files) |
| Rename | `prepareRename` and `rename` of concepts, properties, and relations across the document; rejects keywords and invalid names |
| Formatting | Re-indents the whole document (honours the editor's tab size) |
| Semantic tokens | Keyword, type, class, property, function, variable, string, number, comment, operator |
| Code actions | Quick-fix entries "Verify SMT Consistency", "Explain SMT Unsatisfiable Core", "Inspect SMT Satisfying Model" |
| Execute command | `ontologic.solve`, `ontologic.explainUnsat`, `ontologic.inspectModel`. They run asynchronously with progress notifications and can be cancelled; they always use the `auto` prover. When `auto` falls back to the native prover on an ontology with numeric comparisons, the `ontologic.solve` SAT `details` end with a warning that the theory was checked without arithmetic |

Imports use the same search path as the CLI, including `$ONTOLOGIC_PATH` (set it in the environment the editor is launched from). The server has no `--lib-path` option.

A diagnostic exchange, abbreviated:

```json
{"method":"textDocument/publishDiagnostics","params":{"uri":"file:///tmp/bad.logic","diagnostics":[{"range":{"start":{"line":3,"character":13},"end":{"line":3,"character":100}},"severity":1,"source":"ontologic-linter","message":"Semantic contradiction: Concept Hybrid implies both Truck and Car, but Truck is disjoint with Car."}]}}
```

## VS Code extension

### Install

```bash
./editors/vscode/scripts/build_extension.sh        # npm install, compile, package a .vsix
code --install-extension editors/vscode/ontologic-*.vsix
```

The extension activates for `.logic` files (language id `ontologic`). It finds the language server in this order: an absolute `ontologic.lsp.path`; `bin/ontologic-lsp` or `dist/ontologic-lsp` in the workspace; a Stack build under the workspace; `~/.local/bin/ontologic-lsp`; then plain `ontologic-lsp` on `PATH`. The easiest setup is `stack install`, which puts `ontologic-lsp` in `~/.local/bin`.

### Features

- TextMate syntax highlighting and bracket/comment configuration.
- Snippets: `def-concept`, `def-concept-subclass`, `def-property`, `def-property-optional`, `def-relation`, `def-individual`, `forall-bound`, `forall-range`, `exists`, and `import`. Each expands to current syntax (see the [Language reference](language-reference.md)).
- Everything in the table above via the language server.

### Commands

Open the Command Palette and type "OntoLogic".

| Command | What it does |
|---------|--------------|
| OntoLogic: Restart Language Server | Stop and start `ontologic-lsp` (use after rebuilding the binary) |
| OntoLogic: Check SMT Consistency & Satisfiability | Saves the file and runs the CLI: `-i FILE -t solve --prover <setting>`; shows SAT/UNSAT in a message and the full output in the "OntoLogic" output channel |
| OntoLogic: Check Concept Satisfiability | Saves the file and runs the REPL's `:load` and `:unsat` |
| OntoLogic: Verify SMT Consistency (AutoProver) | LSP `ontologic.solve` |
| OntoLogic: Explain SMT Unsatisfiable Core | LSP `ontologic.explainUnsat` |
| OntoLogic: Inspect SMT Satisfying Model | LSP `ontologic.inspectModel` |

### Settings

| Setting | Default | Meaning |
|---------|---------|---------|
| `ontologic.lsp.path` | `ontologic-lsp` | Language server executable |
| `ontologic.cli.path` | empty | CLI executable (`ontologic` or `ontologic-exe`). Empty means: next to the language server, then a Stack build in the workspace, then `PATH` |
| `ontologic.solver.prover` | `auto` | `auto`, `z3`, `cvc5`, or `vampire`; used by "Check SMT Consistency & Satisfiability" only. The LSP-backed commands always use `auto` |
| `ontologic.trace.server` | `off` | `off`, `messages`, or `verbose` JSON-RPC tracing |

In an untrusted workspace the three path/prover settings are restricted, so a repository cannot make the extension run an arbitrary binary.

To debug the connection, set `ontologic.trace.server` to `verbose` and open View > Output > OntoLogic.

## Other editors

Any client that can launch a stdio server works. The server needs no arguments. For Neovim with `nvim-lspconfig`:

```lua
local lspconfig = require('lspconfig')
local configs = require('lspconfig.configs')

if not configs.ontologic_lsp then
  configs.ontologic_lsp = {
    default_config = {
      cmd = { 'ontologic-lsp' },
      filetypes = { 'logic', 'lisp' },
      root_dir = lspconfig.util.root_pattern('.git', 'package.yaml'),
      settings = {},
    },
  }
end
lspconfig.ontologic_lsp.setup{}
```

Map `*.logic` to a filetype your config lists (here `logic`). For other editors use `ontologic-lsp` (or `ontologic-exe --lsp`) as the server command over stdio, with the document language `ontologic` or `.logic` as the file pattern.

Next: [Standard library](standard-library.md)
