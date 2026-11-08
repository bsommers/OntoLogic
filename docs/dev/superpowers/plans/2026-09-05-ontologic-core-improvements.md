# OntoLogic Core Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix critical bugs in emitters (OWL XML syntax, Python topological ordering, Neo4j metamodel/instance conflation), extend type & numeric support (signed numbers, Float/Double bounds, Object Properties), enhance semantic linting (symbol table, cross-axiom contradictions), and improve developer experience (CLI ergonomics, build hygiene).

**Architecture:** The compiler follows a functional pipeline: Lexer/Parser (`Parser.hs`) $\to$ AST/IR (`OntoLogic.hs`) $\to$ Semantic Linter (`Linter.hs`) $\to$ Code Emitters (`Emitters/*.hs`). The plan introduces topological class ordering using `Data.Graph`, enhances `Linter.hs` with symbol resolution and interval checks across axioms, patches XML namespaces in `Owl.hs`, updates Cypher generation in `Neo4j.hs`, and supports signed numbers and decimal validations in `Java.hs` and `Python.hs`.

**Tech Stack:** Haskell (GHC 9.6+, Megaparsec 9+, containers, Hspec), Java 17 (Jakarta Bean Validation 3.0), Python 3.11+ (Pydantic v2), Neo4j 5.12+ (Cypher), Gradle 8.4.

## Global Constraints

- Preserve all existing passes in `stack test` without breaking backward compatibility for valid `.logic` models.
- All code changes must adhere to GHC Haskell best practices with zero compiler warnings under `-Wall`.
- Do not introduce external Haskell package dependencies beyond existing packages in `package.yaml` (`containers`, `megaparsec`, `text`, `filepath`, etc.).
- Maintain documentation integrity and update test specifications to cover new features and bugfixes.

---

### Task 1: Fix OWL Emitter XML Syntax & Add OwlSpec

**Files:**
- Modify: `src/Emitters/Owl.hs`
- Create: `test/OwlSpec.hs`
- Modify: `package.yaml`

**Interfaces:**
- Consumes: `Registry` from `OntoLogic.hs`
- Produces: `emitOwl :: Registry -> String` generating well-formed RDF/XML with valid W3C namespaces (`xmlns:rdf`, `xmlns:rdfs`, `xmlns:owl`, `xml:base`).

- [ ] **Step 1: Write the failing test**

Create `test/OwlSpec.hs`:
```haskell
module OwlSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Owl (emitOwl)
import Data.List (isInfixOf)

spec :: Spec
spec = do
  describe "OWL Emitter" $ do
    it "emits well-formed XML with standard RDF/OWL namespaces" $ do
      let reg = Registry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = []
                  , properties = [Property "serial_number" "Asset" "String"]
                  }
          xml = emitOwl reg
      xml `shouldSatisfy` isInfixOf "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\""
      xml `shouldSatisfy` isInfixOf "xmlns:owl=\"http://www.w3.org/2002/07/owl#\""
      xml `shouldSatisfy` isInfixOf "xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\""
      xml `shouldSatisfy` isInfixOf "<owl:Ontology"
      xml `shouldSatisfy` isInfixOf "<owl:Class rdf:about=\"#Asset\"/>"
      xml `shouldSatisfy` isInfixOf "<owl:Class rdf:about=\"#Device\"><rdfs:subClassOf rdf:resource=\"#Asset\"/></owl:Class>"
      xml `shouldSatisfy` isInfixOf "</rdf:RDF>"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test --test-arguments="-m OWL"`
Expected: FAIL due to missing namespaces and unclosed root element.

- [ ] **Step 3: Implement the fix in `src/Emitters/Owl.hs`**

