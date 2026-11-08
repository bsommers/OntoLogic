# OntoLogic Security, Hardening & Hygiene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address critical security vulnerabilities (shell injection in CLI rendering, Cypher injection in Neo4j emitter), correctness flaws (graceful exits on validation failure and unknown target), build hygiene, configurable Java packaging, and establish automated GitHub Actions CI.

**Architecture:** Replace shell-interpolated execution (`callCommand`) with direct process invocation (`callProcess`), add Cypher string escaping to the Neo4j emitter, parameterize Java package generation with CLI flags, fix CLI exit codes, clean stale build artifacts and unused dependencies, and add a complete CI workflow.

**Tech Stack:** Haskell (GHC 9.4.8, Stack, LTS 21.25, Megaparsec 9.3, Optparse-Applicative, Hspec), Gradle 8.4, GitHub Actions.

## Global Constraints

- Zero compiler warnings under GHC (`-Wall -Werror`).
- Preserve all existing tests without breaking backward compatibility (all 49 current specs must continue to pass).
- No new external Haskell library dependencies beyond existing ones (`process`, `directory`, `filepath`, `containers`, `text`, `megaparsec`, `optparse-applicative`, `hashable`, `base`).
- Work directory: `.worktrees/core-improvements`.
- Keep documentation and central replay playbook updated.

---

### Task 1: Fix Command Injection in CLI Image Rendering (`callCommand` -> `callProcess`)

**Files:**
- Modify: `src/Main.hs:7-9, 98-116`
- Test: `test/MainSpec.hs`

**Interfaces:**
- `renderMermaid :: String -> IO ()`
- `renderD2 :: String -> IO ()`
- Consumes: `System.Process.callProcess` instead of `System.Process.callCommand`

- [ ] **Step 1: Write failing test or inspect CLI rendering logic**
Verify in `src/Main.hs` lines 103 and 112 that `callCommand` executes a shell string.

- [ ] **Step 2: Update `src/Main.hs` to use `callProcess`**
Replace `import System.Process (callCommand)` with `import System.Process (callProcess)`.
Update `renderMermaid`:
```haskell
renderMermaid :: String -> IO ()
renderMermaid src = do
    let svg = src ++ ".svg"
    putStrLn $ "Rendering to " ++ svg ++ " using mmdc..."
    result <- try (callProcess "mmdc" ["-i", src, "-o", svg]) :: IO (Either IOException ())
    case result of
        Left _ -> putStrLn "⚠️  Error: 'mmdc' (Mermaid CLI) not found or failed. Install with 'npm install -g @mermaid-js/mermaid-cli'"
        Right _ -> putStrLn "✅ Rendered SVG successfully."
```
Update `renderD2`:
```haskell
renderD2 :: String -> IO ()
renderD2 src = do
    let svg = src ++ ".svg"
    putStrLn $ "Rendering to " ++ svg ++ " using d2..."
    result <- try (callProcess "d2" [src, svg]) :: IO (Either IOException ())
    case result of
        Left _ -> putStrLn "⚠️  Error: 'd2' CLI not found or failed. Install from https://d2lang.com"
        Right _ -> putStrLn "✅ Rendered SVG successfully."
```

- [ ] **Step 3: Run `stack test`**
Verify compilation with `-Wall -Werror` passes.

- [ ] **Step 4: Commit**
`git commit -m "fix(security): eliminate shell command injection in diagram rendering via callProcess"`

---

### Task 2: Fix CLI Error Handling & Graceful Exit Codes

**Files:**
- Modify: `src/Main.hs:47-54, 96-97`
- Test: `test/MainSpec.hs`

**Interfaces:**
- If linter fails: `mapM_ putStrLn errors >> exitFailure` (no unhandled Haskell `error` exception).
- If unknown target: `putStrLn ("Unknown target: " ++ t) >> exitFailure`.

- [ ] **Step 1: Write failing CLI driver tests in `test/MainSpec.hs`**
Add tests:
- Unknown target exits with code 1.
- Invalid schema validation error exits with code 1 without Haskell call stack.

- [ ] **Step 2: Run `stack test --test-arguments="-m Main"` to confirm failure**
Confirm the new tests fail as expected.

- [ ] **Step 3: Implement graceful exits in `src/Main.hs`**
Replace line 49:
```haskell
if not (null errors)
    then mapM_ putStrLn errors >> exitFailure
    else case (target args, output args) of
```
Replace line 96:
```haskell
processTarget t _ _ _ = putStrLn ("Unknown target: " ++ t) >> exitFailure
```

- [ ] **Step 4: Run `stack test`**
Verify tests pass under `-Wall -Werror`.

- [ ] **Step 5: Commit**
`git commit -m "fix(cli): exit cleanly with exitFailure on validation failure and unknown target"`

---

### Task 3: Neo4j Cypher Injection Sanitization

**Files:**
- Modify: `src/Emitters/Neo4j.hs`
- Test: `test/Neo4jSpec.hs`

**Interfaces:**
- `escapeCypherString :: String -> String`
- `emitNode`, `emitConstraint`, `emitAuditQuery` sanitize string literals and identifier names.

