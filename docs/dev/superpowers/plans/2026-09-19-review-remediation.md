# Review Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close GitHub issues #16–#35 (the 2026-09-19 code review) in six waves, each ending green in CI.

**Architecture:** Fixes are grouped by dependency and by the files they touch. Wave 0 fixes CI and the small, independent defects. Wave 1 fixes the shared code later waves build on (registry helpers, target table, cycle-safe ancestors, parser, stdlib lookup). Wave 2 fixes semantics and the solver. Wave 3 fixes the emitters. Wave 4 fixes the language server. Wave 5 reworks the generated ecosystem data. Every task is test-first and lands as its own PR.

**Tech Stack:** Haskell (stack, lts-21.25 / GHC 9.4.8), megaparsec 9.3, hspec + hspec-discover, z3 and cvc5, TypeScript (VS Code extension), GitHub Actions.

**Spec:** GitHub issues bsommers/OntoLogic #16–#35. The issue bodies are the spec: each has repro steps, evidence and acceptance criteria. The source text is in `.issues/draft-2026-09-19.sh`. Milestones: `Wave 0: Quick wins & security`, `Wave 1: Foundations`, `Wave 2: Semantics & solver`, `Wave 3: Emitters`, `Wave 4: Language server`, `Wave 5: Ecosystem data`.

## Global Constraints

- Build and test: `stack build --test --no-run-tests --ghc-options="-Wall -Werror"`, then `stack test --ghc-options="-Wall -Werror"`. Both must pass before any commit.
- GHC 9.4.8 / resolver `lts-21.25`. Don't add Hackage dependencies other than `bytestring` (Task 4.1), which ships with GHC.
- Tests are Hspec modules in `test/`, named `*Spec.hs` and found by `hspec-discover`. New spec modules need no registration.
- Tests that call a solver need `z3` and `cvc5` on `PATH`. CI installs them after Task 0.1.
- Tests that shell out to the CLI use `readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", ...]` from the repo root, as `test/MainSpec.hs` does.
- One branch and one PR per task: branch `fix/<issue>-<slug>`, PR body contains `Fixes #<issue>`, and the PR is assigned to that wave's milestone.
- Commit messages end with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- If a change alters expected output in an existing test, update the expectation in the same commit and say why in the PR. Never delete a test to get green.
- A wave's gate: every task PR in the wave is merged, CI is green on `main`, and every issue in the milestone is closed.

## Wave map

| Wave | Task | Issue | Depends on |
|---|---|---|---|
| 0 | 0.1 Install SMT solvers in CI | (none; CI on `main` is red) | — |
| 0 | 0.2 VS Code: no shell strings, correct CLI | #28 | — |
| 0 | 0.3 Solver errors reach the user | #16 | 0.1 |
| 0 | 0.4 Exit code for `unknown` | #31 | 0.3 (both edit `runSolverCheck`) |
| 0 | 0.5 REPL exits cleanly on EOF | #32 | — |
| 0 | 0.6 Fix capability manifest and component ontology | #30 | — |
| 1 | 1.1 One definition of the registry helpers | #34 (part 1) | — |
| 1 | 1.2 One emit-target table for the CLI and REPL | #34 (part 2) | 1.1 |
| 1 | 1.3 Cycle-safe `getAncestors` | #21 | — |
| 1 | 1.4 Keywords need a word boundary | #20 | — |
| 1 | 1.5 Malformed `def-*` forms are parse errors | #23 | 1.4 (same file) |
| 1 | 1.6 Standard library found from any directory | #29 | 1.2 (both edit `Main.hs` options) |
| 2 | 2.1 Only `(C v)` antecedents become bounds | #19 | — |
| 2 | 2.2 Subclasses inherit ancestor bounds | #17 | 1.3, 2.1 |
| 2 | 2.3 One SMT emitter with valid numerals and relations | #24 | 0.3 |
| 2 | 2.4 FOL-to-SMT translator | #18 (part 1) | 2.3 |
| 2 | 2.5 Solver uses the FOL theory | #18 (part 2) | 2.4 |
| 3 | 3.1 Go, Rust, Python and Zod output compiles and keeps bounds | #25 | 2.2 |
| 3 | 3.2 Neo4j, Mermaid, D2, GraphQL and OpenAPI output loads | #26 | — |
| 3 | 3.3 Configurable base IRI and Java package | #33 | 1.2 |
| 4 | 4.1 LSP framing in UTF-8 bytes; EOF and `exit` | #22 | — |
| 4 | 4.2 LSP resolves imports and reports real positions | #27 (part 1) | 1.6, 4.1 |
| 4 | 4.3 Lint diagnostics carry a real line and column | #27 (part 2) | 4.2 |
| 5 | 5.1 Code symbols become instance data | #35 | 3.2, 3.3 |

Within a wave, tasks with no dependency between them can run in parallel on separate branches.

**Decision points:**
- Task 0.6 — **resolved:** vendor `factory_domain.logic` into `ontologic-lib/`, and set `"stratum"` to **20**. Both directories are kept; the spider's conventions are raised upstream instead of changed here.
- Task 2.5 — **resolved:** `--solve` reports consistency and coherence separately.
- Task 5.1 — **resolved 2026-09-20:** option 1 — keep the class layer in `ontologic-lib/ecosystem.logic` and move the 910 symbols to `ontologic-lib/data/ecosystem_symbols.ttl` as instances. No DSL change; `def-individual` stays out of scope.

**Cross-repo dependencies:** Task 0.6 Step 6 files an issue against `example-org/factory-domain` (spider conventions). Task 5.1 needs a change to `example-org/symbol-harvester/scripts/harvest_ast_to_ontologic.py`, which must land first.

---
# Wave 0: Quick wins & security

Milestone `Wave 0: Quick wins & security`: #28, #16, #31, #32, #30.

### Task 0.1: Install SMT solvers in CI

CI on `main` has been red for the last three commits (runs 35284456344, 34840827299, 34808815186). In the `Haskell Build & Test` job, the 12 solver tests fail because the runner has neither `z3` nor `cvc5`. Every other test passes. This task has no issue: open the PR as `ci: install z3 and cvc5 for solver tests` with no `Fixes` line.

**Files:**
- Modify: `.github/workflows/ci.yml` (job `haskell-test`, after the checkout step)

- [ ] **Step 1: Confirm the failure**

Run: `gh run view 35284456344 --log-failed | grep '✘'`
Expected: 12 lines, all solver tests (`runs Z3 solver consistency check ...`, `proves ... via CVC5`, etc.).

- [ ] **Step 2: Add the install step**

Insert after `- name: Check out repository` / `uses: actions/checkout@v4` in job `haskell-test`:

```yaml
      - name: Install SMT solvers
        run: |
          sudo apt-get update
          sudo apt-get install -y z3 cvc5
          z3 --version
          cvc5 --version
```

If `apt-get install cvc5` fails on the runner image, replace the `cvc5` part with the static release binary:

```yaml
          sudo apt-get install -y z3
          curl -fsSL -o /tmp/cvc5.zip https://github.com/cvc5/cvc5/releases/download/cvc5-1.2.0/cvc5-Linux-x86_64-static.zip
          unzip -q /tmp/cvc5.zip -d /tmp/cvc5
          sudo install "$(find /tmp/cvc5 -type f -name cvc5 -perm -u+x | head -1)" /usr/local/bin/cvc5
```

(Check the asset name on the cvc5 releases page before using the fallback.)

- [ ] **Step 3: Push and watch**

```bash
git checkout -b ci/install-smt-solvers
git add .github/workflows/ci.yml
git commit -m "ci: install z3 and cvc5 for solver tests"
git push -u origin ci/install-smt-solvers
gh pr create --fill --milestone "Wave 0: Quick wins & security"
gh pr checks --watch
```

Expected: `Haskell Build & Test` passes with 0 failures.

---

### Task 0.2: VS Code commands use argument vectors and find the CLI (#28)

**Files:**
- Modify: `editors/vscode/src/extension.ts` (commands at lines 35–100, `resolveLspBinary` at 103–134)
- Modify: `editors/vscode/package.json` (`contributes.configuration`, new top-level `capabilities`)

**Interfaces:**
- Produces: setting `ontologic.cli.path` (string, machine scope). The helpers `resolveCliBinary()` and `findStackBinary(root, name)` are local to `extension.ts`.

- [ ] **Step 1: Write a failing check**

The extension has no test harness, so the check is a grep plus a manual repro.

Run: `grep -n "cp.exec(" editors/vscode/src/extension.ts`
Expected: 2 matches (lines 55 and 85). This step "fails" by finding them.

- [ ] **Step 2: Replace both commands and the binary lookup**

In `extension.ts`, add the following after the imports:

```ts
const PROVERS = ['auto', 'z3', 'cvc5', 'vampire'];

function findOnPath(name: string): string | undefined {
  for (const dir of (process.env.PATH || '').split(path.delimiter)) {
    const cand = path.join(dir, name);
    if (dir && fs.existsSync(cand)) {
      return cand;
    }
  }
  return undefined;
}

// stack installs to .stack-work/install/<platform>/<hash>/<ghc>/bin
function findStackBinary(root: string, name: string): string | undefined {
  const base = path.join(root, '.stack-work', 'install');
  if (!fs.existsSync(base)) {
    return undefined;
  }
  for (const platform of fs.readdirSync(base)) {
    const pDir = path.join(base, platform);
    for (const hash of fs.readdirSync(pDir)) {
      const hDir = path.join(pDir, hash);
      for (const ghc of fs.readdirSync(hDir)) {
        const cand = path.join(hDir, ghc, 'bin', name);
        if (fs.existsSync(cand)) {
          return cand;
        }
      }
    }
  }
  return undefined;
}

function resolveCliBinary(): string {
  const configured = workspace.getConfiguration('ontologic').get<string>('cli.path', '');
  if (configured) {
    return configured;
  }
  const lspDir = path.dirname(resolveLspBinary());
  for (const name of ['ontologic', 'ontologic-exe']) {
    const sibling = path.join(lspDir, name);
    if (path.isAbsolute(sibling) && fs.existsSync(sibling)) {
      return sibling;
    }
  }
  for (const folder of workspace.workspaceFolders || []) {
    const stackBin = findStackBinary(folder.uri.fsPath, 'ontologic-exe');
    if (stackBin) {
      return stackBin;
    }
  }
  return findOnPath('ontologic') || findOnPath('ontologic-exe') || 'ontologic-exe';
}
```

Replace the body of `ontologic.checkConsistency` from `const lspPath = ...` to the end of the `cp.exec(...)` call with:

```ts
      if (!PROVERS.includes(prover)) {
        window.showErrorMessage(`Invalid ontologic.solver.prover "${prover}". Use one of: ${PROVERS.join(', ')}.`);
        return;
      }
      const cliPath = resolveCliBinary();
      cp.execFile(cliPath, ['-i', filePath, '-t', 'solve', '--prover', prover], (err, stdout, stderr) => {
        outputChannel.appendLine(`[SMT Solver Output]\n${stdout}${stderr}`);
        if (!err && stdout.includes('SMT Satisfiable (SAT)')) {
          window.showInformationMessage('OntoLogic: SMT Model is Satisfiable & Consistent (SAT).');
        } else if (stdout.includes('SMT Unsatisfiable (UNSAT)')) {
          window.showErrorMessage('OntoLogic: Logical contradiction detected (UNSAT). See output channel.');
        } else {
          window.showWarningMessage('OntoLogic: SMT check did not prove consistency. See output channel.');
        }
      });
```

Replace the body of `ontologic.findUnsat` from `const lspPath = ...` to the end of the `cp.exec(...)` call with:

```ts
      const cliPath = resolveCliBinary();
      const child = cp.execFile(cliPath, ['--repl'], (err, stdout) => {
        outputChannel.appendLine(`[REPL Output]\n${stdout}`);
        if (err || stdout.includes('❌')) {
          window.showErrorMessage('OntoLogic: Concept satisfiability check failed. See output channel.');
        } else if (stdout.includes('All concepts are satisfiable')) {
          window.showInformationMessage('OntoLogic: All concepts are logically satisfiable.');
        } else {
          window.showWarningMessage('OntoLogic: Unsatisfiable concept(s) detected. Check output channel.');
        }
      });
      child.stdin?.end(`:load ${filePath}\n:unsat\n:quit\n`);
```

In `resolveLspBinary`, replace the hard-coded `.stack-work/install/x86_64-linux/bin` candidate with:

```ts
      const stackLsp = findStackBinary(folder.uri.fsPath, 'ontologic-lsp');
      if (stackLsp) {
        return stackLsp;
      }
```

(Keep the `bin/` and `dist/` candidates.)

- [ ] **Step 3: Lock down the settings in `package.json`**

In `contributes.configuration.properties`, add `"scope": "machine"` to `ontologic.lsp.path` and add:

```json
        "ontologic.cli.path": {
          "type": "string",
          "default": "",
          "scope": "machine",
          "description": "Path to the ontologic CLI (ontologic or ontologic-exe). Empty = next to the LSP binary, then the stack build, then PATH."
        },
```

Add a top-level key next to `"contributes"`:

```json
  "capabilities": {
    "untrustedWorkspaces": {
      "supported": "limited",
      "description": "Solver commands and custom binary paths are disabled in untrusted workspaces.",
      "restrictedConfigurations": ["ontologic.lsp.path", "ontologic.cli.path", "ontologic.solver.prover"]
    }
  },
```

- [ ] **Step 4: Verify**

```bash
cd editors/vscode && npm ci && npm run compile && cd ../..
grep -n "cp.exec(" editors/vscode/src/extension.ts   # expected: no output
```

Manual check: in the Extension Development Host (F5), open `/tmp/inj/a$(touch pwned).logic` containing `(def-concept A)`. Run both OntoLogic SMT commands, then `ls /tmp/inj`. Expected: no `pwned` file. With a `stack build` checkout and no settings, both commands run and write output to the channel.

- [ ] **Step 5: Commit**

```bash
git add editors/vscode/src/extension.ts editors/vscode/package.json
git commit -m "fix(vscode): run CLI with execFile, validate prover, find stack binaries (#28)"
```

---

### Task 0.3: Solver failures reach the user (#16)

**Files:**
- Modify: `src/Solver.hs` (`runProver` 66–117, `findUnsatConceptsWith` 191–197, `checkSingleClassSatisfiability` 199–213, exports)
- Modify: `src/REPL.hs` (`:unsat` branch, lines 132–136)
- Modify: `src/Main.hs` (`runSolverCheck`, lines 83–95)
- Test: `test/SolverSpec.hs`, `test/REPLSpec.hs`, `test/MainSpec.hs`

**Interfaces:**
- Produces (exported from `Solver`):
  - `data RunFailure = NotInstalled String | SolverFailed String deriving (Show, Eq)`
  - `classifyOutput :: String -> ExitCode -> String -> String -> Either RunFailure String`, with arguments label, exit code, stdout and stderr
  - `findUnsatConceptsWith :: Prover -> Registry -> IO (Either String [String])` (was `IO [String]`)
  - `findUnsatConcepts :: Registry -> IO (Either String [String])`
  - `resolveProver :: Maybe String -> Either String Prover`
- `runProver :: Prover -> String -> IO (Either String String)` keeps its signature.

- [ ] **Step 1: Write failing tests**

Add to the imports of `test/SolverSpec.hs`:

```haskell
import Control.Exception (bracket_)
import System.Environment (lookupEnv, setEnv, unsetEnv)
import System.Exit (ExitCode(..))
import Data.Either (isLeft)
import Data.List (isInfixOf)
```

Add at the bottom of the file:

```haskell
withPath :: String -> IO a -> IO a
withPath p act = do
    old <- lookupEnv "PATH"
    bracket_ (setEnv "PATH" p) (maybe (unsetEnv "PATH") (setEnv "PATH") old) act

emptyReg :: Registry
emptyReg = Registry [] [] [] [] [] []
```

Add a new `describe` block inside `spec`:

```haskell
    describe "Solver failure reporting (#16)" $ do
        it "keeps the solver's stdout diagnostics in the error" $
            classifyOutput "Z3" (ExitFailure 1) "(error \"line 3 column 20: unknown constant e-3\")\n" ""
                `shouldSatisfy` either (\e -> case e of SolverFailed m -> "unknown constant e-3" `isInfixOf` m; _ -> False) (const False)

        it "accepts unsat followed by a get-model error" $
            classifyOutput "Z3" (ExitFailure 1) "unsat\n(error \"model is not available\")\n" ""
                `shouldBe` Right "unsat\n(error \"model is not available\")\n"

        it "reports an error from findUnsatConcepts when no solver is installed" $ do
            let reg = emptyReg { concepts = [("A", Nothing)] }
            res <- withPath "/nonexistent" (findUnsatConceptsWith AutoProver reg)
            res `shouldSatisfy` isLeft

        it "rejects unknown prover names" $ do
            resolveProver (Just "z4") `shouldSatisfy` isLeft
            resolveProver Nothing `shouldBe` Right AutoProver
```

Update the two existing `findUnsat*` expectations in `test/SolverSpec.hs` (lines 125–126 and 158–159):

```haskell
            unsatList `shouldBe` Right ["ContradictoryNode"]
```
```haskell
            unsatList `shouldBe` Right ["BrokenConcept"]
```

Add to `test/REPLSpec.hs` (with the same `withPath` helper and imports):

```haskell
    it ":unsat reports an error, not success, when no solver is installed (#16)" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Robot)"
        (_, out) <- withPath "/nonexistent" (evalREPLCommand s1 ":unsat")
        out `shouldContain` "SMT Solver Error"
        out `shouldNotContain` "All concepts are satisfiable"
```

Add to `test/MainSpec.hs`:

```haskell
    it "rejects an unknown --prover value (#16)" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--solve", "-p", "z4"] ""
      exitCode `shouldBe` ExitFailure 1
      stdout `shouldContain` "Unknown prover 'z4'"
```

- [ ] **Step 2: Run the tests to confirm they fail**

Run: `stack test --ghc-options="-Wall -Werror" --ta '--match "#16"'`
Expected: compile errors (`classifyOutput`, `RunFailure` and `resolveProver` aren't defined), or failures once they're stubbed.

- [ ] **Step 3: Implement in `src/Solver.hs`**

Add `RunFailure(..)`, `classifyOutput` and `resolveProver` to the export list. Replace the imports with:

```haskell
import OntoLogic
import IR
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.IO.Error (isDoesNotExistError)
import Control.Exception (try, IOException)
import Data.List (isPrefixOf, isInfixOf)
import Data.Char (toLower)
```

Replace all four `runProver` equations (lines 66–117) with:

```haskell
data RunFailure
    = NotInstalled String   -- ^ executable not found; AutoProver may try the next one
    | SolverFailed String   -- ^ solver ran and failed; report as-is
    deriving (Show, Eq)

failureMessage :: RunFailure -> String
failureMessage (NotInstalled m) = m
failureMessage (SolverFailed m) = m

trimStart :: String -> String
trimStart = dropWhile (`elem` (" \t\r\n" :: String))

-- | Decide whether a finished solver run produced a usable answer.
-- A leading sat/unsat/unknown verdict is kept even with a non-zero exit (e.g. get-model after unsat).
classifyOutput :: String -> ExitCode -> String -> String -> Either RunFailure String
classifyOutput label code out err
    | any (`isPrefixOf` trimmed) ["sat", "unsat", "unknown"] = Right out
    | code == ExitSuccess && not ("(error" `isInfixOf` out) = Right out
    | otherwise = Left (SolverFailed (label ++ " failed (" ++ show code ++ "):\n" ++ trimStart (out ++ err)))
  where
    trimmed = trimStart out

runBinary :: String -> FilePath -> [String] -> String -> IO (Either RunFailure String)
runBinary label exe args smtInput = do
    result <- try (readProcessWithExitCode exe args smtInput) :: IO (Either IOException (ExitCode, String, String))
    return $ case result of
        Left ex
            | isDoesNotExistError ex ->
                Left (NotInstalled ("Failed to execute " ++ label ++ " solver: " ++ show ex ++ "\nEnsure '" ++ exe ++ "' is installed and available in PATH."))
            | otherwise -> Left (SolverFailed ("Failed to execute " ++ label ++ " solver: " ++ show ex))
        Right (code, out, err) -> classifyOutput label code out err

runProverRaw :: Prover -> String -> IO (Either RunFailure String)
runProverRaw Z3 = runBinary "Z3" "z3" ["-in"]
runProverRaw CVC5 = runBinary "CVC5" "cvc5" ["--lang=smt2", "--produce-models", "-"]
runProverRaw Vampire = runBinary "Vampire" "vampire" ["--input_syntax", "smtlib2", "--mode", "smtcomp", "-"]
runProverRaw AutoProver = \smtInput -> tryEach smtInput [Z3, CVC5, Vampire]
  where
    -- Fall through only when a solver is not installed; a real failure is reported.
    tryEach _ [] = return (Left (NotInstalled "No compatible SMT solver found in PATH (tried z3, cvc5, vampire). Please install Z3 or CVC5."))
    tryEach smtInput (p:ps) = do
        r <- runProverRaw p smtInput
        case r of
            Left (NotInstalled _) -> tryEach smtInput ps
            other -> return other

-- | Run raw SMT-LIB2 code through the selected SMT solver backend
runProver :: Prover -> String -> IO (Either String String)
runProver p smtInput = either (Left . failureMessage) Right <$> runProverRaw p smtInput

-- | Parse a --prover value; Nothing means the default (auto).
resolveProver :: Maybe String -> Either String Prover
resolveProver Nothing = Right AutoProver
resolveProver (Just s) =
    maybe (Left ("Unknown prover '" ++ s ++ "'. Valid options: z3, cvc5, vampire, auto")) Right (parseProver s)
```

Replace `findUnsatConceptsWith`, `findUnsatConcepts` and `checkSingleClassSatisfiability` with:

```haskell
-- | Find all unsatisfiable concepts; Left if the solver could not run.
findUnsatConceptsWith :: Prover -> Registry -> IO (Either String [String])
findUnsatConceptsWith p reg = go (irClasses (compileRegistry reg)) []
  where
    go [] acc = return (Right (reverse acc))
    go (cls:rest) acc = do
        r <- checkSingleClassSatisfiability p cls
        case r of
            Left err    -> return (Left err)
            Right True  -> go rest (compClassName cls : acc)
            Right False -> go rest acc

-- | Find all unsatisfiable (logically empty/contradictory) concepts using AutoProver
findUnsatConcepts :: Registry -> IO (Either String [String])
findUnsatConcepts = findUnsatConceptsWith AutoProver

-- | Right True when the class is unsatisfiable.
checkSingleClassSatisfiability :: Prover -> CompiledClass -> IO (Either String Bool)
checkSingleClassSatisfiability p cls = do
    let cName = sanitizeIdent (compClassName cls)
        smtCode =
            "; SMT check for concept " ++ cName ++ "\n" ++
            "(set-logic ALL)\n" ++
            "(declare-sort Entity 0)\n" ++
            "(declare-const " ++ cName ++ " Entity)\n" ++
            concatMap (emitPropertyFunction cName) (compProperties cls) ++
            "(check-sat)\n"
    res <- runProver p smtCode
    return (fmap (\out -> "unsat" `isPrefixOf` trimStart out) res)
```

In `checkConsistencyWith` and `proveSubsumptionWith`, replace each local `dropWhile (`elem` (" \t\r\n" :: String)) out` with `trimStart out`.

- [ ] **Step 4: Update the REPL and the CLI**

In `src/REPL.hs`, replace the `:unsat` branch:

```haskell
    | input == ":unsat" = do
        res <- findUnsatConceptsWith (replProver state) (replRegistry state)
        case res of
            Left err -> return (state, "❌ SMT Solver Error:\n" ++ err)
            Right [] -> return (state, "✅ All concepts are satisfiable (0 empty concepts) via " ++ proverName (replProver state) ++ ".")
            Right unsatList -> return (state, "❌ Unsatisfiable / Contradictory Concepts Found via " ++ proverName (replProver state) ++ ":\n" ++ unlines (map ("  - " ++) unsatList))
```

In `src/Main.hs`, import `resolveProver` from `Solver` and replace the start of `runSolverCheck`:

```haskell
runSolverCheck :: Maybe String -> Registry -> IO ()
runSolverCheck maybeP reg =
    case resolveProver maybeP of
        Left msg -> putStrLn msg >> exitFailure
        Right prover -> do
            res <- checkConsistencyWith prover reg
            case res of
                Sat _ -> putStrLn "✅ SMT Satisfiable (SAT) — Ontology is logically consistent."
                Unsat -> putStrLn "❌ SMT Unsatisfiable (UNSAT) — Logical contradiction detected!" >> exitFailure
                Unknown out -> putStrLn ("⚠️  SMT Solver Result: " ++ out)
                SolverError err -> putStrLn ("❌ SMT Solver Error: " ++ err) >> exitFailure
```

Remove the `Prover(..)` and `parseProver` imports from `Main.hs` if `-Wall` reports them as unused.

- [ ] **Step 5: Run the tests**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass, including the four new `#16` cases and the updated `findUnsat` expectations. The old REPL test `runs concept unsatisfiability check (:unsat) from REPL` needs a solver now, which Task 0.1 provides.

- [ ] **Step 6: Commit**

```bash
git add src/Solver.hs src/REPL.hs src/Main.hs test/SolverSpec.hs test/REPLSpec.hs test/MainSpec.hs
git commit -m "fix(solver): report solver failures instead of success; reject unknown provers (#16)"
```

The VS Code side of #16 (success only on an explicit result) is done in Task 0.2. Link that PR from this one.

---

### Task 0.4: `--solve` exits non-zero on `unknown` (#31)

**Files:**
- Modify: `src/Solver.hs` (new export)
- Modify: `src/Main.hs` (`runSolverCheck`, as rewritten in Task 0.3)
- Modify: `HOW_TO_USE.md` (the `solve` section around line 221)
- Test: `test/SolverSpec.hs`

**Interfaces:**
- Consumes: `resolveProver` and the `runSolverCheck` shape from Task 0.3.
- Produces: `solverExitCode :: SolverResult -> ExitCode` (exported from `Solver`).

- [ ] **Step 1: Write the failing test**

Add to `test/SolverSpec.hs`:

```haskell
    describe "Exit codes (#31)" $
        it "maps every solver result to a documented exit code" $ do
            solverExitCode (Sat "model") `shouldBe` ExitSuccess
            solverExitCode Unsat `shouldBe` ExitFailure 1
            solverExitCode (SolverError "boom") `shouldBe` ExitFailure 1
            solverExitCode (Unknown "unknown") `shouldBe` ExitFailure 2
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `stack test --ta '--match "#31"'`
Expected: compile error, `solverExitCode` not in scope.

- [ ] **Step 3: Implement**

In `src/Solver.hs`, export `solverExitCode` and add:

```haskell
-- | CLI exit code for a consistency result: 0 = SAT, 1 = UNSAT or error, 2 = unknown.
solverExitCode :: SolverResult -> ExitCode
solverExitCode (Sat _)         = ExitSuccess
solverExitCode Unsat           = ExitFailure 1
solverExitCode (SolverError _) = ExitFailure 1
solverExitCode (Unknown _)     = ExitFailure 2
```

In `src/Main.hs`, change the `Right prover` branch of `runSolverCheck` to print and then exit with the mapped code:

```haskell
        Right prover -> do
            res <- checkConsistencyWith prover reg
            putStrLn $ case res of
                Sat _ -> "✅ SMT Satisfiable (SAT) — Ontology is logically consistent."
                Unsat -> "❌ SMT Unsatisfiable (UNSAT) — Logical contradiction detected!"
                Unknown out -> "⚠️  SMT Solver Result (unknown): " ++ out
                SolverError err -> "❌ SMT Solver Error: " ++ err
            exitWith (solverExitCode res)
```

Import `exitWith` from `System.Exit` and `solverExitCode` from `Solver`.

- [ ] **Step 4: Document the codes**

In `HOW_TO_USE.md`, after the `--solve -p cvc5` example (line 225), add:

```markdown
`--solve` exit codes: `0` = satisfiable (consistent), `1` = unsatisfiable or solver error, `2` = the solver answered `unknown`.
```

- [ ] **Step 5: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass.

```bash
git add src/Solver.hs src/Main.hs HOW_TO_USE.md test/SolverSpec.hs
git commit -m "fix(cli): exit 2 when the solver answers unknown (#31)"
```

---

### Task 0.5: The REPL exits cleanly at end of input (#32)

**Files:**
- Modify: `src/REPL.hs` (`runREPL` loop, lines 52–64; import line 4)
- Test: `test/MainSpec.hs`

- [ ] **Step 1: Write the failing test**

Add to `test/MainSpec.hs`:

```haskell
    it "exits 0 without an exception when REPL input ends (#32)" $ do
      (exitCode, stdout, stderr) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "--repl"] ":help\n"
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Goodbye!"
      stderr `shouldNotContain` "end of file"
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `stack build && stack test --ta '--match "#32"'`
Expected: FAIL. The exit code is `ExitFailure 1` and stderr contains `hGetLine: end of file`.

