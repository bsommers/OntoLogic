module OwlSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Owl (emitOwl, emitOwlWithBase)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)
import Data.List (isInfixOf)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

-- OWL IRIs are absolute as of #49: a prefixed name resolves into its declared
-- namespace, so the old "#prefix:Local" expectation encoded the double-prefix bug.
spec :: Spec
spec = do
  describe "OWL Emitter" $ do
    it "emits well-formed XML with standard RDF/OWL namespaces" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = []
                  , properties = [Property "serial_number" "Asset" PTString]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          xml = emitOwl reg
      xml `shouldSatisfy` isInfixOf "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\""
      xml `shouldSatisfy` isInfixOf "xmlns:owl=\"http://www.w3.org/2002/07/owl#\""
      xml `shouldSatisfy` isInfixOf "xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\""
      xml `shouldSatisfy` isInfixOf "<owl:Ontology"
      xml `shouldSatisfy` isInfixOf "<owl:Class rdf:about=\"http://example.org/ontologic#Asset\"/>"
      xml `shouldSatisfy` isInfixOf "<owl:Class rdf:about=\"http://example.org/ontologic#Device\"><rdfs:subClassOf rdf:resource=\"http://example.org/ontologic#Asset\"/></owl:Class>"
      xml `shouldSatisfy` isInfixOf "</rdf:RDF>"

    it "emitted OWL passes python3 xml.etree well-formedness validation" $ do
      let reg = emptyRegistry
                  { concepts = [("Machine", Nothing), ("Mixer", Just "Machine")]
                  , axioms = []
                  , properties = [Property "rpm" "Mixer" PTInteger]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          xml = emitOwl reg
      (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import xml.etree.ElementTree as ET, sys; ET.fromstring(sys.stdin.read())"] xml
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""

  describe "base IRI (#33)" $ do
    it "uses the ontology's own namespace" $ do
      let reg = load "(namespace sys \"http://bsommers.github.io/ecosystem\") (def-concept sys:Thing)"
      emitOwl reg `shouldContain` "xml:base=\"http://bsommers.github.io/ecosystem\""
      emitOwl reg `shouldNotContain` "acme"
    it "falls back to a neutral default" $
      emitOwl (load "(def-concept Thing)") `shouldContain` "xml:base=\"http://example.org/ontologic\""
    it "honours an explicit base" $
      emitOwlWithBase "http://acme.test/onto" (load "(def-concept Thing)")
        `shouldContain` "xml:base=\"http://acme.test/onto\""

    it "emits rdfs:range referencing XML Schema datatypes" $ do
      let reg = load "(def-concept Sensor) (def-property reading Sensor Float) (def-property count Sensor Integer)"
          xml = emitOwl reg
      xml `shouldContain` "<rdfs:range rdf:resource=\"http://www.w3.org/2001/XMLSchema#float\"/>"
      xml `shouldContain` "<rdfs:range rdf:resource=\"http://www.w3.org/2001/XMLSchema#integer\"/>"
