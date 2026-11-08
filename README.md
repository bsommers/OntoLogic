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

## Logic-as-Code Compiler, Ontology Transpiler & SMT Solver Engine

OntoLogic is a formal First-Order Logic (FOL) domain-specific language (DSL), multi-target compiler, theorem prover bridge, and interactive REPL implemented in Haskell. It compiles high-integrity formal ontological specifications into production software artifacts, API contracts, graph database schemas, knowledge graphs, SMT-LIB2 theorem prover specifications, and visual architecture diagrams.

> 💡 **Why OntoLogic?** Read the architectural and strategic manifesto: [**Why OntoLogic? Strategic & Architectural Rationale**](docs/WHY_ONTOLOGIC.md)
> *How Logic-as-Code and automated theorem proving eliminate distributed logic drift, the property graph sloppiness tax, and LLM hallucinations across polyglot enterprise stacks.*

---

## 🚀 Key Features

* **Formal FOL DSL & Rich Type System**: First-order logic predicates, quantifiers (`forall`, `exists`), implications (`implies`), boolean operators (`and`, `or`, `not`), typed property constraints (`Integer`, `Float`, `Double`, `String`, `Boolean`, custom object concepts), and binary relations (`def-relation`).
* **Modular Multi-File Namespaces**: Support for `(import "path/file.logic")` and `(namespace "prefix")` with cycle detection, diamond import deduplication, and automatic standard library lookup.
* **Semantic Static Linter**: Compile-time symbol table resolution, circular inheritance detection, duplicate definitions, intra-axiom propositional contradictions ($P \land \neg P$), and cross-axiom numeric interval contradiction analysis.
* **Multi-Prover SMT Solver & Theorem Prover**: Live automated consistency checking, taxonomic subsumption proofs ($A \sqsubseteq B$), empty/unsatisfiable concept detection, and counterexample generation with pluggable SMT/ATP backend support (**Z3**, **CVC5**, **Vampire**, or auto-discovery).
* **Language Server Protocol (LSP) Engine (`ontologic-lsp`)**: Built-in JSON-RPC stdio LSP server with real-time squiggly diagnostics, intelligent autocompletion, hover documentation tooltips, jump-to-definition, and rename refactoring.
* **VS Code Extension (`editors/vscode`)**: Packaged `.vsix` extension providing TextMate syntax highlighting, code snippets, LSP client, and SMT solver commands.
* **Intermediate Representation (IR)**: Decoupled compilation pipeline (`ModelIR`) separating frontend logic ASTs from backend target renderers.
* **Interactive Ontology REPL**: Dynamic command-line REPL (`ontologic --repl` or `-t repl`) supporting incremental DSL evaluation, `:load`, `:show`, `:lint`, `:prover <name>`, `:solve`, `:prove`, `:unsat`, `:ir`, `:emit <target>`, and `:clear`.
* **16 Multi-Target Code & Contract Emitters**:
  * **TypeScript / Zod**: TypeScript type definitions and composable Zod validation schemas (`z.infer`, `.extend()`, `.gte()`, `.lte()`).
  * **OpenAPI 3.1**: OpenAPI YAML component schemas with `allOf` inheritance composition and JSON Schema validation bounds.
  * **GraphQL SDL**: GraphQL types, scalar mappings, and query roots (`type Query`).
  * **PostgreSQL / ANSI SQL DDL**: Strongly typed relational tables, foreign key constraints, column-level `CHECK` constraints, and index generation.
  * **SMT-LIB2 / Z3**: Automated consistency verification and satisfiability checking (`check-sat`, `get-model`) for Z3 / CVC5 theorem provers.
  * **TPTP FOF / Vampire ATP**: First-Order Form problem generation for automated theorem provers (Vampire, E, Prover9).
  * **Java POJOs**: Jakarta Bean Validation (`@NotNull`, `@Min`, `@Max`, `@DecimalMin`, `@DecimalMax`), typed association fields, and customizable packages (`--java-package`).
  * **Python Pydantic v2**: Pydantic `BaseModel` classes, `Field(ge=..., le=...)` constraints, topological sort for clean runtime resolution, and typed association fields.
  * **Rust Structs**: Idiomatic Rust structs with derives (`Debug, Clone, PartialEq`), field composition, and `validate(&self) -> Result<(), Vec<String>>` methods.
  * **Go Structs**: Go structs with JSON tags, struct embedding for inheritance, and `Validate() []string` methods.
  * **Neo4j Cypher**: ABox/TBox decoupled schema creation (`:OntologyClass`), typed relationship edges (`-[:REL]->`), and modern audit queries (`elementId(n)`).
  * **W3C OWL/RDF XML**: Standards-compliant OWL ontologies (`owl:Class`, `owl:DatatypeProperty`, `owl:ObjectProperty`, `rdfs:subClassOf`, `rdfs:domain`, `rdfs:range`).
  * **JSON Schema**: Draft 2020-12 / Draft 7 schemas with `$defs`, `allOf` inheritance chains, and numerical bound constraints.
  * **W3C SHACL Shapes**: Shapes Constraint Language rules in Turtle syntax (`sh:NodeShape`, `sh:PropertyShape`, `sh:datatype`, `sh:class`, `sh:min/maxInclusive`).
  * **Mermaid & D2 Visualizers**: Class diagrams and relation arrows with optional headless CLI rendering (`--render`).


