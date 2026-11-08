{-# LANGUAGE OverloadedStrings #-}
module ThreatModelingSpec (spec) where

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
  describe "Tier 3.1: STIX 2.1 & CVE Vulnerability Ontology (stix_cve.logic)" $ do
    let stixPath = "ontologic-lib/stix_cve.logic"

    it "transitively loads BFO -> CCO -> UCO -> STIX stack without errors" $ do
      loadRes <- loadRegistryWithImports stixPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:Artifact"
            , "uco-obs:CyberObservable"
            , "stix:SDO"
            , "stix:AttackPattern"
            , "stix:Campaign"
            , "stix:CourseOfAction"
            , "stix:Indicator"
            , "stix:Malware"
            , "stix:ThreatActor"
            , "stix:Vulnerability"
            , "stix:Weakness"
            ]

    it "passes all semantic linter checks with zero contradictions" $ do
      loadRes <- loadRegistryWithImports stixPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Python Pydantic models with CVSS and EPSS score validations" $ do
      loadRes <- loadRegistryWithImports stixPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class stix_Vulnerability(stix_SDO):"
          pyCode `shouldContain` "stix_cvss_score: float = Field(ge=0.0, le=10.0)"
          pyCode `shouldContain` "stix_epss_score: float = Field(ge=0.0, le=1.0)"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "generates Java Jakarta DecimalMin and DecimalMax annotations for CVSS" $ do
      loadRes <- loadRegistryWithImports stixPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let javaFiles = emitJavaWithPackage "com.acme.stix" reg
          case lookup "stix_Vulnerability" javaFiles of
            Nothing -> expectationFailure "Expected stix_Vulnerability in Java files"
            Just vulnCode -> do
              vulnCode `shouldContain` "@DecimalMin(\"0.0\")"
              vulnCode `shouldContain` "@DecimalMax(\"10.0\")"

  describe "Tier 3.2: MITRE ATT&CK Enterprise Matrix Ontology (mitre_attack.logic)" $ do
    let attackPath = "ontologic-lib/mitre_attack.logic"

    it "transitively loads STIX -> UCO -> CCO -> BFO with all 12 tactics" $ do
      loadRes <- loadRegistryWithImports attackPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "attack:AttackTactic"
            , "attack:InitialAccess"
            , "attack:Execution"
            , "attack:Persistence"
            , "attack:PrivilegeEscalation"
            , "attack:DefenseEvasion"
            , "attack:CredentialAccess"
            , "attack:Discovery"
            , "attack:LateralMovement"
            , "attack:Collection"
            , "attack:CommandAndControl"
            , "attack:Exfiltration"
            , "attack:Impact"
            , "attack:AttackTechnique"
            , "attack:AttackSubTechnique"
            , "attack:AttackMitigation"
            , "attack:ThreatGroup"
            ]

    it "passes all semantic linter checks with zero errors" $ do
      loadRes <- loadRegistryWithImports attackPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "emits valid OWL/RDF XML with attack namespace" $ do
      loadRes <- loadRegistryWithImports attackPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let owlXml = emitOwl reg
          owlXml `shouldContain` "xmlns:attack=\"https://attack.mitre.org/\""
          owlXml `shouldContain` "<owl:Class rdf:about=\"https://attack.mitre.org/AttackTechnique\">"
          owlXml `shouldContain` "<owl:ObjectProperty rdf:about=\"https://attack.mitre.org/mitigated_by\">"

    it "generates Neo4j Cypher schema for Attack Graph traversal" $ do
      loadRes <- loadRegistryWithImports attackPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let cypher = emitCypher reg
          cypher `shouldContain` "MERGE (n:OntologyClass {name: 'attack:AttackTechnique'})"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'attack:mitigated_by'}]->(t)"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'attack:has_tactic'}]->(t)"

  describe "Tier 3.3: MITRE D3FEND Countermeasures Ontology (mitre_d3fend.logic)" $ do
    let d3fendPath = "ontologic-lib/mitre_d3fend.logic"

    it "transitively loads full 4-tier stack (BFO -> CCO -> UCO -> STIX -> ATT&CK -> D3FEND)" $ do
      loadRes <- loadRegistryWithImports d3fendPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:Agent"
            , "uco-obs:CyberObservable"
            , "stix:SDO"
            , "attack:AttackTechnique"
            , "d3f:DefensiveTactic"
            , "d3f:DefensiveTechnique"
            , "d3f:ProcessIsolation"
            , "d3f:MemoryHardening"
            , "d3f:NetworkSegmentation"
            , "d3f:CredentialEviction"
            , "d3f:SystemCallFiltering"
            ]

    it "passes all semantic linter checks with zero errors" $ do
      loadRes <- loadRegistryWithImports d3fendPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Mermaid and D2 defensive architecture graphs" $ do
      loadRes <- loadRegistryWithImports d3fendPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let mmd = emitMermaid reg
              d2 = emitD2 reg
          mmd `shouldContain` "d3f:DefensiveTechnique"
          mmd `shouldContain` "d3f:ProcessIsolation"
          d2 `shouldContain` "\"d3f:DefensiveTechnique\": { shape: class }"

  describe "End-to-End Cyber Threat Modeling Scenario" $ do
    let tmpDir = "/tmp/ontologic_threat_scenario_test"

    it "compiles an end-to-end cyber threat model with APT actor, CVE vulnerability, ATT&CK technique, and D3FEND defense" $ do
      createDirectoryIfMissing True tmpDir
      let scenarioFile = tmpDir </> "apt29_campaign.logic"
          content = unlines
            [ "(import \"ontologic-lib/mitre_d3fend.logic\")"
            , "(namespace corp \"http://enterprise.corp/security#\")"
            , ""
            , ";; Enterprise Infrastructure"
            , "(def-concept corp:DMZWebServer cco:HardwareComponent)"
            , "(def-concept corp:AppServerProcess uco-obs:DigitalProcess)"
            , ""
            , ";; Threat Model Instances"
            , "(def-concept corp:APT29Campaign attack:ThreatGroup)"
            , "(def-concept corp:PowerShellTechnique attack:AttackTechnique)"
            , "(def-concept corp:Log4jVuln stix:Vulnerability)"
            , "(def-concept corp:HardenedIsolation d3f:ProcessIsolation)"
            , ""
            , ";; Security Properties"
            , "(def-property corp:asset_criticality corp:DMZWebServer Integer)"
            , ""
            , ";; Security Relations"
            , "(def-relation corp:exploits corp:APT29Campaign corp:Log4jVuln)"
            , "(def-relation corp:targets_asset corp:APT29Campaign corp:DMZWebServer)"
            , "(def-relation corp:executes_technique corp:APT29Campaign corp:PowerShellTechnique)"
            , "(def-relation corp:defended_by corp:DMZWebServer corp:HardenedIsolation)"
            , ""
            , ";; Criticality Constraint"
            , "(forall (s)"
            , "  (implies (corp:DMZWebServer s)"
            , "           (and (gte corp:asset_criticality 1)"
            , "                (lte corp:asset_criticality 5))))"
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
          pyCode `shouldContain` "class corp_APT29Campaign(attack_ThreatGroup):"
          pyCode `shouldContain` "class corp_HardenedIsolation(d3f_ProcessIsolation):"
          pyCode `shouldContain` "corp_asset_criticality: int = Field(ge=1, le=5)"
