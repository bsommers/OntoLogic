# OntoLogic

```text
  ______           __           __                      __            
 /      \         /  |         /  |                    /  |           
/$$$$$$  |_______ $$ |_ ______ $$ |  ______   ______  $$/   _______   
$$ |  $$ |/      \$$   /      \$$ | /      \ /      \ /  | /       |  
$$ |  $$ |$$$$$$  |$$ |$$$$$$  |$$ |/$$$$$$  /$$$$$$  |$$ |/$$$$$$/   
$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$ |$$ |    
$$ \__$$ |$$ |  $$ |$$ |$$ \__$$ |$$ |$$ \__$$ |$$ \__$$ |$$ |$$ \_____ 
$$    $$/ $$ |  $$ |$$ |$$    $$/ $$ |$$    $$/ $$    $$ |$$ |$$       |
 $$$$$$/  $$/   $$/ $$/  $$$$$$/  $$/  $$$$$$/   $$$$$$$ |$$/  $$$$$$$/ 
                                                /  \__$$ |            
                                                $$    $$/             
                                                 $$$$$$/              
```

**Logic-as-Code compiler, ontology transpiler and SMT solver engine.**

OntoLogic is a first-order logic (FOL) domain-specific language, multi-target compiler, theorem-prover bridge and REPL written in Haskell. Write a formal ontology once, check it for consistency with Z3, CVC5, Vampire or the built-in native prover, and compile it into code, API contracts, database schemas, knowledge-graph formats and diagrams. The aim is that all of these outputs stay in step with the model instead of drifting apart; some axioms are not yet enforced by every output, so read [Current limitations](#current-limitations) first.

[![Docs](https://github.com/bsommers/OntoLogic/actions/workflows/docs.yml/badge.svg)](https://github.com/bsommers/OntoLogic/actions/workflows/docs.yml)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

Project site: <https://bsommers.github.io/OntoLogic/> | Rationale: [docs/purpose.md](docs/purpose.md)

## Quickstart

```bash
stack build                                              # 1. build
stack exec ontologic-exe -- -i examples/smart_factory.logic -t lint     # 2. lint
stack exec ontologic-exe -- --version                                  # prints: ontologic 1.8.4
stack exec ontologic-exe -- -i examples/smart_factory.logic -t solve    # 3. check consistency (SMT)
stack exec ontologic-exe -- -i examples/smart_factory.logic -t ts -o ./generated/ts   # 4. emit TypeScript/Zod
stack exec ontologic-exe -- --repl                       # 5. interactive REPL
```

Full walkthrough: [docs/user-guide/quickstart.md](docs/user-guide/quickstart.md). Install options: [docs/user-guide/installation.md](docs/user-guide/installation.md).

## Features

- **FOL DSL** with typed properties, binary relations, quantifiers and inheritance.
- **Modular namespaces**: `import`, `namespace`, cycle detection and a standard library lookup path.
- **Semantic linter**: symbol resolution, circular inheritance, duplicates and axiom contradictions (structural problems are errors; findings from the logical pass are warnings).
- **Multi-prover solver**: consistency, subsumption proofs, unsatisfiable-concept detection and counterexamples (Z3, CVC5, Vampire, the built-in native prover, or auto). The solver fails closed: an error or an unclear answer is never reported as satisfiable, and every backend has a 60 second default time limit.
- **Language server and VS Code extension** (`ontologic-lsp`, `editors/vscode`).
- **Interactive REPL** with `:load`, `:solve`, `:prove`, `:unsat`, `:emit <target>`.
- **Many emitters** from one shared intermediate representation (`ModelIR`).

## Targets

Select with `-t <target>`; see `--help` for the full list and [docs/user-guide/targets-and-emitters.md](docs/user-guide/targets-and-emitters.md) for details.

| Category | Targets |
|----------|---------|
| Application code | `ts` (Zod), `java`, `python` (Pydantic v2), `rust`, `go`, `cpp` |
| API and data contracts | `openapi`, `graphql`, `jsonschema`, `protobuf`, `sql` |
| Knowledge graphs | `owl`, `shacl`, `neo4j` |
| Provers | `smt` (SMT-LIB2), `tptp`, `solve` |
| Diagrams | `mermaid`, `d2` (add `--render` for images); see [docs/user-guide/visualization.md](docs/user-guide/visualization.md) |
| Tooling | `lint`, `repl`, `lsp` |

## Current limitations

- Generated code enforces property bounds and simple conditional bounds. Other axioms (disjointness, existentials, relational rules) are checked by the solver, not by the generated code, and are reported as "unmapped" (use `--warn-unmapped` to list them).
- The solver encoding does not yet assert the domain and range of relations on the Z3 and CVC5 route, and ignores cardinality.
- `def-individual` feeds the solver only; no target emits individuals, and there is no way yet to check instance data against a model.
- The shipped BFO file declares categories and relations but carries almost no axioms.
- The SQL target writes each relation twice (a junction table and a `TEXT[]` column).

Details: [targets and emitters](docs/user-guide/targets-and-emitters.md#what-is-and-is-not-enforced-or-exported) and [axioms and reasoning](docs/user-guide/axioms-and-reasoning.md).

## Documentation

- [Documentation index](docs/README.md)
- [User guide](docs/user-guide/README.md): [quickstart](docs/user-guide/quickstart.md), [installation](docs/user-guide/installation.md), [language reference](docs/user-guide/language-reference.md), [CLI reference](docs/user-guide/cli-reference.md), [targets and emitters](docs/user-guide/targets-and-emitters.md), [visualization](docs/user-guide/visualization.md)
- [Architecture](docs/architecture.md) and [purpose](docs/purpose.md)
- [Using OntoLogic](docs/using.md)
- [Developer guide](docs/dev/README.md)
- [Changelog](CHANGELOG.md)

## Standard library and domain examples

The bundled libraries live in `ontologic-lib/`; see [docs/standard-library.md](docs/standard-library.md). Worked examples across many domains: [docs/domains/README.md](docs/domains/README.md).

## Build and test

```bash
stack build --ghc-options="-Wall -Werror"
stack test
```

## License

Apache License 2.0. See [LICENSE](LICENSE).
