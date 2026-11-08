{-# LANGUAGE OverloadedStrings #-}
module SoftwareSystemsSpec (spec) where

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
  describe "Tier 3: Software Engineering & Systems Programming Domain Ontology (software_systems.logic)" $ do
    let sePath = "ontologic-lib/software_systems.logic"

    it "transitively loads BFO -> CCO -> SE-Systems stack without errors" $ do
      loadRes <- loadRegistryWithImports sePath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "bfo:MaterialEntity"
            , "cco:Artifact"
            , "cco:SoftwareArtifact"
            , "cco:EngineeredSystem"
            , "se:Repository"
            , "se:GitRepository"
            , "se:Workspace"
            , "se:Branch"
            , "se:Commit"
            , "se:PullRequest"
            , "se:SourceFile"
            , "se:SourceModule"
            , "se:CompilationUnit"
            , "se:ASTNode"
            , "se:HostMachine"
            , "se:ContainerInstance"
            , "se:BuildProcess"
            , "se:CIPipelineExecution"
            , "se:CoverageMetric"
            ]

    it "passes all semantic linter checks across entire standard library stack" $ do
      loadRes <- loadRegistryWithImports sePath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "grounds software engineering and systems hierarchy in BFO/CCO realism" $ do
      loadRes <- loadRegistryWithImports sePath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          lookup "se:Repository" (concepts reg) `shouldBe` Just (Just "cco:InformationBearingArtifact")
          lookup "se:GitRepository" (concepts reg) `shouldBe` Just (Just "se:Repository")
          lookup "se:SourceFile" (concepts reg) `shouldBe` Just (Just "cco:SoftwareArtifact")
          lookup "se:BuildProcess" (concepts reg) `shouldBe` Just (Just "cco:PlannedProcess")
          lookup "se:HostMachine" (concepts reg) `shouldBe` Just (Just "cco:EngineeredSystem")

    it "compiles cleanly to Intermediate Representation (IR)" $ do
      loadRes <- loadRegistryWithImports sePath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let modelIR = compileRegistry reg
          length (irClasses modelIR) `shouldSatisfy` (> 20)

    it "proves SMT satisfiability and concept coherence via Z3" $ do
      loadRes <- loadRegistryWithImports sePath
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
      loadRes <- loadRegistryWithImports sePath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let py = emitPython reg
          py `shouldContain` "class se_Repository"
          py `shouldContain` "class se_SourceFile"

          let ts = emitTypeScript reg
          ts `shouldContain` "export const se_RepositorySchema"
          ts `shouldContain` "export const se_SourceFileSchema"

          let rs = emitRust reg
          rs `shouldContain` "pub struct se_Repository"
          rs `shouldContain` "pub struct se_SourceFile"

          let go = emitGo reg
          go `shouldContain` "type se_Repository struct"
          go `shouldContain` "type se_SourceFile struct"

          let javaFiles = emitJavaWithPackage "com.software.systems" reg
          length javaFiles `shouldSatisfy` (> 10)

          let shacl = emitShacl reg
          shacl `shouldContain` "se:SourceFile"

          let owl = emitOwl reg
          owl `shouldContain` "SourceFile"

          let cypher = emitCypher reg
          cypher `shouldContain` "SourceFile"

          let mmd = emitMermaid reg
          mmd `shouldContain` "se_SourceFile"

          let d2 = emitD2 reg
          d2 `shouldContain` "\"se:SourceFile\""
