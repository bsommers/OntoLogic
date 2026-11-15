module MainSpec (spec) where

import Test.Hspec
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (removeDirectoryRecursive, doesFileExist, createDirectoryIfMissing, getTemporaryDirectory, getCurrentDirectory)
import System.FilePath ((</>))
import Data.Version (showVersion)
import Paths_ontologic (version)
import Data.List (isInfixOf, isPrefixOf)
import System.Directory (findExecutable)
import GHC.Clock (getMonotonicTime)

spec :: Spec
spec = do
  describe "Language server driver (ontologic-lsp)" $ do
    it "ontologic-lsp exits cleanly at end of input (#22)" $ do
      (exitCode, _, stderr) <- readProcessWithExitCode "stack" ["exec", "ontologic-lsp"] ""
      exitCode `shouldBe` ExitSuccess
      stderr `shouldNotContain` "end of file"

  describe "CLI Driver (ontologic-exe)" $ do
    it "prints help when --help flag is passed" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "--help"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Usage:"
      stdout `shouldContain` "--input"
      stdout `shouldContain` "--target"

    it "rejects a zero or negative --solve-timeout / --solve-memory" $ do
      (c1, _, e1) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--solve", "-T", "0"] ""
      c1 `shouldNotBe` ExitSuccess
      e1 `shouldContain` "expected a positive integer"
      (c2, _, e2) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--solve", "--solve-memory", "-5"] ""
      c2 `shouldNotBe` ExitSuccess
      e2 `shouldContain` "expected a positive integer"

    it "warns that --solve-memory is ignored by non-Z3 provers" $ do
      (_, _, err) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--solve", "-p", "native", "--solve-memory", "512"] ""
      err `shouldContain` "--solve-memory is not supported by Native"

    it "warns when a prover without arithmetic gives an all-clear on numeric comparisons" $ do
      (code, out, err) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "test/fixtures/integer_gap.logic", "--solve", "-p", "native"] ""
      code `shouldBe` ExitSuccess
      out `shouldContain` "SMT Satisfiable (SAT)"
      err `shouldContain` "The native prover checks this theory without arithmetic"

    it "runs -t lint successfully without -o flag" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "lint"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Logic Validated successfully"

    it "fails with exit code 1 when target requires output but -o is missing" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "java"] ""
      exitCode `shouldBe` ExitFailure 1
      stdout `shouldContain` "Error: --output is required for target: java"

    it "generates expected Python models in output directory" $ do
      let outDir = "/tmp/cli_test_py"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "python", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated Python models"
      exists <- doesFileExist (outDir </> "models.py")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "fails with exit code 1 when target is unknown" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "unknown_target", "-o", "/tmp"] ""
      exitCode `shouldBe` ExitFailure 1
      stdout `shouldContain` "Unknown target: unknown_target"

    it "exits with code 1 cleanly on validation failure" $ do
      let badFile = "/tmp/bad_model.logic"
      writeFile badFile "(def-concept A B)\n(def-concept B A)\n"
      (exitCode, stdout, stderr) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", badFile, "-t", "lint"] ""
      exitCode `shouldBe` ExitFailure 1
      stdout `shouldContain` "Circular inheritance"
      stdout `shouldContain` "/tmp/bad_model.logic:1:14: error: Circular inheritance"
      stderr `shouldNotContain` "CallStack (from HasCallStack)"

    it "generates expected JSON Schema in output directory" $ do
      let outDir = "/tmp/cli_test_jsonschema"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "jsonschema", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated JSON Schema"
      exists <- doesFileExist (outDir </> "schema.json")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "generates expected SHACL shapes in output directory" $ do
      let outDir = "/tmp/cli_test_shacl"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "shacl", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated SHACL shapes"
      exists <- doesFileExist (outDir </> "shapes.ttl")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "generates expected Rust models in output directory" $ do
      let outDir = "/tmp/cli_test_rust"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "rust", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated Rust models"
      exists <- doesFileExist (outDir </> "models.rs")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "generates expected Go models in output directory" $ do
      let outDir = "/tmp/cli_test_go"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "go", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated Go models"
      exists <- doesFileExist (outDir </> "models.go")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "supports configurable Java package name via --java-package flag" $ do
      let outDir = "/tmp/cli_test_java_pkg"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "java", "-o", outDir, "--java-package", "com.custom.pkg"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated Java models"
      code <- readFile (outDir </> "Asset.java")
      code `shouldContain` "package com.custom.pkg;"
      removeDirectoryRecursive outDir

    it "generates expected TypeScript / Zod models in output directory" $ do
      let outDir = "/tmp/cli_test_ts"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "ts", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated TypeScript/Zod models"
      exists <- doesFileExist (outDir </> "models.ts")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "generates expected OpenAPI 3.1 schema in output directory" $ do
      let outDir = "/tmp/cli_test_openapi"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "openapi", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated OpenAPI 3.1 schema"
      exists <- doesFileExist (outDir </> "openapi.yaml")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "generates expected GraphQL SDL schema in output directory" $ do
      let outDir = "/tmp/cli_test_graphql"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "graphql", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated GraphQL schema"
      exists <- doesFileExist (outDir </> "schema.graphql")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "generates expected SMT-LIB2 logic in output directory" $ do
      let outDir = "/tmp/cli_test_smt"
      createDirectoryIfMissing True outDir
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "smt", "-o", outDir] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Generated SMT-LIB2 specification"
      exists <- doesFileExist (outDir </> "spec.smt2")
      exists `shouldBe` True
      removeDirectoryRecursive outDir

    it "runs Z3 solver consistency check with -t solve" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "solve", "--prover", "z3"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "SMT Satisfiable (SAT)"

    it "runs CVC5 solver consistency check with --solve -p cvc5" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--solve", "-p", "cvc5"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "SMT Satisfiable (SAT)"

    it "exits 0 without an exception when REPL input ends (#32)" $ do
      (exitCode, stdout, stderr) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "--repl"] ":help\n"
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Goodbye!"
      stderr `shouldNotContain` "end of file"

    it "rejects an unknown --prover value (#16)" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--solve", "-p", "z4"] ""
      exitCode `shouldBe` ExitFailure 1
      stdout `shouldContain` "Unknown prover 'z4'"

    it "accepts --lib-path for stdlib imports (#29)" $ do
      tmp <- (</> "ontologic-libpath-29") <$> getTemporaryDirectory
      createDirectoryIfMissing True tmp
      writeFile (tmp </> "pump.logic") "(import \"bfo_2020.logic\")\n(def-concept Pump bfo:Process)\n"
      repo <- getCurrentDirectory
      (exitCode, stdout, _) <- readProcessWithExitCode "stack"
        ["exec", "ontologic-exe", "--", "-i", tmp </> "pump.logic", "-t", "lint", "--lib-path", repo </> "ontologic-lib"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Logic Validated successfully"

    it "reports axioms not sent to the solver (#18)" $ do
      tmp <- (</> "ontologic-18.logic") <$> getTemporaryDirectory
      writeFile tmp "(def-concept A)\n(definedIn \"a\" \"b\")\n"
      (_, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", tmp, "--solve", "-p", "z3"] ""
      stdout `shouldContain` "not sent to the solver"

    it "emits canonical clausal normal form with --cnf flag" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--cnf"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Device(X1)"
      stdout `shouldContain` "Asset(X1)"

    it "runs consistency and satisfiability check using native prover (--solve -p native)" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "--solve", "-p", "native"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Satisfiable (SAT)"
      stdout `shouldContain` "All concepts are satisfiable"

  describe "Partial checks are unknown, not consistent" $ do
    let partial exe prover = it ("--solve -p " ++ prover ++ " answers unknown (exit 2) when axioms were not sent") $ do
          found <- findExecutable exe
          case found of
            Nothing -> pendingWith (exe ++ " not installed")
            Just _ -> do
              (code, out, _) <- readProcessWithExitCode "stack"
                ["exec", "ontologic-exe", "--", "-i", "test/fixtures/failclosed/free_var.logic", "-t", "solve", "-p", prover] ""
              code `shouldBe` ExitFailure 2
              out `shouldNotContain` "Satisfiable (SAT)"
              out `shouldContain` "could not be checked"
              -- the message comes first, then the list of axioms that were not sent
              let (ahead, rest) = breakOn "could not be checked" out
              rest `shouldContain` "were not sent to the solver"
              ahead `shouldNotContain` "were not sent to the solver"
    partial "z3" "z3"
    partial "cvc5" "cvc5"

  describe "Native prover honours the time limit" $ do
    it "returns unknown within the limit plus grace on a theory it cannot saturate (two_color, -T 4)" $ do
      t0 <- getMonotonicTime
      -- Hard outer limit: if the in-process limit failed, the child is killed and the test fails.
      (code, out, _) <- readProcessWithExitCode "timeout"
        ["-s", "KILL", "40", "stack", "exec", "ontologic-exe", "--"
        , "-i", "test/fixtures/failclosed/two_color.logic", "-t", "solve", "-p", "native", "-T", "4"] ""
      t1 <- getMonotonicTime
      code `shouldBe` ExitFailure 2
      out `shouldContain` "unknown"
      (t1 - t0) `shouldSatisfy` (< 9)  -- limit 4 s plus grace; one limit per phase would take 12 s

  describe "CLI surface (B7, B8)" $ do
    it "--version prints the package version" $ do
      (code, out, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "--version"] ""
      code `shouldBe` ExitSuccess
      out `shouldContain` ("ontologic " ++ showVersion version)

    it "--neo4j-edition rejects unknown values" $ do
      (code, _, err) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", "logic/fleet.logic", "-t", "neo4j", "-o", "/tmp/ontologic-neo-edition", "--neo4j-edition", "bogus"] ""
      code `shouldNotBe` ExitSuccess
      err `shouldContain` "unknown Neo4j edition"

    it "refuses absolute imports unless --allow-absolute-imports is given" $ do
      tmp <- getTemporaryDirectory
      let dir = tmp </> "ontologic-main-b7"
      createDirectoryIfMissing True dir
      writeFile (dir </> "ok.logic") "(def-concept Ok)\n"
      writeFile (dir </> "root.logic") ("(import \"" ++ dir ++ "/ok.logic\")\n")
      (c1, o1, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", dir </> "root.logic"] ""
      c1 `shouldNotBe` ExitSuccess
      o1 `shouldSatisfy` ("Absolute import paths are not allowed" `isInfixOf`)
      (c2, _, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "-i", dir </> "root.logic", "--allow-absolute-imports"] ""
      c2 `shouldBe` ExitSuccess

breakOn :: String -> String -> (String, String)
breakOn needle = go []
  where
    go acc rest@(c:cs)
      | needle `isPrefixOf` rest = (reverse acc, rest)
      | otherwise = go (c : acc) cs
    go acc [] = (reverse acc, [])
