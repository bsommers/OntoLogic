# Milestone 5 Plan: Multi-Entity Relational Axioms & Graph Transpilation

> **Context:** Expands OntoLogic's compiler and intermediate representation to support cross-entity relationships (`(def-relation ...)` and multi-variable First-Order Logic predicates), transpiling them into Neo4j graph relationships, OWL Object Properties, OOP association references, and visualizer relationship arrows.
> **Tracking Document:** [`docs/dev/superpowers/REPLAY_PLAYBOOK.md`](../REPLAY_PLAYBOOK.md)

---

## 🎯 Objectives

1. **First-Class Relation Syntax:** Add `(def-relation <name> <domain-concept> <range-concept>)` to the Megaparsec frontend and AST.
2. **Multi-Variable FOL Support:** Support multi-variable quantifiers and binary relation predicates `(forall (s g) (implies (and (Sensor s) (connected_to s g)) (Gateway g)))`.
3. **Extend Model IR (`src/IR.hs`):** Add `CompiledRelation` to `ModelIR` capturing relationship endpoint semantics and associated cross-entity rules.
4. **Relational Semantic Linter:** Validate relation endpoints against known concept declarations, flag duplicate relations, and verify relationship domain/range consistency.
5. **Multi-Target Relational Transpilation:**
   * **Neo4j Cypher:** Emit graph pattern matches, existence constraints, and relationship taxonomy edges `(:OntologyClass)-[:RELATION_TYPE]->(:OntologyClass)`.
   * **OWL XML:** Emit W3C `owl:ObjectProperty` blocks with `rdfs:domain` and `rdfs:range`.
   * **Mermaid & D2:** Render directional relationship arrows between concept class boxes with relation labels.
   * **Java POJOs:** Emit typed association fields (e.g. `private Gateway gateway;` with getter/setter).
   * **Python Pydantic:** Emit typed relationship references (e.g. `gateway: Optional['Gateway'] = None`).

---

## 🧱 Architectural Specification

### 1. AST Extension in [`src/OntoLogic.hs`](../../../../src/OntoLogic.hs)

```haskell
-- First-class binary relation connecting two concepts
data Relation = Relation
    { relName   :: Name
    , relDomain :: Name
    , relRange  :: Name
    } deriving (Show, Eq, Generic)

instance Hashable Relation

data Registry = Registry
    { concepts   :: [(Name, Maybe Name)]
    , axioms     :: [FOL]
    , properties :: [Property]
    , relations  :: [Relation]
    } deriving (Show, Generic)
```

---

### 2. Intermediate Representation Extension in [`src/IR.hs`](../../../../src/IR.hs)

```haskell
data CompiledRelation = CompiledRelation
    { compRelName   :: Name
    , compRelDomain :: Name
    , compRelRange  :: Name
    , compRelAxioms :: [FOL]
    } deriving (Show, Eq, Generic)

data ModelIR = ModelIR
    { irClasses        :: [CompiledClass]
    , irRelations      :: [CompiledRelation]
    , irUnmappedAxioms :: [FOL]
    } deriving (Show, Eq, Generic)
```

---

### 3. Target Emitter Output Specifications

#### Neo4j Cypher (`src/Emitters/Neo4j.hs`)
```cypher
// Relationships
MERGE (s:OntologyClass {name: 'Sensor'})
MERGE (g:OntologyClass {name: 'Gateway'})
MERGE (s)-[:RELATION {name: 'connected_to'}]->(g)
```

#### W3C OWL XML (`src/Emitters/Owl.hs`)
```xml
<owl:ObjectProperty rdf:about="#connected_to">
    <rdfs:domain rdf:resource="#Sensor"/>
    <rdfs:range rdf:resource="#Gateway"/>
</owl:ObjectProperty>
```

#### Mermaid Diagram (`src/Emitters/Mermaid.hs`)
```mermaid
Sensor --> Gateway : connected_to
```

#### D2 Diagram (`src/Emitters/D2.hs`)
```d2
Sensor -> Gateway: connected_to
```

#### Java POJO (`src/Emitters/Java.hs`)
```java
public class Sensor {
    private Gateway connected_to;

    public Gateway getConnected_to() {
        return this.connected_to;
    }

    public void setConnected_to(Gateway val) {
        this.connected_to = val;
    }
}
```

#### Python Pydantic (`src/Emitters/Python.hs`)
```python
class Sensor(BaseModel):
    connected_to: Optional['Gateway'] = None
```

---

## 📋 Step-by-Step Execution Tasks

### Task 1: AST & Parser Extension
- [ ] Add `Relation` record to [`src/OntoLogic.hs`](../../../../src/OntoLogic.hs) and update `Registry` record with `relations :: [Relation]`.
- [ ] Implement `parseDefRelation :: Parser Item` in [`src/Parser.hs`](../../../../src/Parser.hs) matching `(def-relation <name> <domain> <range>)`.
- [ ] Support multi-variable quantifier parsing `(forall (s g) ...)` in `Parser.hs`.

### Task 2: Relational Semantic Linter
- [ ] Add `checkUndeclaredRelationEndpoints` in [`src/Linter.hs`](../../../../src/Linter.hs) ensuring both domain and range concepts are declared.
- [ ] Add `checkDuplicateRelations` in `Linter.hs`.

### Task 3: Intermediate Representation (`src/IR.hs`)
- [ ] Add `CompiledRelation` and `irRelations :: [CompiledRelation]` to `ModelIR`.
- [ ] Link relations to class properties for OOP targets (Java/Python) and graph targets (Neo4j/OWL/Mermaid/D2).

### Task 4: Emitter Transpilation
- [ ] **Neo4j:** Emit relationship schema edges between `:OntologyClass` nodes in [`src/Emitters/Neo4j.hs`](../../../../src/Emitters/Neo4j.hs).
- [ ] **OWL:** Emit `owl:ObjectProperty` in [`src/Emitters/Owl.hs`](../../../../src/Emitters/Owl.hs).
- [ ] **Mermaid & D2:** Emit directional association arrows in [`src/Emitters/Mermaid.hs`](../../../../src/Emitters/Mermaid.hs) and [`src/Emitters/D2.hs`](../../../../src/Emitters/D2.hs).
- [ ] **Java:** Emit typed reference getters/setters in [`src/Emitters/Java.hs`](../../../../src/Emitters/Java.hs).
- [ ] **Python:** Emit forward-referenced optional fields in [`src/Emitters/Python.hs`](../../../../src/Emitters/Python.hs).

### Task 5: Testing & Verification
- [ ] Add `test/RelationSpec.hs` testing parsing, linting, and multi-emitter code generation for relations.
- [ ] Update all existing test specs for the new `Registry` record shape.
- [ ] Verify `stack test` (100% green) and `./gradlew clean test`.

---

## 🔒 Quality & Verification Gates

1. `stack build --ghc-options="-Wall -Werror"` compiles cleanly with 0 warnings.
2. `stack test` passes all unit, integration, and property-based test suites.
3. Live compilation checks (`javac`, Python `ast.parse`, OWL XML parser) verify generated relation syntax across targets.
