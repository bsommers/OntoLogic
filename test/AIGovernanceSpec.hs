{-# LANGUAGE OverloadedStrings #-}
module AIGovernanceSpec (spec) where

import Test.Hspec
import System.FilePath ((</>))
import System.Directory (createDirectoryIfMissing, removeDirectoryRecursive)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

import OntoLogic
import Loader (loadRegistryWithImports)
import Linter (lintRegistry)
import IR (compileRegistry, irClasses, irRelations)
import Emitters.Owl (emitOwl)
import Emitters.Python (emitPython)
import Emitters.Java (emitJavaWithPackage)
import Emitters.Neo4j (emitCypher)
import Emitters.Mermaid (emitMermaid)
import Emitters.D2 (emitD2)

-- OWL IRIs are absolute as of #49: a prefixed name resolves into its declared
-- namespace, so the old "#prefix:Local" expectation encoded the double-prefix bug.
spec :: Spec
spec = do
  describe "Tier 3.4: MITRE ATLAS Adversarial AI & Threat Matrix (mitre_atlas.logic)" $ do
    let atlasPath = "ontologic-lib/mitre_atlas.logic"

    it "transitively loads ATT&CK -> STIX -> UCO -> CCO -> BFO stack" $ do
      loadRes <- loadRegistryWithImports atlasPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:SoftwareArtifact"
            , "attack:AttackTechnique"
            , "atlas:AIModel"
            , "atlas:AIInferenceProcess"
            , "atlas:ATLASTechnique"
            , "atlas:LLMPromptInjection"
            , "atlas:DirectPromptInjection"
            , "atlas:IndirectPromptInjection"
            , "atlas:AdversarialEvasion"
            , "atlas:TrainingDataPoisoning"
            , "atlas:ModelInversion"
            , "atlas:ModelExtraction"
            , "atlas:RAGRetrievalInjection"
            , "atlas:AIGuardrailMitigation"
            , "atlas:InputFilterGuardrail"
            ]

    it "passes all semantic linter checks with zero errors" $ do
      loadRes <- loadRegistryWithImports atlasPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Python Pydantic models for AI Models and Guardrails" $ do
      loadRes <- loadRegistryWithImports atlasPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class atlas_AIModel(cco_SoftwareArtifact):"
          pyCode `shouldContain` "class atlas_LLMPromptInjection(atlas_ATLASTechnique):"
          pyCode `shouldContain` "class atlas_InputFilterGuardrail(atlas_AIGuardrailMitigation):"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "generates Neo4j Cypher schema for Adversarial ML Threat Graph" $ do
      loadRes <- loadRegistryWithImports atlasPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let cypher = emitCypher reg
          cypher `shouldContain` "MERGE (n:OntologyClass {name: 'atlas:ATLASTechnique'})"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'atlas:targets_model'}]->(t)"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'atlas:mitigated_by_guardrail'}]->(t)"

  describe "Tier 3.5: NIST AI RMF 1.0 Risk Management (nist_ai_rmf.logic)" $ do
    let nistAIPath = "ontologic-lib/nist_ai_rmf.logic"

    it "transitively loads ATLAS -> ATT&CK -> STIX -> UCO -> CCO -> BFO stack" $ do
      loadRes <- loadRegistryWithImports nistAIPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "nist-ai:AIRMFFunction"
            , "nist-ai:Govern"
            , "nist-ai:Map"
            , "nist-ai:Measure"
            , "nist-ai:Manage"
            , "nist-ai:TrustworthyCharacteristic"
            , "nist-ai:Safe"
            , "nist-ai:SecureAndResilient"
            , "nist-ai:AccountableAndTransparent"
            , "nist-ai:FairHarmfulBiasManaged"
            , "nist-ai:AISystem"
            , "nist-ai:LLMFoundationModel"
            , "nist-ai:AIModelEvaluationMetric"
            ]

    it "passes all semantic linter checks with zero contradictions" $ do
      loadRes <- loadRegistryWithImports nistAIPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Python Pydantic models with AI evaluation metric bounds" $ do
      loadRes <- loadRegistryWithImports nistAIPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class nist_ai_AIModelEvaluationMetric(cco_MeasurementICE):"
          pyCode `shouldContain` "nist_ai_hallucination_rate: float = Field(ge=0.0, le=1.0)"
          pyCode `shouldContain` "nist_ai_toxicity_score: float = Field(ge=0.0, le=1.0)"
          pyCode `shouldContain` "nist_ai_jailbreak_resistance_score: float = Field(ge=0.0, le=1.0)"
          pyCode `shouldContain` "nist_ai_demographic_parity_gap: float = Field(ge=0.0, le=1.0)"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "emits valid OWL/RDF XML with nist-ai namespace" $ do
      loadRes <- loadRegistryWithImports nistAIPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let owlXml = emitOwl reg
          owlXml `shouldContain` "xmlns:nist-ai=\"https://airc.nist.gov/AI_RMF/\""
          owlXml `shouldContain` "<owl:Class rdf:about=\"https://airc.nist.gov/AI_RMF/AISystem\">"

    it "generates Java Jakarta DecimalMin and DecimalMax annotations for AI metrics" $ do
      loadRes <- loadRegistryWithImports nistAIPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let javaFiles = emitJavaWithPackage "com.acme.ai" reg
          case lookup "nist_ai_AIModelEvaluationMetric" javaFiles of
            Nothing -> expectationFailure "Expected nist_ai_AIModelEvaluationMetric in Java files"
            Just metricCode -> do
              metricCode `shouldContain` "@DecimalMin(\"0.0\")"
              metricCode `shouldContain` "@DecimalMax(\"1.0\")"

  describe "Tier 3.6: ISO/IEC 42001 & EU AI Act Governance (iso_42001_eu_ai_act.logic)" $ do
    let isoPath = "ontologic-lib/iso_42001_eu_ai_act.logic"

    it "transitively loads full 5-tier stack with EU AI Act risk tiers and ISO 42001 lifecycle" $ do
      loadRes <- loadRegistryWithImports isoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:Agent"
            , "nist-ai:AISystem"
            , "aiact:AIRiskTier"
            , "aiact:ProhibitedRisk"
            , "aiact:HighRisk"
            , "aiact:TransparencyRisk"
            , "aiact:MinimalRisk"
            , "iso42001:AILifecycleStage"
            , "iso42001:DataCurationStage"
            , "iso42001:ModelTrainingStage"
            , "iso42001:SafetyEvaluationStage"
            , "iso42001:DeploymentOversightStage"
            , "iso42001:PostMarketMonitoringStage"
            , "iso42001:HumanOversightRole"
            , "iso42001:AIAuditRecord"
            ]

    it "passes all semantic linter checks with zero errors" $ do
      loadRes <- loadRegistryWithImports isoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Mermaid and D2 AI governance architecture diagrams" $ do
      loadRes <- loadRegistryWithImports isoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let mmd = emitMermaid reg
              d2 = emitD2 reg
          mmd `shouldContain` "aiact:HighRisk"
          mmd `shouldContain` "iso42001:AILifecycleStage"
          d2 `shouldContain` "\"aiact:HighRisk\": { shape: class }"

  describe "End-to-End Enterprise AI Agent & RAG Governance Scenario" $ do
    let tmpDir = "/tmp/ontologic_ai_scenario_test"

    it "compiles an enterprise GenAI application with model, prompt injection threats, guardrails, and EU AI Act classification" $ do
      createDirectoryIfMissing True tmpDir
      let scenarioFile = tmpDir </> "customer_support_rag.logic"
          content = unlines
            [ "(import \"ontologic-lib/iso_42001_eu_ai_act.logic\")"
            , "(namespace app \"http://enterprise.app/ai#\")"
            , ""
            , ";; AI System Components"
            , "(def-concept app:CustomerSupportAgent nist-ai:AISystem)"
            , "(def-concept app:Llama3Model atlas:AIModel)"
            , "(def-concept app:RAGRetrievalPipe uco-obs:DigitalProcess)"
            , ""
            , ";; Adversarial Threat & Guardrail Mitigations"
            , "(def-concept app:IndirectInjectionThreat atlas:IndirectPromptInjection)"
            , "(def-concept app:DualLayerFilter atlas:InputFilterGuardrail)"
            , ""
            , ";; Governance & Compliance"
            , "(def-concept app:ComplianceOfficerRole iso42001:HumanOversightRole)"
            , "(def-concept app:AgentEvaluationMetric nist-ai:AIModelEvaluationMetric)"
            , ""
            , ";; Properties"
            , "(def-property app:safety_score app:AgentEvaluationMetric Double)"
            , ""
            , ";; Relations"
            , "(def-relation app:deploys_llm app:CustomerSupportAgent app:Llama3Model)"
            , "(def-relation app:filtered_by app:CustomerSupportAgent app:DualLayerFilter)"
            , "(def-relation app:monitored_by app:CustomerSupportAgent app:ComplianceOfficerRole)"
            , "(def-relation app:evaluated_with app:CustomerSupportAgent app:AgentEvaluationMetric)"
            , ""
            , ";; Metric Constraints"
            , "(forall (e)"
            , "  (implies (app:AgentEvaluationMetric e)"
            , "           (and (gte app:safety_score 0.90)"
            , "                (lte app:safety_score 1.0))))"
            ]
      writeFile scenarioFile content

      loadRes <- loadRegistryWithImports scenarioFile
      removeDirectoryRecursive tmpDir

      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          lintRegistry reg `shouldBe` []
          let modelIR = compileRegistry reg
          length (irClasses modelIR) `shouldSatisfy` (> 0)
          length (irRelations modelIR) `shouldSatisfy` (> 0)
          let pyCode = emitPython reg
          pyCode `shouldContain` "class app_CustomerSupportAgent(nist_ai_AISystem):"
          pyCode `shouldContain` "class app_IndirectInjectionThreat(atlas_IndirectPromptInjection):"
          pyCode `shouldContain` "app_safety_score: float = Field(ge=0.9, le=1.0)"
