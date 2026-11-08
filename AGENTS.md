# AGENTS.md

## Repository Overview
OntoLogic is a domain-specific language compiler, semantic linter, multi-target emitter, and automated FOL/SMT reasoner for BFO (Basic Formal Ontology) and real-world industrial ontologies. Written in Haskell (GHC 9.4.8) with multi-target emitters for Java/Jakarta, Python/Pydantic, Rust, Go, TypeScript/Zod, Cypher (Neo4j), OWL, SHACL, SMT-LIB2, D2, and Mermaid.

## CRITICAL DIRECTIVE: GitHub Actions CI Conservation
GitHub Actions CI quota is strictly limited. All agents and developers MUST observe:
1. **Local Test Execution First**: NEVER push branches or open PRs without running full test suites locally.
2. **No Intermediate Commits**: Do not push intermediate or broken commits to origin that trigger remote CI runs.
3. **Merge Gate**: Never merge pull requests or push branch deletions without explicit user authorization command.
4. **Docs Optimization**: Pure documentation, SVG, and markdown changes are ignored by CI (`paths-ignore`).

### Pre-Push Verification Gate
Before pushing any branch or creating a PR, run:
```bash
# 1. Haskell build & test with strict warnings
stack test --ghc-options="-Wall -Werror"

# 2. Test coverage threshold verification (>= 74%)
./scripts/check_coverage.sh

# 3. Java smoke test (if model emitters touched)
./gradlew :models-java:compileJava
```

## Common Commands
```bash
# Build compiler and REPL
stack build

# Run full test suite
stack test

# Run targeted test spec
stack test --ta "-m FOLTheory"
stack test --ta "-m Solver"

# Run compiler CLI on an ontology
stack exec ontologic-exe -- -i examples/mqtt_ecosystem_unified.logic -t solve
stack exec ontologic-exe -- -i examples/bfo_manufacturing.logic -t neo4j -o dist/

# Regenerate checked-in example diagrams and schemas
./scripts/regenerate_examples.sh
```

## Architecture Map
- `src/OntoLogic.hs`: Core AST definitions (`Registry`, `Concept`, `Property`, `Relation`, `Formula`, `Term`).
- `src/Parser.hs`: Megaparsec parser for s-expression syntax (`def-concept`, `def-property`, `def-relation`, axioms).
- `src/Linter.hs`: Semantic validations (circular inheritance, missing domains/ranges, duplicate declarations).
- `src/FOLTheory.hs`: First-Order Logic extraction, quantifier variable binding, and SMT formula translation.
- `src/Solver.hs`: Automated reasoning engine wrapping external SMT solvers (Z3, CVC5, Vampire).
- `src/Emitters/`: Target code and schema generators (`SMT.hs`, `Neo4j.hs`, `Java.hs`, `Python.hs`, etc.).
- `examples/`: Reference ontologies and checked-in artifacts (`.logic`, `.cypher`, `.mmd`, `.d2`, `.svg`).

## Invariants & Contracts
- **BFO Realism**: Separate Information Content Entities (`SoftwareCode`, GDC) from Execution (`SoftwareProcess`, Occurrent). Model trust and permissions as roles (`TrustedRole`, RealizableEntity) rather than objects.
- **Compiler Warnings**: `package.yaml` enforces `-Wall -Werror=incomplete-uni-patterns`. Avoid partial pattern matches.
- **Artifact Sync**: When modifying `.logic` files, run `./scripts/regenerate_examples.sh` and compile `.d2.svg` via `d2`.
