{-# LANGUAGE OverloadedStrings #-}
module StandardLibrarySpec (spec) where

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
  describe "Tier 1: BFO 2020 Standard Library (bfo_2020.logic)" $ do
    let bfoPath = "ontologic-lib/bfo_2020.logic"

    it "loads and parses bfo_2020.logic without errors" $ do
      loadRes <- loadRegistryWithImports bfoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "bfo:Continuant"
            , "bfo:IndependentContinuant"
            , "bfo:MaterialEntity"
            , "bfo:SpecificallyDependentContinuant"
            , "bfo:Quality"
            , "bfo:Role"
            , "bfo:Occurrent"
            , "bfo:Process"
            , "bfo:TemporalRegion"
            ]

    it "passes all semantic linter checks with zero errors" $ do
      loadRes <- loadRegistryWithImports bfoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "emits valid OWL/RDF XML with bfo namespace declaration" $ do
      loadRes <- loadRegistryWithImports bfoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let owlXml = emitOwl reg
          owlXml `shouldContain` "xmlns:bfo=\"http://purl.obolibrary.org/obo/BFO_\""
          owlXml `shouldContain` "<owl:Class rdf:about=\"http://purl.obolibrary.org/obo/BFO_MaterialEntity\">"
          owlXml `shouldContain` "<owl:ObjectProperty rdf:about=\"http://purl.obolibrary.org/obo/BFO_part_of\">"

    it "compiles to Intermediate Representation (IR) with complete hierarchy" $ do
      loadRes <- loadRegistryWithImports bfoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let modelIR = compileRegistry reg
          length (irClasses modelIR) `shouldSatisfy` (> 15)
          length (irRelations modelIR) `shouldSatisfy` (> 5)

  describe "Tier 2: Common Core Ontologies (cco_core.logic)" $ do
    let ccoPath = "ontologic-lib/cco_core.logic"

    it "transitively loads bfo_2020.logic and parses cco_core.logic" $ do
      loadRes <- loadRegistryWithImports ccoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          -- BFO classes
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            ["bfo:Entity", "bfo:MaterialEntity", "bfo:Process"]
          -- CCO classes
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "cco:Agent"
            , "cco:Person"
            , "cco:Organization"
            , "cco:AutonomousSoftwareAgent"
            , "cco:Artifact"
            , "cco:HardwareComponent"
            , "cco:SoftwareArtifact"
            , "cco:PlannedProcess"
            , "cco:SecurityEvent"
            ]

    it "passes all semantic linter checks across both BFO and CCO" $ do
      loadRes <- loadRegistryWithImports ccoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "emits sanitized and valid Python Pydantic models" $ do
      loadRes <- loadRegistryWithImports ccoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class cco_Agent(bfo_MaterialEntity):"
          pyCode `shouldContain` "class cco_AutonomousSoftwareAgent(cco_Agent):"
          pyCode `shouldContain` "class cco_HardwareComponent(cco_Artifact):"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "emits sanitized Java POJOs for CCO entities" $ do
      loadRes <- loadRegistryWithImports ccoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let javaFiles = emitJavaWithPackage "com.acme.cco" reg
              fileMap = javaFiles
          lookup "cco_Agent" fileMap `shouldSatisfy` (/= Nothing)
          lookup "cco_AutonomousSoftwareAgent" fileMap `shouldSatisfy` (/= Nothing)
          case lookup "cco_Agent" fileMap of
            Nothing -> expectationFailure "Expected cco_Agent in Java files"
            Just agentCode -> do
              agentCode `shouldContain` "public class cco_Agent extends bfo_MaterialEntity"
              agentCode `shouldContain` "public String getCco_agent_name()"

  describe "Tier 2.5: Unified Cybersecurity Ontology (uco_observables.logic)" $ do
    let ucoPath = "ontologic-lib/uco_observables.logic"

    it "transitively loads BFO -> CCO -> UCO full 3-tier stack" $ do
      loadRes <- loadRegistryWithImports ucoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:Agent"
            , "cco:PlannedProcess"
            , "uco:CyberItem"
            , "uco-obs:CyberObservable"
            , "uco-obs:IPAddress"
            , "uco-obs:Port"
            , "uco-obs:NetworkFlow"
            , "uco-obs:File"
            , "uco-obs:DigitalProcess"
            ]

    it "passes all semantic linter checks with zero contradictions" $ do
      loadRes <- loadRegistryWithImports ucoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Python Pydantic models with field range validations" $ do
      loadRes <- loadRegistryWithImports ucoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class uco_obs_Port(uco_obs_CyberObservable):"
          pyCode `shouldContain` "uco_obs_port_number: int = Field(ge=0, le=65535)"
          pyCode `shouldContain` "uco_obs_file_size_bytes: int = Field(ge=0)"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "generates Java Jakarta Bean Validation annotations for port and file bounds" $ do
      loadRes <- loadRegistryWithImports ucoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let javaFiles = emitJavaWithPackage "com.acme.uco" reg
          case lookup "uco_obs_Port" javaFiles of
            Nothing -> expectationFailure "Expected uco_obs_Port in Java files"
            Just portCode -> do
              portCode `shouldContain` "@Min(0)"
              portCode `shouldContain` "@Max(65535)"

    it "generates Neo4j Cypher schema and elementId audit queries" $ do
      loadRes <- loadRegistryWithImports ucoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let cypher = emitCypher reg
          cypher `shouldContain` "MERGE (n:OntologyClass {name: 'uco-obs:IPAddress'})"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'uco-obs:source_ip'}]->(t)"

    it "generates Mermaid and D2 architecture diagrams" $ do
      loadRes <- loadRegistryWithImports ucoPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let mmd = emitMermaid reg
              d2 = emitD2 reg
          mmd `shouldContain` "classDiagram"
          mmd `shouldContain` "uco-obs:IPAddress"
          d2 `shouldContain` "\"uco-obs:IPAddress\": { shape: class }"

  describe "Tier 3: Custom Domain Extension on Top of 3-Tier Standard Library" $ do
    let tmpDir = "/tmp/ontologic_tier3_test"

    it "compiles an enterprise domain ontology importing uco_observables.logic" $ do
      createDirectoryIfMissing True tmpDir
      let domainFile = tmpDir </> "enterprise_soc.logic"
          content = unlines
            [ "(import \"ontologic-lib/uco_observables.logic\")"
            , "(namespace soc \"http://enterprise.org/soc#\")"
            , ""
            , ";; Domain Entities"
            , "(def-concept soc:SOCServer cco:HardwareComponent)"
            , "(def-concept soc:SIEMAgent cco:AutonomousSoftwareAgent)"
            , "(def-concept soc:SecurityIncident cco:SecurityEvent)"
            , ""
            , ";; Domain Properties"
            , "(def-property soc:cluster_id soc:SOCServer String)"
            , "(def-property soc:threat_score soc:SecurityIncident Integer)"
            , ""
            , ";; Domain Relations"
            , "(def-relation soc:monitored_by soc:SOCServer soc:SIEMAgent)"
            , "(def-relation soc:triggered_by soc:SecurityIncident uco-obs:NetworkFlow)"
            , ""
            , ";; Domain Axioms"
            , "(forall (i)"
            , "  (implies (soc:SecurityIncident i)"
            , "           (and (gte soc:threat_score 0)"
            , "                (lte soc:threat_score 100))))"
            ]
      writeFile domainFile content

      loadRes <- loadRegistryWithImports domainFile
      removeDirectoryRecursive tmpDir

      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          lintRegistry reg `shouldBe` []
          let modelIR = compileRegistry reg
          length (irClasses modelIR) `shouldSatisfy` (> 0)
          let pyCode = emitPython reg
          pyCode `shouldContain` "class soc_SOCServer(cco_HardwareComponent):"
          pyCode `shouldContain` "class soc_SecurityIncident(cco_SecurityEvent):"
          pyCode `shouldContain` "soc_threat_score: int = Field(ge=0, le=100)"

  describe "Tier 3: Dark Software Factory Domain Ontology (factory_domain.logic)" $ do
    let dsfPath = "ontologic-lib/factory_domain.logic"

    it "transitively loads the CCO/BFO stack and parses factory_domain.logic (#30)" $ do
      loadRes <- loadRegistryWithImports dsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:EngineeredSystem"
            , "dsf:SoftwareFactory"
            , "dsf:AutonomousSwarm"
            , "dsf:ConstitutionalTenet"
            , "dsf:PosetStratum"
            ]

    it "grounds dsf:SoftwareFactory in cco:EngineeredSystem (#30)" $ do
      loadRes <- loadRegistryWithImports dsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          lookup "dsf:SoftwareFactory" (concepts reg) `shouldBe` Just (Just "cco:EngineeredSystem")
          lookup "dsf:AutonomousSwarm" (concepts reg) `shouldBe` Just (Just "cco:AgentSwarm")
          lookup "dsf:VerificationGate" (concepts reg) `shouldBe` Just (Just "cco:ActOfVerification")

    it "passes the semantic linter across the whole vendored stack (#30)" $ do
      loadRes <- loadRegistryWithImports dsfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []
