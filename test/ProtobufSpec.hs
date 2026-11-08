{-# LANGUAGE OverloadedStrings #-}
module ProtobufSpec (spec) where

import Test.Hspec
import Parser (parseRegistry)
import Text.Megaparsec (parse)
import qualified Data.Text as T
import Emitters.Protobuf (emitProtobuf)

spec :: Spec
spec = describe "Protocol Buffers v3 Emitter" $ do
    let logicSource = T.pack $ unlines
          [ "(namespace iot \"http://example.org/iot#\")"
          , "(def-concept Asset)"
          , "(def-property asset_id Asset String :cardinality 1..1)"
          , "(def-concept Sensor Asset)"
          , "(def-property reading Sensor Float :cardinality 1..1)"
          , "(def-property error_code Sensor Integer :optional True :default \"0\")"
          , "(def-property metadata Sensor String :cardinality 0..*)"
          , "(def-property calibrations Sensor Double :cardinality 1..*)"
          , "(def-property is_active Sensor Boolean)"
          ]

    it "emits valid proto3 syntax, package and message structure" $ do
      case parse parseRegistry "test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let proto = emitProtobuf reg
          proto `shouldContain` "syntax = \"proto3\";"
          proto `shouldContain` "package iot;"
          proto `shouldContain` "message Asset {"
          proto `shouldContain` "message Sensor {"
          proto `shouldContain` "// Inherits from Asset"

    it "formats proto3 fields with proper types and tag numbers" $ do
      case parse parseRegistry "test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let proto = emitProtobuf reg
          proto `shouldContain` "string asset_id = 1;"
          proto `shouldContain` "float reading = 1;"
          proto `shouldContain` "optional int64 error_code = 2; // default: 0"
          proto `shouldContain` "repeated string metadata = 3;"
          proto `shouldContain` "repeated double calibrations = 4; // min_count: 1"
          proto `shouldContain` "bool is_active = 5;"
