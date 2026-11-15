# AGENTS.md

## Repository Overview
OntoLogic is a domain-specific language compiler, semantic linter, multi-target emitter, and automated FOL/SMT reasoner for BFO (Basic Formal Ontology) and real-world industrial ontologies. Written in Haskell (GHC 9.4.8). It has 18 output targets; the authoritative list is the `targets` table in `src/Targets.hs`.

## CRITICAL DIRECTIVE: GitHub Actions Conservation (CI is local)
GitHub Actions minutes are strictly limited, so the full build-and-test gate is a local gate and does not run on GitHub automatically. On GitHub only two things run by themselves: the `docs` check (`.github/workflows/docs.yml`, a relative-link check via `python3 -I scripts/check_links.py`, on pull requests and pushes to `main`) and the Pages deployment (`.github/workflows/pages.yml`). The full workflow (`.github/workflows/ci.yml`, Haskell build and test plus Java/Gradle) runs only when started by hand with `workflow_dispatch`. All agents and developers MUST observe:
1. **Local Test Execution First**: NEVER push branches or open PRs without running the full gate locally. Nothing on GitHub will run it for you.
2. **No Intermediate Commits**: Do not push intermediate or broken commits to origin.
3. **Merge Gate**: Never merge pull requests or push branch deletions without explicit user authorization command.
4. **Manual full run**: Start `ci.yml` by hand only when a clean-room run is really needed.

This section is the single list of gates. `CLAUDE.md`, `GEMINI.md`, `docs/dev/README.md` and the installation guide link here instead of repeating it.

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

**Strict local runs.** Locally, tests that need an external toolchain (go, rustc, pydantic, npm, d2, rdflib, Vampire and so on) skip silently when the tool is missing, so a green local run can be weaker than the manual `ci.yml` run. That workflow sets `ONTOLOGIC_REQUIRE_TOOLCHAINS=1`, which turns a missing toolchain into a failure. Set it locally to get the same behaviour:
```bash
ONTOLOGIC_REQUIRE_TOOLCHAINS=1 stack test --ghc-options="-Wall -Werror"
```

**Coverage gate.** `scripts/check_coverage.sh` (74% threshold) is a local gate. It is not enforced automatically on GitHub; the manual `ci.yml` run executes it, and you run it yourself before every push. Also check for unexpected pending examples with `.github/scripts/check_pending.sh` on the saved hspec log.

**Community files.** Contribution rules are in `CONTRIBUTING.md` and vulnerability reporting is in `SECURITY.md` at the repo root (both being added in v1.8.4; see `.planning/STATE.md`).

### Release checklist
1. `CHANGELOG.md` entry; `package.yaml` and `ontologic.cabal` version; `--version` output and VS Code extension version match.
2. `.planning/STATE.md` and `.planning/ROADMAP.md` (history entry) updated; a phase or release summary written.
3. All gates above pass locally; link check (`scripts/check_links.py`) passes.
4. Tag in both repos (the private archive and the public repo).

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
See the module map in [`docs/architecture.md`](docs/architecture.md) (section "Module map"), which is kept current. Other places:
- `examples/`: Reference ontologies and checked-in artifacts (`.logic`, `.cypher`, `.mmd`, `.d2`, `.svg`).
- `test/`: Hspec suites, one per module or target, plus fixtures in `test/fixtures/`.

## Invariants & Contracts
- **BFO Realism**: Separate Information Content Entities (`SoftwareCode`, GDC) from Execution (`SoftwareProcess`, Occurrent). Model trust and permissions as roles (`TrustedRole`, RealizableEntity) rather than objects.
- **Compiler Warnings**: `package.yaml` sets no `-Wall` flags; the warning gate is the `--ghc-options="-Wall -Werror"` argument to `stack test` above (the manual `ci.yml` run uses the same). Avoid partial pattern matches.
- **Artifact Sync**: When modifying `.logic` files, run `./scripts/regenerate_examples.sh` and compile `.d2.svg` via `d2`.
