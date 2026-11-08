# OntoLogic: Autonomous Replay Playbook & Architectural Learnings

This document is the **central master reference** for OntoLogic. It consolidates all implementation plans, architectural decisions, discovered bugs, edge cases, and step-by-step execution procedures so that the entire modern OntoLogic pipeline and test suite can be replayed, validated, and extended autonomously in a clean session.

---

## 📑 Central Plans Index

All formal implementation plans are preserved under `docs/superpowers/plans/`:

1. **[Milestone 1: OntoLogic Core Improvements](docs/superpowers/plans/2026-09-05-ontologic-core-improvements.md)**  
   *Scope:* Fixes OWL XML emitter syntax, introduces topological sorting for Python class definitions, decouples Neo4j TBox/ABox metamodel nodes, adds signed number Megaparsec support, supports Float/Double constraints in Java & Python, implements semantic symbol table validation in the linter, and adds cross-axiom interval contradiction checking.  
   *Pull Request:* [#2 on GitHub](https://github.com/bsommers/OntoLogic/pull/2)

2. **[Milestone 2: Robust Testing Suite](docs/superpowers/plans/2026-09-05-robust-test-suite.md)**  
   *Scope:* Fixes latent semantic defects in example domain models, adds unit tests for visualizer emitters (Mermaid & D2), adds an integration test suite validating all 12 example `.logic` models against all emitters, validates target code syntax (Python `ast.parse`, OWL XML well-formedness, `javac`), implements runtime validation behavior tests (Pydantic instantiation, Java Bean validation), and adds CLI ergonomic driver tests.

3. **[Milestone 3: Security Hardening, Error Handling & CI](docs/superpowers/plans/2026-09-07-security-and-hardening-fixes.md)**  
   *Scope:* Eliminates shell command injection via `callProcess`, sanitizes Cypher string values and identifiers, exits cleanly on validation failure and unknown targets without call stacks, supports configurable Java packages via `--java-package`, cleans stale binaries and dead dependencies, and establishes GitHub Actions CI.

4. **[Milestone 4: Type System Refactoring & Compiler Intermediate Representation (IR)](docs/superpowers/plans/2026-09-13-type-system-and-model-ir.md)**  
   *Scope:* Replaces stringly-typed attributes with formal Haskell ADTs (`PropertyType`, `CompOp`, `Value`), introduces a formal `ModelIR` compilation layer (`src/IR.hs`), decouples emitters into pure rendering views, handles conditional premise rules, and adds property-based fuzz testing.  
   *Pull Request:* [#3 on GitHub](https://github.com/bsommers/OntoLogic/pull/3)

5. **[Milestone 5: Multi-Entity Relational Axioms & Graph Transpilation](docs/superpowers/plans/2026-09-13-relational-axioms-and-graph-transpilation.md)**  
   *Scope:* Extends AST and parser to support binary relations `(def-relation ...)` and multi-variable logic, introduces `CompiledRelation` to `ModelIR`, emits rich Neo4j relationship schemas, W3C OWL `owl:ObjectProperty`, OOP association fields, and visualizer relationship arrows.  
   *Pull Request:* [#4 on GitHub](https://github.com/bsommers/OntoLogic/pull/4)

6. **[Milestone 6: Modular Namespacing & Multi-File Imports](docs/superpowers/plans/2026-09-14-modular-namespacing-and-imports.md)**  
   *Scope:* Implements `(import "path/to/file.logic")` and `(namespace "prefix")` syntax, recursive file import dependency loader with cycle detection, diamond deduplication, and qualified symbol resolution.  
   *Pull Request:* [#5 on GitHub](https://github.com/bsommers/OntoLogic/pull/5)

7. **[Milestone 7: 3-Tier Foundation: BFO 2020, CCO & UCO Standard Library](docs/superpowers/plans/2026-09-14-3-tier-cyber-ai-governance-and-grc-roadmap.md)**  
   *Scope:* Establishes standard library foundation in `ontologic-lib/` with Basic Formal Ontology (BFO 2020), Common Core Ontologies (CCO Core), and Unified Cybersecurity Ontology (UCO Observables). Adds identifier sanitization (`sanitizeIdent`) across Java and Python emitters for colon and hyphen namespaces.  
   *Pull Request:* [#6 on GitHub](https://github.com/bsommers/OntoLogic/pull/6)

8. **[Milestone 8: Cyber Threat Intelligence & MITRE Integration](docs/superpowers/plans/2026-09-14-3-tier-cyber-ai-governance-and-grc-roadmap.md)**  
   *Scope:* Formalizes STIX 2.1 / CVE / CWE vulnerability models (`stix_cve.logic`), MITRE ATT&CK Enterprise matrix (`mitre_attack.logic`), and MITRE D3FEND defensive countermeasures (`mitre_d3fend.logic`) with graph transpilation and CVSS / EPSS range constraints.  
   *Pull Request:* [#7 on GitHub](https://github.com/bsommers/OntoLogic/pull/7)

9. **[Milestone 9: AI Governance, Safety & Adversarial Threat Modeling](docs/superpowers/plans/2026-09-14-3-tier-cyber-ai-governance-and-grc-roadmap.md)**  
   *Scope:* Implements MITRE ATLAS AI attack vectors (`mitre_atlas.logic`), NIST AI RMF 1.0 governance framework (`nist_ai_rmf.logic`), and ISO/IEC 42001 & EU AI Act compliance ontologies (`iso_42001_eu_ai_act.logic`) with quantitative risk and autonomy level constraints.  
   *Pull Request:* [#8 on GitHub](https://github.com/bsommers/OntoLogic/pull/8)

10. **[Milestone 10: Cyber GRC & Automated Compliance-as-Code](docs/superpowers/plans/2026-09-14-3-tier-cyber-ai-governance-and-grc-roadmap.md)**  
    *Scope:* Encodes NIST CSF 2.0 (`nist_csf.logic`) and NIST SP 800-53 Rev 5 / OSCAL Baselines (`nist_sp800_53.logic`) with control hierarchy, implementation status, satisfaction relationships, and graph compliance checking.  
    *Pull Request:* [#9 on GitHub](https://github.com/bsommers/OntoLogic/pull/9)

11. **[Milestone 11: Real-Time Security Telemetry & Monitoring (OCSF & SIGMA)](docs/superpowers/plans/2026-09-14-3-tier-cyber-ai-governance-and-grc-roadmap.md)**  
    *Scope:* Encodes OCSF v1.1.0 security telemetry taxonomy (`ocsf_schema.logic`) and SIGMA detection rules with SIEM semantics (`sigma_rules.logic`), enabling full-stack real-time event validation, attack technique correlation, and defensive telemetry graphing.

12. **[Milestone 12: Web/API Emitters, SMT-LIB2 Verification & Interactive REPL](docs/superpowers/REPLAY_PLAYBOOK.md)**  
    *Scope:* Implements TypeScript/Zod runtime schemas, OpenAPI 3.1 YAML component specs, GraphQL SDL types and query schema, SMT-LIB2 / Z3 theorem prover verification backend, interactive command-line REPL (`ontologic --repl`), and patches all security scan findings to achieve Grade A (98/100).  
    *Pull Request:* [#13 on GitHub](https://github.com/bsommers/OntoLogic/pull/13)

13. **[Milestone 13: Live Z3 SMT Theorem Prover & Language Server Protocol (LSP) Engine](docs/superpowers/REPLAY_PLAYBOOK.md)**  
    *Scope:* Implements live Z3 SMT solver execution (`Solver.hs`), whole-ontology consistency checking, taxonomic subsumption proofs ($A \sqsubseteq B$), empty concept detection, and a full JSON-RPC stdio Language Server Protocol server (`LSP.hs`, `ontologic-lsp`) providing diagnostics, autocompletion, hover docs, and jump-to-definition.  
    *Pull Request:* [#14 on GitHub](https://github.com/bsommers/OntoLogic/pull/14)

14. **[Milestone 14: Official VS Code Extension & Marketplace Packaging](docs/superpowers/REPLAY_PLAYBOOK.md)**  
    *Scope:* Implements full Visual Studio Code extension package (`editors/vscode/`) with TextMate syntax grammar (`syntaxes/ontologic.tmLanguage.json`), bracket matching and auto-closing configuration, code snippets for concepts/relations/axioms, Language Server Protocol client activation, and interactive command palette actions for SMT solver checking. Bundles standalone `ontologic-1.0.0.vsix`.

15. **[Milestone 15: Multi-Prover SMT Solver Backend (Z3, CVC5, Vampire, Auto)](docs/superpowers/REPLAY_PLAYBOOK.md)**  
    *Scope:* Enhances `Solver.hs`, CLI (`--prover` / `-p`), and REPL (`:prover <name>`) with pluggable theorem prover backends supporting **Z3**, **CVC5**, **Vampire**, and automated multi-solver discovery with fallback. Validated against live Z3 and CVC5 binaries with 211 passing tests.

16. **[Future Capabilities & Target Emitters Master Plan](docs/superpowers/plans/2026-09-14-future-capabilities-and-target-emitters.md)**  
    *Scope:* Detailed specifications and test plans for SPARQL 1.1 graph query emitter, Protocol Buffers v3 / gRPC contract emitter, SQL DDL relational schema generator with CHECK constraints, and WebAssembly (WASM) interactive browser studio.

17. **[Initial Recommendations Implementation Plan](docs/superpowers/plans/2026-07-18-implement-ontologic-recommendations.md)**  
    *Scope:* Baseline implementation of early emitters and architectural recommendations.

18. **[Critical Architectural Audit & Suggested Improvements](docs/SUGGESTED_IMPROVEMENTS.md)**  
    *Scope:* Deep-dive evaluation of the original codebase, analyzing intent versus implementation reality across grammar, AST, linter, emitters, and ecosystem integration.

---

## 🧠 Key Learnings & Architectural Gotchas

During the modernization and testing of OntoLogic, critical subtleties and bugs were identified and solved across Haskell, Python, Cypher, OWL XML, Java, and Gradle. When replaying or extending the codebase, follow these established invariants:

### 1. OWL XML Emitter: Well-Formedness & Root Tag Termination
- **Gotcha:** In `src/Emitters/Owl.hs`, early versions omitted the closing `</rdf:RDF>` root tag and standard XML namespaces. This produced invalid XML that failed downstream RDF/OWL tooling (Protégé, Apache Jena).
- **Solution:** Always wrap OWL XML output in `<rdf:RDF ...> ... </rdf:RDF>` with standard namespaces (`xmlns:rdf`, `xmlns:rdfs`, `xmlns:owl`, `xmlns:xsd`). Ensure `test/OwlSpec.hs` asserts closing tags and namespace declarations.

### 2. Python Class Ordering: Topological Sorting via `Data.Graph`
- **Gotcha:** Python classes in a single module are evaluated imperatively at import time. If subclass `Child(Parent)` appears before `class Parent(BaseModel):`, Python immediately throws a runtime `NameError: name 'Parent' is not defined`.
- **Solution:** In `src/Emitters/Python.hs`, use `Data.Graph.graphFromEdges` and `Data.Graph.topSort` to sort concepts topologically (parents/ancestors before children) prior to emitting class definitions. If cycles exist, gracefully fall back to the raw concept sequence (the linter catches cycles independently).

### 3. Neo4j Cypher: TBox vs. ABox Metamodel Decoupling
- **Gotcha:** In early versions of `src/Emitters/Neo4j.hs`, concept taxonomy nodes were emitted with the concept name as the node label: `MERGE (n:Asset {name: 'Asset'})`. When schema constraints and audit queries were run against `:Asset`, this metamodel node collided with actual data instances of `Asset`, triggering false positive constraint violations.
- **Solution:** Decouple ontology classes from domain instances:
  - All taxonomy concepts are tagged with the uniform `:OntologyClass` label: `MERGE (n:OntologyClass {name: 'Asset'})`.
  - Inheritance is expressed as relationships between `:OntologyClass` nodes: `(n)-[:SUBCLASS_OF]->(p)`.

### 4. Cypher Path Merge Node Duplication Bug
- **Gotcha:** In Neo4j Cypher, running:
  ```cypher
  MERGE (n:OntologyClass {name: 'Child'})-[:SUBCLASS_OF]->(p:OntologyClass {name: 'Parent'})
  ```
  will create duplicate `Parent` nodes if the relationship does not yet exist! Cypher's `MERGE` on a path treats the entire path as a unit.
- **Solution:** Explicitly `MERGE` the parent node prior to merging the relationship:
  ```cypher
  MERGE (n:OntologyClass {name: 'Child'})
  MERGE (p:OntologyClass {name: 'Parent'})
  MERGE (n)-[:SUBCLASS_OF]->(p)
  ```

### 5. Modern Cypher Compatibility
- **Gotcha:** `id(n)` is deprecated in Neo4j 5.x and causes warnings or deprecation errors in modern Neo4j Aura/Enterprise.
- **Solution:** Use `elementId(n)` for node identity in audit queries.

### 6. Megaparsec Numeric Literals: Signed Numbers & GHC Ambiguity
- **Gotcha:**
  - Megaparsec's `L.decimal` and `L.float` do NOT parse negative signs (e.g. `-42` or `-15.5`), causing parse failures on negative property constraints.
  - Adding `L.signed sc` without type signatures triggers ambiguous type warnings in GHC under `-Wall -Werror`.
- **Solution:** In `src/Parser.hs`:
  ```haskell
  L.signed sc (L.decimal :: Parser Integer)
  L.signed sc (L.float :: Parser Double)
  ```
  Explicit type annotations guarantee deterministic parsing and zero compiler warnings.

### 7. Float & Double Semantic Support Across Emitters
- **Gotcha:** Early Java and Python emitters only mapped `Integer` constraints, silently ignoring numeric bounds on `Float` and `Double` properties.
- **Solution:**
  - **Java (`src/Emitters/Java.hs`):** Emit Jakarta `@DecimalMin(value = "...")` and `@DecimalMax(value = "...")` for `Float` and `Double`.
  - **Python (`src/Emitters/Python.hs`):** Emit Pydantic `Field(gt=..., lt=...)` for float fields, mapping `Float` and `Double` DSL types to Python `float`.

### 8. Linter Symbol Table Validation & Broken Example Domain Models
- **Gotcha:** Real-world `.logic` files in `examples/` contained latent bugs:
  - `examples/domain_security_trust.logic` referenced undeclared `SoftwareComponent`.
  - `examples/mqtt_ecosystem_unified.logic` defined `(def-concept Container ...)` twice.
  Because the linter originally only checked circular inheritance, these broken files compiled without warnings.
- **Solution:**
  - Implement `checkSymbolIntegrity :: Registry -> [String]` in `src/Linter.hs` to catch:
    1. Undeclared parent concepts
    2. Undeclared domain concepts in properties
    3. Duplicate concept definitions
    4. Duplicate property definitions on the same concept
  - Fix domain files immediately in `examples/`.
  - Add an integration test (`test/ExamplesSpec.hs`) that parses and lints every `.logic` file in `examples/`.

### 9. Cross-Axiom Interval Contradiction Checking
- **Gotcha:** If Axiom 1 states `(gt temp 100)` and Axiom 2 states `(lt temp 50)` on the same concept, intra-axiom checkers miss the conflict because neither axiom is contradictory on its own.
- **Solution:** Implement `checkGlobalPropertyContradictions :: Registry -> [String]` in `src/Linter.hs` to aggregate bounds across all axioms on each concept and identify mutually exclusive intervals.

### 10. CLI Driver Ergonomics & Gradle Wrapper Hygiene
- **Gotcha:**
  - The CLI previously required an output directory flag (`-o`) even when running `-t lint`, forcing users to type `-o /dev/null` or `-o .`.
  - `gradlew` and wrapper jars were gitignored in early commits, breaking the Java subproject build on fresh clones.
  - Compiling generated Java models polluted `git status` with generated files under `models-java/src/generated/`.
- **Solution:**
  - Make `-o` optional for `-t lint` in `src/Main.hs`.
  - Commit Gradle wrapper 8.4 (`gradlew`, `gradlew.bat`, `gradle/wrapper/`).
  - Add `models-java/src/generated/` to `.gitignore`.

### 11. Process Execution vs. Shell Injection in CLI Rendering
- **Gotcha:** `System.Process.callCommand` executes arbitrary strings inside the system shell (`/bin/sh -c`). File paths and options containing metacharacters allow arbitrary command execution.
- **Solution:** Use `System.Process.callProcess`, which directly executes binaries with an argument vector, bypassing shell evaluation entirely.

### 12. Cypher String Literal & Node Name Sanitization
- **Gotcha:** Directly interpolating names and property string values with single quotes (e.g. `O'Connor` or `it's fast`) into Cypher queries produces malformed Cypher syntax or injection vectors.
- **Solution:** Implement `escapeCypherString` in `src/Emitters/Neo4j.hs` to escape single quotes (`\'`) and backslashes (`\\\\`).

### 13. Clean CLI Process Exits vs. Runtime Exceptions
- **Gotcha:** Haskell's `error "..."` throws an unhandled exception that dumps internal call stack traces to stderr on user validation failures.
- **Solution:** Use `mapM_ putStrLn errors >> exitFailure` to return status code 1 cleanly without ugly runtime stack traces.

### 14. Recursive Module Loading & Diamond Import Deduplication
- **Gotcha:** When ontologies import shared base modules (e.g. `uco_observables.logic` and `mitre_attack.logic` both importing `cco_core.logic`), a naive loader parses and registers concepts multiple times, causing false positive duplicate concept errors.
- **Solution:** `src/Loader.hs` maintains a `visited` set of canonical file paths with cycle detection. Standard library lookups resolve against `.` and `ontologic-lib/` automatically.

### 15. Target Language Identifier Sanitization (`sanitizeIdent`)
- **Gotcha:** Qualified ontology names with colons or hyphens (e.g. `ocsf:FileActivity`, `nist-ai:AISystem`, `attack:T1059`) produce invalid identifiers in Java class/type declarations and Python class names.
- **Solution:** Java and Python emitters use `sanitizeIdent`, converting colons, hyphens, and periods to underscores (e.g. `ocsf_FileActivity`, `nist_ai_AISystem`).

---

## 🛠️ Step-by-Step Replay Runbook

To replay and rebuild OntoLogic in a clean environment:

### Step 0: Prerequisites & Worktree Setup
```bash
# Clone repository
git clone https://github.com/bsommers/OntoLogic.git
cd OntoLogic

# Optional: Create an isolated worktree for feature work
git worktree add .worktrees/core-improvements -b feature/core-improvements
cd .worktrees/core-improvements

# Verify GHC and Stack toolchain
stack --version
# Verify Python
python3 --version
# Verify Java & Gradle
java -version
./gradlew --version
```

### Step 1: Run Baseline Verification
```bash
# Verify Haskell builds with zero warnings
stack clean
stack build --ghc-options="-Wall -Werror"

# Verify all unit and integration tests pass
stack test
```

### Step 2: Validate the Example Models
```bash
# Verify semantic linting across all example domain files
for f in examples/*.logic; do
  stack exec ontologic-exe -- -i "$f" -t lint
done

# Verify standard library models
for f in ontologic-lib/*.logic; do
  stack exec ontologic-exe -- -i "$f" -t lint
done
```

### Step 3: Run Multi-Platform Compilation & Runtime Smoke Tests
```bash
# 1. Test Python Pydantic output
mkdir -p /tmp/ontologic-py
stack exec ontologic-exe -- -i logic/fleet.logic -t python -o /tmp/ontologic-py/
python3 -c "import ast; ast.parse(open('/tmp/ontologic-py/models.py').read())"

# 2. Test Java compilation via Gradle
mkdir -p models-java/src/generated/java/com/ontologic/models
stack exec ontologic-exe -- -i logic/fleet.logic -t java -o models-java/src/generated/java/com/ontologic/models/
./gradlew clean build
./gradlew :app-java:run

# 3. Test Cypher & OWL generation
mkdir -p /tmp/ontologic-out
stack exec ontologic-exe -- -i logic/fleet.logic -t neo4j -o /tmp/ontologic-out/
stack exec ontologic-exe -- -i logic/fleet.logic -t owl -o /tmp/ontologic-out/
stack exec ontologic-exe -- -i logic/fleet.logic -t mermaid -o /tmp/ontologic-out/
stack exec ontologic-exe -- -i logic/fleet.logic -t d2 -o /tmp/ontologic-out/
```

---

## 📂 Architecture Map

```
OntoLogic/
├── app/
│   └── Main.hs                 # CLI entrypoint; optparse-applicative; target routing
├── app-lsp/
│   └── Main.hs                 # Dedicated ontologic-lsp binary entrypoint
├── editors/
│   └── vscode/                 # VS Code extension package (.vsix)
│       ├── syntaxes/           # TextMate grammar (ontologic.tmLanguage.json)
│       ├── snippets/           # DSL snippets (ontologic.json)
│       ├── src/extension.ts    # TypeScript LSP client & SMT command handlers
│       └── scripts/            # build_extension.sh VSIX packager
├── src/
│   ├── OntoLogic.hs            # AST types: Concept, Property, Term, Formula, Axiom, Registry, Relation
│   ├── Parser.hs               # Megaparsec S-expression frontend; relations, imports, signed numbers
│   ├── Loader.hs               # Multi-file dependency graph loader, diamond deduplication, cycle detection
│   ├── Linter.hs               # Static semantic analyzer: symbol integrity, cycle detection, interval contradictions
│   ├── IR.hs                   # ModelIR compilation layer with formal ADTs (CompOp, PropertyType, Value)
│   ├── REPL.hs                 # Interactive Ontology REPL loop and command evaluator
│   ├── Solver.hs               # Live Z3 SMT solver runner, subsumption checker, unsatisfiable concept finder
│   ├── LSP.hs                  # JSON-RPC Language Server Protocol engine (diagnostics, completion, hover, def)
│   └── Emitters/
│       ├── TypeScript.hs       # TypeScript interfaces & Zod validation schema emitter
│       ├── OpenApi.hs          # OpenAPI 3.1 YAML component schemas emitter
│       ├── GraphQL.hs          # GraphQL SDL types and root Query schema emitter
│       ├── SMT.hs              # SMT-LIB2 logic emitter for Z3 / CVC5 theorem provers
│       ├── Java.hs             # Jakarta Bean Validation + Java POJO emitter (with sanitizeIdent)
│       ├── Python.hs           # Pydantic v2 emitter with topological class sort (with sanitizeIdent)
│       ├── Rust.hs             # Rust struct emitter with built-in validation methods (with sanitizeIdent)
│       ├── Go.hs               # Go struct emitter with JSON tags & Validate() methods (with sanitizeIdent)
│       ├── Neo4j.hs            # Modern Cypher emitter (:OntologyClass, relations + elementId)
│       ├── Owl.hs              # W3C OWL XML emitter with namespace validation & owl:ObjectProperty
│       ├── JsonSchema.hs       # JSON Schema (Draft 2020-12) emitter with numeric constraints & refs
│       ├── Shacl.hs            # W3C SHACL Shapes emitter (Turtle format) for RDF graph validation
│       ├── Mermaid.hs          # Mermaid class diagram visualizer
│       └── D2.hs               # D2 declarative diagram visualizer
├── ontologic-lib/              # Standard Library (Milestones 7–11)
│   ├── bfo_2020.logic          # Top-Level: Basic Formal Ontology 2020 ISO/IEC 21838-2
│   ├── cco_core.logic          # Middle-Tier: Common Core Ontologies
│   ├── uco_observables.logic   # Middle-Tier: Unified Cybersecurity Ontology
│   ├── stix_cve.logic          # CTI: STIX 2.1, CVE, CWE, CVSS/EPSS
│   ├── mitre_attack.logic      # Adversarial: MITRE ATT&CK Enterprise Matrix (12 tactics)
│   ├── mitre_d3fend.logic      # Defensive: MITRE D3FEND Countermeasures & Artifacts
│   ├── mitre_atlas.logic       # AI Security: MITRE ATLAS AI Threat Matrix
│   ├── nist_ai_rmf.logic       # AI Governance: NIST AI RMF 1.0 (Govern, Map, Measure, Manage)
│   ├── iso_42001_eu_ai_act.logic # AI Compliance: ISO/IEC 42001 & EU AI Act Risk Tiers
│   ├── nist_csf.logic          # Cyber GRC: NIST CSF 2.0 (Govern, Identify, Protect, Detect, Respond, Recover)
│   ├── nist_sp800_53.logic     # Security Controls: NIST SP 800-53 Rev 5 & OSCAL Baselines
│   ├── ocsf_schema.logic       # Telemetry: OCSF v1.1.0 Security Telemetry Taxonomy
│   └── sigma_rules.logic       # Detection: SIGMA Detection Rules & SIEM Semantics
├── test/
│   ├── Spec.hs                 # Hspec test discoverer
│   ├── ParserSpec.hs           # Parser & Linter unit tests
│   ├── ImportSpec.hs           # Multi-file import, diamond deduplication & cycle tests
│   ├── IRSpec.hs               # ModelIR compilation & ADT tests
│   ├── PropertySpec.hs         # QuickCheck property-based fuzz tests
│   ├── RelationSpec.hs         # Binary relations & multi-target emitter tests
│   ├── StandardLibrarySpec.hs  # BFO 2020, CCO Core, and UCO Observables tests
│   ├── ThreatModelingSpec.hs   # STIX 2.1, MITRE ATT&CK, and D3FEND tests
│   ├── AIGovernanceSpec.hs     # MITRE ATLAS, NIST AI RMF, and ISO 42001 / EU AI Act tests
│   ├── ComplianceGRCSpec.hs    # NIST CSF 2.0 and NIST SP 800-53 Rev 5 tests
│   ├── TelemetryMonitoringSpec.hs # OCSF v1.1.0 and SIGMA detection rules tests
│   ├── TypeScriptSpec.hs       # TypeScript / Zod emitter tests
│   ├── OpenApiSpec.hs          # OpenAPI 3.1 YAML emitter tests
│   ├── GraphQLSpec.hs          # GraphQL SDL schema emitter tests
│   ├── SMTSpec.hs              # SMT-LIB2 logic & constraint emitter tests
│   ├── SolverSpec.hs           # Live Z3 SMT solver & subsumption reasoning tests
│   ├── LSPSpec.hs              # Language Server Protocol JSON-RPC tests
│   ├── REPLSpec.hs             # Interactive REPL command and evaluation tests
│   ├── JavaSpec.hs             # Java emitter tests + javac compilation smoke test
│   ├── PythonSpec.hs           # Python emitter tests + ast.parse syntax + Pydantic validation
│   ├── RustSpec.hs             # Rust emitter tests + rustc compilation smoke test
│   ├── GoSpec.hs               # Go emitter tests + go vet validation smoke test
│   ├── JsonSchemaSpec.hs       # JSON Schema structure & Python json.loads syntax tests
│   ├── ShaclSpec.hs            # W3C SHACL node/property shapes & datatype tests
│   ├── Neo4jSpec.hs            # Cypher syntax & metamodel tests
│   ├── OwlSpec.hs              # OWL XML structure tests
│   ├── MermaidSpec.hs          # Mermaid diagram tests
│   ├── D2Spec.hs               # D2 diagram tests
│   ├── ExamplesSpec.hs         # Integration tests running all 12 example models against all targets
│   └── MainSpec.hs             # CLI argument & driver tests
├── examples/                   # Real-world domain models (.logic)
├── models-java/                # Java Gradle subproject with Bean Validation & JUnit tests
├── docs/
│   ├── SUGGESTED_IMPROVEMENTS.md
│   └── superpowers/
│       ├── REPLAY_PLAYBOOK.md  # (This file) Central playbook & learnings
│       └── plans/              # Master plan documents
└── gradlew                     # Pinned Gradle 8.4 wrapper
```
