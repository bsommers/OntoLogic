module ExamplesSpec (spec) where

import Test.Hspec
import System.Directory (listDirectory)
import System.FilePath ((</>), takeExtension)
import qualified Data.Text.IO as TIO
import Text.Megaparsec (parse, errorBundlePretty)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import Data.List (sort)

import OntoLogic
import Parser (parseRegistry)
import Linter (lintRegistry)
import Emitters.Java (emitJava)
import Emitters.Python (emitPython)
import Emitters.Neo4j (emitCypher)
import Emitters.Owl (emitOwl)
import Emitters.Mermaid (emitMermaid)
import Emitters.D2 (emitD2)
import Emitters.JsonSchema (emitJsonSchema)
import Emitters.Shacl (emitShacl)
import Emitters.Rust (emitRust)
import Emitters.Go (emitGo)
import Emitters.TypeScript (emitTypeScript)
import Emitters.OpenApi (emitOpenApi)
import Emitters.GraphQL (emitGraphQL)
import Emitters.SMT (emitSMT)

spec :: Spec
spec = do
  describe "Examples Integration Suite" $ do
    it "successfully parses, lints, and emits code for all domain files in examples/" $ do
      let dir = "examples"
      files <- listDirectory dir
      let logicFiles = sort [ dir </> f | f <- files, takeExtension f == ".logic" ]
      logicFiles `shouldNotBe` []

      mapM_ testExampleFile logicFiles

  describe "Scripts Verification" $ do
    it "verifies regenerate_examples.sh passes bash syntax validation" $ do
      (code, _, err) <- readProcessWithExitCode "bash" ["-n", "scripts/regenerate_examples.sh"] ""
      code `shouldBe` ExitSuccess
      err `shouldBe` ""

    it "verifies package_release.sh passes bash syntax validation" $ do
      (code, _, err) <- readProcessWithExitCode "bash" ["-n", "scripts/package_release.sh"] ""
      code `shouldBe` ExitSuccess
      err `shouldBe` ""

testExampleFile :: FilePath -> Expectation
testExampleFile path = do
  content <- TIO.readFile path
  case parse parseRegistry path content of
    Left err -> expectationFailure $ "Parse error in " ++ path ++ ":\n" ++ errorBundlePretty err
    Right reg -> do
      -- 1. Verify semantic linting passes
      let lintErrors = lintRegistry reg
      lintErrors `shouldBe` []

      -- 2. Verify all emitters generate non-empty code without exceptions
      let javaFiles = emitJava reg
      length javaFiles `shouldBe` length (concepts reg)

      let pyCode = emitPython reg
      null pyCode `shouldBe` False

      let rustCode = emitRust reg
      null rustCode `shouldBe` False

      let goCode = emitGo reg
      null goCode `shouldBe` False

      let tsCode = emitTypeScript reg
      null tsCode `shouldBe` False

      let openApiCode = emitOpenApi reg
      null openApiCode `shouldBe` False

      let graphQLCode = emitGraphQL reg
      null graphQLCode `shouldBe` False

      let smtCode = emitSMT reg
      null smtCode `shouldBe` False

      let cypherCode = emitCypher reg
      null cypherCode `shouldBe` False

      let owlCode = emitOwl reg
      null owlCode `shouldBe` False

      let jsonSchemaCode = emitJsonSchema reg
      null jsonSchemaCode `shouldBe` False

      let shaclCode = emitShacl reg
      null shaclCode `shouldBe` False

      let mermaidCode = emitMermaid reg
      null mermaidCode `shouldBe` False

      let d2Code = emitD2 reg
      null d2Code `shouldBe` False



