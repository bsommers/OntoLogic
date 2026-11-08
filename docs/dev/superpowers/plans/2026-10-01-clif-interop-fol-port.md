# Milestone v1.8.0 Plan: CLIF Interop: Port `feature/upstream-extensions` onto `main`

> **Context:** [clif2OntoLogic](https://github.com/bsommers/clif2OntoLogic) translates COLORE / BFO-2020 Common Logic (CLIF) ontologies into `.logic` modules. Its Phase 08 work ("UP-01..UP-05") went onto branch `feature/upstream-extensions` (`b4376cf`), which forked from `064530a` (2026-09-17) and was **never merged**. Since then `main` has independently added equality (`Eq`), function terms (`Apply`), typed quantifiers, `Top`/`Bottom`, and a FOL→SMT theory (`FOLTheory.hs`). This milestone moves the parts of the branch that are still missing onto `main`, **without changing the `FOL` / `Term` data types**. Once it ships, clif2OntoLogic re-pins to the v1.8.0 tag.
> **Tracking Document:** [`.planning/ROADMAP.md`](../../../.planning/ROADMAP.md)
> **Sequencing:** Start after v1.7.0 (CNF + native prover) has merged. Branch: `feature/clif-interop-v1.8.0` off `main`.
> **Status:** Plan only. No code has been written.

---

## 🎯 Objectives

1. `main` parses and compiles the `.logic` that clif2OntoLogic emits, with no loss: n-ary `and`/`or`, `if` as an alias of `implies`, zero-arity function terms, declared individuals, and 0-ary predicates.
2. FOL axioms that mention **declared individuals** (CLIF constants such as `zero`, `origin`) reach Z3/CVC5/Vampire, instead of being dropped by `FOLTheory.translate` as `"unbound variable"`.
3. **Zero disruption:** nothing changes in `FOL`, `Term`, `ModelIR`, `IR.CNF`, or any emitter's pattern matches. All 472+ existing examples stay green, and output for every existing `examples/` file is byte-identical.

## 🧭 Hard Constraints (non-disruption)

| Constraint | Why |
|---|---|
| **No changes to `FOL` / `Term` constructors** (`And FOL FOL`, `Or FOL FOL`, `Eq`, `Apply` stay as they are) | `IR/Clausify.hs`, `FOLTheory.hs`, `Emitters/TPTP.hs`, `Linter/SAT.hs`, `LSP.hs` and all 14 emitters pattern-match on binary `And`/`Or`. The branch's `And [FOL]` would break every one of them, plus the v1.7.0 CNF pipeline. |
| **N-ary support is parser-only sugar** | `(and p1 … pn)` desugars to right-nested binary `And`, so downstream code never sees anything new. |
| **No positional `Registry` construction added** | 16 call sites build `Registry [] [] …` positionally. A new field must go through `emptyRegistry` / record update, or those sites break. |
| **Existing diagnostics keep their meaning** | Today an undeclared free name is reported as `"unbound variable"`, which catches typos. It must stay that way unless the name is explicitly declared. |
| **Do not merge `feature/upstream-extensions`** | Treat it as reference only. After v1.8.0 ships, tag it `archive/upstream-extensions` instead of deleting it (clif2OntoLogic history refers to its SHAs). |

## 🔍 Gap Analysis: branch vs `main` (as of `eb696f9`, v1.6.0)

| Branch item | On `main`? | v1.8.0 action |
|---|---|---|
| UP-01 equality `(= a b)` → `Equals` | ✅ `Eq`, written `=` or `eq`, plus `!=` | none (superseded) |
| UP-02 function terms `(f x)` → `FnApp` | ✅ `Apply`, but `parseApplyTerm` requires **≥1 argument** | allow zero-arity `(f)` (Phase 1) |
| UP-03 n-ary `and`/`or` | ❌ binary only (`parseAnd` takes exactly two `subFOL`) | parser desugaring (Phase 1) |
| UP-03 `if` alias of `implies` | ❌ | add keyword + reserved word (Phase 1) |
| UP-04 unmapped FOL → SMT | ✅ mostly: `FOLTheory.buildTheory`, with `theorySkipped` reasons | **port only the free-constant handling** (Phase 2) |
| UP-04 free constants → `(declare-const c Entity)` | ❌ `translateTerm (Var v)` returns `Left "unbound variable"` | declared individuals become constants (Phase 2) |
| UP-04 0-ary predicates | ❌ `Left "unsupported 0-ary predicate"` | declare as `Bool` constants (Phase 2) |
| UP-05 `def-individual` | ❌ | new item; stored without a positional `Registry` change (Phase 2) |
| UP-05 `//`, `/* */`, `#| |#` comments | ❌ only `;` | optional (Phase 3) |
| UP-05 wider identifier charset (`. / + * '`) | ❌ `identChar` = alnum `_ : -` | optional (Phase 3). clif2OntoLogic mangles symbols into `[A-Za-z0-9_:-]`, so it doesn't need this |
| `b4376cf` keyword-prefix fix | ✅ `keyword` uses `notFollowedBy identChar` | none (superseded) |

---

## 🧱 Phase 1: Parser sugar (n-ary connectives, `if`, zero-arity terms)

**Files:** `src/Parser.hs`, `test/ParserSpec.hs`.

- `parseAnd` / `parseOr` read `some subFOL` and then fold:
  - `[p]` → `p`
  - `p:ps` → `foldr1 And (p:ps)`, which is right-nested, so `(and a b)` gives exactly the same AST as today.
  - `(and)` → `Top` and `(or)` → `Bottom`, following CLIF semantics for empty conjunction and disjunction. Use `many` plus an explicit match.
- `parseImplies` accepts `keyword "if"` as well as `"implies"`. Add `"if"` to `reservedWords`.
- `parseApplyTerm`: `many parseTerm` instead of `some`. Keep it after the constant/literal alternatives so `(f)` doesn't capture a parenthesized formula. Add a regression test that `(not (p))` still parses as `Not (Predicate "p" [])`.
- **Formatter round-trip:** the `formatFOL` and LSP formatting provider print binary form. That's acceptable because the meaning is the same; document it in the CHANGELOG ("n-ary input is normalized to binary nesting").

**Tests:**
- `(and a b c)` ≡ `(and a (and b c))` as an AST.
- Unary `and` and `or`, and empty `and` and `or`.
- `if` gives the same AST as `implies`.
- `if` is still rejected as a predicate name.
- `(f)` gives `Apply "f" []`.
- **Golden:** every `examples/*.logic` gives the same `Registry` before and after the change. Snapshot `show` output before the branch starts.

## 🧱 Phase 2: Declared individuals and free constants in `FOLTheory` (UP-04 port)

**Files:** `src/Parser.hs`, `src/OntoLogic.hs`, `src/FOLTheory.hs`, `src/Emitters/TPTP.hs` (check only), `test/SMTSpec.hs`, `test/SolverSpec.hs`.

1. **`def-individual` syntax:** `(def-individual <name> [<concept>])`.
   - **Storage options:**
     - (a) A new `individuals :: [(Name, Maybe Name)]` field set only through `emptyRegistry` and record update. Before choosing this, migrate the 16 positional `Registry` constructions to `emptyRegistry { … }` in a separate commit that changes nothing else.
     - (b) Lower each one to existing items: an axiom `Predicate concept [Var name]` plus an entry in a new `Set Name` carried by `makeEnv`.
   - **Recommendation:** (a), with the migration commit first.
2. **`makeEnv` / `translate`:** a name that isn't bound by a quantifier but is a declared individual translates to `ind_<name>` and gets a `(declare-const ind_<name> Entity)` in `theoryDecls`.
   - If the individual has a concept, add `(assert (is_C ind_<name>))`.
   - Undeclared free names keep returning `Left "unbound variable …"`, so the typo diagnostic stays.
   - Add the prefix `ind_` to the clash checks `makeEnv` already runs for `up_` (v1.5.1).
3. **0-ary predicates:** `(p)`, where `p` isn't a boolean property, becomes `(declare-fun up_p () Bool)` instead of being skipped. Arity tracking in `envUserPreds` already exists; extend it to arity 0.
4. **TPTP / Vampire:** confirm `Emitters/TPTP.hs` emits declared individuals as lowercase FOF constants. Add one SolverSpec case per prover that uses an individual.
5. **Optional flag:** `--free-constants` treats *every* free name as an individual, for bulk corpus runs. It's off by default and reported in the diagnostics header.

**Tests:**
- A contradiction found through an individual: `(def-individual zero)`, `(forall (x) (not (= x zero)))`. Z3 must report UNSAT where it previously skipped the axiom.
- Undeclared free names are still skipped, with the same reason string.
- Every axiom in `theorySkipped` must still appear in the unmapped-axiom warnings. Count before and after on `examples/`; it may only go down, and only for files that declare individuals.

## 🧱 Phase 3 (optional): Lexical extensions

Low priority. Ship it only if it costs nothing in the LSP's semantic tokens or formatter.

- Extra `sc` comment styles: `//`, `/* */`, `#| |#`. Semantic tokens must classify them as comments.
- Wider identifier charset. **Risk:** `identChar` is shared with `keyword`. Adding `.` or `/` changes which characters may follow a keyword, and `parseApplyTerm`'s `funcName` already accepts `+ - * /`. Defer unless another consumer needs it.

## 🧱 Phase 4: CLIF interop conformance suite and release

- Add `test/fixtures/clif-interop/`: about 10 hand-written `.logic` files covering what clif2OntoLogic emits under its `ontologic-next` profile (n-ary connectives, `=`, nested function terms, individuals, `;;` provenance comments, `(def-axiom "<label>" …)`).
  - **License:** don't copy COLORE-derived output into this repo (it's CC BY-SA 4.0). Write the fixtures by hand under Apache-2.0.
