# Language reference

A `.logic` file is a sequence of parenthesized top-level forms in an S-expression syntax. This page lists every form the parser accepts, what it means, and a small example, then explains imports and how the search path is built. The authoritative source is `src/Parser.hs`.

## Lexical rules

| Item | Rule |
|------|------|
| Line comments | `;` or `//` to end of line |
| Block comments | `/* ... */` or `#| ... |#` |
| Identifiers | start with a letter or `_`, then letters, digits, and any of `_ : - . / + * '`. So `bfo:Entity`, `max-load`, and `ns.Thing` are single identifiers |
| Operator symbols | runs of `+ * / < > = ! & \| ' ~` (for example `!=` and `=`) |
| Strings | double quoted, with the usual escapes |
| Numbers | integers and decimals, optionally signed (`-3`, `0.5`) |
| Booleans | `True`, `False`, `true`, `false` |

Whitespace and comments may appear between any tokens. Source positions in diagnostics are 1-based `line:col`.

Comments directly above a `def-concept` or `def-property` (consecutive `;` lines with no blank line between) become the hover documentation in the editor (see [Editor and LSP](editor-and-lsp.md)).

## Declarations

### `def-concept`

```lisp
(def-concept Name)
(def-concept Name Parent)
```

Declares a concept (class). With a parent it is a subclass; the parent must be declared somewhere (the linter reports `Undeclared parent concept`). Inheritance cycles are lint errors. Declaring the same concept twice with an identical definition is harmless (identical duplicates are merged, which is what makes diamond imports work), but two definitions that differ, for example with different parents, are reported as `Duplicate concept definition`. The same rule applies to properties and relations.

```lisp
(def-concept Vehicle)
(def-concept Truck Vehicle)
```

### `def-property`

```lisp
(def-property name Domain Type [:cardinality C] [:optional True|False] [:default V])
```

A typed attribute of the domain concept. Types: `Integer`, `Float`, `Double`, `Boolean`, `String`; any other name is a custom type, treated as a reference to another concept (an entity-valued property, which the solver models as a relation).

Options can be given in any order:

| Option | Meaning |
|--------|---------|
| `:cardinality C` | One of `1..1` (or `1`), `0..1` (or `optional`), `0..*` (or `*`, `0..n`), `1..*` (or `1..n`). Anything else is a parse error |
| `:optional True` | Same as `:cardinality 0..1`. `:optional False` is `1..1`. Only `True`/`true`/`False`/`false` are accepted |
| `:default V` | A default value, as a string literal, identifier, or number |

If you give no cardinality, the emitters pick a default (a plain required field for scalars). Cardinality and defaults shape generated code; they are not sent to the solver (see [Axioms and reasoning](axioms-and-reasoning.md)).

```lisp
(def-property vin Vehicle String :cardinality 1..1)
(def-property nickname Driver String :optional True)
(def-property tags Driver String :cardinality 1..*)
(def-property version Vehicle String :default "1.0.0")
```

### `def-relation`

```lisp
(def-relation name Domain Range [MoreConcepts...] [:cardinality C])
```

A relation between concepts. The first two concepts are domain and range; any further concepts extend the signature to an n-ary relation. Cardinality uses the same values as properties.

```lisp
(def-relation drives Driver Vehicle :cardinality 0..*)
```

Domain and range must be declared concepts.

### `def-individual`

```lisp
(def-individual name)
(def-individual name Concept)
```

Declares a named individual (a constant), optionally typed by a concept. Individuals can be used as terms in axioms.

```lisp
(def-individual depot1 Site)
```

### `namespace`

```lisp
(namespace prefix "http://example.org/ns#")
(namespace prefix)
```

Declares a prefix and optionally its IRI. The prefix is a bare identifier, not a quoted string (`(namespace "bfo" "...")` is a parse error). The first declared namespace becomes the default base IRI for the `owl` and `shacl` targets (override with `--base-iri`). Duplicate prefixes are lint errors. Prefixes are conventionally used in concept names (`bfo:Entity`) but a name containing `:` is just an identifier; nothing expands it.

### `import`

```lisp
(import "relative/or/library/file.logic")
```

