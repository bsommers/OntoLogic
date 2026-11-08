module D2Spec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.D2 (emitD2)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

spec :: Spec
spec = do
  describe "D2 Emitter" $ do
    it "emits D2 class shapes, inheritance, and properties" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = []
                  , properties =
                      [ Property "serial_number" "Asset" PTString
                      , Property "temperature" "Device" PTInteger
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          diagram = emitD2 reg
      -- Keys are quoted as of #26; unquoted ':' is a D2 key/value separator.
      diagram `shouldContain` "\"Asset\": { shape: class }"
      diagram `shouldContain` "\"Device\": { shape: class }"
      diagram `shouldContain` "\"Device\" -> \"Asset\""
      diagram `shouldContain` "\"Asset\".\"serial_number\": String"
      diagram `shouldContain` "\"Device\".\"temperature\": Integer"

    it "quotes namespaced keys (#26)" $ do
      -- Unquoted ':' is a key/value separator in D2, so the declaration is invalid.
      let reg = load "(def-concept sys:Foo) (def-concept sys:Bar sys:Foo)"
          out = emitD2 reg
      out `shouldContain` "\"sys:Foo\": { shape: class }"
      out `shouldContain` "\"sys:Bar\" -> \"sys:Foo\""

    it "quotes namespaced keys in properties and associations (#26)" $ do
      let reg = load "(def-concept sys:Foo) (def-concept sys:Bar) (def-property sys:size sys:Bar Integer) (def-relation sys:uses sys:Bar sys:Foo)"
          out = emitD2 reg
      out `shouldContain` "\"sys:Bar\".\"sys:size\": Integer"
      out `shouldContain` "\"sys:Bar\" -> \"sys:Foo\": sys:uses"
