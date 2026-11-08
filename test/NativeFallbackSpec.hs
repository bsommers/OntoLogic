module NativeFallbackSpec (spec) where

import Test.Hspec
import OntoLogic
import Solver
import Control.Exception (bracket_)
import System.Environment (lookupEnv, setEnv, unsetEnv)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)

spec :: Spec
spec = describe "Zero-Dependency Native Fallback Engine" $ do
    let load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

    describe "Autonomous Fallback When No External SMT Provers in PATH" $ do
        it "checks consistency (SAT) via fallback to Tableau" $ do
            let reg = load $ unlines
                  [ "(def-concept Device)"
                  , "(def-concept Sensor Device)"
                  ]
            res <- withPath "/nonexistent" (checkConsistencyWith AutoProver reg)
            case res of
                Sat _ -> return ()
                _     -> expectationFailure $ "Expected Sat via native fallback, got: " ++ show res

        it "proves subsumption theorem via fallback to Tableau" $ do
            let reg = load $ unlines
                  [ "(def-concept Vehicle)"
                  , "(def-concept Car Vehicle)"
                  ]
            res <- withPath "/nonexistent" (proveSubsumptionWith AutoProver reg "Car" "Vehicle")
            res `shouldBe` Subsumed

        it "disproves subsumption and yields countermodel via fallback to Tableau" $ do
            let reg = load $ unlines
                  [ "(def-concept Vehicle)"
                  , "(def-concept Building)"
                  ]
            res <- withPath "/nonexistent" (proveSubsumptionWith AutoProver reg "Vehicle" "Building")
            case res of
                NotSubsumed model -> model `shouldContain` "Countermodel"
                _                 -> expectationFailure $ "Expected NotSubsumed via native fallback, got: " ++ show res

        it "detects concept incoherence via fallback to Tableau" $ do
            let reg = load $ unlines
                  [ "(def-concept ValidNode)"
                  , "(def-concept DeadNode)"
                  , "(forall (x) (implies (DeadNode x) (not (DeadNode x))))"
                  ]
            unsatList <- withPath "/nonexistent" (findUnsatConceptsWith AutoProver reg)
            unsatList `shouldBe` Right ["DeadNode"]

        it "explains UNSAT core via fallback to Resolution refutation" $ do
            let reg = load $ unlines
                  [ "(def-concept Impossible)"
                  , "(exists (x) (Impossible x))"
                  , "(forall (x) (implies (Impossible x) (not (Impossible x))))"
                  ]
            explRes <- withPath "/nonexistent" (explainUnsatWith AutoProver reg)
            case explRes of
                Left err -> expectationFailure err
                Right expl -> do
                    unsatCoreNames expl `shouldSatisfy` (\names -> length names >= 2)
                    unlines (unsatCoreDetails expl) `shouldContain` "Impossible"

withPath :: String -> IO a -> IO a
withPath p act = do
    old <- lookupEnv "PATH"
    bracket_ (setEnv "PATH" p) (maybe (unsetEnv "PATH") (setEnv "PATH") old) act
