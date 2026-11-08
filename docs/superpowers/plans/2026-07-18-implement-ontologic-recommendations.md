# Implement OntoLogic Recommendations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve compilation bugs in the Java emitter, implement axiom-based validation in Python/Java/Cypher, improve linter validations, complete Java app entry point, and expand testing coverage.

**Architecture:** 
1. Refactor `Main.hs` and `Emitters.Java` to output separate `.java` files for each concept.
2. Implement axiom extraction inside the compiler and compile local concept range/equality constraints into Java Jakarta annotations (`@Min`, `@Max`, `@AssertTrue`), Python Pydantic validators, and Neo4j Cypher assertions.
3. Improve `Linter.hs` to perform basic propositional simplification and contradiction checks on axioms.
4. Add a JVM entrypoint in `app-java` and unit test assertions in `test/ParserSpec.hs`.

**Tech Stack:** Haskell (Megaparsec, GHC), Java (Gradle, Jakarta Validation), Python (Pydantic), Neo4j (Cypher).

## Global Constraints
- Target compatibility for Java is Java 17.
- Python constraints use Pydantic v2.5.2.
- Haskell code must compile cleanly using Stack (GHC 9.4.8).

---

### Task 1: Fix Java Emitter to Generate Separate Files

**Files:**
- Modify: `src/Emitters/Java.hs`
- Modify: `src/Main.hs`

**Interfaces:**
- `emitJava` changes type signature:
  - Consumes: `Registry`
  - Produces: `[(String, String)]` (List of tuples: `(ClassName, FileContent)`)

- [ ] **Step 1: Update `src/Emitters/Java.hs` to return a list of files**
  Rewrite `emitJava` to map each concept to a separate class definition string, including packages and imports per file.
  ```haskell
  module Emitters.Java where

  import OntoLogic

  emitJava :: Registry -> [(String, String)]
  emitJava reg = 
      map (\(name, parent) -> (name, emitJavaClass (properties reg) (name, parent))) (concepts reg)

  emitJavaClass :: [Property] -> (Name, Maybe Name) -> String
  emitJavaClass allProps (name, parent) = 
      "package com.acme.generated;\n" ++
      "import jakarta.validation.constraints.*;\n\n" ++
      "public class " ++ name ++ maybe "" (\p -> " extends " ++ p) parent ++ " {\n" ++
      concatMap emitField (filter (\p -> domain p == name) allProps) ++
      "}\n"

  emitField :: Property -> String
  emitField p = "    @NotNull\n    private " ++ mapType (rangeType p) ++ " " ++ propName p ++ ";\n"

  mapType :: String -> String
  mapType "Integer" = "Integer"
  mapType "Boolean" = "boolean"
  mapType _         = "String"
  ```

- [ ] **Step 2: Update `src/Main.hs` to write multiple files for Java target**
  Modify the `processTarget "java"` handler to iterate over the list of files returned by `emitJava` and write them to the output directory.
  ```haskell
  -- In Main.hs
  processTarget "java" out _ reg = do
      mapM_ (\(name, content) -> writeFile (out ++ "/" ++ name ++ ".java") content) (emitJava reg)
      putStrLn $ "Generated Java models in " ++ out
  ```

- [ ] **Step 3: Run stack test to verify compilation**
  Run: `stack test`
  Expected: Success

---

### Task 2: Implement Axiom Property Constraint Extraction

**Files:**
- Modify: `src/OntoLogic.hs`
- Modify: `src/Emitters/Java.hs`
- Modify: `src/Emitters/Python.hs`
- Modify: `src/Emitters/Neo4j.hs`

**Interfaces:**
- Add `getLocalConstraints :: Name -> [FOL] -> [(Name, String, String)]` to extract constraints.
  - Consumes: Concept `Name`, list of axioms `[FOL]`
  - Produces: List of constraints `(PropName, Operator, Value)` (e.g. `("temperature", "lt", "5")`)

- [ ] **Step 1: Write local constraint extractor in `src/OntoLogic.hs`**
  Add helper functions to traverse FOL terms and find simple range conditions.
  ```haskell
  -- Add to OntoLogic.hs
  getLocalConstraints :: Name -> [FOL] -> [(String, String, String)]
  getLocalConstraints conceptName axiomsList = concatMap extract axiomsList
    where
      extract (ForAll _ body) = extract body
      extract (Implies cond body) = 
          if matchesConcept cond 
          then extractSimplePredicates body
          else []
      extract _ = []

      matchesConcept (Predicate name [Var _]) = name == conceptName
      matchesConcept (And p1 _) = matchesConcept p1
      matchesConcept _ = False

      extractSimplePredicates (Predicate op [Var prop, Constant val]) = [(prop, op, val)]
      extractSimplePredicates (And p1 p2) = extractSimplePredicates p1 ++ extractSimplePredicates p2
      extractSimplePredicates _ = []
  ```

