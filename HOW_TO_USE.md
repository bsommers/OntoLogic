# OntoLogic: User Guide & Manual

OntoLogic is a formal First-Order Logic (FOL) domain-specific language (DSL), multi-target transpiler, theorem prover bridge, and interactive REPL.

---

## 📦 Installation & Setup

### 1. Building from Source (Haskell Stack)
```bash
# Clone the repository
git clone https://github.com/bsommers/OntoLogic.git
cd OntoLogic

# Build the project
stack build --ghc-options="-Wall -Werror"

# Run the test suite
stack test
```

### 2. Standalone Release Archive
```bash
# Package standalone bundle
./scripts/package_release.sh

# Extract and install binary to PATH
tar -xzf dist/ontologic-v1.0.0-linux-x86_64.tar.gz
sudo cp dist/ontologic-v1.0.0-linux-x86_64/bin/ontologic /usr/local/bin/
```

### 3. Docker Environment
```bash
# Spin up local Neo4j database & sandbox
docker-compose up -d
```

---

## 💻 CLI Commands & Targets

### Command Syntax
```bash
ontologic -i <input.logic> -t <target> -o <output_directory> [options]
```

### Supported Targets (`-t`)

| Target | Description | Output File | Sample Command |
| :--- | :--- | :--- | :--- |
| `lint` | Static semantic verification | Console output | `ontologic -i model.logic -t lint` |
| `solve` | Z3 SMT consistency & satisfiability check | Console output | `ontologic -i model.logic -t solve` |
| `lsp` | Language Server Protocol (LSP) stdio server | Stdio stream | `ontologic-lsp` / `ontologic --lsp` |
| `repl` | Interactive Ontology REPL | Interactive shell | `ontologic --repl` |
| `ts` / `typescript` / `zod` | TypeScript interfaces & Zod runtime validation | `models.ts` | `ontologic -i model.logic -t ts -o ./ts` |
| `openapi` | OpenAPI 3.1 YAML component schemas | `openapi.yaml` | `ontologic -i model.logic -t openapi -o ./api` |
| `graphql` / `gql` | GraphQL SDL types & Query schema | `schema.graphql` | `ontologic -i model.logic -t graphql -o ./gql` |
| `smt` / `smtlib` | SMT-LIB2 logic for Z3 / CVC5 theorem provers | `spec.smt2` | `ontologic -i model.logic -t smt -o ./smt` |
| `python` | Python Pydantic v2 data models | `models.py` | `ontologic -i model.logic -t python -o ./py` |
| `java` | Jakarta Bean Validation POJOs | `<Class>.java` | `ontologic -i model.logic -t java -o ./java --java-package com.domain` |
| `rust` | Rust structs with validation methods | `models.rs` | `ontologic -i model.logic -t rust -o ./rs` |
| `go` / `golang` | Go structs with JSON tags & validation | `models.go` | `ontologic -i model.logic -t go -o ./go` |
| `jsonschema` / `json`| JSON Schema (Draft 2020-12) | `schema.json` | `ontologic -i model.logic -t jsonschema -o ./schema` |
| `shacl` | W3C SHACL Shapes (Turtle format) | `shapes.ttl` | `ontologic -i model.logic -t shacl -o ./rdf --base-iri https://acme.test/onto` |
| `neo4j` | Cypher taxonomy schema & audit queries | `graph.cypher`, `constraints.cypher` | `ontologic -i model.logic -t neo4j -o ./cypher` |
| `owl` | W3C OWL/RDF XML ontology | `ontology.owl` | `ontologic -i model.logic -t owl -o ./owl --base-iri https://acme.test/onto` |
| `mermaid` | Mermaid class diagram (`--render` for SVG) | `class_diagram.mmd` | `ontologic -i model.logic -t mermaid -o ./diag --render` |
| `d2` | D2 declarative architecture diagram (`--render` for SVG) | `diagram.d2` | `ontologic -i model.logic -t d2 -o ./diag --render` |

