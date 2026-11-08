# Robust Testing Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform OntoLogic's test suite from basic string-matching into a comprehensive, robust verification framework covering real-world example models, target syntax & compilation smoke tests, visualizer emitters, CLI driver ergonomics, and runtime validation checks.

**Architecture:** The test suite operates on three tiers:
1. **Unit Tier (Hspec):** Fine-grained unit tests for parsers, AST, linter rules, and emitters (`ParserSpec`, `JavaSpec`, `PythonSpec`, `Neo4jSpec`, `OwlSpec`, `MermaidSpec`, `D2Spec`, `MainSpec`).
2. **Integration Tier (`ExamplesSpec`):** Dynamic discovery of all `.logic` files in `examples/`, testing full parsing, semantic linting, and multi-target code generation across diverse industrial domains.
3. **Target Validation Tier (Runtime & Compilation):** Verifying emitted code compiles and enforces business rules in the target runtimes (Python Pydantic instantiation & validation, Java Jakarta Bean Validation under JUnit/Gradle, and valid XML parsing).

**Tech Stack:** Haskell (Hspec, Megaparsec, Process, Directory, FilePath), Java 17 (JUnit 5, Jakarta Validation, Hibernate Validator), Python 3.11+ (Pydantic v2, `ast`), Gradle 8.4.

## Global Constraints

- All tests in `stack test` must pass cleanly.
- Maintain zero compiler warnings under GHC (`-Wall -Werror`).
- Do not introduce new external Haskell dependencies to `package.yaml` beyond standard libraries (`process`, `directory`, `filepath`, `containers`, `hspec`).
- Tests that invoke external tools (`python3`, `javac`, `gradlew`) must fail gracefully or skip with clear diagnostic messages if optional system tooling is absent.

---

### Task 1: Fix Broken Example Domain Models

**Files:**
- Modify: `examples/domain_security_trust.logic:47`
- Modify: `examples/mqtt_ecosystem_unified.logic:75-77`

**Interfaces:**
- Input: Existing `.logic` example files
- Output: Validated example files that comply with `checkSymbolIntegrity` without errors.

- [ ] **Step 1: Inspect the linting failures**

Run:
```bash
stack exec ontologic-exe -- -i examples/domain_security_trust.logic -t lint
stack exec ontologic-exe -- -i examples/mqtt_ecosystem_unified.logic -t lint
```
Expected:
- `domain_security_trust.logic` fails with `Undeclared domain concept: SoftwareComponent`
- `mqtt_ecosystem_unified.logic` fails with `Duplicate concept definition: Container`

- [ ] **Step 2: Fix `examples/domain_security_trust.logic`**

Add `(def-concept SoftwareComponent)` to taxonomy declarations (around line 18):
```lisp
(def-concept SoftwareComponent)
```

- [ ] **Step 3: Fix `examples/mqtt_ecosystem_unified.logic`**

Remove the duplicate `(def-concept Container ComputeNode)` on line 76.

- [ ] **Step 4: Verify both example files pass linting**

Run:
```bash
stack exec ontologic-exe -- -i examples/domain_security_trust.logic -t lint
stack exec ontologic-exe -- -i examples/mqtt_ecosystem_unified.logic -t lint
```
Expected: `✅ Logic Validated successfully.` for both files.

- [ ] **Step 5: Commit**

```bash
git add examples/domain_security_trust.logic examples/mqtt_ecosystem_unified.logic
git commit -m "fix(examples): declare SoftwareComponent and remove duplicate Container concept"
```

---

### Task 2: Visualizer Emitter Unit Tests (MermaidSpec & D2Spec)

**Files:**
- Create: `test/MermaidSpec.hs`
- Create: `test/D2Spec.hs`

**Interfaces:**
- Consumes: `emitMermaid :: Registry -> String` from `Emitters.Mermaid`
- Consumes: `emitD2 :: Registry -> String` from `Emitters.D2`
- Produces: Hspec tests verifying class definitions, inheritance relationships, and properties.

- [ ] **Step 1: Write `test/MermaidSpec.hs`**

