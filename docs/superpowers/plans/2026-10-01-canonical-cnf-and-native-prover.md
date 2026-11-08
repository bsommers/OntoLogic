# Milestone v1.7.0 Plan: Canonical Clausal Normal Form (CNF) IR & Native First-Order Prover Engine

> **Context:** Evolution from relying exclusively on external automated theorem provers (Z3, CVC5, Vampire) over process stdio to providing a native, zero-dependency First-Order Logic (FOL) reasoning engine. Incorporates a formal Canonical Clausal Normal Form (CNF) intermediate representation and a built-in resolution/tableau prover directly in Haskell.
> **Tracking Document:** [`.planning/ROADMAP.md`](.planning/ROADMAP.md)

---

## 🎯 Executive Summary & Objectives

1. **Self-Contained Reasoning (Zero External Dependencies)**:
   Enable OntoLogic to prove taxonomic subsumptions ($A \sqsubseteq B$), detect concept unsatisfiability, and identify contradictory axioms on any machine without requiring `z3`, `cvc5`, or `vampire` installed in the host `$PATH`.
2. **Canonical Clausal Normal Form (CNF) IR (`src/IR/CNF.hs`)**:
   Implement a dedicated fourth IR level that lowers First-Order Logic formulas into a canonical set of skolemized clauses optimized for automated deduction.
3. **Deterministic 7-Stage Normalization Pipeline (`src/IR/Clausify.hs`)**:
   Desugaring $\to$ Negation Normal Form (NNF) $\to$ Variable Standardization $\to$ Prenex Normal Form (PNF) $\to$ Outer Skolemization $\to$ Universal Quantifier Stripping $\to$ Clausal Distribution & Trivial Clause Elimination.
4. **Dual-Strategy Native Prover Engine (`src/Prover/`)**:
   - **Saturation Engine (`src/Prover/Resolution.hs`)**: Ordered Resolution with Factoring, Superposition for equality, and the Given-Clause loop (Otter/DISCOUNT model) for refutation proofs.
   - **Countermodel Search (`src/Prover/Tableau.hs`)**: Analytic Free-Variable Semantic Tableaux for finite model finding and generating human-readable counterexamples when formulas are satisfiable.
5. **Architectural Integration**:
   Integrate the native engine into [`src/Solver.hs`](src/Solver.hs) as `--prover native` (default fallback when no external binaries exist), the REPL (`:cnf`, `:clausify`), and the LSP server (`ontologic-lsp`).

---

## 🔬 Architectural Trade-Off Analysis: Built-in vs. Standalone Tool

### Comparative Analysis

| Dimension | Option A: Built-in to OntoLogic Core (`src/Prover/`) | Option B: Separate Standalone CLI / Repo (`ontologic-prover`) | Option C: Hybrid Built-in Engine with Standalone Subcommand |
| :--- | :--- | :--- | :--- |
| **Portability & Zero-Setup** | **Optimal**: A single static binary (`ontologic-exe`) runs everywhere (CI containers, air-gapped systems, WebAssembly) with reasoning out-of-the-box. | **Poor**: Users must install, build, and configure multiple independent binaries in `$PATH`. | **Optimal**: Core binary bundles the engine; CLI exposes it directly via subcommands or flags. |
| **LSP Latency & Memory** | **Sub-millisecond**: Direct in-memory pointer traversal without serialization, process forking, or JSON/pipe overhead. | **High Latency**: Requires process spawning, pipe IPC, and serialization per keystroke diagnostic. | **Sub-millisecond**: Direct memory invocation in the LSP server. |
| **Code Reuse & Maintenance** | Single repository, synchronized AST evolution, zero IPC schema drift. | Multi-repo coordination, independent versioning, duplicate AST definitions. | Single repository; exposed as library stanzas in `package.yaml`. |
| **ATP Benchmarking** | Harder to run standalone against standard TPTP benchmark suites (e.g., CASC). | Straightforward integration with TPTP benchmark harnesses and tools like `vampire-tptp`. | Straightforward: provide an entrypoint or CLI flag (`ontologic --prove-tptp file.p`). |
| **Failure Isolation** | Solver crash or loop affects compiler process (mitigated by `System.Timeout.timeout`). | Process crash is isolated to the worker process. | Mitigated via Haskell thread timeouts and memory limits (`Control.Exception`). |

### Architectural Recommendation: **Option C (Hybrid Built-in Engine)**

1. **Implement as Built-in Modules**: Place the engine inside the main codebase (`src/IR/CNF.hs`, `src/Prover/Resolution.hs`, `src/Prover/Tableau.hs`, `src/Prover/Unification.hs`).
2. **Library Export**: Expose these modules in `package.yaml` so downstream tools can consume the prover as a pure Haskell library.
3. **CLI & Solver Seam**: Register the engine in `src/Solver.hs` as `NativeProver`. When `ontologic --solve` is run without `--prover`, it auto-detects external provers; if none are found, it seamlessly executes `NativeProver` instead of failing with an error.

