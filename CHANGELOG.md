# Changelog

All notable changes to OntoLogic are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

Entries before 1.5.1 were back-filled from git history. v1.4.0 and v1.5.0 were
tagged after the fact, on their version-bump commits.

## [1.8.3] - 2026-11-11

Emitter, REPL and prover fixes found while writing the user guide, and a warning for answers
reached without arithmetic.

### Added
- **Warning when a prover without arithmetic gives an all-clear.** The native prover and
  Vampire read `gt`, `gte`, `lt` and `lte` without arithmetic, so their SAT can miss a conflict
  that needs it (an integer gap such as `gt 5` with `lt 6`). When the ontology uses those
  comparisons and one of them reports SAT or every concept satisfiable, `--solve` prints a
  warning on stderr. The REPL adds the same line to `:solve`, `:model`, `:explain`, `:unsat`
  and a refuted `:prove`, and the language server adds it to the `ontologic.solve` result.
  `auto` warns only when it falls back to the native prover. Z3 and CVC5 answers, and every
  UNSAT, are unchanged.

### Fixed
- **Repeated bounds in generated Python and Java.** A subclass that restated an inherited
  bound produced `Field(le=90, ge=0, le=130)` or two `@Max` annotations, which neither
  language accepts. The IR now keeps only the tightest lower and upper bound per property.
- **Invalid `openapi.yaml` for subclasses with their own properties.** Their properties
  were emitted one level too shallow under `allOf`; they are now nested correctly.
- **`:explain` / `--explain-unsat` answered SAT after `:solve` reported UNSAT.** The unsat-core
  query left out the property bound assertions the consistency check makes. It now includes
  them, named, so the core cites the conflicting bounds.
- **Native prover and Vampire missed plain numeric-bound conflicts** (a universal `gte 100`
  with an existential `lt 50`). Both now receive background axioms for each pair of bounds
  that no number satisfies together. The native prover also reads a bare property name in a
  comparison as that property of the quantified entity, as the SMT and TPTP backends do,
  instead of as a free variable. Conflicts that need real arithmetic (integer gaps) still need
  Z3 or CVC5.
- **VS Code snippets expanded to obsolete syntax.** They now use the current grammar, and the
  extension README and `build_extension.sh` report the real package version.

## [1.8.2] - 2026-11-08

Fixes to the v1.8.1 solver resource controls.

### Fixed
- **`--solve-timeout` was ignored by CVC5.** `--tlimit` was passed after the `-` stdin
  marker, where cvc5 ignores options. It now comes before `-`.
- **Timeouts behave the same on every backend.** External solvers now also run under a
  wall-clock limit: `--solve-timeout` plus a 2 s grace period, after which the child process
  is killed. The backend's own flag still fires first in the normal case.
- **A cvc5 timeout was reported as a solver error.** cvc5's "interrupted by timeout" abort
  (exit 134) was reported as "SMT Solver Error" (exit 1). It, and a wall-clock timeout, are
  now reported as `Unknown` (exit 2).
- **`--solve-timeout` and `--solve-memory` reject 0 and negative values.** Previously Z3
  read `-T 0` as "no limit" while the native prover read it as "already expired".
- **`--solve-memory` warns when it cannot apply.** It still applies only to Z3. With
  `-p cvc5`, `-p vampire` or `-p native` it now prints a warning on stderr saying it is
  ignored; with `auto` the warning says it applies only if Z3 is selected.

### Notes
- **Correction to the 1.8.1 entry below.** The removed ground assertions targeted the plain
  relation symbol (`lt`), but the FOL theory sent to the solver constrains `rel_lt`. Removing
  them did not change any SAT/UNSAT verdict, and the irreflexive-relation example solves as
  `Sat` with or without that change.
- **Known limitation.** For Z3 and CVC5, the coherence check (`findUnsatConcepts`) runs all
  concepts in one solver process, so `--solve-timeout` is one budget for the whole batch.
  Vampire and native get the budget once per concept.

