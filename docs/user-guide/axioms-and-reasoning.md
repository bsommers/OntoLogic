# Axioms and reasoning

OntoLogic checks an ontology in two layers. The linter is fast, runs on every invocation, and catches structural mistakes and obvious contradictions. The solvers (Z3, CVC5, Vampire, or the built-in native prover) are invoked with `--solve` and answer deeper questions: can all axioms hold at once (consistency), and can every concept have an instance (coherence)? This page explains what is checked, how to read SAT, UNSAT, and unknown results, and how to control time, memory, and prover choice.

## What axioms can say

Axioms are full first-order logic, not Horn clauses (see [Language reference](language-reference.md) for syntax). Typical uses:

| Intent | Axiom |
|--------|-------|
| Disjointness | `(forall (x) (implies (Truck x) (not (Car x))))` |
| Property bound | `(forall (v) (implies (Vehicle v) (and (gte speed 0) (lte speed 130))))` |
| Required relation | `(forall ((t Truck)) (exists ((s Site)) (serves t s)))` |
| Subsumption | `(forall (x) (implies (Hybrid x) (Truck x)))` (also implied by `(def-concept Hybrid Truck)`) |
| Rule | `(forall (o) (implies (and (Oven o) (eq is_active True)) (gt temperature 100)))` |

Cardinality (`:cardinality`), `:optional`, and `:default` on properties and relations shape generated code and schemas but are not part of the solver's logical theory. If you need a cardinality to take part in reasoning, state it as an axiom.

Disjointness is not a separate keyword; write it as an implication to a negation, as above. The linter recognizes that pattern.

## Layer 1: the linter

`-t lint` (or any run, since the linter always goes first) checks:

- Undeclared parents, property domains, and relation endpoints; duplicate concepts, properties, relations, and namespace prefixes.
- Circular inheritance.
- Direct contradictions inside one axiom (`P and not P`, asserted `bottom`).
- Impossible numeric ranges on one property (`gt 5` with `lt 3`), within one axiom and across axioms for a concept and its ancestors.
- A propositional/Horn pass over the hierarchy and disjointness axioms that finds concepts forced to be empty, for example a subclass of two disjoint concepts.

```bash
ontologic-exe -i test/fixtures/domains/domain_mining_conflict.logic -t lint
```

```text
examples/domain_mining.logic:49:15: error: Property contradiction on methane_level: gt 5 and lt 3
examples/domain_mining.logic:27:14: error: Cross-axiom contradiction on GasSensor.methane_level: gt 5 and lt 3
examples/domain_mining.logic:27:14: error: Cross-axiom contradiction on GasSensor.methane_level: lt 3 and gt 5
```

(Paths are printed in full in real output; they are shortened here.) Any lint error stops the run with exit code 1. Because the linter runs first, `--solve` on an ontology with lint errors prints those errors and does not reach the solver.

Add `--warn-unmapped` to also report axioms that the field-constraint emitters cannot express (see below).

## Layer 2: the solvers

`--solve` (or `-t solve`) translates the ontology to a first-order theory over one sort, `Entity`, and runs two checks.

How the translation works (`src/FOLTheory.hs`):

| Source | Solver encoding |
|--------|-----------------|
| concept `C` | predicate `is_C(x)` |
| `(def-concept C P)` | `is_C(x) => is_P(x)` |
| relation `r` | predicate `rel_r(x, y)`, with domain and range implications |
| data property `p : T` | function `prop_p(x) -> T` (`Int`, `Real`, `Bool`, `String`) |
| entity-valued property | treated as a relation |
| comparison `(gt p v)` in a quantifier | `prop_p(<innermost bound variable>) > v` |
| `def-individual i C` | constant `ind_i`, asserted to be a `C` |
| any other predicate | uninterpreted predicate `up_P` |