```haskell
module MermaidSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Mermaid (emitMermaid)

spec :: Spec
spec = do
  describe "Mermaid Emitter" $ do
    it "emits class diagram header and concept classes" $ do
      let reg = Registry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = []
                  , properties = 
                      [ Property "serial_number" "Asset" "String"
                      , Property "temperature" "Device" "Integer"
                      ]
                  }
          diagram = emitMermaid reg
      diagram `shouldContain` "classDiagram\n"
      diagram `shouldContain` "class Asset\n"
      diagram `shouldContain` "class Device\n"
      diagram `shouldContain` "Asset <|-- Device\n"
      diagram `shouldContain` "Asset : +String serial_number\n"
      diagram `shouldContain` "Device : +Integer temperature\n"
```

- [ ] **Step 2: Write `test/D2Spec.hs`**

```haskell
module D2Spec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.D2 (emitD2)

spec :: Spec
spec = do
  describe "D2 Emitter" $ do
    it "emits D2 class shapes, inheritance, and properties" $ do
      let reg = Registry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = []
                  , properties = 
                      [ Property "serial_number" "Asset" "String"
                      , Property "temperature" "Device" "Integer"
                      ]
                  }
          diagram = emitD2 reg
      diagram `shouldContain` "Asset: { shape: class }"
      diagram `shouldContain` "Device: { shape: class }"
      diagram `shouldContain` "Device -> Asset"
      diagram `shouldContain` "Asset.serial_number: String"
      diagram `shouldContain` "Device.temperature: Integer"
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `stack test --test-arguments="-m Mermaid" && stack test --test-arguments="-m D2"`
Expected: PASS with 0 warnings.

- [ ] **Step 4: Commit**

```bash
git add test/MermaidSpec.hs test/D2Spec.hs
git commit -m "test: add unit test coverage for Mermaid and D2 emitters"
```

---

### Task 3: Examples Integration Test Suite (`ExamplesSpec.hs`)

**Files:**
- Create: `test/ExamplesSpec.hs`

**Interfaces:**
- Consumes: All `.logic` files in `examples/` directory
- Produces: Automated tests verifying parsing, linting, and emission across all targets.

- [ ] **Step 1: Write `test/ExamplesSpec.hs`**

```haskell
module ExamplesSpec (spec) where

import Test.Hspec
import System.Directory (listDirectory, doesFileExist)
import System.FilePath ((</>), takeExtension)
import qualified Data.Text.IO as TIO
import Text.Megaparsec (parse, errorBundlePretty)
import Data.List (sort)

import OntoLogic
import Parser (parseRegistry)
import Linter (lintRegistry)
import Emitters.Java (emitJava)
import Emitters.Python (emitPython)
import Emitters.Neo4j (emitCypher)
import Emitters.Owl (emitOwl)
import Emitters.Mermaid (emitMermaid)
import Emitters.D2 (emitD2)

spec :: Spec
spec = do
  describe "Examples Integration Suite" $ do
    it "successfully parses, lints, and emits code for all domain files in examples/" $ do
      let dir = "examples"
      files <- listDirectory dir
      let logicFiles = sort [ dir </> f | f <- files, takeExtension f == ".logic" ]
      logicFiles `shouldNotBe` []

      mapM_ testExampleFile logicFiles

testExampleFile :: FilePath -> Expectation
testExampleFile path = do
  content <- TIO.readFile path
  case parse parseRegistry path content of
    Left err -> expectationFailure $ "Parse error in " ++ path ++ ":\n" ++ errorBundlePretty err
    Right reg -> do
      -- 1. Verify semantic linting passes
      let lintErrors = lintRegistry reg
      lintErrors `shouldBe` []

      -- 2. Verify all emitters generate non-empty code without exceptions
      let javaFiles = emitJava reg
      length javaFiles `shouldBe` length (concepts reg)

      let pyCode = emitPython reg
      null pyCode `shouldBe` False

      let cypherCode = emitCypher reg
      null cypherCode `shouldBe` False

      let owlCode = emitOwl reg
      null owlCode `shouldBe` False

      let mermaidCode = emitMermaid reg
      null mermaidCode `shouldBe` False

      let d2Code = emitD2 reg
      null d2Code `shouldBe` False
