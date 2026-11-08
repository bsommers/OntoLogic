{-# LANGUAGE OverloadedStrings #-}
module TelemetryMonitoringSpec (spec) where

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
  describe "Tier 3.9: OCSF v1.1.0 Telemetry Schema Ontology (ocsf_schema.logic)" $ do
    let ocsfPath = "ontologic-lib/ocsf_schema.logic"

    it "transitively loads UCO -> CCO -> BFO stack and defines all core event classes" $ do
      loadRes <- loadRegistryWithImports ocsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:SecurityEvent"
            , "uco-obs:IPAddress"
            , "ocsf:OCSEventCategory"
            , "ocsf:SystemActivityCategory"
            , "ocsf:FindingsCategory"
            , "ocsf:NetworkActivityCategory"
            , "ocsf:OCSEvent"
            , "ocsf:FileActivity"
            , "ocsf:ProcessActivity"
            , "ocsf:SecurityFinding"
            , "ocsf:AuthenticationEvent"
            , "ocsf:NetworkActivityEvent"
            , "ocsf:DNSActivity"
            , "ocsf:HTTPActivity"
            ]

    it "passes all semantic linter checks with zero errors" $ do
      loadRes <- loadRegistryWithImports ocsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "emits valid OWL/RDF XML with ocsf namespace" $ do
      loadRes <- loadRegistryWithImports ocsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let owlXml = emitOwl reg
          owlXml `shouldContain` "xmlns:ocsf=\"https://schema.ocsf.io/1.1.0/\""
          owlXml `shouldContain` "<owl:Class rdf:about=\"https://schema.ocsf.io/1.1.0/NetworkActivityEvent\">"
          owlXml `shouldContain` "<owl:ObjectProperty rdf:about=\"https://schema.ocsf.io/1.1.0/source_endpoint\">"

    it "generates Python Pydantic models with severity and confidence bounds" $ do
      loadRes <- loadRegistryWithImports ocsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class ocsf_OCSEvent(cco_SecurityEvent):"
          pyCode `shouldContain` "ocsf_severity_id: int = Field(ge=0, le=6)"
          pyCode `shouldContain` "class ocsf_SecurityFinding(ocsf_OCSEvent):"
          pyCode `shouldContain` "ocsf_confidence_score: float = Field(ge=0.0, le=100.0)"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "generates Java Jakarta validation annotations for severity, bytes, and confidence" $ do
      loadRes <- loadRegistryWithImports ocsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let javaFiles = emitJavaWithPackage "com.acme.ocsf" reg
          case lookup "ocsf_OCSEvent" javaFiles of
            Nothing -> expectationFailure "Expected ocsf_OCSEvent in Java files"
            Just eventCode -> do
              eventCode `shouldContain` "@Min(0)"
              eventCode `shouldContain` "@Max(6)"

  describe "Tier 3.10: SIGMA Detection Rules & SIEM Semantics (sigma_rules.logic)" $ do
    let sigmaPath = "ontologic-lib/sigma_rules.logic"

    it "transitively loads OCSF -> ATT&CK -> STIX -> UCO -> CCO -> BFO stack" $ do
      loadRes <- loadRegistryWithImports sigmaPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:DirectiveICE"
            , "attack:AttackTechnique"
            , "ocsf:OCSEvent"
            , "sigma:SigmaRule"
            , "sigma:SigmaDetectionCondition"
            , "sigma:DetectionLevel"
            , "sigma:LowLevel"
            , "sigma:MediumLevel"
            , "sigma:HighLevel"
            , "sigma:CriticalLevel"
            ]

    it "passes all semantic linter checks with zero contradictions" $ do
      loadRes <- loadRegistryWithImports sigmaPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Python Pydantic models with false positive risk bounds" $ do
      loadRes <- loadRegistryWithImports sigmaPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class sigma_SigmaRule(cco_DirectiveICE):"
          pyCode `shouldContain` "sigma_false_positive_risk: float = Field(ge=0.0, le=1.0)"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "generates Neo4j Cypher schema for Real-Time SIEM Detection Graph" $ do
      loadRes <- loadRegistryWithImports sigmaPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let cypher = emitCypher reg
          cypher `shouldContain` "MERGE (n:OntologyClass {name: 'sigma:SigmaRule'})"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'sigma:detects_technique'}]->(t)"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'sigma:matches_ocsf_event'}]->(t)"

    it "generates Mermaid and D2 telemetry event flow diagrams" $ do
      loadRes <- loadRegistryWithImports sigmaPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let mmd = emitMermaid reg
              d2 = emitD2 reg
          mmd `shouldContain` "sigma:SigmaRule"
          mmd `shouldContain` "ocsf:OCSEvent"
          d2 `shouldContain` "\"sigma:SigmaRule\": { shape: class }"

  describe "End-to-End Enterprise SOC Real-Time Detection Scenario" $ do
    let tmpDir = "/tmp/ontologic_telemetry_scenario_test"

    it "compiles a real-time SIEM alert pipeline connecting OCSF events, SIGMA detection rules, and ATT&CK techniques" $ do
      createDirectoryIfMissing True tmpDir
      let scenarioFile = tmpDir </> "siem_auth_alert.logic"
          content = unlines
            [ "(import \"ontologic-lib/sigma_rules.logic\")"
            , "(namespace soc \"http://enterprise.soc/telemetry#\")"
            , ""
            , ";; Live Telemetry & Detection Instances"
            , "(def-concept soc:BruteForceAlert sigma:SigmaRule)"
            , "(def-concept soc:SSHFailedAuth ocsf:AuthenticationEvent)"
            , "(def-concept soc:T1110BruteForce attack:AttackTechnique)"
            , "(def-concept soc:BruteForceFinding ocsf:SecurityFinding)"
            , ""
            , ";; Security Properties"
            , "(def-property soc:failed_attempts soc:SSHFailedAuth Integer)"
            , ""
            , ";; Telemetry Pipeline Relations"
            , "(def-relation soc:triggers_rule soc:SSHFailedAuth soc:BruteForceAlert)"
            , "(def-relation soc:identifies_technique soc:BruteForceAlert soc:T1110BruteForce)"
            , "(def-relation soc:generates_finding soc:BruteForceAlert soc:BruteForceFinding)"
            , ""
            , ";; Threshold Constraint"
            , "(forall (a)"
            , "  (implies (soc:SSHFailedAuth a)"
            , "           (gte soc:failed_attempts 5)))"
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
          pyCode `shouldContain` "class soc_BruteForceAlert(sigma_SigmaRule):"
          pyCode `shouldContain` "class soc_SSHFailedAuth(ocsf_AuthenticationEvent):"
          pyCode `shouldContain` "soc_failed_attempts: int = Field(ge=5)"