- [ ] **Step 3: Implement**

In `src/REPL.hs`, change the import to `import System.IO (hFlush, stdout, isEOF)` and the loop to:

```haskell
    loop state = do
        putStr "ontologic> "
        hFlush stdout
        eof <- isEOF
        if eof
            then putStrLn "\nGoodbye!"
            else do
                line <- getLine
                case trim line of
                    ":quit" -> putStrLn "Goodbye!"
                    ":q"    -> putStrLn "Goodbye!"
                    "exit"  -> putStrLn "Goodbye!"
                    ""      -> loop state
                    cmd     -> do
                        (newState, output) <- evalREPLCommand state cmd
                        putStrLn output
                        loop newState
```

- [ ] **Step 4: Run the tests**

Run: `stack build && stack test --ghc-options="-Wall -Werror"`
Expected: all pass. Manual check: `stack exec ontologic-exe -- --repl`, then Ctrl-D, prints `Goodbye!` and exits 0.

- [ ] **Step 5: Commit**

```bash
git add src/REPL.hs test/MainSpec.hs
git commit -m "fix(repl): exit cleanly on EOF / Ctrl-D (#32)"
```

---

### Task 0.6: Fix the capability manifest; keep both ontology directories (#30)

**Findings that change this task's scope** (checked across `~/ecosystem`):
- `ontology/` is the ecosystem spider's output directory. `~/ecosystem/example-org/factory-domain/src/ecosystem/control/ontology.py` writes `ontology/component.logic` and `ontology/component_schema.ttl`, and `factory-domain/test/test_ontology.py:110` asserts that path. Peer repos (`symbol-seeder`, `central_skills`, `symbol-harvester`) have the same layout.
- `.ontology/` is the seeded-bindings directory from step 6 of `docs/DOMAIN_ONTOLOGY_EXPANSION_PLAN.md`. So the two directories have **different owners**, and neither should be deleted.
- The class-versus-individual difference and the IRI-base difference are **spider conventions across the ecosystem**, not defects in this repo: `symbol-seeder/ontology/component.logic` declares `(def-concept seed_brain_gh:seed_brain_ghNode dsf:SoftwareFactory)` while its TTL declares `:symbol-seederNode a dsf:SoftwareFactory`, under `/symbol-seeder/ontology#` and `/symbol-seeder/` respectively. Changing them here alone would make this repo the odd one out.
- `factory_domain.logic` exists at `~/ecosystem/example-org/factory-domain/ontology/factory_domain.logic` (59 lines). Every `cco:` and `bfo:` name it references already resolves against this repo's `ontologic-lib/cco_core.logic` and `bfo_2020.logic` (checked), so vendoring it here lints.

This task therefore fixes only what is wrong for this repo, and documents the rest. The spider-level items become a separate issue against `factory-domain` (Step 6).

**Decision, resolved 2026-09-19 — Option 1 (vendor).** The owner chose to vendor, and set the stratum question below to **20**.
1. **Chosen: vendor `factory_domain.logic` into `ontologic-lib/`.** `docs/DOMAIN_ONTOLOGY_EXPANSION_PLAN.md` names OntoLogic the authority repository, and `factory-domain` already keeps its own copies of `bfo_2020.logic` and `cco_core.logic` taken from here, so the tier-3 file belongs in this library. Risk: a second copy that can drift from `factory-domain`.
2. Leave the import external and resolve it with `ONTOLOGIC_PATH` (Task 1.6). No copy, but the component ontology then can't be linted from a clean checkout, and any path in a script would be machine-specific.

The steps below assume option 1.

**Files:**
- Modify: `docs/capabilities.json`, `docs/CAPABILITIES.md`
- Create: `ontology/README.md`, `ontologic-lib/factory_domain.logic` (vendored)
- Modify: `.ontology/README.md`, `HOW_TO_USE.md`
- Test: `test/MainSpec.hs`, `test/StandardLibrarySpec.hs`

- [ ] **Step 1: Write the failing tests**

Add to `test/MainSpec.hs`:

```haskell
    it "capabilities.json declares the real entrypoints and test command (#30)" $ do
      manifest <- readFile "docs/capabilities.json"
      manifest `shouldContain` "\"test_command\": \"stack test\""
      manifest `shouldContain` "\"cli\": \"ontologic-exe\""
      manifest `shouldNotContain` "pytest"

    it "lints the component ontology from a clean checkout (#30)" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "ontology/component.logic", "-t", "lint"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Logic Validated successfully"
```

Run: `stack test --ta '--match "#30"'`
Expected: both FAIL — the manifest says `pytest`, and the lint run says `Import not found: factory_domain.logic`.

- [ ] **Step 2: Fix the manifest**

In `docs/capabilities.json`, replace:

```json
      "entrypoints": {
        "python": "OntoLogic.core"
      },
```
with
```json
      "entrypoints": {
        "cli": "ontologic-exe",
        "lsp": "ontologic-lsp"
      },
```

and replace `"test_command": "pytest test/ -q"` with `"test_command": "stack test"`. Update the same two cells in the `docs/CAPABILITIES.md` table.

`manifest_sha256` and `last_reconciled` are written by the ecosystem reconciler (`ecosystem` in `factory-domain`). Re-run it if it's available; otherwise leave both fields untouched and say so in the PR. Do not hand-edit the hash.

`"stratum": 50` is wrong: the owner confirmed **20**. Set `"stratum": 20` in `docs/capabilities.json` so it matches `poset_tier: 20` in the bindings, and fix the `**Stratum Tier:** Tier 50` line in `docs/CAPABILITIES.md`. Add to the Step 1 test:

```haskell
      manifest `shouldContain` "\"stratum\": 20"
```

- [ ] **Step 3: Vendor the tier-3 library**

```bash
cp ~/ecosystem/example-org/factory-domain/ontology/factory_domain.logic ontologic-lib/factory_domain.logic
stack exec ontologic-exe -- -i ontologic-lib/factory_domain.logic -t lint
stack exec ontologic-exe -- -i ontology/component.logic -t lint
```

Expected: both print `✅ Logic Validated successfully.` Add a header comment to the vendored file:

```lisp
;; Vendored from example-org/factory-domain/ontology/factory_domain.logic.
;; factory-domain owns the source; update this copy when that file changes.
```

Add a case to `test/StandardLibrarySpec.hs` that loads `ontologic-lib/factory_domain.logic` and asserts `dsf:SoftwareFactory` is present with parent `cco:EngineeredSystem`, following the existing cases in that file.

- [ ] **Step 4: Document the two directories**

Create `ontology/README.md`:

```markdown
# ontology/ — component ontology (generated)

Written by the ecosystem ontology spider (`factory-domain/src/ecosystem/control/ontology.py`).
Every ecosystem repository carries this layout, so the conventions here are the spider's, not this repo's:

- `component.logic` — this repository as a DSL concept, imported from `factory_domain.logic` (vendored into `ontologic-lib/`).
- `component_schema.ttl` — the same node in RDF, where the spider declares it as an individual.

Regenerate with the spider rather than editing by hand. For the seeded BFO bindings, see `.ontology/`.
```

Append to `.ontology/README.md`:

```markdown
## Relationship to `ontology/`

`.ontology/` holds bindings seeded by the ecosystem pipeline (step 6 of `docs/DOMAIN_ONTOLOGY_EXPANSION_PLAN.md`).
`ontology/` holds the component ontology written by the ecosystem spider. Different owners, so both are kept.
```

Add a line to `HOW_TO_USE.md` pointing at both READMEs.

- [ ] **Step 5: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass.

```bash
git add docs/capabilities.json docs/CAPABILITIES.md ontology/README.md .ontology/README.md ontologic-lib/factory_domain.logic HOW_TO_USE.md test/MainSpec.hs test/StandardLibrarySpec.hs
git commit -m "fix(capabilities): real entrypoints and test command; vendor factory_domain; document ontology dirs (#30)"
```

- [ ] **Step 6: File the spider-level issues upstream**

These are generator conventions, so they belong to `factory-domain`, not to this repo's waves. Open one issue there (don't fix it here) covering:
- `component.logic` declares the repo node as a **subclass** of `dsf:SoftwareFactory` while `component_schema.ttl` declares it as an **individual**. One of the two is wrong in all 65 repos.
- The `.logic` base is `<repo>/ontology#` and the TTL base is `<repo>/`, so the same node has two IRIs.
- `.ontology/bfo_binding.cql` uses `CREATE`, which duplicates nodes on re-run, and `ontology/bfo_binding.cql` MERGEs on the whole property map, so changing `poset_tier` creates a second node. Both should `MERGE` on `id` and `SET` the rest.
- `.ontology/domain_schema.ttl` uses `bfo: <http://purl.obolibrary.org/obo/bfo.owl#>`, which doesn't match BFO's `BFO_nnnnnnn` IRIs.
- Some repos keep these files in `.ontology/` (e.g. `central_skills`), others in `ontology/`. Pick one.

Paste the exact file and line references from this repo as evidence, and link the issue from #30 before closing it.

**Wave 0 gate:** all six PRs merged, `gh run list --branch main --limit 1` shows `success`, and milestone `Wave 0: Quick wins & security` shows 0 open issues.

---
# Wave 1: Foundations

Milestone `Wave 1: Foundations`: #34, #21, #20, #23, #29. #34 is split over two PRs: Task 1.1 says `Refs #34`, Task 1.2 says `Fixes #34`.

### Task 1.1: One definition of the registry helpers (#34, part 1)

**Files:**
- Modify: `src/OntoLogic.hs` (add helpers and instances after the `Registry` type, line ~159)
- Modify: `src/Parser.hs` (delete `emptyRegistry`, lines 172–173)
- Modify: `src/Loader.hs` (delete `mergeRegistries`, `emptyRegistry`, `deduplicateRegistry`, lines 96–119)
- Modify: `src/REPL.hs` (delete `mergeRegistries`, lines 195–203; `initialREPLState` uses `emptyRegistry`)
- Modify: `src/LSP.hs` (replace the `Registry [] [] [] [] [] []` literals with `emptyRegistry`)
- Test: `test/RegistrySpec.hs` (new)

**Interfaces:**
- Produces (exported from `OntoLogic`): `emptyRegistry :: Registry`, `mergeRegistries :: Registry -> Registry -> Registry`, `deduplicateRegistry :: Registry -> Registry`, `instance Semigroup Registry`, `instance Monoid Registry`.

- [ ] **Step 1: Write the failing test**

Create `test/RegistrySpec.hs`:

```haskell
module RegistrySpec (spec) where

import Test.Hspec
import OntoLogic

spec :: Spec
spec = describe "Registry helpers (#34)" $ do
    let a = emptyRegistry { concepts = [("A", Nothing)], namespaces = [NamespaceDecl "x" (Just "http://x/")] }
        b = emptyRegistry { concepts = [("A", Nothing), ("B", Just "A")], namespaces = [NamespaceDecl "x" (Just "http://other/")] }

    it "merges field by field, left first" $
        concepts (a <> b) `shouldBe` [("A", Nothing), ("A", Nothing), ("B", Just "A")]

    it "has emptyRegistry as identity" $ do
        (a <> mempty) `shouldBe` a
        (mempty <> a) `shouldBe` a

    it "deduplicates entries and keeps the last namespace per prefix (current Loader behavior)" $ do
        let d = deduplicateRegistry (a <> b)
        concepts d `shouldBe` [("A", Nothing), ("B", Just "A")]
        namespaces d `shouldBe` [NamespaceDecl "x" (Just "http://other/")]
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `stack test --ta '--match "#34"'`
Expected: compile error, `emptyRegistry` and the `Semigroup Registry` instance aren't in scope from `OntoLogic`.

- [ ] **Step 3: Move the helpers into `src/OntoLogic.hs`**

Add `import Data.List (nub)` and, after `data Registry ...`:

```haskell
emptyRegistry :: Registry
emptyRegistry = Registry [] [] [] [] [] []

mergeRegistries :: Registry -> Registry -> Registry
mergeRegistries r1 r2 = Registry
    { concepts   = concepts r1 ++ concepts r2
    , axioms     = axioms r1 ++ axioms r2
    , properties = properties r1 ++ properties r2
    , relations  = relations r1 ++ relations r2
    , imports    = imports r1 ++ imports r2
    , namespaces = namespaces r1 ++ namespaces r2
    }

instance Semigroup Registry where
    (<>) = mergeRegistries

instance Monoid Registry where
    mempty = emptyRegistry

-- | Drop repeated entries; for namespaces keep the last declaration of each prefix.
deduplicateRegistry :: Registry -> Registry
deduplicateRegistry reg = Registry
    { concepts   = nub (concepts reg)
    , axioms     = nub (axioms reg)
    , properties = nub (properties reg)
    , relations  = nub (relations reg)
    , imports    = nub (imports reg)
    , namespaces = nubByPrefix (namespaces reg)
    }
  where
    nubByPrefix ns = foldr (\n acc -> if any (\x -> nsPrefix x == nsPrefix n) acc then acc else n : acc) [] ns
```

This is the Loader version copied unchanged. Its right fold keeps the **last** declaration of each prefix, and `RegistrySpec` pins that so the move doesn't change behavior.

Delete the copies from `Parser.hs`, `Loader.hs` and `REPL.hs`. In `Loader.hs` remove `nub` from the `Data.List` import if it becomes unused. In `REPL.hs` set `initialREPLState = REPLState emptyRegistry Nothing AutoProver`. In `LSP.hs` replace both `Registry [] [] [] [] [] []` with `emptyRegistry`.

- [ ] **Step 4: Run the full suite**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass. `grep -rn "^emptyRegistry\|^mergeRegistries\|^deduplicateRegistry" src` shows only `src/OntoLogic.hs`.

- [ ] **Step 5: Commit**

```bash
git add src/OntoLogic.hs src/Parser.hs src/Loader.hs src/REPL.hs src/LSP.hs test/RegistrySpec.hs
git commit -m "refactor: define registry helpers once in OntoLogic (#34)"
```

---

### Task 1.2: One emit-target table for the CLI and REPL (#34, part 2)

**Files:**
- Create: `src/Targets.hs`
- Modify: `src/Main.hs` (replace the 20 `processTarget` equations at lines 97–218 and the `--target` help text at line 48)
- Modify: `src/REPL.hs` (`:emit` branch, lines 159–179; `:help` line for `:emit`)
- Test: `test/TargetsSpec.hs` (new)

**Interfaces:**
- Consumes: `Registry` and the emitter functions (unchanged).
- Produces (module `Targets`):
  - `data EmitOptions = EmitOptions { optJavaPackage :: String } deriving (Show, Eq)` (Task 3.3 adds `optBaseIri`)
  - `defaultEmitOptions :: EmitOptions`
  - `data Target = Target { targetName :: String, targetAliases :: [String], targetLabel :: String, targetWarnAs :: Maybe String, targetEmit :: EmitOptions -> Registry -> [(FilePath, String)] }`
  - `targets :: [Target]`, `lookupTarget :: String -> Maybe Target`, `targetHelp :: String`

- [ ] **Step 1: Write the failing test**

Create `test/TargetsSpec.hs`:

```haskell
module TargetsSpec (spec) where

import Test.Hspec
import Control.Monad (forM_)
import Data.Maybe (isJust)
import OntoLogic
import Targets
import REPL (evalREPLCommand, initialREPLState)

spec :: Spec
spec = describe "Shared emit-target table (#34)" $ do
    it "resolves every name and alias" $
        forM_ targets $ \t ->
            forM_ (targetName t : targetAliases t) $ \n ->
                fmap targetName (lookupTarget n) `shouldBe` Just (targetName t)

    it "includes the targets the REPL used to lack" $ do
        lookupTarget "mermaid" `shouldSatisfy` isJust
        lookupTarget "d2" `shouldSatisfy` isJust
        lookupTarget "neo4j" `shouldSatisfy` isJust
        lookupTarget "owl" `shouldSatisfy` isJust

    it "lists every target in the CLI help" $
        forM_ targets $ \t -> targetHelp `shouldContain` targetName t

    it "can emit every target from the REPL" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Robot)"
        forM_ targets $ \t -> do
            (_, out) <- evalREPLCommand s1 (":emit " ++ targetName t)
            out `shouldNotContain` "Unknown emit target"

    it "produces at least one file per target" $
        forM_ targets $ \t ->
            targetEmit t defaultEmitOptions (emptyRegistry { concepts = [("A", Nothing)] }) `shouldSatisfy` (not . null)
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `stack test --ta '--match "#34"'`
Expected: compile error, module `Targets` not found.

- [ ] **Step 3: Create `src/Targets.hs`**

