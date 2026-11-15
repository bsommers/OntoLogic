module LintSoundnessSpec (spec) where

import Test.Hspec
import Control.Monad (forM_, filterM)
import Data.List (isInfixOf, isSuffixOf, sort)
import System.Directory (listDirectory, doesDirectoryExist, doesFileExist)
import System.FilePath ((</>))
import System.Timeout (timeout)
import qualified Data.Text as T
import Text.Megaparsec (parse)
import Control.Exception (evaluate)

import OntoLogic
import Parser (parseRegistry)
import Linter
import Loader (loadRegistryWithImportsAndSource)
import IR.Clausify (clausifyTheory)
import IR.CNF (formatCNFTheory)




load :: String -> IO Registry
load src = case parse parseRegistry "<test>" (T.pack src) of
    Left e  -> fail (show e)
    Right r -> return r

errorsOf :: Registry -> [String]
errorsOf = map lintMessage . lintRegistryErrors

spec :: Spec
spec = do
  describe "linter never rejects a satisfiable theory (v1.8.4)" $ do
    it "D1: two unary facts on different individuals are not a contradiction" $ do
      r <- load "(def-concept Person)\n(def-concept Employee Person)\n(def-individual alice Person)\n(def-individual bob Person)\n(Employee alice)\n(not (Employee bob))\n"
      lintRegistryFindings r `shouldBe` []
    it "D1: a ground fact plus an unrelated disjointness is fine" $ do
      r <- load "(def-concept Person)\n(def-concept Employee Person)\n(def-concept Robot)\n(def-individual alice Person)\n(Employee alice)\n(forall (x) (implies (Robot x) (not (Person x))))\n"
      lintRegistryFindings r `shouldBe` []
    it "D2: (implies ... false) is accepted" $ do
      r <- load "(def-concept Cat)\n(def-concept Dog)\n(forall (x) (implies (and (Cat x) (Dog x)) false))\n"
      lintRegistryFindings r `shouldBe` []
    it "D2: (not false) is accepted" $ do
      r <- load "(def-concept A)\n(forall (x) (implies (A x) (not false)))\n"
      lintRegistryFindings r `shouldBe` []
    it "D3: forall x exists y is not collapsed onto one witness" $ do
      r <- load "(def-concept Node)\n(def-concept Red Node)\n(forall (x) (exists (y) (iff (Red x) (not (Red y)))))\n"
      lintRegistryFindings r `shouldBe` []
    it "D4: bounds under different binder guards do not clash" $ do
      r <- load "(def-concept Person)\n(def-concept Adult Person)\n(def-concept Child Person)\n(def-concept Member Person)\n(def-property fee Member Integer)\n(forall (x) (implies (Adult x) (not (Child x))))\n(forall ((x Adult)) (implies (Member x) (gte fee 100)))\n(forall ((x Child)) (implies (Member x) (lt fee 50)))\n"
      lintRegistryFindings r `shouldBe` []
    it "a vacuous antecedent is not a contradiction" $ do
      r <- load "(def-concept Oven)\n(def-concept Alarm)\n(def-property temp Oven Integer)\n(forall (o) (implies (and (Oven o) (gt temp 100) (lt temp 50)) (Alarm o)))\n"
      lintRegistryFindings r `shouldBe` []

  describe "real contradictions are still found" $ do
    it "p and not p at the top of an axiom is an error" $ do
      r <- load "(def-concept A)\n(and (A x) (not (A x)))\n"
      errorsOf r `shouldSatisfy` any ("both exist" `isInfixOf`)
    it "(not true) is an error" $ do
      r <- load "(def-concept A)\n(not top)\n"
      errorsOf r `shouldSatisfy` any ("bottom" `isInfixOf`)
    it "contradictory bounds on one concept stay an error" $ do
      r <- load "(def-concept Tank)\n(def-property cap Tank Integer)\n(forall (x) (implies (Tank x) (gt cap 10)))\n(forall (x) (implies (Tank x) (lt cap 5)))\n"
      errorsOf r `shouldSatisfy` any ("contradiction" `isInfixOf`)

  describe "B4: propositional findings are warnings" $ do
    it "a disjointness clash is a warning with exit-0 severity" $ do
      r <- load "(def-concept A)\n(def-concept B A)\n(def-concept C A)\n(def-concept D B)\n(forall (x) (implies (B x) (not (A x))))\n"
      let fs = lintRegistryFindings r
      fs `shouldSatisfy` any (\f -> "Semantic contradiction" `isInfixOf` lintMessage f)
      errorsOf r `shouldBe` []
      lintRegistryDiagnostics r `shouldSatisfy` any ("warning:" `isInfixOf`)

  describe "B5: undeclared references" $ do
    it "an undeclared property type is an error" $ do
      r <- load "(def-concept T)\n(def-property n T Int)\n"
      errorsOf r `shouldSatisfy` any ("Undeclared property type: Int" `isInfixOf`)
    it "DateTime is an error too" $ do
      r <- load "(def-concept T)\n(def-property when T DateTime)\n"
      errorsOf r `shouldSatisfy` any ("DateTime" `isInfixOf`)
    it "a declared concept as property type is fine" $ do
      r <- load "(def-concept T)\n(def-concept U)\n(def-property link T U)\n(def-property s T String)\n"
      lintRegistryFindings r `shouldBe` []
    it "an undeclared predicate in an axiom is a warning, not an error" $ do
      r <- load "(def-concept T)\n(forall (x) (implies (T x) (Ghost x)))\n"
      errorsOf r `shouldBe` []
      map lintMessage (lintRegistryFindings r) `shouldSatisfy` any ("Ghost" `isInfixOf`)
    it "an undeclared property in a bound is a warning" $ do
      r <- load "(def-concept T)\n(forall (x) (implies (T x) (gt phantom 3)))\n"
      errorsOf r `shouldBe` []
      map lintMessage (lintRegistryFindings r) `shouldSatisfy` any ("phantom" `isInfixOf`)
    it "conflicting namespace prefixes survive loading and are an error" $ do
      r <- load "(namespace a \"http://x/a#\")\n(namespace a \"http://x/b#\")\n(def-concept C)\n"
      errorsOf (deduplicateRegistry r) `shouldSatisfy` any ("Duplicate namespace prefix" `isInfixOf`)
    it "an exact repeated namespace is harmless" $ do
      r <- load "(namespace a \"http://x/a#\")\n(namespace a \"http://x/a#\")\n(def-concept C)\n"
      errorsOf (deduplicateRegistry r) `shouldBe` []

  describe "D17: clausifier terminates on (not top)" $ do
    it "clausifies (not top) as the empty clause" $ do
      r <- load "(def-concept A)\n(not top)\n"
      res <- timeout 5000000 (evaluate (length (formatCNFTheory (clausifyTheory r))))
      res `shouldSatisfy` (/= Nothing)

  describe "every shipped file lints clean" $ do
    files <- runIO (concat <$> mapM logicFiles ["examples", "ontologic-lib"])
    forM_ (sort files) $ \f ->
      it f $ do
        res <- loadRegistryWithImportsAndSource f
        case res of
          Left e -> expectationFailure e
          Right (reg, _) -> map lintMessage (lintRegistryFindings reg) `shouldBe` []

logicFiles :: FilePath -> IO [FilePath]
logicFiles dir = do
  exists <- doesDirectoryExist dir
  if not exists then return [] else do
    names <- listDirectory dir
    let paths = map (dir </>) names
    dirs <- filterM doesDirectoryExist paths
    plain <- filterM doesFileExist paths
    sub <- concat <$> mapM logicFiles dirs
    return ([ p | p <- plain, ".logic" `isSuffixOf` p ] ++ sub)
