# Milestone 6 Plan: Modular Namespacing & Multi-File Imports

> **Context:** Expands OntoLogic's DSL, parser, linter, and IR to support modular multi-file ontologies (`(import "path/to/file.logic")` and `(namespace "prefix")`), enabling the decomposition of large enterprise ontologies (BFO, CCO, MITRE, NIST AI RMF) into reusable components.
> **Tracking Document:** [`docs/dev/superpowers/REPLAY_PLAYBOOK.md`](../REPLAY_PLAYBOOK.md)

---

## 🎯 Objectives

1. **Import & Namespace Syntax:**
   * Support `(import "path/to/submodel.logic")` declarations in `.logic` files.
   * Support `(namespace "prefix" "http://iri-or-uri")` declarations.
   * Support qualified concept, property, and relation identifiers (e.g. `bfo:Continuant`, `cco:HardwareArtifact`, `uco:IPAddress`).

2. **Dependency Graph & Circular Import Resolver:**
   * Implement a recursive import loader that discovers and resolves transitive dependencies relative to the root file or a library search path (`--lib-path`).
   * Add cycle detection using `Data.Graph` to flag circular import loops (e.g. `A.logic -> B.logic -> A.logic`) with clear compiler error diagnostics.
   * Handle missing files gracefully with clean status code 1 exits.

3. **Symbol Table & Namespace Scoping in Linter:**
   * Verify all qualified and unqualified symbols across the merged AST.
   * Detect symbol collisions and ambiguous cross-namespace references.

4. **Provenance-Aware Model IR (`src/IR.hs`):**
   * Extend `CompiledClass` and `CompiledRelation` to track namespace provenance and qualified names.

5. **Multi-Target Namespace Transpilation:**
   * **W3C OWL:** Emit standard XML namespace prefixes (`xmlns:bfo="..."`, `xmlns:cco="..."`) and qualified `rdf:about` attributes.
   * **Java:** Group classes by package namespace or emit required package imports.
   * **Python:** Emit modular Python module imports.
   * **Neo4j Cypher:** Support namespaced labels (e.g. `:bfo__Continuant` or `:OntologyClass {namespace: 'bfo', name: 'Continuant'}`).
   * **Mermaid & D2:** Render namespace subgraphs/containers.

6. **Comprehensive Unit & Integration Test Suite (`test/ImportSpec.hs`):**
   * Test single import, transitive multi-level imports, diamond dependencies, circular dependency rejection, missing file errors, and qualified symbol resolution.

---

## 🧱 Architectural Specification

### 1. AST Extension in [`src/OntoLogic.hs`](../../../../src/OntoLogic.hs)

```haskell
-- Qualified or unqualified identifier
data Identifier = Ident
    { idNamespace :: Maybe String
    , idName      :: String
    } deriving (Show, Eq, Generic)

instance Hashable Identifier

-- Import declaration
data ImportDecl = ImportDecl
    { importPath :: FilePath
    } deriving (Show, Eq, Generic)

-- Namespace declaration
data NamespaceDecl = NamespaceDecl
    { nsPrefix :: String
    , nsUri    :: Maybe String
    } deriving (Show, Eq, Generic)

-- Extended Registry
data Registry = Registry
    { concepts   :: [(Name, Maybe Name)]
    , axioms     :: [FOL]
    , properties :: [Property]
    , relations  :: [Relation]
    , imports    :: [ImportDecl]
    , namespaces :: [NamespaceDecl]
    } deriving (Show, Eq, Generic)
```

---

### 2. Multi-File Loader & Cycle Detection

```haskell
-- Resolves all transitive imports starting from a root file path
loadRegistryWithImports :: [FilePath] -> FilePath -> IO (Either String Registry)
```

1. **Cycle Detection Algorithm:** Build a directed dependency graph of canonicalized file paths. Run `stronglyConnComp` / `topSort`. If any strongly connected component has $> 1$ node or a self-loop, fail with `"Circular import dependency detected: [A -> B -> A]"`.
2. **Diamond Deduplication:** If `A` imports `B` and `C`, and both import `D`, `D` is parsed and evaluated exactly once.
3. **Symbol Merging:** Merge concept, property, relation, and axiom collections into a single canonical `Registry`.

---

## 📋 Execution Checklist

- [ ] Create branch `feature/modular-imports`.
- [ ] Add `ImportDecl`, `NamespaceDecl`, `imports`, and `namespaces` to `Registry` in [`src/OntoLogic.hs`](../../../../src/OntoLogic.hs).
- [ ] Implement `(import "...")` and `(namespace "...")` parsers in [`src/Parser.hs`](../../../../src/Parser.hs).
- [ ] Implement multi-file import resolver with cycle detection in [`src/Loader.hs`](../../../../src/Loader.hs) / [`src/Parser.hs`](../../../../src/Parser.hs).
- [ ] Update [`src/Linter.hs`](../../../../src/Linter.hs) for multi-namespace symbol table validation.
- [ ] Update `ModelIR` in [`src/IR.hs`](../../../../src/IR.hs) and emitters for namespace support.
- [ ] Add `test/ImportSpec.hs` with full test coverage.
- [ ] Update existing test specs for new `Registry` record fields.
- [ ] Verify with `stack test --ghc-options="-Wall -Werror"` and `./gradlew test`.
- [ ] Open PR, verify CI, and merge.
