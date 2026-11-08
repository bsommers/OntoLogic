#!/usr/bin/env bash
# Draft issues from a code review of OntoLogic (main @ 064530a). Nothing is filed unless you pass --file.
#
#   ./.issues/draft-2026-09-19.sh           # dry run: print every issue
#   ./.issues/draft-2026-09-19.sh --file    # create them with gh (after review)
#   REPO=owner/name ./.issues/draft-2026-09-19.sh --file
#
# Index (severity order):
#    1. [bug, critical]     :unsat reports success on solver failure; solver errors print empty
#    2. [bug, major]        Superclass bounds ignored by linter and :unsat; empty subclasses pass
#    3. [bug, major]        SMT solver drops FOL axioms; :prove disproves subsumptions axioms state
#    4. [bug, major]        Axiom with (and (C x) ...) antecedent applied to every C instance
#    5. [bug, major]        Predicate names starting with a keyword fail to parse (e.g. orderedBy)
#    6. [bug, major]        Cyclic inheritance hangs REPL :emit/:ir and LSP hover forever
#    7. [bug, major]        LSP framing counts chars not bytes; non-ASCII text desyncs the server
#    8. [bug, major]        Misspelled or incomplete def-* forms silently parsed as axioms
#    9. [bug, major]        SMT-LIB output invalid for small/large floats and reused relation names
#   10. [bug, major]        Go/Rust/Python output fails to compile; Zod drops inherited bounds
#   11. [bug, major]        Neo4j/Mermaid/D2/GraphQL/OpenAPI output unloadable for stdlib ontologies
#   12. [bug, major]        LSP flags valid stdlib imports as undeclared; all diagnostics on line 0
#   13. [security, major]   VS Code SMT commands shell-inject file paths/settings; wrong CLI path
#   14. [bug, major]        Stdlib imports fail unless ontologic runs from the repo root
#   15. [bug, minor]        capabilities.json and ontology/ bindings from 064530a are broken
#   16. [bug, major]        --solve exits 0 when the solver returns unknown
#   17. [bug, minor]        REPL crashes with hGetLine: end of file on Ctrl-D or piped input
#   18. [enhancement, minor] Make Acme namespace and Java package configurable
#   19. [refactor, minor]   Deduplicate registry helpers and share one emit-target table
#   20. [bug, minor]        ecosystem.logic models code symbols as classes; count wrong
#
# Environment for every reproduction below, unless marked [UNVERIFIED]:
#   Linux, main @ 064530a, `stack build` (lts-21.25 / GHC 9.4.8), z3 and cvc5 on PATH.
set -euo pipefail

REPO="${REPO:-}"                      # empty = repo of the current directory
MODE=dry-run
[[ "${1:-}" == "--file" ]] && MODE=file

# Labels used below that the repo does not have yet (repo only has the GitHub defaults).
# Uncomment after review:
#   gh label create security --color b60205 --description "Security-relevant defect"
#   gh label create critical --color b60205 --description "Severity: critical"
#   gh label create major    --color d93f0b --description "Severity: major"
#   gh label create minor    --color fbca04 --description "Severity: minor"

USED_LABELS=()