---

## 🏛️ Standard Library (`ontologic-lib/`)

OntoLogic includes a rigorous, multi-tier standard library covering foundational ontologies, cyber threat intelligence, AI governance, compliance-as-code, and security telemetry:

### 1. 3-Tier Foundation
* **Top-Level**: `bfo_2020.logic` — Basic Formal Ontology 2020 (ISO/IEC 21838-2).
* **Middle-Tier**: `cco_core.logic` — Common Core Ontologies (Agents, Artifacts, Information Entities).
* **Cyber Observables**: `uco_observables.logic` — Unified Cybersecurity Ontology (Processes, Network Traffic, Sockets, Files).

### 2. Cyber Threat Intelligence & Adversarial Defense
* **Vulnerability & Exploit**: `stix_cve.logic` — STIX 2.1, CVE, CWE, CVSS score bounds, EPSS probability.
* **Attack Matrix**: `mitre_attack.logic` — MITRE ATT&CK Enterprise Matrix (all 12 tactics & techniques).
* **Defensive Matrix**: `mitre_d3fend.logic` — MITRE D3FEND Countermeasures and defensive relations.

### 3. AI Safety, Risk Management & Governance
* **AI Threats**: `mitre_atlas.logic` — MITRE ATLAS Adversarial Threat Matrix for Artificial Intelligence.
* **Risk Management**: `nist_ai_rmf.logic` — NIST AI RMF 1.0 (Govern, Map, Measure, Manage functions).
* **Compliance**: `iso_42001_eu_ai_act.logic` — ISO/IEC 42001 & EU AI Act Risk Categories.

### 4. Cyber GRC & Automated Compliance
* **Cybersecurity Framework**: `nist_csf.logic` — NIST CSF 2.0 (Govern, Identify, Protect, Detect, Respond, Recover).
* **Control Baselines**: `nist_sp800_53.logic` — NIST SP 800-53 Rev 5 & OSCAL Security Baselines.

### 5. Security Telemetry & Detection
* **Telemetry Taxonomy**: `ocsf_schema.logic` — OCSF v1.1.0 Security Telemetry Schema.
* **SIEM Detection Rules**: `sigma_rules.logic` — SIGMA Detection Rules with OCSF and ATT&CK correlation.

---

## 💻 CLI Usage