```haskell
module Targets
    ( Target(..)
    , EmitOptions(..)
    , defaultEmitOptions
    , targets
    , lookupTarget
    , targetHelp
    ) where

import Data.List (intercalate)
import OntoLogic
import Emitters.Java (emitJavaWithPackage)
import Emitters.Python (emitPython)
import Emitters.Rust (emitRust)
import Emitters.Go (emitGo)
import Emitters.TypeScript (emitTypeScript)
import Emitters.OpenApi (emitOpenApi)
import Emitters.GraphQL (emitGraphQL)
import Emitters.SMT (emitSMT)
import Emitters.Neo4j (emitCypher)
import Emitters.Owl (emitOwl)
import Emitters.JsonSchema (emitJsonSchema)
import Emitters.Shacl (emitShacl)
import Emitters.Mermaid (emitMermaid)
import Emitters.D2 (emitD2)

-- | Options that emitters may consult.
data EmitOptions = EmitOptions
    { optJavaPackage :: String
    } deriving (Show, Eq)

defaultEmitOptions :: EmitOptions
defaultEmitOptions = EmitOptions { optJavaPackage = "com.acme.generated" }

-- | One code-generation target, shared by the CLI and the REPL.
data Target = Target
    { targetName    :: String
    , targetAliases :: [String]
    , targetLabel   :: String         -- ^ "Generated <label> in <dir>"
    , targetWarnAs  :: Maybe String   -- ^ report unmapped axioms under this name
    , targetEmit    :: EmitOptions -> Registry -> [(FilePath, String)]  -- ^ (file name, contents)
    }

single :: FilePath -> (Registry -> String) -> EmitOptions -> Registry -> [(FilePath, String)]
single file f _ reg = [(file, f reg)]

targets :: [Target]
targets =
    [ Target "java" [] "Java models" (Just "Java")
        (\o reg -> [ (n ++ ".java", c) | (n, c) <- emitJavaWithPackage (optJavaPackage o) reg ])
    , Target "python" [] "Python models" (Just "Python") (single "models.py" emitPython)
    , Target "rust" [] "Rust models" (Just "Rust") (single "models.rs" emitRust)
    , Target "go" ["golang"] "Go models" (Just "Go") (single "models.go" emitGo)
    , Target "ts" ["typescript", "zod"] "TypeScript/Zod models" Nothing (single "models.ts" emitTypeScript)
    , Target "openapi" [] "OpenAPI 3.1 schema" Nothing (single "openapi.yaml" emitOpenApi)
    , Target "graphql" ["gql"] "GraphQL schema" Nothing (single "schema.graphql" emitGraphQL)
    , Target "smt" ["smtlib"] "SMT-LIB2 specification" Nothing (single "spec.smt2" emitSMT)
    , Target "neo4j" [] "Neo4j Cypher" Nothing (single "graph.cypher" emitCypher)
    , Target "owl" [] "OWL ontology" Nothing (single "ontology.owl" emitOwl)
    , Target "jsonschema" ["json"] "JSON Schema" (Just "JSON Schema") (single "schema.json" emitJsonSchema)
    , Target "shacl" [] "SHACL shapes" Nothing (single "shapes.ttl" emitShacl)
    , Target "mermaid" [] "Mermaid diagram" Nothing (single "class_diagram.mmd" emitMermaid)
    , Target "d2" [] "D2 diagram" Nothing (single "diagram.d2" emitD2)
    ]

lookupTarget :: String -> Maybe Target
lookupTarget t =
    case filter (\x -> t == targetName x || t `elem` targetAliases x) targets of
        (x:_) -> Just x
        []    -> Nothing

targetHelp :: String
targetHelp = "Target: " ++ intercalate ", " (map targetName targets ++ ["lint", "solve", "repl", "lsp"])
```

- [ ] **Step 4: Use the table in `src/Main.hs`**

Replace every `processTarget` equation (lines 97–218) with:

```haskell
processTarget :: String -> String -> Maybe String -> Bool -> Registry -> IO ()
processTarget "lint" _ _ _ _ = putStrLn "✅ Logic Validated successfully."
processTarget t out jPkg doRender reg =
    case lookupTarget t of
        Nothing -> putStrLn ("Unknown target: " ++ t) >> exitFailure
        Just tgt -> do
            createDirectoryIfMissing True out
            mapM_ (`warnUnmappedAxioms` reg) (targetWarnAs tgt)
            let opts = defaultEmitOptions { optJavaPackage = maybe (optJavaPackage defaultEmitOptions) id jPkg }
                files = targetEmit tgt opts reg
            mapM_ (\(name, content) -> writeFile (out </> name) content) files
            putStrLn ("Generated " ++ targetLabel tgt ++ " in " ++ out)
            case (targetName tgt, files) of
                ("mermaid", [(name, _)]) -> renderIf (renderMermaid (out </> name))
                ("d2", [(name, _)])      -> renderIf (renderD2 (out </> name))
                _                        -> return ()
  where
    renderIf act = if doRender then act else putStrLn "Skipping render (use --render to generate SVG)."
```

Change the `--target` help to `help targetHelp`. Add `import Targets (lookupTarget, targetHelp, targetEmit, targetLabel, targetName, targetWarnAs, defaultEmitOptions, EmitOptions(..))` and `import System.FilePath ((</>))`, and drop the per-emitter imports that `-Wall` now reports as unused.

- [ ] **Step 5: Use the table in `src/REPL.hs`**

Replace the `:emit` branch with:

```haskell
    | ":emit " `isPrefixOf` input =
        let target = trim (drop 6 input)
        in case lookupTarget target of
            Nothing  -> return (state, "❌ Unknown emit target: " ++ target ++ ". Valid targets: " ++ intercalate ", " (map targetName targets))
            Just tgt -> return (state, concatMap snd (targetEmit tgt defaultEmitOptions (replRegistry state)))
```

Change the `:help` line to `"  :emit <target>        Emit code (" ++ intercalate ", " (map targetName targets) ++ ")"`. Import `Targets` and `Data.List (isPrefixOf, intercalate)`, and drop the unused emitter imports.

- [ ] **Step 6: Run the full suite**

Run: `stack build && stack test --ghc-options="-Wall -Werror"`
Expected: all pass. If a Mermaid or D2 CLI test asserted the old message `Generated Mermaid diagram in <file>`, update it to the directory form and note that in the PR.

- [ ] **Step 7: Commit**

```bash
git add src/Targets.hs src/Main.hs src/REPL.hs test/TargetsSpec.hs
git commit -m "refactor: share one emit-target table between CLI and REPL (#34)"
```

---

### Task 1.3: `getAncestors` stops at cycles (#21)

**Files:**
- Modify: `src/OntoLogic.hs` (`getAncestors`, lines 187–192; add `import qualified Data.Set as Set`)
- Test: `test/IRSpec.hs`, `test/REPLSpec.hs`, `test/LSPSpec.hs`

**Interfaces:**
- Produces: `getAncestors :: Name -> [(Name, Maybe Name)] -> [Name]`, same signature, now always finite and never containing its argument. Task 2.2 relies on this.

- [ ] **Step 1: Write failing tests**

In `test/IRSpec.hs` add imports `System.Timeout (timeout)`, `Control.Exception (evaluate)` and `Data.Maybe (isJust)`, then:

```haskell
    describe "cyclic inheritance (#21)" $ do
      -- Registry fields: concepts, axioms, properties, relations, imports, namespaces
      let cyclic = Registry [("A", Just "B"), ("B", Just "A"), ("C", Nothing)] [] [Property "w" "C" PTInteger] [] [] []
      it "getAncestors terminates on a cycle" $
        getAncestors "A" (concepts cyclic) `shouldBe` ["B"]
      it "compileRegistry terminates on a cycle" $ do
        r <- timeout 2000000 (evaluate (length (show (compileRegistry cyclic))))
        r `shouldSatisfy` isJust
```

In `test/REPLSpec.hs` (add `System.Timeout (timeout)` and `Data.Maybe (isJust)`):

```haskell
    it ":emit responds for a registry with an inheritance cycle (#21)" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept A B) (def-concept B A) (def-concept C) (def-property w C Integer)"
        r <- timeout 3000000 (evalREPLCommand s1 ":emit python" >>= \(_, o) -> return $! length o)
        r `shouldSatisfy` isJust
```

In `test/LSPSpec.hs` (same imports, plus `Control.Exception (evaluate)`):

```haskell
    it "answers hover on a document with an inheritance cycle (#21)" $ do
        let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///c.logic\",\"text\":\"(def-concept A B)\\n(def-concept B A)\\n(def-concept C)\\n(def-property w C Integer)\\n\"}}"
            (s1, _, _) = handleLSPRequest initialLSPState openReq
            hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"textDocument/hover\",\"params\":{\"textDocument\":{\"uri\":\"file:///c.logic\"},\"position\":{\"line\":0,\"character\":13}}}"
        r <- timeout 3000000 (evaluate (length (show (handleLSPRequest s1 hoverReq))))
        r `shouldSatisfy` isJust
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#21"'`
Expected: `compileRegistry terminates` and the REPL and LSP cases FAIL on timeout. `getAncestors terminates` hangs, so give the run a `timeout 60`.

- [ ] **Step 3: Implement**

```haskell
-- | Parents, grandparents, ... of a concept, nearest first. Stops at a cycle.
getAncestors :: Name -> [(Name, Maybe Name)] -> [Name]
getAncestors name conceptsList = go (Set.singleton name) name
  where
    go seen n = case lookup n conceptsList of
        Just (Just parent) | not (Set.member parent seen) -> parent : go (Set.insert parent seen) parent
        _ -> []
```

- [ ] **Step 4: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass. The existing `detects circular inheritance cycles` linter test is unchanged.

```bash
git add src/OntoLogic.hs test/IRSpec.hs test/REPLSpec.hs test/LSPSpec.hs
git commit -m "fix: stop getAncestors at inheritance cycles (#21)"
```

---

### Task 1.4: Keywords must end at a word boundary (#20)

**Files:**
- Modify: `src/Parser.hs` (add `keyword`/`identChar`; use `keyword` in every `def-*`, `import`, `namespace`, `forall`, `exists`, `implies`, `iff`, `and`, `or`, `not` parser; `identifier` at line 166)
- Test: `test/ParserSpec.hs`

**Interfaces:**
- Produces: `keyword :: Text -> Parser Text` and `identChar :: Parser Char` in `Parser`. Task 1.5 uses both.

- [ ] **Step 1: Write the failing test**

Add to `test/ParserSpec.hs` (imports `Control.Monad (forM_)` and `qualified Data.Text as T` if missing):

```haskell
    describe "keyword boundaries (#20)" $
      forM_ ["orderedBy", "origin", "notifies", "android", "iffy", "impliesX", "forallX", "existsIn"] $ \name ->
        it ("parses a predicate named " ++ name) $ do
          let src = T.pack ("(forall (x) (implies (Order x) (" ++ name ++ " x x)))")
          case parse parseRegistry "t" src of
            Left err -> expectationFailure (errorBundlePretty err)
            Right reg -> axioms reg `shouldBe`
              [ForAll "x" (Implies (Predicate "Order" [Var "x"]) (Predicate name [Var "x", Var "x"]))]
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `stack test --ta '--match "#20"'`
Expected: FAIL for all eight, e.g. `unexpected 'd' expecting '('` for `orderedBy`.

- [ ] **Step 3: Implement**

In `src/Parser.hs`:

```haskell
identChar :: Parser Char
identChar = alphaNumChar <|> char '_' <|> char ':' <|> char '-'

-- | A reserved word that is not the prefix of a longer identifier.
keyword :: Text -> Parser Text
keyword w = lexeme (try (string w <* notFollowedBy identChar))

identifier :: Parser String
identifier = lexeme ((:) <$> (letterChar <|> char '_') <*> many identChar)
```

Replace each `symbol "def-concept"`, `symbol "def-property"`, `symbol "def-relation"`, `symbol "def-axiom"`, `symbol "import"` and `symbol "namespace"` with `keyword "..."`. Replace each `try (symbol "forall")` (and `exists`, `implies`, `iff`, `and`, `or`, `not`) with `keyword "..."`.

- [ ] **Step 4: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass, including `ExamplesSpec` and `StandardLibrarySpec`, which parse every shipped `.logic` file.

```bash
git add src/Parser.hs test/ParserSpec.hs
git commit -m "fix(parser): require a word boundary after DSL keywords (#20)"
```

---

### Task 1.5: Malformed `def-*` forms are parse errors (#23)

**Files:**
- Modify: `src/Parser.hs` (`parseItem`, lines 40–49; `parsePredicate`, lines 153–157; imports)
- Test: `test/ParserSpec.hs`

**Interfaces:**
- Consumes: `keyword` from Task 1.4.
- Produces: `reservedWords :: [String]` in `Parser`.

- [ ] **Step 1: Write the failing test**

```haskell
    describe "malformed definitions (#23)" $ do
      let bad = [ ("(def-concpt Typo)", "def-concpt")
                , ("(def-property capacity Tank)", "def-property")
                , ("(def-relation ownedBy Tank)", "def-relation")
                ]
      forM_ bad $ \(src, needle) ->
        it ("rejects " ++ src) $
          case parse parseRegistry "t" (T.pack ("(def-concept Tank)\n" ++ src)) of
            Left err -> errorBundlePretty err `shouldContain` "2:"
            Right reg -> expectationFailure ("parsed as " ++ show (axioms reg) ++ " (" ++ needle ++ ")")
      it "still parses a valid axiom" $
        parse parseRegistry "t" (T.pack "(forall (x) (implies (Tank x) (gt capacity 1)))") `shouldSatisfy` either (const False) (const True)
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `stack test --ta '--match "#23"'`
Expected: 3 FAIL with `parsed as [Predicate "def-..." ...]`.

- [ ] **Step 3: Implement**

Add imports `Control.Monad (when)` and `Data.List (isPrefixOf)`. Remove the `try` wrappers in `parseItem`: each alternative starts with a `keyword`, which consumes nothing when it fails, so a failure after the keyword is now reported instead of silently falling through:

```haskell
parseItem :: Parser Item
parseItem = parens (
        parseDefConcept <|>
        parseDefProperty <|>
        parseDefRelation <|>
        parseImport <|>
        parseNamespace <|>
        parseDefAxiom <|>
        (IAxiom <$> parseFOL)
    )

reservedWords :: [String]
reservedWords = ["forall", "exists", "implies", "iff", "and", "or", "not", "import", "namespace"]

parsePredicate :: Parser FOL
parsePredicate = do
    o <- getOffset
    op <- identifier
    when ("def-" `isPrefixOf` op || op `elem` reservedWords) $ do
        setOffset o
        fail ("unknown form '" ++ op ++ "'")
    args <- many parseTerm
    return $ Predicate op args
```

- [ ] **Step 4: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass. If a shipped `.logic` file fails `ExamplesSpec` or `StandardLibrarySpec`, it contained a malformed form that used to be dropped silently. Fix that file in this commit and list it in the PR.

```bash
git add src/Parser.hs test/ParserSpec.hs
git commit -m "fix(parser): report malformed def-* forms instead of parsing them as axioms (#23)"
```

---

### Task 1.6: Standard library is found from any directory (#29)

**Files:**
- Modify: `package.yaml` (add top-level `data-files`)
- Modify: `src/Loader.hs` (`loadRegistryWithImports`, lines 19–23; new `stdlibSearchPaths`, `loadRegistryWithLibPaths`)
- Modify: `src/Main.hs` (new `--lib-path` option)
- Test: `test/ImportSpec.hs`, `test/MainSpec.hs`

**Interfaces:**
- Produces (exported from `Loader`):
  - `stdlibSearchPaths :: IO [FilePath]`, which returns the existing directories from `$ONTOLOGIC_PATH`, `<exe>/../ontologic-lib`, `<exe>/ontologic-lib`, `<datadir>/ontologic-lib` and `./ontologic-lib`, in that order
  - `loadRegistryWithLibPaths :: [FilePath] -> FilePath -> IO (Either String Registry)`
  - `loadRegistryWithImports :: FilePath -> IO (Either String Registry)`, same signature, now equal to `loadRegistryWithLibPaths []`
- The current directory `.` is no longer a search path. The importing file's own directory still comes first.

- [ ] **Step 1: Write failing tests**

In `test/ImportSpec.hs` (imports `System.Directory (getTemporaryDirectory, createDirectoryIfMissing, withCurrentDirectory, getCurrentDirectory)`, `System.FilePath ((</>))`, `System.Environment (setEnv, unsetEnv)`, `Control.Exception (bracket_)`):

```haskell
    describe "standard library lookup (#29)" $ do
      it "resolves a stdlib import from another directory via ONTOLOGIC_PATH" $ do
        repo <- getCurrentDirectory
        tmp <- (</> "ontologic-import-29") <$> getTemporaryDirectory
        createDirectoryIfMissing True tmp
        writeFile (tmp </> "pump.logic") "(import \"bfo_2020.logic\")\n(def-concept Pump bfo:Process)\n"
        res <- bracket_ (setEnv "ONTOLOGIC_PATH" (repo </> "ontologic-lib")) (unsetEnv "ONTOLOGIC_PATH") $
                 withCurrentDirectory tmp (loadRegistryWithImports "pump.logic")
        either expectationFailure (\reg -> lookup "Pump" (concepts reg) `shouldBe` Just (Just "bfo:Process")) res

      it "does not let the current directory shadow a stdlib import" $ do
        repo <- getCurrentDirectory
        tmp <- (</> "ontologic-shadow-29") <$> getTemporaryDirectory
        createDirectoryIfMissing True (tmp </> "sub")
        writeFile (tmp </> "bfo_2020.logic") "(def-concept Shadow)\n"
        writeFile (tmp </> "sub" </> "m.logic") "(import \"bfo_2020.logic\")\n"
        res <- withCurrentDirectory tmp (loadRegistryWithLibPaths [repo </> "ontologic-lib"] "sub/m.logic")
        either expectationFailure (\reg -> lookup "Shadow" (concepts reg) `shouldBe` Nothing) res
```

In `test/MainSpec.hs`:

```haskell
    it "accepts --lib-path for stdlib imports (#29)" $ do
      tmp <- (</> "ontologic-libpath-29") <$> getTemporaryDirectory
      createDirectoryIfMissing True tmp
      writeFile (tmp </> "pump.logic") "(import \"bfo_2020.logic\")\n(def-concept Pump bfo:Process)\n"
      repo <- getCurrentDirectory
      (exitCode, stdout, _) <- readProcessWithExitCode "stack"
        ["exec", "ontologic-exe", "--", "-i", tmp </> "pump.logic", "-t", "lint", "--lib-path", repo </> "ontologic-lib"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Logic Validated successfully"
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#29"'`
Expected: compile error, since `loadRegistryWithLibPaths` doesn't exist and `--lib-path` isn't accepted.

- [ ] **Step 3: Implement**

`package.yaml`, top level (next to `dependencies:`):

```yaml
data-files:
- ontologic-lib/*.logic
```

`src/Loader.hs` (export the new functions; imports `System.Environment (lookupEnv, getExecutablePath)`, `System.FilePath (splitSearchPath)`, `Control.Monad (filterM)`, `Paths_ontologic (getDataDir)`):

```haskell
-- | Standard-library directories that exist, highest priority first.
stdlibSearchPaths :: IO [FilePath]
stdlibSearchPaths = do
    envPaths <- maybe [] splitSearchPath <$> lookupEnv "ONTOLOGIC_PATH"
    exeDir <- takeDirectory <$> getExecutablePath
    dataDir <- getDataDir
    filterM doesDirectoryExist $
        envPaths ++
        [ exeDir </> ".." </> "ontologic-lib"   -- release layout: bin/ontologic + ontologic-lib/
        , exeDir </> "ontologic-lib"
        , dataDir </> "ontologic-lib"            -- cabal/stack install
        , "ontologic-lib"                        -- running from a source checkout
        ]

-- | Load a .logic file and its transitive imports using the default library paths.
loadRegistryWithImports :: FilePath -> IO (Either String Registry)
loadRegistryWithImports = loadRegistryWithLibPaths []

-- | Like 'loadRegistryWithImports', searching the given directories before the defaults.
loadRegistryWithLibPaths :: [FilePath] -> FilePath -> IO (Either String Registry)
loadRegistryWithLibPaths extra rootFile = do
    defaults <- stdlibSearchPaths
    loadRegistryWithImportsFromSearchPaths (extra ++ defaults) rootFile
```

Remove the old `doesDirectoryExist "ontologic-lib"` code. hpack adds `Paths_ontologic` automatically. Run `stack build` once so `ontologic.cabal` is regenerated, and commit it.

`src/Main.hs`: add `libPaths :: [String]` to `Args` and to the parser:

```haskell
      <*> many (strOption (long "lib-path" <> metavar "DIR" <> help "Extra directory searched for imports (repeatable; also $ONTOLOGIC_PATH)"))
```

Then call `loadRegistryWithLibPaths (libPaths args) inpFile` in place of `loadRegistryWithImports inpFile`.

- [ ] **Step 4: Check the release layout**

`scripts/package_release.sh` copies the binary to `<dist>/bin/ontologic` and the library to `<dist>/ontologic-lib/`, which is the `<exe>/../ontologic-lib` case. Run `bash scripts/package_release.sh`, then from `/tmp`, `<dist>/bin/ontologic -i /tmp/ontologic-import-29/pump.logic -t lint`. Expected: `✅ Logic Validated successfully.`

- [ ] **Step 5: Run the tests and commit**

Run: `stack build && stack test --ghc-options="-Wall -Werror"`
Expected: all pass.

```bash
git add package.yaml ontologic.cabal src/Loader.hs src/Main.hs test/ImportSpec.hs test/MainSpec.hs
git commit -m "fix(loader): find the standard library from any directory; add --lib-path (#29)"
```

Also add a sentence about `ONTOLOGIC_PATH` and `--lib-path` to the stdlib section of `HOW_TO_USE.md`.

**Wave 1 gate:** all Wave 1 PRs merged, CI green on `main`, milestone `Wave 1: Foundations` shows 0 open issues.

---
# Wave 2: Semantics & solver

Milestone `Wave 2: Semantics & solver`: #19, #17, #24, #18. Tasks 2.1–2.2 touch `OntoLogic.hs`, `IR.hs` and `Linter.hs`. Tasks 2.3–2.5 touch `Solver.hs` and `Emitters/SMT.hs`. The two tracks can run in parallel. #18 is split over two PRs: Task 2.4 says `Refs #18`, Task 2.5 says `Fixes #18`.

Expect generated output in `examples/` and the golden strings in emitter specs to change in this wave. Update each one on purpose and list them in the PR.

### Task 2.1: Only `(C v)` antecedents become field bounds (#19)

**Files:**
- Modify: `src/OntoLogic.hs` (`getLocalConstraints`, lines 167–181)
- Test: `test/InheritedBoundsSpec.hs` (new; Task 2.2 adds to it)

**Interfaces:**
- Produces: `getLocalConstraints :: Name -> [FOL] -> [(Name, String, String)]` (same signature). It returns bounds only from axioms shaped `(forall (v ...) (implies (C v) body))`, with `C == conceptName` and `v` bound by an enclosing `forall`.

- [ ] **Step 1: Write the failing test**

Create `test/InheritedBoundsSpec.hs`:

```haskell
module InheritedBoundsSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import Linter (lintRegistry)
import IR

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

propConstraints :: Name -> Name -> Registry -> [BoundConstraint]
propConstraints cls prop reg =
    concat [ compConstraints p
           | c <- irClasses (compileRegistry reg), compClassName c == cls
           , p <- compProperties c, compPropName p == prop ]

spec :: Spec
spec = do
  describe "conjunctive antecedents (#19)" $ do
    let reg = load $ unlines
          [ "(def-concept Tank) (def-concept Civil) (def-concept Military)"
          , "(def-property capacity Tank Integer)"
          , "(forall (x) (implies (and (Tank x) (Civil x)) (lt capacity 50)))"
          , "(forall (x) (implies (and (Tank x) (Military x)) (gt capacity 100)))"
          ]
    it "lints cleanly" $ lintRegistry reg `shouldBe` []
    it "puts no conditional bound on Tank.capacity" $ propConstraints "Tank" "capacity" reg `shouldBe` []
    it "reports both axioms as unmapped" $ length (irUnmappedAxioms (compileRegistry reg)) `shouldBe` 2
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `stack test --ta '--match "#19"'`
Expected: `lints cleanly` FAILS with `Cross-axiom contradiction on Tank.capacity ...`. `puts no conditional bound` FAILS as well.

- [ ] **Step 3: Implement**

```haskell
getLocalConstraints :: Name -> [FOL] -> [(Name, String, String)]
getLocalConstraints conceptName = concatMap (extract [])
  where
    -- Only (forall (v) (implies (C v) body)) with C == conceptName and v bound yields bounds;
    -- conjunctive antecedents apply to a subset and stay in irUnmappedAxioms.
    extract bound (ForAll v body) = extract (v : bound) body
    extract bound (Implies (Predicate name [Var x]) body)
        | name == conceptName && x `elem` bound = extractSimplePredicates body
    extract _ _ = []

    extractSimplePredicates (Predicate op [Var prop, Constant val]) = [(prop, op, val)]
    extractSimplePredicates (And p1 p2) = extractSimplePredicates p1 ++ extractSimplePredicates p2
    extractSimplePredicates _ = []
