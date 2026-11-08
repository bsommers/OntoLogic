# CLI reference

The compiler executable is `ontologic-exe` (named `ontologic` in release tarballs). One invocation loads one input file, lints it, and then does exactly one thing: print the CNF, run the solver, or emit a target. This page lists every flag, every target (with aliases), the order in which modes are chosen, environment variables, and exit codes.

```text
ontologic-exe [-i|--input FILE] [-t|--target TARGET] [-o|--output PATH]
              [--java-package PKG] [--base-iri IRI] [-p|--prover NAME]
              [--neo4j-edition EDITION] [--render] [--repl] [--cnf] [--lsp]
              [--solve] [--warn-unmapped] [--explain-unsat] [--inspect-model]
              [--free-constants] [-T|--solve-timeout SECONDS]
              [--solve-memory MB] [--lib-path DIR]
```

## Flags

| Flag | Argument | Description |
|------|----------|-------------|
| `-h`, `--help` | | Print usage and exit |
| `-i`, `--input` | FILE | Path to the `.logic` file. Required except with `--repl`/`--lsp` |
| `-t`, `--target` | TARGET | A target below, or `lint`, `solve`, `repl`, `lsp`. Default is `lint` |
| `-o`, `--output` | PATH | Output directory (created if missing). Required for every emitter target; ignored by `lint` and `solve` |
| `--java-package` | PKG | Package for the `java` target. Default `ontologic.generated` |
| `--base-iri` | IRI | Base IRI for `owl` and `shacl`. Default: the ontology's first namespace IRI (trailing `#` or `/` stripped), else `http://example.org/ontologic` |
| `-p`, `--prover` | z3, cvc5, vampire, native, auto | Solver backend for `--solve`. Default `auto` |
| `--neo4j-edition` | community, enterprise | Edition for `neo4j` constraints. Default `enterprise`; with `community`, node-property-existence constraints are written commented out |
| `--render` | | After `mermaid` or `d2` generation, call `mmdc` or `d2` to write an `.svg` |
| `--repl` | | Start the interactive REPL (same as `-t repl`) |
| `--cnf` | | Print the clausal normal form of the (linted) ontology to stdout and exit |
| `--lsp` | | Start the Language Server on stdin/stdout (same as `-t lsp`) |
| `--solve` | | Run the consistency and coherence checks (same as `-t solve`) |
| `--warn-unmapped` | | Report axioms that cannot be mapped to field constraints, even for targets that do not warn by default. With `-t lint` this is the only way to see them |
| `--explain-unsat` | | With `--solve`: on UNSAT print the unsatisfiable core |
| `--inspect-model` | | With `--solve`: on SAT print the full model valuation |
| `--free-constants` | | Treat undeclared free variables in axioms as `Entity` constants (applied before linting and solving) |
| `-T`, `--solve-timeout` | SECONDS | Positive integer. Enforced for z3, cvc5, vampire, and native |
| `--solve-memory` | MB | Positive integer. Z3 only; ignored with a warning for other provers |
| `--lib-path` | DIR | Extra import search directory; repeatable. Also `$ONTOLOGIC_PATH` |

## Which mode runs

Checked in this order after the file loads and lints cleanly:

1. `--lsp` or `-t lsp`: start the language server (no input needed).
2. `--repl` or `-t repl`: start the REPL (no input needed).
3. Otherwise `-i` is required (`Error: --input is required (or use --repl / --lsp)`, exit 1).
4. Load the file and its imports. Failure: parse or import error printed, exit 1.
5. Lint. Any error: errors printed, exit 1. Nothing further runs.
6. `--cnf`: print CNF, exit 0.
7. `--solve` or `-t solve`: run the solver.
8. Otherwise the target: `lint` (the default) prints `✅ Logic Validated successfully.`; an emitter writes files into `-o`.

So `--cnf` wins over `--solve`, which wins over `-t <emitter>`.

## Targets

Names accepted by `-t`; aliases are equivalent. "Unmapped" says whether unmapped-axiom warnings are on by default (`--warn-unmapped` turns them on for the rest).