Loads another `.logic` file and merges its declarations and axioms. See [Imports and search path](#imports-and-search-path).

## Axioms

An axiom is a first-order formula. There are three equivalent ways to state one:

```lisp
(forall (v) (implies (Truck v) (not (Car v))))                 ; bare axiom
(def-axiom (forall (v) (implies (Truck v) (not (Car v)))))      ; def-axiom
(def-axiom "trucks-not-cars" (forall (v) (implies (Truck v) (not (Car v)))))  ; with a label
```

The optional label is documentation only.

### Formulas

| Form | Meaning |
|------|---------|
| `(Concept x)` | `x` is an instance of the concept |
| `(relation x y)` | `x` and `y` are related |
| `(pred t1 t2 ...)` | any other predicate application; undeclared predicate names become uninterpreted predicates in the solver |
| `(and P Q ...)` | conjunction (zero arguments is `top`) |
| `(or P Q ...)` | disjunction (zero arguments is `bottom`) |
| `(not P)` | negation |
| `(implies P Q)` or `(if P Q)` | implication |
| `(iff P Q)` | biconditional |
| `(forall (x y ...) P)` | universal quantification over one or more variables |
| `(exists (x y ...) P)` | existential quantification |
| `(forall ((x Concept) ...) P)` | typed binder; mixing plain and typed variables is allowed |
| `(eq a b)` or `(= a b)` | equality |
| `(!= a b)` | disequality |
| `(gt p v)` `(gte p v)` `(lt p v)` `(lte p v)` `(ne p v)` `(eq p v)` | comparison of a property with a value |
| `top`, `true`, `bottom`, `false` | truth and falsity (any capitalization of the first letter) |

Subformulas of connectives must be parenthesized or one of the constants above.

### Terms

A term is a variable (identifier), a constant (string, number, boolean), or a function application `(f t1 t2 ...)`.

### Property comparisons

Comparisons name the property directly, without a variable: `(gte speed 0)`. Inside a quantifier the property is read on the innermost bound variable:

```lisp
(forall (v) (implies (Vehicle v) (and (gte speed 0) (lte speed 130))))
```

Axioms of the shape `forall x. Concept(x) implies <comparisons>` are the ones emitters can turn into field constraints (`@Min`, `Field(ge=...)`, `CHECK (...)`). Everything else (disjointness, existentials, relational rules) is still checked by the solvers, but emitters report it as an unmapped axiom (see [Targets and emitters](targets-and-emitters.md)).

### Common patterns

```lisp
;; Disjointness
(forall (x) (implies (Truck x) (not (Car x))))

;; Every Truck has some Site it serves
(forall ((t Truck)) (exists ((s Site)) (serves t s)))

;; Symmetric relation
(forall (x y) (implies (link x y) (link y x)))

;; Multi-premise rule
(forall (o) (implies (and (Oven o) (eq is_active True)) (gt temperature 100)))
```

## Imports and search path

`(import "name.logic")` is resolved by looking for `name.logic` in these directories, first match wins:

1. The directory of the importing file.
2. Each `--lib-path DIR` given on the command line, in order (the flag is repeatable).
3. Each directory in `$ONTOLOGIC_PATH` (a `:`-separated list on Linux and macOS).
4. `ontologic-lib/` next to the executable's parent (`bin/../ontologic-lib`, the release-tarball layout), then next to the executable.
5. `ontologic-lib/` in the installed package data directory (`stack install`).
6. `./ontologic-lib` in the current directory (running from a source checkout).
7. The current directory, last, so a stray file there cannot shadow a library module.

Only directories that exist are searched. An absolute import path is used as is. Imports are transitive, imported files may import others, and a file imported by several paths is loaded once. A circular import is reported:

```text
Circular import dependency detected: /path/a.logic -> /path/b.logic -> /path/a.logic
```

A missing file is reported as `Import not found: shared.logic` (exit 1). Adding the directory fixes it:

```bash
ontologic-exe -i imp3.logic -t lint --lib-path libx
ONTOLOGIC_PATH=libx ontologic-exe -i imp3.logic -t lint
```

```text
✅ Logic Validated successfully.
✅ Logic Validated successfully.
```

The standard library names are listed in [Standard library](standard-library.md). Note that library concepts carry namespace prefixes, so you write `(def-concept Pump bfo:MaterialEntity)` after `(import "bfo_2020.logic")`.

The REPL's `:load` uses the default search path but has no `--lib-path`; set `ONTOLOGIC_PATH` instead.

## Lint-visible rules at a glance

| Check | Example message |
|-------|-----------------|
| Undeclared parent / domain / range | `Undeclared parent concept: B referenced by A` |
| Duplicates | `Duplicate concept definition: Bus` |
| Circular inheritance | `Circular inheritance: ...` |
| Contradictory bounds | `Property contradiction on methane_level: gt 5 and lt 3` |
| Inherited-bound clash | `Cross-axiom contradiction on GasSensor.methane_level: ...` |
| Disjointness violation | `Semantic contradiction: Concept Hybrid implies both Truck and Car, but Truck is disjoint with Car.` |

Next: [Axioms and reasoning](axioms-and-reasoning.md)
