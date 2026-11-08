{-# LANGUAGE OverloadedStrings #-}
module AutonomousAISpec (spec) where

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
  describe "Tier 3: Autonomous AI & Multi-Agent Swarm Ontology (autonomous_ai.logic)" $ do
    let aiPath = "ontologic-lib/autonomous_ai.logic"

    it "transitively loads BFO -> CCO -> AI-MAS stack without errors" $ do
      loadRes <- loadRegistryWithImports aiPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "bfo:MaterialEntity"
            , "cco:Agent"
            , "cco:AgentSwarm"
            , "cco:AutonomousSoftwareAgent"
            , "ai:AutonomousAgent"
            , "ai:Subagent"
            , "ai:AgentSwarm"
            , "ai:FoundationModel"
            , "ai:SystemPrompt"
            , "ai:Tool"
            , "ai:MCPTool"
            , "ai:MCPServer"
            , "ai:AgentTaskExecution"
            , "ai:LLMInference"
            , "ai:EvaluationTask"
            , "ai:BenchmarkScore"
            , "ai:QualityGate"
            ]

    it "passes all semantic linter checks across entire standard library stack" $ do
      loadRes <- loadRegistryWithImports aiPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "grounds autonomous agent and swarm hierarchy in BFO/CCO realism" $ do
      loadRes <- loadRegistryWithImports aiPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          lookup "ai:AutonomousAgent" (concepts reg) `shouldBe` Just (Just "cco:AutonomousSoftwareAgent")
          lookup "ai:Subagent" (concepts reg) `shouldBe` Just (Just "ai:AutonomousAgent")
          lookup "ai:AgentSwarm" (concepts reg) `shouldBe` Just (Just "cco:AgentSwarm")
          lookup "ai:FoundationModel" (concepts reg) `shouldBe` Just (Just "cco:SoftwareArtifact")
          lookup "ai:EvaluationTask" (concepts reg) `shouldBe` Just (Just "cco:ActOfVerification")

    it "compiles cleanly to Intermediate Representation (IR)" $ do
      loadRes <- loadRegistryWithImports aiPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let modelIR = compileRegistry reg
          length (irClasses modelIR) `shouldSatisfy` (> 20)

    it "proves SMT satisfiability and concept coherence via Z3" $ do
      loadRes <- loadRegistryWithImports aiPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg ->
          case resolveProver (Just "z3") of
            Left err -> expectationFailure err
            Right prover -> do
              res <- checkConsistencyWith prover reg
              case res of
                Sat _ -> return ()
                Unsat -> expectationFailure "Expected SAT, got UNSAT contradiction"
                Unknown msg -> expectationFailure ("SMT unknown: " ++ msg)
                SolverError msg -> expectationFailure ("Solver error: " ++ msg)

              coh <- findUnsatConceptsWith prover reg
              case coh of
                Left err -> expectationFailure err
                Right empties -> empties `shouldBe` []

    it "generates valid models across multi-target emitters" $ do
      loadRes <- loadRegistryWithImports aiPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let py = emitPython reg
          py `shouldContain` "class ai_AutonomousAgent"
          py `shouldContain` "class ai_FoundationModel"

          let ts = emitTypeScript reg
          ts `shouldContain` "export const ai_AutonomousAgentSchema"
          ts `shouldContain` "export const ai_FoundationModelSchema"

          let rs = emitRust reg
          rs `shouldContain` "pub struct ai_AutonomousAgent"
          rs `shouldContain` "pub struct ai_FoundationModel"

          let go = emitGo reg
          go `shouldContain` "type ai_AutonomousAgent struct"
          go `shouldContain` "type ai_FoundationModel struct"

          let javaFiles = emitJavaWithPackage "com.autonomous.ai" reg
          length javaFiles `shouldSatisfy` (> 10)

          let shacl = emitShacl reg
          shacl `shouldContain` "ai:AutonomousAgent"

          let owl = emitOwl reg
          owl `shouldContain` "AutonomousAgent"

          let cypher = emitCypher reg
          cypher `shouldContain` "AutonomousAgent"

          let mmd = emitMermaid reg
          mmd `shouldContain` "ai_AutonomousAgent"

          let d2 = emitD2 reg
          d2 `shouldContain` "\"ai:AutonomousAgent\""
