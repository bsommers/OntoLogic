module ShaclSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Shacl (emitShacl)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

spec :: Spec
spec = describe "SHACL Shapes Emitter" $ do
    it "emits standard prefixes and custom namespaces in Turtle format" $ do
        let reg = emptyRegistry
                { concepts = [("Device", Nothing)]
                , properties = [Property "id" "Device" PTString]
                , axioms = []
                , relations = []
                , namespaces = [NamespaceDecl "nist" (Just "http://csrc.nist.gov/ns#")]
                , imports = []
                }
            shacl = emitShacl reg
        shacl `shouldContain` "@prefix sh: <http://www.w3.org/ns/shacl#> ."
        shacl `shouldContain` "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ."
        shacl `shouldContain` "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ."
        shacl `shouldContain` "@prefix nist: <http://csrc.nist.gov/ns#> ."

    it "generates sh:NodeShape with sh:targetClass and sh:datatype" $ do
        let reg = emptyRegistry
                { concepts = [("Server", Nothing)]
                , properties = [ Property "port" "Server" PTInteger
                               , Property "name" "Server" PTString
                               ]
                , axioms = [ForAll "s" (Implies (Predicate "Server" [Var "s"])
                                               (And (Predicate "gte" [Var "port", Constant "1"])
                                                    (Predicate "lte" [Var "port", Constant "65535"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            shacl = emitShacl reg
        shacl `shouldContain` "ont:ServerShape"
        shacl `shouldContain` "a sh:NodeShape ;"
        shacl `shouldContain` "sh:targetClass ont:Server ;"
        shacl `shouldContain` "sh:path ont:port ;"
        shacl `shouldContain` "sh:datatype xsd:integer ;"
        shacl `shouldContain` "sh:minInclusive 1 ;"
        shacl `shouldContain` "sh:maxInclusive 65535"
        shacl `shouldContain` "sh:path ont:name ;"
        shacl `shouldContain` "sh:datatype xsd:string"

    it "emits relational object properties as sh:class constraints" $ do
        let reg = emptyRegistry
                { concepts = [("SecurityFinding", Nothing), ("Asset", Nothing)]
                , properties = [Property "severity" "SecurityFinding" PTFloat]
                , axioms = [ForAll "f" (Implies (Predicate "SecurityFinding" [Var "f"])
                                               (And (Predicate "gt" [Var "severity", Constant "0.0"])
                                                    (Predicate "lt" [Var "severity", Constant "10.0"])))]
                , relations = [Relation "affectsAsset" "SecurityFinding" "Asset"]
                , namespaces = []
                , imports = []
                }
            shacl = emitShacl reg
        shacl `shouldContain` "ont:SecurityFindingShape"
        shacl `shouldContain` "sh:path ont:affectsAsset ;"
        shacl `shouldContain` "sh:class ont:Asset"
        shacl `shouldContain` "sh:minExclusive 0.0 ;"
        shacl `shouldContain` "sh:maxExclusive 10.0"

    it "prefixes shapes with the ontology's namespace (#33)" $ do
      let reg = load "(namespace sys \"http://bsommers.github.io/ecosystem\") (def-concept sys:Thing)"
      emitShacl reg `shouldContain` "@prefix ont: <http://bsommers.github.io/ecosystem#> ."
      emitShacl reg `shouldNotContain` "acme"

    it "emits sh:or / sh:not shapes for conditional constraints" $ do
      let reg = emptyRegistry
              { concepts = [("Oven", Nothing)]
              , properties = [ Property "temperature" "Oven" PTInteger
                             , Property "is_active" "Oven" PTBoolean
                             ]
              , axioms = [ ForAll "o" (Implies (And (Predicate "Oven" [Var "o"])
                                                    (Predicate "eq" [Var "is_active", Constant "True"]))
                                               (Predicate "gt" [Var "temperature", Constant "100"]))
                         ]
              , relations = []
              , namespaces = []
              , imports = []
              }
          shacl = emitShacl reg
      shacl `shouldContain` "sh:or ("
      shacl `shouldContain` "sh:not ["
      shacl `shouldContain` "sh:path ont:is_active ;"
      shacl `shouldContain` "sh:hasValue true ;"
      shacl `shouldContain` "sh:path ont:temperature ;"
      shacl `shouldContain` "sh:minExclusive 100 ;"

    it "emits cardinality constraints (minCount, maxCount) and data types" $ do
      let reg = emptyRegistry
              { concepts = [("Sensor", Nothing)]
              , properties = [ PropertyDef "active" "Sensor" PTBoolean CardExactlyOne Nothing
                             , PropertyDef "reading" "Sensor" PTDouble CardZeroOrOne Nothing
                             , PropertyDef "tags" "Sensor" PTString CardOneOrMore Nothing
                             , Property "threshold" "Sensor" PTInteger
                             ]
              , axioms = [ ForAll "s" (Implies (Predicate "Sensor" [Var "s"])
                                               (Predicate "eq" [Var "threshold", Constant "42"]))
                         ]
              }
          shacl = emitShacl reg
      shacl `shouldContain` "sh:path ont:active ;"
      shacl `shouldContain` "sh:datatype xsd:boolean ;"
      shacl `shouldContain` "sh:minCount 1 ;"
      shacl `shouldContain` "sh:maxCount 1"
      shacl `shouldContain` "sh:path ont:reading ;"
      shacl `shouldContain` "sh:datatype xsd:double ;"
      shacl `shouldContain` "sh:hasValue 42"

    it "emits sh:not [ sh:hasValue ... ] for ne comparisons in conditional shapes" $ do
      let reg = emptyRegistry
              { concepts = [("Device", Nothing)]
              , properties = [ Property "status" "Device" PTString
                             , Property "code" "Device" PTInteger
                             ]
              , axioms = [ ForAll "d" (Implies (And (Predicate "Device" [Var "d"])
                                                    (Predicate "ne" [Var "status", Constant "error"]))
                                               (Predicate "eq" [Var "code", Constant "200"]))
                         ]
              }
          shacl = emitShacl reg
      shacl `shouldContain` "sh:not [ sh:hasValue error ]"
      shacl `shouldContain` "sh:hasValue 200"