```

- [ ] **Step 4: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass. If an example or stdlib spec loses a bound, check whether that bound came from an `and` antecedent (the bug) or from an unquantified `implies`. Only the `and` case should change.

```bash
git add src/OntoLogic.hs test/InheritedBoundsSpec.hs
git commit -m "fix: only simple (C v) antecedents become field bounds (#19)"
```

---

### Task 2.2: Subclasses inherit ancestor bounds (#17)

**Files:**
- Modify: `src/OntoLogic.hs` (new `getInheritedConstraints`)
- Modify: `src/IR.hs` (`compileClass` lines 63–86, `resolveProperty` lines 109–132)
- Modify: `src/Linter.hs` (`checkConceptAxioms` and `reportCrossContradictions`, lines 169–181)
- Test: `test/InheritedBoundsSpec.hs`

**Interfaces:**
- Consumes: the cycle-safe `getAncestors` from Task 1.3, and `getLocalConstraints` from Task 2.1.
- Produces: `getInheritedConstraints :: Name -> [(Name, Maybe Name)] -> [FOL] -> [(Name, String, String)]`, which returns own bounds first, then the parent's, and so on. After this task, `compConstraints` on a `CompiledProperty` holds the merged bounds (own plus ancestors). An inherited property still appears on a subclass only when the subclass adds a bound of its own.

- [ ] **Step 1: Write failing tests**

Append to `test/InheritedBoundsSpec.hs` (add imports `Solver (findUnsatConceptsWith, Prover(..))` and `Emitters.Java (emitJavaWithPackage)`):

```haskell
  describe "bounds inherited from superclasses (#17)" $ do
    let reg = load $ unlines
          [ "(def-concept Vessel)"
          , "(def-concept Tank Vessel)"
          , "(def-property capacity Vessel Integer)"
          , "(forall (x) (implies (Vessel x) (gt capacity 10)))"
          , "(forall (x) (implies (Tank x) (lt capacity 5)))"
          ]
    it "reports the cross-level contradiction in lint" $
      lintRegistry reg `shouldSatisfy` any ("Cross-axiom contradiction on Tank.capacity" `isInfixOf`)
    it "merges parent bounds into the subclass" $
      propConstraints "Tank" "capacity" reg `shouldBe`
        [BoundConstraint OpLt (VInt 5), BoundConstraint OpGt (VInt 10)]
    it "finds Tank unsatisfiable" $
      findUnsatConceptsWith Z3 reg `shouldReturn` Right ["Tank"]
    it "emits the parent's bound on the Java subclass" $ do
      let Just tank = lookup "Tank" (emitJavaWithPackage "p" reg)
      tank `shouldContain` "@Max(4)"
      tank `shouldContain` "@Min(11)"
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#17"'`
Expected: all four FAIL. Lint passes, the constraints are only `[lt 5]`, `findUnsat` returns `Right []`, and there's no `@Min(11)`.

- [ ] **Step 3: Implement**

`src/OntoLogic.hs`:

```haskell
-- | Bounds that apply to a concept: its own, then each ancestor's, nearest first.
getInheritedConstraints :: Name -> [(Name, Maybe Name)] -> [FOL] -> [(Name, String, String)]
getInheritedConstraints conceptName conceptsList axs =
    concatMap (`getLocalConstraints` axs) (conceptName : getAncestors conceptName conceptsList)
```

`src/IR.hs`, in `compileClass` replace the first two `let` bindings and the `resolvedProps` line:

```haskell
    let localMap  = groupConstraints (getLocalConstraints name axs)
        mergedMap = groupConstraints (getInheritedConstraints name conceptsList axs)

        -- Preserves original definition order from allProps
        resolvedProps = concatMap (resolveProperty name conceptsList localMap mergedMap) allProps
```

and replace `resolveProperty`:

```haskell
-- | localMap decides whether a subclass re-declares an inherited property (it adds its own bound);
-- mergedMap supplies the bounds that apply (own + ancestors).
resolveProperty :: Name -> [(Name, Maybe Name)] -> Map.Map Name [BoundConstraint] -> Map.Map Name [BoundConstraint] -> Property -> [CompiledProperty]
resolveProperty name conceptsList localMap mergedMap p
    | domain p == name =
        [ CompiledProperty
            { compPropName = propName p
            , compPropType = rangeType p
            , compConstraints = Map.findWithDefault [] (propName p) mergedMap
            , compIsInherited = False
            , compOriginClass = domain p
            }
        ]
    | isInherited name p conceptsList && Map.member (propName p) localMap && rangeType p `elem` [PTInteger, PTFloat, PTDouble] =
        [ CompiledProperty
            { compPropName = propName p
            , compPropType = rangeType p
            , compConstraints = Map.findWithDefault [] (propName p) mergedMap
            , compIsInherited = True
            , compOriginClass = domain p
            }
        ]
    | otherwise = []
```

`src/Linter.hs`, replace `checkConceptAxioms` and delete `reportCrossContradictions`:

```haskell
-- | Contradictions between a concept's own bounds and the bounds it has or inherits.
checkConceptAxioms :: Registry -> Name -> [String]
checkConceptAxioms reg conceptName =
    let local = getLocalConstraints conceptName (axioms reg)
        allC  = getInheritedConstraints conceptName (concepts reg) (axioms reg)
    in nubOrd
        [ "Cross-axiom contradiction on " ++ conceptName ++ "." ++ p1 ++ ": " ++ o1 ++ " " ++ v1 ++ " and " ++ o2 ++ " " ++ v2
        | (p1, o1, v1) <- local
        , (p2, o2, v2) <- allC
        , p1 == p2
        , evalPairContradiction (o1, v1) (o2, v2) || evalPairContradiction (o2, v2) (o1, v1)
        ]
  where
    nubOrd = Set.toList . Set.fromList
```

(`Linter.hs` already imports `Data.Set as Set`.) A contradiction that lives entirely in a parent is reported once, on the parent. Children only report pairs that involve one of their own bounds.

- [ ] **Step 4: Run the tests**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: the new cases pass. Existing Java, Python, JSON Schema and SHACL golden strings for subclasses that add a bound will now also show the parent's bound. Update them, then check each change against the rule "subclass enforces parent bounds too."

- [ ] **Step 5: Commit**

```bash
git add src/OntoLogic.hs src/IR.hs src/Linter.hs test/InheritedBoundsSpec.hs test/*Spec.hs
git commit -m "fix: merge ancestor bounds into subclasses for lint, :unsat and emitters (#17)"
```

---

### Task 2.3: One SMT emitter with valid numerals and relations (#24)

**Files:**
- Modify: `src/Emitters/SMT.hs` (whole module)
- Modify: `src/Solver.hs` (delete the copied emitter, lines 215–288; `emitSMTBase` calls `Emitters.SMT`)
- Test: `test/SMTSpec.hs`

**Interfaces:**
- Produces (exported from `Emitters.SMT`):
  - `emitSMT :: Registry -> String` (unchanged)
  - `emitSMTDeclarations :: Registry -> String` (sort, concept constants, hierarchy, property bounds and relation facts; no `set-logic`, no `check-sat`)
  - `emitPropertyFunction :: String -> CompiledProperty -> String`
  - `smtNumeral :: PropertyType -> Value -> String` (plain decimals, negatives as `(- n)`)
  - `mapSmtType :: PropertyType -> String`
- `Solver.emitSMTBase :: Registry -> String` keeps its signature.

- [ ] **Step 1: Write failing tests**

Add to `test/SMTSpec.hs` (imports `System.Process (readProcessWithExitCode)`, `Data.List (isPrefixOf, isInfixOf)`, `Data.Text (pack)`, `Text.Megaparsec (parse, errorBundlePretty)`, `Parser (parseRegistry)`):

```haskell
    describe "valid SMT-LIB2 for real inputs (#24)" $ do
      let load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))
          accepts solver args smt = do
            (_, out, err) <- readProcessWithExitCode solver args smt
            (out ++ err) `shouldSatisfy` (\o -> "sat" `isPrefixOf` o && not ("error" `isInfixOf` o))
          small = load "(def-concept Vuln) (def-property epss Vuln Double) (forall (x) (implies (Vuln x) (lt epss 0.001)))"
          shared = load "(def-concept Engine) (def-concept Car) (def-concept Wheel) (def-relation partOf Engine Car) (def-relation partOf Wheel Car)"
          negative = load "(def-concept T) (def-property temp T Integer) (forall (x) (implies (T x) (gt temp -5)))"

      it "prints decimals without exponents" $
        emitSMT small `shouldContain` "(assert (< (Vuln_epss Vuln) 0.001))"
      it "prints negatives as (- n)" $
        emitSMT negative `shouldContain` "(assert (> (T_temp T) (- 5)))"
      it "declares a shared relation name once" $
        length (filter ("(declare-fun partOf" `isPrefixOf`) (lines (emitSMT shared))) `shouldBe` 1
      it "is accepted by z3" $ mapM_ (accepts "z3" ["-in"] . emitSMT) [small, shared, negative]
      it "is accepted by cvc5" $ mapM_ (accepts "cvc5" ["--lang=smt2", "-"] . emitSMT) [small, shared, negative]
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#24"'`
Expected: FAIL. The output contains `1.0e-3` and `-5`, and `partOf` is declared twice. z3 reports `unknown constant e-3`.

- [ ] **Step 3: Rewrite `src/Emitters/SMT.hs`**

```haskell
module Emitters.SMT
    ( emitSMT
    , emitSMTDeclarations
    , emitPropertyFunction
    , smtNumeral
    , mapSmtType
    ) where

import Data.List (nub)
import Numeric (showFFloat)
import OntoLogic
import IR

-- | Emit standards-compliant SMT-LIB2 logic definitions for Z3 / CVC5 theorem provers
emitSMT :: Registry -> String
emitSMT reg =
    "; SMT-LIB2 Logic Specification generated by OntoLogic\n" ++
    "(set-logic ALL)\n" ++
    "(set-option :produce-models true)\n\n" ++
    emitSMTDeclarations reg ++
    "; Satisfiability Check\n" ++
    "(check-sat)\n" ++
    "(get-model)\n"

-- | Sort, concept constants, hierarchy, property bounds and relation facts (no set-logic, no check-sat).
emitSMTDeclarations :: Registry -> String
emitSMTDeclarations reg =
    let modelIR = compileRegistry reg
        classes = irClasses modelIR
    in "; Sort declarations\n" ++
       "(declare-sort Entity 0)\n\n" ++
       "; Entity Concept Constants\n" ++
       concatMap emitConceptConst classes ++ "\n" ++
       "; Subclass Hierarchy\n" ++
       "(declare-fun subClassOf (Entity Entity) Bool)\n" ++
       concatMap emitHierarchy classes ++ "\n" ++
       "; Property Functions and Bound Assertions\n" ++
       concatMap emitClassProperties classes ++ "\n" ++
       "; Relational Assertions\n" ++
       emitRelations (irRelations modelIR) ++ "\n"

emitConceptConst :: CompiledClass -> String
emitConceptConst cls =
    "(declare-const " ++ sanitizeIdent (compClassName cls) ++ " Entity)\n"

emitHierarchy :: CompiledClass -> String
emitHierarchy cls =
    case compParentClass cls of
        Just p  -> "(assert (subClassOf " ++ sanitizeIdent (compClassName cls) ++ " " ++ sanitizeIdent p ++ "))\n"
        Nothing -> ""

emitClassProperties :: CompiledClass -> String
emitClassProperties cls =
    concatMap (emitPropertyFunction (sanitizeIdent (compClassName cls))) (compProperties cls)

emitPropertyFunction :: String -> CompiledProperty -> String
emitPropertyFunction cName p =
    let fName = cName ++ "_" ++ sanitizeIdent (compPropName p)
        pType = compPropType p
        decl = "(declare-fun " ++ fName ++ " (Entity) " ++ mapSmtType pType ++ ")\n"
    in decl ++ concatMap (emitPropertyAssertion cName fName pType) (compConstraints p)

emitPropertyAssertion :: String -> String -> PropertyType -> BoundConstraint -> String
emitPropertyAssertion cName fName pType (BoundConstraint op val) =
    let app = "(" ++ fName ++ " " ++ cName ++ ")"
        lit = smtNumeral pType val
    in case op of
        OpGt  -> "(assert (> " ++ app ++ " " ++ lit ++ "))\n"
        OpGte -> "(assert (>= " ++ app ++ " " ++ lit ++ "))\n"
        OpLt  -> "(assert (< " ++ app ++ " " ++ lit ++ "))\n"
        OpLte -> "(assert (<= " ++ app ++ " " ++ lit ++ "))\n"
        OpEq  -> "(assert (= " ++ app ++ " " ++ lit ++ "))\n"
        OpNe  -> "(assert (distinct " ++ app ++ " " ++ lit ++ "))\n"

-- | SMT-LIB2 numeral: plain decimal notation, reals keep a fraction, negatives as (- n).
smtNumeral :: PropertyType -> Value -> String
smtNumeral pType val =
    let isReal = pType `elem` [PTFloat, PTDouble]
        (negative, body) = case val of
            VInt n    -> (n < 0, show (abs n) ++ (if isReal then ".0" else ""))
            VDouble d -> (d < 0, showFFloat Nothing (abs d) "")
            other     -> (False, valueToString other)
    in if negative then "(- " ++ body ++ ")" else body

-- | Declare each relation name once; assert one fact per domain/range pair.
emitRelations :: [CompiledRelation] -> String
emitRelations rels =
    concatMap declare (nub (map (sanitizeIdent . compRelName) rels)) ++
    concatMap assertFact rels
  where
    declare rName = "(declare-fun " ++ rName ++ " (Entity Entity) Bool)\n"
    assertFact rel =
        "; Relation: " ++ compRelName rel ++ "\n" ++
        "(assert (" ++ sanitizeIdent (compRelName rel) ++ " " ++ sanitizeIdent (compRelDomain rel) ++ " " ++ sanitizeIdent (compRelRange rel) ++ "))\n"

mapSmtType :: PropertyType -> String
mapSmtType PTInteger    = "Int"
mapSmtType PTFloat      = "Real"
mapSmtType PTDouble     = "Real"
mapSmtType PTBoolean    = "Bool"
mapSmtType PTString     = "String"
mapSmtType (PTCustom _) = "Entity"
```

- [ ] **Step 4: Make `Solver` reuse it**

In `src/Solver.hs`, delete `emitConceptConst`, `emitHierarchy`, `emitClassProperties`, `emitPropertyFunction`, `emitPropertyAssertion`, `emitRelationDeclaration` and `mapSmtType`. Add `import Emitters.SMT (emitSMTDeclarations, emitPropertyFunction)` and replace `emitSMTBase`:

```haskell
-- | Emit base SMT declarations without check-sat
emitSMTBase :: Registry -> String
emitSMTBase reg =
    "; SMT-LIB2 Base Declarations generated by OntoLogic Solver\n" ++
    "(set-logic ALL)\n\n" ++
    emitSMTDeclarations reg
```

- [ ] **Step 5: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass. `grep -n "declare-fun" src/Solver.hs` now shows only the `subClassOf`-free lines used by the per-class check (no emitter copy).

```bash
git add src/Emitters/SMT.hs src/Solver.hs test/SMTSpec.hs
git commit -m "fix(smt): one emitter; plain decimal and negative numerals; declare relations once (#24)"
```

---

### Task 2.4: FOL-to-SMT translator (#18, part 1)

This task adds the translator as a pure module with its own tests. Task 2.5 wires it into the solver.

**Files:**
- Create: `src/FOLTheory.hs`
- Test: `test/FOLTheorySpec.hs` (new)

**Interfaces:**
- Consumes: `smtNumeral` and `mapSmtType` from Task 2.3.
- Produces (module `FOLTheory`):
  - `data Theory = Theory { theoryDecls :: String, theoryAxioms :: [String], theorySkipped :: [(FOL, String)] } deriving (Show, Eq)`
  - `buildTheory :: Registry -> Theory`. It assumes the caller has already emitted `(declare-sort Entity 0)`.
  - `theoryText :: Theory -> String` (declarations followed by axioms)
  - `conceptPred :: Name -> String` (`"is_" ++ sanitizeIdent name`)
- Encoding: concept `C` becomes `(is_C x)`, relation `r` becomes `(rel_r a b)`, and property `p` becomes `(prop_p x)`. `(op p v)` inside a quantifier compares `(prop_p <innermost variable>)`. Variables become `v_<name>`. Declared parents become `(forall ((x Entity)) (=> (is_C x) (is_P x)))`.

- [ ] **Step 1: Write failing tests**

Create `test/FOLTheorySpec.hs`:

```haskell
module FOLTheorySpec (spec) where

import Test.Hspec
import Data.List (isPrefixOf)
import Data.Text (pack)
import System.Process (readProcessWithExitCode)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import FOLTheory

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

spec :: Spec
spec = describe "FOL theory translation (#18)" $ do
    let dog = load "(def-concept Animal) (def-concept Dog) (forall (x) (implies (Dog x) (Animal x)))"
        tank = load "(def-concept Vessel) (def-concept Tank Vessel) (def-property capacity Vessel Integer) (forall (x) (implies (Tank x) (lt capacity 5)))"

    it "translates concept implications" $
        theoryAxioms (buildTheory dog) `shouldBe`
            ["(assert (forall ((v_x Entity)) (=> (is_Dog v_x) (is_Animal v_x))))\n"]

    it "translates bounds against the quantified variable" $
        theoryAxioms (buildTheory tank) `shouldBe`
            ["(assert (forall ((v_x Entity)) (=> (is_Tank v_x) (< (prop_capacity v_x) 5))))\n"]

    it "turns declared parents into implications" $
        theoryDecls (buildTheory tank) `shouldContain`
            "(assert (forall ((x Entity)) (=> (is_Tank x) (is_Vessel x))))"

    it "reports axioms it cannot translate" $ do
        let reg = load "(def-concept A) (definedIn \"a\" \"b\")"
        map snd (theorySkipped (buildTheory reg)) `shouldBe` ["unsupported predicate definedIn/2"]

    it "produces SMT that z3 accepts" $ do
        let smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory tank) ++ "(check-sat)\n"
        (_, out, _) <- readProcessWithExitCode "z3" ["-in"] smt
        out `shouldSatisfy` ("sat" `isPrefixOf`)
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#18"'`
Expected: compile error, module `FOLTheory` not found.

- [ ] **Step 3: Create `src/FOLTheory.hs`**

```haskell
-- | Instance-level SMT-LIB2 encoding of an ontology's first-order axioms.
--
--   concept C       -> (declare-fun is_C (Entity) Bool)
--   def-concept C P -> (assert (forall ((x Entity)) (=> (is_C x) (is_P x))))
--   relation r      -> (declare-fun rel_r (Entity Entity) Bool)
--   property p : T  -> (declare-fun prop_p (Entity) T)
--   (op p v) inside a quantifier compares (prop_p <innermost variable>) with v.
--
-- The caller must emit (declare-sort Entity 0) first.
module FOLTheory
    ( Theory(..)
    , buildTheory
    , theoryText
    , conceptPred
    ) where

import Data.List (nub)
import qualified Data.Map as Map
import OntoLogic
import Emitters.SMT (smtNumeral, mapSmtType)

data Theory = Theory
    { theoryDecls   :: String            -- ^ declarations and hierarchy assertions
    , theoryAxioms  :: [String]          -- ^ one (assert ...) line per translated axiom
    , theorySkipped :: [(FOL, String)]   -- ^ axioms not sent to the solver, with the reason
    } deriving (Show, Eq)

data Env = Env
    { envConcepts  :: [Name]
    , envRelations :: [Name]
    , envProps     :: Map.Map Name PropertyType   -- ^ properties with a single consistent type
    }

theoryText :: Theory -> String
theoryText t = theoryDecls t ++ concat (theoryAxioms t)

conceptPred :: Name -> String
conceptPred c = "is_" ++ sanitizeIdent c

relPred :: Name -> String
relPred r = "rel_" ++ sanitizeIdent r

propFun :: Name -> String
propFun p = "prop_" ++ sanitizeIdent p

varName :: Name -> String
varName v = "v_" ++ sanitizeIdent v

buildTheory :: Registry -> Theory
buildTheory reg =
    let conceptNames = nub (map fst (concepts reg))
        relNames = nub (map relName (relations reg))
        typed = Map.fromListWith (\a b -> if a == b then Just a else Nothing)
                    [ (propName p, Just (rangeType p)) | p <- properties reg ]
        env = Env conceptNames relNames (Map.mapMaybe id typed)
        decls =
            concatMap (\c -> "(declare-fun " ++ conceptPred c ++ " (Entity) Bool)\n") conceptNames ++
            concatMap (\r -> "(declare-fun " ++ relPred r ++ " (Entity Entity) Bool)\n") relNames ++
            concatMap (\(p, t) -> "(declare-fun " ++ propFun p ++ " (Entity) " ++ mapSmtType t ++ ")\n") (Map.toList (envProps env)) ++
            concat [ "(assert (forall ((x Entity)) (=> (" ++ conceptPred c ++ " x) (" ++ conceptPred p ++ " x))))\n"
                   | (c, Just p) <- nub (concepts reg), p `elem` conceptNames ]
        results = [ (ax, translate env [] ax) | ax <- axioms reg ]
    in Theory
        { theoryDecls = decls
        , theoryAxioms = [ "(assert " ++ s ++ ")\n" | (_, Right s) <- results ]
        , theorySkipped = [ (ax, e) | (ax, Left e) <- results ]
        }

translate :: Env -> [Name] -> FOL -> Either String String
translate env bound f = case f of
    ForAll v b  -> quant "forall" v b
    Exists v b  -> quant "exists" v b
    And a b     -> bin "and" a b
    Or a b      -> bin "or" a b
    Implies a b -> bin "=>" a b
    Iff a b     -> bin "=" a b
    Not a       -> (\s -> "(not " ++ s ++ ")") <$> translate env bound a
    Predicate name args -> predicate name args
  where
    quant q v b = (\s -> "(" ++ q ++ " ((" ++ varName v ++ " Entity)) " ++ s ++ ")") <$> translate env (v : bound) b
    bin op a b = (\x y -> "(" ++ op ++ " " ++ x ++ " " ++ y ++ ")") <$> translate env bound a <*> translate env bound b

    predicate name [Var v]
        | name `elem` envConcepts env && v `elem` bound = Right ("(" ++ conceptPred name ++ " " ++ varName v ++ ")")
    predicate name [Var a, Var b]
        | name `elem` envRelations env && a `elem` bound && b `elem` bound =
            Right ("(" ++ relPred name ++ " " ++ varName a ++ " " ++ varName b ++ ")")
    predicate opStr [Var prop, Constant val]
        | Just op <- parseCompOp opStr = comparison op prop val
    predicate name args = Left ("unsupported predicate " ++ name ++ "/" ++ show (length args))

    comparison op prop val = case (bound, Map.lookup prop (envProps env)) of
        ([], _) -> Left ("comparison on " ++ prop ++ " outside any quantifier")
        (_, Nothing) -> Left ("unknown or ambiguously typed property " ++ prop)
        (subject : _, Just pType)
            | op `notElem` [OpEq, OpNe] && pType `notElem` numeric ->
                Left ("ordering comparison on non-numeric property " ++ prop)
            | otherwise -> do
                lit <- literal pType (parseValue val)
                let app = "(" ++ propFun prop ++ " " ++ varName subject ++ ")"
                Right $ case op of
                    OpEq  -> "(= " ++ app ++ " " ++ lit ++ ")"
                    OpNe  -> "(not (= " ++ app ++ " " ++ lit ++ "))"
                    OpGt  -> "(> " ++ app ++ " " ++ lit ++ ")"
                    OpGte -> "(>= " ++ app ++ " " ++ lit ++ ")"
                    OpLt  -> "(< " ++ app ++ " " ++ lit ++ ")"
                    OpLte -> "(<= " ++ app ++ " " ++ lit ++ ")"

    numeric = [PTInteger, PTFloat, PTDouble]

    literal pType v = case (pType, v) of
        (PTBoolean, VBool b) -> Right (if b then "true" else "false")
        (PTString, _)        -> Right (show (valueToString v))
        _ | pType `elem` numeric && isNumericValue v -> Right (smtNumeral pType v)
          | otherwise -> Left ("value " ++ valueToString v ++ " does not fit " ++ propertyTypeToString pType)
```

