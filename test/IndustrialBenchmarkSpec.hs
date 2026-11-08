{-# LANGUAGE OverloadedStrings #-}
module IndustrialBenchmarkSpec (spec) where

import Test.Hspec
import qualified Data.Text as T
import Text.Megaparsec (parse, errorBundlePretty)

import OntoLogic
    ( Registry(..)
    , concepts
    , axioms
    )
import Loader (loadRegistryWithImports)
import Parser (parseRegistry)
import Solver
    ( Prover(..)
    , SolverResult(..)
    , SubsumptionResult(..)
    , UnsatExplanation(..)
    , checkConsistencyWith
    , proveSubsumptionWith
    , findUnsatConceptsWith
    , explainUnsatWith
    )

spec :: Spec
spec = describe "Industrial Ontology Stress & Verification Suite" $ do

    describe "BFO Manufacturing Domain Ontology (bfo_manufacturing.logic)" $ do
        let path = "examples/bfo_manufacturing.logic"

        it "proves ontology consistency (SAT) natively in milliseconds" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- checkConsistencyWith NativeProver reg
                    case res of
                        Sat _ -> return ()
                        _     -> expectationFailure $ "Expected Sat, got: " ++ show res

        it "proves multi-level taxonomic subsumption (Robot <= Entity)" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    -- Robot -> Machine -> Object -> MaterialEntity -> IndependentContinuant -> Continuant -> Entity
                    res <- proveSubsumptionWith NativeProver reg "Robot" "Entity"
                    res `shouldBe` Subsumed

        it "proves process subsumption (WeldingProcess <= Process)" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- proveSubsumptionWith NativeProver reg "WeldingProcess" "Process"
                    res `shouldBe` Subsumed

        it "disproves non-subsumption between disjoint BFO branches (Robot <= Process)" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- proveSubsumptionWith NativeProver reg "Robot" "Process"
                    case res of
                        NotSubsumed _ -> return ()
                        _             -> expectationFailure $ "Expected NotSubsumed, got: " ++ show res

        it "verifies full concept coherence across all 21 concepts" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    unsat <- findUnsatConceptsWith NativeProver reg
                    unsat `shouldBe` Right []

    describe "Acme Unified Enterprise IoT Ontology (mqtt_ecosystem_unified.logic)" $ do
        let path = "examples/mqtt_ecosystem_unified.logic"

        it "proves consistency (SAT) over large 100+ clause clausal theory" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- checkConsistencyWith NativeProver reg
                    case res of
                        Sat _ -> return ()
                        _     -> expectationFailure $ "Expected Sat, got: " ++ show res

        it "proves taxonomic inheritance (Object <= Entity)" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- proveSubsumptionWith NativeProver reg "Object" "Entity"
                    res `shouldBe` Subsumed

        it "disproves subsumption across distinct branches (Process <= Continuant)" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- proveSubsumptionWith NativeProver reg "Process" "Continuant"
                    case res of
                        NotSubsumed _ -> return ()
                        _             -> expectationFailure $ "Expected NotSubsumed, got: " ++ show res

    describe "Security & Trust Architecture Ontology (domain_security_trust.logic)" $ do
        let path = "examples/domain_security_trust.logic"

        it "proves consistency natively" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- checkConsistencyWith NativeProver reg
                    case res of
                        Sat _ -> return ()
                        _     -> expectationFailure $ "Expected Sat, got: " ++ show res

    describe "Autonomous AI & Multi-Agent Swarm Ontology (autonomous_ai.logic)" $ do
        let path = "ontologic-lib/autonomous_ai.logic"

        it "proves consistency across transitive 4-tier stack (BFO -> CCO -> AI)" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- checkConsistencyWith NativeProver reg
                    case res of
                        Sat _ -> return ()
                        _     -> expectationFailure $ "Expected Sat, got: " ++ show res

        it "proves agent hierarchy subsumption (ai:Subagent <= ai:AutonomousAgent)" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right reg -> do
                    res <- proveSubsumptionWith NativeProver reg "ai:Subagent" "ai:AutonomousAgent"
                    res `shouldBe` Subsumed

    describe "Inconsistency Detection & Unsat Core Explanation on Corrupted Ontologies" $ do
        let path = "examples/bfo_manufacturing.logic"

        it "identifies injected contradictory concept as unsatisfiable" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right baseReg -> do
                    let corruptSrc = unlines
                          [ "(def-concept BrokenMachine Machine)"
                          , "(forall (x) (implies (BrokenMachine x) (Process x)))"
                          , "(forall (x) (not (and (Continuant x) (Occurrent x))))"
                          ]
                        corruptReg = either (error . errorBundlePretty) id (parse parseRegistry "corrupt" (T.pack corruptSrc))
                        combinedReg = baseReg
                            { concepts = concepts baseReg ++ concepts corruptReg
                            , axioms   = axioms baseReg ++ axioms corruptReg
                            }

                    unsatList <- findUnsatConceptsWith NativeProver combinedReg
                    unsatList `shouldBe` Right ["BrokenMachine"]

        it "detects full ontology UNSAT and extracts refutation core when instance is asserted" $ do
            loadRes <- loadRegistryWithImports path
            case loadRes of
                Left err -> expectationFailure err
                Right baseReg -> do
                    let corruptSrc = unlines
                          [ "(def-concept BrokenMachine Machine)"
                          , "(exists (x) (BrokenMachine x))"
                          , "(forall (x) (implies (BrokenMachine x) (Process x)))"
                          , "(forall (x) (not (and (Continuant x) (Occurrent x))))"
                          ]
                        corruptReg = either (error . errorBundlePretty) id (parse parseRegistry "corrupt" (T.pack corruptSrc))
                        combinedReg = baseReg
                            { concepts = concepts baseReg ++ concepts corruptReg
                            , axioms   = axioms baseReg ++ axioms corruptReg
                            }

                    res <- checkConsistencyWith NativeProver combinedReg
                    res `shouldBe` Unsat

                    explRes <- explainUnsatWith NativeProver combinedReg
                    case explRes of
                        Left err -> expectationFailure err
                        Right expl -> do
                            unsatCoreNames expl `shouldSatisfy` (\names -> length names >= 2)
                            unlines (unsatCoreDetails expl) `shouldContain` "BrokenMachine"