## [1.8.1] - 2026-10-17

SMT relational semantics correction and external/native solver timeout & memory resource controls.

### Fixed
- **SMT Relational Fact Elimination (`src/Emitters/SMT.hs`):**
  - Removed spurious ground assertions `(assert (r D1 D2))` on concept constants emitted by `emitRelations`.
  - Relations are now declared via `(declare-fun r (Entity Entity) Bool)` without falsely treating concept universals as particulars.
  - Fixes false UNSAT contradictions on irreflexive and strict relations (`(def-relation lt Thing Thing)` with `(forall (x) (not (lt x x)))` now solves as `Sat`).

### Added
- **Solver Resource Limits & Options (`src/Solver.hs`, `src/Main.hs`):**
  - Added `SolverOptions` record (`optTimeoutSeconds`, `optMemoryLimitMb`) and `defaultSolverOptions`.
  - Added `*WithOptions` variants for all solver operations: `runProverWithOptions`, `runProverRawWithOptions`, `checkConsistencyWithOptions`, `proveSubsumptionWithOptions`, `findUnsatConceptsWithOptions`, and `explainUnsatWithOptions`.
  - Added CLI options `--solve-timeout` / `-T <SECONDS>` and `--solve-memory <MB>` to `ontologic-exe`.
  - Propagates timeouts and memory limits to prover backends:
    - Z3: `-T:<sec>`, `-memory:<MB>`
    - CVC5: `--tlimit=<ms>`
    - Vampire: `-t <sec>`
    - NativeProver: `cfgTimeoutMs` (Resolution) and `tcTimeoutMs` (Tableaux)
  - Maintained full backwards compatibility for existing call sites defaulting to `defaultSolverOptions`.

## [1.8.0] - 2026-10-05

Common Logic / CLIF interop and upstream extensions port: parser sugar, declared individuals, free constants, 0-ary predicates, lexical extensions, and CLIF conformance suite.

### Added
- **Parser Sugar & Desugaring (`src/Parser.hs`):**
  - Desugars arbitrary arity n-ary `(and ...)` and `(or ...)` into binary right-nested `And`/`Or` AST nodes while preserving unary unwrapping and nullary `Top`/`Bottom`.
  - Added `if` as a first-class synonym for `implies` without altering `FOL` constructors.
  - Supported zero-arity function application terms `(f)` in term positions without syntactic ambiguity.
- **Declared Individuals & Free Constants (`src/OntoLogic.hs`, `src/Parser.hs`, `src/FOLTheory.hs`, `src/Emitters/TPTP.hs`):**
  - Added `individuals :: [(Name, Maybe Name)]` field to `Registry` with `emptyRegistry`, `mergeRegistries`, and `deduplicateRegistry` support.
  - Added `(def-individual <name> [<concept>])` syntax in parser and source coordinate tracking in `SourceTable`.
  - SMT and TPTP translation for declared individuals (`ind_<name>`, `is_<concept>(ind_<name>)`).
  - Added opt-in `--free-constants` CLI flag and `promoteFreeConstants` in `FOLTheory.hs` to promote undeclared free variables to individuals.
  - Allowed 0-ary user predicates `(declare-fun up_<p> () Bool)` in SMT and FOL theories.
- **Lexical Extensions & Identifier Charset (`src/Parser.hs`):**
  - Supported multi-line C-style block comments (`/* ... */`) and Common Logic / Scheme block comments (`#| ... |#`).
  - Supported C-style line comments (`//`) alongside existing Lisp comments (`;`).
  - Extended identifier character set to support punctuation, arithmetic symbols, and namespaced identifiers (`_:-./+*'`, `+*/<>=!&|'~`).
  - Added boundary protection on keyword recognition to prevent prefix matching on extended identifiers (`android`, `if-then`, `forall-devices`).
