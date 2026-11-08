module InheritedBoundsSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import Linter (lintRegistry)
import IR
import Solver (findUnsatConceptsWith, Prover(..))
import Emitters.Java (emitJavaWithPackage)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

propConstraints :: Name -> Name -> Registry -> [BoundConstraint]
propConstraints cls prop reg =
    concat [ compConstraints p
           | c <- irClasses (compileRegistry reg), compClassName c == cls
           , p <- compProperties c, compPropName p == prop ]

spec :: Spec
spec = do
  describe "conjunctive antecedents (#19)" $ do
    let reg = load $ unlines
          [ "(def-concept Tank) (def-concept Civil) (def-concept Military)"
          , "(def-property capacity Tank Integer)"
          , "(forall (x) (implies (and (Tank x) (Civil x)) (lt capacity 50)))"
          , "(forall (x) (implies (and (Tank x) (Military x)) (gt capacity 100)))"
          ]
    it "lints cleanly" $ lintRegistry reg `shouldBe` []
    it "puts no conditional bound on Tank.capacity" $ propConstraints "Tank" "capacity" reg `shouldBe` []
    it "reports both axioms as unmapped" $ length (irUnmappedAxioms (compileRegistry reg)) `shouldBe` 2

  describe "bounds inherited from superclasses (#17)" $ do
    let reg = load $ unlines
          [ "(def-concept Vessel)"
          , "(def-concept Tank Vessel)"
          , "(def-property capacity Vessel Integer)"
          , "(forall (x) (implies (Vessel x) (gt capacity 10)))"
          , "(forall (x) (implies (Tank x) (lt capacity 5)))"
          ]
    it "reports the cross-level contradiction in lint" $
      lintRegistry reg `shouldSatisfy` any ("Cross-axiom contradiction on Tank.capacity" `isInfixOf`)
    it "merges parent bounds into the subclass" $
      propConstraints "Tank" "capacity" reg `shouldBe`
        [BoundConstraint OpLt (VInt 5), BoundConstraint OpGt (VInt 10)]
    it "finds Tank unsatisfiable" $
      findUnsatConceptsWith Z3 reg `shouldReturn` Right ["Tank"]
    it "emits the parent's bound on the Java subclass" $
      case lookup "Tank" (emitJavaWithPackage "p" reg) of
        Nothing -> expectationFailure "no Tank class emitted"
        Just tank -> do
          tank `shouldContain` "@Max(4)"
          tank `shouldContain` "@Min(11)"
