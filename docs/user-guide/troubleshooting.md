# Troubleshooting

This page maps messages and surprising results to causes and fixes. Messages are quoted exactly as OntoLogic prints them; paths are shortened. When in doubt, run `-t lint` first: it is fast, and every other mode starts with it.

## Parse and load errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Parse error in FILE:` followed by a caret excerpt | Syntax error | Look at the line and column; the `expecting` list says what the parser wanted |
| `unexpected '"'` / `expecting '_' or letter` on a `namespace` line | Quoted prefix, as in `(namespace "bfo" "...")` | Use a bare prefix: `(namespace bfo "http://...")` |
| `unexpected ':'` / `expecting ')'` in a `def-property` | Unknown or invalid option, for example `:cardinality 2..3` | Cardinalities are `1..1`, `0..1`, `0..*`, `1..*` (and `1`, `optional`, `*`, `0..n`, `1..n`). |
| `unexpected end of input, expecting ')'` | Unbalanced parentheses | Check the last form; an editor with bracket matching helps |
| `unknown form 'def-foo'` | A `def-` word the parser does not know | The declarations are `def-concept`, `def-property`, `def-relation`, `def-individual`, `def-axiom` |
| `File not found: x.logic` | Wrong `-i` path | Check the working directory |
| `Import not found: x.logic` | Import not on the search path | Add `--lib-path DIR` or `$ONTOLOGIC_PATH`, or fix the name; see [Language reference](language-reference.md#imports-and-search-path) |
| `Circular import dependency detected: a -> b -> a` | Two files import each other | Move shared definitions to a third file both import |
| `Error: --input is required (or use --repl / --lsp)` | No `-i` | Pass `-i FILE` |
| `Error: --output is required for target: ts` | Emitter without `-o` | Pass `-o DIR` |
| `Unknown target: foo` | Misspelled target | See the list in `--help` or the [CLI reference](cli-reference.md#targets) |
| `option -T: expected a positive integer, got '0'` | Zero or negative limit | Use a value of 1 or more |

## Lint errors

All have the form `file:line:col: error: message` and make the run exit 1.

| Message | Meaning and fix |
|---------|-----------------|
| `Undeclared parent concept: B referenced by A` | `A`'s parent is not declared. Declare it or fix the name. For library concepts include the prefix: `bfo:MaterialEntity` |
| `Undeclared domain concept: X in property p` | The property's domain concept is missing |
| `Undeclared domain/range concept: X in relation r` | A relation endpoint is missing |
| `Duplicate concept definition: A` | Two differing definitions of one concept (identical repeats are merged silently) |
| `Circular inheritance: ["A","B","A"]` | The parent chain loops |
| `Property contradiction on p: gt 5 and lt 3` | One axiom demands incompatible bounds |
| `Cross-axiom contradiction on C.p: ...` | Axioms (including inherited ones) on a concept's property conflict |
| `Semantic contradiction: Concept H implies both T and C, but T is disjoint with C.` | A subclass of two disjoint concepts. Remove one parent or the disjointness axiom |
| `Axiom contradiction: bottom (false) asserted.` | An axiom reduces to `bottom` |
| `Semantic contradiction: Global axioms derive unsatisfiable conflict: A, B.` | The axioms force these concepts to be empty |

Contradictions can be reported twice (once per operand order); fix the first and the pair disappears.

## Solver messages

| Output | Meaning |
|--------|---------|
| `⚠️ N axiom(s) were not sent to the solver` | Those axioms could not be translated (reason in parentheses). The verdict covers the rest. See [Axioms and reasoning](axioms-and-reasoning.md#axioms-that-are-not-sent) |
| `ℹ️ ... --free-constants` | You enabled free-constants mode; undeclared names are treated as constants |
| `SMT Solver Result (unknown): ...` | Exit 2. Timeout or the solver gave up. Raise `-T`, try another `-p`, or simplify the ontology |
| `SMT Solver Error: Failed to execute Z3 solver: ... Ensure 'z3' is installed and available in PATH.` | You asked for a specific prover (`-p z3`) that is not installed. Install it, or use `-p auto`/`-p native` |
| `Unknown prover 'x'. Valid options: z3, cvc5, vampire, native, auto` | Bad `-p` value |
| `⚠️ --solve-memory is not supported by CVC5 and is ignored.` | Memory limits apply to Z3 only |
| `Concept coherence check could not run: ...` | Exit 2; the second solver step failed. Usually the same cause as an adjacent solver error |
| `Native resolution prover timed out / step limit / clause limit exceeded` | The built-in prover gave up (reported as unknown). Use `z3` or `cvc5` |

### SAT from one prover, UNSAT from another

The native prover and Vampire have no arithmetic. They are told which pairs of numeric bounds in the file exclude each other, so a plain conflict (a universal `gte 100` and an existential witness with `lt 50`) is UNSAT on every backend. A contradiction that needs real arithmetic, such as an integer gap (`gt 5` and `lt 6` on an `Integer`), is UNSAT under `-p z3` or `-p cvc5` and can look SAT under `-p native` or `-p vampire`. Prefer Z3 or CVC5 whenever properties have numeric bounds.

### Auto picked the native prover

`--prover auto` falls back to the native prover only when none of `z3`, `cvc5`, `vampire` is on `PATH`. Check with `which z3 cvc5 vampire`. Solvers installed through sandboxed packages (snap, flatpak) may not be visible or may not read your files.

### "Satisfiable" but a constraint is missing at runtime

`--solve` reasons about the logic, not about generated code. Cardinality, `:optional`, and `:default` are not part of the solver's theory; axioms that are not field-shaped are reported as unmapped by emitters. See [Targets and emitters](targets-and-emitters.md#unmapped-axioms).

## Emitter issues

| Symptom | Cause and fix |
|---------|---------------|
| `⚠️ Warning: N complex / conditional axiom(s) could not be mapped...` | Expected for disjointness, existential, and relational axioms. Enforce them elsewhere or ignore |
| No warning for `owl`, `shacl`, `smt`, `neo4j`, ... | They do not warn by default; add `--warn-unmapped` |
| Output file overwritten | File names are fixed per target; use a separate `-o` directory per ontology |
| `mmdc ... not found or failed` / `d2 CLI not found or failed` | Install the renderer or drop `--render`; see [Visualization](visualization.md) |

## REPL and editor

| Symptom | Fix |
|---------|-----|
| REPL form spans several lines and fails | Each REPL line is parsed on its own; put the whole form on one line |
| Editor shows no diagnostics | Check the "OntoLogic" output channel; run "OntoLogic: Restart Language Server"; make sure `ontologic-lsp` is found (set `ontologic.lsp.path`) |
| Editor reports undeclared library concepts | `ONTOLOGIC_PATH` must be set in the environment the editor was launched from |
| Snippet expands to code that does not parse | The concept and axiom snippets use an older syntax; see [Editor and LSP](editor-and-lsp.md) |

## Getting more detail

- `--cnf` shows how axioms were understood.
- `--inspect-model` shows a witness world; `--explain-unsat` shows the conflicting axioms.
- `-t smt -o DIR` or `-t tptp -o DIR` writes the problem so you can run `z3`, `cvc5`, or `vampire` yourself.
- See [FAQ](faq.md) for conceptual questions.

Next: [FAQ](faq.md)
