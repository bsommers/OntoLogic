{-# LANGUAGE OverloadedStrings #-}
module CardinalitySpec (spec) where

import Test.Hspec
import OntoLogic
import Parser (parseRegistry)
import Text.Megaparsec (parse)
import qualified Data.Text as T
import Emitters.Python (emitPython)
import Emitters.TypeScript (emitTypeScript)
import Emitters.Rust (emitRust)
import Emitters.Go (emitGo)
import Emitters.Java (emitJavaWithPackage)
import Emitters.Shacl (emitShacl)

spec :: Spec
spec = do
  describe "Property & Relation Cardinality, Optionality, and Defaults" $ do
    let logicSource = T.pack $ unlines
          [ "(def-concept Device)"
          , "(def-property serial_number Device String :cardinality 1..1)"
          , "(def-property description Device String :cardinality 0..1 :default \"none\")"
          , "(def-property reading Device Integer :optional True)"
          , "(def-property tags Device String :cardinality 0..*)"
          , "(def-property required_sensors Device String :cardinality 1..*)"
          ]

    it "parses cardinality, optionality, and default modifiers correctly" $ do
      case parse parseRegistry "cardinality_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let props = properties reg
          length props `shouldBe` 5

          case [p | p <- props, propName p == "serial_number"] of
            [p] -> propCardinality p `shouldBe` CardExactlyOne
            _   -> expectationFailure "Missing serial_number"

          case [p | p <- props, propName p == "description"] of
            [p] -> do
              propCardinality p `shouldBe` CardZeroOrOne
              propDefault p `shouldBe` Just "none"
            _   -> expectationFailure "Missing description"

          case [p | p <- props, propName p == "reading"] of
            [p] -> propCardinality p `shouldBe` CardZeroOrOne
            _   -> expectationFailure "Missing reading"

          case [p | p <- props, propName p == "tags"] of
            [p] -> propCardinality p `shouldBe` CardZeroOrMore
            _   -> expectationFailure "Missing tags"

          case [p | p <- props, propName p == "required_sensors"] of
            [p] -> propCardinality p `shouldBe` CardOneOrMore
            _   -> expectationFailure "Missing required_sensors"

    it "emits Python Pydantic models with Optional and List types" $ do
      case parse parseRegistry "cardinality_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let py = emitPython reg
          py `shouldContain` "from typing import Optional, List"
          py `shouldContain` "serial_number: str"
          py `shouldContain` "description: Optional[str] = None"
          py `shouldContain` "reading: Optional[int] = None"
          py `shouldContain` "tags: List[str] = Field(default_factory=list)"
          py `shouldContain` "required_sensors: List[str] = Field(min_length=1)"

    it "emits TypeScript Zod schemas with .optional(), .default(), and z.array()" $ do
      case parse parseRegistry "cardinality_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let ts = emitTypeScript reg
          ts `shouldContain` "serial_number: z.string()"
          ts `shouldContain` "description: z.string().optional().default(\"none\")"
          ts `shouldContain` "reading: z.number().int().optional()"
          ts `shouldContain` "tags: z.array(z.string())"
          ts `shouldContain` "required_sensors: z.array(z.string()).nonempty()"

    it "emits Rust structs with Option<T> and Vec<T>" $ do
      case parse parseRegistry "cardinality_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let rs = emitRust reg
          rs `shouldContain` "pub serial_number: String"
          rs `shouldContain` "pub description: Option<String>"
          rs `shouldContain` "pub reading: Option<i64>"
          rs `shouldContain` "pub tags: Vec<String>"
          rs `shouldContain` "pub required_sensors: Vec<String>"

    it "emits Go structs with pointers (*T) and slices ([]T)" $ do
      case parse parseRegistry "cardinality_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let go = emitGo reg
          go `shouldContain` "SerialNumber string"
          go `shouldContain` "Description *string"
          go `shouldContain` "Reading *int"
          go `shouldContain` "Tags []string"
          go `shouldContain` "RequiredSensors []string"

    it "emits Java getters with List and NotEmpty annotations" $ do
      case parse parseRegistry "cardinality_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let javaFiles = emitJavaWithPackage "com.cardinality.test" reg
          case lookup "Device" javaFiles of
            Nothing -> expectationFailure "Device not emitted"
            Just javaCode -> do
              javaCode `shouldContain` "@NotNull\n    public String getSerial_number()"
              javaCode `shouldContain` "public String getDescription()"
              javaCode `shouldContain` "public Integer getReading()"
              javaCode `shouldContain` "public java.util.List<String> getTags()"
              javaCode `shouldContain` "@jakarta.validation.constraints.NotEmpty\n    public java.util.List<String> getRequired_sensors()"

    it "emits SHACL shapes with sh:minCount and sh:maxCount" $ do
      case parse parseRegistry "cardinality_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let shacl = emitShacl reg
          shacl `shouldContain` "sh:minCount 1"
          shacl `shouldContain` "sh:maxCount 1"
