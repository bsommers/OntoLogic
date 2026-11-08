module JsonSchemaSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.JsonSchema (emitJsonSchema)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

spec :: Spec
spec = describe "JSON Schema Emitter" $ do
    it "generates basic schema structure with $schema and $defs" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing)]
                , properties = [Property "speed" "Vehicle" PTInteger]
                , axioms = [ForAll "v" (Implies (Predicate "Vehicle" [Var "v"])
                                               (And (Predicate "gte" [Var "speed", Constant "0"])
                                                    (Predicate "lte" [Var "speed", Constant "120"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            schema = emitJsonSchema reg
        schema `shouldContain` "\"$schema\": \"https://json-schema.org/draft/2020-12/schema\""
        schema `shouldContain` "\"$defs\":"
        schema `shouldContain` "\"Vehicle\":"
        schema `shouldContain` "\"speed\":"
        schema `shouldContain` "\"type\": \"integer\""
        schema `shouldContain` "\"minimum\": 0"
        schema `shouldContain` "\"maximum\": 120"

    it "generates allOf and $ref for inheritance hierarchy" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing), ("Car", Just "Vehicle")]
                , properties = [ Property "speed" "Vehicle" PTInteger
                               , Property "doors" "Car" PTInteger
                               ]
                , axioms = [ ForAll "v" (Implies (Predicate "Vehicle" [Var "v"]) (Predicate "gte" [Var "speed", Constant "0"]))
                           , ForAll "c" (Implies (Predicate "Car" [Var "c"]) (Predicate "gte" [Var "doors", Constant "2"]))
                           ]
                , relations = []
                , namespaces = []
                , imports = []
                }
            schema = emitJsonSchema reg
        schema `shouldContain` "\"$ref\": \"#/$defs/Vehicle\""
        schema `shouldContain` "\"Car\":"
        schema `shouldContain` "\"doors\":"
        schema `shouldContain` "\"minimum\": 2"

    it "maps exclusive bounds and float types correctly" $ do
        let reg = emptyRegistry
                { concepts = [("Sensor", Nothing)]
                , properties = [Property "voltage" "Sensor" PTDouble]
                , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"])
                                               (And (Predicate "gt" [Var "voltage", Constant "0.5"])
                                                    (Predicate "lt" [Var "voltage", Constant "5.0"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            schema = emitJsonSchema reg
        schema `shouldContain` "\"voltage\":"
        schema `shouldContain` "\"type\": \"number\""
        schema `shouldContain` "\"exclusiveMinimum\": 0.5"
        schema `shouldContain` "\"exclusiveMaximum\": 5.0"

    it "emitted JSON Schema parses cleanly with Python json.loads" $ do
        let reg = emptyRegistry
                { concepts = [("Asset", Nothing), ("Host", Just "Asset")]
                , properties = [ Property "hostname" "Host" PTString
                               , Property "riskScore" "Host" PTFloat
                               ]
                , axioms = [ForAll "h" (Implies (Predicate "Host" [Var "h"])
                                               (And (Predicate "gte" [Var "riskScore", Constant "0.0"])
                                                    (Predicate "lte" [Var "riskScore", Constant "10.0"])))]
                , relations = [Relation "hasHost" "Asset" "Host"]
                , namespaces = []
                , imports = []
                }
            schema = emitJsonSchema reg
        (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import json, sys; json.loads(sys.stdin.read())"] schema
        exitCode `shouldBe` ExitSuccess
        stderr `shouldBe` ""

    it "emits array items, minItems, and required array" $ do
        let reg = emptyRegistry
                { concepts = [("Cluster", Nothing)]
                , properties = [ PropertyDef "nodes" "Cluster" PTString CardZeroOrMore Nothing
                               , Property "primary" "Cluster" PTString
                               , PropertyDef "timeout" "Cluster" PTInteger CardZeroOrOne Nothing
                               ]
                , axioms = []
                , relations = []
                , namespaces = []
                , imports = []
                }
            schema = emitJsonSchema reg
        schema `shouldContain` "\"nodes\":"
        schema `shouldContain` "\"type\": \"array\""
        schema `shouldContain` "\"items\":"
        schema `shouldContain` "\"type\": \"string\""
        schema `shouldContain` "\"required\": [\"primary\"]"
