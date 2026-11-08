{-# LANGUAGE OverloadedStrings #-}
module EcosystemUnifiedSpec (spec) where

import Test.Hspec
import OntoLogic
import Loader (loadRegistryWithImports)
import Linter (lintRegistry)
import IR (compileRegistry, irClasses)
import Solver (checkConsistencyWith, findUnsatConceptsWith, resolveProver)
import Emitters.Python (emitPython)
import Emitters.TypeScript (emitTypeScript)
import Emitters.Rust (emitRust)
import Emitters.Go (emitGo)
import Emitters.Java (emitJavaWithPackage)
import Emitters.Shacl (emitShacl)
import Emitters.Owl (emitOwl)
import Emitters.Neo4j (emitCypher)
import Emitters.Mermaid (emitMermaid)
import Emitters.D2 (emitD2)

spec :: Spec
spec = do
  describe "Tier 4: Unified Ecosystem Mega-Ontology (ecosystem_unified.logic)" $ do
    let ecoPath = "ontologic-lib/ecosystem_unified.logic"

    it "transitively loads full 11-ontology unified stack without errors" $ do
      loadRes <- loadRegistryWithImports ecoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:EngineeredSystem"
            , "ai:AutonomousAgent"
            , "ai:AgentSwarm"
            , "se:Repository"
            , "se:SourceFile"
            , "se:CIPipelineExecution"
            , "stix:Vulnerability"
            , "attack:AttackTechnique"
            , "d3f:DefensiveTechnique"
            , "ocsf:OCSEvent"
            , "sigma:SigmaRule"
            , "dsf:SoftwareFactory"
            , "eco:AutonomousFactorySystem"
            , "eco:SecureAutonomousSDLC"
            , "eco:AgenticDevOpsSwarm"
            ]

    it "passes all semantic linter checks across the entire unified stack" $ do
      loadRes <- loadRegistryWithImports ecoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "compiles cleanly to intermediate representation with 100+ classes" $ do
      loadRes <- loadRegistryWithImports ecoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let modelIR = compileRegistry reg
          length (irClasses modelIR) `shouldSatisfy` (> 80)

    it "proves unified SMT satisfiability and concept coherence via Z3" $ do
      loadRes <- loadRegistryWithImports ecoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg ->
          case resolveProver (Just "z3") of
            Left err -> expectationFailure err
            Right prover -> do
              res <- checkConsistencyWith prover reg
              case res of
                Sat _ -> return ()
                Unsat -> expectationFailure "Expected SAT, got UNSAT contradiction in unified stack"
                Unknown msg -> expectationFailure ("SMT unknown: " ++ msg)
                SolverError msg -> expectationFailure ("Solver error: " ++ msg)

              coh <- findUnsatConceptsWith prover reg
              case coh of
                Left err -> expectationFailure err
                Right empties -> empties `shouldBe` []

    it "generates valid models across multi-target emitters for unified architecture" $ do
      loadRes <- loadRegistryWithImports ecoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let py = emitPython reg
          py `shouldContain` "class eco_AutonomousFactorySystem"
          py `shouldContain` "class eco_SecureAutonomousSDLC"

          let ts = emitTypeScript reg
          ts `shouldContain` "export const eco_AutonomousFactorySystemSchema"

          let rs = emitRust reg
          rs `shouldContain` "pub struct eco_AutonomousFactorySystem"

          let go = emitGo reg
          go `shouldContain` "type eco_AutonomousFactorySystem struct"

          let javaFiles = emitJavaWithPackage "com.ecosystem.unified" reg
          length javaFiles `shouldSatisfy` (> 20)

          let shacl = emitShacl reg
          shacl `shouldContain` "eco:AutonomousFactorySystem"

          let owl = emitOwl reg
          owl `shouldContain` "AutonomousFactorySystem"

          let cypher = emitCypher reg
          cypher `shouldContain` "AutonomousFactorySystem"

          let mmd = emitMermaid reg
          mmd `shouldContain` "eco_AutonomousFactorySystem"

          let d2 = emitD2 reg
          d2 `shouldContain` "\"eco:AutonomousFactorySystem\""