```bash
# Start Interactive REPL session
stack exec ontologic-exe -- --repl

# Run SMT consistency and satisfiability verification (Z3, CVC5, or auto)
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t solve --prover z3
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic --solve -p cvc5

# Install VS Code Extension
code --install-extension dist/ontologic-1.0.0.vsix

# Start Language Server Protocol (LSP) stdio server
stack exec ontologic-lsp
# or
stack exec ontologic-exe -- --lsp

# Lint ontology model
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t lint

# Generate TypeScript / Zod validation schemas
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t ts -o ./generated/ts

# Generate OpenAPI 3.1 specification (YAML)
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t openapi -o ./generated/openapi

# Generate GraphQL SDL schema
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t graphql -o ./generated/graphql

# Generate SMT-LIB2 logic for Z3 / CVC5 theorem proving
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t smt -o ./generated/smt

# Generate Java models with Jakarta Bean Validation
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t java -o ./generated/java --java-package com.soc.telemetry

# Generate Python Pydantic v2 models
stack exec ontologic-exe -- -i ontologic-lib/sigma_rules.logic -t python -o ./generated/python

# Generate Rust models with built-in validation methods
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t rust -o ./generated/rust

# Generate Go models with validation methods
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t go -o ./generated/go

# Generate JSON Schema (Draft 2020-12)
stack exec ontologic-exe -- -i ontologic-lib/stix_cve.logic -t jsonschema -o ./generated/jsonschema

# Generate W3C SHACL Shapes (Turtle format)
stack exec ontologic-exe -- -i ontologic-lib/bfo_2020.logic -t shacl -o ./generated/shacl

# Generate Neo4j Cypher schema & audit scripts
stack exec ontologic-exe -- -i ontologic-lib/mitre_attack.logic -t neo4j -o ./generated/cypher

# Generate W3C OWL XML ontology
stack exec ontologic-exe -- -i ontologic-lib/bfo_2020.logic -t owl -o ./generated/owl

# Generate Mermaid / D2 architecture diagrams
stack exec ontologic-exe -- -i examples/smart_grid_relational.logic -t mermaid -o ./generated/diagrams
stack exec ontologic-exe -- -i examples/smart_grid_relational.logic -t d2 -o ./generated/diagrams --render
```

---

## ⚡ Interactive REPL & Proof-Checking Session

```text
$ stack exec ontologic-exe -- --repl
╔════════════════════════════════════════════════════════════╗
║              OntoLogic Interactive REPL v1.0               ║
║   Type ':help' for commands or enter DSL expressions       ║
╚════════════════════════════════════════════════════════════╝
ontologic> :load examples/smart_factory.logic
✅ Loaded examples/smart_factory.logic (4 concepts, 0 lint errors).

ontologic> :solve
✅ SMT Satisfiable (SAT) — Consistent Model Found:
sat
(
  (define-fun RoboticArm () Entity ...)
)

ontologic> :prove RoboticArm Asset
✅ Theorem Proved: 'RoboticArm' ⊑ 'Asset' (Every instance of RoboticArm is necessarily a Asset).

ontologic> :unsat
✅ All concepts are satisfiable (0 empty concepts).

ontologic> :emit ts
import { z } from "zod";

export const AssetSchema = z.object({
  id: z.string(),
});
export type Asset = z.infer<typeof AssetSchema>;

export const RoboticArmSchema = AssetSchema.extend({
  maxPayload: z.number().int().gte(1).lte(500),
});
export type RoboticArm = z.infer<typeof RoboticArmSchema>;

ontologic> :quit
Goodbye!
```

---

## 📖 Documentation & Architecture

* **[Why OntoLogic? Strategic & Technical Rationale](docs/WHY_ONTOLOGIC.md)** — Foundational manifesto on distributed logic drift, BFO realism, automated theorem proving, and AI hallucination guardrails.
* **[Documentation Index](docs/README.md)** — Master table of contents for compiler manuals, architecture docs, and design guides.
* **[Comprehensive User Guide](docs/user-guide/README.md)** — In-depth tutorial, syntax specifications, CLI flags, multi-target workflows, and troubleshooting.
* **[User Guide & CLI Reference](docs/using.md)** — Quick command-line manual, flags, syntax rules, and examples.
* **[Compiler Pipeline & Architecture](docs/architecture.md)** — Haskell AST, intermediate representations, linter checks, and emitter design.
* **[Standard Library Catalog](ontologic-lib/README.md)** — 3-Tier foundation (BFO/CCO/UCO), cyber threat intelligence (STIX/ATT&CK/D3FEND), AI safety (ATLAS/NIST AI RMF/EU AI Act), and GRC baselines (NIST CSF/800-53/OSCAL).

---

## 🛠️ Building & Testing

```bash
# Compile with all warnings as errors
stack build --ghc-options="-Wall -Werror"

# Run full Hspec test suite (685 examples)
stack test

# Package standalone distribution release
./scripts/package_release.sh
```

---

## 📄 License

Apache License 2.0. See [LICENSE](LICENSE) for details.
