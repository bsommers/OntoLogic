{-# LANGUAGE OverloadedStrings #-}
module TPTPSpec (spec) where

import Test.Hspec
import Parser (parseRegistry)
import Text.Megaparsec (parse, errorBundlePretty)
import qualified Data.Text as T
import System.Directory (findExecutable)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import OntoLogic
import FOLTheory (makeEnv)
import Emitters.TPTP (emitTPTP, emitTPTPSubsumption, emitTPTPCoherence, folToTPTP, termToTPTP, tptpVar, tptpConst)
import Targets (lookupTarget, targetEmit, defaultEmitOptions)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (T.pack src))

spec :: Spec
spec = describe "TPTP First-Order Form (FOF) Emitter & Vampire Bridge" $ do
    let ontologySrc = unlines
          [ "(def-concept Device)"
          , "(def-property serial_number Device String :cardinality 1..1)"
          , "(def-concept Robot Device)"
          , "(def-property battery_level Robot Integer)"
          , "(def-relation manages Robot Device)"
          , "(forall (r) (implies (Robot r) (Device r)))"
          , "(forall (x y) (implies (manages x y) (and (Robot x) (Device y))))"
          ]
        reg = load ontologySrc

    it "emits subclass hierarchy axioms in TPTP FOF" $ do
        let tptp = emitTPTP reg
        tptp `shouldContain` "fof(subclass_Robot_Device, axiom, (! [X] : (is_Robot(X) => is_Device(X))))."

    it "emits relation domain and range axioms in TPTP FOF" $ do
        let tptp = emitTPTP reg
        tptp `shouldContain` "fof(rel_domain_manages, axiom, (! [X, Y] : (rel_manages(X, Y) => is_Robot(X))))."
        tptp `shouldContain` "fof(rel_range_manages, axiom, (! [X, Y] : (rel_manages(X, Y) => is_Device(Y))))."

    it "emits FOL axioms in valid TPTP FOF syntax" $ do
        let tptp = emitTPTP reg
        tptp `shouldContain` "fof(ax_1, axiom, (! [V_r] : (is_Robot(V_r) => is_Device(V_r))))."
        tptp `shouldContain` "fof(ax_2, axiom, (! [V_x] : (! [V_y] : (rel_manages(V_x, V_y) => (is_Robot(V_x) & is_Device(V_y))))))."

    it "emits subsumption conjecture in TPTP format" $ do
        let tptp = emitTPTPSubsumption reg "Robot" "Device"
        tptp `shouldContain` "fof(conjecture_subsumption, conjecture, (! [X] : (is_Robot(X) => is_Device(X))))."

    it "emits concept coherence check in TPTP format" $ do
        let tptp = emitTPTPCoherence reg "Robot"
        tptp `shouldContain` "fof(assert_nonempty_Robot, axiom, (? [X] : is_Robot(X)))."

    it "formats unmapped axiom warnings with TPTP comment prefix (%)" $ do
        let unmappedSrc = unlines
              [ "(def-concept A)"
              , "(def-concept B)"
              , "(forall (x y) (or (A x) (B y)))"
              ]
            unmappedReg = load unmappedSrc
            target = maybe (error "tptp target not found") id (lookupTarget "tptp")
            files = targetEmit target defaultEmitOptions unmappedReg
            tptp = concatMap snd files
        tptp `shouldContain` "% WARNING: The following axioms could not be mapped to field constraints:"
        tptp `shouldContain` "%   forall x (forall y (A(x) or B(y)))"

    it "proves theorems cleanly with vampire when installed" $ do
        mVampire <- findExecutable "vampire"
        case mVampire of
            Nothing -> pendingWith "vampire not installed"
            Just vampire -> do
                let tptp = emitTPTPSubsumption reg "Robot" "Device"
                (code, out, _err) <- readProcessWithExitCode vampire ["--mode", "casc", "-t", "2", "/dev/stdin"] tptp
                code `shouldBe` ExitSuccess
                out `shouldContain` "SZS status Theorem"

    describe "FOF Translation & Quantifier Handling" $ do
        let env = makeEnv reg

        it "translates TypedForAll for known concept sorts and unknown sorts" $ do
            folToTPTP env [] (TypedForAll "d" "Device" (Predicate "Robot" [Var "d"]))
                `shouldBe` Right "(! [V_d] : (is_Device(V_d) => is_Robot(V_d)))"
            folToTPTP env [] (TypedForAll "x" "NonConcept" (Predicate "is_active" [Var "x"]))
                `shouldBe` Right "(! [V_x] : up_is_active(V_x))"

        it "translates TypedExists for known concept sorts and unknown sorts" $ do
            folToTPTP env [] (TypedExists "r" "Robot" (Predicate "Device" [Var "r"]))
                `shouldBe` Right "(? [V_r] : (is_Robot(V_r) & is_Device(V_r)))"
            folToTPTP env [] (TypedExists "x" "NonConcept" (Predicate "is_active" [Var "x"]))
                `shouldBe` Right "(? [V_x] : up_is_active(V_x))"

        it "translates Top and Bottom constants" $ do
            folToTPTP env [] Top `shouldBe` Right "$true"
            folToTPTP env [] Bottom `shouldBe` Right "$false"

        it "translates Eq, Iff, and Not connectives" $ do
            folToTPTP env [] (Iff (Predicate "Robot" [Var "x"]) (Predicate "Device" [Var "x"]))
                `shouldBe` Right "(is_Robot(V_x) <=> is_Device(V_x))"
            folToTPTP env [] (Not (Predicate "Robot" [Var "x"]))
                `shouldBe` Right "(~is_Robot(V_x))"
            folToTPTP env ["r"] (Eq (Var "battery_level") (Constant "100"))
                `shouldBe` Right "(prop_battery_level(V_r) = c_100)"
            folToTPTP env [] (Eq (Var "battery_level") (Constant "100"))
                `shouldBe` Right "(prop_battery_level = c_100)"
            folToTPTP env [] (Eq (Constant "1") (Constant "2"))
                `shouldBe` Right "(c_1 = c_2)"

        it "translates comparison predicates in forward and inverted order" $ do
            folToTPTP env ["r"] (Predicate "gt" [Var "battery_level", Constant "10"])
                `shouldBe` Right "cmp_gt(prop_battery_level(V_r), c_10)"
            folToTPTP env ["r"] (Predicate "gt" [Constant "10", Var "battery_level"])
                `shouldBe` Right "cmp_lt(prop_battery_level(V_r), c_10)"
            folToTPTP env [] (Predicate "lte" [Var "battery_level", Constant "50"])
                `shouldBe` Right "cmp_lte(prop_battery_level, c_50)"
            folToTPTP env [] (Predicate "lte" [Constant "50", Var "battery_level"])
                `shouldBe` Right "cmp_gte(prop_battery_level, c_50)"
            folToTPTP env [] (Predicate "ne" [Constant "a", Constant "b"])
                `shouldBe` Right "(c_a != c_b)"
            folToTPTP env [] (Predicate "!=" [Constant "x", Constant "y"])
                `shouldBe` Right "(c_x != c_y)"
            folToTPTP env [] (Predicate "=" [Constant "x", Constant "y"])
                `shouldBe` Right "(c_x = c_y)"

        it "formats TPTP constant and variable terms" $ do
            tptpVar "robot-id" `shouldBe` "V_robot_id"
            tptpConst "42" `shouldBe` "c_42"
            tptpConst "-42" `shouldBe` "c_neg_42"
            tptpConst "3.14" `shouldBe` "c_3_14"
            tptpConst "-1.5" `shouldBe` "c_m1_5"
            tptpConst "True" `shouldBe` "c_true"
            tptpConst "False" `shouldBe` "c_false"
            tptpConst "identifier-string" `shouldBe` "c_identifier_string"

        it "translates nested function applications" $ do
            termToTPTP env ["x"] (Apply "fn_plus" [Var "x", Constant "5"])
                `shouldBe` Right "fn_fn_plus(V_x, c_5)"

        it "emits domain and range axioms for PTCustom properties" $ do
            let customReg = emptyRegistry
                              { concepts = [("Device", Nothing), ("Person", Nothing)]
                              , properties = [Property "owner" "Device" (PTCustom "Person")]
                              }
                tptp = emitTPTP customReg
            tptp `shouldContain` "fof(prop_domain_owner, axiom, (! [X, Y] : (prop_owner(X, Y) => is_Device(X))))."
            tptp `shouldContain` "fof(prop_range_owner, axiom, (! [X, Y] : (prop_owner(X, Y) => is_Person(Y))))."