> **Note on Neo4j Cypher Target (`neo4j`)**:
> OntoLogic emits two files for Neo4j:
> - `graph.cypher`: Node taxonomies, relationships, and axiom validation queries. Fully compatible with Neo4j Community Edition.
> - `constraints.cypher`: Property existence constraints (`IS NOT NULL`). These require Neo4j Enterprise Edition and are separated so `graph.cypher` can always load cleanly on Community instances (#48).

---

## ⚡ Interactive Ontology REPL

Launch the REPL by passing `--repl` or `-t repl`:
```bash
stack exec ontologic-exe -- --repl
```

### REPL Commands

| Command | Action |
| :--- | :--- |
| `:load <file.logic>` | Ingest an ontology file, resolving all imports and namespaces |
| `:show` | Print active concepts, properties, relations, axioms, and active prover |
| `:lint` | Run the static semantic linter against the in-memory registry |
| `:prover [name]` | Show or switch the active SMT prover (`z3`, `cvc5`, `vampire`, `auto`) |
| `:solve` / `:check` | Run SMT consistency & satisfiability check |
| `:prove <A> <B>` | Prove subsumption theorem ($A \sqsubseteq B$) |
| `:unsat` | Identify unsatisfiable/contradictory concepts |
| `:ir` | Display the compiled `ModelIR` AST structure |
| `:emit <target>` | Emit code in any of the 14 supported target formats |
| `:clear` | Reset active in-memory session |
| `:help` / `:?` | Display command help |
| `:quit` / `:q` / `exit` | Exit the REPL |
| `(def-concept ...)` | Interactively evaluate and add DSL statements |

### Example REPL Session
```text
ontologic> (def-concept Device)
Added to registry.

ontologic> (def-concept SmartSensor Device)
Added to registry.

ontologic> (def-property batteryLevel SmartSensor Integer)
Added to registry.

ontologic> (forall (s) (implies (SmartSensor s) (and (gte batteryLevel 0) (lte batteryLevel 100))))
Added to registry.

ontologic> :lint
✅ Semantic Linting Passed (0 errors).

ontologic> :emit ts
import { z } from "zod";

export const DeviceSchema = z.object({
});
export type Device = z.infer<typeof DeviceSchema>;

export const SmartSensorSchema = DeviceSchema.extend({
  batteryLevel: z.number().int().gte(0).lte(100),
});
export type SmartSensor = z.infer<typeof SmartSensorSchema>;

ontologic> :emit smt
; SMT-LIB2 Logic Specification generated by OntoLogic
(set-logic ALL)
(set-option :produce-models true)

; Sort declarations
(declare-sort Entity 0)

; Entity Concept Constants
(declare-const Device Entity)
(declare-const SmartSensor Entity)

; Subclass Hierarchy
(declare-fun subClassOf (Entity Entity) Bool)
(assert (subClassOf SmartSensor Device))

; Property Functions and Bound Assertions
(declare-fun SmartSensor_batteryLevel (Entity) Int)
(assert (>= (SmartSensor_batteryLevel SmartSensor) 0))
(assert (<= (SmartSensor_batteryLevel SmartSensor) 100))

; Satisfiability Check
(check-sat)
(get-model)
```

---

## 📝 First-Order Logic (FOL) DSL Syntax

### 1. Concepts & Inheritance
```lisp
(def-concept Entity)
(def-concept Asset Entity)
(def-concept Server Asset)
```

### 2. Typed Properties
Supported types: `Integer`, `Float`, `Double`, `String`, `Boolean`, or custom concept names.
```lisp
(def-property hostname Server String)
(def-property cpuCores Server Integer)
(def-property cpuUtilization Server Float)
(def-property isActive Server Boolean)
```

### 3. Binary Relations
```lisp
(def-relation hosts Server Asset)
(def-relation connectsTo Server Server)
```

### 4. Axioms & Quantifiers
```lisp
; Bound assertions on properties
(forall (s)
  (implies (Server s)
    (and (gte cpuCores 1)
         (lte cpuCores 128))))

(forall (s)
  (implies (Server s)
    (and (gte cpuUtilization 0.0)
         (lte cpuUtilization 100.0))))
```

### 5. Multi-File Imports & Namespaces
```lisp
(namespace "bfo" "http://purl.obolibrary.org/obo/bfo.owl#")
(namespace "cco" "http://www.ontologyrepository.com/CommonCoreOntologies/")

(import "ontologic-lib/bfo_2020.logic")
(import "ontologic-lib/cco_core.logic")
```

Standard-library imports are resolved without a path (`(import "bfo_2020.logic")`) by searching, in order:
`$ONTOLOGIC_PATH` (a `:`-separated list), the directory next to the installed binary, the package data
directory, `./ontologic-lib`, and finally the current directory. Add your own directories with a repeatable
`--lib-path DIR`. Because the current directory is searched **last**, a stray file there cannot shadow a
standard-library module.

### Naming the generated output

Neither the RDF base IRI nor the Java package is hardcoded.

`--base-iri IRI` sets the base for the `owl` and `shacl` targets. With no flag the base is the
ontology's **first declared namespace URI** (a trailing `#` or `/` is stripped), and if the ontology
declares none it falls back to `http://example.org/ontologic`.

`--java-package PKG` sets the package for the `java` target; the default is `ontologic.generated`.

In the REPL both are set with `:set`:

```
:set base-iri https://acme.test/onto
:set java-package com.acme.models
```

### 6. Repository Ontology Directories

This repository carries two ontology directories with different owners, both intentional:

- [`ontology/`](./ontology/README.md) — the component ontology generated by the ecosystem spider.
- [`.ontology/`](./.ontology/README.md) — BFO bindings seeded by the ecosystem pipeline.
- [`ontologic-lib/data/`](./ontologic-lib/data/README.md) — generated instance data in Turtle, for
  facts the DSL cannot express (it has no form for declaring an individual).

The tier-3 library they build on, `ontologic-lib/factory_domain.logic`, is vendored from
`factory-domain`, which owns the source.

---

## 🛡️ Static Semantic Linter

OntoLogic includes a compile-time static analyzer (`-t lint`) that guarantees logical soundness:
1. **Circular Inheritance Detection:** Prevents cycles in the concept taxonomy via DFS graph analysis.
2. **Symbol Table Integrity:** Ensures all parent concepts, property domains, and relation endpoints are declared.
3. **Duplicate Definitions:** Rejects duplicate concept or property definitions.
4. **Intra-Axiom Contradictions:** Flags direct contradictions ($P \land \neg P$).
5. **Cross-Axiom Interval Contradictions:** Flags disjoint numerical intervals across separate axioms (e.g. `(gt score 10)` and `(lt score 5)` on the same concept).

---

## 🔬 Multi-Prover SMT Theorem Proving & Subsumption Reasoning

OntoLogic integrates directly with automated SMT theorem provers (**Z3**, **CVC5**, **Vampire**, or auto-discovery) to perform live formal verification on your ontology models.

### 1. Consistency & Satisfiability Checking
```bash
# Check whole-ontology satisfiability with default auto-discovery
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t solve

# Specify SMT solver backend explicitly (z3, cvc5, vampire)
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic --solve --prover z3
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic --solve -p cvc5
```

`--solve` reports two things. **Consistency**: whether the axioms can be satisfied at all. **Coherence**:
which concepts can have no instance, given the axioms, bounds and hierarchy (the same check as the REPL's
`:unsat`). It exits non-zero if either fails, `2` if the solver could not decide. Axioms the SMT encoding
cannot express are listed first.

`--solve` exit codes: `0` = satisfiable (consistent), `1` = unsatisfiable or solver error, `2` = the solver answered `unknown`.

### 2. REPL Theorem Proving & Reasoning
In the interactive REPL (`ontologic --repl`):
- `:prover [name]`: View active prover or switch backend (`:prover cvc5`, `:prover z3`, `:prover auto`).
- `:solve` / `:check`: Verify whether the current in-memory ontology is satisfiable and display the satisfying model.
- `:prove <ConceptA> <ConceptB>`: Proves whether $\text{ConceptA} \sqsubseteq \text{ConceptB}$ is a mathematically necessary consequence of the hierarchy and axioms.
- `:unsat`: Identifies whether any concept has contradictory constraints that make it logically empty.

---

## 🛠️ Language Server Protocol (LSP) & VS Code Extension

OntoLogic provides both a Language Server Protocol engine (`ontologic-lsp` / `ontologic --lsp`) and a packaged VS Code extension (`.vsix`).

### Installing the VS Code Extension (.vsix)
```bash
# Package or use prebuilt .vsix
./editors/vscode/scripts/build_extension.sh

# Install extension into VS Code
code --install-extension dist/ontologic-1.0.0.vsix
```

The extension automatically manages `ontologic-lsp`, provides full TextMate syntax highlighting, code snippets, real-time diagnostics, hover types, jump-to-definition, and command palette actions (`OntoLogic: Check SMT Consistency & Satisfiability`, `OntoLogic: Check Concept Satisfiability`).

### Neovim Integration (`nvim-lspconfig`)
```lua
local lspconfig = require('lspconfig')
local configs = require('lspconfig.configs')

if not configs.ontologic_lsp then
  configs.ontologic_lsp = {
    default_config = {
      cmd = { 'ontologic-lsp' },
      filetypes = { 'logic', 'lisp' },
      root_dir = lspconfig.util.root_pattern('.git', 'package.yaml'),
      settings = {},
    },
  }
end

lspconfig.ontologic_lsp.setup{}
```

---

## 🏛️ Standard Library Reference (`ontologic-lib/`)

- `bfo_2020.logic`: Basic Formal Ontology (BFO ISO/IEC 21838-2).
- `cco_core.logic`: Common Core Ontologies (Agent, Information Entity, Artifact).
- `uco_observables.logic`: Unified Cybersecurity Ontology (Process, Socket, File, IP).
- `stix_cve.logic`: STIX 2.1, CVE, CWE, CVSS score bounds, EPSS probability.
- `mitre_attack.logic`: MITRE ATT&CK Enterprise Matrix (Tactics, Techniques, Sub-techniques).
- `mitre_d3fend.logic`: MITRE D3FEND Countermeasures & Defensive Artifacts.
- `mitre_atlas.logic`: MITRE ATLAS Adversarial Threat Matrix for AI.
- `nist_ai_rmf.logic`: NIST AI Risk Management Framework (Govern, Map, Measure, Manage).
- `iso_42001_eu_ai_act.logic`: ISO/IEC 42001 & EU AI Act Risk Categories.
- `nist_csf.logic`: NIST CSF 2.0 (Govern, Identify, Protect, Detect, Respond, Recover).
- `nist_sp800_53.logic`: NIST SP 800-53 Rev 5 & OSCAL Security Baselines.
- `ocsf_schema.logic`: OCSF v1.1.0 Security Telemetry Schema.
- `sigma_rules.logic`: SIGMA Detection Rules & SIEM Semantics.