Update `xmlHeader` and `ontologyHeader`:
```haskell
module Emitters.Owl where

import OntoLogic

emitOwl :: Registry -> String
emitOwl reg = 
    xmlHeader ++
    ontologyHeader ++
    concatMap emitClass (concepts reg) ++
    concatMap emitProperty (properties reg) ++
    xmlFooter

xmlHeader :: String
xmlHeader = "<?xml version=\"1.0\"?>\n" ++
            "<rdf:RDF xmlns=\"http://www.acme.com/ontologies/fleet#\"\n" ++
            "         xml:base=\"http://www.acme.com/ontologies/fleet\"\n" ++
            "         xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n" ++
            "         xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"\n" ++
            "         xmlns:owl=\"http://www.w3.org/2002/07/owl#\">\n"

ontologyHeader :: String
ontologyHeader = "    <owl:Ontology rdf:about=\"http://www.acme.com/ontologies/fleet\"/>\n"

xmlFooter :: String
xmlFooter = "</rdf:RDF>\n"

emitClass :: (Name, Maybe Name) -> String
emitClass (name, Nothing) = "    <owl:Class rdf:about=\"#" ++ name ++ "\"/>\n"
emitClass (name, Just parent) = "    <owl:Class rdf:about=\"#" ++ name ++ "\"><rdfs:subClassOf rdf:resource=\"#" ++ parent ++ "\"/></owl:Class>\n"

emitProperty :: Property -> String
emitProperty p = "    <owl:DatatypeProperty rdf:about=\"#" ++ propName p ++ "\">\n" ++
                 "        <rdfs:domain rdf:resource=\"#" ++ domain p ++ "\"/>\n" ++
                 "    </owl:DatatypeProperty>\n"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `stack test --test-arguments="-m OWL"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Emitters/Owl.hs test/OwlSpec.hs
git commit -m "fix(owl): emit well-formed RDF/XML with standard W3C namespaces"
```

---

### Task 2: Fix Python Emitter Class Ordering via Topological Sort

**Files:**
- Modify: `src/Emitters/Python.hs`
- Modify: `test/PythonSpec.hs`

**Interfaces:**
- Consumes: `concepts :: [(Name, Maybe Name)]` from `Registry`
- Produces: `emitPython :: Registry -> String` with concepts topologically sorted (ancestors before subclasses).

- [ ] **Step 1: Write the failing test in `test/PythonSpec.hs`**

Add test for out-of-order concepts:
```haskell
    it "emits classes in topological order so base classes precede subclasses" $ do
      -- Child "Sensor" appears before parent "Device", which appears before parent "Asset"
      let reg = Registry
                  { concepts = [("Sensor", Just "Device"), ("Device", Just "Asset"), ("Asset", Nothing)]
                  , axioms = []
                  , properties = []
                  }
          content = emitPython reg
          posAsset = head [i | (i, s) <- zip [0..] (lines content), "class Asset" `isInfixOf` s]
          posDevice = head [i | (i, s) <- zip [0..] (lines content), "class Device" `isInfixOf` s]
          posSensor = head [i | (i, s) <- zip [0..] (lines content), "class Sensor" `isInfixOf` s]
      posAsset < posDevice `shouldBe` True
      posDevice < posSensor `shouldBe` True
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test --test-arguments="-m topological"`
Expected: FAIL because `Sensor` is emitted first.

- [ ] **Step 3: Implement topological sort in `src/Emitters/Python.hs`**

Use `Data.Graph` to sort concepts:
```haskell
import Data.Graph (graphFromEdges, topSort)
import Data.List (intercalate, isInfixOf)

topologicalSortConcepts :: [(Name, Maybe Name)] -> [(Name, Maybe Name)]
topologicalSortConcepts conceptList =
    let edges = [ (c, fst c, maybe [] (\p -> [p]) (snd c)) | c <- conceptList ]
        (graph, nodeFromVertex, _) = graphFromEdges edges
        sortedVertices = reverse (topSort graph)
    in map (\v -> let (c, _, _) = nodeFromVertex v in c) sortedVertices
```
Apply `topologicalSortConcepts` to `concepts reg` in `emitPython`:
```haskell
emitPython :: Registry -> String
emitPython reg = 
    let sortedConcepts = topologicalSortConcepts (concepts reg)
    in "from pydantic import BaseModel, Field\n" ++
       "from typing import Optional, List\n\n" ++
       concatMap (emitPythonClass sortedConcepts (axioms reg) (properties reg)) sortedConcepts
