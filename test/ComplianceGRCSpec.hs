{-# LANGUAGE OverloadedStrings #-}
module ComplianceGRCSpec (spec) where

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
  describe "Tier 3.7: NIST Cybersecurity Framework (CSF 2.0) Ontology (nist_csf.logic)" $ do
    let csfPath = "ontologic-lib/nist_csf.logic"

    it "transitively loads CCO -> BFO stack and defines all 6 CSF 2.0 functions" $ do
      loadRes <- loadRegistryWithImports csfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:DirectiveICE"
            , "csf:CSFFunction"
            , "csf:Govern"
            , "csf:Identify"
            , "csf:Protect"
            , "csf:Detect"
            , "csf:Respond"
            , "csf:Recover"
            , "csf:CSFCategory"
            , "csf:AssetManagement"
            , "csf:RiskAssessment"
            , "csf:DataSecurity"
            , "csf:ContinuousMonitoring"
            , "csf:IncidentManagement"
            ]

    it "passes all semantic linter checks with zero errors" $ do
      loadRes <- loadRegistryWithImports csfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "emits valid OWL/RDF XML with csf namespace" $ do
      loadRes <- loadRegistryWithImports csfPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let owlXml = emitOwl reg
          owlXml `shouldContain` "xmlns:csf=\"https://csrc.nist.gov/projects/cybersecurity-framework/\""
          owlXml `shouldContain` "<owl:Class rdf:about=\"https://csrc.nist.gov/projects/cybersecurity-framework/CSFFunction\">"
          owlXml `shouldContain` "<owl:ObjectProperty rdf:about=\"https://csrc.nist.gov/projects/cybersecurity-framework/has_category\">"

  describe "Tier 3.8: NIST SP 800-53 Rev 5 & OSCAL (nist_sp800_53.logic)" $ do
    let nistPath = "ontologic-lib/nist_sp800_53.logic"

    it "transitively loads CSF -> STIX -> UCO -> CCO -> BFO multi-tier stack" $ do
      loadRes <- loadRegistryWithImports nistPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let classNames = map fst (concepts reg)
          mapM_ (\c -> classNames `shouldSatisfy` elem c)
            [ "bfo:Entity"
            , "cco:Artifact"
            , "csf:Protect"
            , "stix:Vulnerability"
            , "nist80053:ControlFamily"
            , "nist80053:AccessControlFamily"
            , "nist80053:SystemCommunicationsProtectionFamily"
            , "nist80053:SecurityControl"
            , "nist80053:AC_2_AccountManagement"
            , "nist80053:AC_3_AccessEnforcement"
            , "nist80053:SC_7_BoundaryProtection"
            , "nist80053:SC_13_CryptographicProtection"
            , "oscal:ControlBaseline"
            , "oscal:LowBaseline"
            , "oscal:ModerateBaseline"
            , "oscal:HighBaseline"
            , "oscal:SystemSecurityPlan"
            ]

    it "passes all semantic linter checks with zero contradictions" $ do
      loadRes <- loadRegistryWithImports nistPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> lintRegistry reg `shouldBe` []

    it "generates Python Pydantic models with compliance score and audit frequency bounds" $ do
      loadRes <- loadRegistryWithImports nistPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let pyCode = emitPython reg
          pyCode `shouldContain` "class nist80053_SecurityControl(cco_DirectiveICE):"
          pyCode `shouldContain` "nist80053_compliance_score: float = Field(ge=0.0, le=100.0)"
          pyCode `shouldContain` "nist80053_audit_frequency_days: int = Field(ge=1)"
          (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast; ast.parse('''" ++ pyCode ++ "''')"] ""
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""

    it "generates Java Jakarta DecimalMin and Min annotations for compliance controls" $ do
      loadRes <- loadRegistryWithImports nistPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let javaFiles = emitJavaWithPackage "com.acme.grc" reg
          case lookup "nist80053_SecurityControl" javaFiles of
            Nothing -> expectationFailure "Expected nist80053_SecurityControl in Java files"
            Just ctrlCode -> do
              ctrlCode `shouldContain` "@DecimalMin(\"0.0\")"
              ctrlCode `shouldContain` "@DecimalMax(\"100.0\")"
              ctrlCode `shouldContain` "@Min(1)"

    it "generates Neo4j Cypher schema for Automated Compliance Knowledge Graph" $ do
      loadRes <- loadRegistryWithImports nistPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let cypher = emitCypher reg
          cypher `shouldContain` "MERGE (n:OntologyClass {name: 'nist80053:SecurityControl'})"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'nist80053:implements_control'}]->(t)"
          cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'oscal:included_in_baseline'}]->(t)"

    it "generates Mermaid and D2 compliance architecture diagrams" $ do
      loadRes <- loadRegistryWithImports nistPath
      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let mmd = emitMermaid reg
              d2 = emitD2 reg
          mmd `shouldContain` "nist80053:SecurityControl"
          mmd `shouldContain` "oscal:HighBaseline"
          d2 `shouldContain` "\"nist80053:SecurityControl\": { shape: class }"

  describe "End-to-End Enterprise Cloud Compliance & GRC Audit Scenario" $ do
    let tmpDir = "/tmp/ontologic_grc_scenario_test"

    it "compiles an enterprise banking GRC architecture with NIST 800-53 controls, CSF mapping, and OSCAL High baseline" $ do
      createDirectoryIfMissing True tmpDir
      let scenarioFile = tmpDir </> "banking_cloud_grc.logic"
          content = unlines
            [ "(import \"ontologic-lib/nist_sp800_53.logic\")"
            , "(namespace bank \"http://enterprise.bank/compliance#\")"
            , ""
            , ";; Regulated Banking Infrastructure"
            , "(def-concept bank:PaymentGatewaySystem cco:EngineeredSystem)"
            , "(def-concept bank:HSMHardwareComponent cco:HardwareComponent)"
            , ""
            , ";; Compliance Controls Implementation"
            , "(def-concept bank:BoundaryProtectionSC7 nist80053:SC_7_BoundaryProtection)"
            , "(def-concept bank:CryptoProtectionSC13 nist80053:SC_13_CryptographicProtection)"
            , "(def-concept bank:BankingSecurityPlan oscal:SystemSecurityPlan)"
            , ""
            , ";; Security Properties"
            , "(def-property bank:audit_score bank:PaymentGatewaySystem Double)"
            , ""
            , ";; Compliance Relations"
            , "(def-relation bank:protects_gateway bank:BoundaryProtectionSC7 bank:PaymentGatewaySystem)"
            , "(def-relation bank:crypto_hardened bank:CryptoProtectionSC13 bank:HSMHardwareComponent)"
            , "(def-relation bank:certified_in_baseline bank:BoundaryProtectionSC7 oscal:HighBaseline)"
            , ""
            , ";; Audit Score Constraint"
            , "(forall (g)"
            , "  (implies (bank:PaymentGatewaySystem g)"
            , "           (and (gte bank:audit_score 95.0)"
            , "                (lte bank:audit_score 100.0))))"
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
          pyCode `shouldContain` "class bank_PaymentGatewaySystem(cco_EngineeredSystem):"
          pyCode `shouldContain` "class bank_BoundaryProtectionSC7(nist80053_SC_7_BoundaryProtection):"
          pyCode `shouldContain` "bank_audit_score: float = Field(ge=95.0, le=100.0)"
