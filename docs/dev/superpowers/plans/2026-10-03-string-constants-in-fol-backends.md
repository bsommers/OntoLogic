# String constants in the FOL backends

**Status:** proposal from clif2OntoLogic (2026-10-03). Not scheduled. Additive to
`2026-10-01-clif-interop-fol-port.md`; does not touch the v1.7.0 work.

## Problem

CLIF distinguishes a quoted string `'abc'` (denotes the string) from a name `abc`.
clif2OntoLogic now emits CLIF strings as OntoLogic string literals (`"abc"`) and
names as identifiers (clif2OntoLogic 16-05, commit f7c7b96). OntoLogic parses both,
but the FOL term type cannot keep them apart:

```haskell
data Term = Var Name | Constant String | Apply Name [Term]   -- src/OntoLogic.hs
```

`Parser.parseTerm` stores a string literal, a number and `True`/`False` all as
`Constant String`. `FOLTheory.translateTerm` then re-reads the text with
`parseValue`, so the kind is guessed from the contents (read from source on main at
82e4428, not yet run against a test file):

| OntoLogic source | Intended | SMT emitted today |
|---|---|---|
| `"1"` | the string "1" | `1` (an Int) |
| `"True"` | the string "True" | `true` (a Bool) |
| `"say \"hi\""` | a string | Haskell `show` escaping (`\"`), which SMT-LIB 2.6 does not use (it doubles quotes: `""`) |
| `"é"` | a string | `show` gives `"\233"`; SMT-LIB wants `\u{e9}` |

On the older fork pinned by clif2OntoLogic (`feature/upstream-extensions`), the SMT
backend wrote the raw text as a symbol instead, so `"None"` collided with the name
`None` and strings with spaces produced invalid SMT.

There is a sort problem too: entities are an uninterpreted sort, so an SMT `String`
literal as an argument of an entity predicate is ill-sorted.

## Proposal

1. Keep the kind from the parser: add `StringLit String` and `NumberLit ...` (or a
   tag on `Constant`) so `translateTerm` never guesses from the contents.
2. In FOL backends, encode a string literal as a distinct entity constant whose name
   cannot clash with a user name, e.g. `|s:<hex of UTF-8>|`, and assert pairwise
   distinctness of the string constants that occur (unique names for strings). This is
   what clif2OntoLogic's own Tier-2 encoder does (`verify/smt.py`, `smt_string_symbol`).
3. Apply the same rule in the TPTP emitter (`tptpConst`), which has the same
   ambiguity.

## Test cases

- `(P "1")` and `(P 1)` must not be interchangeable: asserting one and refuting the
  other is SAT.
- `(P "None")` and `(P None)` likewise.
- `(P "a b")`, `(P "say \"hi\"")`, `(P "é")` produce SMT that z3 accepts.

## Affected clif2OntoLogic inputs

Five COLORE files carry CLIF strings that reach `--solve`; see
clif2OntoLogic `.planning/phases/16-reverse-transpiler-round-trip-semantic-fidelity/16-05-PLAN.md`
("Known upstream limitation").