- [ ] **Step 4: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass.

```bash
git add src/FOLTheory.hs test/FOLTheorySpec.hs
git commit -m "feat(solver): translate FOL axioms to an instance-level SMT theory (#18)"
```

---

### Task 2.5: The solver uses the FOL theory (#18, part 2)

**Decision, resolved:** `--solve` reports **two** results instead of collapsing them into one.
1. **Consistency** — are the axioms satisfiable at all? No non-emptiness is asserted, so this catches a genuinely contradictory axiom set.
2. **Coherence** — which concepts can have no instance? This is the per-concept check, run in one solver process, and it names the offending concepts.

Asserting non-emptiness inside the consistency check would have made both questions one UNSAT answer that names nothing, which is exactly what makes the current `--solve` unhelpful. Reporting them separately keeps the diagnosis specific: `--solve` exits non-zero if either fails, and says which concepts are empty.

**Files:**
- Modify: `src/Solver.hs` (`proveSubsumptionWith`, `findUnsatConceptsWith`, `emitSMTForConsistency`; delete `checkSingleClassSatisfiability`; new export `untranslatedAxioms`)
- Modify: `src/Main.hs` (`runSolverCheck`), `src/REPL.hs` (`:solve` branch)
- Modify: `HOW_TO_USE.md` (solver section)
- Test: `test/SolverSpec.hs`, `test/MainSpec.hs`

**Interfaces:**
- Consumes: `buildTheory`, `theoryText`, `theorySkipped` and `conceptPred` from Task 2.4. The `Either String [String]` result of `findUnsatConceptsWith` comes from Task 0.3.
- Produces: `untranslatedAxioms :: Registry -> [(FOL, String)]` (exported from `Solver`). All existing exported signatures stay the same.

- [ ] **Step 1: Write failing tests**

Add to `test/SolverSpec.hs` (imports `Data.Text (pack)`, `Text.Megaparsec (parse, errorBundlePretty)`, `Parser (parseRegistry)`, `Loader (loadRegistryWithImports)`, `System.Timeout (timeout)`, `Data.Maybe (isJust)`):

```haskell
    describe "axioms reach the solver (#18)" $ do
        let load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))
        it "proves subsumption stated by an axiom" $ do
            let reg = load "(def-concept Animal) (def-concept Dog) (forall (x) (implies (Dog x) (Animal x)))"
            proveSubsumptionWith Z3 reg "Dog" "Animal" `shouldReturn` Subsumed
        it "finds a concept emptied by disjointness" $ do
            let reg = load $ unlines
                  [ "(def-concept A) (def-concept B) (def-concept C A)"
                  , "(forall (x) (implies (A x) (not (B x))))"
                  , "(forall (x) (implies (C x) (B x)))" ]
            findUnsatConceptsWith Z3 reg `shouldReturn` Right ["C"]
        it "reports consistency and coherence separately" $ do
            let reg = load "(def-concept A) (def-concept B) (def-concept C A) (forall (x) (implies (A x) (not (B x)))) (forall (x) (implies (C x) (B x)))"
            consistency <- checkConsistencyWith Z3 reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)  -- axioms alone are satisfiable
            findUnsatConceptsWith Z3 reg `shouldReturn` Right ["C"]                   -- but C is empty
        it "lists axioms it could not translate" $ do
            let reg = load "(def-concept A) (definedIn \"a\" \"b\")"
            length (untranslatedAxioms reg) `shouldBe` 1
        it "checks bfo_2020 concepts in one solver run within 60s" $ do
            Right reg <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
            r <- timeout 60000000 (findUnsatConceptsWith Z3 reg)
            r `shouldSatisfy` maybe False (either (const False) (const True))
```

Add to `test/MainSpec.hs`:

```haskell
    it "reports axioms not sent to the solver (#18)" $ do
      tmp <- (</> "ontologic-18.logic") <$> getTemporaryDirectory
      writeFile tmp "(def-concept A)\n(definedIn \"a\" \"b\")\n"
      (_, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", tmp, "--solve", "-p", "z3"] ""
      stdout `shouldContain` "not sent to the solver"
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#18"'`
Expected: `proves subsumption` FAILS with `NotSubsumed ...`, `finds a concept emptied` FAILS with `Right []`, and `untranslatedAxioms` doesn't compile.

- [ ] **Step 3: Implement in `src/Solver.hs`**

Add `import FOLTheory (buildTheory, theoryText, theorySkipped, conceptPred)` and `import Data.List (nub)`, and export `untranslatedAxioms`.

```haskell
-- | Axioms the SMT encoding leaves out, with the reason.
untranslatedAxioms :: Registry -> [(FOL, String)]
untranslatedAxioms = theorySkipped . buildTheory

-- | Emit SMT-LIB2 for consistency checking: class-level bounds plus the FOL theory.
-- Non-emptiness is NOT asserted here; that is the coherence check (findUnsatConceptsWith).
emitSMTForConsistency :: Registry -> String
emitSMTForConsistency reg =
    emitSMTBase reg ++
    "; First-order theory\n" ++ theoryText (buildTheory reg) ++
    "(check-sat)\n(get-model)\n"

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) with specified prover
proveSubsumptionWith :: Prover -> Registry -> String -> String -> IO SubsumptionResult
proveSubsumptionWith p reg child parent
    | not (null unknown) = return (ProofError ("Unknown concept(s): " ++ unwords unknown))
    | otherwise = do
        let smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory reg) ++
                  "; Negated goal: some " ++ child ++ " is not a " ++ parent ++ "\n" ++
                  "(assert (exists ((x Entity)) (and (" ++ conceptPred child ++ " x) (not (" ++ conceptPred parent ++ " x)))))\n" ++
                  "(check-sat)\n(get-model)\n"
        res <- runProver p smt
        return $ case res of
            Left err -> ProofError err
            Right out
                | "unsat" `isPrefixOf` trimStart out -> Subsumed
                | "sat" `isPrefixOf` trimStart out   -> NotSubsumed out
                | otherwise                          -> ProofError out
  where
    unknown = filter (`notElem` map fst (concepts reg)) [child, parent]

-- | Find all unsatisfiable concepts in one solver run; Left if the solver could not decide.
findUnsatConceptsWith :: Prover -> Registry -> IO (Either String [String])
findUnsatConceptsWith p reg = do
    let names = map compClassName (irClasses (compileRegistry reg))
        check c = "(push 1)\n(assert (exists ((x Entity)) (" ++ conceptPred c ++ " x)))\n(check-sat)\n(pop 1)\n"
        smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory reg) ++ concatMap check names
    res <- runProver p smt
    return $ do
        out <- res
        let verdicts = filter (`elem` ["sat", "unsat", "unknown"]) (map (filter (`notElem` (" \t\r" :: String))) (lines out))
        if length verdicts /= length names
            then Left ("Expected " ++ show (length names) ++ " solver answers, got " ++ show (length verdicts) ++ ":\n" ++ out)
            else case [ n | (n, "unknown") <- zip names verdicts ] of
                []       -> Right [ n | (n, "unsat") <- zip names verdicts ]
                unknowns -> Left ("Solver answered unknown for: " ++ unwords unknowns)
```

Delete `checkSingleClassSatisfiability` and the transitivity preamble. Drop the `Emitters.SMT (emitPropertyFunction)` import if it's now unused.

- [ ] **Step 4: Report consistency, coherence and skipped axioms in the CLI and REPL**

`--solve` now runs both checks. In `src/Main.hs`, after the consistency result is printed and before the exit, add the coherence pass:

```haskell
            -- Coherence: which concepts can have no instance at all?
            coh <- findUnsatConceptsWith prover reg
            coherenceCode <- case coh of
                Left err -> do
                    putStrLn ("⚠️  Concept coherence check could not run: " ++ err)
                    return (ExitFailure 2)
                Right [] -> do
                    putStrLn "✅ All concepts are satisfiable (0 empty concepts)."
                    return ExitSuccess
                Right empties -> do
                    putStrLn ("❌ Unsatisfiable / empty concept(s): " ++ unwords empties)
                    return (ExitFailure 1)
            exitWith (worst [solverExitCode res, coherenceCode])
```

with a helper in `Solver` so the precedence is stated once:

```haskell
-- | The most severe of several exit codes: failure beats unknown beats success.
worst :: [ExitCode] -> ExitCode
worst codes
    | ExitFailure 1 `elem` codes = ExitFailure 1
    | ExitFailure 2 `elem` codes = ExitFailure 2
    | otherwise = ExitSuccess
```

Add the same two-part report to the REPL `:solve` output, and leave `:unsat` as the coherence-only command.

In `src/Main.hs` `runSolverCheck`, before `checkConsistencyWith`:

```haskell
            let skipped = untranslatedAxioms reg
            if null skipped then return () else do
                putStrLn ("⚠️  " ++ show (length skipped) ++ " axiom(s) were not sent to the solver:")
                mapM_ (\(ax, why) -> putStrLn ("   - " ++ show ax ++ " (" ++ why ++ ")")) skipped
```

and change the `Sat` line to:

```haskell
                Sat _ -> "✅ SMT Satisfiable (SAT) — Ontology is logically consistent" ++
                         (if null skipped then "." else " for the " ++ show (length (axioms reg) - length skipped) ++ " axioms checked.")
```

Apply the same warning block to the REPL `:solve` output, prepended to the returned string.

- [ ] **Step 5: Document**

In `HOW_TO_USE.md`'s solver section, add: "`--solve` reports two things. **Consistency**: whether the axioms can be satisfied at all. **Coherence**: which concepts can have no instance, given the axioms, bounds and hierarchy (the same check as the REPL's `:unsat`). It exits non-zero if either fails, `2` if the solver could not decide. Axioms the SMT encoding cannot express are listed first."

- [ ] **Step 6: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass, including the older solver tests (Car ⊑ Vehicle, the CVC5 cases, and `ContradictoryNode`). If the bfo_2020 timing test is close to 60 s, record the measured time in the PR.

```bash
git add src/Solver.hs src/Main.hs src/REPL.hs HOW_TO_USE.md test/SolverSpec.hs test/MainSpec.hs
git commit -m "fix(solver): send FOL axioms to the solver; one-process :unsat; report untranslated axioms (#18)"
```

**Wave 2 gate:** all Wave 2 PRs merged, CI green on `main`, milestone `Wave 2: Semantics & solver` shows 0 open issues.

---
# Wave 3: Emitters

Milestone `Wave 3: Emitters`: #25, #26, #33. The three tasks touch different emitter modules and can run in parallel, but all three change generated output, so rebase rather than merge in parallel if they both touch `examples/`.

### Task 3.1: Go, Rust, Python and Zod output compiles and keeps bounds (#25)

**Files:**
- Modify: `src/Emitters/Go.hs` (import line 13), `src/Emitters/Rust.hs` (`emitRust` 8–13, `emitRustStruct` 15–26, `emitRustValidation` 34–52, `emitPropValidation` 54–63), `src/Emitters/Python.hs` (whole module), `src/Emitters/TypeScript.hs` (`emitTypeScriptClass` 15–32)
- Modify: `.github/workflows/ci.yml` (print toolchain versions in `haskell-test`)
- Test: `test/CompileSpec.hs` (new), `test/TypeScriptSpec.hs`, `test/PythonSpec.hs`, `test/GoSpec.hs`, `test/RustSpec.hs`

**Interfaces:**
- Consumes: `compOriginClass` and the merged `compConstraints` from Task 2.2.
- Produces: no signature changes. `emitRust` now walks the parent chain to build `self.base.base.<field>` accessors; `emitGo` imports `fmt` only when a validator uses it; `emitPython` writes `from __future__ import annotations` and a `model_rebuild()` call per class; `emitTypeScript` includes inherited constrained properties in `.extend({...})`.

- [ ] **Step 1: Write the failing compile tests**

Create `test/CompileSpec.hs`:

```haskell
module CompileSpec (spec) where

import Test.Hspec
import Data.Text (pack)
import System.Directory (findExecutable, createDirectoryIfMissing, getTemporaryDirectory)
import System.Exit (ExitCode(..))
import System.FilePath ((</>))
import System.Process (readProcessWithExitCode)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import Loader (loadRegistryWithImports)
import Emitters.Go (emitGo)
import Emitters.Rust (emitRust)
import Emitters.Python (emitPython)

threeLevel :: Registry
threeLevel = either (error . errorBundlePretty) id . parse parseRegistry "t" . pack $ unlines
    [ "(def-concept Person)"
    , "(def-concept Vessel)"
    , "(def-concept Tank Vessel)"
    , "(def-concept FuelTank Tank)"
    , "(def-property capacity Vessel Integer)"
    , "(forall (x) (implies (FuelTank x) (gt capacity 100)))"
    , "(def-relation ownedBy Vessel Person)"
    , "(def-relation manages Person Person)"
    ]

-- Skip rather than fail when a toolchain is missing locally; CI has all of them.
withTool :: String -> (FilePath -> IO ()) -> IO ()
withTool exe act = findExecutable exe >>= maybe (pendingWith (exe ++ " not installed")) act

tmpDir :: String -> IO FilePath
tmpDir name = do
    base <- getTemporaryDirectory
    let dir = base </> ("ontologic-compile-" ++ name)
    createDirectoryIfMissing True dir
    return dir

spec :: Spec
spec = describe "generated code compiles (#25)" $ do
    it "go vet accepts the bfo_2020 Go output" $ withTool "go" $ \go -> do
        Right reg <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
        dir <- tmpDir "go"
        writeFile (dir </> "go.mod") "module models\n\ngo 1.21\n"
        writeFile (dir </> "models.go") (emitGo reg)
        (code, out, err) <- readProcessWithExitCode go ["vet", "./..."] ""
        (code, out ++ err) `shouldBe` (ExitSuccess, "")
      -- NB: readProcessWithExitCode runs in the test process's cwd; set it via the dir-aware
      -- helper below if your environment needs it (see Step 2).

    it "rustc compiles the three-level Rust output" $ withTool "rustc" $ \rustc -> do
        dir <- tmpDir "rust"
        writeFile (dir </> "models.rs") (emitRust threeLevel)
        (code, _, err) <- readProcessWithExitCode rustc
            ["--crate-type", "lib", "--edition", "2021", "-A", "dead_code", "-o", dir </> "libmodels.rlib", dir </> "models.rs"] ""
        (code, err) `shouldBe` (ExitSuccess, "")

    it "python imports the generated module" $ withTool "python3" $ \py -> do
        (havePydantic, _, _) <- readProcessWithExitCode py ["-c", "import pydantic"] ""
        if havePydantic /= ExitSuccess
            then pendingWith "pydantic not installed"
            else do
                dir <- tmpDir "python"
                writeFile (dir </> "models.py") (emitPython threeLevel)
                (code, _, err) <- readProcessWithExitCode py
                    ["-c", "import sys; sys.path.insert(0, '" ++ dir ++ "'); import models"] ""
                (code, err) `shouldBe` (ExitSuccess, "")
```

For the Go case, `go vet ./...` must run inside `dir`. Use `readCreateProcessWithExitCode (proc go ["vet", "./..."]) { cwd = Just dir }` from `System.Process` instead of `readProcessWithExitCode`, and import `proc`, `cwd` and `readCreateProcessWithExitCode`.

Add to `test/TypeScriptSpec.hs`:

```haskell
    it "keeps an inherited constrained property in the subclass schema (#25)" $ do
        let ts = emitTypeScript threeLevelReg   -- same registry as CompileSpec, inlined here
        ts `shouldContain` "export const FuelTankSchema = TankSchema.extend({"
        ts `shouldContain` "capacity: z.number().int().gt(100)"
```

And add the type-check to `test/CompileSpec.hs`. It needs `zod` and `typescript` from npm, so it installs them into a cache directory once and skips when `npm` is missing or offline:

```haskell
    it "tsc --noEmit accepts the Zod output" $ withTool "npm" $ \npm -> do
        dir <- tmpDir "ts"
        writeFile (dir </> "models.ts") (emitTypeScript threeLevel)
        writeFile (dir </> "package.json") "{\"name\":\"ontologic-ts-check\",\"private\":true,\"version\":\"0.0.0\"}"
        writeFile (dir </> "tsconfig.json") "{\"compilerOptions\":{\"strict\":true,\"target\":\"ES2020\",\"module\":\"ES2020\",\"moduleResolution\":\"node\",\"noEmit\":true}}"
        (instCode, _, instErr) <- runIn dir npm ["install", "--silent", "--no-audit", "--no-fund", "zod@3", "typescript@5"]
        if instCode /= ExitSuccess
            then pendingWith ("npm install failed (offline?): " ++ take 200 instErr)
            else do
                (code, out, err) <- runIn dir (dir </> "node_modules" </> ".bin" </> "tsc") ["--noEmit"]
                (code, out ++ err) `shouldBe` (ExitSuccess, "")
```

Add the shared helper next to `withTool`, since the Go case needs it too:

```haskell
-- | Run a command with the working directory set, which readProcessWithExitCode cannot do.
runIn :: FilePath -> FilePath -> [String] -> IO (ExitCode, String, String)
runIn dir exe args = readCreateProcessWithExitCode (proc exe args) { cwd = Just dir } ""
```

(import `System.Process (proc, cwd, readCreateProcessWithExitCode)`).

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#25"'`
Expected: Go fails with `"fmt" imported and not used`, Rust with `error[E0609]: no field 'capacity' on type 'Tank'`, Python with `NameError: name 'Person' is not defined`, and the Zod case with an empty `extend({})`.

- [ ] **Step 3: Fix the Go emitter**

```haskell
emitGo :: Registry -> String
emitGo reg =
    let modelIR = compileRegistry reg
        classes = irClasses modelIR
        usesFmt = any (not . null . compConstraints) (concatMap compProperties classes)
    in "// Code generated by OntoLogic. DO NOT EDIT.\n" ++
       "package models\n\n" ++
       (if usesFmt then "import \"fmt\"\n\n" else "") ++
       concatMap emitGoStruct classes
```

- [ ] **Step 4: Fix the Rust emitter**

Pass the parent chain down and compute one `base.` per level between the class and the property's origin:

```haskell
emitRust :: Registry -> String
emitRust reg =
    let modelIR = compileRegistry reg
        classes = irClasses modelIR
        parents = [ (compClassName c, compParentClass c) | c <- classes ]
    in "// Generated by OntoLogic - Rust Model Target\n\n" ++
       concatMap (emitRustStruct parents) classes

emitRustStruct :: [(Name, Maybe Name)] -> CompiledClass -> String
emitRustStruct parents cls =
    let cName = sanitizeIdent (compClassName cls)
        directProps = filter (not . compIsInherited) (compProperties cls)
        structDef =
            "#[derive(Debug, Clone, PartialEq)]\n" ++
            "pub struct " ++ cName ++ " {\n" ++
            maybe "" (\p -> "    pub base: " ++ sanitizeIdent p ++ ",\n") (compParentClass cls) ++
            concatMap emitRustField directProps ++
            "}\n\n"
    in structDef ++ emitRustValidation parents cls

-- | "self." plus one "base." per inheritance level between cls and the class that declares the property.
fieldAccessor :: [(Name, Maybe Name)] -> Name -> CompiledProperty -> String
fieldAccessor parents cls p = "self." ++ concat (replicate (walk cls 0) "base.") ++ toRustFieldName (compPropName p)
  where
    limit = length parents
    walk current n
        | current == compOriginClass p = n
        | n >= limit = n                            -- guard against inheritance cycles
        | otherwise = case lookup current parents of
            Just (Just parent) -> walk parent (n + 1)
            _                  -> n
```

In `emitRustValidation`, take `parents` as the first argument and build each check with `fieldAccessor parents (compClassName cls) p`:

```haskell
emitRustValidation :: [(Name, Maybe Name)] -> CompiledClass -> String
emitRustValidation parents cls =
    let cName = sanitizeIdent (compClassName cls)
        parentCheck = case compParentClass cls of
            Just _  -> "        if let Err(parent_errs) = self.base.validate() {\n            errors.extend(parent_errs);\n        }\n"
            Nothing -> ""
        propChecks = concatMap (emitPropValidation parents (compClassName cls)) (filter (not . null . compConstraints) (compProperties cls))
    in "impl " ++ cName ++ " {\n" ++
       "    pub fn validate(&self) -> Result<(), Vec<String>> {\n" ++
       "        let mut errors = Vec::new();\n" ++
       parentCheck ++
       propChecks ++
       "        if errors.is_empty() {\n            Ok(())\n        } else {\n            Err(errors)\n        }\n" ++
       "    }\n}\n\n"

emitPropValidation :: [(Name, Maybe Name)] -> Name -> CompiledProperty -> String
emitPropValidation parents cls p =
    concatMap (emitSingleBound (fieldAccessor parents cls p) (compPropName p) (compPropType p)) (compConstraints p)
```

- [ ] **Step 5: Fix the Python emitter**

```haskell
emitPython :: Registry -> String
emitPython reg =
    let classes = irClasses (compileRegistry reg)
    in "from __future__ import annotations\n\n" ++
       "from pydantic import BaseModel, Field\n\n" ++
       concatMap emitPythonClass classes ++
       -- resolve forward references between models declared in any order
       concatMap (\c -> sanitizeIdent (compClassName c) ++ ".model_rebuild()\n") classes
```

(`Optional` and `List` were imported but never used; dropping them is part of the fix.)

- [ ] **Step 6: Fix the TypeScript emitter**

In `emitTypeScriptClass`, emit every property the class carries, so an inherited property with a subclass bound overrides the parent field:

```haskell
emitTypeScriptClass :: CompiledClass -> String
emitTypeScriptClass cls =
    let cName = sanitizeIdent (compClassName cls)
        props = compProperties cls   -- direct plus inherited-with-constraints
        schemaDef = case compParentClass cls of
            Nothing ->
                "export const " ++ cName ++ "Schema = z.object({\n" ++ concatMap emitZodField props ++ "});\n\n"
            Just pName ->
                "export const " ++ cName ++ "Schema = " ++ sanitizeIdent pName ++ "Schema.extend({\n" ++ concatMap emitZodField props ++ "});\n\n"
        typeAlias = "export type " ++ cName ++ " = z.infer<typeof " ++ cName ++ "Schema>;\n\n"
    in schemaDef ++ typeAlias
```

