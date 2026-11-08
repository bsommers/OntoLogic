module SMTSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.SMT (emitSMT)
import System.Process (readProcessWithExitCode)
import Data.List (isPrefixOf, isInfixOf)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)
import Solver (emitSMTForConsistency)

spec :: Spec
spec = describe "SMT-LIB2 Emitter" $ do
    it "generates sort declarations, concept constants, property functions, and assertions" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing)]
                , properties = [Property "speed" "Vehicle" PTInteger]
                , axioms = [ForAll "v" (Implies (Predicate "Vehicle" [Var "v"])
                                               (And (Predicate "gte" [Var "speed", Constant "0"])
                                                    (Predicate "lte" [Var "speed", Constant "120"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            smt = emitSMT reg
        smt `shouldContain` "(set-logic ALL)"
        smt `shouldContain` "(declare-sort Entity 0)"
        smt `shouldContain` "(declare-const Vehicle Entity)"
        smt `shouldContain` "(declare-fun Vehicle_speed (Entity) Int)"
        smt `shouldContain` "(assert (>= (Vehicle_speed Vehicle) 0))"
        smt `shouldContain` "(assert (<= (Vehicle_speed Vehicle) 120))"
        smt `shouldContain` "(check-sat)"
        smt `shouldContain` "(get-model)"

    it "declares subclass hierarchy assertions and relations" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing), ("Car", Just "Vehicle")]
                , properties = [ Property "speed" "Vehicle" PTInteger
                               , Property "doors" "Car" PTInteger
                               ]
                , axioms = [ ForAll "c" (Implies (Predicate "Car" [Var "c"]) (Predicate "gte" [Var "doors", Constant "2"])) ]
                , relations = [Relation "contains" "Car" "Vehicle"]
                , namespaces = []
                , imports = []
                }
            smt = emitSMT reg
        smt `shouldContain` "(assert (subClassOf Car Vehicle))"
        smt `shouldContain` "(declare-fun Car_doors (Entity) Int)"
        smt `shouldContain` "(assert (>= (Car_doors Car) 2))"
        smt `shouldContain` "(declare-fun contains (Entity Entity) Bool)"
        smt `shouldNotContain` "(assert (contains Car Vehicle))"

    it "formats floating point real bounds properly" $ do
        let reg = emptyRegistry
                { concepts = [("Metric", Nothing)]
                , properties = [Property "loss" "Metric" PTFloat]
                , axioms = [ForAll "m" (Implies (Predicate "Metric" [Var "m"])
                                               (And (Predicate "gt" [Var "loss", Constant "0"])
                                                    (Predicate "lt" [Var "loss", Constant "1.0"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            smt = emitSMT reg
        smt `shouldContain` "(declare-fun Metric_loss (Entity) Real)"
        smt `shouldContain` "(assert (> (Metric_loss Metric) 0.0))"
        smt `shouldContain` "(assert (< (Metric_loss Metric) 1.0))"

    describe "valid SMT-LIB2 for real inputs (#24)" $ do
      let load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))
          accepts solver args smt = do
            (_, out, err) <- readProcessWithExitCode solver args smt
            (out ++ err) `shouldSatisfy` (\o -> "sat" `isPrefixOf` o && not ("error" `isInfixOf` o))
          small = load "(def-concept Vuln) (def-property epss Vuln Double) (forall (x) (implies (Vuln x) (lt epss 0.001)))"
          shared = load "(def-concept Engine) (def-concept Car) (def-concept Wheel) (def-relation partOf Engine Car) (def-relation partOf Wheel Car)"
          negative = load "(def-concept T) (def-property temp T Integer) (forall (x) (implies (T x) (gt temp -5)))"

      it "prints decimals without exponents" $
        emitSMT small `shouldContain` "(assert (< (Vuln_epss Vuln) 0.001))"
      it "prints negatives as (- n)" $
        emitSMT negative `shouldContain` "(assert (> (T_temp T) (- 5)))"
      it "declares a shared relation name once" $
        length (filter ("(declare-fun partOf" `isPrefixOf`) (lines (emitSMT shared))) `shouldBe` 1
      it "is accepted by z3" $ mapM_ (accepts "z3" ["-in"] . emitSMT) [small, shared, negative]
      it "is accepted by cvc5" $ mapM_ (accepts "cvc5" ["--lang=smt2", "-"] . emitSMT) [small, shared, negative]

      it "emits declared individuals and 0-ary predicates accepted by z3 and cvc5" $ do
        let indReg = load $ unlines
                [ "(def-concept Origin)"
                , "(def-individual origin Origin)"
                , "(is_ready)"
                , "(forall (x) (implies (Origin x) (= x origin)))"
                ]
            smt = emitSMTForConsistency indReg
        smt `shouldContain` "(declare-const ind_origin Entity)"
        smt `shouldContain` "(assert (is_Origin ind_origin))"
        smt `shouldContain` "(declare-fun up_is_ready () Bool)"
        smt `shouldContain` "(assert up_is_ready)"
        accepts "z3" ["-in"] smt
        accepts "cvc5" ["--lang=smt2", "--produce-models", "--finite-model-find", "-"] smt