```

- [ ] **Step 4: Run test to verify it passes**

Run: `stack test --test-arguments="-m topological"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Emitters/Python.hs test/PythonSpec.hs
git commit -m "fix(python): sort classes topologically to prevent NameError on subclass inheritance"
```

---

### Task 3: Decouple TBox and ABox in Neo4j Emitter & Modernize Cypher

**Files:**
- Modify: `src/Emitters/Neo4j.hs`
- Modify: `test/Neo4jSpec.hs`

**Interfaces:**
- Consumes: `Registry`
- Produces: `emitCypher :: Registry -> String` with distinct `:OntologyClass` nodes for metamodel and `elementId(n)` in audit queries.

- [ ] **Step 1: Write the failing test in `test/Neo4jSpec.hs`**

Update `test/Neo4jSpec.hs` to assert `:OntologyClass` for taxonomy nodes and `elementId(n)` for audits:
```haskell
    it "generates OntologyClass taxonomy nodes and modern elementId audits" $ do
      let reg = Registry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = [ForAll "d" (Implies (Predicate "Device" [Var "d"]) (Predicate "gt" [Var "connections", Constant "0"]))]
                  , properties = [Property "connections" "Device" "Integer"]
                  }
          content = emitCypher reg
      content `shouldContain` "MERGE (n:OntologyClass {name: 'Asset'})"
      content `shouldContain` "MERGE (n:OntologyClass {name: 'Device'})"
      content `shouldContain` "MERGE (n)-[:SUBCLASS_OF]->(p:OntologyClass {name: 'Asset'})"
      content `shouldContain` "CREATE CONSTRAINT IF NOT EXISTS FOR (n:Device) REQUIRE n.connections IS NOT NULL;"
      content `shouldContain` "RETURN elementId(n) AS invalid_node_id;"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test --test-arguments="-m Neo4j"`
Expected: FAIL due to legacy `id(n)` and `:Asset {name: 'Asset'}` syntax.

- [ ] **Step 3: Implement fix in `src/Emitters/Neo4j.hs`**

Update `emitNode` and `emitAuditQuery`:
```haskell
emitNode :: (Name, Maybe Name) -> String
emitNode (name, parent) = 
    "MERGE (n:OntologyClass {name: '" ++ name ++ "'})\n" ++
    maybe "" (\p -> "MERGE (p:OntologyClass {name: '" ++ p ++ "'})\nMERGE (n)-[:SUBCLASS_OF]->(p)\n") parent

emitAuditQuery :: Registry -> Name -> (String, String, String) -> String
emitAuditQuery reg conceptName (prop, op, val) =
    let cypherOp = mapCypherOp op
        cypherVal = formatCypherValue reg prop val
    in "// Axiom validation: " ++ conceptName ++ " " ++ prop ++ " " ++ op ++ " " ++ val ++ "\n" ++
       "MATCH (n:" ++ conceptName ++ ") WHERE NOT (n." ++ prop ++ " " ++ cypherOp ++ " " ++ cypherVal ++ ") RETURN elementId(n) AS invalid_node_id;\n"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `stack test --test-arguments="-m Neo4j"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Emitters/Neo4j.hs test/Neo4jSpec.hs
git commit -m "fix(neo4j): decouple ontology class nodes from data instances and use elementId"
```

---

### Task 4: Support Signed Numbers in Parser & Float/Double in Java/Python

**Files:**
- Modify: `src/Parser.hs`
- Modify: `src/Emitters/Java.hs`
- Modify: `src/Emitters/Python.hs`
- Modify: `test/ParserSpec.hs`
- Modify: `test/JavaSpec.hs`
- Modify: `test/PythonSpec.hs`

**Interfaces:**
- Parser: parses negative decimals and floats via `L.signed sc`
- Java Emitter: maps `Float` / `Double` to `@DecimalMin` / `@DecimalMax`
- Python Emitter: maps `Float` / `Double` to `float` with `Field(gt=..., lt=...)`

- [ ] **Step 1: Write failing tests**

