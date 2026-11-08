# OntoLogic FOL Language Completeness Analysis & Technical Debt Remediation Plan

- **Date**: 2026-09-26
- **Status**: Draft / Roadmap Proposal
- **Author**: Antigravity (Advanced Agentic Coding Engine)
- **Scope**: Formal logic semantics, compiler architecture, SMT translation, 16 target emitters, LSP/REPL, and test infrastructure.

---

## Executive Summary

OntoLogic's First-Order Logic (FOL) implementation is a **pragmatic, ontology-directed Horn-clause subset with first-order quantifiers**, but it is **not formally complete** with respect to standard First-Order Predicate Calculus with Equality (FOL=) or Many-Sorted First-Order Logic (MS-FOL).

While the AST supports arbitrary connectives ($\land, \lor, \neg, \to, \leftrightarrow$) and quantifiers ($\forall, \exists$), the downstream compiler pipeline exhibits severe semantic cliffs:
1. **SMT Solver Cliff**: `FOLTheory.hs` rejects functions in terms, arbitrary $n$-ary predicates ($n \ge 3$), variable-variable equality, and non-Entity sorts.
2. **Target Emitter Cliff**: Software and schema emitters (Java, Python, Rust, Go, TypeScript, OpenAPI, JSON Schema) only compile single-variable property bounds and simple implication rules; all other FOL formulas are dumped into `irUnmappedAxioms` and discarded without warnings.

This document details the exact theoretical and practical gaps in the FOL engine, audits technical debt across all 6 compiler layers, and lays out a phased remediation plan.

---

## Part 1: Is the FOL Language Complete?

### 1. Mathematical & Theoretical FOL Completeness

Standard First-Order Logic with Equality ($\mathcal{L}_{\text{FOL}}^{=}$) is defined over a signature $\Sigma = (\mathcal{S}, \mathcal{F}, \mathcal{P})$:
- Sorts $\mathcal{S}$
- Function symbols $\mathcal{F}$ with arities $f: s_1 \times \cdots \times s_n \to s$
- Relation/Predicate symbols $\mathcal{P}$ with arities $P \subseteq s_1 \times \cdots \times s_n$
- Terms: $t ::= x \mid c \mid f(t_1, \ldots, t_n)$
- Formulas: $\phi ::= P(t_1, \ldots, t_n) \mid t_1 = t_2 \mid \neg \phi \mid \phi_1 \land \phi_2 \mid \phi_1 \lor \phi_2 \mid \phi_1 \to \phi_2 \mid \phi_1 \leftrightarrow \phi_2 \mid \forall x:s.\, \phi \mid \exists x:s.\, \phi \mid \top \mid \bot$

### 2. Gap Analysis Matrix: OntoLogic vs. Standard FOL

| FOL Feature | Standard FOL / SMT-LIB2 | OntoLogic Implementation | Status | Impact |
| :--- | :--- | :--- | :--- | :--- |
| **Propositional Connectives** | $\land, \lor, \neg, \to, \leftrightarrow$ | `And`, `Or`, `Not`, `Implies`, `Iff` in `FOL` | **Complete** | Full boolean expressive power |
| **Quantifiers** | $\forall x, \exists x$ | `ForAll Name FOL`, `Exists Name FOL` | **Syntactically Complete** | Unrestricted nesting supported in AST |
| **Truth Constants** | $\top$ (True), $\bot$ (False) | Not in `FOL` AST; simulated as `Constant "True"` | **Incomplete** | Cannot write bare truth constants in formulas |
| **Terms & Function Symbols** | $t ::= x \mid c \mid f(t_1, \ldots, t_k)$ | `data Term = Var Name \| Constant String` | **Incomplete** | **No function symbols** ($f(x)$). No arithmetic terms ($(x + y)$). |
| **Equality ($\approx$)** | First-class logical connective ($t_1 = t_2$) | Uninterpreted predicate `Predicate "eq" [t1, t2]` | **Incomplete** | No built-in equality axioms; variable equality ($x = y$) rejected by SMT |
| **Predicate Arity** | Arbitrary $n$-ary relations ($P(t_1, \ldots, t_n)$) | AST allows arbitrary arity; **SMT rejects $n \ge 3$** | **Incomplete** | Only arity 0 (bool), 1 (concept), 2 (relation), 3 (prop cmp) reach solver |
| **Sorts / Typing** | Many-sorted ($\forall x:\text{Sort}$) | Untyped in AST; SMT hardcodes all vars to `Entity` | **Incomplete** | Cannot quantify over integers, reals, timestamps, or domain sorts |
| **Arithmetic Theories** | LIA / LRA ($x + 2y \le 10$) | Only scalar property bounds ($p \le 10$) | **Incomplete** | Linear arithmetic across variables is impossible |
| **Target Code Generation** | Full logic compiling to executable checks | Only Horn property bounds & conditional implications | **Severely Incomplete** | 90% of expressive FOL is ignored by 14 of 16 emitters |