- [ ] **Step 7: Make CI print the toolchains**

In `.github/workflows/ci.yml`, job `haskell-test`, after the Python step:

```yaml
      - name: Set up Node for the TypeScript check
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Toolchain versions for generated-code tests
        run: |
          go version
          rustc --version
          node --version && npm --version
          python3 -c "import pydantic; print('pydantic', pydantic.VERSION)"
```

If `go` or `rustc` is missing from the runner image, add `actions/setup-go@v5` and `dtolnay/rust-toolchain@stable` too, and say so in the PR. The four checks (`go vet`, `rustc`, `python -c import`, `tsc --noEmit`) must all run in CI, not skip: after the first green run, confirm in the log that none of them printed a PENDING line.

- [ ] **Step 8: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass. `GoSpec`, `RustSpec` and `PythonSpec` golden strings change (the missing `import "fmt"`, the new accessors, the new header and the `model_rebuild()` lines). Update them.

```bash
git add src/Emitters/Go.hs src/Emitters/Rust.hs src/Emitters/Python.hs src/Emitters/TypeScript.hs .github/workflows/ci.yml test/CompileSpec.hs test/GoSpec.hs test/RustSpec.hs test/PythonSpec.hs test/TypeScriptSpec.hs
git commit -m "fix(emitters): compilable Go/Rust/Python output; Zod keeps inherited bounds (#25)"
```

---

### Task 3.2: Graph, diagram and API-schema output loads (#26)

**Files:**
- Modify: `src/Emitters/Neo4j.hs`, `src/Emitters/Mermaid.hs`, `src/Emitters/D2.hs`, `src/Emitters/GraphQL.hs`, `src/Emitters/OpenApi.hs` (`emitOpenApiSchema`, lines 20–41)
- Create: `scripts/regenerate_examples.sh`
- Modify: the generated `examples/*.cypher`, `examples/*.mmd`, `examples/*.d2`
- Test: `test/Neo4jSpec.hs`, `test/MermaidSpec.hs`, `test/D2Spec.hs`, `test/GraphQLSpec.hs`, `test/OpenApiSpec.hs`

