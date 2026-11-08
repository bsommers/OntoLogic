# OntoLogic Documentation

OntoLogic is a Haskell First-Order Logic ontology DSL and toolchain: write a
domain once in a `.logic` file, verify it, and compile it to code, schemas,
proofs and diagrams. Start with the [project README](../README.md), then pick a
path below.

## Learn and use

| Document | Read it to |
| :--- | :--- |
| [User guide](user-guide/README.md) | Learn the language and tools in depth |
| [Installation](user-guide/installation.md) | Build or install OntoLogic |
| [Quickstart](user-guide/quickstart.md) | Go from zero to generated output in minutes |
| [Using OntoLogic](using.md) | Follow task-oriented recipes |
| [Language reference](user-guide/language-reference.md) | Look up syntax |
| [Axioms and reasoning](user-guide/axioms-and-reasoning.md) | Write axioms and use the provers |
| [CLI reference](user-guide/cli-reference.md) | Look up every flag and exit code |
| [Targets and emitters](user-guide/targets-and-emitters.md) | See what each of the 18 targets produces |
| [Visualization](user-guide/visualization.md) | Render Mermaid and D2 diagrams |
| [REPL](user-guide/repl.md) | Explore interactively |
| [Editor and LSP](user-guide/editor-and-lsp.md) | Set up VS Code, Neovim and other editors |
| [Troubleshooting](user-guide/troubleshooting.md), [FAQ](user-guide/faq.md) | Fix problems |

## Understand

| Document | Read it to |
| :--- | :--- |
| [Purpose](purpose.md) | Know why OntoLogic exists |
| [Architecture](architecture.md) | See how the pipeline, solvers and tooling fit together |

## Reuse and examples

| Document | Read it to |
| :--- | :--- |
| [Standard library](standard-library.md) | Find and import ready-made ontologies (BFO, CCO, ATT&CK, NIST, ...) |
| [Domain examples gallery](domains/README.md) | Browse runnable models by sector |

## Develop and track

| Document | Read it to |
| :--- | :--- |
| [Developer notes](dev/README.md) | Find plans, reviews, design notes, benchmarks and the coverage audit |
| [Changelog](../CHANGELOG.md) | See what changed in each release |
| [Contributor guide](../AGENTS.md) | Learn the workflow and pre-push gates |

## Quick start

```bash
ontologic -i examples/smart_factory.logic -t lint          # validate
ontologic -i examples/smart_factory.logic --solve          # prove consistency
ontologic -i examples/smart_factory.logic -t python -o out # generate
```

From a source checkout, replace `ontologic` with `stack exec ontologic-exe --`.