- [ ] **Step 2: Integrate constraints into `src/Emitters/Java.hs`**
  Map operators (`gt`, `lt`, `gte`, `lte`) to Jakarta annotations (`@Min`, `@Max`).
  ```haskell
  -- Update emitField in Java.hs
  emitFieldWithConstraints :: [(String, String, String)] -> Property -> String
  emitFieldWithConstraints consts p = 
      let pConsts = filter (\(name, _, _) -> name == propName p) consts
          annotations = concatMap mapConstraintToAnnotation pConsts
      in "    @NotNull\n" ++ annotations ++ "    private " ++ mapType (rangeType p) ++ " " ++ propName p ++ ";\n"

  mapConstraintToAnnotation :: (String, String, String) -> String
  mapConstraintToAnnotation (_, "gt", val)  = "    @Min(" ++ show (read val + 1 :: Integer) ++ ")\n"
  mapConstraintToAnnotation (_, "gte", val) = "    @Min(" ++ val ++ ")\n"
  mapConstraintToAnnotation (_, "lt", val)  = "    @Max(" ++ show (read val - 1 :: Integer) ++ ")\n"
  mapConstraintToAnnotation (_, "lte", val) = "    @Max(" ++ val ++ ")\n"
  mapConstraintToAnnotation _ = ""
  ```

- [ ] **Step 3: Integrate constraints into `src/Emitters/Python.hs`**
  Generate field validators or annotation constraints (using `Field(gt=...)` or similar Pydantic constructs).
  ```haskell
  -- In Emitters/Python.hs
  emitFieldWithConstraints :: [(String, String, String)] -> Property -> String
  emitFieldWithConstraints consts p =
      let pConsts = filter (\(name, _, _) -> name == propName p) consts
          fieldArgs = mapConstraintToPydantic pConsts
          fieldStr = if null fieldArgs then "" else " = Field(" ++ fieldArgs ++ ")"
      in "    " ++ propName p ++ ": " ++ mapType (rangeType p) ++ fieldStr ++ "\n"

  mapConstraintToPydantic :: [(String, String, String)] -> String
  mapConstraintToPydantic constraints =
      let args = concatMap mapOpt constraints
      in if null args then "" else init args
    where
      mapOpt (_, "gt", val)  = "gt=" ++ val ++ ", "
      mapOpt (_, "gte", val) = "ge=" ++ val ++ ", "
      mapOpt (_, "lt", val)  = "lt=" ++ val ++ ", "
      mapOpt (_, "lte", val) = "le=" ++ val ++ ", "
      mapOpt _ = ""
  ```

- [ ] **Step 4: Verify test suite still compiles**
  Run: `stack test`
  Expected: Success

---

### Task 3: Create JVM Application and Compile Java Subprojects

**Files:**
- Create: `app-java/src/main/java/com/ontologic/app/Main.java`
- Modify: `app-java/build.gradle.kts`

- [ ] **Step 1: Write Java Main application**
  Provide an entry point showing validation of compiled entities.
  ```java
  package com.ontologic.app;

  import com.acme.generated.*;
  import jakarta.validation.*;
  import java.util.Set;

  public class Main {
      public static void main(String[] args) {
          ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
          Validator validator = factory.getValidator();

          System.out.println("Running OntoLogic JVM validation tests...");
          // Test compilation
          Asset asset = new Asset();
          System.out.println("Java POJO Classes loaded successfully.");
      }
  }
  ```

- [ ] **Step 2: Add resources structure and build app**
  Run Gradle build on the Java subprojects to verify they compile.
  Run: `./gradlew compileJava`
  Expected: SUCCESS

---

### Task 4: Extend Haskell Test Suite with Compiler & Linter Tests

**Files:**
- Modify: `test/ParserSpec.hs`

- [ ] **Step 1: Add unit tests for linter cycle detection and local constraints**
  Add spec cases verifying circular inheritance detection and validator annotations are correctly emitted.
  ```haskell
  -- In ParserSpec.hs
  -- Under describe "Registry Parser":
  it "detects circular inheritance cycles" $ do
      let cyclicReg = Registry [("A", Just "B"), ("B", Just "A")] [] []
      lintRegistry cyclicReg `shouldContain` ["Circular inheritance: [\"A\",\"B\",\"A\"]"]
  ```

- [ ] **Step 2: Run all compiler tests**
  Run: `stack test`
  Expected: All tests pass.