In `test/ParserSpec.hs`:
```haskell
    it "parses signed negative numbers" $ do
      parse parseTerm "" "-42" `shouldBe` Right (Constant "-42")
      parse parseTerm "" "-15.5" `shouldBe` Right (Constant "-15.5")
```
In `test/JavaSpec.hs`:
```haskell
    it "generates @DecimalMin and @DecimalMax for Double/Float properties" $ do
      let reg = Registry
                  { concepts = [("Freezer", Nothing)]
                  , axioms = [ForAll "f" (Implies (Predicate "Freezer" [Var "f"])
                                (And (Predicate "gt" [Var "temperature", Constant "-20.5"])
                                     (Predicate "lte" [Var "temperature", Constant "0.0"])))]
                  , properties = [Property "temperature" "Freezer" "Double"]
                  }
          files = emitJava reg
          (_, code) = head files
      code `shouldContain` "private Double temperature;"
      code `shouldContain` "@DecimalMin(value = \"-20.5\", inclusive = false)"
      code `shouldContain` "@DecimalMax(\"0.0\")"
```
In `test/PythonSpec.hs`:
```haskell
    it "generates range bounds for Float properties" $ do
      let reg = Registry
                  { concepts = [("Freezer", Nothing)]
                  , axioms = [ForAll "f" (Implies (Predicate "Freezer" [Var "f"])
                                (And (Predicate "gte" [Var "temperature", Constant "-20.5"])
                                     (Predicate "lt" [Var "temperature", Constant "0.0"])))]
                  , properties = [Property "temperature" "Freezer" "Float"]
                  }
          code = emitPython reg
      code `shouldContain` "temperature: float = Field(ge=-20.5, lt=0.0)"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `stack test`
Expected: FAIL on signed numbers and decimal constraint annotations.

- [ ] **Step 3: Implement signed parsing in `src/Parser.hs`**

Update `parseTerm`:
```haskell
parseTerm :: Parser Term
parseTerm = (Constant <$> try stringLiteral) 
        <|> (try (Constant . show <$> L.signed sc L.float))
        <|> (try (Constant . show <$> L.signed sc L.decimal))
        <|> (Var <$> identifier)
```

- [ ] **Step 4: Implement Float/Double support in `Java.hs` and `Python.hs`**

In `Java.hs`:
Support `Float` and `Double` in `mapType`, `mapConstraintToAnnotation`:
```haskell
mapConstraintToAnnotation :: String -> (String, String, String) -> String
mapConstraintToAnnotation "Integer" (_, "gt", val) =
    case readMaybe val :: Maybe Integer of
        Just n  -> "    @Min(" ++ show (n + 1) ++ ")\n"
        Nothing -> ""
mapConstraintToAnnotation "Integer" (_, "gte", val) =
    case readMaybe val :: Maybe Integer of
        Just n  -> "    @Min(" ++ show n ++ ")\n"
        Nothing -> ""
mapConstraintToAnnotation "Integer" (_, "lt", val) =
    case readMaybe val :: Maybe Integer of
        Just n  -> "    @Max(" ++ show (n - 1) ++ ")\n"
        Nothing -> ""
mapConstraintToAnnotation "Integer" (_, "lte", val) =
    case readMaybe val :: Maybe Integer of
        Just n  -> "    @Max(" ++ show n ++ ")\n"
        Nothing -> ""
mapConstraintToAnnotation rType (_, "gt", val) | rType `elem` ["Float", "Double"] =
    "    @DecimalMin(value = \"" ++ val ++ "\", inclusive = false)\n"
mapConstraintToAnnotation rType (_, "gte", val) | rType `elem` ["Float", "Double"] =
    "    @DecimalMin(\"" ++ val ++ "\")\n"
mapConstraintToAnnotation rType (_, "lt", val) | rType `elem` ["Float", "Double"] =
    "    @DecimalMax(value = \"" ++ val ++ "\", inclusive = false)\n"
mapConstraintToAnnotation rType (_, "lte", val) | rType `elem` ["Float", "Double"] =
    "    @DecimalMax(\"" ++ val ++ "\")\n"
mapConstraintToAnnotation _ _ = ""
```
In `Python.hs`:
Support `Float` and `Double` in `mapConstraintToPydantic`:
```haskell
mapConstraintToPydantic :: String -> [(String, String, String)] -> String
mapConstraintToPydantic rType constraints = 
    if not (rType `elem` ["Integer", "Float", "Double"])
    then ""
    else let args = filter (not . null) (map mapOpt constraints)
          in intercalate ", " args
```
Update `mapType`:
```haskell
mapType "Integer" = "int"
mapType "Float"   = "float"
mapType "Double"  = "float"
mapType "Boolean" = "bool"
mapType _         = "str"
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `stack test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/Parser.hs src/Emitters/Java.hs src/Emitters/Python.hs test/
git commit -m "feat: add signed number parsing and Float/Double constraint support in Java and Python"
```

---

### Task 5: Semantic Validation in Linter (Symbol Table, Undeclared References, Duplicates)