- **CLIF Interop Conformance Suite (`test/fixtures/clif-interop/`, `test/ClifInteropSpec.hs`):**
  - 10 hand-crafted Apache-2.0 `.logic` conformance test fixtures covering equality, n-ary connectives, conditional implications, function terms, comments, extended identifiers, syllogisms, zero-arity predicates, quantified coherence, and individual contradiction detection.
  - End-to-end integration tests asserting clean parsing, 100% translation coverage with zero skipped axioms, and SAT/UNSAT reasoning across Z3, CVC5, and native provers.

## [1.7.0] - 2026-10-04

Canonical Clausal Normal Form (CNF) IR, Robinson First-Order Unification, Native Ordered Resolution saturation engine, Analytic Free-Variable Semantic Tableaux, and Zero-Dependency Solver Fallback.

### Added
- **Canonical Clausal Normal Form (CNF) Intermediate Representation (`src/IR/CNF.hs`):**
  - Dedicated Fourth IR level modeling First-Order Logic in canonical clausal normal form (`Term`, `Literal`, `Clause`, `CNFTheory`).
  - Supports variable identifiers (`VarId`), Skolem functions/constants (`SkolemId`), predicates with arbitrary arity, and built-in equality/disequality literals (`EqT`, `NeqT`).
- **Deterministic 7-Stage Normalization & Clausification Pipeline (`src/IR/Clausify.hs`):**
  - Desugaring (eliminates `Iff`, `Implies`) -> Negation Normal Form (NNF with De Morgan laws & quantifier duality) -> Variable Standardization Apart -> Outer Skolemization -> Universal Quantifier Stripping -> Clausal Distribution ($\lor$ over $\land$) -> Tautology Elimination and Set Simplification.
  - Converts arbitrary First-Order Logic formulas and full ontology registries into canonical `CNFTheory`.
- **First-Order Unification Engine (`src/Prover/Unification.hs`):**
  - Robinson's Most General Unifier (MGU) algorithm with occurs-check preventing cyclic infinite terms.
  - Substitution algebra with substitution application (`applySubstLit`, `applySubstTerm`) and associative composition ($\sigma_1 \circ \sigma_2$).
  - Dual clause subsumption checking ($C \subseteq_\sigma D$) for forward and backward redundancy pruning.
- **Native Ordered Resolution Prover Engine (`src/Prover/Resolution.hs`):**
  - Given-Clause saturation loop (Otter/DISCOUNT model) for refutation theorem proving directly in Haskell.
  - Binary resolution, positive factoring, and equality resolution inference rules.
  - Directed Acyclic Graph (DAG) refutation proof reconstruction (`formatProofTrace`) from empty clause $\Box$ back to input axioms.
- **Analytic Free-Variable Semantic Tableaux (`src/Prover/Tableau.hs`):**
  - Analytic Smullyan-style semantic tableaux ($\alpha, \beta, \gamma, \delta$ rules) with branch closure unification.
  - Finite Herbrand countermodel generation and extraction for non-theorems and satisfiable theories (`formatCounterModel`).
- **Zero-Dependency Solver Fallback (`src/Solver.hs`):**
  - Registered `NativeProver` in solver framework.
  - `AutoProver` seamlessly falls back to `NativeProver` when external binaries (`z3`, `cvc5`, `vampire`) are absent from `$PATH`, guaranteeing zero-setup ontology reasoning out-of-the-box.
- **CLI & REPL Integration (`src/Main.hs`, `src/REPL.hs`):**
  - Added `--cnf` CLI flag to dump canonical CNF clauses to stdout.
  - Supported `--solve -p native` for command-line native reasoning.
  - Added `:cnf` command to REPL to inspect active ontology clausal representations.
  - Added `:prover native` to REPL.
