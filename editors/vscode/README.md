# OntoLogic VS Code Extension

Official Visual Studio Code extension for **OntoLogic** — First-Order Logic Domain Modeling, SMT Theorem Proving, and Multi-Target Code Generation.

---

## Features

- **Syntax highlighting**: a TextMate grammar for OntoLogic S-expressions: the `def-concept`, `def-property`, `def-relation`, `def-individual`, `def-axiom`, `namespace` and `import` forms, quantifiers (`forall`, `exists`), connectives (`and`, `or`, `not`, `implies`, `if`, `iff`), comparison operators, types, booleans, `top` and `bottom`, the `:cardinality`, `:optional` and `:default` options, and all comment forms (`;`, `//`, `/* */`, `#| |#`).
- **Language Server Protocol (LSP)**, powered by `ontologic-lsp`:
  - **Real-time diagnostics**: parse errors and linter findings (errors and warnings).
  - **Completion**: keywords, primitive types, concepts, properties and relations.
  - **Hover**: class inheritance, typed properties, and the comments written above a declaration.
  - **Go to definition**: follows imports into other files.
  - **Rename** of concepts, properties and relations, and **document formatting**.
  - **Semantic highlighting**.
- **Snippets**: `def-concept` (with or without a parent), `def-property`, `def-relation`, `def-individual`, `forall` bound/range axioms, `exists` axioms, and `import`.
- **Solver commands** in the Command Palette: check SMT consistency and satisfiability, check concept satisfiability, verify consistency, explain the unsatisfiable core, inspect a satisfying model, and restart the language server.

---

## Installation & Setup

1. Build and package the extension (needs Node.js and npm; run from the repository root):
   ```bash
   ./editors/vscode/scripts/build_extension.sh
   ```
   This writes `editors/vscode/ontologic-<version>.vsix`, where the version is the one in `package.json` (1.8.4 for this release). No `.vsix` file is checked in.
2. Install it:
   ```bash
   code --install-extension editors/vscode/ontologic-*.vsix
   ```
3. Ensure `ontologic-lsp` is in your `PATH` (for example `~/.local/bin/ontologic-lsp` after `stack install`) or set `ontologic.lsp.path` in Settings.

---

## Configuration

| Setting | Default | Description |
| :--- | :--- | :--- |
| `ontologic.lsp.path` | `"ontologic-lsp"` | Path to the `ontologic-lsp` binary. |
| `ontologic.cli.path` | empty | Path to the `ontologic` CLI used by the check commands. Empty means: next to the language server, a Stack build in the workspace, then `PATH`. |
| `ontologic.solver.prover` | `"auto"` | SMT theorem prover backend (`auto`, `z3`, `cvc5`, `vampire`). |
| `ontologic.trace.server` | `"off"` | Trace level for LSP JSON-RPC communication. |
