# Milestone 4 Plan: Type System Refactoring & Compiler Intermediate Representation (IR)

> **Context:** Evolution from an ad-hoc pattern-matching emitter pipeline to a strongly typed compiler architecture with an Intermediate Representation (IR), premise-aware axiom extraction, and property-based verification.
> **Tracking Document:** [`docs/superpowers/REPLAY_PLAYBOOK.md`](docs/superpowers/REPLAY_PLAYBOOK.md)

---

## 🎯 Objectives

1. **Eliminate Primitive Obsession:** Replace magic strings (`"Integer"`, `"gt"`, `"true"`) with typed Haskell Algebraic Data Types (`PropertyType`, `CompOp`, `Value`, `BoundConstraint`).
2. **Implement Formal Model IR (`src/IR.hs`):** Centralize class inheritance resolution, topological sorting, constraint aggregation, and property inheritance into an intermediate data model.
3. **Decouple Code Emitters:** Convert `Java.hs`, `Python.hs`, `Neo4j.hs`, `Owl.hs`, `Mermaid.hs`, and `D2.hs` into pure rendering views over the `ModelIR`.
4. **Premise-Aware Axiom Processing:** Prevent stripping conditional premises (e.g., `is_active`) into unconditional field constraints; emit compile-time warnings on unmapped axioms.
5. **Property-Based Testing:** Introduce `QuickCheck` generators to fuzz test parser roundtripping, linter consistency, and emitter syntax guarantees.

---

## 🧱 Architectural Specification

### 1. Core ADTs in [`src/OntoLogic.hs`](src/OntoLogic.hs)

```haskell
-- Target-agnostic property types
data PropertyType
    = PTInteger
    | PTFloat
    | PTDouble
    | PTBoolean
    | PTString
    | PTCustom Name
    deriving (Show, Eq, Ord, Generic)

-- Comparison operators
data CompOp
    = OpEq
    | OpNe
    | OpGt
    | OpGte
    | OpLt
    | OpLte
    deriving (Show, Eq, Ord, Generic)

-- Strongly-typed scalar values
data Value
    = VInt Integer
    | VDouble Double
    | VString String
    | VBool Bool
    deriving (Show, Eq, Ord, Generic)

-- Bound constraint on a property
data BoundConstraint = BoundConstraint
    { constraintOp    :: CompOp
    , constraintValue :: Value
    } deriving (Show, Eq, Ord, Generic)
```

---

### 2. Intermediate Representation in [`src/IR.hs`](src/IR.hs)

```haskell
module IR where

import OntoLogic

data CompiledProperty = CompiledProperty
    { compPropName     :: Name
    , compPropType     :: PropertyType
    , compConstraints  :: [BoundConstraint]
    , compIsInherited  :: Bool
    , compOriginClass  :: Name
    } deriving (Show, Eq, Generic)

data CompiledClass = CompiledClass
    { compClassName    :: Name
    , compParentClass  :: Maybe Name
    , compProperties   :: [CompiledProperty]
    } deriving (Show, Eq, Generic)

data ModelIR = ModelIR
    { irClasses          :: [CompiledClass]       -- Topologically sorted
    , irUnmappedAxioms   :: [FOL]                 -- Relational/conditional axioms
    } deriving (Show, Eq, Generic)

compileRegistry :: Registry -> ModelIR
```

---

## 📋 Step-by-Step Execution Tasks

### Task 1: Type System ADT Foundations
- [ ] Add `PropertyType`, `CompOp`, `Value`, and `BoundConstraint` to [`src/OntoLogic.hs`](src/OntoLogic.hs).
- [ ] Derive `Generic`, `Hashable`, `Eq`, `Ord`, and `Show` instances.
- [ ] Update `Property` definition in `OntoLogic.hs` to use `rangeType :: PropertyType`.

### Task 2: Megaparsec Parser Type Alignment
- [ ] Update `parseDefProperty` in [`src/Parser.hs`](src/Parser.hs) to parse `PropertyType`.
- [ ] Update `parsePredicate` to recognize `CompOp` operators.
- [ ] Parse typed literals directly into `Term (ConstantVal Value)`.

### Task 3: Intermediate Representation (`src/IR.hs`)
- [ ] Create [`src/IR.hs`](src/IR.hs) implementing `compileRegistry`.
- [ ] Centralize topological class sorting using `Data.Graph`.
- [ ] Resolve direct vs. inherited property sets and merge bound constraints.
- [ ] Detect state-conditional axioms (e.g. `(implies (and (Concept c) (Cond c)) ...)`) and preserve them in `irUnmappedAxioms`.

### Task 4: Unified Linter Refactoring
- [ ] Refactor [`src/Linter.hs`](src/Linter.hs) to use typed `CompOp` and `Value`.
- [ ] Unify single-axiom and cross-axiom contradiction detection via `evalPairContradiction`.
- [ ] Add linter check for unsupported property types and invalid operator-value pairs.

### Task 5: Refactor Code Emitters to Consume `ModelIR`
- [ ] **Java:** Refactor [`src/Emitters/Java.hs`](src/Emitters/Java.hs) to render `CompiledClass` instances with Jakarta `@NotNull`, `@Min`, `@Max`, `@DecimalMin`, `@DecimalMax`.
- [ ] **Python:** Refactor [`src/Emitters/Python.hs`](src/Emitters/Python.hs) to render `CompiledClass` instances with Pydantic `Field`.
- [ ] **Neo4j:** Refactor [`src/Emitters/Neo4j.hs`](src/Emitters/Neo4j.hs) to use `ModelIR`.
- [ ] **OWL:** Refactor [`src/Emitters/Owl.hs`](src/Emitters/Owl.hs) to use `ModelIR`.
- [ ] **Mermaid & D2:** Refactor [`src/Emitters/Mermaid.hs`](src/Emitters/Mermaid.hs) and [`src/Emitters/D2.hs`](src/Emitters/D2.hs).

### Task 6: CLI Warning Reporting
- [ ] In [`src/Main.hs`](src/Main.hs), report compile-time warnings for `irUnmappedAxioms` when targeting OOP models (Java/Python).

### Task 7: Property-Based & Regression Testing
- [ ] Add `test/IRSpec.hs` verifying compilation of complex hierarchies and inherited constraints.
- [ ] Add `test/PropertySpec.hs` using `QuickCheck` to test arbitrary valid ontology AST roundtrips.
- [ ] Ensure all 54 existing unit and integration tests continue to pass.

---

## 🔒 Quality & Verification Gates

1. `stack build --ghc-options="-Wall -Werror"` passes with 0 warnings.
2. `stack test` passes 100% of specs (including new IR & QuickCheck suites).
3. `./gradlew clean test` passes for generated Java models.
4. Python integration script verifies runtime Pydantic validations.
