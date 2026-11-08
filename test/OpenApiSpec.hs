module OpenApiSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.OpenApi (emitOpenApi)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

spec :: Spec
spec = describe "OpenAPI 3.1 Emitter" $ do
    it "generates OpenAPI 3.1 document structure with info and components/schemas" $ do
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
            yamlDoc = emitOpenApi reg
        yamlDoc `shouldContain` "openapi: 3.1.0"
        yamlDoc `shouldContain` "title: OntoLogic Compiled API Specification"
        yamlDoc `shouldContain` "components:"
        yamlDoc `shouldContain` "  schemas:"
        yamlDoc `shouldContain` "    Vehicle:"
        yamlDoc `shouldContain` "      type: object"
        yamlDoc `shouldContain` "      title: Vehicle"
        yamlDoc `shouldContain` "      properties:"
        yamlDoc `shouldContain` "        speed:"
        yamlDoc `shouldContain` "          type: integer"
        yamlDoc `shouldContain` "          minimum: 0"
        yamlDoc `shouldContain` "          maximum: 120"

    it "handles inheritance using allOf and $ref" $ do
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
            yamlDoc = emitOpenApi reg
        yamlDoc `shouldContain` "    Car:"
        yamlDoc `shouldContain` "      allOf:"
        yamlDoc `shouldContain` "        - $ref: '#/components/schemas/Vehicle'"
        yamlDoc `shouldContain` "        doors:"
        yamlDoc `shouldContain` "          minimum: 2"

    it "maps numeric bounds (gt, lt, eq) and float types" $ do
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
            yamlDoc = emitOpenApi reg
        yamlDoc `shouldContain` "    Sensor:"
        yamlDoc `shouldContain` "        voltage:"
        yamlDoc `shouldContain` "          type: number"
        yamlDoc `shouldContain` "          exclusiveMinimum: 0.5"
        yamlDoc `shouldContain` "          exclusiveMaximum: 5.0"

    it "emits an empty properties object for a concept with no fields (#26)" $ do
      -- A bare `properties:` key parses as null, which is not a valid schema.
      let reg = load "(def-concept Empty)"
      emitOpenApi reg `shouldContain` "      properties: {}"

    it "emits an empty properties object for a fieldless subclass (#26)" $ do
      let reg = load "(def-concept Base) (def-property b Base String) (def-concept Sub Base)"
      emitOpenApi reg `shouldContain` "          properties: {}"

    it "emits array items, minItems, and required properties array" $ do
        let reg = emptyRegistry
                { concepts = [("Cluster", Nothing)]
                , properties = [ PropertyDef "nodes" "Cluster" PTString CardZeroOrMore Nothing
                               , Property "primary" "Cluster" PTString
                               ]
                , axioms = []
                , relations = []
                , namespaces = []
                , imports = []
                }
            yamlDoc = emitOpenApi reg
        yamlDoc `shouldContain` "        nodes:"
        yamlDoc `shouldContain` "          type: array"
        yamlDoc `shouldContain` "          items:"
        yamlDoc `shouldContain` "            type: string"
        yamlDoc `shouldContain` "      required:\n      - primary"
