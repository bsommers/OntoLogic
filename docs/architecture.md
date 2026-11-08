# OntoLogic: Compiler Architecture

This document describes the compiler internals, abstract syntax tree (AST), validation linter, and compilation emitter structure of OntoLogic.

---

## ⚙️ The Compilation Pipeline

OntoLogic follows a classic compiler frontend-to-backend pipeline:

```
  ┌─────────────────┐      ┌───────────────┐      ┌─────────────┐      ┌──────────────┐
  │   .logic File   │ ───> │ Megaparsec    │ ───> │ Linter (DFS │ ───> │ Emitters     │
  │ (S-expressions) │      │ parser        │      │ / Contrad.) │      │ (Java, Py,   │
  └─────────────────┘      └───────────────┘      └─────────────┘      │ Neo4j, etc.) │
                                                                       └──────────────┘
```

### 1. Frontend Parser (Megaparsec)
The parser in [`src/Parser.hs`](src/Parser.hs) scans Lisp-style S-expressions from `.logic` files and processes three main blocks:
- **Taxonomy Concepts**: Declared via `(def-concept Name [Parent])`.
- **Property Schemas**: Declared via `(def-property Name Domain ConceptType)`.
- **Logical Axioms**: Declarative constraints represented in quantified First-Order Logic (FOL).

### 2. Intermediate Representation (IR)
The intermediate representation is defined in [`src/OntoLogic.hs`](src/OntoLogic.hs):
- `FOL`: Represents first-order logical terms, including variables, constants, quantifiers (`forall`, `exists`), implications (`implies`), double-implications (`iff`), conjunctions (`and`), disjunctions (`or`), and negations (`not`).
- `Property`: Tracks field mappings (name, domain class, and range type).
- `Registry`: Keeps a centralized "Single Source of Truth" repository of concepts, properties, and axioms.

### 3. Static Linter Validation
The linter in [`src/Linter.hs`](src/Linter.hs) verifies the registry:
- **Circular Inheritance Check**: Employs a Depth-First Search (DFS) on the taxonomy DAG. If any child concept inherits from itself through a parent chain (e.g. `A -> B -> A`), the compile fails.
- **Axiom Contradiction Checker**: Inspects axioms for immediate logical contradictions (such as `P and (Not P)`).

### 4. Code Generation Emitters
The backend backends reside in `src/Emitters/` and translate the parsed registry into platform-specific structures:
*   **Java Emitter**: Writes distinct `.java` files for each concept. Maps properties to private fields and binds range limits to Jakarta validation annotations (`@Min`, `@Max`, `@NotNull`).
*   **Python Emitter**: Writes a `models.py` file with Pydantic class structures and binds range constraints to Pydantic `Field` arguments (e.g., `Field(gt=...)`).
*   **Neo4j Emitter**: Emits a Cypher script (`graph.cypher`) containing schema indexes, `SUBCLASS_OF` subclass nodes, and validation queries to audit the data.
*   **OWL Emitter**: Generates standard RDF/XML ontological specifications mapping concepts to OWL classes and properties.
*   **Mermaid / D2 Emitters**: Generates visual diagrams representing the concept hierarchy and properties.