**Files:**
- Modify: `src/Linter.hs`
- Modify: `test/ParserSpec.hs` (or create `test/LinterSpec.hs`)

**Interfaces:**
- Consumes: `Registry`
- Produces: `checkSymbolIntegrity :: Registry -> [String]` integrated into `lintRegistry :: Registry -> [String]`

- [ ] **Step 1: Write failing tests for symbol validation**

In `test/ParserSpec.hs`:
```haskell
    it "detects undeclared parent concepts" $ do
      let reg = Registry [("Sensor", Just "NonExistentParent")] [] []
      lintRegistry reg `shouldContain` ["Undeclared parent concept: NonExistentParent referenced by Sensor"]

    it "detects undeclared property domain concepts" $ do
      let reg = Registry [("Sensor", Nothing)] [] [Property "temp" "UnknownConcept" "Integer"]
      lintRegistry reg `shouldContain` ["Undeclared domain concept: UnknownConcept in property temp"]

    it "detects duplicate concept definitions" $ do
      let reg = Registry [("Asset", Nothing), ("Asset", Nothing)] [] []
      lintRegistry reg `shouldContain` ["Duplicate concept definition: Asset"]

    it "detects duplicate property definitions on the same concept" $ do
      let reg = Registry [("Asset", Nothing)] [] 
                  [ Property "serial" "Asset" "String"
                  , Property "serial" "Asset" "Integer"
                  ]
      lintRegistry reg `shouldContain` ["Duplicate property definition: serial on concept Asset"]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test --test-arguments="-m undeclared"`
Expected: FAIL

- [ ] **Step 3: Implement `checkSymbolIntegrity` in `src/Linter.hs`**

```haskell
checkSymbolIntegrity :: Registry -> [String]
checkSymbolIntegrity reg =
    checkDuplicateConcepts (concepts reg) ++
    checkDuplicateProperties (properties reg) ++
    checkUndeclaredParents (concepts reg) ++
    checkUndeclaredDomains (concepts reg) (properties reg)

checkDuplicateConcepts :: [(Name, Maybe Name)] -> [String]
checkDuplicateConcepts cList =
    [ "Duplicate concept definition: " ++ name
    | (name, count) <- countOccurrences (map fst cList)
    , count > 1
    ]

checkDuplicateProperties :: [Property] -> [String]
checkDuplicateProperties pList =
    [ "Duplicate property definition: " ++ p ++ " on concept " ++ d
    | ((p, d), count) <- countOccurrences [ (propName p, domain p) | p <- pList ]
    , count > 1
    ]

checkUndeclaredParents :: [(Name, Maybe Name)] -> [String]
checkUndeclaredParents cList =
    let knownConcepts = Set.fromList (map fst cList)
    in [ "Undeclared parent concept: " ++ parent ++ " referenced by " ++ name
       | (name, Just parent) <- cList
       , not (Set.member parent knownConcepts)
       ]

checkUndeclaredDomains :: [(Name, Maybe Name)] -> [Property] -> [String]
checkUndeclaredDomains cList pList =
    let knownConcepts = Set.fromList (map fst cList)
    in [ "Undeclared domain concept: " ++ domain p ++ " in property " ++ propName p
       | p <- pList
       , not (Set.member (domain p) knownConcepts)
       ]

countOccurrences :: Ord a => [a] -> [(a, Int)]
countOccurrences xs = Map.toList (Map.fromListWith (+) [ (x, 1) | x <- xs ])
```
Add `checkSymbolIntegrity reg` to `lintRegistry`:
```haskell
lintRegistry :: Registry -> [String]
lintRegistry reg = 
    checkSymbolIntegrity reg ++
    checkCircularInheritance (Map.fromList $ concepts reg) ++ 
    checkContradictoryAxioms (axioms reg)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `stack test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Linter.hs test/ParserSpec.hs
git commit -m "feat(linter): add symbol table validation for undeclared parents, domains, and duplicates"
```

---

### Task 6: Cross-Axiom & Inheritance Interval Contradiction Checking

**Files:**
- Modify: `src/Linter.hs`
- Modify: `test/ParserSpec.hs`

**Interfaces:**
- Consumes: `Registry`
- Produces: `checkGlobalPropertyContradictions :: Registry -> [String]` in `lintRegistry`

- [ ] **Step 1: Write failing test in `test/ParserSpec.hs`**

```haskell
    it "detects contradictions across multiple separate axioms on the same concept" $ do
      let axiomsList =
            [ ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "temp", Constant "100"]))
            , ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "lt" [Var "temp", Constant "50"]))
            ]
          reg = Registry [("Sensor", Nothing)] axiomsList [Property "temp" "Sensor" "Integer"]
      lintRegistry reg `shouldContain` ["Cross-axiom contradiction on Sensor.temp: gt 100 and lt 50"]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `stack test --test-arguments="-m separate"`