1. **Consistency.** Can all translated axioms be true together? Result: SAT (a model exists), UNSAT (contradiction), or unknown (timeout, resource limit, or the solver gave up).
2. **Coherence.** For each concept, is there a model in which it has at least one instance? Concepts that cannot are reported as empty or unsatisfiable. A contradictory ontology makes every concept empty, which is why the UNSAT example below lists them all.

### Axioms that are not sent

Some axioms cannot be translated. They are listed before the verdict, and the verdict says how many were checked:

```text
⚠️  1 axiom(s) were not sent to the solver:
   - ForAll "c" (Implies (And (Predicate "Controller" [Var "c"]) (Eq (Var "safety_status") (Constant "False"))) (Eq (Var "active") (Constant "False"))) (unbound variable active)
✅ SMT Satisfiable (SAT) — Ontology is logically consistent for the 1 axioms checked.
```

Common reasons: an unbound variable, a comparison outside any quantifier, an ordering comparison on a non-numeric property, a property used with conflicting types, a predicate used with different arities. A SAT verdict only covers the axioms actually sent. Fix the axiom or use `--free-constants`.

### `--free-constants`

By default a variable that is free (not bound by a quantifier, not a declared individual, concept, relation, or property) is an error for that axiom (it is skipped). With `--free-constants`, such names become `Entity` constants:

```bash
ontologic-exe -i free.logic --solve
ontologic-exe -i free.logic --solve --free-constants
```

```text
⚠️  1 axiom(s) were not sent to the solver:
   - ForAll "x" (Implies (Predicate "A" [Var "x"]) (Predicate "Open" [Var "y"])) (unbound variable in predicate Open)
✅ SMT Satisfiable (SAT) — Ontology is logically consistent for the 0 axioms checked.
...
ℹ️  Free constants mode enabled (--free-constants): undeclared free variables are treated as Entity constants.
✅ SMT Satisfiable (SAT) — Ontology is logically consistent.
```

## Reading results

| Output | Meaning | Exit |
|--------|---------|------|
| `✅ SMT Satisfiable (SAT)` and `✅ All concepts are satisfiable` | Consistent and coherent | 0 |
| `❌ SMT Unsatisfiable (UNSAT)` | The axioms contradict each other | 1 |
| `❌ Unsatisfiable / empty concept(s): A B` | Those concepts cannot have instances | 1 |
| `⚠️ SMT Solver Result (unknown): ...` | Timeout, limit, or solver gave up; not a proof either way | 2 |
| `❌ SMT Solver Error: ...` | The solver ran and failed | 1 |
| `⚠️ Concept coherence check could not run` | Coherence step failed | 2 |

When several checks run, the worst code wins: 1 beats 2 beats 0.

### `--explain-unsat`

When the verdict is UNSAT, `--explain-unsat` re-runs the problem with every axiom named and prints the unsatisfiable core, the subset of axioms that already contradict each other:

```bash
ontologic-exe -i unsat.logic -t solve --explain-unsat
```

```text
❌ SMT Unsatisfiable (UNSAT) — Logical contradiction detected!
🔍 Unsatisfiable Core Conflicting Axioms:
   • Axiom #1: forall a (Account(a) implies gte(balance, 100))
   • Axiom #2: exists a (Account(a) and lt(balance, 50))
❌ Unsatisfiable / empty concept(s): Account Frozen
```

The numbers are the axioms' positions in the file. In the REPL use `:explain`.

### `--inspect-model`

For a satisfiable ontology, `--inspect-model` prints the solver's model: a finite universe of `Entity` values and the interpretation of every `is_C`, `rel_r`, and `prop_p` symbol. It is useful to see a concrete witness, and to notice when a constraint you expected is not binding.

```bash
ontologic-exe -i fleet.logic --solve --inspect-model
```

```text
✅ SMT Satisfiable (SAT) — Ontology is logically consistent.

📋 SMT Model Valuation:
(
;; universe for Entity:
;;   Entity!val!1 Entity!val!2 Entity!val!0
...
(define-fun prop_speed ((x!0 Entity)) Int
1)
```

