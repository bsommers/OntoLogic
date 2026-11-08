# OntoLogic VS Code Extension

Official Visual Studio Code extension for **OntoLogic** — First-Order Logic Domain Modeling, SMT Theorem Proving, and Multi-Target Code Generation.

---

## Features

- 🌟 **Syntax Highlighting**: Full TextMate grammar support for OntoLogic S-expressions, keywords, FOL quantifiers (`forall`, `exists`), comparison operators, types, and comments.
- ⚡ **Language Server Protocol (LSP)**: Powered by `ontologic-lsp`:
  - **Real-Time Diagnostics**: Instant feedback on syntax errors and semantic linter issues (cycle detection, undeclared symbols, interval contradictions).
  - **Context-Aware Autocompletion**: Keywords, primitive types, concept classes, and properties.
  - **Type Definition & Hover**: Hover over concept names to inspect class inheritance and typed bounds.
  - **Jump to Definition**: Jump directly to concept declarations across files.
- 🧩 **Code Snippets**: Quick templates for `def-concept`, `subclass-of`, `def-relation`, `axiom`, and `import`.
- 🔍 **Interactive SMT Solver Integration**: Trigger Z3 and CVC5 satisfiability checks and concept emptiness tests directly from the editor command palette.

---

## Installation & Setup

1. Install the `ontologic-1.0.0.vsix` extension package:
   ```bash
   code --install-extension ontologic-1.0.0.vsix
   ```
2. Ensure `ontologic-lsp` is in your `PATH` (e.g., `~/.local/bin/ontologic-lsp`) or configure `ontologic.lsp.path` in Settings.

---

## Configuration

| Setting | Default | Description |
| :--- | :--- | :--- |
| `ontologic.lsp.path` | `"ontologic-lsp"` | Path to the `ontologic-lsp` binary. |
| `ontologic.solver.prover` | `"auto"` | SMT theorem prover backend (`auto`, `z3`, `cvc5`, `vampire`). |
| `ontologic.trace.server` | `"off"` | Trace level for LSP JSON-RPC communication. |
