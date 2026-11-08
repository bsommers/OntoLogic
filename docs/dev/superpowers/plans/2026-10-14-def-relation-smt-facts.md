# `def-relation` as an asserted fact in the SMT backend

**Status:** proposal from clif2OntoLogic (2026-10-14). Not scheduled. Additive; touches only
`src/Emitters/SMT.hs` (`emitRelations`) if adopted.

## Problem

The SMT backend turns each `(def-relation R D1 ... Dn)` into a ground fact about the concept constants:

```smt2
; Relational Assertions
; Relation: lt
(declare-fun lt (Entity Entity) Bool)
(assert (lt Thing Thing))
```

(`emitRelations` in `src/Emitters/SMT.hs` on main at d647230: "Declare each relation name once; assert
one fact per domain/range pair". Measured below with the older pinned fork `feature/upstream-extensions`,
which does the same.)

A `def-relation` is a signature: it says what kinds of things `R` relates. It does not say that the
concept constants are related by `R`. Asserting the fact changes the theory, and for any relation
whose axioms make it irreflexive or strict on its domain, the theory becomes unsatisfiable:

```lisp
(def-concept Thing)
(def-relation lt Thing Thing)
(def-axiom "irreflexive" (forall (x) (not (lt x x))))
```

`ontologic-exe --solve` reports this file `SMT Unsatisfiable (UNSAT)`. Without the `def-relation` the
same axiom is SAT.

## Measured effect (clif2OntoLogic, full COLORE corpus, 2026-10-14)

clif2OntoLogic emits a `def-relation` for every relation it derives from the axioms (2,778 modules).
With OntoLogic's SMT and z3 at 10 s per module:

- 1,240 modules are UNSAT (after dropping duplicate declarations, see below).
- With only the `; Relational Assertions` facts removed, 55 stay UNSAT; 347 become SAT; 790 time out.
- Checking the source CLIF directly (native equality) gives 101 UNSAT modules in total.

So about 96% of the UNSAT answers come from the encoding. The smallest example is COLORE
`orderings/tree`: `(assert (sym_lt Thing Thing))` against `sym_lt x y = leq x y ∧ ¬leq y x`.

## Two smaller observations from the same run

1. About 580 modules declare a function twice with the same signature: once in the relations section
   and again in `; FOL Axioms & Declarations`. z3 prints `invalid declaration ... already declared`
   and continues, so the answer is unaffected, but every such run looks like an error to a tool that
   reads z3's output.
2. `--solve` starts `z3 -in` with no time or memory limit. clif2OntoLogic had z3 processes run for
   hours after a caller's timeout until it began killing the whole process group.

## Proposal

1. Declare relations in the SMT backend; do not assert facts about the concept constants. If a
   domain/range constraint is wanted in FOL, assert it as a guard over the arguments instead, for
   example `(forall ((x Entity) (y Entity)) (=> (lt x y) (and (isa x D1) (isa y D2))))`, which is what
   the signature means. Which membership predicate to use depends on how the backend models instances;
   that is a separate design choice.
2. Emit each `declare-fun` once across sections.
3. Optional: `--solve-timeout` / `--solve-memory` flags passed to z3 as `-T:` and `-memory:`.

## How clif2OntoLogic handles it meanwhile

Its consistency matrix (Phase 18) checks the CLIF source as the primary verdict and runs OntoLogic's
SMT as a second route. Modules that are UNSAT only because of these facts are reported in their own
cluster (`ontologic-relation-facts`). Its emitted `.logic` files are unchanged.
