# Changelog

All notable changes to the "ontologic" extension will be documented in this file.

## [1.8.4] - 2026-11-15

### Changed
- Version aligned with the OntoLogic compiler (1.8.4); `package.json`, the lock file and this changelog now agree.
- TextMate grammar rewritten against the real parser: highlights `def-property`, `def-individual`, `def-axiom`, `namespace`, `if`, `ne`, `true`/`false`/`top`/`bottom`, the `:cardinality`, `:optional` and `:default` options, and the `//`, `/* */` and `#| |#` comment forms. Removed forms the language does not have (`axiom`, `subclass-of`, `neq`, `between`, `in`, `=>`, `<=>`, `DateTime`, `Decimal`, `URI`).
- The `import` snippet now inserts a bare library name (`bfo_2020.logic`) that resolves on the search path.
- README: working install steps, build step, and an accurate feature list.

### Notes since 1.0.0
- Go to definition follows imports; rename, document formatting, semantic tokens and the explain/inspect/restart commands were added; the `ontologic.cli.path` setting selects the CLI used by the check commands.

## [1.0.0] - 2026-09-13

### Initial Release
- TextMate syntax grammar for OntoLogic DSL (`.logic`).
- Stdio Language Server Protocol (LSP) client connecting to `ontologic-lsp`.
- Real-time diagnostic reporting for Megaparsec syntax and Linter semantic errors.
- Document symbol completion, hover tooltips, and jump-to-definition.
- Code snippets for ontology declarations and first-order logic axioms.
- Direct command palette actions for SMT consistency checking and concept satisfiability verification.
