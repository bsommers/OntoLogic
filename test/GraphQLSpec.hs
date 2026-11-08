module GraphQLSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.GraphQL (emitGraphQL)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)
import Data.List (nub, isPrefixOf, isInfixOf)
import Loader (loadRegistryWithImports)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

spec :: Spec
spec = describe "GraphQL SDL Emitter" $ do
    it "generates GraphQL types, field mappings, and Query root" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing)]
                , properties = [ Property "speed" "Vehicle" PTInteger
                               , Property "name" "Vehicle" PTString
                               , Property "isActive" "Vehicle" PTBoolean
                               ]
                , axioms = []
                , relations = []
                , namespaces = []
                , imports = []
                }
            sdl = emitGraphQL reg
        sdl `shouldContain` "type Vehicle {"
        sdl `shouldContain` "  speed: Int!"
        sdl `shouldContain` "  name: String!"
        sdl `shouldContain` "  isActive: Boolean!"
        sdl `shouldContain` "type Query {"
        sdl `shouldContain` "  vehicles: [Vehicle!]!"

    it "flattens inherited properties into child GraphQL type" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing), ("Car", Just "Vehicle")]
                , properties = [ Property "speed" "Vehicle" PTInteger
                               , Property "doors" "Car" PTInteger
                               ]
                , axioms = []
                , relations = []
                , namespaces = []
                , imports = []
                }
            sdl = emitGraphQL reg
        sdl `shouldContain` "type Car {"
        sdl `shouldContain` "  doors: Int!"
        sdl `shouldContain` "  speed: Int!"
        sdl `shouldContain` "  cars: [Car!]!"
        sdl `shouldContain` "  vehicles: [Vehicle!]!"

    it "handles custom object property types" $ do
        let reg = emptyRegistry
                { concepts = [("Driver", Nothing), ("Car", Nothing)]
                , properties = [ Property "driver" "Car" (PTCustom "Driver") ]
                , axioms = []
                , relations = []
                , namespaces = []
                , imports = []
                }
            sdl = emitGraphQL reg
        sdl `shouldContain` "type Car {"
        sdl `shouldContain` "  driver: Driver"

    describe "valid SDL for the standard library (#26)" $ do
      it "gives every query field a unique name" $ do
        -- Two concepts differing only in namespace or case collapsed to one field
        -- name, which makes the whole schema invalid.
        loaded <- loadRegistryWithImports "ontologic-lib/ecosystem.logic"
        case loaded of
          Left err -> expectationFailure ("could not load ecosystem.logic: " ++ err)
          Right reg -> do
            let fields = [ takeWhile (/= ':') (dropWhile (== ' ') l)
                         | l <- lines (emitGraphQL reg), "  " `isPrefixOf` l, ": [" `isInfixOf` l ]
            length (nub fields) `shouldBe` length fields

      it "gives a subclass its parent's fields" $ do
        let reg = load "(def-concept A) (def-property a A String) (def-concept B A) (def-property b B String)"
        emitGraphQL reg `shouldContain` "type B {\n  b: String!\n  a: String!\n}"

      it "respects optionality and collections in GraphQL types" $ do
        let reg = load "(def-concept Item) (def-property opt Item String :optional True) (def-property list Item Integer :cardinality 0..*) (def-property reqList Item Float :cardinality 1..*)"
            sdl = emitGraphQL reg
        sdl `shouldContain` "opt: String\n"
        sdl `shouldContain` "list: [Int!]\n"
        sdl `shouldContain` "reqList: [Float!]!\n"