| Target | Aliases | Files written | Unmapped by default |
|--------|---------|---------------|---------------------|
| `java` | | one `<Class>.java` per concept, plus `package-info.java` if there are unmapped axioms | yes |
| `python` | | `models.py` | yes |
| `rust` | | `models.rs` | yes |
| `go` | `golang` | `models.go` | yes |
| `ts` | `typescript`, `zod` | `models.ts` | yes |
| `openapi` | | `openapi.yaml` | yes |
| `graphql` | `gql` | `schema.graphql` | yes |
| `smt` | `smtlib` | `spec.smt2` | no |
| `neo4j` | | `graph.cypher`, `constraints.cypher` | no |
| `owl` | | `ontology.owl` | no |
| `jsonschema` | `json` | `schema.json` | yes (CLI only; JSON has no comments) |
| `shacl` | | `shapes.ttl` | no |
| `mermaid` | | `class_diagram.mmd` (+ `.svg` with `--render`) | no |
| `d2` | | `diagram.d2` (+ `.svg` with `--render`) | no |
| `protobuf` | `proto`, `proto3` | `schema.proto` | no |
| `cpp` | `c++` | `models.hpp` | yes |
| `sql` | `postgres`, `postgresql`, `ddl` | `schema.sql` | yes |
| `tptp` | `p`, `fof` | `theory.p` | yes |

Special targets: `lint`, `solve`, `repl`, `lsp`. An unknown name prints `Unknown target: foo` and exits 1; an emitter without `-o` prints `Error: --output is required for target: ts` and exits 1. Details for each emitter: [Targets and emitters](targets-and-emitters.md).

Each successful emission prints `Generated <label> in <dir>`, for example `Generated TypeScript/Zod models in out/ts`.

## Environment variables

| Variable | Effect |
|----------|--------|
| `ONTOLOGIC_PATH` | `:`-separated list of directories searched for imports, after `--lib-path` directories and before the built-in locations |

External solvers (`z3`, `cvc5`, `vampire`) and renderers (`d2`, `mmdc`) are located through `PATH`.

## Exit codes

| Code | When |
|------|------|
| 0 | Lint passed; files emitted; `--cnf` printed; `--solve` found the ontology consistent and every concept satisfiable; REPL/LSP exited normally |
| 1 | Missing `--input`; file not found; parse error; import error (not found, circular); any lint error; unknown target; missing `-o`; unknown `--prover`; `--solve` reported UNSAT, empty concepts, or a solver error |
| 2 | `--solve` was inconclusive: the solver answered `unknown` (including a timeout), or the coherence check could not run |

Command-line parse errors (for example a non-positive `-T`) print the message plus usage and exit 1. For `--solve` with several results, the worst wins (1 over 2 over 0), which makes it safe in CI:

```bash
ontologic-exe -i model.logic -t solve -p z3 -T 60 || { echo "ontology check failed"; exit 1; }
```

## Example invocations

```bash
ontologic-exe -i fleet.logic -t lint                         # lint only
ontologic-exe -i fleet.logic -t lint --warn-unmapped         # also list unmapped axioms
ontologic-exe -i fleet.logic --solve -p cvc5 -T 30           # solve with a timeout
ontologic-exe -i fleet.logic -t java -o out/java --java-package com.acme.fleet
ontologic-exe -i fleet.logic -t owl  -o out/owl  --base-iri http://example.org/other#
ontologic-exe -i fleet.logic -t neo4j -o out/neo --neo4j-edition community
ontologic-exe -i app.logic -t ts -o out/ts --lib-path ./shared
```

`--warn-unmapped` with lint:

```text
⚠️  Warning: 1 complex / conditional axiom(s) could not be mapped to target models field constraints:
fleet.logic:17:2: warning: [WUnmappedAxiom] forall v (Truck(v) implies not Car(v))
✅ Logic Validated successfully.
```

Next: [Targets and emitters](targets-and-emitters.md)
