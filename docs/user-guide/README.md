# OntoLogic User Guide

This guide shows how to write, check, and compile OntoLogic ontologies. OntoLogic is a Haskell toolchain around a small first-order-logic (FOL) language: you describe concepts, properties, relations, and axioms in `.logic` files; the linter and SMT/ATP solvers check them for contradictions; and eighteen emitters turn the same model into code, API schemas, database schemas, knowledge-graph formats, prover input, and diagrams. A REPL, a language server (LSP), and a VS Code extension sit on top.

Every command in these pages was run against the current build and the output pasted (trimmed). Commands are written as `stack exec ontologic-exe -- ...` or just `ontologic-exe ...` if the binary is on your `PATH`.

## Reading order

New to OntoLogic: read 1 to 3 in order, then pick topics as needed.

| # | Page | Read it when you want to... |
|---|------|------------------------------|
| 1 | [Installation](installation.md) | Build the tools, add solvers and diagram renderers, install the editor extension |
| 2 | [Quickstart](quickstart.md) | Go from an empty file to a checked, compiled, visualized ontology in 10 minutes |
| 3 | [Language reference](language-reference.md) | Look up every form the parser accepts, plus imports and search paths |
| 4 | [Axioms and reasoning](axioms-and-reasoning.md) | Understand what the linter and solvers check, SAT vs UNSAT, timeouts, prover choice |
| 5 | [CLI reference](cli-reference.md) | Find a flag, a target name, or an exit code |
| 6 | [Targets and emitters](targets-and-emitters.md) | See what each target writes and which constraints it can express |
| 7 | [Visualization](visualization.md) | Produce Mermaid and D2 diagrams and render them |
| 8 | [REPL](repl.md) | Explore an ontology interactively |
| 9 | [Editor and LSP](editor-and-lsp.md) | Get diagnostics, hover, completion, and solver commands in an editor |
| 10 | [Standard library](standard-library.md) | Import BFO, MITRE, NIST and other bundled ontologies |
| 11 | [Domain examples](domain-examples.md) | Browse worked domain ontologies and their conflict fixtures |
| 12 | [Troubleshooting](troubleshooting.md) | Decode an error message or a surprising result |
| 13 | [FAQ](faq.md) | Quick answers to common questions |

## The workflow in one picture

```text
  .logic files --parse+imports--> Registry --lint--> errors? stop
                                      |
                       +--------------+---------------+
                       v                              v
                 --solve (z3/cvc5/vampire/native)   -t <target> -o DIR
                 SAT / UNSAT / unknown              code, schemas, diagrams
```

The linter always runs first. If it finds an error, nothing else runs (no solving, no emission) and the exit code is 1.

## Related documents

- Project overview: [../../README.md](../../README.md)
- Architecture: [../architecture.md](../architecture.md)
- Why constraints are mapped the way they are: [../dev/design/constraints_and_patterned.md](../dev/design/constraints_and_patterned.md), [../dev/design/constraint_considerations.md](../dev/design/constraint_considerations.md)
- Release notes: [../../CHANGELOG.md](../../CHANGELOG.md)

Next: [Installation](installation.md)
