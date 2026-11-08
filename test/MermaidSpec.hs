module MermaidSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Mermaid (emitMermaid)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

spec :: Spec
spec = do
  describe "Mermaid Emitter" $ do
    it "emits class diagram header and concept classes" $ do
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
          diagram = emitMermaid reg
      diagram `shouldContain` "classDiagram\n"
      -- Ids are sanitized and the original name moved into a label as of #26.
      diagram `shouldContain` "class Asset[\"Asset\"]\n"
      diagram `shouldContain` "class Device[\"Device\"]\n"
      diagram `shouldContain` "Asset <|-- Device\n"
      diagram `shouldContain` "Asset : +String serial_number\n"
      diagram `shouldContain` "Device : +Integer temperature\n"

    it "uses sanitized ids with the original name as the label (#26)" $ do
      -- A raw ':' in a mermaid class id is a syntax error, so the namespace has to
      -- move into the display label.
      let reg = load "(def-concept sys:InformationArtifact)"
      emitMermaid reg `shouldContain` "class sys_InformationArtifact[\"sys:InformationArtifact\"]"
      emitMermaid reg `shouldNotContain` "class sys:InformationArtifact"

    it "uses sanitized ids for inheritance, attributes and associations (#26)" $ do
      let reg = load "(def-concept sys:Foo) (def-concept sys:Bar sys:Foo) (def-property sys:size sys:Bar Integer) (def-relation sys:uses sys:Bar sys:Foo)"
          out = emitMermaid reg
      out `shouldContain` "sys_Foo <|-- sys_Bar"
      -- Attribute names and edge labels are sanitized too: mermaid offers no quoting
      -- for either, and a raw ':' aborts the parse (verified with mmdc).
      out `shouldContain` "sys_Bar : +Integer sys_size"
      out `shouldContain` "sys_Bar --> sys_Foo : sys_uses"
