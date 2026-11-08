# Installation

OntoLogic is built with Stack (GHC 9.4.8, resolver `lts-21.25`) and produces two executables: `ontologic-exe` (compiler, solver driver, REPL) and `ontologic-lsp` (language server). SMT/ATP solvers (Z3, CVC5, Vampire) and diagram renderers (`d2`, `mmdc`) are optional external programs: without a solver OntoLogic falls back to a built-in native prover, and without a renderer it still writes the diagram source.

## Build from source

```bash
git clone <repository-url> OntoLogic
cd OntoLogic
stack build
stack exec ontologic-exe -- --help
```

Install both executables into `~/.local/bin`:

```bash
stack install
ontologic-exe --help
```

Before contributing, the project's gate is `stack test --ghc-options="-Wall -Werror"`; `scripts/check_coverage.sh` runs the suite with coverage.

Release tarballs (built by `scripts/package_release.sh`) lay out `bin/ontologic`, `bin/ontologic-lsp`, `ontologic-lib/`, `examples/`, and the `.vsix`. The CLI in a tarball is named `ontologic`; everywhere in this guide `ontologic-exe` and `ontologic` are the same program. In that layout the standard library is found automatically (see [Standard library](standard-library.md)).

## Optional solvers

OntoLogic talks to solvers by running them as child processes found on `PATH`.

| Solver | Used for | Install |
|--------|----------|---------|
| Z3 | Default first choice; best for integer/real bounds on properties | `sudo apt-get install z3` / `brew install z3` |
| CVC5 | Second choice; finite-model finding | `sudo apt-get install cvc5` / `brew install cvc5` |
| Vampire | Third choice; strong on pure first-order reasoning | releases at the Vampire project site |

With `--prover auto` (the default) OntoLogic tries `z3`, then `cvc5`, then `vampire`, moving on only when a binary is not installed. If none is installed it uses the native prover. Check what you have:

```bash
z3 --version && cvc5 --version && vampire --version
```

Note that the native prover does not reason about numeric comparisons such as `(gt balance 100)`, so numeric contradictions are only found by Z3 or CVC5. See [Axioms and reasoning](axioms-and-reasoning.md).

## Optional diagram renderers

| Tool | Renders | Install |
|------|---------|---------|
| `d2` | `-t d2 --render` | `curl -fsSL https://d2lang.com/install.sh \| sh -s --` |
| `mmdc` (Mermaid CLI) | `-t mermaid --render` | `npm install -g @mermaid-js/mermaid-cli` |

If a renderer is missing, generation still succeeds and a warning is printed. Details in [Visualization](visualization.md).

## Docker

There is no OntoLogic image. The repository's `docker-compose.yml` starts a Neo4j 5.12 container and a Python validator container (`Dockerfile.python`, which mounts `./generated/python`) for trying the `neo4j` and `python` targets:

```bash
docker-compose up
```

Neo4j listens on ports 7474 (web UI) and 7687 (Bolt); set `NEO4J_AUTH` to change the default credentials.

## VS Code extension

The extension (`editors/vscode`) adds highlighting, snippets, diagnostics, hover, completion, go-to-definition, rename, formatting, and solver commands. Build and install it:

```bash
./editors/vscode/scripts/build_extension.sh     # needs Node.js and npm
code --install-extension editors/vscode/ontologic-*.vsix
```

The extension needs the `ontologic-lsp` binary: put it on `PATH` (for example via `stack install`) or set `ontologic.lsp.path`. See [Editor and LSP](editor-and-lsp.md).

## Verify the install

```bash
ontologic-exe -i examples/smart_factory.logic -t lint
```

```text
✅ Logic Validated successfully.
```

Next: [Quickstart](quickstart.md)
