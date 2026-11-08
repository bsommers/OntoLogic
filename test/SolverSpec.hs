module SolverSpec (spec) where

import Test.Hspec
import OntoLogic
import Solver
import Control.Exception (bracket_)
import System.Environment (lookupEnv, setEnv, unsetEnv)
import System.Exit (ExitCode(..))
import Data.Either (isLeft)
import Data.List (isInfixOf)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)
import Loader (loadRegistryWithImports)
import System.Directory (findExecutable)
import System.Timeout (timeout)

spec :: Spec
spec = describe "Multi-Prover SMT Solver & Automated Proof-Checking Engine" $ do
    describe "Prover Configuration & Parsing" $ do
        it "parses supported prover names correctly" $ do
            parseProver "z3" `shouldBe` Just Z3
            parseProver "Z3" `shouldBe` Just Z3
            parseProver "cvc5" `shouldBe` Just CVC5
            parseProver "CVC5" `shouldBe` Just CVC5
            parseProver "vampire" `shouldBe` Just Vampire
            parseProver "native" `shouldBe` Just NativeProver
            parseProver "auto" `shouldBe` Just AutoProver
            parseProver "invalid-prover" `shouldBe` Nothing

        it "formats human-readable prover names" $ do
            proverName Z3 `shouldBe` "Z3"
            proverName CVC5 `shouldBe` "CVC5"
            proverName Vampire `shouldBe` "Vampire"
            proverName NativeProver `shouldBe` "Native"
            proverName AutoProver `shouldBe` "Auto (Z3/CVC5/Vampire/Native)"

    describe "Z3 Solver Backend" $ do
        it "proves a valid ontology is SMT Satisfiable (SAT) and produces a model" $ do
            let reg = emptyRegistry
                    { concepts = [("Vehicle", Nothing)]
                    , properties = [Property "speed" "Vehicle" PTInteger]
                    , axioms = [ForAll "v" (Implies (Predicate "Vehicle" [Var "v"])
                                                   (And (Predicate "gte" [Var "speed", Constant "0"])
                                                        (Predicate "lte" [Var "speed", Constant "120"])))]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- checkConsistencyWith Z3 reg
            case res of
                Sat model -> model `shouldContain` "Vehicle"
                _         -> expectationFailure $ "Expected Sat but got: " ++ show res

        it "detects SMT Unsatisfiability (UNSAT) when contradictory constraints are asserted" $ do
            let reg = emptyRegistry
                    { concepts = [("Sensor", Nothing)]
                    , properties = [Property "temp" "Sensor" PTInteger]
                    , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"])
                                                   (And (Predicate "gt" [Var "temp", Constant "100"])
                                                        (Predicate "lt" [Var "temp", Constant "50"])))]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- checkConsistencyWith Z3 reg
            res `shouldBe` Unsat

        it "proves taxonomic subsumption theorem (Car ⊑ Vehicle) via Z3" $ do
            let reg = emptyRegistry
                    { concepts = [("Vehicle", Nothing), ("Car", Just "Vehicle")]
                    , properties = [Property "speed" "Vehicle" PTInteger]
                    , axioms = []
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- proveSubsumptionWith Z3 reg "Car" "Vehicle"
            res `shouldBe` Subsumed

    describe "CVC5 Solver Backend" $ do
        it "proves a valid ontology is SMT Satisfiable (SAT) via CVC5" $ do
            let reg = emptyRegistry
                    { concepts = [("Device", Nothing)]
                    , properties = [Property "voltage" "Device" PTFloat]
                    , axioms = [ForAll "d" (Implies (Predicate "Device" [Var "d"])
                                                   (Predicate "gte" [Var "voltage", Constant "3.3"]))]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- checkConsistencyWith CVC5 reg
            case res of
                Sat model -> model `shouldContain` "Device"
                _         -> expectationFailure $ "Expected Sat but got: " ++ show res

        it "detects SMT Unsatisfiability (UNSAT) via CVC5" $ do
            let reg = emptyRegistry
                    { concepts = [("Alarm", Nothing)]
                    , properties = [Property "level" "Alarm" PTInteger]
                    , axioms = [ForAll "a" (Implies (Predicate "Alarm" [Var "a"])
                                                   (And (Predicate "gt" [Var "level", Constant "10"])
                                                        (Predicate "lt" [Var "level", Constant "5"])))]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- checkConsistencyWith CVC5 reg
            res `shouldBe` Unsat

        it "proves taxonomic subsumption theorem (Drone ⊑ Aircraft) via CVC5" $ do
            let reg = emptyRegistry
                    { concepts = [("Aircraft", Nothing), ("Drone", Just "Aircraft")]
                    , properties = []
                    , axioms = []
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- proveSubsumptionWith CVC5 reg "Drone" "Aircraft"
            res `shouldBe` Subsumed

        it "identifies unsatisfiable / empty concepts via CVC5" $ do
            let reg = emptyRegistry
                    { concepts = [("ValidNode", Nothing), ("ContradictoryNode", Nothing)]
                    , properties = [ Property "val" "ValidNode" PTInteger
                                   , Property "val" "ContradictoryNode" PTInteger
                                   ]
                    , axioms = [ ForAll "v" (Implies (Predicate "ValidNode" [Var "v"]) (Predicate "gte" [Var "val", Constant "0"]))
                               , ForAll "c" (Implies (Predicate "ContradictoryNode" [Var "c"])
                                                     (And (Predicate "gt" [Var "val", Constant "50"])
                                                          (Predicate "lt" [Var "val", Constant "20"])))
                               ]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            unsatList <- findUnsatConceptsWith CVC5 reg
            unsatList `shouldBe` Right ["ContradictoryNode"]

    describe "Vampire ATP Prover Backend" $ do
        let withVampire action = do
                mVampire <- findExecutable "vampire"
                case mVampire of
                    Nothing -> pendingWith "vampire not installed in PATH"
                    Just _  -> action

        it "proves a valid ontology is Satisfiable (SAT) via Vampire TPTP" $ withVampire $ do
            let reg = emptyRegistry
                    { concepts = [("Device", Nothing)]
                    , properties = []
                    , axioms = [ForAll "d" (Implies (Predicate "Device" [Var "d"])
                                                   (Predicate "Device" [Var "d"]))]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- checkConsistencyWith Vampire reg
            case res of
                Sat out -> out `shouldContain` "SZS status Satisfiable"
                _       -> expectationFailure $ "Expected Sat but got: " ++ show res

        it "detects Unsatisfiability (UNSAT) when contradictory axioms are asserted via Vampire" $ withVampire $ do
            let reg = emptyRegistry
                    { concepts = [("Sensor", Nothing)]
                    , axioms = [ ForAll "s" (Predicate "Sensor" [Var "s"])
                               , ForAll "s" (Not (Predicate "Sensor" [Var "s"]))
                               ]
                    }
            res <- checkConsistencyWith Vampire reg
            res `shouldBe` Unsat

        it "detects Unsatisfiability (UNSAT) with declared individuals via Vampire" $ withVampire $ do
            let reg = emptyRegistry
                    { concepts = [("Number", Nothing)]
                    , individuals = [("zero", Just "Number")]
                    , axioms = [ ForAll "x" (Not (Eq (Var "x") (Var "zero"))) ]
                    }
            res <- checkConsistencyWith Vampire reg
            res `shouldBe` Unsat

        it "proves taxonomic subsumption theorem (Drone ⊑ Aircraft) via Vampire TPTP" $ withVampire $ do
            let reg = emptyRegistry
                    { concepts = [("Aircraft", Nothing), ("Drone", Just "Aircraft")]
                    , properties = []
                    , axioms = []
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- proveSubsumptionWith Vampire reg "Drone" "Aircraft"
            res `shouldBe` Subsumed

        it "disproves subsumption and returns a counterexample when concepts are unrelated via Vampire" $ withVampire $ do
            let reg = emptyRegistry
                    { concepts = [("Car", Nothing), ("Airplane", Nothing)]
                    , properties = []
                    , axioms = []
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- proveSubsumptionWith Vampire reg "Car" "Airplane"
            case res of
                NotSubsumed model -> any (`isInfixOf` model) ["is_Car", "CounterSatisfiable", "Satisfiable"] `shouldBe` True
                _                 -> expectationFailure $ "Expected NotSubsumed but got: " ++ show res

        it "identifies unsatisfiable / empty concepts via Vampire TPTP" $ withVampire $ do
            let reg = emptyRegistry
                    { concepts = [("ValidNode", Nothing), ("BrokenNode", Nothing)]
                    , properties = []
                    , axioms = [ ForAll "b" (Implies (Predicate "BrokenNode" [Var "b"])
                                                     (Not (Predicate "BrokenNode" [Var "b"])))
                                ]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            unsatList <- findUnsatConceptsWith Vampire reg
            unsatList `shouldBe` Right ["BrokenNode"]

    describe "AutoProver Fallback & Subsumption General" $ do
        it "disproves subsumption and returns a counterexample when concepts are unrelated" $ do
            let reg = emptyRegistry
                    { concepts = [("Car", Nothing), ("Airplane", Nothing)]
                    , properties = []
                    , axioms = []
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            res <- proveSubsumption reg "Car" "Airplane"
            case res of
                NotSubsumed model -> model `shouldContain` "Car"
                _                 -> expectationFailure $ "Expected NotSubsumed but got: " ++ show res

        it "identifies unsatisfiable / empty concepts using default AutoProver" $ do
            let reg = emptyRegistry
                    { concepts = [("GoodConcept", Nothing), ("BrokenConcept", Nothing)]
                    , properties = [ Property "score" "GoodConcept" PTInteger
                                   , Property "score" "BrokenConcept" PTInteger
                                   ]
                    , axioms = [ ForAll "g" (Implies (Predicate "GoodConcept" [Var "g"]) (Predicate "gte" [Var "score", Constant "0"]))
                               , ForAll "b" (Implies (Predicate "BrokenConcept" [Var "b"])
                                                     (And (Predicate "gt" [Var "score", Constant "100"])
                                                          (Predicate "lt" [Var "score", Constant "10"])))
                               ]
                    , relations = []
                    , namespaces = []
                    , imports = []
                    }
            unsatList <- findUnsatConcepts reg
            unsatList `shouldBe` Right ["BrokenConcept"]

    describe "Solver failure reporting (#16)" $ do
        it "keeps the solver's stdout diagnostics in the error" $
            classifyOutput "Z3" (ExitFailure 1) "(error \"line 3 column 20: unknown constant e-3\")\n" ""
                `shouldSatisfy` either (\e -> case e of SolverFailed m -> "unknown constant e-3" `isInfixOf` m; _ -> False) (const False)

        it "accepts unsat followed by a get-model error" $
            classifyOutput "Z3" (ExitFailure 1) "unsat\n(error \"model is not available\")\n" ""
                `shouldBe` Right "unsat\n(error \"model is not available\")\n"

        it "reports an error from findUnsatConcepts when explicit external solver is not installed (#16)" $ do
            let reg = emptyReg { concepts = [("A", Nothing)] }
            res <- withPath "/nonexistent" (findUnsatConceptsWith Z3 reg)
            res `shouldSatisfy` isLeft

        it "falls back seamlessly to native prover when AutoProver is used without external solvers" $ do
            let reg = emptyReg { concepts = [("A", Nothing)] }
            res <- withPath "/nonexistent" (findUnsatConceptsWith AutoProver reg)
            res `shouldBe` Right []

        it "rejects unknown prover names and resolves native prover" $ do
            resolveProver (Just "z4") `shouldSatisfy` isLeft
            resolveProver Nothing `shouldBe` Right AutoProver
            resolveProver (Just "native") `shouldBe` Right NativeProver

    describe "Exit codes (#31)" $
        it "maps every solver result to a documented exit code" $ do
            solverExitCode (Sat "model") `shouldBe` ExitSuccess
            solverExitCode Unsat `shouldBe` ExitFailure 1
            solverExitCode (SolverError "boom") `shouldBe` ExitFailure 1
            solverExitCode (Unknown "unknown") `shouldBe` ExitFailure 2

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

        it "solves ontologies with binary property relations and boolean predicates (#58)" $ do
            let reg = load $ unlines
                  [ "(def-concept Device)"
                  , "(def-concept Sensor)"
                  , "(def-property connects_to Device Sensor)"
                  , "(def-property is_active Device Boolean)"
                  , "(forall (d s) (implies (connects_to d s) (Device d)))"
                  , "(forall (d) (implies (Device d) (eq is_active True)))"
                  ]
            untranslatedAxioms reg `shouldBe` []
            consistency <- checkConsistencyWith Z3 reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)
            findUnsatConceptsWith Z3 reg `shouldReturn` Right []

        it "solves irreflexive relations as satisfiable without false UNSAT contradictions" $ do
            let reg = load $ unlines
                  [ "(def-concept Thing)"
                  , "(def-relation lt Thing Thing)"
                  , "(forall (x) (not (lt x x)))"
                  ]
            consistency <- checkConsistencyWith Z3 reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)

        it "detects contradiction through declared individual via Z3" $ do
            let reg = load $ unlines
                  [ "(def-concept Number)"
                  , "(def-individual zero Number)"
                  , "(forall (x) (not (= x zero)))"
                  ]
            untranslatedAxioms reg `shouldBe` []
            consistency <- checkConsistencyWith Z3 reg
            consistency `shouldBe` Unsat

        it "detects contradiction through declared individual via CVC5" $ do
            let reg = load $ unlines
                  [ "(def-concept Number)"
                  , "(def-individual zero Number)"
                  , "(forall (x) (not (= x zero)))"
                  ]
            untranslatedAxioms reg `shouldBe` []
            consistency <- checkConsistencyWith CVC5 reg
            consistency `shouldBe` Unsat

        it "solves irreflexive relations as satisfiable without false UNSAT contradictions via CVC5" $ do
            let reg = load $ unlines
                  [ "(def-concept Thing)"
                  , "(def-relation lt Thing Thing)"
                  , "(forall (x) (not (lt x x)))"
                  ]
            consistency <- checkConsistencyWith CVC5 reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)

        it "checks bfo_2020 concepts in one solver run within 60s" $ do

            loaded <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
            case loaded of
              Left err -> expectationFailure err
              Right reg -> do
                r <- timeout 60000000 (findUnsatConceptsWith Z3 reg)
                r `shouldSatisfy` maybe False (either (const False) (const True))

        it "extracts valuation model from SAT result" $ do
            let reg = load "(def-concept Device) (def-property port Device Integer) (forall (d) (implies (Device d) (gt port 1000)))"
            res <- checkConsistencyWith Z3 reg
            case extractModel res of
                Just m  -> m `shouldContain` "define-fun"
                Nothing -> expectationFailure "Expected model extraction to succeed"

        it "identifies conflicting axioms via explainUnsatWith" $ do
            let reg = load $ unlines
                  [ "(def-concept A)"
                  , "(def-concept B)"
                  , "(def-relation r A B)"
                  , "(forall (x) (forall (y) (implies (and (A x) (B y)) (r x y))))"
                  , "(forall (x) (forall (y) (implies (and (A x) (B y)) (not (r x y)))))"
                  , "(exists (x) (A x))"
                  , "(exists (y) (B y))"
                  ]
            explRes <- explainUnsatWith Z3 reg
            case explRes of
                Left err -> expectationFailure err
                Right expl -> do
                    unsatCoreNames expl `shouldSatisfy` (\names -> length names >= 2)
                    unlines (unsatCoreDetails expl) `shouldContain` "Axiom #"

        it "identifies conflicting axioms via explainUnsatWith using CVC5" $ do
            let reg = load $ unlines
                  [ "(def-concept A)"
                  , "(def-concept B)"
                  , "(def-relation r A B)"
                  , "(forall (x) (forall (y) (implies (and (A x) (B y)) (r x y))))"
                  , "(forall (x) (forall (y) (implies (and (A x) (B y)) (not (r x y)))))"
                  , "(exists (x) (A x))"
                  , "(exists (y) (B y))"
                  ]
            explRes <- explainUnsatWith CVC5 reg
            case explRes of
                Left err -> expectationFailure err
                Right expl -> do
                    unsatCoreNames expl `shouldSatisfy` (\names -> length names >= 2)
                    unlines (unsatCoreDetails expl) `shouldContain` "Axiom #"

        it "solves ontologies with multi-arity relations, function terms, and equality" $ do
            let reg = load $ unlines
                  [ "(def-concept Agent)"
                  , "(def-concept Region)"
                  , "(def-concept Time)"
                  , "(def-relation occupies Agent Region Time)"
                  , "(forall (a r t) (implies (occupies a r t) (= (parentOf a) a)))"
                  ]
            untranslatedAxioms reg `shouldBe` []
            consistency <- checkConsistencyWith Z3 reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)

    describe "NativeProver Reasoning Engine" $ do
        let load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))
        it "proves an ontology is Satisfiable (SAT) natively via semantic tableaux" $ do
            let reg = load $ unlines
                  [ "(def-concept Animal)"
                  , "(def-concept Dog Animal)"
                  ]
            res <- checkConsistencyWith NativeProver reg
            case res of
                Sat _ -> return ()
                _     -> expectationFailure $ "Expected Sat but got: " ++ show res

        it "proves taxonomic subsumption theorem natively via semantic tableaux" $ do
            let reg = load $ unlines
                  [ "(def-concept Vehicle)"
                  , "(def-concept Car Vehicle)"
                  ]
            res <- proveSubsumptionWith NativeProver reg "Car" "Vehicle"
            res `shouldBe` Subsumed

        it "disproves subsumption and produces a countermodel natively" $ do
            let reg = load $ unlines
                  [ "(def-concept Car)"
                  , "(def-concept Airplane)"
                  ]
            res <- proveSubsumptionWith NativeProver reg "Car" "Airplane"
            case res of
                NotSubsumed model -> model `shouldContain` "Countermodel"
                _                 -> expectationFailure $ "Expected NotSubsumed with countermodel but got: " ++ show res

        it "identifies unsatisfiable / empty concepts natively" $ do
            let reg = load $ unlines
                  [ "(def-concept ValidNode)"
                  , "(def-concept BrokenNode)"
                  , "(forall (b) (implies (BrokenNode b) (not (BrokenNode b))))"
                  ]
            unsatList <- findUnsatConceptsWith NativeProver reg
            unsatList `shouldBe` Right ["BrokenNode"]

        it "explains UNSAT contradiction via resolution refutation core extraction" $ do
            let reg = load $ unlines
                  [ "(def-concept BrokenNode)"
                  , "(exists (b) (BrokenNode b))"
                  , "(forall (b) (implies (BrokenNode b) (not (BrokenNode b))))"
                  ]
            explRes <- explainUnsatWith NativeProver reg
            case explRes of
                Left err -> expectationFailure err
                Right expl -> do
                    unsatCoreNames expl `shouldSatisfy` (\names -> length names >= 2)
                    unlines (unsatCoreDetails expl) `shouldContain` "BrokenNode"

    describe "Solver Options & Resource Limits" $ do
        it "provides defaultSolverOptions with no timeout or memory limits" $ do
            optTimeoutSeconds defaultSolverOptions `shouldBe` Nothing
            optMemoryLimitMb defaultSolverOptions `shouldBe` Nothing

        it "passes timeout and memory limits to Z3 without error" $ do
            let reg = loadOntology $ unlines
                  [ "(def-concept Vehicle)"
                  , "(def-concept Car Vehicle)"
                  ]
                opts = defaultSolverOptions { optTimeoutSeconds = Just 10, optMemoryLimitMb = Just 1024 }
            consistency <- checkConsistencyWithOptions opts Z3 reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)
            subRes <- proveSubsumptionWithOptions opts Z3 reg "Car" "Vehicle"
            subRes `shouldBe` Subsumed
            unsatList <- findUnsatConceptsWithOptions opts Z3 reg
            unsatList `shouldBe` Right []

        it "passes timeout limits to CVC5 without error" $ do
            let reg = loadOntology $ unlines
                  [ "(def-concept Vehicle)"
                  , "(def-concept Car Vehicle)"
                  ]
                opts = defaultSolverOptions { optTimeoutSeconds = Just 10 }
            consistency <- checkConsistencyWithOptions opts CVC5 reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)
            subRes <- proveSubsumptionWithOptions opts CVC5 reg "Car" "Vehicle"
            subRes `shouldBe` Subsumed
            unsatList <- findUnsatConceptsWithOptions opts CVC5 reg
            unsatList `shouldBe` Right []

        it "passes timeout limits to NativeProver without error" $ do
            let reg = loadOntology $ unlines
                  [ "(def-concept Vehicle)"
                  , "(def-concept Car Vehicle)"
                  ]
                opts = defaultSolverOptions { optTimeoutSeconds = Just 5 }
            consistency <- checkConsistencyWithOptions opts NativeProver reg
            consistency `shouldSatisfy` (\r -> case r of Sat _ -> True; _ -> False)
            subRes <- proveSubsumptionWithOptions opts NativeProver reg "Car" "Vehicle"
            subRes `shouldBe` Subsumed
            unsatList <- findUnsatConceptsWithOptions opts NativeProver reg
            unsatList `shouldBe` Right []

    describe "Model Extraction & Output Classification" $ do
        it "extracts model valuations from Vampire SZS definitions blocks" $ do
            let vOut = unlines
                  [ "% SZS output start Definitions and Model Updates."
                  , "  c_speed := 60"
                  , "  is_Vehicle(X) := true"
                  , "% SZS output end Definitions and Model Updates."
                  ]
            extractModel (Sat vOut) `shouldBe` Just "  c_speed := 60\n  is_Vehicle(X) := true\n"

        it "extracts model body from standard SMT 'sat' output" $ do
            let sOut = unlines
                  [ "sat"
                  , "(model"
                  , "  (define-fun speed () Int 55)"
                  , ")"
                  ]
            extractModel (Sat sOut) `shouldBe` Just "(model\n(define-fun speed () Int 55)\n)\n"

        it "returns raw text when sat header is absent" $ do
            extractModel (Sat "raw model data") `shouldBe` Just "raw model data"

        it "returns Nothing for non-Sat solver results" $ do
            extractModel Unsat `shouldBe` Nothing
            extractModel (Unknown "timeout") `shouldBe` Nothing
            extractModel (SolverError "syntax error") `shouldBe` Nothing

        it "classifies solver output correctly under diverse exit codes" $ do
            classifyOutput "Z3" (ExitFailure 1) "sat\n(model)" "" `shouldBe` Right "sat\n(model)"
            classifyOutput "Z3" (ExitFailure 1) "unsat\n" "" `shouldBe` Right "unsat\n"
            classifyOutput "Vampire" (ExitFailure 0) "% SZS status Theorem" "" `shouldBe` Right "% SZS status Theorem"
            classifyOutput "Z3" ExitSuccess "(model (x 1))" "" `shouldBe` Right "(model (x 1))"
            classifyOutput "Z3" ExitSuccess "(error \"line 1: unexpected token\")" "" `shouldSatisfy` isLeft
            classifyOutput "Z3" (ExitFailure 127) "" "command not found" `shouldSatisfy` isLeft

        it "classifies a cvc5 --tlimit abort as an unknown verdict, not a solver failure" $ do
            let r = classifyOutput "CVC5" (ExitFailure 134) "" "cvc5 interrupted by timeout.\n"
            fmap (take 7) r `shouldBe` Right "unknown"

        it "kills a child process that outlives --solve-timeout and reports unknown" $ do
            exe <- findExecutable "sleep"
            case exe of
                Nothing -> pendingWith "sleep not found in PATH"
                Just _ -> do
                    let opts = defaultSolverOptions { optTimeoutSeconds = Just 1 }
                    r <- timeout ((1 + wallClockGraceSeconds + 5) * 1000000) (runBinary opts "sleep" "sleep" ["60"] "")
                    case r of
                        Nothing -> expectationFailure "wall-clock limit did not fire"
                        Just res -> fmap (take 7) res `shouldBe` Right "unknown"

        it "enforces --solve-timeout on CVC5 and Z3 for an input they cannot decide quickly" $ do
            let hard = unlines
                    [ "(set-logic ALL)"
                    , "(declare-const x Int) (declare-const y Int) (declare-const z Int)"
                    , "(assert (> x 0)) (assert (> y 0)) (assert (> z 0))"
                    , "(assert (= (+ (* x x x) (* y y y)) (* z z z)))"
                    , "(check-sat)" ]
                opts = defaultSolverOptions { optTimeoutSeconds = Just 1 }
                limit = (1 + wallClockGraceSeconds + 5) * 1000000
                check name p = do
                    exe <- findExecutable name
                    case exe of
                        Nothing -> return ()
                        Just _ -> do
                            r <- timeout limit (runProverRawWithOptions opts p hard)
                            case r of
                                Nothing -> expectationFailure (name ++ " ran past --solve-timeout")
                                -- z3 -T prints "timeout"; cvc5 and the wall-clock limit give "unknown".
                                Just res -> fmap (\o -> take 1 (words o)) res `shouldSatisfy` (`elem` [Right ["unknown"], Right ["timeout"]])
            check "cvc5" CVC5
            check "z3" Z3

        it "maps SolverResult to CLI exit codes and orders worst severity" $ do
            solverExitCode (Sat "model") `shouldBe` ExitSuccess
            solverExitCode Unsat `shouldBe` ExitFailure 1
            solverExitCode (SolverError "err") `shouldBe` ExitFailure 1
            solverExitCode (Unknown "timeout") `shouldBe` ExitFailure 2

            worst [ExitSuccess, ExitFailure 2] `shouldBe` ExitFailure 2
            worst [ExitSuccess, ExitFailure 1, ExitFailure 2] `shouldBe` ExitFailure 1
            worst [ExitSuccess, ExitSuccess] `shouldBe` ExitSuccess

        it "resolves command-line prover flags with resolveProver" $ do
            resolveProver Nothing `shouldBe` Right AutoProver
            resolveProver (Just "z3") `shouldBe` Right Z3
            resolveProver (Just "cvc5") `shouldBe` Right CVC5
            resolveProver (Just "unknown-prover") `shouldSatisfy` isLeft

withPath :: String -> IO a -> IO a
withPath p act = do
    old <- lookupEnv "PATH"
    bracket_ (setEnv "PATH" p) (maybe (unsetEnv "PATH") (setEnv "PATH") old) act

emptyReg :: Registry
emptyReg = emptyRegistry

loadOntology :: String -> Registry
loadOntology src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))