A model is one possible world, usually a tiny one. Concepts that are empty in this particular model are not necessarily unsatisfiable; the coherence check is what decides that.

## Prover choice

`-p/--prover` takes `z3`, `cvc5`, `vampire`, `native`, or `auto` (default); anything else is an error (`Unknown prover 'bogus'. Valid options: z3, cvc5, vampire, native, auto`, exit 1).

| Prover | Notes |
|--------|-------|
| `z3` | External. Handles integer and real bounds well; supports `-T` and `--solve-memory`. Good default |
| `cvc5` | External. Run with finite-model finding and unsat-core support; supports `-T` |
| `vampire` | External. First-order specialist; given SMT-LIB or TPTP input; supports `-T` |
| `native` | Built into the binary (tableau and resolution). No install needed; honours `-T`; reports unknown on step or clause limits |
| `auto` | Tries `z3`, `cvc5`, `vampire` in order, skipping any that is not installed; if none is installed, falls back to `native`. A solver that is installed but fails is reported, not skipped |

Practical guidance: use `z3` or `cvc5` for ontologies with numeric property bounds. `native` and `vampire` have no arithmetic. OntoLogic gives them one background axiom for each pair of numeric bounds in the file that no number can meet together (such as `gte 100` and `lt 50`), so they catch contradictions like the balance example above. They still miss contradictions that need real arithmetic, such as integer gaps (`gt 5` and `lt 6` on an `Integer`) or bounds derived from sums. The domain fixtures in `test/fixtures/domains/` are checked with Z3 (then CVC5) for this reason. For purely taxonomic and relational reasoning, all backends agree. If two provers disagree, trust UNSAT from an SMT solver and treat the other's SAT as incomplete.

## Time and memory limits

```bash
ontologic-exe -i big.logic --solve -p z3 -T 60 --solve-memory 2048
```

| Flag | Applies to | Behaviour |
|------|-----------|-----------|
| `-T/--solve-timeout SECONDS` | z3, cvc5, vampire, native | Positive integer. Each backend gets its own limit flag; external solvers are also killed after the limit plus a 2 second grace period. A timeout is reported as unknown (exit 2), never as an error |
| `--solve-memory MB` | z3 only | Positive integer. With `-p cvc5|vampire|native` it prints `⚠️ --solve-memory is not supported by CVC5 and is ignored.`; with `auto` it warns it applies only if Z3 is the selected prover |

Zero and negative values are rejected: `option -T: expected a positive integer, got '0'`. For Z3 and CVC5 the coherence check runs all concepts in one solver process, so `-T` is a single budget for that whole batch; Vampire and native get the budget once per concept.

## Subsumption proofs

"Is every Truck necessarily a Vehicle?" is answered in the [REPL](repl.md) with `:prove Truck Vehicle`; a counterexample model is printed when the answer is no. There is no CLI flag for it.

## From axioms to generated code

Emitters work on the same parsed model but not through the solver. Axioms shaped like `forall x. Concept(x) implies comparisons` become field constraints; others are reported as unmapped (a `⚠️ Warning` on the CLI plus a comment in the output file, where the format allows). Targets without a built-in unmapped warning can be asked with `--warn-unmapped`. A clean `--solve` does not mean every axiom is enforced at runtime in generated code; see [Targets and emitters](targets-and-emitters.md).

## CNF output

`--cnf` prints the clausal normal form the native prover works with and exits, which helps to debug how an axiom is understood:

```bash
ontologic-exe -i fleet.logic --cnf
```

```text
~Car(X1) | ~Truck(X1)
~Car(X1) | Vehicle(X1)
~Truck(X1) | Vehicle(X1)
~Truck(X1) | gte(X2, 0)
~Vehicle(X1) | gte(X2, 0)
~Vehicle(X1) | lte(X2, 130)
~drives(X1, X2) | Driver(X1)
~drives(X1, X2) | Vehicle(X2)
```

Next: [CLI reference](cli-reference.md)