### 3. Conclusion on Language Completeness
OntoLogic is **not** a general-purpose FOL compiler. It is an **Ontological Description Logic (DL) / Horn-constraint language formatted as S-expression FOL**. Calling it "FOL" is syntactically accurate at parse-time, but semantically inaccurate at compile- and solve-time.

---

## Part 2: Comprehensive Technical Debt Audit

### Layer 1: Core AST, Type System & Grammar
1. **`Term` Algebraic Representation**:
   - `Term = Var Name | Constant String` prevents algebraic expressions, function applications, and skolem constants.
   - Numbers and booleans are stringly-typed in `Constant String` instead of a strongly-typed `Literal (LInt, LDouble, LBool, LString)`.
2. **Missing Equality Primitive in AST**:
   - `Predicate "eq"` and `Predicate "ne"` pollute the user predicate namespace and require ad-hoc pattern matching throughout `FOLTheory.hs`, `IR.hs`, and `Linter.hs`.
3. **Loss of Source Locations on AST Sub-Nodes**:
   - `SourceTable` records `SourcePos` only for top-level definitions (`concept:C`, `property:P`, `axiom:A`). Sub-formulas, terms, and predicates lose line/column information, preventing pinpoint squiggly diagnostics on inner sub-expressions.
4. **Keyword Shadowing in Parser**:
   - `Parser.hs` uses custom prefix checks `("def-" isPrefixOf op)` rather than a structured lexer/token stream, creating edge-case parsing hazards with custom identifiers.

### Layer 2: SMT Solver & Theory Translation
5. **Monolithic `Entity` Sort Fallacy**:
   - `FOLTheory.hs` emits `(declare-sort Entity 0)` and maps every quantified variable to `Entity`. This forces all concept predicates to be `(Entity -> Bool)`, discarding static domain/range sort information that modern SMT solvers (Z3, CVC5) use for rapid instantiation.
6. **Subprocess Pipe Invocations in `Solver.hs`**:
   - Solvers are invoked by spawning new processes via `readProcessWithExitCode ("z3", ["-in", "-smt2"])`. This incurs OS process creation overhead on every query, making large ontology suites or batch IDE linting sluggish.
7. **Naive Unsat-Core Isolation**:
   - `:explain` and `explainUnsatWith` compute unsat cores by sequentially removing axioms in a Haskell loop rather than using SMT-LIB2 native `:produce-unsat-cores` and tracking named assertions `(! (assert ...) :named ax_1)`.

### Layer 3: Multi-Target Code & Schema Emitters (16 Targets)
8. **Silent Dropping of `irUnmappedAxioms`**:
   - When an axiom contains disjunctions, existentials, multi-variable relations, or non-trivial formulas, it is placed in `irUnmappedAxioms`. Emitters (Java, Python, Rust, Go, TypeScript) silently ignore this list, emitting classes without full invariant enforcement.
9. **String Concatenation Anti-Pattern**:
   - All 16 emitters build target code via manual `++` string concatenations rather than an AST-based or pretty-printer library (e.g. `prettyprinter`). This leads to subtle whitespace, indentation, and escaping bugs.
10. **Neo4j Community vs. Enterprise Fragility**:
    - Cypher `IS NOT NULL` property constraints require Neo4j Enterprise. While filtered in PR #67 for optional fields, running `constraints.cypher` on Community Edition still fails for required properties unless an explicit configuration or flag is passed.
11. **RDF/XML String Formatting in OWL Emitter**:
    - `src/Emitters/Owl.hs` formats RDF/XML by hand-crafting XML tags with string concatenation. Escaping errors or malformed XML structures risk passing unseen if not validated against `librdf` or `rdflib`.

### Layer 4: Static Semantic Linter
12. **Heuristic Propositional Checking**:
    - `Linter.hs` uses string pattern matching for pairwise contradictions ($P$ and $\neg P$, $x = a$ and $x \neq a$). It lacks an internal propositional SAT or tableaux solver, missing transitive contradictions (e.g., $A \to B$, $B \to C$, $A \land \neg C$) without running an external SMT solver.

### Layer 5: Language Server (LSP) & REPL
13. **Full Document Synchronization Only**:
    - `src/LSP.hs` only implements `TextDocumentSyncKind.Full`. Every keystroke transmits and reparses the complete file buffer. For ontologies exceeding 10,000 lines, this causes editor lag.
14. **Synchronous SMT Execution in LSP**:
    - Running `ontologic.solve` blocks the stdio loop. If Z3 or CVC5 encounters an expensive quantifier instantiation, the language server hangs until timeout.