---

## 🧱 Technical Specification: Canonical Clausal Normal Form (CNF)

### 1. Data Model (`src/IR/CNF.hs`)

```haskell
module IR.CNF
    ( VarId(..)
    , SkolemId(..)
    , Term(..)
    , Literal(..)
    , Clause(..)
    , CNFTheory(..)
    , litPredicate
    , litArgs
    , isComplementary
    ) where

import qualified Data.Set as Set
import OntoLogic (Name)

newtype VarId = VarId Int deriving (Show, Eq, Ord)
newtype SkolemId = SkolemId Int deriving (Show, Eq, Ord)

-- | First-Order Terms in CNF
data Term
    = TVar VarId
    | TConst Name
    | TFunc Name [Term]
    | TSkolem SkolemId [Term]   -- Skolem function applied to enclosing universal variables
    deriving (Show, Eq, Ord)

-- | First-Order Literal: positive or negated atomic predicate
data Literal
    = Pos Name [Term]
    | Neg Name [Term]
    | EqT Term Term            -- Built-in equality predicate t1 = t2
    | NeqT Term Term           -- Built-in inequality predicate t1 != t2
    deriving (Show, Eq, Ord)

-- | A Clause is a disjunction of literals: L1 \/ L2 \/ ... \/ Ln
newtype Clause = Clause { getLiterals :: Set.Set Literal }
    deriving (Show, Eq, Ord)

-- | A CNF Theory is a conjunction of clauses: C1 /\ C2 /\ ... /\ Cm
newtype CNFTheory = CNFTheory { getClauses :: Set.Set Clause }
    deriving (Show, Eq, Ord)
```

---

### 2. Normalization Pipeline (`src/IR/Clausify.hs`)

