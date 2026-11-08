# OntoLogic User Guide

[← Back to Project README](../../README.md)

OntoLogic is a formal First-Order Logic (FOL) domain-specific language compiler, semantic linter, multi-target emitter, and automated theorem-proving bridge implemented in Haskell. It compiles high-integrity ontological specifications into production software artifacts, API schemas, relational and graph database schemas, automated theorem prover problems, and visual architectural diagrams.

---

## Table of Contents

- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation & Build](#installation--build)
  - [Two-Minute First Run](#two-minute-first-run)
- [Core Concepts & DSL Syntax](#core-concepts--dsl-syntax)
  - [Concepts & Taxonomic Inheritance](#concepts--taxonomic-inheritance)
  - [Properties, Types & Cardinalities](#properties-types--cardinalities)
  - [Relations](#relations)
  - [First-Order Logic Axioms & Constraints](#first-order-logic-axioms--constraints)
  - [Modular Namespaces & Imports](#modular-namespaces--imports)
- [Examples & Common Workflows](#examples--common-workflows)
  - [1. Semantic Linting](#1-semantic-linting)
  - [2. Automated SMT Reasoning & Coherence Verification](#2-automated-smt-reasoning--coherence-verification)
  - [3. Multi-Target Code Generation](#3-multi-target-code-generation)
  - [4. Interactive REPL Exploration](#4-interactive-repl-exploration)
  - [5. Language Server Protocol (LSP) & Editor Setup](#5-language-server-protocol-lsp--editor-setup)
- [CLI Reference](#cli-reference)
  - [Command-Line Options & Flags](#command-line-options--flags)
  - [Compilation Targets](#compilation-targets)
  - [Theorem Prover Backends](#theorem-prover-backends)
  - [Exit Codes](#exit-codes)
  - [Environment Variables](#environment-variables)
- [Troubleshooting & FAQ](#troubleshooting--faq)
  - [Common Error Messages & Remedies](#common-error-messages--remedies)
  - [Prover Selection & Solver Fallback](#prover-selection--solver-fallback)
  - [Unmapped Axiom Warnings](#unmapped-axiom-warnings)

---

## Getting Started

### Prerequisites

- **Haskell Toolchain:** [Stack](https://docs.haskellstack.org/) (recommended) or GHC 9.4.8 + Cabal 3.8+.
- **External Automated Theorem Provers (Optional, recommended for automated reasoning):**
  - **Z3** (`z3 >= 4.8.0`): `sudo apt-get install z3` or `brew install z3`
  - **CVC5** (`cvc5 >= 1.0.0`): `sudo apt-get install cvc5` or `brew install cvc5`
  - **Vampire** (`vampire >= 4.7`): Download from [Vampire Prover releases](https://vprover.github.io/)
  - *Note:* If external solvers are not present in `PATH`, OntoLogic automatically falls back to its built-in native Semantic Tableaux and Resolution engines.
- **Visual Diagram Renderers (Optional):**
  - **Mermaid CLI** (`mmdc`): `npm install -g @mermaid-js/mermaid-cli`
  - **D2 CLI** (`d2`): `curl -fsSL https://d2lang.com/install.sh | sh -s --`

### Installation & Build

Clone the repository and compile with Stack:

```bash
git clone https://github.com/bsommers/OntoLogic.git
cd OntoLogic

# Build compiler, REPL, and LSP server
stack build

# Run full test suite with coverage verification
./scripts/check_coverage.sh
```

To install the executables (`ontologic-exe` and `ontologic-lsp`) to `~/.local/bin`:

```bash
stack install
```

### Two-Minute First Run

Create a sample specification named `device.logic`:

```lisp
;; device.logic - Sample Industrial Ontology
(namespace iot "http://example.org/iot#")

(def-concept Device)
(def-property serial_number Device String :cardinality 1..1)
(def-property firmware_version Device String :default "1.0.0")

(def-concept Sensor Device)
(def-property reading Sensor Float)
(def-property is_active Sensor Boolean :default True)

;; Axiom: If a sensor is active, its reading must be positive
(forall (s)
  (implies (Sensor s)
    (implies (eq is_active True) (gt reading 0.0))))
```

Validate and solve the ontology:

```bash
# 1. Semantic Linting
stack exec ontologic-exe -- -i device.logic -t lint

# 2. Automated SMT Satisfiability and Concept Coherence Check
stack exec ontologic-exe -- -i device.logic -t solve --prover auto

# 3. Transpile to TypeScript / Zod schemas
stack exec ontologic-exe -- -i device.logic -t ts -o dist/ts/

# 4. Transpile to Python Pydantic v2 models
stack exec ontologic-exe -- -i device.logic -t python -o dist/py/

# 5. Transpile to PostgreSQL DDL with check constraints
stack exec ontologic-exe -- -i device.logic -t sql -o dist/schema.sql
```

---

## Core Concepts & DSL Syntax

OntoLogic uses an S-expression syntax designed to balance human readability with strict mathematical semantics.

### Concepts & Taxonomic Inheritance

Concepts define ontological classes or entity types. Subtyping is declared by naming the parent concept:

```lisp
(def-concept Vehicle)
(def-concept Aircraft Vehicle)
(def-concept Drone Aircraft)
```

- In BFO-grounded models, concepts derive transitively from foundational entities (e.g. `bfo:Continuant`, `bfo:Occurrent`).
- Cyclic inheritance (e.g. `A` subclass of `B`, `B` subclass of `A`) is strictly rejected by the semantic linter.

### Properties, Types & Cardinalities

Properties define strongly typed datatype attributes associated with a domain concept:

```lisp
(def-property <name> <DomainConcept> <Type> [:cardinality <card>] [:default <val>] [:optional <bool>])
```

#### Supported Types:
- `Integer`: Signed 64-bit integer (`int64`, `int64_t`, `i64`).
- `Float`: 32-bit IEEE-754 floating point number.
- `Double`: 64-bit IEEE-754 floating point number.
- `String`: UTF-8 textual string.
- `Boolean`: Truth value (`True` / `False`).
- `<ConceptName>`: Custom object reference to another declared concept.

#### Supported Cardinalities:
- `1..1` or `1`: Mandatory scalar (default for datatype properties).
- `0..1` or `optional`: Optional scalar (`Option<T>`, `Optional<T>`, `*T`, `null`).
- `0..*` or `*`: Arbitrary collection / array / list (`Vec<T>`, `List<T>`, `[]T`).
- `1..*`: Non-empty collection requiring at least one element.

```lisp
(def-property port Server Integer :cardinality 1..1 :default "8080")
(def-property backup_ip Server String :optional True)
(def-property error_codes Server Integer :cardinality 0..*)
(def-property tags Server String :cardinality 1..*)
```

### Relations

Relations define directed associations (object properties) between a domain concept and a range concept:

```lisp
(def-relation connects_to Device Router :cardinality 0..*)
(def-relation manages Controller Robot)
```

In relational targets (`sql`), relations emit junction tables with foreign key cascades. In graph targets (`neo4j`), relations emit labeled edges (`-[:CONNECTS_TO]->`).

### First-Order Logic Axioms & Constraints

Axioms declare universal rules, bound constraints, or conditional invariants using standard FOL connectives:

- **Quantifiers:** `(forall (x) ...)`, `(exists (x) ...)`, `(forall ((x Concept)) ...)`, `(exists ((x Concept)) ...)`
- **Connectives:** `(implies P Q)`, `(iff P Q)`, `(and P Q ...)`, `(or P Q ...)`, `(not P)`
- **Comparison Operators:** `(eq prop val)`, `(ne prop val)`, `(gt prop val)`, `(gte prop val)`, `(lt prop val)`, `(lte prop val)`
- **Constants:** `top` (truth), `bottom` (contradiction).

#### Simple Bound Constraints:
```lisp
(forall (v)
  (implies (Vehicle v)
    (and (gte speed 0) (lte speed 120))))
```

#### Multi-Premise Conditional Constraints:
```lisp
(forall (o)
  (implies (and (Oven o) (eq is_active True))
    (gt temperature 100)))
```

### Modular Namespaces & Imports

Ontologies can be split across modular files and reusable namespaces:

```lisp
;; Declare namespace prefix and base IRI
(namespace sys "http://example.org/systems#")

;; Import shared foundations
(import "ontologic-lib/bfo_2020.logic")
(import "common/types.logic")
```

The import engine performs cycle detection, deduplicates diamond imports, and resolves files relative to the current file, `--lib-path`, or `$ONTOLOGIC_PATH`.

---

## Examples & Common Workflows

### 1. Semantic Linting

Run static checks to detect circular inheritance, undeclared types, or contradictory axioms prior to code generation:

```bash
stack exec ontologic-exe -- -i examples/bfo_manufacturing.logic -t lint
```

Output:
```text
✅ Logic Validated successfully.
```

If an error is present:
```text
examples/broken.logic:14:3: error: Circular inheritance detected: Vehicle -> Car -> Vehicle
```

### 2. Automated SMT Reasoning & Coherence Verification

Verify satisfiability and concept coherence using external solvers or the native prover:

```bash
# Check satisfiability using auto-discovered solver (Z3, CVC5, Vampire, or Native)
stack exec ontologic-exe -- -i ontologic-lib/stix_cve.logic -t solve --prover auto

# Explicitly use Z3 with a 5-second timeout
stack exec ontologic-exe -- -i ontologic-lib/stix_cve.logic -t solve -p z3 -T 5

# Explain an unsatisfiable core if a logical contradiction exists
stack exec ontologic-exe -- -i broken.logic -t solve --explain-unsat

# Inspect full model valuation for satisfiable specifications
stack exec ontologic-exe -- -i device.logic -t solve --inspect-model
```

### 3. Multi-Target Code Generation

Generate code for polyglot systems from a single source of truth:

```bash
# TypeScript / Zod validation schemas
stack exec ontologic-exe -- -i device.logic -t ts -o src/models/device.ts

# Python Pydantic v2 models
stack exec ontologic-exe -- -i device.logic -t python -o src/models/device.py

# Rust structs with validate() implementation
stack exec ontologic-exe -- -i device.logic -t rust -o src/models/device.rs

# Go structs with Validate() methods
stack exec ontologic-exe -- -i device.logic -t go -o models/device.go

# Java Jakarta Bean Validation models with package declaration
stack exec ontologic-exe -- -i device.logic -t java --java-package com.company.iot -o src/main/java/

# PostgreSQL / ANSI SQL schema with foreign keys and check constraints
stack exec ontologic-exe -- -i device.logic -t sql -o db/schema.sql

# Neo4j Cypher schema & index creation script
stack exec ontologic-exe -- -i device.logic -t neo4j --neo4j-edition enterprise -o db/schema.cypher

# W3C OWL/RDF XML and SHACL Turtle Shapes
stack exec ontologic-exe -- -i device.logic -t owl -o dist/device.owl
stack exec ontologic-exe -- -i device.logic -t shacl -o dist/device.shacl.ttl

# Visual Diagrams (Mermaid and D2)
stack exec ontologic-exe -- -i device.logic -t mermaid -o diagrams/device.mmd
stack exec ontologic-exe -- -i device.logic -t d2 -o diagrams/device.d2
```

### 4. Interactive REPL Exploration

Launch the interactive REPL to prototype, inspect, and query ontologies interactively:

```bash
stack exec ontologic-exe -- --repl
```

Session example:
```text
ontologic> (def-concept Asset)
Added to registry.

ontologic> (def-concept Robot Asset)
Added to registry.

ontologic> (def-property batteryLevel Robot Integer)
Added to registry.

ontologic> (forall (r) (implies (Robot r) (and (gte batteryLevel 0) (lte batteryLevel 100))))
Added to registry.

ontologic> :show
Active Registry State:
  Concepts:   2 -> ["Asset","Robot"]
  Properties: 1 -> ["batteryLevel"]
  Relations:  0 -> []
  Axioms:     1
  Prover:     Auto (Z3/CVC5/Vampire/Native)
  Loaded:     <none>

ontologic> :prove Robot Asset
✅ Theorem Proved via Auto (Z3/CVC5/Vampire/Native): 'Robot' ⊑ 'Asset' (Every instance of Robot is necessarily a Asset).

ontologic> :solve
✅ SMT Satisfiable (SAT) via Auto (Z3/CVC5/Vampire/Native) — Consistent Model Found:
sat
✅ All concepts are satisfiable (0 empty concepts).

ontologic> :emit ts
import { z } from "zod";

export const AssetSchema = z.object({
});
export type Asset = z.infer<typeof AssetSchema>;

export const RobotSchema = AssetSchema.extend({
  batteryLevel: z.number().int().gte(0).lte(100),
});
export type Robot = z.infer<typeof RobotSchema>;

ontologic> :quit
Goodbye!
```

### 5. Language Server Protocol (LSP) & Editor Setup

OntoLogic includes an LSP server providing real-time IDE diagnostics, hover tooltips, and jump-to-definition.

#### Start LSP Daemon:
```bash
stack exec ontologic-lsp
```

#### Install VS Code Extension:
The VS Code extension package is available under `dist/`:
```bash
code --install-extension dist/ontologic-1.0.0.vsix
```

Features provided in VS Code:
- Syntax highlighting for `.logic` files.
- Live squiggly diagnostics from the parser and semantic linter.
- Documentation hover tooltips for concepts, properties, relations, and quantifiers.
- Code action quickfixes to solve consistency (`ontologic.solve`) or explain UNSAT cores (`ontologic.explainUnsat`).

---

## CLI Reference

### Command-Line Options & Flags

| Option / Flag | Type | Description |
|---|---|---|
| `-h`, `--help` | Flag | Show CLI help text and option overview. |
| `-i`, `--input ARG` | FilePath | Path to input `.logic` ontology file. |
| `-t`, `--target ARG` | String | Target action or emitter format (see list below). |
| `-o`, `--output ARG` | Path | Output directory or file destination for emitted code. |
| `-p`, `--prover ARG` | String | Theorem prover backend: `z3`, `cvc5`, `vampire`, `native`, `auto` (default: `auto`). |
| `-T`, `--solve-timeout SECONDS` | Integer | Wall-clock execution timeout passed to theorem prover (in seconds). |
| `--solve-memory MB` | Integer | Virtual memory limit in megabytes (passed to Z3 `-memory:`). |
| `--repl` | Flag | Launch the interactive ontology REPL session. |
| `--solve` | Flag | Run SMT consistency, satisfiability, and coherence checks (shorthand for `-t solve`). |
| `--explain-unsat` | Flag | Extract minimal unsatisfiable core explaining logical contradictions. |
| `--inspect-model` | Flag | Print satisfying model valuation assignments for satisfiable ontologies. |
| `--cnf` | Flag | Emit ontology in Clausal Normal Form (CNF) to stdout. |
| `--lsp` | Flag | Start Language Server Protocol stdio daemon. |
| `--java-package ARG` | String | Target package for Java models (default: `ontologic.generated`). |
| `--base-iri IRI` | URI | Custom base IRI override for RDF/OWL/SHACL emissions. |
| `--neo4j-edition EDITION` | String | Neo4j constraint edition: `community` or `enterprise` (default: `enterprise`). |
| `--render` | Flag | Render Mermaid/D2 diagrams to SVG/PNG using installed CLI tools (`mmdc` / `d2`). |
| `--warn-unmapped` | Flag | Display warnings for axioms that cannot be mapped to field-level constraints. |
| `--lib-path DIR` | Directory | Additional search directory for imported modules (repeatable). |

### Compilation Targets

Specify using `-t <target>`:

| Target | Description | Output Structure |
|---|---|---|
| `lint` | Static semantic linter & cycle detector | Stdio diagnostic report |
| `solve` | SMT consistency & concept coherence check | Stdio SAT/UNSAT report |
| `ts` | TypeScript interfaces & Zod validation schemas | `.ts` file |
| `python` | Python Pydantic v2 `BaseModel` classes | `.py` file |
| `rust` | Rust structs with `validate()` methods | `.rs` file |
| `go` | Go structs with `Validate()` methods | `.go` file |
| `java` | Java POJOs with Jakarta validation annotations | `.java` files in directory |
| `sql` | PostgreSQL / ANSI SQL DDL with check constraints | `.sql` file |
| `openapi` | OpenAPI 3.1 YAML component schemas | `.yaml` file |
| `graphql` | GraphQL Schema Definition Language (SDL) | `.graphql` file |
| `neo4j` | Neo4j Cypher schema & constraint scripts | `.cypher` file |
| `owl` | W3C OWL 2 / RDF XML ontology | `.owl` / `.rdf` file |
| `shacl` | W3C SHACL shapes in Turtle syntax | `.ttl` file |
| `jsonschema` | JSON Schema (Draft 2020-12) definitions | `.json` file |
| `protobuf` | Protocol Buffers v3 message definitions | `.proto` file |
| `cpp` | Modern C++20 header structs with `validate()` | `.hpp` file |
| `smt` | Raw SMT-LIB2 theory for external provers | `.smt2` file |
| `tptp` | TPTP FOF format for automated theorem provers | `.p` file |
| `mermaid` | Mermaid class diagram | `.mmd` file |
| `d2` | D2 declarative architecture diagram | `.d2` file |

### Theorem Prover Backends

Configure using `-p <backend>` or `--prover <backend>`:

- `auto` (Default): Discovers installed provers in `PATH` in order: **Z3** $\to$ **CVC5** $\to$ **Vampire**. If none are installed, gracefully falls back to the native **Semantic Tableaux** and **Ordered Resolution** reasoning engines.
- `z3`: Invokes the Z3 SMT solver via stdin with `-in` and optional `-T:<seconds>` / `-memory:<mb>`.
- `cvc5`: Invokes CVC5 with `--lang=smt2 --incremental --finite-model-find`.
- `vampire`: Invokes Vampire in CASC / SMTCOMP mode.
- `native`: Uses OntoLogic's pure in-memory First-Order Semantic Tableaux and Resolution saturation engines without spawning any external processes.

### Exit Codes

| Exit Code | Meaning |
|---|---|
| `0` | Success / SMT Satisfiable (SAT) / Linting Passed |
| `1` | SMT Unsatisfiable (UNSAT) / Logical Contradiction / Lint Error / CLI Error |
| `2` | SMT Result Inconclusive / Solver Timeout / Resource Limit Exceeded |

### Environment Variables

- `ONTOLOGIC_PATH`: Colon-separated (`:`) list of directory paths searched for `(import "...")` files.

---

## Troubleshooting & FAQ

### Common Error Messages & Remedies

#### 1. `Circular inheritance detected: A -> B -> A`
- **Cause:** Concept `A` inherits from `B`, while `B` directly or transitively inherits from `A`.
- **Remedy:** Break the cycle by refactoring mutual dependencies into a common parent concept or modeling interactions as `def-relation`.

#### 2. `Undeclared concept / property / relation`
- **Cause:** A property or relation references a concept name that has not been defined in the current file or imported modules.
- **Remedy:** Ensure the referenced concept is defined using `(def-concept <Name>)` or imported via `(import "path.logic")`. Check for typos or namespace prefix mismatches.

#### 3. `❌ SMT Unsatisfiable (UNSAT) — Logical Contradiction Detected!`
- **Cause:** Asserted axioms form a logical contradiction (e.g. an entity must be simultaneously greater than 100 and less than 50, or concept disjointness is violated).
- **Remedy:** Run with `--explain-unsat` to identify the minimal unsatisfiable core of conflicting axioms:
  ```bash
  stack exec ontologic-exe -- -i model.logic -t solve --explain-unsat
  ```

#### 4. `Error: --output is required for target: <target>`
- **Cause:** Code generation targets (`ts`, `python`, `rust`, `go`, `java`, `sql`, etc.) write output to files and require `-o` / `--output`.
- **Remedy:** Provide the `-o` argument:
  ```bash
  stack exec ontologic-exe -- -i model.logic -t ts -o dist/models.ts
  ```

### Prover Selection & Solver Fallback

**Q: Do I need Z3 or CVC5 installed to run OntoLogic?**  
**A:** No. While Z3 and CVC5 offer high performance on massive industrial theories, OntoLogic bundles a fully native First-Order Semantic Tableaux engine and Robinson-resolution prover. Setting `-p native` or using `-p auto` when no solver is in `PATH` executes all proofs hermetically in memory.

### Unmapped Axiom Warnings

**Q: Why do I see `warning: [WUnmappedAxiom] ... could not be mapped to field constraints`?**  
**A:** Target programming languages (TypeScript, Python, Go, Rust) represent record types and field validators. Existential assertions (e.g. $\forall x.\, \exists y.\, R(x, y)$) or cross-concept relational assertions cannot be expressed as static record field bounds. OntoLogic emits a warning while preserving these axioms in full for formal targets (SMT, TPTP, OWL, SHACL). To suppress these warnings during build scripts, omit the `--warn-unmapped` flag.