### Layer 6: Test Infrastructure & Operations
15. **Docker Neo4j Test Teardown Lifecycle**:
    - `test/CompileSpec.hs` optionally checks live Neo4j via Docker. Container cleanup must be rigorously guaranteed under failure modes to avoid leaking daemon resources.

---

## Part 3: Phased Remediation Plan

```mermaid
flowchart TD
    subgraph Phase 1: Formal Logic Foundations
        P1A["Refactor Term to Support Functions & Typed Literals"]
        P1B["Introduce Built-in Eq Connective (= t1 t2)"]
        P1C["Add Top (True) and Bottom (False) to FOL"]
    end

    subgraph Phase 2: Many-Sorted SMT Theory
        P2A["Sort Partitioning (Sort per Concept Hierarchy)"]
        P2B["Native SMT-LIB2 Named Unsat Cores (:named)"]
        P2C["Support Multi-Arity Predicates in SMT (n >= 3)"]
    end

    subgraph Phase 3: Emitter Parity & Diagnostics
        P3A["Unmapped Axiom Warning Diagnostics"]
        P3B["PrettyPrinter Integration for Emitters"]
        P3C["Neo4j --no-constraints Flag & Community Mode"]
    end

    subgraph Phase 4: IDE & Solver Performance
        P4A["Async LSP SMT Execution with Cancellation"]
        P4B["Incremental Text Synchronization in LSP"]
        P4C["Embedded SAT Engine in Linter"]
    end

    Phase 1 --> Phase 2
    Phase 2 --> Phase 3
    Phase 3 --> Phase 4
```

### Phase 1: Core FOL AST & Grammar Modernization
- **Goal**: Elevate FOL AST to full first-order logic with equality and typed terms.
- **Tasks**:
  1. Refactor `data Term`:
     ```haskell
     data Term
         = Var Name
         | Lit Literal
         | Apply Name [Term]
     data Literal
         = LInt Integer
         | LDouble Double
         | LBool Bool
         | LString String
     ```
  2. Add first-class `Eq Term Term`, `Top`, and `Bottom` to `data FOL`.
  3. Support typed quantifiers: `(forall ((x Sort)) ...)` with fallback to default `Entity`.
  4. Preserve `SourcePos` inside AST nodes (`AnnFOL SourcePos FOL`).

### Phase 2: Many-Sorted SMT-LIB2 Translation Engine
- **Goal**: Transform `FOLTheory.hs` from an uninterpreted `Entity` sort into a typed many-sorted SMT theory.
- **Tasks**:
  1. Generate distinct SMT sorts for disjoint top-level taxonomy branches.
  2. Support $n$-ary predicates ($n \ge 3$) by declaring `(declare-fun pred (Sort_1 ... Sort_n) Bool)`.
  3. Replace naive unsat core loop with native SMT-LIB2 `(! formula :named ax_id)` and `(get-unsat-core)`.

### Phase 3: Compiler Transparency & Emitter Robustness
- **Goal**: Bridge the semantic gap between FOL expressions and code/schema emitters.
- **Tasks**:
  1. Emit structured compiler warnings when an axiom cannot be rendered into target code:
     `"Warning: Axiom (exists ...) cannot be represented in Java POJO; skipped in models-java."`
  2. Migrate target emitters from string concatenation (`++`) to `Data.Text.Prettyprint.Doc`.
  3. Add CLI flag `--neo4j-edition community|enterprise` to automatically comment out enterprise-only constraints.

### Phase 4: IDE Experience & Linter Hardening
- **Goal**: Sub-millisecond developer feedback loop in LSP and REPL.
- **Tasks**:
  1. Add embedded propositional Horn/Resolution engine in `Linter.hs` for instant contradiction detection.
  2. Implement async worker thread in `LSP.hs` for SMT solving with cancellation tokens.
  3. Upgrade LSP to `TextDocumentSyncKind.Incremental`.

---

## Acceptance Criteria & Success Verification

1. **FOL Expressivity Suite**: Test suite demonstrates parsing, SMT encoding, and theorem proving for:
   - Function terms ($f(x)$)
   - Variable-variable equality ($x = y$, $x \neq y$)
   - $n$-ary relations ($n \ge 3$)
   - Typed quantifiers ($\forall x: \text{Integer}$)
2. **Compiler Diagnostic Transparency**: Zero silent dropping of unmapped axioms; all dropped formulas generate explicit compiler warnings.
3. **Solver Performance**: SMT unsat core isolation runs in single invocation via `(get-unsat-core)`, reducing proof extraction time by $\ge 70\%$.
4. **Verification Gate**: Full compliance with local verification gate (`stack test --ghc-options="-Wall -Werror"` and `./gradlew :models-java:compileJava`).