The normalization pass takes raw [`FOL`](src/OntoLogic.hs#L49-L64) formulas and transforms them into [`CNFTheory`](#1-data-model-srcircnfhs):

```
 Raw FOL Formula
       │
       ▼ [Stage 1: Desugaring]
 Eliminate Iff (P <-> Q  ==>  (P -> Q) /\ (Q -> P))
 Eliminate Implies (P -> Q  ==>  ~P \/ Q)
       │
       ▼ [Stage 2: Negation Normal Form (NNF)]
 Push negation inwards using De Morgan's laws:
   ~(P /\ Q)  ==>  ~P \/ ~Q
   ~(P \/ Q)  ==>  ~P /\ ~Q
 Quantifier duality:
   ~forall x. P(x)  ==>  exists x. ~P(x)
   ~exists x. P(x)  ==>  forall x. ~P(x)
 Eliminate double negation: ~~P  ==>  P
       │
       ▼ [Stage 3: Variable Standardization Apart]
 Rename all quantified variables to globally unique integers (VarId 1, VarId 2, ...)
       │
       ▼ [Stage 4: Outer Skolemization]
 Traverse tree tracking active universally quantified variables [u1, ..., uk]:
   exists y. P(y)  ==>  P(TSkolem freshId [u1, ..., uk])
       │
       ▼ [Stage 5: Universal Quantifier Dropping]
 Drop all remaining 'forall' quantifiers (all free variables are universally quantified)
       │
       ▼ [Stage 6: Clausal Distribution]
 Distribute disjunction over conjunction:
   P \/ (Q /\ R)  ==>  (P \/ Q) /\ (P \/ R)
       │
       ▼ [Stage 7: Clause Simplification & Tautology Elimination]
 Remove tautological clauses (containing P and ~P)
 Remove duplicate literals within clauses (Set semantics)
 Remove subsumed clauses
       │
       ▼
 Canonical CNFTheory
```

---

### 3. Prover Engines

#### Strategy A: Ordered Resolution Engine (`src/Prover/Resolution.hs`)
- **Unification (`src/Prover/Unification.hs`)**: Robinson's Most General Unifier (MGU) algorithm with occurs-check.
- **Inference Rules**:
  1. **Binary Resolution**:
     $$\frac{C \lor A \quad D \lor \neg B}{(C \lor D)\sigma} \quad \text{where } \sigma = \text{mgu}(A, B)$$
  2. **Positive Factoring**:
     $$\frac{C \lor A \lor B}{(C \lor A)\sigma} \quad \text{where } \sigma = \text{mgu}(A, B)$$
  3. **Paramodulation / Superposition** (for equality handling):
     $$\frac{C \lor s = t \quad D \lor L[s']}{(C \lor D \lor L[t])\sigma} \quad \text{where } \sigma = \text{mgu}(s, s')$$
- **Saturation Loop (Given-Clause / DISCOUNT Algorithm)**:
  - Maintain two sets: `Unprocessed` (priority queue by clause weight) and `Processed` (passive set).
  - Loop:
    1. Select lightest clause $C$ from `Unprocessed`.
    2. Check if $C$ is the empty clause $\Box$ $\implies$ **UNSAT (Theorem Proved)**.
    3. Perform forward subsumption: if $C$ is subsumed by any clause in `Processed`, discard $C$.
    4. Perform backward subsumption: remove any clauses in `Processed` subsumed by $C$.
    5. Resolve $C$ against all compatible clauses in `Processed`.
    6. Add newly generated clauses to `Unprocessed`.
    7. Add $C$ to `Processed`.
    8. Terminate if `Unprocessed` is empty $\implies$ **SAT (Theory Consistent)** or step limit reached $\implies$ **UNKNOWN / TIMEOUT**.

#### Strategy B: Analytic Free-Variable Semantic Tableaux (`src/Prover/Tableau.hs`)
- Constructs tree derivations using Smullyan-style rules:
  - $\alpha$-rules: Non-branching (conjunctions $\phi \land \psi$).
  - $\beta$-rules: Branching (disjunctions $\phi \lor \psi$).
  - $\gamma$-rules: Universal expansion with free variables.
  - $\delta$-rules: Existential expansion with Skolem terms.
- **Model Construction**: When all branches are saturated without closure, extract a finite Herbrand interpretation or counterexample valuation to explain why a conjecture failed.

---

## 📋 Implementation Roadmap & Work Breakdown

### Phase 1: Canonical CNF Intermediate Representation
- [ ] **Task 1.1**: Create [`src/IR/CNF.hs`](src/IR/CNF.hs) defining `VarId`, `SkolemId`, `Term`, `Literal`, `Clause`, and `CNFTheory`.
- [ ] **Task 1.2**: Implement [`src/IR/Clausify.hs`](src/IR/Clausify.hs) with NNF transformation, variable standardization, and skolemization.
- [ ] **Task 1.3**: Implement clausal distribution ($\lor$ over $\land$) with tautology pruning.
- [ ] **Task 1.4**: Add unit tests in `test/CNFSpec.hs` verifying roundtripping, De Morgan correctness, and Skolem arity consistency.

### Phase 2: First-Order Unification & Term Indexing
- [ ] **Task 2.1**: Implement Robinson's MGU algorithm in [`src/Prover/Unification.hs`](src/Prover/Unification.hs) with occurs-check.
- [ ] **Task 2.2**: Implement substitution application and composition ($\sigma_1 \circ \sigma_2$).
- [ ] **Task 2.3**: Implement clause subsumption checking ($C \subseteq_\sigma D$).
- [ ] **Task 2.4**: Unit tests in `test/UnificationSpec.hs` covering cyclic terms, variable renaming, and failure cases.

### Phase 3: Native Resolution Prover Engine
- [ ] **Task 3.1**: Implement the Given-Clause saturation loop in [`src/Prover/Resolution.hs`](src/Prover/Resolution.hs).
- [ ] **Task 3.2**: Implement binary resolution and positive factoring rules.
- [ ] **Task 3.3**: Implement step/clause iteration limits and execution timeouts (`timeout :: Int -> IO a -> IO (Maybe a)`).
- [ ] **Task 3.4**: Implement refutation proof trace generation (reconstructing the derivation tree from empty clause back to input axioms).

### Phase 4: Semantic Tableaux & Countermodel Generation
- [ ] **Task 4.1**: Implement tableau tree data structures in [`src/Prover/Tableau.hs`](src/Prover/Tableau.hs).
- [ ] **Task 4.2**: Implement branch unification and branch closure checking.
- [ ] **Task 4.3**: Implement open branch valuation extraction for counterexample reporting.

### Phase 5: Compiler & CLI Integration
- [ ] **Task 5.1**: Register `NativeProver` in [`src/Solver.hs`](src/Solver.hs) (`ProverType Native`).
- [ ] **Task 5.2**: Update `AutoProver` fallback chain: `Z3 -> CVC5 -> Vampire -> NativeProver` (never error out due to missing binaries).
- [ ] **Task 5.3**: Add REPL commands in [`src/REPL.hs`](src/REPL.hs): `:cnf` (print CNF clauses), `:prover native`.
- [ ] **Task 5.4**: Add CLI flag `--prover native` to `Main.hs`.

### Phase 6: Verification & Benchmarking
- [ ] **Task 6.1**: Run full existing test suite (472 examples) with `--prover native`.
- [ ] **Task 6.2**: Add TPTP benchmark problems (subset of basic FOF problems) in `test/NativeProverSpec.hs`.
- [ ] **Task 6.3**: Benchmark memory consumption and saturation speed against BFO 2020 standard library.
