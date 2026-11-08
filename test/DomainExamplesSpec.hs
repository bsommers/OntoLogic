module DomainExamplesSpec (spec) where

import Test.Hspec
import Control.Monad (forM_, unless)
import Data.Char (isSpace)
import Data.List (isPrefixOf, isSuffixOf, sort)
import System.Directory (doesFileExist, findExecutable, listDirectory)
import System.FilePath ((</>), takeBaseName)

import OntoLogic
import Solver
import Loader (loadRegistryWithImports)

fixturesDir :: FilePath
fixturesDir = "test/fixtures/domains"

-- | 30s cap keeps a runaway fixture from hanging CI.
domainOpts :: SolverOptions
domainOpts = defaultSolverOptions { optTimeoutSeconds = Just 30 }

-- | Z3 (then CVC5) reasons over the integer property bounds the conflict
-- fixtures rely on; the native prover does not. Nothing available -> Nothing.
pickSmtProver :: IO (Maybe Prover)
pickSmtProver = do
  z3 <- findExecutable "z3"
  cvc <- findExecutable "cvc5"
  return $ case (z3, cvc) of
    (Just _, _) -> Just Z3
    (_, Just _) -> Just CVC5
    _           -> Nothing

data DomainExpect = ExpConcept String | ExpRelation String | ExpProperty String

trim :: String -> String
trim = f . f where f = reverse . dropWhile isSpace

parseExpect :: FilePath -> String -> Either String [DomainExpect]
parseExpect path = mapM one . filter keep . map trim . lines
  where
    keep l = not (null l) && not ("#" `isPrefixOf` l)
    one l = case words l of
      ["concept", n]  -> Right (ExpConcept n)
      ["relation", n] -> Right (ExpRelation n)
      ["property", n] -> Right (ExpProperty n)
      _ -> Left (path ++ ": malformed line: " ++ show l)

checkExpectation :: FilePath -> Registry -> DomainExpect -> Maybe String
checkExpectation file reg e = case e of
  ExpConcept n  -> miss "concept" n (n `elem` map fst (concepts reg))
  ExpRelation n -> miss "relation" n (n `elem` map relName (relations reg))
  ExpProperty n -> miss "property" n (n `elem` map propName (properties reg))
  where
    miss kind n ok
      | ok = Nothing
      | otherwise = Just (file ++ ": expected " ++ kind ++ " '" ++ n ++ "' not found in registry")

spec :: Spec
spec = describe "Domain examples (data-driven fixtures)" $ do
  expectFiles <- runIO $ sort . filter (".expect" `isSuffixOf`) <$> listDirectory fixturesDir
  let names = map takeBaseName expectFiles

  describe "fixture coverage guard" $
    it "every examples/domain_*.logic has a matching .expect fixture" $ do
      exs <- listDirectory "examples"
      let domains = [ takeBaseName f | f <- sort exs, "domain_" `isPrefixOf` f, ".logic" `isSuffixOf` f ]
          missing = [ d | d <- domains, d `notElem` names ]
      unless (null missing) $
        expectationFailure $ "domain examples without " ++ fixturesDir ++ "/<name>.expect: " ++ show missing

  forM_ names $ \name -> describe name $ do
    let exampleF  = "examples" </> name ++ ".logic"
        expectF  = fixturesDir </> name ++ ".expect"
        conflict = fixturesDir </> name ++ "_conflict.logic"

    it "parses and declares every expected name" $ do
      txt <- readFile expectF
      exps <- either (\e -> expectationFailure e >> return []) return (parseExpect expectF txt)
      r <- loadRegistryWithImports exampleF
      case r of
        Left err  -> expectationFailure (exampleF ++ ": failed to load: " ++ err)
        Right reg -> do
          let problems = [ m | ex <- exps, Just m <- [checkExpectation exampleF reg ex] ]
          unless (null problems) $ expectationFailure (unlines problems)

    it "is consistent (SAT)" $ do
      prover <- maybe NativeProver id <$> pickSmtProver
      r <- loadRegistryWithImports exampleF
      case r of
        Left err  -> expectationFailure (exampleF ++ ": failed to load: " ++ err)
        Right reg -> do
          res <- checkConsistencyWithOptions domainOpts prover reg
          case res of
            Sat _ -> return ()
            _     -> expectationFailure (exampleF ++ ": expected SAT but got " ++ show res)

    hasConflict <- runIO (doesFileExist conflict)
    if hasConflict
      then it "conflict fixture is inconsistent (UNSAT)" $ do
       mp <- pickSmtProver
       case mp of
        Nothing -> pendingWith "neither z3 nor cvc5 installed in PATH"
        Just prover -> do
         r <- loadRegistryWithImports conflict
         case r of
          Left err  -> expectationFailure (conflict ++ ": failed to load: " ++ err)
          Right reg -> do
            res <- checkConsistencyWithOptions domainOpts prover reg
            case res of
              Unsat -> return ()
              _     -> expectationFailure (conflict ++ ": expected UNSAT but got " ++ show res)
      else it "conflict fixture is inconsistent (UNSAT)" $
        pendingWith ("no " ++ conflict)