# Fail before anything is filed if any label used below is missing from the repo.
check_labels() {
  local have missing=()
  have="$(gh label list ${REPO:+--repo "$REPO"} --limit 500 --json name -q '.[].name')"
  for l in $(printf '%s\n' "${USED_LABELS[@]}" | sort -u); do
    grep -qxF "$l" <<<"$have" || missing+=("$l")
  done
  if ((${#missing[@]})); then
    echo "Missing labels: ${missing[*]}. Create them or edit this script." >&2
    exit 1
  fi
}

# issue "<title>" "<label>,<label>" <<'BODY' ... BODY
issue() {
  local title="$1" labels="$2" body
  body="$(cat)"
  if [[ $MODE == collect ]]; then
    IFS=, read -ra l <<<"$labels"
    USED_LABELS+=("${l[@]}")
  elif [[ $MODE == file ]]; then
    gh issue create ${REPO:+--repo "$REPO"} --title "$title" --label "$labels" --body "$body"
  else
    printf '=== %s  [%s]\n%s\n\n' "$title" "$labels" "$body"
  fi
}

# ---- Issues (edit below) ----
all_issues() {

issue ":unsat reports success on solver failure; solver errors print empty" "bug,critical" <<'BODY'
## Summary
When a solver is missing or fails, `:unsat` and the VS Code "Check Concept Satisfiability" command report success. Other solver errors reach the user as empty or misleading text.

## Description
**Steps to reproduce**
1. `printf ':load examples/smart_factory.logic\n:unsat\n:solve\n:quit\n' | env PATH=/usr/bin:/bin stack exec ontologic-exe -- --repl`
2. With z3 and cvc5 installed, run `ontologic-exe -i f.logic --solve` on any input that makes Z3 fail. Example: `(forall (x) (implies (V x) (lt p 0.001)))` with `p` declared `Double` (see the invalid SMT-LIB issue).

**Expected:** `:unsat` reports that no solver could run. Solver errors show the solver's own message.

**Actual:**
- Step 1: `:unsat` prints `✅ All concepts are satisfiable (0 empty concepts)`. `:solve` in the same session prints `No compatible SMT solver found in PATH`.
- Step 2 with `-p z3`: `❌ SMT Solver Error: Z3 exited with error code 1: `, with nothing after the colon.
- Step 2 with the default `auto` prover: `No compatible SMT solver found in PATH (tried z3, cvc5, vampire). Please install Z3 or CVC5.`, even though both are installed.

**Evidence**
- `src/Solver.hs:211`: `checkSingleClassSatisfiability` maps `Left _ -> return False`, so a failed run counts as "satisfiable".
- `editors/vscode/src/extension.ts:91` shows a success toast when stdout contains `0 empty concepts`.
- `src/Solver.hs:72-100`: on a non-zero exit, `runProver` reports `stderr`. z3 and cvc5 write errors to stdout.
- `src/Solver.hs:104-117`: `AutoProver` falls through on any `Left`, including real solver errors.
- `src/Main.hs:85-89`: an unknown `--prover` value (e.g. `z4`) silently becomes `auto`.
- `src/Main.hs:94`: `Unknown` exits 0.

## Why it matters
Anyone using `:unsat` without a solver, or with an input the solver rejects, gets a false "verified" result, and CI or editor users will trust it. When the solver does report an error, users are told to install tools they already have and never see the real message.

## Suggested fix
Suggestion:
- `checkSingleClassSatisfiability :: ... -> IO (Either String Bool)` and `findUnsatConceptsWith :: ... -> IO (Either String [String])`. Print the error in the REPL.
- Include stdout in error text.
- In `auto`, fall back to the next solver only when the executable is missing (an `IOException` of the does-not-exist kind).
- Reject unknown `--prover` values, and exit non-zero on `Unknown`.
- Optional: run every per-class check in one solver process with `(push)`/`(pop)` or `check-sat-assuming`. Today it starts one process per class: `ecosystem.logic` takes about 11.6 s for 935 classes with Z3.

Tests: stub `PATH` with no solvers, then assert that `:unsat` reports an error. Feed an invalid SMT string and assert the error text contains the solver's message.

## Acceptance criteria
- [ ] `:unsat` with no solver on PATH reports an error, not success
- [ ] Solver error text includes the solver's stdout diagnostics
- [ ] `auto` with z3 installed but failing reports the Z3 error, not "no solver found"
- [ ] `--prover z4` exits non-zero with a usage error
- [ ] The VS Code command shows success only on an explicit success result

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "Superclass bounds ignored by linter and :unsat; empty subclasses pass" "bug,major" <<'BODY'
## Summary
Numeric bounds declared on a superclass are never combined with a subclass's bounds. A subclass that can have no instances passes both the linter and `:unsat`.

## Description
**Steps to reproduce**
```lisp
(def-concept Vessel)
(def-concept Tank Vessel)
(def-property capacity Vessel Integer)
(forall (x) (implies (Vessel x) (gt capacity 10)))
(forall (x) (implies (Tank x) (lt capacity 5)))
```
1. `ontologic-exe -i f.logic -t lint`
2. REPL: `:load f.logic` then `:unsat`

**Expected:** `Tank` is reported as contradictory (capacity > 10 and < 5).
**Actual:** `✅ Logic Validated successfully.` and `✅ All concepts are satisfiable (0 empty concepts)`.

**Evidence**
- `src/IR.hs:65`: `getLocalConstraints name axs` uses only the class's own name.
- `src/IR.hs:119`: an inherited property carries only the subclass's own bounds.
- `src/Solver.hs:196-205`: each class gets its own function (`Tank_capacity`, `Vessel_capacity`), with nothing linking them.
- `src/Linter.hs:170`: `checkConceptAxioms` groups bounds by concept only.

## Why it matters
Finding concepts that refinement makes empty is the stated purpose of `:unsat` and the cross-axiom linter, and this is the most common way to produce one. The emitters then generate subclasses that can never validate. For example, the Java subclass getter gets `@Max(4)` while the parent getter has `@Min(11)`.

## Suggested fix
Suggestion: when compiling a class, merge the bounds of the class and every ancestor per property, using a cycle-safe `getAncestors`. Use the merged set in the linter, the SMT per-class check, and the emitters. Add the repro above as a Linter and Solver test.

## Acceptance criteria
- [ ] The repro fails lint with a cross-level contradiction message
- [ ] `:unsat` lists `Tank`
- [ ] Emitters include the parent's bounds on the subclass
- [ ] Regression tests in `test/SolverSpec.hs` and the linter spec

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "SMT solver drops FOL axioms; :prove disproves subsumptions axioms state" "bug,major" <<'BODY'
## Summary
The SMT encoding leaves out every FOL axiom. Subsumption proofs contradict the ontology, and `--solve` reports "logically consistent" for logic the solver never saw.

## Description
**Steps to reproduce**
```lisp
(def-concept Animal)
(def-concept Dog)
(forall (x) (implies (Dog x) (Animal x)))
```
REPL: `:load f.logic` then `:prove Dog Animal`.

**Expected:** `✅ Theorem Proved`.
**Actual:** `❌ Theorem Disproved ... 'Dog' is NOT subsumed by 'Animal'`, followed by a "counterexample".

**Evidence:** `emitSMTBase` (`src/Solver.hs:219-231`, and the copy in `src/Emitters/SMT.hs:7-28`) emits only:
- class constants
- `subClassOf` facts from `def-concept` parents
- per-class numeric bounds
- relation facts

Axioms in `irUnmappedAxioms` are dropped: implications between concepts, disjointness written with `not`, `exists`, `iff`, and relation axioms. The solver can only ever find numeric bound conflicts, and the linter already rejects those before `--solve` runs (`src/Main.hs:73-77`), so `--solve` effectively always prints "consistent".

## Why it matters
The README advertises consistency checking and taxonomic subsumption proofs. Any ontology whose hierarchy is defined by axioms gets wrong answers, and "consistent" is reported without the logic being checked.

## Suggested fix
Suggestion:
- Encode concepts as unary predicates over `Entity`, relations as binary predicates, and properties as functions.
- Translate FOL structurally (ForAll, Exists, Implies, And, Or, Not, Iff).
- Prove A ⊑ B by checking that `(exists ((x Entity)) (and (A x) (not (B x))))` is unsat.

Until then, print the axioms that were not translated (as `warnUnmappedAxioms` does) and stop claiming "logically consistent".

Tests:
- the Dog/Animal repro
- a disjointness axiom that makes a concept empty

## Acceptance criteria
- [ ] `:prove Dog Animal` succeeds for the repro
- [ ] Axioms are included in, or explicitly reported as missing from, `--solve` output
- [ ] SolverSpec covers subsumption defined by an axiom

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "Axiom with (and (C x) ...) antecedent applied to every C instance" "bug,major" <<'BODY'
## Summary
A conditional axiom such as `(implies (and (Tank x) (Military x)) ...)` is applied to every `Tank`. The linter then reports false contradictions, and the emitters generate wrong validators.

## Description
**Steps to reproduce**
```lisp
(def-concept Tank) (def-concept Civil) (def-concept Military)
(def-property capacity Tank Integer)
(forall (x) (implies (and (Tank x) (Civil x))    (lt capacity 50)))
(forall (x) (implies (and (Tank x) (Military x)) (gt capacity 100)))
```
`ontologic-exe -i f.logic -t lint`

**Expected:** passes, because the two bounds apply to different subsets.
**Actual:** `Cross-axiom contradiction on Tank.capacity: gt 100 and lt 50`, exit 1. No target can be generated.

**Evidence**
- `src/OntoLogic.hs:176`: `matchesConcept (And p1 p2) = matchesConcept p1 || matchesConcept p2`. `matchesConcept` also ignores which variable the predicate uses.
- The same data feeds the IR bounds used by Java, Pydantic, Zod, JSON Schema, SHACL and the Neo4j audits.
- `isUnmappedAxiom` (`src/IR.hs:141-150`) reports these same axioms as "could not be mapped".

## Why it matters
Valid ontologies are rejected. Where there is no conflict, generated validators enforce a constraint on every instance that was meant for a subset.

## Suggested fix
Suggestion: accept only antecedents that are exactly `(C v)`, where `v` is the quantified variable. That is the same rule as `isSimpleConceptMembership`. Leave conjunctive antecedents in `irUnmappedAxioms`. Add the repro as a linter and IR test.

## Acceptance criteria
- [ ] The repro lints cleanly
- [ ] No bound from a conjunctive antecedent reaches `compConstraints`
- [ ] The unmapped-axiom warning and the IR agree

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "Predicate names starting with a keyword fail to parse (e.g. orderedBy)" "bug,major" <<'BODY'
## Summary
DSL keywords are matched without a word boundary. Any predicate whose name starts with `or`, `and`, `not`, `iff`, `implies`, `forall` or `exists` gives a parse error.

## Description
**Steps to reproduce**
```lisp
(def-concept Order)
(def-relation orderedBy Order Order)
(forall (x) (implies (Order x) (orderedBy x x)))
```
`ontologic-exe -i f.logic -t lint`

**Expected:** parses.
**Actual:** `3:35: unexpected 'd' expecting '('`.

**Evidence:** `src/Parser.hs:143` has `try (symbol "or")`, and `symbol = L.symbol sc` (line 20) does not check for a word boundary. `or` is consumed from `orderedBy`, and the `parens` that follows fails after consuming input, so megaparsec never tries `parsePredicate`. The same happens for names like `origin`, `organizes`, `notifies`, `android` and `existsIn`.

## Why it matters
Relation names are conventionally lowerCamelCase, so this hits ordinary vocabularies. The error message does not explain the cause, and the workaround is renaming domain terms.

## Suggested fix
Suggestion: add `keyword w = lexeme (try (string w <* notFollowedBy (alphaNumChar <|> oneOf "_:-")))` and use it for every DSL keyword, including `def-*`, `import` and `namespace`. Add parser tests for `orderedBy`, `notifies` and `android`.

## Acceptance criteria
- [ ] The repro parses
- [ ] ParserSpec covers predicates prefixed by each keyword

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "Cyclic inheritance hangs REPL :emit/:ir and LSP hover forever" "bug,major" <<'BODY'
## Summary
`getAncestors` has no cycle detection. Compiling a registry that has an inheritance cycle loops forever, which freezes the REPL and the language server.

## Description
**Steps to reproduce**
```lisp
(def-concept A B)
(def-concept B A)
(def-concept C)
(def-property w C Integer)
```
1. REPL: `:load f.logic` (prints "2 lint warnings"), then `:emit python`.
2. LSP: open the file, then hover over `A`.

**Expected:** an error or a lint message.
**Actual:**
- REPL: `:emit python` never returns (killed by `timeout 10`, exit 124). `:ir`, `:solve` and `:unsat` behave the same.
- LSP: the server writes `Content-Length: ` and hangs. Its loop is single-threaded, so every feature stops until restart.

**Evidence:** `src/OntoLogic.hs:187-192` walks parents with no visited set. `isInherited` (`src/IR.hs:119`) runs `elem` over that infinite list, which only terminates if the searched domain is on the cycle. The CLI is safe only because `Main` exits on lint errors; REPL `:load`, REPL input and LSP `updateDoc` keep the registry anyway.

## Why it matters
One typo in the editor kills all language features. REPL users lose their session.

## Suggested fix
Suggestion: make `getAncestors` stop when it revisits a concept, using a `Set`. Optionally skip `compileRegistry` in the REPL and LSP when lint reports a cycle. Add a test that `compileRegistry` terminates on the repro.

## Acceptance criteria
- [ ] `compileRegistry` terminates on cyclic input
- [ ] REPL `:emit` and LSP hover respond for the repro
- [ ] Regression test in IRSpec

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "LSP framing counts chars not bytes; non-ASCII text desyncs the server" "bug,major" <<'BODY'
## Summary
The LSP server treats `Content-Length` as a character count, but the protocol defines it as a UTF-8 byte count. Any non-ASCII text makes the server read or send the wrong amount and lose messages.

## Description
**Steps to reproduce:** send `didOpen` over stdio with text `"; café ⊑ comment\n(def-concept Tank)\n"`, then send a `hover` request.

**Expected:** a diagnostics notification, then a hover response.
**Actual:** no diagnostics until the hover message arrives. The server takes the start of the hover message as the rest of the `didOpen` body, and the hover request is never answered. Reproduced with a Python stdio harness.

**Evidence**
- `src/LSP.hs:57-62`: `readContent` reads `n` `Char`s with `getChar`.
- `src/LSP.hs:68-71`: `sendResponse` writes `length body`, which counts characters. Parse-error diagnostics quote the source line (`errorBundlePretty`), so non-ASCII in that line makes outbound lengths wrong too.

Related, from the code:
- `getLineSafe` throws at EOF.
- `exit` is not handled.
- Unknown requests never get a response.
- JSON with a space after the colon (`"method": "x"`) is ignored. This was seen in the harness.
- [UNVERIFIED] Under `LANG=C`, `getChar` may throw on non-ASCII bytes.

## Why it matters
Every user with a non-ASCII comment or label, including the ⊑ notation the README uses, gets a broken language server and silently dropped requests.

## Suggested fix
Suggestion:
- Use `hSetBinaryMode stdin/stdout True`, read the body with `Data.ByteString.hGet stdin n`, and decode UTF-8.
- Write `BS.length (encodeUtf8 body)` as the length.
- Handle EOF and `exit`.
- Parse JSON with `aeson`, or adopt the `lsp` package.

Add an LSPSpec case with multi-byte content that checks the framing.

## Acceptance criteria
- [ ] Non-ASCII documents open and get diagnostics, and later requests are answered
- [ ] Outbound `Content-Length` equals the UTF-8 byte length
- [ ] The server exits cleanly on EOF or `exit`

_Source: code review (xhigh) of main @ 064530a; reproduced locally with a stdio harness_
BODY

issue "Misspelled or incomplete def-* forms silently parsed as axioms" "bug,major" <<'BODY'
## Summary
A typo such as `(def-concpt X)`, or a `def-property`/`def-relation` missing an argument, parses as a bare predicate axiom. The definition then disappears from every output with no error.

## Description
**Steps to reproduce**
```lisp
(def-concept Tank)
(def-concpt Typo)
(def-property capacity Tank)   ; missing range type
(def-relation ownedBy Tank)    ; missing range
```
`ontologic-exe -i f.logic -t lint`, then REPL `:ir`.

**Expected:** a parse error that names the malformed form.
**Actual:** `✅ Logic Validated successfully.` `:ir` shows `irUnmappedAxioms = [Predicate "def-concpt" [..], Predicate "def-property" [..], Predicate "def-relation" [..]]`.

**Evidence:** `src/Parser.hs:40-49`. Each `def-*` parser is wrapped in `try`, and `IAxiom <$> parseFOL` catches everything else.

## Why it matters
A typo silently removes concepts, fields or relations from every generated artifact. Nothing points at the typo.

## Suggested fix
Suggestion: commit once a `def-*` keyword has matched, so the error names the missing argument. Reject predicate heads that start with `def-` or are reserved words. Optionally, lint that each axiom's predicate head is a declared concept, a declared relation, or a comparison operator. Add parser tests for each malformed form.

## Acceptance criteria
- [ ] Each line in the repro produces a positioned parse error
- [ ] Valid axioms still parse

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "SMT-LIB output invalid for small/large floats and reused relation names" "bug,major" <<'BODY'
## Summary
The SMT emitter writes floats in Haskell `show` format and declares a relation once per `def-relation`. Z3 and cvc5 reject the output for ordinary inputs.

## Description
**Steps to reproduce**
1. `(def-concept Vuln) (def-property epss Vuln Double) (forall (x) (implies (Vuln x) (lt epss 0.001)))`, then `-t smt` and `--solve -p z3`.
2. `(def-concept Engine) (def-concept Car) (def-concept Wheel) (def-relation partOf Engine Car) (def-relation partOf Wheel Car)`, then `--solve -p z3`.

**Expected:** valid SMT-LIB and a SAT result.
**Actual:**
1. Emits `(assert (< (Vuln_epss Vuln) 1.0e-3))`. Z3 reports `unknown constant e-3`; cvc5 reports `Symbol 'e-3' not declared`. Values of 1e7 and above are printed the same way.
2. Emits `(declare-fun partOf ...)` twice, and the solver fails with a duplicate declaration. The linter allows this input because its duplicate key is (name, domain, range).

**Evidence**
- `valueToString` (`src/OntoLogic.hs:90`) is used by `emitPropertyAssertion` in both `src/Solver.hs:259-272` and `src/Emitters/SMT.hs:56-69`.
- `emitRelationDeclaration` is at `src/Solver.hs:274-280` and `src/Emitters/SMT.hs:71-78`.
- `Solver.hs` duplicates the whole SMT emitter line for line.

## Why it matters
Probability and score bounds, such as EPSS in `stix_cve.logic`, and any relation shared across domains cannot be checked. This also triggers the misleading error reporting described in the ":unsat reports success on solver failure" issue.

## Suggested fix
Suggestion:
- Print SMT reals as plain decimals (`showFFloat Nothing`, or `Data.Scientific`).
- Declare each relation name once and assert one fact per domain/range pair.
- Make `Solver.hs` call `Emitters.SMT` so the fix is made in one place.

Tests: emit both repros and run `z3 -in` on the output.

## Acceptance criteria
- [ ] Both repros produce SMT that z3 and cvc5 accept
- [ ] `Solver.hs` reuses `Emitters.SMT` instead of a copy
- [ ] SMTSpec covers a decimal like 0.001 and a reused relation name

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "Go/Rust/Python output fails to compile; Zod drops inherited bounds" "bug,major" <<'BODY'
## Summary
Generated models do not compile or import for three common ontology shapes: pure taxonomies (Go), three-level hierarchies (Rust) and relations (Python). The TypeScript/Zod output compiles but silently drops constraints.

## Description
**Steps to reproduce**
1. `ontologic-exe -i ontologic-lib/bfo_2020.logic -t go -o out`, then `go vet out/models.go`.
2. With `Vessel ⊃ Tank ⊃ FuelTank`, `(def-property capacity Vessel Integer)`, a `FuelTank` bound `(gt capacity 100)`, `(def-relation ownedBy Vessel Person)` and `(def-relation manages Person Person)`, emit `-t rust`, `-t python` and `-t ts`.

**Actual**
- **Go:** `"fmt" imported and not used`. `src/Emitters/Go.hs:14` always imports fmt, but only constraint checks use it.
- **Rust:** `error[E0609]: no field capacity on type Tank` (rustc). `src/Emitters/Rust.hs:59-61` always reads `self.base.<field>`, which is wrong when the property is declared on a grandparent.
- **Python:** `ownedBy: Person` appears before `Person` is defined, and `manages: Person` appears inside `Person`. On Python 3.10, a plain class with this shape raises `NameError: name 'Person' is not defined` (checked). [UNVERIFIED with pydantic installed.] 3.14 works because annotations are evaluated lazily. CI uses 3.11. `Optional, List` are imported but unused.
- **TypeScript:** `FuelTankSchema = TankSchema.extend({})`. `src/Emitters/TypeScript.hs:19` filters out inherited properties that carry constraints, so `capacity > 100` is never enforced. Java, Python, JSON Schema and OpenAPI keep it.

## Why it matters
The README promises compilable, validating models for every target. These failures hit the most common shapes, so users hit them on their first real ontology.

## Suggested fix
Suggestion:
- **Go:** emit `import "fmt"` only when it is used.
- **Rust:** use `compOriginClass` to walk up to the class that declares the property and emit one `.base` per level.
- **Python:** add `from __future__ import annotations` and call `Model.model_rebuild()` for each class at the end of the file.
- **TypeScript:** emit inherited constrained properties in `.extend({...})`.

Add tests that compile the output: `go vet`, `rustc --crate-type lib`, `python -c 'import models'`, `tsc --noEmit`.

## Acceptance criteria
- [ ] bfo_2020 Go output passes `go vet`
- [ ] The Rust output for the three-level repro compiles
- [ ] The Python output imports on 3.11 with pydantic v2
- [ ] Zod enforces the subclass bound
- [ ] Compile or import checks run in CI

_Source: code review (xhigh) of main @ 064530a; reproduced locally (go vet, rustc, python3.10)_
BODY

issue "Neo4j/Mermaid/D2/GraphQL/OpenAPI output unloadable for stdlib ontologies" "bug,major" <<'BODY'
## Summary
The graph, diagram and API-schema emitters produce output their tools reject, especially for the namespaced names (`bfo:`, `sys:` and so on) the standard library uses.

## Description
**Steps to reproduce:** emit `-t neo4j`, `-t mermaid`, `-t d2` and `-t graphql` for `ontologic-lib/ecosystem.logic`, and `-t neo4j` for any file with two or more concepts.

**Actual**
- **Neo4j** (`src/Emitters/Neo4j.hs:16-35`):
  - Every block reuses the variables `n`, `p`, `s` and `t`, with no `;` until the first `CREATE CONSTRAINT`. The whole nodes-and-relationships section, plus the first constraint, is therefore one statement. [UNVERIFIED against a Neo4j instance; Cypher does not allow re-binding `n` in `MERGE`, and schema and data commands cannot share a statement.]
  - Namespaced labels are not backticked, so `FOR (n:bfo:Entity)` reads as two labels.
  - The checked-in `examples/*.cypher` files no longer match the emitter's output.
- **Mermaid / D2** (`src/Emitters/Mermaid.hs:15-28`, `src/Emitters/D2.hs:16-30`): identifiers are emitted raw, e.g. `class sys:InformationArtifact` (seen in output). `:` is not valid in a Mermaid class id and is D2's key separator. [UNVERIFIED with mmdc/d2 installed.] `sanitizeIdent` exists for exactly this, but neither emitter calls it.
- **GraphQL** (`src/Emitters/GraphQL.hs:39-43`):
  - Query fields are named `map toLower cName ++ "s"`. `ecosystem.logic` has `sys:Cost`/`sys:cost` and `sys:Status`/`sys:status`, so the output contains `sys_costs` and `sys_statuss` twice each (seen in output), which makes the SDL invalid.
  - Subclass types do not get their parent's fields.
- **OpenAPI** (`src/Emitters/OpenApi.hs:28-32`): a root concept with no properties emits `properties:` with no value, which YAML reads as null. That is not a valid JSON Schema `properties` object. [UNVERIFIED with a validator.]

## Why it matters
These are the advertised graph, visual and API targets, and the standard library (BFO, CCO, ecosystem) is what users feed them first.

## Suggested fix
Suggestion:
- **Neo4j:** end each MERGE group with `;`, or use `UNWIND`. Backtick labels and keys.
- **Mermaid:** emit `class sys_Foo["sys:Foo"]`. **D2:** quote keys.
- **GraphQL:** disambiguate names that collide, and emit parent fields or interfaces.
- **OpenAPI:** emit `properties: {}`.

Validate the output in tests: cypher-shell `EXPLAIN`, mmdc/d2 parsing, graphql-js `buildSchema`, and an OpenAPI linter.

## Acceptance criteria
- [ ] Neo4j output for a multi-concept file runs in cypher-shell
- [ ] Mermaid and D2 output for bfo_2020 renders
- [ ] GraphQL SDL for ecosystem.logic builds
- [ ] OpenAPI output validates

_Source: code review (xhigh) of main @ 064530a; output inspected locally_
BODY

issue "LSP flags valid stdlib imports as undeclared; all diagnostics on line 0" "bug,major" <<'BODY'
## Summary
The language server lints each buffer without resolving its imports. Any file that uses the standard library shows false errors, and every diagnostic is placed on line 0.

## Description
**Steps to reproduce:** open a file containing `(import "bfo_2020.logic")` and `(def-concept Pump bfo:Process)`.

**Expected:** no diagnostics. The CLI (`-t lint`) passes this file when run from the repo root.
**Actual:** `Undeclared parent concept: bfo:Process referenced by Pump`, at line 0, character 0 (confirmed over stdio).

**Evidence** (`src/LSP.hs`):
- `updateDoc` (lines 142-160) parses the buffer with `parseRegistry` and never calls the Loader.
- The parse-error position is hard-coded to `(0,0)`, and `makeLintDiag` always uses line 0.
- `findDefinitionLine` (lines 218-223) searches only the current buffer, using a substring match, so `Tank` can jump to `(def-concept TankTruck`.

## Why it matters
Every example, `ontology/component.logic` and `ecosystem.logic` show red errors. Users learn to ignore diagnostics, and completion and hover miss every imported symbol.

## Suggested fix
Suggestion:
- Resolve imports through `Loader`, relative to the document's path plus the stdlib paths, and lint the merged registry. Report only diagnostics that belong to the open document.
- Take positions from the `ParseErrorBundle` (`reachOffset`).
- Store source positions on parsed items.
- Match whole identifiers when looking up definitions.

Add LSPSpec cases for an importing document and a parse-error position.

## Acceptance criteria
- [ ] The repro yields no diagnostics
- [ ] Parse and lint diagnostics point at the right line and column
- [ ] Go-to-definition resolves whole identifiers, including imported ones

_Source: code review (xhigh) of main @ 064530a; reproduced locally with a stdio harness_
BODY

issue "VS Code SMT commands shell-inject file paths/settings; wrong CLI path" "security,major" <<'BODY'
## Summary
The extension builds shell command strings from the file path and a workspace setting. It also derives a CLI binary name that stack builds do not produce.

## Description
**Evidence**
- `editors/vscode/src/extension.ts:55`: ``cp.exec(`"${cliPath}" -i "${filePath}" -t solve --prover=${prover}`)``
- `editors/vscode/src/extension.ts:85`: ``cp.exec(`printf ":load ${filePath}\\n:unsat\\n:quit\\n" | "${cliPath}" --repl`)``

Consequences:
- A `.logic` file whose name contains `$(...)` or `"` runs shell code when either command is used. A `%` in the path breaks the `printf` form. [UNVERIFIED: not executed; follows from the code.]
- `ontologic.solver.prover` is inserted into the command unquoted. A value like `auto; <cmd>` in `.vscode/settings.json` runs `<cmd>`. [UNVERIFIED that VS Code passes non-enum values through unchanged.]
- `ontologic.lsp.path` has no `scope`, and the manifest does not declare `capabilities.untrustedWorkspaces`.
- `cliPath = lspPath.replace(/ontologic-lsp$/, 'ontologic')`, but `package.yaml` builds the CLI as `ontologic-exe`. Only the release tarball renames it. The stack candidate `.stack-work/install/x86_64-linux/bin` does not exist; the local build installed to `.stack-work/install/x86_64-linux-tinfo6/<hash>/9.4.8/bin`.
- A zero exit is shown as "Satisfiable & Consistent", including `Unknown` results.

## Why it matters
Opening a repository with crafted file names or settings and running an OntoLogic command can execute arbitrary code. Separately, both SMT commands fail for developers using the documented `stack` workflow.

## Suggested fix
Suggestion:
- Use `cp.execFile(cli, ['-i', filePath, '-t', 'solve', '--prover', prover])` and check `prover` against the allowed values.
- Run the REPL with `execFile` and write commands to stdin, or add a `--unsat` CLI flag.
- Set `"scope": "machine"` on the binary-path settings and declare `untrustedWorkspaces`.
- Add an `ontologic.cli.path` setting with fallbacks `ontologic` then `ontologic-exe`.
- Treat only an explicit SAT result as success.

## Acceptance criteria
- [ ] No `cp.exec` with interpolated strings remains
- [ ] A file named `a$(touch x).logic` does not create `x`
- [ ] The SMT commands work with a `stack build` checkout

_Source: code review (xhigh) of main @ 064530a; static analysis of extension.ts_
BODY

issue "Stdlib imports fail unless ontologic runs from the repo root" "bug,major" <<'BODY'
## Summary
The loader looks for `ontologic-lib/` in the current working directory, so standard-library imports fail from any other directory.

## Description
**Steps to reproduce**
1. Create `pump.logic` containing `(import "bfo_2020.logic")` and `(def-concept Pump bfo:Process)`, outside the repo.
2. From that directory, run `ontologic-exe -i pump.logic -t lint`.
3. From the repo root, run the same command with the file's absolute path.

**Expected:** both resolve the import.
**Actual:** step 2 prints `Import not found: bfo_2020.logic` (exit 1). Step 3 passes.

**Evidence:** `src/Loader.hs:21-22`: `doesDirectoryExist "ontologic-lib"` checks the current directory, which is also always a search path, so a file with the same name there can shadow a stdlib file. HOW_TO_USE installs only the binary into `/usr/local/bin`.

## Why it matters
"Automatic standard library lookup" only works inside the source checkout. Installed users, REPL `:load` from other directories, and the VS Code commands all fail on the first import.

## Suggested fix
Suggestion: search, in order:
1. the importing file's directory
2. `$ONTOLOGIC_PATH`
3. a `--lib-path` flag
4. `<exe dir>/../ontologic-lib` (via `getExecutablePath`)
5. the cabal data dir (`data-files: ontologic-lib/*.logic` plus `Paths_ontologic.getDataDir`)

Add a loader test that runs from a temporary directory.

## Acceptance criteria
- [ ] The repro resolves from any working directory with the release layout
- [ ] Stdlib location is configurable
- [ ] The current directory no longer shadows imports implicitly

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "capabilities.json and ontology/ bindings from 064530a are broken" "bug,minor" <<'BODY'
## Summary
The capability manifest and component ontology added in 064530a name a nonexistent Python entrypoint and test command, import a missing file, and contradict each other.

## Description
- **`docs/capabilities.json`** declares `"entrypoints": {"python": "OntoLogic.core"}` and `"test_command": "pytest test/ -q"`. There is no Python package, and `test/` is Hspec, so `pytest test/ -q` prints `no tests ran` and exits 5 (checked).
- **`ontology/component.logic:6`** imports `"factory_domain.logic"`, which is not in the repo or the stdlib. `ontologic-exe -i ontology/component.logic -t lint` fails with `Import not found: factory_domain.logic`.
- **The .logic and .ttl files disagree.**
  - `component.logic` declares `OntoLogicNode` as a subclass of `dsf:SoftwareFactory`, under `http://bsommers.github.io/OntoLogic/ontology#`.
  - `component_schema.ttl` declares it as an individual (`a dsf:SoftwareFactory`), under `http://bsommers.github.io/OntoLogic/`.
  - The two IRIs differ, and so does the kind of thing declared.
- **`.ontology/` (from abc7c46) and `ontology/` both hold bindings.**
  - `.ontology/bfo_binding.cql` uses `CREATE`, which duplicates nodes on every re-run.
  - `.ontology/domain_schema.ttl` uses the prefix `bfo: <http://purl.obolibrary.org/obo/bfo.owl#>`, which does not match BFO's `BFO_nnnnnnn` IRIs.
  - `ontology/bfo_binding.cql` MERGEs on the full property map, so changing `poset_tier` creates a second node.
- [UNVERIFIED] `"stratum": 50` may be meant to match `poset_tier: 20`.

## Why it matters
Capability reconcilers and graph loaders will trust this metadata. The repo's own compiler cannot load its own component ontology.

## Suggested fix
Suggestion:
- Set the entrypoints to `ontologic-exe` and `ontologic-lsp`, and the test command to `stack test`.
- Vendor `factory_domain.logic` or drop the import.
- Choose one IRI base and one modelling choice (class or individual) for both files.
- Remove `.ontology/` or merge it into `ontology/`.
- Use `MERGE (r:Repository {id: 'repo://OntoLogic'}) SET r += {...}`.

## Acceptance criteria
- [ ] The manifest's test command runs the real suite
- [ ] `ontology/component.logic` lints
- [ ] One binding directory, with matching IRIs in the .logic and .ttl files

_Source: code review (xhigh) of main @ 064530a; checked locally_
BODY

issue "--solve exits 0 when the solver returns unknown" "bug,major" <<'BODY'
## Summary
`ontologic-exe --solve` (and `-t solve`) prints a warning but exits 0 when the solver answers `unknown`, so CI and scripts treat an undecided check as a pass.

## Description
In `src/Main.hs:94` (`runSolverCheck`), `Sat` exits 0, while `Unsat` and `SolverError` call `exitFailure`. `Unknown out` only prints `⚠️  SMT Solver Result: ...` and falls through to exit 0.

**Steps to reproduce**
1. Give the solver a query it can't decide, e.g. nonlinear arithmetic that makes z3 answer `unknown`, or run with a timeout.
2. `ontologic-exe -i f.logic --solve; echo $?`

**Expected:** a non-zero exit, preferably one distinct from UNSAT.
**Actual:** exit 0. Confirmed from the code; not run with an input that makes z3 answer `unknown`.

## Why it matters
`--solve` is the consistency gate. Anyone using it in CI or a pre-commit hook gets a green result when nothing was proved, so inconsistent ontologies can merge without anyone noticing.

## Suggested fix
Suggestion: in the `Unknown` branch, call `exitWith (ExitFailure 2)` or similar, and document the codes (0 = SAT, 1 = UNSAT/error, 2 = unknown). Add an Hspec or golden test that stubs the solver result and asserts the exit code.

## Acceptance criteria
- [ ] `Unknown` yields a documented non-zero exit code
- [ ] A test covers the exit code for each `SolverResult` constructor

_Source: code review (xhigh) of main @ 064530a; confirmed in src/Main.hs_
BODY

issue "REPL crashes with hGetLine: end of file on Ctrl-D or piped input" "bug,minor" <<'BODY'
## Summary
The REPL loop calls `getLine` without checking for EOF, so Ctrl-D or the end of piped input crashes it with an uncaught exception.

## Description
**Steps to reproduce**
`printf ':help\n' | stack exec ontologic-exe -- --repl`

**Expected:** the REPL exits cleanly (e.g. prints `Goodbye!`) with status 0.
**Actual:** after the output, `ontologic-exe: <stdin>: hGetLine: end of file` (reproduced locally), and the process ends through an uncaught IOException.

Cause: `src/REPL.hs:56`, where `line <- getLine` runs with no `isEOF` check.

## Why it matters
Ctrl-D is the normal way to leave a terminal REPL, and piping a script of commands into `--repl` is a natural way to automate it. Both end in a scary error message and a failure exit status.

## Suggested fix
Suggestion: check `isEOF` before `getLine` and treat EOF like `:quit`, or switch to `haskeline`, which also gives history and line editing. Add a test that pipes a finite command list into the REPL and asserts a clean exit.

## Acceptance criteria
- [ ] Piped input ending without `:quit` exits 0 with no exception text
- [ ] Ctrl-D in an interactive session exits cleanly

_Source: code review (xhigh) of main @ 064530a; reproduced locally_
BODY

issue "Make Acme namespace and Java package configurable in OWL/SHACL/Java" "enhancement,minor" <<'BODY'
## Summary
Generated OWL, SHACL and Java output hard-codes a Acme-specific namespace and package, whatever the ontology's own `namespace` declarations say.

## Description
Current behavior:
- `src/Emitters/Owl.hs:16-24`: `xmlns`, `xml:base` and `owl:Ontology rdf:about` are fixed to `http://www.acme.com/ontologies/fleet`.
- `src/Emitters/Shacl.hs:22`: `@prefix ont: <http://www.acme.com/ontologies/fleet#>`.
- `src/Emitters/Java.hs:8` and `src/Main.hs:105`: the Java package defaults to `com.acme.generated` (`--java-package` overrides it only on the CLI; the REPL `:emit java` can't).

So an ontology that declares `(namespace sys "http://bsommers.github.io/ecosystem")` produces OWL and SHACL claiming its classes live under acme.com.

## Why it matters
The IRIs in the output are wrong for every user who isn't that one project. Loading the OWL/SHACL next to other data mints identifiers in a domain the user doesn't control, and two unrelated ontologies collide under the same base IRI.

## Suggested fix
Suggestion:
- Derive the base IRI from the registry's first/default `namespace` declaration.
- Add a `--base-iri` CLI flag (and a REPL setting) as an override.
- Use a neutral default such as `http://example.org/ontologic#` and `ontologic.generated`.
- Add golden tests asserting that the output IRIs follow the declared namespace.

## Acceptance criteria
- [ ] OWL/SHACL base IRIs come from the ontology's namespace or a flag
- [ ] No `acme` string remains in `src/`
- [ ] The REPL can set the Java package

_Source: code review (xhigh) of main @ 064530a; confirmed by grep_
BODY

issue "Deduplicate registry helpers and share one emit-target table" "refactor,minor" <<'BODY'
## Summary
`mergeRegistries`/`emptyRegistry` are defined in three places, and the CLI and REPL keep separate, already diverging lists of emit targets.

## Description
- `emptyRegistry` is defined in `src/Parser.hs:172` and `src/Loader.hs:106`.
- `mergeRegistries` is defined in `src/Loader.hs:96` and `src/REPL.hs:195`.
- Emit targets are dispatched separately in `src/Main.hs` (`processTarget`, from line 97) and `src/REPL.hs:159-179` (`:emit`). The aliases differ (the REPL accepts `golang`, `gql`, `smtlib`, `zod`, `json`), and targets listed in the CLI help such as `mermaid` and `d2` aren't available from the REPL.

## Why it matters
Any new `Registry` field has to be added to every copy. Missing one silently drops data in only one of the paths (loader vs REPL). New targets land in the CLI but not the REPL, and users see inconsistent behavior between the two front ends.

## Suggested fix
Suggestion:
- Move `emptyRegistry`, `mergeRegistries` and `deduplicateRegistry` into one module (e.g. `OntoLogic` or a new `Registry` module) and import it everywhere. Deriving `Semigroup`/`Monoid` for `Registry` would do the job neatly.
- Define a single `targets :: [(String, [String], Registry -> Output)]` table (name, aliases, emitter) and use it for CLI dispatch, REPL `:emit`, and the `--target` help text.
- Add a test asserting that every target in the table works from both the CLI and the REPL.

## Acceptance criteria
- [ ] One definition each of `emptyRegistry` and `mergeRegistries`
- [ ] The CLI and REPL accept the same targets and aliases
- [ ] The `--target` help text comes from the table

_Source: code review (xhigh) of main @ 064530a; confirmed by grep_
BODY

issue "ecosystem.logic models code symbols as classes; commit count is wrong" "bug,minor" <<'BODY'
## Summary
The generated `ontologic-lib/ecosystem.logic` declares every harvested code symbol as a subclass (`def-concept`), puts every repo under one `sys:` namespace, and has 910 symbols, not the 1009 the commit message claims.

## Description
- The file (from 6e97354, "harvest 1009 cross-ecosystem AST symbols") has 914 `def-concept` forms: 4 bridge classes plus 910 symbols, e.g. `(def-concept sys:registerPlugin sys:CodeSymbol)`.
- Each function or method name is modelled as a **class** under `sys:CodeSymbol`. In BFO terms a particular symbol is an instance of an information artifact, not a universal. So the OWL/SHACL/GraphQL output yields hundreds of meaningless types (see the GraphQL name-collision issue: `sys_costs`/`sys_statuss`).
- Every repo's symbols share the `sys:` namespace, and the source repo only survives as a `;; From uitoolbox` comment. Same-named symbols from different repos collapse into one concept.
- The 1009 vs 910 difference is unexplained; it may be deduplication or dropped symbols. [UNVERIFIED] which.

## Why it matters
Anything downstream (graph loads, reasoning, generated code) inherits the wrong modelling, and the collapsed names lose provenance. The commit message's count can't be reproduced from the file.

## Suggested fix
Suggestion:
- Emit symbols as individuals/instances (or as relation facts like `(definedIn registerPlugin uitoolbox)`) rather than `def-concept`.
- Qualify identifiers per repo (e.g. `sys:uitoolbox/registerPlugin`) or add a per-repo namespace.
- Make the harvester print how many symbols it harvested, deduplicated and dropped, and add a test that counts the generated forms.
- Correct the count in `docs/` and in future commit messages.

## Acceptance criteria
- [ ] Code symbols are not declared as classes
- [ ] Each symbol records its source repo in data, not only in a comment
- [ ] The harvester's reported count matches the generated file

_Source: code review (xhigh) of main @ 064530a; count checked with grep_
BODY

}

# ---- Run ----
if [[ $MODE == file ]]; then
  MODE=collect; all_issues
  check_labels
  MODE=file
fi
all_issues