Expected: FAIL because axioms are only checked individually.

- [ ] **Step 3: Implement cross-axiom constraint audit in `src/Linter.hs`**

```haskell
checkGlobalPropertyContradictions :: Registry -> [String]
checkGlobalPropertyContradictions reg =
    concatMap (checkConceptAxioms reg) (map fst (concepts reg))

checkConceptAxioms :: Registry -> Name -> [String]
checkConceptAxioms reg conceptName =
    let consts = getLocalConstraints conceptName (axioms reg)
        grouped = Map.fromListWith (++) [ (prop, [(op, val)]) | (prop, op, val) <- consts ]
    in concatMap (reportCrossContradictions conceptName) (Map.toList grouped)

reportCrossContradictions :: Name -> (String, [(String, String)]) -> [String]
reportCrossContradictions cName (prop, cs) =
    [ "Cross-axiom contradiction on " ++ cName ++ "." ++ prop ++ ": " ++ op1 ++ " " ++ v1 ++ " and " ++ op2 ++ " " ++ v2
    | (op1, v1) <- cs
    , (op2, v2) <- cs
    , isContradictoryPair (op1, v1) (op2, v2)
    ]
  where
    isContradictoryPair ("gt", val1) ("lt", val2) =
      case (readMaybe val1 :: Maybe Double, readMaybe val2 :: Maybe Double) of
        (Just n1, Just n2) -> n1 >= n2
        _ -> False
    isContradictoryPair _ _ = False
```

- [ ] **Step 4: Run test to verify it passes**

Run: `stack test`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/Linter.hs test/ParserSpec.hs
git commit -m "feat(linter): detect cross-axiom contradictions on identical concept properties"
```

---

### Task 7: CLI Ergonomics, Gradle Wrapper, and Build Hygiene

**Files:**
- Modify: `src/Main.hs`
- Modify: `.gitignore`
- Modify: `build.gradle.kts`
- Modify: `models-java/build.gradle.kts`

**Interfaces:**
- CLI: `-o` is optional when `-t lint`
- Gradle: wrapper files committed, generated sources directed to `build/generated`

- [ ] **Step 1: Make `-o` optional for lint in `src/Main.hs`**

Change `Args`:
```haskell
data Args = Args
  { input  :: String
  , target :: String
  , output :: Maybe String
  , render :: Bool
  }
```
In `main`:
```haskell
Right registry -> do
    let errors = lintRegistry registry
    if not (null errors)
        then mapM_ putStrLn errors >> error "Validation Failed."
        else case (target args, output args) of
            ("lint", _) -> processTarget "lint" "." (render args) registry
            (t, Just out) -> processTarget t out (render args) registry
            (t, Nothing) -> putStrLn ("Error: --output is required for target: " ++ t) >> exitFailure
```

- [ ] **Step 2: Clean up `.gitignore`**

Remove `gradlew`, `gradlew.bat`, `gradle/` from `.gitignore`. Add `models-java/src/generated/` to `.gitignore` or clean up build generated directories.

- [ ] **Step 3: Generate and commit Gradle wrapper**

Run: `gradle wrapper`
Verify: `./gradlew --version` and `./gradlew build` succeed.

- [ ] **Step 4: Verify end-to-end build**

Run:
1. `stack test`
2. `stack exec ontologic-exe -- -i logic/fleet.logic -t lint` (no `-o` flag)
3. `./gradlew build`
4. `./gradlew :app-java:run`

- [ ] **Step 5: Commit**

```bash
git add src/Main.hs .gitignore gradlew gradlew.bat gradle/
git commit -m "feat(cli): make output flag optional for lint and restore gradle wrapper"
```

---

## Execution Handoff

Plan complete and saved to `docs/dev/superpowers/plans/2026-09-05-ontologic-core-improvements.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration
**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
