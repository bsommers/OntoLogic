{-# LANGUAGE OverloadedStrings #-}
module ImportSpec (spec) where

import Test.Hspec
import Text.Megaparsec (parse, errorBundlePretty)
import System.Directory (createDirectoryIfMissing, removeDirectoryRecursive, getTemporaryDirectory, withCurrentDirectory, getCurrentDirectory)
import System.FilePath ((</>))
import System.Environment (setEnv, unsetEnv)
import Control.Exception (bracket_)
import qualified Data.Text.IO as TIO

import OntoLogic
import Parser (parseRegistry, parseFOL)
import Loader (loadRegistryWithImports, loadRegistryWithLibPaths)
import Linter (lintRegistry)
import Emitters.Owl (emitOwl)

spec :: Spec
spec = do
  describe "Import & Namespace Syntax Parser" $ do
    it "parses import declaration" $ do
      let input = "(import \"submodels/bfo.logic\")\n(def-concept Server)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> do
          imports reg `shouldBe` [ImportDecl "submodels/bfo.logic"]
          concepts reg `shouldContain` [("Server", Nothing)]

    it "parses namespace declaration with URI" $ do
      let input = "(namespace bfo \"http://purl.obolibrary.org/obo/\")\n(def-concept Continuant)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> do
          namespaces reg `shouldBe` [NamespaceDecl "bfo" (Just "http://purl.obolibrary.org/obo/")]
          concepts reg `shouldContain` [("Continuant", Nothing)]

    it "parses namespace declaration with prefix only" $ do
      let input = "(namespace cco)\n(def-concept Agent)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> do
          namespaces reg `shouldBe` [NamespaceDecl "cco" Nothing]

    it "parses qualified concept identifiers" $ do
      let input = "(def-concept cco:Agent bfo:Continuant)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> do
          concepts reg `shouldBe` [("cco:Agent", Just "bfo:Continuant")]

    it "parses qualified predicates in FOL formulas" $ do
      let input = "forall (x y) (implies (and (bfo:Continuant x) (bfo:part_of x y)) (bfo:Continuant y))"
      case parse parseFOL "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right fol -> do
          fol `shouldBe` ForAll "x" (ForAll "y" 
            (Implies (And (Predicate "bfo:Continuant" [Var "x"]) (Predicate "bfo:part_of" [Var "x", Var "y"])) 
                     (Predicate "bfo:Continuant" [Var "y"])))

  describe "Namespace Linter Validations" $ do
    it "detects duplicate namespace prefix declarations" $ do
      let reg = emptyRegistry
                  { concepts = [("A", Nothing)]
                  , namespaces =
                      [ NamespaceDecl "bfo" (Just "http://uri1")
                      , NamespaceDecl "bfo" (Just "http://uri2")
                      ]
                  }
      lintRegistry reg `shouldContain` ["Duplicate namespace prefix declaration: bfo"]

  describe "Multi-File Recursive Loader & Dependency Resolution" $ do
    let tmpDir = "/tmp/ontologic_import_tests"

    it "resolves a single direct import" $ do
      createDirectoryIfMissing True tmpDir
      let depFile = tmpDir </> "base.logic"
          mainFile = tmpDir </> "main.logic"
      TIO.writeFile depFile "(def-concept Asset)\n(def-property serial Asset String)"
      TIO.writeFile mainFile "(import \"base.logic\")\n(def-concept Sensor Asset)"

      loadRes <- loadRegistryWithImports mainFile
      removeDirectoryRecursive tmpDir

      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          map fst (concepts reg) `shouldContain` ["Sensor", "Asset"]
          map propName (properties reg) `shouldContain` ["serial"]

    it "resolves multi-level transitive imports (A -> B -> C)" $ do
      createDirectoryIfMissing True tmpDir
      let cFile = tmpDir </> "c.logic"
          bFile = tmpDir </> "b.logic"
          aFile = tmpDir </> "a.logic"
      TIO.writeFile cFile "(def-concept Tier1)"
      TIO.writeFile bFile "(import \"c.logic\")\n(def-concept Tier2 Tier1)"
      TIO.writeFile aFile "(import \"b.logic\")\n(def-concept Tier3 Tier2)"

      loadRes <- loadRegistryWithImports aFile
      removeDirectoryRecursive tmpDir

      case loadRes of
        Left err -> expectationFailure err
        Right reg -> map fst (concepts reg) `shouldContain` ["Tier3", "Tier2", "Tier1"]

    it "deduplicates diamond dependencies (A -> B, A -> C, B -> D, C -> D)" $ do
      createDirectoryIfMissing True tmpDir
      let dFile = tmpDir </> "d.logic"
          bFile = tmpDir </> "b.logic"
          cFile = tmpDir </> "c.logic"
          aFile = tmpDir </> "a.logic"
      TIO.writeFile dFile "(def-concept RootCore)"
      TIO.writeFile bFile "(import \"d.logic\")\n(def-concept BranchB RootCore)"
      TIO.writeFile cFile "(import \"d.logic\")\n(def-concept BranchC RootCore)"
      TIO.writeFile aFile "(import \"b.logic\")\n(import \"c.logic\")\n(def-concept Top)"

      loadRes <- loadRegistryWithImports aFile
      removeDirectoryRecursive tmpDir

      case loadRes of
        Left err -> expectationFailure err
        Right reg -> do
          let rootOccurrences = filter (\(name, _) -> name == "RootCore") (concepts reg)
          length rootOccurrences `shouldBe` 1
          map fst (concepts reg) `shouldMatchList` ["Top", "BranchB", "BranchC", "RootCore"]

    it "detects and reports circular import loops (A -> B -> A)" $ do
      createDirectoryIfMissing True tmpDir
      let bFile = tmpDir </> "cycle_b.logic"
          aFile = tmpDir </> "cycle_a.logic"
      TIO.writeFile bFile "(import \"cycle_a.logic\")\n(def-concept NodeB)"
      TIO.writeFile aFile "(import \"cycle_b.logic\")\n(def-concept NodeA)"

      loadRes <- loadRegistryWithImports aFile
      removeDirectoryRecursive tmpDir

      case loadRes of
        Right _ -> expectationFailure "Expected circular import error"
        Left err -> err `shouldContain` "Circular import dependency detected"

    it "fails gracefully when an imported file is not found" $ do
      createDirectoryIfMissing True tmpDir
      let mainFile = tmpDir </> "missing_import.logic"
      TIO.writeFile mainFile "(import \"non_existent.logic\")\n(def-concept Main)"

      loadRes <- loadRegistryWithImports mainFile
      removeDirectoryRecursive tmpDir

      case loadRes of
        Right _ -> expectationFailure "Expected missing import error"
        Left err -> err `shouldContain` "Import not found: non_existent.logic"

  describe "Multi-Namespace OWL Emitter" $ do
    it "emits custom XML namespaces in RDF/OWL root tag" $ do
      let reg = emptyRegistry
                  { concepts = [("cco:Agent", Nothing)]
                  , axioms = []
                  , properties = []
                  , relations = []
                  , imports = []
                  , namespaces = [NamespaceDecl "cco" (Just "http://www.ontologyrepository.com/CommonCoreOntologies/")]
                  }
          owl = emitOwl reg
      owl `shouldContain` "xmlns:cco=\"http://www.ontologyrepository.com/CommonCoreOntologies/\""

  describe "standard library lookup (#29)" $ do
    it "resolves a stdlib import from another directory via ONTOLOGIC_PATH" $ do
      repo <- getCurrentDirectory
      tmp <- (</> "ontologic-import-29") <$> getTemporaryDirectory
      createDirectoryIfMissing True tmp
      writeFile (tmp </> "pump.logic") "(import \"bfo_2020.logic\")\n(def-concept Pump bfo:Process)\n"
      res <- bracket_ (setEnv "ONTOLOGIC_PATH" (repo </> "ontologic-lib")) (unsetEnv "ONTOLOGIC_PATH") $
               withCurrentDirectory tmp (loadRegistryWithImports "pump.logic")
      either expectationFailure (\reg -> lookup "Pump" (concepts reg) `shouldBe` Just (Just "bfo:Process")) res

    it "does not let the current directory shadow a stdlib import" $ do
      repo <- getCurrentDirectory
      tmp <- (</> "ontologic-shadow-29") <$> getTemporaryDirectory
      createDirectoryIfMissing True (tmp </> "sub")
      writeFile (tmp </> "bfo_2020.logic") "(def-concept Shadow)\n"
      writeFile (tmp </> "sub" </> "m.logic") "(import \"bfo_2020.logic\")\n"
      res <- withCurrentDirectory tmp (loadRegistryWithLibPaths [repo </> "ontologic-lib"] "sub/m.logic")
      either expectationFailure (\reg -> lookup "Shadow" (concepts reg) `shouldBe` Nothing) res