```

- [ ] **Step 2: Run the test to verify all examples pass**

Run: `stack test --test-arguments="-m Examples"`
Expected: PASS for all 12 example models.

- [ ] **Step 3: Commit**

```bash
git add test/ExamplesSpec.hs
git commit -m "test: add integration test suite exercising all examples against all emitters"
```

---

### Task 4: Target Syntax & Compilation Verification

**Files:**
- Modify: `test/PythonSpec.hs`
- Modify: `test/OwlSpec.hs`
- Modify: `test/JavaSpec.hs`

**Interfaces:**
- Tests that generated artifacts are syntactically valid in their host platforms.

- [ ] **Step 1: Add Python syntax smoke test in `test/PythonSpec.hs`**

Verify generated Python is valid via `python3 -c "import ast; ast.parse(...)"`:
```haskell
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

    it "emitted Python code passes python3 ast.parse syntax check" $ do
      let reg = Registry
                  { concepts = [("Sensor", Just "Device"), ("Device", Just "Asset"), ("Asset", Nothing)]
                  , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "temp", Constant "25.0"]))]
                  , properties = [Property "temp" "Sensor" "Float"]
                  }
          code = emitPython reg
      (exitCode, stdout, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast, sys; ast.parse(sys.stdin.read())"] code
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""
```

- [ ] **Step 2: Add XML well-formedness verification in `test/OwlSpec.hs`**

Verify generated OWL passes XML parser:
```haskell
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

    it "emitted OWL passes python3 xml.etree well-formedness validation" $ do
      let reg = Registry
                  { concepts = [("Machine", Nothing), ("Mixer", Just "Machine")]
                  , axioms = []
                  , properties = [Property "rpm" "Mixer" "Integer"]
                  }
          xml = emitOwl reg
      (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import xml.etree.ElementTree as ET, sys; ET.fromstring(sys.stdin.read())"] xml
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""
```

- [ ] **Step 3: Add Java compilation smoke test in `test/JavaSpec.hs`**

Verify emitted Java compiles with `javac` against `jakarta.validation-api`:
```haskell
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (createDirectoryIfMissing, removeDirectoryRecursive)
import System.FilePath ((</>))

    it "emitted Java classes compile successfully with javac" $ do
      let reg = Registry
                  { concepts = [("Sensor", Just "Device"), ("Device", Just "Asset"), ("Asset", Nothing)]
                  , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "reading", Constant "10"]))]
                  , properties = [Property "reading" "Sensor" "Integer"]
                  }
          files = emitJava reg
          tmpDir = "/tmp/javac_test"
      createDirectoryIfMissing True tmpDir
      mapM_ (\(name, code) -> writeFile (tmpDir </> name ++ ".java") code) files
      -- Compile with javac
      (exitCode, _, stderr) <- readProcessWithExitCode "javac" ["-cp", "~/.gradle/caches/modules-2/files-2.1/jakarta.validation/jakarta.validation-api/3.0.2/e9e30a59b58e2d4d9ae508ee9a59560f6412f10b/jakarta.validation-api-3.0.2.jar", tmpDir </> "Asset.java", tmpDir </> "Device.java", tmpDir </> "Sensor.java", "-d", tmpDir] ""
      removeDirectoryRecursive tmpDir
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `stack test`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add test/PythonSpec.hs test/OwlSpec.hs test/JavaSpec.hs
git commit -m "test: add target syntax and compilation smoke tests for Python, OWL, and Java"
```

---

### Task 5: Runtime Business Rule & Validation Behavior Tests

**Files:**
- Create: `models-java/src/test/java/com/ontologic/models/ValidationBehaviorTest.java`
- Modify: `test/PythonSpec.hs`

**Interfaces:**
- Tests that generated artifacts actually enforce constraints at runtime.

- [ ] **Step 1: Add Python Pydantic runtime validation test in `test/PythonSpec.hs`**

Verify that instantiated Pydantic objects enforce constraints at runtime:
```haskell
    it "emitted Python model enforces range constraints at runtime via Pydantic" $ do
      let reg = Registry
                  { concepts = [("Oven", Nothing)]
                  , axioms = [ForAll "o" (Implies (Predicate "Oven" [Var "o"]) 
                                (And (Predicate "gt" [Var "temperature", Constant "100"])
                                     (Predicate "lt" [Var "temperature", Constant "250"])))]
                  , properties = [Property "temperature" "Oven" "Integer"]
                  }
          code = emitPython reg
          script = 
            code ++ "\n" ++
            "from pydantic import ValidationError\n" ++
            "# Valid should succeed\n" ++
            "o1 = Oven(temperature=150)\n" ++
            "assert o1.temperature == 150\n" ++
            "# Invalid (< 100) should raise ValidationError\n" ++
            "try:\n" ++
            "    Oven(temperature=50)\n" ++
            "    sys.exit(1)\n" ++
            "except ValidationError:\n" ++
            "    pass\n" ++
            "# Invalid (> 250) should raise ValidationError\n" ++
            "try:\n" ++
            "    Oven(temperature=300)\n" ++
            "    sys.exit(1)\n" ++
            "except ValidationError:\n" ++
            "    pass\n"
      (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", script] ""
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""
```

- [ ] **Step 2: Add JUnit 5 test in `models-java/src/test/java/com/ontologic/models/ValidationBehaviorTest.java`**

Create `models-java/src/test/java/com/ontologic/models/ValidationBehaviorTest.java`:
```java
package com.ontologic.models;

import com.acme.generated.*;
import jakarta.validation.*;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

public class ValidationBehaviorTest {

    private static Validator validator;

    @BeforeAll
    public static void setUp() {
        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @Test
    public void testAssetNullSerialNumberFailsValidation() {
        Asset asset = new Asset();
        Set<ConstraintViolation<Asset>> violations = validator.validate(asset);
        assertFalse(violations.isEmpty(), "Asset with null serial_number should have violations");
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("serial_number")));
    }

    @Test
    public void testValidAssetPassesValidation() {
        Asset asset = new Asset();
        asset.setSerial_number("SN-12345");
        Set<ConstraintViolation<Asset>> violations = validator.validate(asset);
        assertTrue(violations.isEmpty(), "Valid asset should have no violations");
    }

    @Test
    public void testGatewayMaxConnectionsConstraint() {
        Gateway gateway = new Gateway();
        gateway.setSerial_number("GW-001");
        gateway.setFirmware_ver("v1.0.0");
        gateway.setMax_connections(2); // Violates @Min(5)

        Set<ConstraintViolation<Gateway>> violations = validator.validate(gateway);
        assertFalse(violations.isEmpty());
        assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("max_connections")));

        gateway.setMax_connections(10); // Valid (>= 5)
        violations = validator.validate(gateway);
        assertTrue(violations.isEmpty());
    }
}
```

- [ ] **Step 3: Add JUnit dependencies to `models-java/build.gradle.kts`**

```kotlin
dependencies {
    implementation("jakarta.validation:jakarta.validation-api:3.0.2")
    runtimeOnly("org.hibernate.validator:hibernate-validator:8.0.1.Final")
    runtimeOnly("org.glassfish:jakarta.el:4.0.2")

    testImplementation("org.junit.jupiter:junit-jupiter:5.10.1")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
}
```

- [ ] **Step 4: Run Gradle test suite to verify Java validation**

Run: `./gradlew :models-java:test`
Expected: `BUILD SUCCESSFUL`, all JUnit tests pass.

- [ ] **Step 5: Run `stack test` to verify Haskell suite**

Run: `stack test`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add models-java/ test/PythonSpec.hs
git commit -m "test: add runtime validation tests for Python Pydantic models and Java Jakarta POJOs"
```

