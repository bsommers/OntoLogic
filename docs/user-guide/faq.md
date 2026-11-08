# FAQ

Short answers to common questions, with links to the pages that go deeper.

**What is OntoLogic for?**
Writing a domain model once as first-order logic, proving it is consistent, and generating the code, schemas, and diagrams from it so they cannot drift apart. See the [Quickstart](quickstart.md).

**Is the language Prolog or Datalog?**
No. Axioms are full first-order logic (disjunction, negation, existentials), not restricted to Horn clauses. See [Axioms and reasoning](axioms-and-reasoning.md) and [../dev/design/constraint_considerations.md](../dev/design/constraint_considerations.md).

**Do I need Z3, CVC5, or Vampire?**
No. Without any of them `--prover auto` uses a built-in native prover. But the native prover does not reason about numeric bounds like `(gt level 10)`, so install Z3 or CVC5 if your properties have numeric constraints. See [Installation](installation.md).

**Which prover should I use?**
Z3 for most ontologies; CVC5 as a second opinion; Vampire for heavy first-order reasoning without arithmetic; native when nothing is installed. If provers disagree, trust UNSAT from an SMT solver.

**What is the difference between lint and solve?**
Lint is a fast structural and pattern check that always runs. Solve invokes a theorem prover to find contradictions that need real reasoning, and also checks that every concept can have an instance. A lint error stops everything, so `--solve` only runs on lint-clean input. See [Axioms and reasoning](axioms-and-reasoning.md#layer-1-the-linter).

**What do "SAT" and "UNSAT" mean here?**
SAT: the axioms can all be true in some world, so the ontology is consistent. UNSAT: they cannot, so there is a contradiction (use `--explain-unsat` to see which axioms). `unknown`, exit code 2, is neither: the solver ran out of time or gave up.

**Why does `--solve` say a concept is "empty"?**
The axioms force that concept to have no instances (for example, it inherits two incompatible bounds, or a contradiction exists). It is a modelling error even if the whole ontology is otherwise consistent.

**Does the solver enforce cardinality such as `1..*`?**
No. Cardinality, `:optional`, and `:default` shape generated code (optional vs list fields, `NOT NULL`, SHACL counts). If you need them in reasoning, state them as axioms.

**How do I say two concepts are disjoint?**
`(forall (x) (implies (Truck x) (not (Car x))))`. The linter and solvers both understand it. There is no dedicated keyword.

**Why "could not be mapped to field constraints"?**
Emitters can turn `forall x. Concept(x) implies <comparisons on properties>` into field constraints. Disjointness, existentials, and relational rules have no field-level form, so they are reported (and written as a comment) instead. They are still verified by `--solve`. See [Targets and emitters](targets-and-emitters.md#unmapped-axioms).

**Can I generate several targets at once?**
One target per invocation. Script it: `for t in ts python sql; do ontologic-exe -i m.logic -t $t -o out/$t; done`. File names inside each directory are fixed.

**Where does the output go, and can I choose file names?**
Into the `-o` directory (created if needed) under fixed names such as `models.ts` and `schema.sql`; rename afterwards. See the file table in the [CLI reference](cli-reference.md#targets).

**How do I set the Java package or OWL base IRI?**
`--java-package com.acme.fleet` and `--base-iri http://example.org/ns#`; in the REPL, `:set java-package ...` and `:set base-iri ...`. Without `--base-iri`, the first `namespace` declaration is used.

**Can I split an ontology across files?**
Yes: `(import "file.logic")`. Imports are found next to the importing file, then via `--lib-path`, `$ONTOLOGIC_PATH`, and the bundled library. See [Language reference](language-reference.md#imports-and-search-path).

**Why can't I use a quoted namespace prefix?**
The prefix is an identifier: `(namespace bfo "http://...")`. Some older docs show `(namespace "bfo" ...)`, which does not parse.

**Can I declare individuals (instances)?**
Yes: `(def-individual depot1 Site)`. They can be used as terms in axioms. Larger instance data is better kept in a data format such as Turtle (see `test/fixtures/ecosystem_symbols.ttl` for a small sample).

**How do I use the standard ontologies like BFO or MITRE ATT&CK?**
`(import "bfo_2020.logic")` and refer to concepts with their prefix (`bfo:Process`). See [Standard library](standard-library.md).

**How do I get diagrams?**
`-t mermaid` or `-t d2`, add `--render` for SVGs (needs `mmdc` or `d2`). See [Visualization](visualization.md).

**Can I put OntoLogic in CI?**
Yes. `ontologic-exe -i model.logic -t lint` exits non-zero on any lint error, and `--solve` exits 1 on UNSAT or empty concepts and 2 on unknown. Add `-T` to bound the runtime. See [CLI reference](cli-reference.md#exit-codes).

**A solve takes forever. What can I do?**
Set `-T 60` so it ends with exit 2 instead of hanging, try another prover, check `--cnf` for blow-up, or split the ontology. Z3 also accepts `--solve-memory MB`.

**Why does the REPL not show my multi-line form?**
Each REPL line is parsed independently. Enter the form on one line, or `:load` a file.

**How do I check a subclass relationship?**
In the REPL, `:prove Truck Vehicle`. See [REPL](repl.md).

**How do I find where a lint error comes from in an imported file?**
Diagnostics carry the file and line of the declaration (`examples/domain_mining.logic:49:15: error: ...`), even when the root file is a different one.

**Which version am I running?**
The package version is in `package.yaml` and [../../CHANGELOG.md](../../CHANGELOG.md). The CLI has no `--version` flag.

**Where do I report problems or contribute?**
See the contributor workflow in the repository's `AGENTS.md`; the pre-push gate is `stack test --ghc-options="-Wall -Werror"`.

Next: [README (guide index)](README.md)
