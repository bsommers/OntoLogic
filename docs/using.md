# Using OntoLogic

A task-oriented guide: pick the job you want to do and follow the recipe. For
depth, each section links to the [user guide](user-guide/README.md).

- [Build and install](#build-and-install)
- [Write a first ontology](#write-a-first-ontology)
- [Check an ontology](#check-an-ontology)
- [Prove things about it](#prove-things-about-it)
- [Generate code, schemas and diagrams](#generate-code-schemas-and-diagrams)
- [Reuse the standard library](#reuse-the-standard-library)
- [Work interactively](#work-interactively)
- [Use it in your editor](#use-it-in-your-editor)
- [Integrate with other tools](#integrate-with-other-tools)
- [Where to go next](#where-to-go-next)

The examples use `ontologic`. From a source checkout, replace it with
`stack exec ontologic-exe --`.

## Build and install

```bash
git clone https://github.com/bsommers/OntoLogic.git
cd OntoLogic
stack build --ghc-options="-Wall -Werror"
stack test --ghc-options="-Wall -Werror"
```

For a standalone binary, `./scripts/package_release.sh` builds an archive under
`dist/`; extract it and copy `bin/ontologic` onto your `PATH`. Details are in
[installation](user-guide/installation.md).

## Write a first ontology

```lisp
;; sensors.logic
(def-concept Device)
(def-concept Sensor Device)

(def-property serial       Device String)
(def-property batteryLevel Sensor Integer)
(def-property isActive     Sensor Boolean)

(def-relation monitors Sensor Device)

;; Battery level is a percentage
(forall (s)
  (implies (Sensor s)
    (and (gte batteryLevel 0) (lte batteryLevel 100))))
```

- `def-concept Name [Parent]` declares a class and its parent.
- `def-property name Domain Type` takes `Integer`, `Float`, `Double`, `String`,
  `Boolean`, or a concept name.
- `def-relation name Domain Range` declares a binary relation.
- `forall` / `exists` with `implies`, `iff`, `and`, `or`, `not` build axioms;
  `gt`, `gte`, `lt`, `lte` bound numeric properties.

See the [language reference](user-guide/language-reference.md).

## Check an ontology

```bash
ontologic -i sensors.logic -t lint
```

Lint catches undeclared parents, domains and relation endpoints, taxonomy cycles,
duplicate definitions, contradictory axioms, and empty numeric intervals across
axioms. Findings print as `file:line:col: error: message` and the exit code is
non-zero. Add `--warn-unmapped` to see axioms a given target cannot express
instead of having them dropped quietly.

## Prove things about it

```bash
ontologic -i sensors.logic --solve                 # auto-select a prover
ontologic -i sensors.logic --solve -p z3           # z3, cvc5, vampire, native, auto
ontologic -i sensors.logic --solve -T 30           # 30 second limit, every backend
ontologic -i sensors.logic --solve --explain-unsat # show the conflicting axioms
ontologic -i sensors.logic --solve --inspect-model # print a satisfying model
```

`--solve` reports **consistency** (can the axioms hold at all) and **coherence**
(which concepts can have no instance). Exit code `0` means both pass, `1` means
unsatisfiable or an error, `2` means the solver answered unknown. Axioms the
solver encoding cannot express are listed first. With no external prover
installed, `auto` falls back to the built-in native prover.

Other useful switches: `--free-constants` treats undeclared free variables as
constants, `--solve-memory MB` limits Z3 memory, and `--cnf` prints the clausal
normal form. Subsumption (`:prove A B`) and empty-concept search (`:unsat`) are
REPL commands. See [axioms and reasoning](user-guide/axioms-and-reasoning.md).

## Generate code, schemas and diagrams

```bash
ontologic -i sensors.logic -t python  -o out/py
ontologic -i sensors.logic -t sql     -o out/sql
ontologic -i sensors.logic -t java    -o out/java --java-package com.example.models
ontologic -i sensors.logic -t owl     -o out/owl  --base-iri https://example.test/onto
ontologic -i sensors.logic -t d2      -o out/diagram --render
```

| Goal | Targets |
| :--- | :--- |
| Typed models with validation | `java`, `python`, `rust`, `go`, `ts` (Zod), `cpp` |
| API and storage contracts | `openapi`, `graphql`, `jsonschema`, `protobuf`, `sql` |
| Knowledge graph and semantic web | `neo4j`, `owl`, `shacl` |
| Proof inputs | `smt`, `tptp` |
| Diagrams | `mermaid`, `d2` (add `--render` for SVG) |

Run `ontologic --help` for the live list. Aliases such as `typescript`, `golang`,
`postgres`, `proto` and `gql` also work. Notes:

- **Names.** `--java-package` defaults to `ontologic.generated`. The OWL and
  SHACL base IRI defaults to the ontology's first declared namespace, then to
  `http://example.org/ontologic`.
- **Neo4j** writes `graph.cypher` (loads on Community Edition) and
  `constraints.cypher` (existence constraints, Enterprise only). Use
  `--neo4j-edition community` to adapt the constraints.
- **Diagrams** need `mmdc` (Mermaid CLI) or `d2` on your `PATH` for `--render`;
  without them you still get the `.mmd` / `.d2` source.

Full table of outputs: [targets and emitters](user-guide/targets-and-emitters.md).
Visual output: [visualization](user-guide/visualization.md).

## Reuse the standard library

```lisp
(namespace "bfo" "http://purl.obolibrary.org/obo/bfo.owl#")
(import "bfo_2020.logic")
(import "cco_core.logic")
```

Library files resolve by bare name. The search order is the importing file's
directory, `$ONTOLOGIC_PATH` (`:`-separated), the directory beside the binary, the
package data directory, `./ontologic-lib`, then the current directory. Add your
own folders with `--lib-path DIR` (repeatable). See the
[standard library](standard-library.md) for what each module contains and the
[domain gallery](domains/README.md) for complete models built on it.

## Work interactively

```bash
ontologic --repl
```

```text
ontologic> :load sensors.logic
ontologic> (def-concept Gateway Device)
ontologic> :lint
ontologic> :prove Sensor Device
ontologic> :unsat
ontologic> :emit ts
```

| Command | Action |
| :--- | :--- |
| `:load <file>` | Load a file and its imports |
| `:show` | List concepts, properties, relations, axiom count, active prover |
| `:lint` | Run the linter on the session |
| `:prover [name]` | Show or set `z3`, `cvc5`, `vampire`, `native`, `auto` |
| `:solve` / `:check` | Consistency check |
| `:explain`, `:model` | Unsat core, satisfying model |
| `:prove A B` | Prove `A` is subsumed by `B`, or show a counterexample |
| `:unsat` | Find empty concepts |
| `:cnf`, `:ir` | Show clausal normal form, or the compiled `ModelIR` |
| `:emit <target>` | Print any target's output |
| `:set base-iri X`, `:set java-package X` | Set emit options |
| `:clear`, `:help`, `:quit` | Session control |

Anything starting with `(` is added to the session. See [REPL](user-guide/repl.md).

## Use it in your editor

`ontologic --lsp` (or the `ontologic-lsp` binary) is a Language Server over
stdio. It gives live diagnostics, completion, hover, go-to-definition, rename,
formatting, semantic highlighting, and solver commands as code actions.

```bash
./editors/vscode/scripts/build_extension.sh        # builds the .vsix
code --install-extension <path-to-built>.vsix
```

For Neovim, point `nvim-lspconfig` at `ontologic-lsp` for `logic` files. See
[editor and LSP](user-guide/editor-and-lsp.md).

## Integrate with other tools

- **Gradle.** `./gradlew lintOntology` runs the linter; `./gradlew
  generateJavaModels` writes Java models into the `models-java` subproject.
- **Docker.** `docker-compose up -d` starts a local Neo4j (ports 7474 and 7687)
  for loading generated Cypher. Credentials come from `NEO4J_AUTH`.
- **CI.** Run `ontologic -i model.logic -t lint` and `--solve` as gates; both exit
  non-zero on failure.

## Where to go next

- Problems? [troubleshooting](user-guide/troubleshooting.md) and the
  [FAQ](user-guide/faq.md).
- Command reference: [CLI reference](user-guide/cli-reference.md).
- How it is built: [architecture](architecture.md).
- Why it exists: [purpose](purpose.md).