- Add `test/ClifInteropSpec.hs`: every fixture parses, compiles to `ModelIR`, has an expected `theorySkipped` count, and gives the expected Z3 verdict.
- Update `CHANGELOG.md` `[1.8.0]`, bump the version in `package.yaml`, update STATE/ROADMAP, then tag `v1.8.0`.
- **Downstream follow-up (clif2OntoLogic, not this repo):**
  - Re-pin `upstreams.lock` to the `v1.8.0` SHA.
  - Point the `ontologic-next` profile at `main`'s grammar.
  - Emit `def-individual` for closure-signature constants.
  - Run its `test_ontologic_oracle.py` / `test_ontologic_solver_agreement.py` against the new binary.

---

## ✅ Verification Gates (each phase)

1. `stack test` is fully green. The baseline is 472 examples / 0 failures at v1.6.0, plus whatever v1.7.0 adds.
2. Golden check: `show` of the parsed `Registry` and the output of every emitter on each `examples/*.logic` is byte-identical to the pre-branch snapshot. The only exception is Phase 2 SMT output for files that use `def-individual`, and no existing example does.
3. `git diff main -- src/IR/ src/Prover/` is empty. v1.8.0 never touches the v1.7.0 modules.
4. LSP smoke test: open a fixture, then check that diagnostics, hover and formatting work, and that n-ary input formats to binary without errors.

## ⚠️ Risks

| Risk | Mitigation |
|---|---|
| v1.7.0 is still in progress and touches `Solver.hs` | Start after v1.7.0 merges. Phase 1 touches only `Parser.hs`. |
| `(f)` vs parenthesized-formula ambiguity in `parseApplyTerm` | Order the alternatives carefully and add regression tests (Phase 1). |
| Free-constant promotion hides typos | Do it only for declared individuals. `--free-constants` is opt-in and printed in the header. |
| `Registry` field addition breaks positional constructors | Migrate to `emptyRegistry { … }` in a separate commit first. |