---

### Task 6: CLI Driver Options & Ergonomics Tests (`MainSpec.hs`)

**Files:**
- Create: `test/MainSpec.hs`

**Interfaces:**
- Consumes: `ontologic-exe` binary via `readProcessWithExitCode`
- Tests: Command-line arguments, missing parameters, exit codes, and output generation.

- [ ] **Step 1: Write `test/MainSpec.hs`**

```haskell
module MainSpec (spec) where

import Test.Hspec
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (removeDirectoryRecursive, doesFileExist, createDirectoryIfMissing)
import System.FilePath ((</>))

spec :: Spec
spec = do
  describe "CLI Driver (ontologic-exe)" $ do
    it "prints help when --help flag is passed" $ do
      (exitCode, stdout, _) <- readProcessWithExitCode "stack" ["exec", "ontologic-exe", "--", "--help"] ""
      exitCode `shouldBe` ExitSuccess
      stdout `shouldContain` "Usage:"
      stdout `shouldContain` "--input"
      stdout `shouldContain` "--target"

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
```

- [ ] **Step 2: Run test to verify it passes**

Run: `stack test --test-arguments="-m Driver"`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/MainSpec.hs
git commit -m "test: add comprehensive CLI driver test suite for arguments, flags, and exits"
```

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-09-05-robust-test-suite.md`.

Execute using Subagent-Driven Development with test-driven development, continuous verification, and final code review.
