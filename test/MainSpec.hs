module MainSpec (spec) where

import Test.Hspec
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (removeDirectoryRecursive, doesFileExist, createDirectoryIfMissing, getTemporaryDirectory, getCurrentDirectory)
import System.FilePath ((</>))

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