- **Comprehensive Benchmarks & Verification (`test/NativeProverSpec.hs`, `test/IndustrialBenchmarkSpec.hs`, `docs/benchmarks/`):**
  - Classical FOL benchmarks: Aristotelian Syllogisms (Barbara, Celarent, Darii, Ferio), Russell's Barber paradox, Drinker's paradox, Pelletier Problem 18, equational reasoning.
  - Industrial ontology stress testing across BFO Manufacturing, Acme Unified IoT, Security Trust, and Autonomous AI.

## [1.6.0] - 2026-10-01

Automated Theorem Prover (ATP) expansion via Vampire & TPTP FOF, PostgreSQL / ANSI SQL DDL schema emitter, Language Server Protocol (LSP) features, and architectural manifesto.

### Added
- **PostgreSQL / ANSI SQL DDL Target (`src/Emitters/Sql.hs`):**
  - Strongly typed relational schema generator emitting `CREATE TABLE IF NOT EXISTS` with primary keys, foreign key inheritance chains, column nullability, and default values.
  - Column-level numeric `CHECK` constraints for property bounds and conditional axioms.
  - Automatic junction table generation for binary relationships (`def-relation`) with composite primary keys and foreign keys.
  - Target registered under `"sql"`, `"postgres"`, `"postgresql"`, and `"ddl"` in CLI and REPL.
- **Vampire ATP Prover Bridge & TPTP FOF Emitter (`src/Emitters/TPTP.hs`, `src/Solver.hs`):**
  - Standards-compliant TPTP First-Order Form (FOF) problem formulation (`fof(name, axiom, ...)`).
  - External prover bridge integrating Vampire automated theorem prover alongside Z3 and CVC5.
  - Subsumption conjecture proving ($A \sqsubseteq B$) and counterexample refutation via Vampire.
  - Target registered under `"tptp"` in CLI and REPL.
- **Language Server Protocol (LSP) Engine Modernization (`src/LSP.hs`):**
  - Full semantic tokens provider (`textDocument/semanticTokens/full`) for high-fidelity syntax highlighting.
  - Hover documentation tooltips (`textDocument/hover`) showing concept parentage, attached properties, and comments.
  - Symbol rename refactoring (`textDocument/rename` and `prepareRename`) with workspace-wide text edits.
  - On-demand code formatting provider (`textDocument/formatting`).
- **Architectural Rationale Manifesto (`docs/WHY_ONTOLOGIC.md`):**
  - Comprehensive manifesto detailing the 5 fatal anti-patterns in modern systems (Distributed Logic Drift, Sloppiness Tax, LLM Hallucinations, Academic OWL Trap, Data vs. Logic Contracts).
  - Root `README.md` and `docs/README.md` links updated.

## [1.5.2] - 2026-09-28

Post-v1.5.1 review remediations: FOL sort safety, multi-variable SAT abstraction, Go string escaping, and CRLF comment normalization.

### Fixed
- **FOL translation:** arguments to registered user predicates are checked
  during translation to strictly require Entity sorts; property applications
  and arithmetic terms are rejected with a clear diagnostic instead of causing
  an SMT solver sort mismatch.
- **FOL translation:** shorthand property equality and comparison expressions
  guard against variable shadowing (`prop notElem bound`) so bound variables
  sharing a name with a property are translated as variable equality.
- **Linter:** multi-variable existential axioms are excluded from propositional
  abstraction (`countExistentials == 1` only), avoiding false-positive
  contradiction errors when distinct existential variables satisfy disjoint
  concepts.
- **Go emitter:** `escapeGo` uses full string escaping (`escapeTargetString`),
  properly escaping `\n`, `\r`, `\t`, and quotes so multiline conditional
  constraint descriptions compile cleanly with `go vet`.
- **Emitters:** `splitLines` in `IR.hs` normalizes CRLF (`\r\n`) without
  producing empty comment lines.

### Refactored
- **FOL translation:** deduplicated symbol declarations across `buildTheory`
  and `buildNamedTheory` via shared `commonDecls`.

## [1.5.1] - 2026-09-28

