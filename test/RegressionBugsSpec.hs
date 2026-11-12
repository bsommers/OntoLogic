-- | Regression tests for defects found while writing the 1.8.2 user guide:
--   emitter output for subclasses, the REPL/CLI unsat-core explanation, and numeric-bound
--   contradictions on provers without arithmetic.
module RegressionBugsSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf, isPrefixOf)
import Data.Text (pack)
import System.Directory (findExecutable)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import IR
import Solver (checkConsistencyWith, explainUnsatWith, Prover(..), UnsatExplanation(..))
import Emitters.Java (emitJavaWithPackage)
import Emitters.OpenApi (emitOpenApi)
import Emitters.Python (emitPython)
import Emitters.TPTP (emitTPTP)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

-- | A subclass that restates an inherited bound and adds a property of its own.
truckReg :: Registry
truckReg = load $ unlines
    [ "(def-concept Vehicle)"
    , "(def-concept Truck Vehicle)"
    , "(def-property age Vehicle Integer)"
    , "(def-property max_load Truck Double)"
    , "(forall (v) (implies (Vehicle v) (and (gte age 0) (lte age 130))))"
    , "(forall (t) (implies (Truck t) (lte age 90)))"
    , "(forall (t) (implies (Truck t) (gt max_load 0.5)))"
    ]

-- | A universal lower bound contradicted by an existential witness.
pumpConflictReg :: Registry
pumpConflictReg = load $ unlines
    [ "(def-concept Pump)"
    , "(def-property pressure Pump Integer)"
    , "(forall (p) (implies (Pump p) (gte pressure 100)))"
    , "(exists (p) (and (Pump p) (lt pressure 50)))"
    ]

-- | Disjoint bounds on different concepts' instances: satisfiable, must stay SAT.
pumpValveReg :: Registry
pumpValveReg = load $ unlines
    [ "(def-concept Pump)"
    , "(def-concept Valve)"
    , "(def-property pressure Pump Integer)"
    , "(def-individual p1 Pump)"
    , "(def-individual v1 Valve)"
    , "(forall (p) (implies (Pump p) (gte pressure 100)))"
    , "(forall (v) (implies (Valve v) (lt pressure 50)))"
    ]

sensorReg :: Registry
sensorReg = load $ unlines
    [ "(def-concept Device)"
    , "(def-concept SmartSensor Device)"
    , "(def-property batteryLevel SmartSensor Integer)"
    , "(forall (s) (implies (SmartSensor s) (and (gte batteryLevel 0) (lte batteryLevel 100))))"
    , "(forall (s) (implies (SmartSensor s) (gt batteryLevel 100)))"
    ]

constraintsOf :: Name -> Name -> Registry -> [BoundConstraint]
constraintsOf cls prop reg =
    concat [ compConstraints p
           | c <- irClasses (compileRegistry reg), compClassName c == cls
           , p <- compProperties c, compPropName p == prop ]

count :: String -> String -> Int
count needle hay = length [ () | t <- tailsOf hay, needle `isPrefixOf` t ]
  where tailsOf s = case s of { [] -> [[]]; (_:r) -> s : tailsOf r }

withProver :: String -> IO () -> IO ()
withProver exe act = findExecutable exe >>= maybe (pendingWith (exe ++ " not installed")) (const act)

isUnsat, isSat :: SolverResult -> Bool
isUnsat Unsat = True
isUnsat _     = False
isSat (Sat _) = True
isSat _       = False

spec :: Spec
spec = do
  describe "restated inherited bounds" $ do
    it "keeps only the tightest bound in each direction" $
      constraintsOf "Truck" "age" truckReg `shouldBe`
        [BoundConstraint OpLte (VInt 90), BoundConstraint OpGte (VInt 0)]
    it "prefers the strict operator on a tie" $
      tightenBounds [BoundConstraint OpGte (VInt 5), BoundConstraint OpGt (VInt 5)]
        `shouldBe` [BoundConstraint OpGt (VInt 5)]
    it "keeps a contradiction it cannot resolve (lower above upper)" $
      constraintsOf "SmartSensor" "batteryLevel" sensorReg `shouldBe`
        [BoundConstraint OpGt (VInt 100), BoundConstraint OpLte (VInt 100)]
    it "emits each pydantic keyword once" $ do
      let py = emitPython truckReg
      py `shouldContain` "age: int = Field(le=90, ge=0)"
      py `shouldNotContain` "ge=0, le=130)\n    max_load"
    it "emits a single @Max on the Java subclass" $
      case lookup "Truck" (emitJavaWithPackage "p" truckReg) of
        Nothing -> expectationFailure "no Truck class emitted"
        Just j  -> do
          count "@Max(" j `shouldBe` 1
          count "@Min(" j `shouldBe` 1

  describe "OpenAPI subclass properties" $ do
    let yaml = lines (emitOpenApi truckReg)
    it "nests each property one level under its allOf properties key" $ do
      yaml `shouldContain` ["          properties:"]
      yaml `shouldContain` ["            max_load:"]
      yaml `shouldContain` ["              type: number"]
    it "leaves no subclass property at the base-schema indent" $
      filter ("        max_load:" ==) yaml `shouldBe` []

  describe "unsat-core explanation agrees with the consistency check" $ do
    it "cites the conflicting property bounds (Z3)" $ withProver "z3" $ do
      checkConsistencyWith Z3 sensorReg >>= (`shouldSatisfy` isUnsat)
      res <- explainUnsatWith Z3 sensorReg
      case res of
        Left err -> expectationFailure err
        Right e  -> do
          unsatCoreNames e `shouldSatisfy` (not . null)
          unwords (unsatCoreDetails e) `shouldSatisfy` ("SmartSensor.batteryLevel" `isInfixOf`)

  describe "numeric-bound contradictions without arithmetic" $ do
    it "native prover finds the forall/exists bound conflict" $
      checkConsistencyWith NativeProver pumpConflictReg >>= (`shouldSatisfy` isUnsat)
    it "native prover keeps disjoint bounds on different entities satisfiable" $
      checkConsistencyWith NativeProver pumpValveReg >>= (`shouldSatisfy` isSat)
    it "TPTP states that the two bounds exclude each other" $
      emitTPTP pumpConflictReg `shouldSatisfy` ("~(cmp_gte(T, c_100) & cmp_lt(T, c_50))" `isInfixOf`)
    it "vampire finds the conflict" $ withProver "vampire" $
      checkConsistencyWith Vampire pumpConflictReg >>= (`shouldSatisfy` isUnsat)
    it "vampire keeps disjoint bounds on different entities satisfiable" $ withProver "vampire" $
      checkConsistencyWith Vampire pumpValveReg >>= (`shouldSatisfy` isSat)
