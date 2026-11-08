{-# LANGUAGE OverloadedStrings #-}
module RelationSpec (spec) where

import Test.Hspec
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry, parseFOL)
import Linter (lintRegistry)
import IR (compileRegistry, irRelations, compRelName, compRelDomain, compRelRange, compProperties, compPropName, irClasses, compClassName)
import Emitters.Neo4j (emitCypher)
import Emitters.Owl (emitOwl)
import Emitters.Mermaid (emitMermaid)
import Emitters.D2 (emitD2)
import Emitters.Java (emitJava)
import Emitters.Python (emitPython)
import Emitters.TypeScript (emitTypeScript)
import Emitters.Rust (emitRust)
import Emitters.Go (emitGo)

-- OWL IRIs are absolute as of #49: a prefixed name resolves into its declared
-- namespace, so the old "#prefix:Local" expectation encoded the double-prefix bug.
spec :: Spec
spec = do
  describe "Relational Axioms & Syntax" $ do
    it "parses def-relation correctly" $ do
      let input = "(def-concept Sensor)\n\
                  \(def-concept Gateway)\n\
                  \(def-relation connected_to Sensor Gateway)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> do
          relations reg `shouldBe` [Relation "connected_to" "Sensor" "Gateway"]

    it "parses multi-variable quantifiers in FOL formulas" $ do
      let input = "forall (s g) (implies (and (Sensor s) (connected_to s g)) (Gateway g))"
      case parse parseFOL "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right fol -> do
          fol `shouldBe` ForAll "s" (ForAll "g" (Implies (And (Predicate "Sensor" [Var "s"]) (Predicate "connected_to" [Var "s", Var "g"])) (Predicate "Gateway" [Var "g"])))

  describe "Relational Linter Validations" $ do
    it "detects undeclared domain concept in relations" $ do
      let reg = emptyRegistry
                  { concepts = [("Gateway", Nothing)]
                  , relations = [Relation "connected_to" "UnknownSensor" "Gateway"]
                  }
      lintRegistry reg `shouldContain` ["Undeclared domain concept: UnknownSensor in relation connected_to"]

    it "detects undeclared range concept in relations" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Nothing)]
                  , relations = [Relation "connected_to" "Sensor" "UnknownGateway"]
                  }
      lintRegistry reg `shouldContain` ["Undeclared range concept: UnknownGateway in relation connected_to"]

    it "detects duplicate relation definitions" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Nothing), ("Gateway", Nothing)]
                  , relations =
                      [ Relation "connected_to" "Sensor" "Gateway"
                      , Relation "connected_to" "Sensor" "Gateway"
                      ]
                  }
      lintRegistry reg `shouldContain` ["Duplicate relation definition: connected_to from Sensor to Gateway"]

  describe "Model IR Relational Compilation" $ do
    it "compiles relations into irRelations and resolves class association fields" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Nothing), ("Gateway", Nothing)]
                  , axioms = []
                  , properties = [Property "sensor_id" "Sensor" PTString]
                  , relations = [Relation "gateway" "Sensor" "Gateway"]
                  , imports = []
                  , namespaces = []
                  }
          modelIR = compileRegistry reg
      map compRelName (irRelations modelIR) `shouldBe` ["gateway"]
      let rel = head (irRelations modelIR)
      compRelDomain rel `shouldBe` "Sensor"
      compRelRange rel `shouldBe` "Gateway"

      let sensorClass = head (filter (\c -> compClassName c == "Sensor") (irClasses modelIR))
      map compPropName (compProperties sensorClass) `shouldBe` ["sensor_id", "gateway"]

  describe "Multi-Target Relational Emitters" $ do
    let sampleReg = emptyRegistry
                      { concepts = [("Sensor", Nothing), ("Gateway", Nothing)]
                      , axioms = []
                      , properties = []
                      , relations = [Relation "connected_to" "Sensor" "Gateway"]
                      , imports = []
                      , namespaces = []
                      }

    it "emits Neo4j Cypher relationship schema" $ do
      let cypher = emitCypher sampleReg
      cypher `shouldContain` "MERGE (s:OntologyClass {name: 'Sensor'})"
      cypher `shouldContain` "MERGE (t:OntologyClass {name: 'Gateway'})"
      cypher `shouldContain` "MERGE (s)-[:RELATION {name: 'connected_to'}]->(t)"

    it "emits W3C OWL ObjectProperty block" $ do
      let owl = emitOwl sampleReg
      owl `shouldContain` "<owl:ObjectProperty rdf:about=\"http://example.org/ontologic#connected_to\">"
      owl `shouldContain` "<rdfs:domain rdf:resource=\"http://example.org/ontologic#Sensor\"/>"
      owl `shouldContain` "<rdfs:range rdf:resource=\"http://example.org/ontologic#Gateway\"/>"

    it "emits Mermaid association arrows" $ do
      let mermaid = emitMermaid sampleReg
      mermaid `shouldContain` "Sensor --> Gateway : connected_to"

    it "emits D2 association arrows" $ do
      let d2 = emitD2 sampleReg
      -- D2 keys are quoted as of #26.
      d2 `shouldContain` "\"Sensor\" -> \"Gateway\": connected_to"

    it "emits Java typed getter and setter for association" $ do
      let files = emitJava sampleReg
          (_, sensorCode) = head (filter (\(name, _) -> name == "Sensor") files)
      sensorCode `shouldContain` "private Gateway connected_to;"
      sensorCode `shouldContain` "public Gateway getConnected_to()"
      sensorCode `shouldContain` "public void setConnected_to(Gateway val)"

    it "emits Python Pydantic typed reference field" $ do
      let py = emitPython sampleReg
      py `shouldContain` "connected_to: Gateway"

    it "emits TypeScript Zod schema with lazy relation reference" $ do
      let ts = emitTypeScript sampleReg
      ts `shouldContain` "connected_to: z.lazy(() => GatewaySchema)"

    it "emits Rust struct with boxed relation reference" $ do
      let rust = emitRust sampleReg
      rust `shouldContain` "pub connected_to: Option<Box<Gateway>>"

    it "emits Go struct with pointer relation reference" $ do
      let go = emitGo sampleReg
      go `shouldContain` "ConnectedTo *Gateway `json:\"connected_to,omitempty\"`"