Fixes for the code-review findings on v1.5.0 (#68).

### Fixed
- **FOL translation:** a one-argument use of a property or relation, such as
  `(temperature x)`, is skipped as unsupported instead of producing an
  undeclared SMT symbol.
- **FOL translation:** user-defined predicates are declared as `up_<name>`, so
  they can no longer clash with SMT-LIB built-ins (`distinct`, `div`, ...),
  base declarations (`subClassOf`), or function names.
- **FOL translation:** user-predicate arguments must be Entity-sorted.
  Property applications and arithmetic terms are rejected instead of causing a
  solver sort mismatch.
- **FOL translation:** a predicate used with two arities is skipped with a
  reason instead of being declared twice.
- **Linter:** existential axioms are checked one at a time against the
  universal axioms, removing false "Semantic contradiction" errors in the
  linter and LSP. Concept coherence uses universal axioms only.
- **Linter:** concept-typed quantifiers keep their sort guard when quantifiers
  are stripped.
- **Linter:** DPLL runs only when Horn resolution found no global
  contradiction, and its "Involved" list is a minimal set of source axioms,
  each listed once.
- **Emitters:** every line of a multi-line unmapped axiom is commented, so a
  string constant containing a newline no longer breaks generated code.
- **Emitters:** Java writes the unmapped-axiom warning once, to
  `package-info.java`, instead of into every class file.

### Changed
- User-defined predicates appear as `up_<name>` in generated SMT.
- The DPLL finding now reads "Propositional clauses are jointly unsatisfiable
  (DPLL)".
- The unmapped-axiom warning is added by the target table instead of by each
  emitter. Calling an emitter function directly (e.g. `emitCypher`) no longer
  includes it. OWL output now carries the warning as an XML comment.
- `nubOrd` comes from `Data.Containers.ListUtils`; the copy exported by
  `OntoLogic` is removed.

## [1.5.0] - 2026-09-28

Tech-debt remediation.

### Added
- Sort-aware typed quantifiers in the FOL theory, emitting guarded forms for
  concept sorts.
- Translation of user-defined unary and n-ary predicates, and declarations for
  uninterpreted functions.
- Unmapped-axiom warnings as comments in generated code and schemas.
- Clause-origin tracing in DPLL contradiction diagnostics.
- Tests for multi-change, multi-line, and insertion edits in incremental LSP
  sync.

### Fixed
- The DPLL fallback in the propositional linter was never reached.

### Changed
- Replaced O(n²) `nub` with O(n log n) `nubOrd` in the registry, FOL theory,
  and SMT emitter.

## [1.4.0] - 2026-09-26

### Added
- Full FOL language coverage and an expanded SMT theory.
- Native SMT-LIB2 named unsat-core extraction for Z3 and CVC5.
- `--neo4j-edition` CLI flag and source-located unmapped-axiom diagnostics.
- Embedded propositional SAT linter (Horn resolution with a DPLL fallback),
  an async SMT worker in the language server, and incremental document sync.

### Fixed
- Code-review findings in the Protobuf, C++, LSP, and VS Code extension (#67).

## [1.3.0] - 2026-09-25

### Added
- LSP code actions backed by the SMT solver, proof inspection in the REPL, and
  Protobuf and C++ emitters (#66).

## [1.2.0] - 2026-09-25

### Added
- Software-systems ontology, cardinality and optionality, SMT proof
  inspection, and a unified ecosystem model (#65).

### Fixed
- Name shadowing of `imports` in an emitter.

## [1.1.1] - 2026-09-25

### Added
- Conditional-constraint parity across emitters, relational code generation,
  and unmapped-axiom diagnostics (#63).
- Source positions on AST nodes for diagnostics, and an Autonomous AI domain
  ontology (#64).

## [1.1.0] - 2026-09-24

### Added
- JSON Schema (Draft 2020-12) and W3C SHACL emitters.
- Rust and Go struct emitters with validation methods.
- TypeScript/Zod, OpenAPI 3.1, GraphQL SDL and SMT-LIB2 emitters, and an
  interactive REPL.
- Live Z3 solver, subsumption reasoning, and a Language Server Protocol
  engine.
- VS Code extension and a multi-prover backend (Z3, CVC5, Vampire).
- BFO 2020 ontology bindings and cross-ecosystem symbols mapped to BFO.
- Capability manifest and schemas.
- CCO/DSF mid-level ontology alignment, a morphisms plant reference, and
  conditional validators (#62).
- Foundations (#45): registry helpers, a shared target table, cycle safety,
  stricter parsing, and standard-library lookup.

### Changed
- Semantics and solver (#46): bound scoping, inheritance, valid SMT output,
  and an instance-level FOL theory.
- Emitters (#47): compilable code, loadable graphs, and configurable IRIs.
- Language server (#50): byte-accurate framing, import resolution, and real
  diagnostic positions.
- Examples model software code as instance data with repository provenance
  (#51), separate software code from software process per BFO (#56), and align
  with BFO 2020 realism (#61).

### Fixed
- Solver failures are reported as failures, and unknown provers are rejected
  (#39). The CLI exits with code 2 when the solver answers unknown (#40).
- The REPL exits cleanly on EOF / Ctrl-D (#41).
- The VS Code extension runs the CLI with `execFile`, validates the prover, and
  finds stack binaries (#37).
- OWL and SHACL resolve prefixed names into their namespace and agree with each
  other (#52).
- Neo4j enterprise-only constraints are separated so the graph loads on
  Community Edition (#57).
- The solver translates binary property relations, boolean literals, and 0-ary
  predicates (#60).
- Capability manifest entrypoints, test command, and checksums (#42, #43).

## [1.0.0] - 2026-09-13

First tagged release.

### Added
- S-expression ontology language with concepts, properties, relations, and
  first-order axioms.
- Java (one file per class, Jakarta validation, configurable package via
  `--java-package`), Python (Pydantic), OWL, Neo4j Cypher, Mermaid and D2
  emitters.
- Typed `PropertyType` ADTs and a Model IR compiler pipeline.
- Axiom-to-constraint extraction, with validation queries.
- Linter checks: cycle detection, local constraints, propositional and numeric
  contradictions, undeclared parents and domains, duplicates, and cross-axiom
  contradictions.
- Multi-entity relational axioms and graph transpilation.
- Modular namespaces and multi-file imports.
- Standard libraries: BFO 2020, CCO and UCO; STIX 2.1, MITRE ATT&CK and D3FEND;
  MITRE ATLAS, NIST AI RMF, ISO 42001 and the EU AI Act; NIST SP 800-53 Rev 5,
  OSCAL and NIST CSF 2.0; OCSF and SIGMA.
- BFO, Acme and domain example ontologies.
- Test suites for the parser, linter, emitters, CLI, and compiled output, plus a
  GitHub Actions workflow.
- Release packaging script.

### Fixed
- OWL output is well-formed RDF/XML with standard W3C namespaces.
- Python classes are sorted topologically to avoid `NameError` on subclasses.
- Neo4j class nodes are separate from data instances and use `elementId`;
  string literals are escaped.
- Diagram rendering no longer passes input through a shell.
- The CLI exits with a failure code on validation errors and unknown targets.

### Changed
- License changed to Apache 2.0.

[1.7.0]: https://github.com/bsommers/OntoLogic/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/bsommers/OntoLogic/compare/v1.5.2...v1.6.0
[1.5.2]: https://github.com/bsommers/OntoLogic/compare/v1.5.1...v1.5.2
[1.5.1]: https://github.com/bsommers/OntoLogic/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/bsommers/OntoLogic/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/bsommers/OntoLogic/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/bsommers/OntoLogic/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/bsommers/OntoLogic/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/bsommers/OntoLogic/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/bsommers/OntoLogic/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/bsommers/OntoLogic/releases/tag/v1.0.0