- [ ] **Step 1: Write failing test in `test/Neo4jSpec.hs` for escaping single quotes and backslashes**
Test that string values containing single quotes (e.g. `O'Connor`) or backslashes are properly escaped as `\'` and `\\`.

- [ ] **Step 2: Run `stack test --test-arguments="-m Neo4j"` to see test fail**

- [ ] **Step 3: Implement `escapeCypherString` in `src/Emitters/Neo4j.hs`**
```haskell
escapeCypherString :: String -> String
escapeCypherString [] = []
escapeCypherString ('\'':cs) = "\\'" ++ escapeCypherString cs
escapeCypherString ('\\':cs) = "\\\\" ++ escapeCypherString cs
escapeCypherString (c:cs) = c : escapeCypherString cs
```
Use `escapeCypherString` in `emitNode` and in `formatCypherValue`:
```haskell
formatCypherValue reg prop val =
    case findProperty prop (properties reg) of
        Just p ->
            case rangeType p of
                "Boolean" -> if val == "True" then "true" else if val == "False" then "false" else val
                "String"  -> "'" ++ escapeCypherString val ++ "'"
                _         -> val
        Nothing -> val
```

- [ ] **Step 4: Run `stack test`**
Verify all tests pass with zero warnings.

- [ ] **Step 5: Commit**
`git commit -m "fix(neo4j): sanitize and escape string literals in generated Cypher"`

---

### Task 4: Configurable Java Package via CLI (`--java-package`)

**Files:**
- Modify: `src/Emitters/Java.hs:7-21`
- Modify: `src/Main.hs:21-36, 50-60`
- Test: `test/JavaSpec.hs`
- Test: `test/MainSpec.hs`

**Interfaces:**
- `emitJavaWithPackage :: String -> Registry -> [(String, String)]`
- `emitJava :: Registry -> [(String, String)]` (default `"com.acme.generated"`)
- CLI option: `--java-package <pkg>`

- [ ] **Step 1: Add unit tests in `test/JavaSpec.hs` and `test/MainSpec.hs`**
Test `emitJavaWithPackage "com.custom.pkg" reg` produces `package com.custom.pkg;`.
Test CLI `--java-package` overrides default.

- [ ] **Step 2: Implement in `src/Emitters/Java.hs`**
```haskell
emitJava :: Registry -> [(String, String)]
emitJava = emitJavaWithPackage "com.acme.generated"

emitJavaWithPackage :: String -> Registry -> [(String, String)]
emitJavaWithPackage pkg reg = 
    map (\(name, parent) -> (name, emitJavaClass pkg (concepts reg) (axioms reg) (properties reg) (name, parent))) (concepts reg)

emitJavaClass :: String -> [(Name, Maybe Name)] -> [FOL] -> [Property] -> (Name, Maybe Name) -> String
emitJavaClass pkg conceptsList axs allProps (name, parent) = 
    ...
    in "package " ++ pkg ++ ";\n" ++ ...
```

- [ ] **Step 3: Update `src/Main.hs` with `--java-package` option**
Add `javaPackage :: Maybe String` to `Args`.
In `processTarget "java"` pass `maybe "com.acme.generated" id (javaPackage args)`.

- [ ] **Step 4: Run full verification**
`stack test && ./gradlew clean build`

- [ ] **Step 5: Commit**
`git commit -m "feat(java): support configurable Java package name via --java-package"`

---

### Task 5: Build Hygiene, Metadata Cleanup & GitHub Actions CI

**Files:**
- Modify: `package.yaml`
- Modify: `stack.yaml`
- Delete: `src/Main` (stale 9.3MB binary)
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- GitHub Actions workflow running on push and pull_request on `main` and `feature/*`.

- [ ] **Step 1: Clean up metadata and extra-deps**
In `package.yaml`:
- `github: "bsommers/OntoLogic"`
- `maintainer: "bsommers"`
In `stack.yaml`:
- Remove `aeson-2.1.2.1` from `extra-deps`.
Remove stale `src/Main` binary from disk.

- [ ] **Step 2: Create `.github/workflows/ci.yml`**
Create automated CI pipeline:
- Setup Haskell (GHC 9.4.8, Stack)
- Setup Java 17
- Run `stack test --ghc-options="-Wall -Werror"`
- Run `./gradlew clean build test`

- [ ] **Step 3: Run `stack clean && stack test --ghc-options="-Wall -Werror"` locally**
Verify zero compiler warnings.

- [ ] **Step 4: Commit**
`git commit -m "chore(ci): add GitHub Actions workflow and clean up package metadata"`

---

### Task 6: Final Verification, Central Documentation Sync & PR Update

**Files:**
- Modify: `docs/dev/superpowers/REPLAY_PLAYBOOK.md`
- Copy plan to root repo and sync `main` branch if appropriate.

- [ ] **Step 1: Run complete verification battery**
- `stack clean && stack test --ghc-options="-Wall -Werror"` (all tests pass, 0 warnings).
- `./gradlew clean build test` (Java build and JUnit 5 pass).
- `./gradlew :app-java:run` (run app).

- [ ] **Step 2: Update `docs/dev/superpowers/REPLAY_PLAYBOOK.md`**
Record security hardening, Cypher sanitization, `callProcess`, and CI setup.

- [ ] **Step 3: Commit and push**
Push to `origin/feature/core-improvements`.