**Interfaces:**
- Produces: no signature changes. New helpers: `cypherLabel :: String -> String` (backticked, `` ` `` doubled) in `Emitters.Neo4j`; `d2Key :: String -> String` in `Emitters.D2`; `queryFieldNames :: [CompiledClass] -> [String]` (collision-free) and `inheritedProperties :: [CompiledClass] -> CompiledClass -> [CompiledProperty]` in `Emitters.GraphQL`.

- [ ] **Step 1: Write failing tests**

`test/Neo4jSpec.hs`:

```haskell
    describe "loadable Cypher (#26)" $ do
      let reg = load "(def-concept bfo:Entity) (def-concept bfo:Process bfo:Entity) (def-property dur bfo:Process Integer)"
          stmts = filter (not . null) (map trim (lines (emitCypher reg)))
      it "terminates every statement group with a semicolon" $
        filter (\l -> not ("//" `isPrefixOf` l)) stmts `shouldSatisfy` any (";" `isSuffixOf`)
      it "never re-binds n inside one statement" $
        emitCypher reg `shouldNotContain` "MERGE (n:OntologyClass {name: 'bfo:Process'})\nMERGE (n"
      it "backticks namespaced labels" $
        emitCypher reg `shouldContain` "FOR (n:`bfo:Process`)"
```

`test/MermaidSpec.hs`:

```haskell
    it "uses sanitized ids with the original name as the label (#26)" $ do
      let reg = load "(def-concept sys:InformationArtifact)"
      emitMermaid reg `shouldContain` "class sys_InformationArtifact[\"sys:InformationArtifact\"]"
      emitMermaid reg `shouldNotContain` "class sys:InformationArtifact"
```

`test/D2Spec.hs`:

```haskell
    it "quotes namespaced keys (#26)" $ do
      let reg = load "(def-concept sys:Foo) (def-concept sys:Bar sys:Foo)"
      emitD2 reg `shouldContain` "\"sys:Foo\": { shape: class }"
      emitD2 reg `shouldContain` "\"sys:Bar\" -> \"sys:Foo\""
```

`test/GraphQLSpec.hs`:

```haskell
    describe "valid SDL for the standard library (#26)" $ do
      it "gives every query field a unique name" $ do
        Right reg <- loadRegistryWithImports "ontologic-lib/ecosystem.logic"
        let fields = [ takeWhile (/= ':') (dropWhile (== ' ') l) | l <- lines (emitGraphQL reg), "  " `isPrefixOf` l, ": [" `isInfixOf` l ]
        length (nub fields) `shouldBe` length fields
      it "gives a subclass its parent's fields" $ do
        let reg = load "(def-concept A) (def-property a A String) (def-concept B A) (def-property b B String)"
        emitGraphQL reg `shouldContain` "type B {\n  b: String!\n  a: String!\n}"
```

`test/OpenApiSpec.hs`:

```haskell
    it "emits an empty properties object for a concept with no fields (#26)" $ do
      let reg = load "(def-concept Empty)"
      emitOpenApi reg `shouldContain` "      properties: {}"
```

(Each spec needs the `load` helper from Task 2.1 and the imports it uses; copy it in.)

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#26"'`
Expected: all FAIL. GraphQL shows duplicate `sys_costs`, Mermaid shows a raw `sys:` id, and OpenAPI has a bare `properties:`.

- [ ] **Step 3: Fix the Neo4j emitter**

```haskell
-- | A Cypher label or property key, backticked so namespaced names stay one token.
cypherLabel :: String -> String
cypherLabel s = "`" ++ concatMap (\c -> if c == '`' then "``" else [c]) s ++ "`"

emitNode :: (Name, Maybe Name) -> String
emitNode (name, parent) =
    case parent of
        Nothing ->
            "MERGE (n:OntologyClass {name: '" ++ escapeCypherString name ++ "'});\n"
        Just p ->
            "MERGE (n:OntologyClass {name: '" ++ escapeCypherString name ++ "'})\n" ++
            "MERGE (p:OntologyClass {name: '" ++ escapeCypherString p ++ "'})\n" ++
            "MERGE (n)-[:SUBCLASS_OF]->(p);\n"

emitRelation :: Relation -> String
emitRelation rel =
    "MERGE (s:OntologyClass {name: '" ++ escapeCypherString (relDomain rel) ++ "'})\n" ++
    "MERGE (t:OntologyClass {name: '" ++ escapeCypherString (relRange rel) ++ "'})\n" ++
    "MERGE (s)-[:RELATION {name: '" ++ escapeCypherString (relName rel) ++ "'}]->(t);\n"

emitConstraint :: Property -> String
emitConstraint p =
    "CREATE CONSTRAINT IF NOT EXISTS FOR (n:" ++ cypherLabel (domain p) ++ ") REQUIRE n." ++ cypherLabel (propName p) ++ " IS NOT NULL;\n"
```

In `emitAuditQuery`, use `cypherLabel conceptName` after `MATCH (n:` and `cypherLabel prop` after `n.`.

- [ ] **Step 4: Fix the Mermaid and D2 emitters**

`src/Emitters/Mermaid.hs`:

```haskell
emitClass :: (Name, Maybe Name) -> String
emitClass (name, _) = "    class " ++ sanitizeIdent name ++ "[\"" ++ name ++ "\"]\n"

emitRelation :: (Name, Maybe Name) -> String
emitRelation (name, Just parent) = "    " ++ sanitizeIdent parent ++ " <|-- " ++ sanitizeIdent name ++ "\n"
emitRelation _ = ""

emitProperty :: Property -> String
emitProperty p = "    " ++ sanitizeIdent (domain p) ++ " : +" ++ propertyTypeToString (rangeType p) ++ " " ++ propName p ++ "\n"

emitAssociation :: Relation -> String
emitAssociation r = "    " ++ sanitizeIdent (relDomain r) ++ " --> " ++ sanitizeIdent (relRange r) ++ " : " ++ relName r ++ "\n"
```

`src/Emitters/D2.hs`:

```haskell
-- | A D2 key, quoted so ':' is not read as a separator.
d2Key :: String -> String
d2Key s = "\"" ++ concatMap (\c -> if c == '"' then "\\\"" else [c]) s ++ "\""

emitClass :: (Name, Maybe Name) -> String
emitClass (name, _) = d2Key name ++ ": { shape: class }"

emitRelation :: (Name, Maybe Name) -> String
emitRelation (name, Just parent) = d2Key name ++ " -> " ++ d2Key parent
emitRelation _ = ""

emitPropertyReference :: Property -> String
emitPropertyReference p = d2Key (domain p) ++ "." ++ d2Key (propName p) ++ ": " ++ propertyTypeToString (rangeType p)

emitAssociation :: Relation -> String
emitAssociation r = d2Key (relDomain r) ++ " -> " ++ d2Key (relRange r) ++ ": " ++ relName r
```

- [ ] **Step 5: Fix the GraphQL emitter**

```haskell
emitGraphQL :: Registry -> String
emitGraphQL reg =
    let classes = irClasses (compileRegistry reg)
        typeDefs = concatMap (emitGraphQLType classes) classes
        rootQuery =
            "type Query {\n" ++
            concat [ "  " ++ field ++ ": [" ++ sanitizeIdent (compClassName cls) ++ "!]!\n"
                   | (cls, field) <- zip classes (queryFieldNames classes) ] ++
            "}\n"
    in "# Code generated by OntoLogic. DO NOT EDIT.\n\n" ++ typeDefs ++ rootQuery

-- | Query field per class, made unique: lowercase first letter, plural, then _2, _3 on collision.
queryFieldNames :: [CompiledClass] -> [String]
queryFieldNames = go []
  where
    go _ [] = []
    go seen (c:cs) =
        let base = plural (sanitizeIdent (compClassName c))
            name = disambiguate seen base 1
        in name : go (name : seen) cs
    plural (x:xs) = toLower x : xs ++ "s"
    plural []     = "items"
    disambiguate seen base n
        | candidate `elem` seen = disambiguate seen base (n + 1)
        | otherwise = candidate
      where candidate = if n == 1 then base else base ++ "_" ++ show n

-- | A class's own properties plus its ancestors', subclass definitions winning.
inheritedProperties :: [CompiledClass] -> CompiledClass -> [CompiledProperty]
inheritedProperties classes cls =
    let parents = [ (compClassName c, compParentClass c) | c <- classes ]
        chain = compClassName cls : getAncestors (compClassName cls) parents
        props = [ p | n <- chain, c <- classes, compClassName c == n, p <- compProperties c ]
    in nubByName props
  where
    nubByName = foldr (\p acc -> if any ((== compPropName p) . compPropName) acc then acc else p : acc) []

emitGraphQLType :: [CompiledClass] -> CompiledClass -> String
emitGraphQLType classes cls =
    let props = inheritedProperties classes cls
        fieldLines = if null props then "  _empty: Boolean\n" else concatMap emitGraphQLField props
    in "type " ++ sanitizeIdent (compClassName cls) ++ " {\n" ++ fieldLines ++ "}\n\n"
```

`nubByName` keeps the first occurrence, and the chain lists the class before its ancestors, so a subclass property wins. Remove `emitQueryField`.

- [ ] **Step 6: Fix the OpenAPI emitter**

In `emitOpenApiSchema`, replace each `"      properties:\n"` (and the indented `"          properties:\n"` in the `allOf` branch) with a helper:

```haskell
    propsBlock indent ps
        | null ps = indent ++ "properties: {}\n"
        | otherwise = indent ++ "properties:\n" ++ concatMap emitOpenApiField ps
```

Call it with `"      "` in the parentless branch and `"          "` in the `allOf` branch.

- [ ] **Step 7: Regenerate the checked-in examples**

Create `scripts/regenerate_examples.sh`:

```bash
#!/usr/bin/env bash
# Regenerate the checked-in examples/*.cypher, *.mmd and *.d2 from examples/*.logic.
set -euo pipefail
cd "$(dirname "$0")/.."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for f in examples/*.logic; do
  base="$(basename "$f" .logic)"
  stack exec ontologic-exe -- -i "$f" -t neo4j   -o "$tmp" >/dev/null
  cp "$tmp/graph.cypher"       "examples/$base.cypher"
  stack exec ontologic-exe -- -i "$f" -t mermaid -o "$tmp" >/dev/null
  cp "$tmp/class_diagram.mmd"  "examples/$base.mmd"
  stack exec ontologic-exe -- -i "$f" -t d2      -o "$tmp" >/dev/null
  cp "$tmp/diagram.d2"         "examples/$base.d2"
done
echo "Regenerated $(ls examples/*.logic | wc -l) example(s). The .d2.svg files need the d2 CLI: make -C examples svg"
```

Run `chmod +x scripts/regenerate_examples.sh && ./scripts/regenerate_examples.sh` and review `git diff examples/` — every change should be a semicolon, a backtick or a sanitized id. The `.d2.svg` files stay as they are unless the `d2` CLI is installed; note that in the PR.

- [ ] **Step 8: Verify the output in the real tools**

`docker-compose.yml` already defines a `neo4j:5.12` service, so the Cypher output can be checked against a real server with `cypher-shell` inside the container. Add to `test/CompileSpec.hs` (which already has `withTool`, `tmpDir` and `runIn`):

```haskell
    it "cypher-shell accepts the generated Cypher" $ withTool "docker" $ \docker -> do
        up <- runIn "." docker ["compose", "up", "-d", "--wait", "neo4j"]
        case up of
            (ExitFailure _, _, err) -> pendingWith ("neo4j service unavailable: " ++ take 200 err)
            _ -> do
                Right reg <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
                (code, out, err) <- runIn "." docker
                    (words "compose exec -T neo4j cypher-shell -u neo4j -p password --format plain")
                    -- statements are piped in on stdin
                    `withStdin` emitCypher reg
                (code, out ++ err) `shouldSatisfy` \(c, o) -> c == ExitSuccess && not ("Invalid input" `isInfixOf` o)
```

`runIn` passes an empty stdin, so add one more helper beside it:

```haskell
-- | Same as runIn but feeds the process stdin.
runInWith :: FilePath -> FilePath -> [String] -> String -> IO (ExitCode, String, String)
runInWith dir exe args input = readCreateProcessWithExitCode (proc exe args) { cwd = Just dir } input
```

and use `runInWith "." docker (words "compose exec -T neo4j cypher-shell -u neo4j -p password") (emitCypher reg)` rather than the `withStdin` sketch above. Tear the service down at the end of the spec with `runIn "." docker ["compose", "down"]`.

Because `cypher-shell` stops at the first error, a clean exit means every statement parsed and ran. Run it once locally before relying on it:

```bash
docker compose up -d --wait neo4j
stack exec ontologic-exe -- -i ontologic-lib/bfo_2020.logic -t neo4j -o /tmp/cy
docker compose exec -T neo4j cypher-shell -u neo4j -p password < /tmp/cy/graph.cypher; echo "exit=$?"
docker compose down
```

Expected: `exit=0`. Before the fix the same command fails with a Cypher syntax error on the second `MERGE (n...)`.

In CI, run it as a service container in the `haskell-test` job:

```yaml
    services:
      neo4j:
        image: neo4j:5.12
        env:
          NEO4J_AUTH: neo4j/password
        ports: ["7687:7687"]
        options: >-
          --health-cmd "cypher-shell -u neo4j -p password 'RETURN 1'"
          --health-interval 10s --health-timeout 5s --health-retries 10
```

With a service container there's no `docker compose`, so have the test prefer a reachable `bolt://localhost:7687` (via a locally installed `cypher-shell`, which the CI step below installs) and fall back to `docker compose` locally:

```yaml
      - name: Install cypher-shell
        run: |
          sudo apt-get update && sudo apt-get install -y wget gnupg
          wget -qO- https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
          echo 'deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable 5' | sudo tee /etc/apt/sources.list.d/neo4j.list
          sudo apt-get update && sudo apt-get install -y cypher-shell
          cypher-shell --version
```

Also verify the diagram output with the real CLIs when they're installed (both are optional locally, and neither is in CI):

```haskell
    it "renders with the d2 CLI when available" $ withTool "d2" $ \d2 -> do
        dir <- tmpDir "d2"
        writeFile (dir </> "diagram.d2") (emitD2 reg)
        (code, _, err) <- runIn dir d2 ["diagram.d2", "out.svg"]
        (code, err) `shouldBe` (ExitSuccess, "")

    it "renders with mmdc when available" $ withTool "mmdc" $ \mmdc -> do
        dir <- tmpDir "mmd"
        writeFile (dir </> "class_diagram.mmd") (emitMermaid reg)
        (code, _, err) <- runIn dir mmdc ["-i", "class_diagram.mmd", "-o", "out.svg"]
        (code, err) `shouldBe` (ExitSuccess, "")
```

Install them locally once to confirm the fix (`npm i -g @mermaid-js/mermaid-cli`, and d2 from https://d2lang.com), run the two cases, and paste the output in the PR. If you'd rather have them in CI too, add `npm i -g @mermaid-js/mermaid-cli` and the d2 install script to the workflow and say so.

- [ ] **Step 9: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass, with updated golden strings in the five emitter specs.

```bash
git add src/Emitters/Neo4j.hs src/Emitters/Mermaid.hs src/Emitters/D2.hs src/Emitters/GraphQL.hs src/Emitters/OpenApi.hs scripts/regenerate_examples.sh examples test/Neo4jSpec.hs test/MermaidSpec.hs test/D2Spec.hs test/GraphQLSpec.hs test/OpenApiSpec.hs
git commit -m "fix(emitters): loadable Cypher, valid Mermaid/D2 ids, unique GraphQL fields, OpenAPI properties (#26)"
```

---

### Task 3.3: Configurable base IRI and Java package (#33)

**Files:**
- Modify: `src/OntoLogic.hs` (new `resolveBaseIri`, `defaultBaseIri`)
- Modify: `src/Emitters/Owl.hs`, `src/Emitters/Shacl.hs` (take a base IRI), `src/Emitters/Java.hs` (default package)
- Modify: `src/Targets.hs` (`EmitOptions` gains `optBaseIri`), `src/Main.hs` (`--base-iri`), `src/REPL.hs` (`:set`)
- Modify: `models-java/src/test/java/com/ontologic/models/ValidationBehaviorTest.java`, `app-java/src/main/java/com/ontologic/app/Main.java` (import the new package)
- Test: `test/OwlSpec.hs`, `test/ShaclSpec.hs`, `test/JavaSpec.hs`, `test/REPLSpec.hs`

**Interfaces:**
- Consumes: `EmitOptions` from Task 1.2.
- Produces:
  - `defaultBaseIri :: String` = `"http://example.org/ontologic"`
  - `resolveBaseIri :: Maybe String -> Registry -> String` — the override if given, else the first namespace that has a URI, else `defaultBaseIri`; a trailing `#` or `/` is stripped
  - `emitOwlWithBase :: String -> Registry -> String`, `emitShaclWithBase :: String -> Registry -> String`; `emitOwl` and `emitShacl` keep their signatures and call these with `resolveBaseIri Nothing`
  - `EmitOptions { optJavaPackage :: String, optBaseIri :: Maybe String }`; `defaultEmitOptions` uses `"ontologic.generated"` and `Nothing`
  - REPL: `:set java-package <pkg>` and `:set base-iri <iri>`; `REPLState` gains `replEmitOptions :: EmitOptions`

- [ ] **Step 1: Write failing tests**

`test/OwlSpec.hs`:

```haskell
    describe "base IRI (#33)" $ do
      it "uses the ontology's own namespace" $ do
        let reg = load "(namespace sys \"http://bsommers.github.io/ecosystem\") (def-concept sys:Thing)"
        emitOwl reg `shouldContain` "xml:base=\"http://bsommers.github.io/ecosystem\""
        emitOwl reg `shouldNotContain` "acme"
      it "falls back to a neutral default" $
        emitOwl (load "(def-concept Thing)") `shouldContain` "xml:base=\"http://example.org/ontologic\""
      it "honours an explicit base" $
        emitOwlWithBase "http://acme.test/onto" (load "(def-concept Thing)") `shouldContain` "xml:base=\"http://acme.test/onto\""
```

`test/ShaclSpec.hs`:

```haskell
    it "prefixes shapes with the ontology's namespace (#33)" $ do
      let reg = load "(namespace sys \"http://bsommers.github.io/ecosystem\") (def-concept sys:Thing)"
      emitShacl reg `shouldContain` "@prefix ont: <http://bsommers.github.io/ecosystem#> ."
      emitShacl reg `shouldNotContain` "acme"
```

`test/REPLSpec.hs`:

```haskell
    it "sets the Java package for :emit java (#33)" $ do
      (s1, _) <- evalREPLCommand initialREPLState "(def-concept Robot)"
      (s2, out) <- evalREPLCommand s1 ":set java-package com.acme.models"
      out `shouldContain` "java-package"
      (_, java) <- evalREPLCommand s2 ":emit java"
      java `shouldContain` "package com.acme.models;"
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#33"'`
Expected: FAIL. The OWL output says `acme.com`, and `:set` is an unknown command.

- [ ] **Step 3: Implement `resolveBaseIri` in `src/OntoLogic.hs`**

```haskell
-- | Neutral base IRI used when the ontology declares no namespace URI.
defaultBaseIri :: String
defaultBaseIri = "http://example.org/ontologic"

-- | Base IRI for RDF output: the override, else the first declared namespace URI, else the default.
resolveBaseIri :: Maybe String -> Registry -> String
resolveBaseIri (Just iri) _ = stripTrailing iri
resolveBaseIri Nothing reg =
    case [ u | NamespaceDecl _ (Just u) <- namespaces reg ] of
        (u:_) -> stripTrailing u
        []    -> defaultBaseIri
  where
    stripTrailing = reverse . dropWhile (`elem` ("#/" :: String)) . reverse
```

(`stripTrailing` is needed in both branches; define it at the top level of the module rather than in a `where` attached to the second equation.)

- [ ] **Step 4: Thread it through OWL, SHACL and Java**

`src/Emitters/Owl.hs`:

```haskell
emitOwl :: Registry -> String
emitOwl reg = emitOwlWithBase (resolveBaseIri Nothing reg) reg

emitOwlWithBase :: String -> Registry -> String
emitOwlWithBase base reg =
    xmlHeader base (namespaces reg) ++
    ontologyHeader base ++
    concatMap emitClass (concepts reg) ++
    concatMap emitProperty (properties reg) ++
    concatMap emitRelation (relations reg) ++
    xmlFooter

xmlHeader :: String -> [NamespaceDecl] -> String
xmlHeader base customNs =
    "<?xml version=\"1.0\"?>\n" ++
    "<rdf:RDF xmlns=\"" ++ base ++ "#\"\n" ++
    "         xml:base=\"" ++ base ++ "\"\n" ++
    "         xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n" ++
    "         xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"\n" ++
    "         xmlns:owl=\"http://www.w3.org/2002/07/owl#\"" ++
    concatMap (\ns -> "\n         xmlns:" ++ nsPrefix ns ++ "=\"" ++ maybe (nsPrefix ns ++ "#") id (nsUri ns) ++ "\"") customNs ++ ">\n"

ontologyHeader :: String -> String
ontologyHeader base = "    <owl:Ontology rdf:about=\"" ++ base ++ "\"/>\n"
```

`src/Emitters/Shacl.hs`: add `emitShaclWithBase :: String -> Registry -> String`, make `emitShacl reg = emitShaclWithBase (resolveBaseIri Nothing reg) reg`, and use `"@prefix ont: <" ++ base ++ "#> .\n"` in `emitPrefixes`.

`src/Emitters/Java.hs`: `emitJava = emitJavaWithPackage "ontologic.generated"`.

`src/Targets.hs`:

```haskell
data EmitOptions = EmitOptions
    { optJavaPackage :: String
    , optBaseIri     :: Maybe String
    } deriving (Show, Eq)

defaultEmitOptions :: EmitOptions
defaultEmitOptions = EmitOptions { optJavaPackage = "ontologic.generated", optBaseIri = Nothing }
```

and use the base in the two RDF targets:

```haskell
    , Target "owl" [] "OWL ontology" Nothing
        (\o reg -> [("ontology.owl", emitOwlWithBase (resolveBaseIri (optBaseIri o) reg) reg)])
    , Target "shacl" [] "SHACL shapes" Nothing
        (\o reg -> [("shapes.ttl", emitShaclWithBase (resolveBaseIri (optBaseIri o) reg) reg)])
```

- [ ] **Step 5: Add the CLI flag and the REPL command**

`src/Main.hs`: add `baseIri :: Maybe String` to `Args` with

```haskell
      <*> optional (strOption (long "base-iri" <> metavar "IRI" <> help "Base IRI for OWL/SHACL output (default: the ontology's first namespace)"))
```

Pass it into `processTarget`, which sets `optBaseIri` on the `EmitOptions` it builds. Change the `--java-package` help text to `"Java package for generated models (default: ontologic.generated)"`.

`src/REPL.hs`: add `replEmitOptions :: EmitOptions` to `REPLState` (initialised to `defaultEmitOptions`), use it in `:emit`, and add a branch before `:show`:

```haskell
    | ":set " `isPrefixOf` input =
        case words (trim (drop 5 input)) of
            ["java-package", pkg] ->
                return (state { replEmitOptions = (replEmitOptions state) { optJavaPackage = pkg } }, "✅ java-package set to " ++ pkg)
            ["base-iri", iri] ->
                return (state { replEmitOptions = (replEmitOptions state) { optBaseIri = Just iri } }, "✅ base-iri set to " ++ iri)
            _ -> return (state, "⚠️  Usage: :set java-package <pkg> | :set base-iri <iri>")
```

Add the `:set` line to `:help`.

- [ ] **Step 6: Update the Java consumers**

`build.gradle.kts` calls the CLI with no `--java-package`, so the generated package changes. Update the two Java sources:

```bash
sed -i 's/import com\.acme\.generated\.\*;/import ontologic.generated.*;/' \
  models-java/src/test/java/com/ontologic/models/ValidationBehaviorTest.java \
  app-java/src/main/java/com/ontologic/app/Main.java
./gradlew clean build test
```

Expected: the Gradle job passes. If it doesn't, pass `--java-package ontologic.generated` explicitly in `build.gradle.kts` and re-run.

- [ ] **Step 7: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"` and `grep -rn acme src/`
Expected: tests pass; the grep prints nothing. `JavaSpec` golden strings move to `package ontologic.generated;` — update them. The domain specs that pass their own package (`com.acme.grc`, `com.acme.ai`, …) still pass; renaming those is optional and out of scope.

```bash
git add src/OntoLogic.hs src/Emitters/Owl.hs src/Emitters/Shacl.hs src/Emitters/Java.hs src/Targets.hs src/Main.hs src/REPL.hs models-java app-java test
git commit -m "fix(emitters): derive base IRI from the ontology; neutral Java package default (#33)"
```

**Wave 3 gate:** all Wave 3 PRs merged, CI green on `main` (including the Gradle job), milestone `Wave 3: Emitters` shows 0 open issues.

---
# Wave 4: Language server

Milestone `Wave 4: Language server`: #22, #27. Task 4.2 builds on 4.1's I/O layer, so run them in order.

### Task 4.1: LSP framing in UTF-8 bytes; handle EOF and `exit` (#22)

**Files:**
- Modify: `package.yaml` (add `bytestring` to `dependencies`)
- Modify: `src/LSP.hs` (`runLSPServer` 27–74, the JSON helpers 246–300, the `_` case of `handleLSPRequest`)
- Test: `test/LSPSpec.hs`, `test/MainSpec.hs`

**Interfaces:**
- Produces (exported from `LSP`):
  - `encodeMessage :: String -> BS.ByteString` — `Content-Length` is the UTF-8 byte count
  - `readMessage :: Handle -> IO (Maybe String)` — one framed message, `Nothing` at end of input
- `handleLSPRequest` keeps its pure signature. Unknown *requests* (those with an `id`) now get a JSON-RPC `-32601` error; notifications still get nothing.

- [ ] **Step 1: Write failing tests**

Add to `test/LSPSpec.hs` (imports `qualified Data.ByteString as BS`, `qualified Data.ByteString.Char8 as BC`, `qualified Data.Text as T`, `qualified Data.Text.Encoding as TE`, `Data.List (isInfixOf)`, `System.IO`, `System.Directory (getTemporaryDirectory)`, `System.FilePath ((</>))`):

```haskell
    describe "message framing (#22)" $ do
      it "counts Content-Length in UTF-8 bytes" $ do
        let body = "{\"note\":\"café ⊑\"}"
            framed = encodeMessage body
            headerLen = read (takeWhile (/= '\r') (drop (length "Content-Length: ") (BC.unpack framed))) :: Int
        -- the byte count, not the character count
        headerLen `shouldBe` BS.length (TE.encodeUtf8 (T.pack body))
        headerLen `shouldSatisfy` (> length body)

      it "reads two consecutive messages with multi-byte content" $ do
        dir <- getTemporaryDirectory
        let f = dir </> "ontologic-lsp-frames.bin"
            m1 = "{\"method\":\"a\",\"text\":\"café ⊑\"}"
            m2 = "{\"method\":\"b\"}"
        BS.writeFile f (encodeMessage m1 <> encodeMessage m2)
        h <- openBinaryFile f ReadMode
        r1 <- readMessage h
        r2 <- readMessage h
        r3 <- readMessage h
        hClose h
        (r1, r2, r3) `shouldBe` (Just m1, Just m2, Nothing)

      it "parses JSON with a space after the colon" $ do
        let req = "{\"jsonrpc\": \"2.0\", \"id\": 7, \"method\": \"initialize\", \"params\": {}}"
            (_, respOpt, _) = handleLSPRequest initialLSPState req
        fmap (\r -> "\"id\":7" `isInfixOf` r) respOpt `shouldBe` Just True

      it "answers an unknown request with a method-not-found error" $ do
        let req = "{\"jsonrpc\":\"2.0\",\"id\":9,\"method\":\"textDocument/formatting\",\"params\":{}}"
            (_, respOpt, _) = handleLSPRequest initialLSPState req
        fmap (\r -> "-32601" `isInfixOf` r) respOpt `shouldBe` Just True
```

(Compute the expected byte count with `BS.length (Data.Text.Encoding.encodeUtf8 (Data.Text.pack body))` rather than the literal `22` if you prefer; keep one assertion that the byte count exceeds the character count.)

Add to `test/MainSpec.hs`:

```haskell
    it "ontologic-lsp exits cleanly at end of input (#22)" $ do
      (exitCode, _, stderr) <- readProcessWithExitCode "stack" ["exec", "ontologic-lsp"] ""
      exitCode `shouldBe` ExitSuccess
      stderr `shouldNotContain` "end of file"
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#22"'`
Expected: compile error (`encodeMessage`, `readMessage` missing), and the space-after-colon and unknown-request cases fail once stubs exist.

- [ ] **Step 3: Replace the I/O layer in `src/LSP.hs`**

Add to `package.yaml` under `dependencies:` the line `- bytestring`, then run `stack build` so `ontologic.cabal` regenerates.

```haskell
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Encoding.Error as TEE
import System.IO (Handle, hFlush, stdout, stdin, hSetBinaryMode, hIsEOF)
import Data.Char (isSpace, isHexDigit, chr)

-- | Frame one message. Content-Length is the UTF-8 byte count, as the protocol requires.
encodeMessage :: String -> BS.ByteString
encodeMessage body =
    let bytes = TE.encodeUtf8 (T.pack body)
    in BC.pack ("Content-Length: " ++ show (BS.length bytes) ++ "\r\n\r\n") <> bytes

-- | Read one framed message; Nothing at end of input or on a truncated body.
readMessage :: Handle -> IO (Maybe String)
readMessage h = do
    mLen <- readHeaders Nothing
    case mLen of
        Nothing -> return Nothing
        Just n -> do
            body <- BS.hGet h n
            return $ if BS.length body < n
                then Nothing
                else Just (T.unpack (TE.decodeUtf8With TEE.lenientDecode body))
  where
    readHeaders acc = do
        eof <- hIsEOF h
        if eof
            then return Nothing
            else do
                line <- BC.filter (/= '\r') <$> BS.hGetLine h
                if BS.null line
                    then maybe (readHeaders Nothing) (return . Just) acc
                    else readHeaders (contentLength line `orElse` acc)
    contentLength line =
        case BS.stripPrefix (BC.pack "Content-Length:") line of
            Just rest -> fst <$> BC.readInt (BC.dropWhile isSpace rest)
            Nothing   -> Nothing
    orElse new old = maybe old Just new

runLSPServer :: IO ()
runLSPServer = do
    hSetBinaryMode stdin True
    hSetBinaryMode stdout True
    loop initialLSPState
  where
    loop state = do
        msg <- readMessage stdin
        case msg of
            Nothing -> return ()
            Just body
                | extractJsonString "method" body == "exit" -> return ()
                | otherwise -> do
                    let (newState, responseOpt, notifs) = handleLSPRequest state body
                    mapM_ send notifs
                    mapM_ send responseOpt
                    loop newState
    send body = BS.hPut stdout (encodeMessage body) >> hFlush stdout
```

Delete `readHeader`, `readContent`, `getLineSafe`, `sendResponse` and `sendNotification`.

- [ ] **Step 4: Fix the JSON helpers and the unknown-method case**

```haskell
-- | The text after "key" : , skipping whitespace on both sides of the colon.
afterKey :: String -> String -> Maybe String
afterKey key json = go json
  where
    pat = "\"" ++ key ++ "\""
    go s = case findSubstring pat s of
        Nothing -> Nothing
        Just idx ->
            let afterPat = drop (idx + length pat) s
            in case dropWhile isSpace afterPat of
                (':':r) -> Just (dropWhile isSpace r)
                _       -> go afterPat

extractJsonString :: String -> String -> String
extractJsonString key json = case afterKey key json of
    Just ('"':r) -> unescapeJson (extractUntilUnescapedQuote r)
    _            -> ""

extractJsonId :: String -> String
extractJsonId json = case afterKey "id" json of
    Just ('"':r) -> "\"" ++ extractUntilUnescapedQuote r ++ "\""
    Just rest@(_:_)
        | "null" `isPrefixOf` rest -> "null"
        | otherwise -> let numStr = takeWhile (`elem` ("0123456789-" :: String)) rest
                       in if null numStr then "null" else numStr
    _ -> "null"

extractJsonInt :: String -> String -> Int
extractJsonInt key json = case afterKey key json of
    Just rest -> case reads (takeWhile (`elem` ("0123456789-" :: String)) rest) of
        [(n, _)] -> n
        _        -> 0
    Nothing -> 0
```

Add `\uXXXX` support to `unescapeJson`:

```haskell
unescapeJson ('\\':'u':a:b:c:d:cs)
    | all isHexDigit [a, b, c, d] = chr (read ("0x" ++ [a, b, c, d])) : unescapeJson cs
```

(Put this equation before the catch-all.) Replace the `_ ->` case of `handleLSPRequest` with:

```haskell
        _ | reqId == "null" -> (state, Nothing, [])   -- notification: no response
          | otherwise ->
            (state, Just ("{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"error\":{\"code\":-32601,\"message\":\"Method not found: " ++ escapeJson method ++ "\"}}"), [])
```

- [ ] **Step 5: Run the tests and commit**

Run: `stack build && stack test --ghc-options="-Wall -Werror"`
Expected: all pass, including the existing LSP cases.

Manual check with a stdio harness:

```bash
python3 - <<'PY'
import subprocess
def frame(s): b=s.encode(); return b"Content-Length: %d\r\n\r\n%s" % (len(b), b)
msgs = frame('{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"uri":"file:///t.logic","text":"; café ⊑\\n(def-concept Tank)\\n"}}')
msgs += frame('{"jsonrpc":"2.0","id":2,"method":"textDocument/hover","params":{"textDocument":{"uri":"file:///t.logic"},"position":{"line":1,"character":14}}}')
msgs += frame('{"jsonrpc":"2.0","method":"exit"}')
p = subprocess.run(["stack","exec","ontologic-lsp"], input=msgs, capture_output=True)
print(p.stdout.decode()[:400]); print("exit", p.returncode)
PY
```

Expected: a `publishDiagnostics` notification, then a hover response with `Concept ` + `Tank`, then exit 0.

```bash
git add package.yaml ontologic.cabal src/LSP.hs test/LSPSpec.hs test/MainSpec.hs
git commit -m "fix(lsp): frame messages in UTF-8 bytes; handle EOF, exit and unknown methods (#22)"
```

---

### Task 4.2: The language server resolves imports and reports real positions (#27)

**Files:**
- Modify: `src/Loader.hs` (lift `findImportFile` to the top level and export it; add `loadImportFrom`)
- Modify: `src/LSP.hs` (`LSPState`, `updateDoc`, `makeLintDiag`, `findDefinitionLine`, new `handleLSPRequestIO`, `uriToPath`, `parseErrorPosition`)
- Test: `test/LSPSpec.hs`

**Interfaces:**
- Consumes: `stdlibSearchPaths` from Task 1.6, `Monoid Registry` from Task 1.1, `readMessage`/`encodeMessage` from Task 4.1.
- Produces:
  - `Loader`: `findImportFile :: [FilePath] -> FilePath -> IO (Either String FilePath)`, `loadImportFrom :: [FilePath] -> FilePath -> IO (Either String (FilePath, Registry))`
  - `LSP`: `handleLSPRequestIO :: LSPState -> String -> IO (LSPState, Maybe String, [String])` (used by the server loop; the pure `handleLSPRequest` stays for tests and for requests that need no I/O), `LSPState` gains `lspImportFiles :: Map.Map String [FilePath]`
- Diagnostics: parse errors carry the real line and column from the `ParseErrorBundle`. Lint and import errors are placed by a documented heuristic: the first line of the document that mentions one of the message's identifiers, else line 0.

- [ ] **Step 1: Write failing tests**

Add to `test/LSPSpec.hs` (imports `System.Directory (getCurrentDirectory, getTemporaryDirectory, createDirectoryIfMissing)`, `System.FilePath ((</>))`, `Data.List (isInfixOf)`):

```haskell
    describe "imports and positions (#27)" $ do
      it "publishes no diagnostics for a document importing the standard library" $ do
        tmp <- (</> "ontologic-lsp-27") <$> getTemporaryDirectory
        createDirectoryIfMissing True tmp
        let uri = "file://" ++ tmp </> "pump.logic"
            req = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"" ++ uri ++ "\",\"text\":\"(import \\\"bfo_2020.logic\\\")\\n(def-concept Pump bfo:Process)\\n\"}}"
        (_, _, notifs) <- handleLSPRequestIO initialLSPState req
        head notifs `shouldContain` "\"diagnostics\":[]"

      it "reports a parse error at its real line" $ do
        let req = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///p.logic\",\"text\":\"(def-concept A)\\n(def-concept B (oops\\n\"}}"
        (_, _, notifs) <- handleLSPRequestIO initialLSPState req
        head notifs `shouldContain` "\"line\":1"

      it "resolves go-to-definition on a whole identifier" $ do
        let text = "(def-concept TankTruck)\\n(def-concept Tank)\\n"
            openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///d.logic\",\"text\":\"" ++ text ++ "\"}}"
        (st, _, _) <- handleLSPRequestIO initialLSPState openReq
        let defReq = "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"textDocument/definition\",\"params\":{\"textDocument\":{\"uri\":\"file:///d.logic\"},\"position\":{\"line\":1,\"character\":14}}}"
        (_, respOpt, _) <- handleLSPRequestIO st defReq
        fmap (\r -> "\"line\":1" `isInfixOf` r) respOpt `shouldBe` Just True
```

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#27"'`
Expected: compile error (`handleLSPRequestIO` missing); after stubbing, the import case reports `Undeclared parent concept: bfo:Process` and both position cases report line 0.

- [ ] **Step 3: Export the import helpers from `src/Loader.hs`**

Move `findImportFile` out of the `where` block of `resolveImports` to the top level, unchanged, and add it plus `loadImportFrom` to the export list:

```haskell
-- | Resolve one import by name and load it with its own transitive imports.
loadImportFrom :: [FilePath] -> FilePath -> IO (Either String (FilePath, Registry))
loadImportFrom dirs rawPath = do
    found <- findImportFile dirs rawPath
    case found of
        Left err -> return (Left err)
        Right p -> do
            canon <- canonicalizePath p
            reg <- resolveImports dirs canon
            return (fmap (\r -> (canon, r)) reg)
```

- [ ] **Step 4: Implement the LSP side**

```haskell
data LSPState = LSPState
    { lspDocs :: Map.Map String String
    , lspRegistries :: Map.Map String Registry
    , lspImportFiles :: Map.Map String [FilePath]   -- URI -> files its imports resolved to
    } deriving (Show, Eq)

initialLSPState :: LSPState
initialLSPState = LSPState Map.empty Map.empty Map.empty

-- | file:///a/b.logic -> /a/b.logic, with %XX decoded.
uriToPath :: String -> Maybe FilePath
uriToPath uri
    | "file://" `isPrefixOf` uri = Just (decode (drop 7 uri))
    | otherwise = Nothing
  where
    decode ('%':a:b:cs) | all isHexDigit [a, b] = chr (read ("0x" ++ [a, b])) : decode cs
    decode (c:cs) = c : decode cs
    decode [] = []

-- | Registry of everything the document imports, the files used, and any unresolved imports.
loadDocumentImports :: FilePath -> Registry -> IO (Registry, [FilePath], [String])
loadDocumentImports docPath reg = do
    libs <- stdlibSearchPaths
    let dirs = takeDirectory docPath : libs
    results <- mapM (loadImportFrom dirs . importPath) (imports reg)
    return ( mconcat [ r | Right (_, r) <- results ]
           , [ f | Right (f, _) <- results ]
           , [ e | Left e <- results ] )

-- | Line/column of the first parse error, zero-based.
parseErrorPosition :: ParseErrorBundle T.Text Void -> (Int, Int)
parseErrorPosition bundle =
    let err = NE.head (bundleErrors bundle)
        (_, pst) = reachOffset (errorOffset err) (bundlePosState bundle)
        pos = pstateSourcePos pst
    in (unPos (sourceLine pos) - 1, unPos (sourceColumn pos) - 1)

-- | Best-effort placement for messages that carry no position: the first line of the
-- document that mentions one of the message's identifier-like words, else line 0.
messageLine :: String -> String -> Int
messageLine content msg =
    let tokens = filter ((> 2) . length) (words (map (\c -> if c `elem` ("(),:.\"" :: String) then ' ' else c) msg))
        ls = lines content
    in case [ i | (i, l) <- zip [0 ..] ls, any (`isInfixOf` l) tokens ] of
        (i:_) -> i
        []    -> 0
```

Replace `updateDoc` with a version that takes the imported registry, and keep a pure wrapper:

```haskell
updateDoc :: LSPState -> String -> String -> (LSPState, String)
updateDoc = updateDocWith emptyRegistry []

updateDocWith :: Registry -> [String] -> LSPState -> String -> String -> (LSPState, String)
updateDocWith impReg impErrs state uri content =
    case parse parseRegistry uri (T.pack content) of
        Left bundle ->
            let (l, c) = parseErrorPosition bundle
                diag = mkDiag l c "ontologic-parser" (errorBundlePretty bundle)
            in ( state { lspDocs = Map.insert uri content (lspDocs state) }
               , publishDiagnostics uri [diag] )
        Right reg ->
            let merged = deduplicateRegistry (reg <> impReg)
                inherited = lintRegistry impReg          -- problems that belong to imported files
                own = filter (`notElem` inherited) (lintRegistry merged)
                diags = [ mkDiag (messageLine content e) 0 "ontologic-imports" e | e <- impErrs ] ++
                        [ mkDiag (messageLine content m) 0 "ontologic-linter" m | m <- own ]
                newState = state
                    { lspDocs = Map.insert uri content (lspDocs state)
                    , lspRegistries = Map.insert uri merged (lspRegistries state)
                    }
            in (newState, publishDiagnostics uri diags)

mkDiag :: Int -> Int -> String -> String -> String
mkDiag line char source msg =
    "{\"range\":{\"start\":{\"line\":" ++ show line ++ ",\"character\":" ++ show char ++
    "},\"end\":{\"line\":" ++ show line ++ ",\"character\":100}},\"severity\":1,\"source\":\"" ++ source ++
    "\",\"message\":\"" ++ escapeJson msg ++ "\"}"

publishDiagnostics :: String -> [String] -> String
publishDiagnostics uri diags =
    "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"" ++
    escapeJson uri ++ "\",\"diagnostics\":[" ++ intercalateComma diags ++ "]}}"
```

Delete `makeLintDiag`. Make definition lookup match whole identifiers:

```haskell
findDefinitionLine :: String -> [String] -> Int -> String -> Maybe (String, Int, Int)
findDefinitionLine _ [] _ _ = Nothing
findDefinitionLine word (l:ls) lineIdx uri
    | definesWord word l = Just (uri, lineIdx, 0)
    | otherwise = findDefinitionLine word ls (lineIdx + 1) uri

-- | True when the line is a def-* form whose declared name is exactly word.
definesWord :: String -> String -> Bool
definesWord word l =
    case words (map (\c -> if c `elem` ("()" :: String) then ' ' else c) l) of
        (kw:name:_) -> kw `elem` ["def-concept", "def-property", "def-relation"] && name == word
        _ -> False
```

Add the IO dispatcher:

```haskell
-- | Server-side entry point: handles the requests that need the filesystem, delegates the rest.
handleLSPRequestIO :: LSPState -> String -> IO (LSPState, Maybe String, [String])
handleLSPRequestIO state raw
    | method `elem` ["textDocument/didOpen", "textDocument/didChange"] =
        case (uriToPath uri, parse parseRegistry uri (T.pack text)) of
            (Just p, Right reg) -> do
                (impReg, impFiles, impErrs) <- loadDocumentImports p reg
                let (st, notif) = updateDocWith impReg impErrs state uri text
                return (st { lspImportFiles = Map.insert uri impFiles (lspImportFiles st) }, Nothing, [notif])
            _ -> return (handleLSPRequest state raw)
    | method == "textDocument/definition" = do
        let content = Map.findWithDefault "" uri (lspDocs state)
            word = getWordAtPosition content (extractJsonInt "line" raw) (extractJsonInt "character" raw)
        loc <- case findDefinitionLine word (lines content) 0 uri of
            Just l  -> return (Just l)
            Nothing -> searchImports word (Map.findWithDefault [] uri (lspImportFiles state))
        return (state, Just (definitionResponse (extractJsonId raw) loc), [])
    | otherwise = return (handleLSPRequest state raw)
  where
    method = extractJsonString "method" raw
    uri = extractJsonString "uri" raw
    text = extractJsonString "text" raw
    searchImports _ [] = return Nothing
    searchImports word (f:fs) = do
        content <- readFile f
        case findDefinitionLine word (lines content) 0 ("file://" ++ f) of
            Just l  -> return (Just l)
            Nothing -> searchImports word fs
```

Factor the definition response out of the pure handler so both paths share it:

```haskell
definitionResponse :: String -> Maybe (String, Int, Int) -> String
definitionResponse reqId loc = case loc of
    Just (targetUri, targetLine, targetChar) ->
        "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"uri\":\"" ++ escapeJson targetUri ++
        "\",\"range\":{\"start\":{\"line\":" ++ show targetLine ++ ",\"character\":" ++ show targetChar ++
        "},\"end\":{\"line\":" ++ show targetLine ++ ",\"character\":" ++ show (targetChar + 10) ++ "}}}}"
    Nothing -> "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":null}"
```

Point the server loop at `handleLSPRequestIO`:

```haskell
            Just body
                | extractJsonString "method" body == "exit" -> return ()
                | otherwise -> do
                    (newState, responseOpt, notifs) <- handleLSPRequestIO state body
                    mapM_ send notifs
                    mapM_ send responseOpt
                    loop newState
```

New imports for `src/LSP.hs`: `Text.Megaparsec (ParseErrorBundle(..), errorOffset, reachOffset, PosState(..), SourcePos(..), unPos, parse)`, `qualified Data.List.NonEmpty as NE`, `Data.Void (Void)`, `Data.List (intercalate, isInfixOf, isPrefixOf)`, `System.FilePath (takeDirectory)`, `Loader (stdlibSearchPaths, loadImportFrom)`.

- [ ] **Step 5: Run the tests and commit**

Run: `stack build && stack test --ghc-options="-Wall -Werror"`
Expected: all pass. Manual check: open `examples/bfo_energy.logic` in VS Code with the extension from Task 0.2 and confirm no red squiggles, and that go-to-definition on an imported `bfo:` concept opens `ontologic-lib/bfo_2020.logic`.

```bash
git add src/Loader.hs src/LSP.hs test/LSPSpec.hs
git commit -m "fix(lsp): resolve imports before linting; real parse positions; whole-identifier definitions (#27)"
```

Note in the PR that lint diagnostics are still placed by a heuristic at this point, and that Task 4.3 replaces it with the symbol's real line and column.

### Task 4.3: Lint diagnostics carry a real line and column (#27)

Task 4.2 places lint and import diagnostics with a word-matching heuristic. #27's acceptance criterion asks for the right line **and column**, so this task replaces the heuristic with the symbol each lint message is actually about. Full source spans on every parsed item would be the complete fix; this gets exact positions for every current lint message without changing `Registry`.

**Files:**
- Modify: `src/Linter.hs` (new `LintFinding`, `lintRegistryFindings`; `lintRegistry` becomes a wrapper)
- Modify: `src/LSP.hs` (`updateDocWith` uses findings; new `symbolPosition`; delete `messageLine`)
- Test: `test/LinterSpec.hs` (new), `test/LSPSpec.hs`

**Interfaces:**
- Produces:
  - `data LintFinding = LintFinding { lintMessage :: String, lintSymbol :: Maybe Name } deriving (Show, Eq)`
  - `lintRegistryFindings :: Registry -> [LintFinding]`
  - `lintRegistry :: Registry -> [String]` keeps its signature: `map lintMessage . lintRegistryFindings`, so every existing caller and test is unaffected
  - `LSP.symbolPosition :: String -> Name -> Maybe (Int, Int)` — the line and column of the symbol's declaration, else of its first whole-token occurrence

- [ ] **Step 1: Write failing tests**

Create `test/LinterSpec.hs`:

```haskell
module LinterSpec (spec) where

import Test.Hspec
import OntoLogic
import Linter

spec :: Spec
spec = describe "lint findings carry their symbol (#27)" $ do
    it "names the concept for an undeclared parent" $ do
        let reg = emptyRegistry { concepts = [("Pump", Just "bfo:Process")] }
        map lintSymbol (lintRegistryFindings reg) `shouldBe` [Just "Pump"]

    it "names the property for an undeclared domain" $ do
        let reg = emptyRegistry { properties = [Property "capacity" "Tank" PTInteger] }
        map lintSymbol (lintRegistryFindings reg) `shouldBe` [Just "capacity"]

    it "keeps lintRegistry's messages unchanged" $ do
        let reg = emptyRegistry { concepts = [("Pump", Just "bfo:Process")] }
        lintRegistry reg `shouldBe` ["Undeclared parent concept: bfo:Process referenced by Pump"]
```

Add to `test/LSPSpec.hs`:

```haskell
      it "points a lint diagnostic at the offending declaration" $ do
        let text = "(def-concept Asset)\n(def-concept Device Asset)\n(def-concept Pump bfo:Process)\n"
            req = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///l.logic\",\"text\":\"" ++ escapeForJson text ++ "\"}}"
        (_, _, notifs) <- handleLSPRequestIO initialLSPState req
        head notifs `shouldContain` "\"line\":2"
        head notifs `shouldContain` "\"character\":13"   -- column of "Pump"
```

(`escapeForJson` just replaces newlines with `\\n`; write it as a local helper in the spec.)

- [ ] **Step 2: Run them to confirm they fail**

Run: `stack test --ta '--match "#27"'`
Expected: `LinterSpec` doesn't compile (`lintRegistryFindings` missing) and the LSP case reports `"line":0`.

- [ ] **Step 3: Return findings from the linter**

In `src/Linter.hs`, add the type and make every check produce one:

```haskell
-- | A lint message plus the symbol it is about, so editors can place it.
data LintFinding = LintFinding
    { lintMessage :: String
    , lintSymbol  :: Maybe Name
    } deriving (Show, Eq)

lintRegistry :: Registry -> [String]
lintRegistry = map lintMessage . lintRegistryFindings

lintRegistryFindings :: Registry -> [LintFinding]
lintRegistryFindings reg =
    checkSymbolIntegrity reg ++
    checkCircularInheritance (Map.fromList (concepts reg)) ++
    checkContradictoryAxioms (axioms reg) ++
    checkGlobalPropertyContradictions reg
```

Change each check's return type from `[String]` to `[LintFinding]`, keeping the message text byte-for-byte so existing expectations still pass. The symbol for each is:

| Check | `lintSymbol` |
|---|---|
| `checkDuplicateConcepts` | the concept name |
| `checkDuplicateProperties` | the property name |
| `checkDuplicateRelations` | the relation name |
| `checkDuplicateNamespaces` | the prefix |
| `checkUndeclaredParents` | the **child** concept (that's the line that has the error) |
| `checkUndeclaredDomains` | the property name |
| `checkUndeclaredRelationEndpoints` | the relation name |
| `checkCircularInheritance` | the node the cycle was found from |
| `checkContradictoryAxioms`, `checkPropConstraints` | the property name |
| `checkConceptAxioms` (cross-axiom) | the concept name |

For example:

```haskell
checkUndeclaredParents :: [(Name, Maybe Name)] -> [LintFinding]
checkUndeclaredParents cList =
    let knownConcepts = Set.fromList (map fst cList)
    in [ LintFinding ("Undeclared parent concept: " ++ parent ++ " referenced by " ++ name) (Just name)
       | (name, Just parent) <- cList
       , not (Set.member parent knownConcepts)
       ]
```

- [ ] **Step 4: Place diagnostics by symbol in `src/LSP.hs`**

```haskell
-- | Line and column of a symbol: its def-* declaration if present, else its first
-- whole-token occurrence. Nothing when the symbol does not appear in this document
-- (it came from an import), and the caller then falls back to (0, 0).
symbolPosition :: String -> Name -> Maybe (Int, Int)
symbolPosition content sym =
    case [ (i, col) | (i, l) <- numbered, definesWord sym l, Just col <- [tokenColumn sym l] ] of
        ((i, c):_) -> Just (i, c)
        [] -> case [ (i, c) | (i, l) <- numbered, Just c <- [tokenColumn sym l] ] of
            ((i, c):_) -> Just (i, c)
            []         -> Nothing
  where
    numbered = zip [0 ..] (lines content)

-- | Column of sym in the line, when it appears as a whole identifier.
tokenColumn :: Name -> String -> Maybe Int
tokenColumn sym l = go 0 l
  where
    go _ [] = Nothing
    go i rest
        | sym `isPrefixOf` rest && boundaryBefore i && boundaryAfter (drop (length sym) rest) = Just i
        | otherwise = go (i + 1) (tail rest)
    boundaryBefore 0 = True
    boundaryBefore i = not (isIdent (l !! (i - 1)))
    boundaryAfter [] = True
    boundaryAfter (c:_) = not (isIdent c)
    isIdent c = isAlphaNum c || c `elem` ("_:-" :: String)
```

In `updateDocWith`, build the lint diagnostics from findings:

```haskell
            let merged = deduplicateRegistry (reg <> impReg)
                inherited = map lintMessage (lintRegistryFindings impReg)
                own = filter ((`notElem` inherited) . lintMessage) (lintRegistryFindings merged)
                place f = case lintSymbol f >>= symbolPosition content of
                    Just (l, c) -> (l, c)
                    Nothing     -> (0, 0)
                lintDiags = [ let (l, c) = place f in mkDiag l c "ontologic-linter" (lintMessage f) | f <- own ]
```

Keep the import diagnostics placed on the `(import "...")` line, which is exact — match the line containing `(import` and the quoted path from the message:

```haskell
                importDiags = [ mkDiag (importLine content e) 0 "ontologic-imports" e | e <- impErrs ]

-- | The line of the failing (import "...") form; the message ends with the path.
importLine :: String -> String -> Int
importLine content msg =
    let path = reverse (takeWhile (/= ' ') (reverse msg))
    in case [ i | (i, l) <- zip [0 ..] (lines content), "(import" `isInfixOf` l, path `isInfixOf` l ] of
        (i:_) -> i
        []    -> 0
```

Delete `messageLine`. Add `Data.Char (isAlphaNum)` to the imports if it isn't there.

- [ ] **Step 5: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass, including every existing spec that calls `lintRegistry` (the messages are unchanged).

```bash
git add src/Linter.hs src/LSP.hs test/LinterSpec.hs test/LSPSpec.hs
git commit -m "fix(lsp): place lint diagnostics at the symbol's line and column (#27)"
```

Both 4.2 and 4.3 reference #27; put `Fixes #27` on 4.3's PR and `Refs #27` on 4.2's.

---

**Wave 4 gate:** both PRs merged, CI green on `main`, milestone `Wave 4: Language server` shows 0 open issues.

---

# Wave 5: Ecosystem data

Milestone `Wave 5: Ecosystem data`: #35. Runs last so the file is regenerated with the fixed emitters, namespaces and parser.

### Task 5.1: Code symbols become instance data, not classes (#35)

**Decision, resolved 2026-09-20 — option 1.** The DSL has no way to declare an individual, so a code symbol cannot be modelled correctly in `.logic` today. The owner chose option 1; options 2 and 3 are kept here as the rejected alternatives.

1. **Recommended.** Keep only the class layer in `ontologic-lib/ecosystem.logic` (the 4 bridge classes, plus `sys:Repository` and a `definedIn` relation), and move the 910 symbols into a data file, `ontologic-lib/data/ecosystem_symbols.ttl`, as instances typed `sys:CodeSymbol` with a `sys:definedIn` triple naming the repository. No DSL change; provenance is in the data; the emitters stop producing hundreds of meaningless types.
2. Add a `def-individual` form to the DSL. Correct, but it touches the parser, the IR and every emitter — its own plan.
3. Leave the modelling and only fix the count. Cheapest, but the acceptance criteria in #35 aren't met.

The steps below implement option 1.

**Files:**
- Modify: `ontologic-lib/ecosystem.logic` (regenerated: classes only)
- Create: `ontologic-lib/data/ecosystem_symbols.ttl` (generated instance data)
- Modify: the harvester that generated the file (it is **not** in this repository; commit 6e97354 only added the `.logic`)
- Test: `test/EcosystemSpec.hs` (new)

**Interfaces:**
- Produces: `ontologic-lib/ecosystem.logic` contains only `namespace`, `import`, `def-concept` for the bridge classes and `sys:Repository`, and `def-relation sys:definedIn sys:CodeSymbol sys:Repository`. Every generated symbol lives in the TTL as `sys:<repo>/<symbol> a sys:CodeSymbol ; sys:definedIn sys:<repo> .`

**The generator, found:** `~/ecosystem/example-org/symbol-harvester/scripts/harvest_ast_to_ontologic.py` (101 lines). Facts from reading it:
- It scrapes `symbol-harvester/docs/repos/*.md` (65 files) for rows of an "Exported Symbols & AST Catalog" table, with the regex `\|\s*`?(?:function|class|struct|interface|method)`?\s*\|\s*`?([A-Za-z0-9_]+)`?\s*\|`.
- **The 1009-versus-910 mystery is solved.** Line 69 prints `f"Harvested {len(symbols)} unique symbols."` — but `symbols` is the list of *all* matched rows (1009). The de-duplication happens later, in `generate_logic_file`, via the `seen` set, which yields the 910 written concepts. The label "unique" on that line is simply wrong, and the commit message repeated it. Nothing was dropped.
- It writes to `~/.cache/symbol-harvester/repos/OntoLogic/ontologic-lib/ecosystem.logic`, a **cache clone**, not to this working copy. So the file in this repo got there by a copy step outside the script, which is why it can drift.
- It then runs `-t solve --prover z3` in the cache clone and prints whatever it gets.

So the fix spans two repos. This task owns the OntoLogic side, and Step 5 files the generator changes against `symbol-harvester`.

- [ ] **Step 1: Confirm the counts before changing anything**

```bash
grep -c 'def-concept sys:' ontologic-lib/ecosystem.logic     # expected: 914 (4 bridge + 910 symbols)
python3 - <<'EOF'
import re, pathlib
pat = re.compile(r'\|\s*`?(?:function|class|struct|interface|method)`?\s*\|\s*`?([A-Za-z0-9_]+)`?\s*\|')
rows, uniq = 0, set()
for f in pathlib.Path.home().joinpath("ecosystem/example-org/symbol-harvester/docs/repos").glob("*.md"):
    inside = False
    for line in f.read_text().splitlines():
        if "Exported Symbols & AST Catalog" in line: inside = True; continue
        if inside and line.startswith("## "): inside = False
        if inside and "|" in line:
            m = pat.search(line)
            if m: rows += 1; uniq.add(m.group(1))
print("rows", rows, "unique", len(uniq))
EOF
```

Expected: `rows 1009 unique 910`, which confirms the mislabeled count. Record both numbers in the PR.

- [ ] **Step 2: Write the failing test**

Create `test/EcosystemSpec.hs`:

```haskell
module EcosystemSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf, isPrefixOf)
import OntoLogic
import Loader (loadRegistryWithImports)

spec :: Spec
spec = describe "ecosystem.logic models symbols as data (#35)" $ do
    it "declares only the class layer" $ do
        Right reg <- loadRegistryWithImports "ontologic-lib/ecosystem.logic"
        let own = [ c | (c, _) <- concepts reg, "sys:" `isPrefixOf` c ]
        length own `shouldSatisfy` (< 20)

    it "keeps a relation for symbol provenance" $ do
        Right reg <- loadRegistryWithImports "ontologic-lib/ecosystem.logic"
        map relName (relations reg) `shouldContain` ["sys:definedIn"]

    it "has one instance per symbol in the data file, with a repository" $ do
        ttl <- readFile "ontologic-lib/data/ecosystem_symbols.ttl"
        let symbols = length (filter ("a sys:CodeSymbol" `isInfixOf`) (lines ttl))
            provenance = length (filter ("sys:definedIn" `isInfixOf`) (lines ttl))
        symbols `shouldSatisfy` (> 0)
        provenance `shouldBe` symbols

    it "reports the same count in the file header as it contains" $ do
        ttl <- readFile "ontologic-lib/data/ecosystem_symbols.ttl"
        let symbols = length (filter ("a sys:CodeSymbol" `isInfixOf`) (lines ttl))
            header = [ w | l <- lines ttl, "# symbols:" `isPrefixOf` l, w <- words l, all (`elem` "0123456789") w, not (null w) ]
        header `shouldBe` [show symbols]
```

Run: `stack test --ta '--match "#35"'`
Expected: FAIL. There are 914 `sys:` concepts and no data file.

- [ ] **Step 3: Change the harvester**

In `~/ecosystem/example-org/symbol-harvester/scripts/harvest_ast_to_ontologic.py`:
- Emit the class layer once:

```lisp
;; ============================================================================
;; AUTO-GENERATED ECOSYSTEM ONTOLOGY (class layer)
;; Symbols live in data/ecosystem_symbols.ttl as instances.
;; ============================================================================
(namespace sys "http://bsommers.github.io/ecosystem")
(import "bfo_2020.logic")

(def-concept sys:InformationArtifact bfo:GenericallyDependentContinuant)
(def-concept sys:AgentRole bfo:Role)
(def-concept sys:AgentProcess bfo:Process)
(def-concept sys:CodeSymbol sys:InformationArtifact)
(def-concept sys:Repository sys:InformationArtifact)
(def-relation sys:definedIn sys:CodeSymbol sys:Repository)
```

- Emit one instance per symbol into `ontologic-lib/data/ecosystem_symbols.ttl`, qualified by repository so same-named symbols from different repos stay distinct:

```turtle
# Generated by the ecosystem harvester. Do not edit.
# symbols: 910
# repositories: 17
@prefix sys: <http://bsommers.github.io/ecosystem#> .

sys:uitoolbox\/registerPlugin a sys:CodeSymbol ;
    sys:definedIn sys:uitoolbox .
```

- Fix the mislabeled count at line 69 and print all three numbers:

```python
    unique = {sym for _, sym in symbols}
    print(f"Harvested {len(symbols)} rows, {len(unique)} unique symbols, from {len(list(DOCS_DIR.glob('*.md')))} repos.")
```

  and write the written-instance count into the TTL's `# symbols:` header so the file states its own size.
- Make the output path an argument (`--out-dir`, defaulting to the cache clone) so the file can be generated straight into a real checkout instead of being copied by hand.

- [ ] **Step 4: Regenerate and check the downstream output**

```bash
# from the harvester's directory, per its own usage
stack exec ontologic-exe -- -i ontologic-lib/ecosystem.logic -t lint
stack exec ontologic-exe -- -i ontologic-lib/ecosystem.logic -t graphql -o /tmp/eco
grep -c "^type " /tmp/eco/schema.graphql
```
Expected: lint passes; the GraphQL schema now has a handful of types instead of ~914, and no duplicate query fields.

- [ ] **Step 5: Correct the record and file the generator change**

Add a line to `docs/` (wherever the harvest is described) giving the real counts: 1009 table rows, 910 unique symbols. Note in the PR that commit 6e97354's message said 1009 because `harvest_ast_to_ontologic.py:69` labels the row count "unique".

Open a PR or issue against `symbol-harvester` for the generator changes in Step 3 (class layer plus TTL instances, the corrected count, and `--out-dir`), and link it from #35. This repo's PR should not be merged before that one, or the next harvest run will overwrite `ecosystem.logic` with the old shape. Note that ordering in both PRs.

- [ ] **Step 6: Run the tests and commit**

Run: `stack test --ghc-options="-Wall -Werror"`
Expected: all pass. The GraphQL uniqueness test from Task 3.2 still passes on the smaller file.

```bash
git add ontologic-lib/ecosystem.logic ontologic-lib/data/ecosystem_symbols.ttl test/EcosystemSpec.hs docs
git commit -m "fix(ecosystem): model code symbols as instance data with repository provenance (#35)"
```

**Wave 5 gate:** PR merged, CI green on `main`, milestone `Wave 5: Ecosystem data` shows 0 open issues, and all 20 issues are closed.

---

## Self-review

**Spec coverage.** Every issue maps to a task: #16 → 0.3 (plus the VS Code part in 0.2), #17 → 2.2, #18 → 2.4 + 2.5, #19 → 2.1, #20 → 1.4, #21 → 1.3, #22 → 4.1, #23 → 1.5, #24 → 2.3, #25 → 3.1, #26 → 3.2, #27 → 4.2, #28 → 0.2, #29 → 1.6, #30 → 0.6, #31 → 0.4, #32 → 0.5, #33 → 3.3, #34 → 1.1 + 1.2, #35 → 5.1. The red CI on `main`, which no issue covers, is Task 0.1.

**Acceptance criteria and how each is covered now:**
- #26's "Neo4j output runs in cypher-shell" — Task 3.2 Step 8 runs the generated Cypher through `cypher-shell` against the `neo4j:5.12` service that `docker-compose.yml` already defines, locally via `docker compose` and in CI via a service container. The test skips only when Docker or the service is unavailable.
- #26's "Mermaid and D2 output renders" — Task 3.2 Step 8 runs `mmdc` and `d2` when installed, and says to install them once to confirm the fix and paste the output in the PR. Adding them to CI is called out as optional.
- #25's "compile or import checks run in CI" — Task 3.1 covers all four: `go vet`, `rustc`, `python -c import` (with pydantic) and `tsc --noEmit` against `zod@3` + `typescript@5` installed from npm in a temp directory. The CI step adds `actions/setup-node@v4`, and the task requires confirming that no check printed PENDING in the first green run.
- #27's "diagnostics point at the right line and column" — Task 4.3 replaces 4.2's heuristic: the linter returns `LintFinding` with the symbol each message is about, and the LSP resolves that symbol to its declaration's line and column. Import errors are placed on their `(import "...")` line. Parse errors already come from the `ParseErrorBundle`. Complete source spans on every parsed item would still be a further step, and would change `Registry`.
- #35's generator — identified as `~/ecosystem/example-org/symbol-harvester/scripts/harvest_ast_to_ontologic.py`. Task 5.1 owns the OntoLogic side and Step 5 files the generator change against `symbol-harvester`, which must merge first or the next harvest overwrites the file. The 1009-versus-910 discrepancy is no longer unexplained: line 69 prints the row count with the word "unique", and the de-duplication to 910 happens later in `generate_logic_file`.

**Known risks:**
- Task 2.5 puts quantified axioms in front of the solver. On large ontologies (ecosystem, bfo_2020) z3 may answer `unknown` or get slow; the timing test in 2.5 is the tripwire, and adding `(set-option :timeout ...)` is the fallback.
- Tasks 2.2, 3.1, 3.2 and 3.3 all change generated output, so several emitter specs' golden strings move. Each task says to review those diffs rather than accept them.
- Task 0.3 changes `PATH` inside tests, and Tasks 1.6, 3.1 and 3.2 change the working directory or spawn containers. Hspec runs specs sequentially by default; don't enable `--jobs` for the suite.
- Task 3.1's npm install and Task 3.2's Docker pull need network access in CI. If the runner is offline both tests skip, which would quietly drop two acceptance criteria — hence the "confirm no PENDING lines" step.
- Task 0.6 vendors `factory_domain.logic` from `factory-domain`, creating a second copy that can drift. The header comment names the owner; a periodic diff check would be the follow-up.

**Type consistency.** `EmitOptions` gains `optBaseIri` in Task 3.3, so tasks written before it construct it with `defaultEmitOptions { ... }` rather than positionally. `findUnsatConceptsWith` returns `IO (Either String [String])` from Task 0.3 onward, and Task 2.5 keeps that type. `resolveProperty` takes two constraint maps from Task 2.2 onward. `handleLSPRequest` stays pure throughout; only `handleLSPRequestIO` is in `IO`.
