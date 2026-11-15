# Installation

OntoLogic is built with Stack (GHC 9.4.8, resolver `lts-21.25`) and produces two executables: `ontologic-exe` (compiler, solver driver, REPL) and `ontologic-lsp` (language server). SMT/ATP solvers (Z3, CVC5, Vampire) and diagram renderers (`d2`, `mmdc`) are optional external programs: without a solver OntoLogic falls back to a built-in native prover, and without a renderer it still writes the diagram source.

## Ways to get OntoLogic

- **Build from source with Stack.** This is the supported path and the one the rest of this guide assumes. The first build downloads GHC 9.4.8 and compiles every dependency, so expect it to take a while.
- **Use a release tarball.** `scripts/package_release.sh` builds one (still with Stack, on your machine). If a tarball is attached to a GitHub release for your platform, you can download it, unpack it and copy `bin/ontologic` onto your `PATH` without installing Stack. No prebuilt binary is promised for every platform, so check the project's releases page and fall back to a source build.
- **Docker.** There is no OntoLogic image.

## Build from source

```bash
git clone https://github.com/bsommers/OntoLogic.git OntoLogic
cd OntoLogic
stack build
stack exec ontologic-exe -- --help
```

Install both executables into `~/.local/bin`:

```bash
stack install
ontologic-exe --help
```

Before contributing, the project's gate is `stack test --ghc-options="-Wall -Werror"`; `scripts/check_coverage.sh` runs the suite with coverage. Both run on your machine; GitHub does not run them automatically (see [AGENTS.md](../../AGENTS.md)).

Release tarballs (built by `scripts/package_release.sh`) lay out `bin/ontologic`, `bin/ontologic-lsp`, `ontologic-lib/`, `examples/`, and the `.vsix`. The CLI in a tarball is named `ontologic`; everywhere in this guide `ontologic-exe` and `ontologic` are the same program. In that layout the standard library is found automatically (see [Standard library](standard-library.md)).

### The `setup.sh` helper

The repository's `setup.sh` is an optional convenience for Debian or Ubuntu machines. It uses `sudo apt` to install Stack and Docker tooling, and SDKMAN to install Java and Gradle for the `models-java` subproject. You do not need it to build or use OntoLogic; read it before running it, because it changes your system.

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

Since 1.8.3 the native prover also catches numeric bound conflicts such as `(gt balance 100)` together with `(lt balance 50)`. Only integer gaps (for example no whole number between 1 and 2) need Z3 or CVC5. The native prover does not reason about equality: if the theory uses equality it answers "unknown" instead of guessing. See [Axioms and reasoning](axioms-and-reasoning.md).

Every backend has a default time limit of 60 seconds; change it with `-T SECONDS`. A solver that crashes, prints an error, or gives no clear answer is reported as a solver error with a non-zero exit code. It is never reported as satisfiable.

## Optional diagram renderers

| Tool | Renders | Install |
|------|---------|---------|
| `d2` | `-t d2 --render` | `curl -fsSL https://d2lang.com/install.sh \| sh -s --` |
| `mmdc` (Mermaid CLI) | `-t mermaid --render` | `npm install -g @mermaid-js/mermaid-cli` |

If a renderer is missing, generation still succeeds and a warning is printed. Details in [Visualization](visualization.md).

## Neo4j (optional)

The `neo4j` target writes Cypher files; it does not need a running database. To try them, start any Neo4j instance you like, for example:

```bash
docker run --rm -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=neo4j/choose-a-password neo4j:5
```

Then load `graph.cypher` through the web UI on port 7474 or with `cypher-shell`.

## VS Code extension

The extension (`editors/vscode`) adds highlighting, snippets, diagnostics, hover, completion, go-to-definition, rename, formatting, and solver commands. Build and install it:

```bash
./editors/vscode/scripts/build_extension.sh     # needs Node.js and npm
code --install-extension editors/vscode/ontologic-*.vsix
```

The packaged file is named after the version in `editors/vscode/package.json` (1.8.4 for this release).

The extension needs the `ontologic-lsp` binary: put it on `PATH` (for example via `stack install`) or set `ontologic.lsp.path`. See [Editor and LSP](editor-and-lsp.md).

## Verify the install

```bash
ontologic-exe -i examples/smart_factory.logic -t lint
```

```text
✅ Logic Validated successfully.
```

Next: [Quickstart](quickstart.md)
