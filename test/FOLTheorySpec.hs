module FOLTheorySpec (spec) where

import Test.Hspec
import Data.List (isPrefixOf)
import Data.Text (pack)
import System.Process (readProcessWithExitCode)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import FOLTheory
import Solver (emitSMTForConsistency)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

spec :: Spec
spec = describe "FOL theory translation (#18)" $ do
    let dog = load "(def-concept Animal) (def-concept Dog) (forall (x) (implies (Dog x) (Animal x)))"
        tank = load "(def-concept Vessel) (def-concept Tank Vessel) (def-property capacity Vessel Integer) (forall (x) (implies (Tank x) (lt capacity 5)))"

    it "translates concept implications" $
        theoryAxioms (buildTheory dog) `shouldBe`
            ["(assert (forall ((v_x Entity)) (=> (is_Dog v_x) (is_Animal v_x))))\n"]

    it "translates bounds against the quantified variable" $
        theoryAxioms (buildTheory tank) `shouldBe`
            ["(assert (forall ((v_x Entity)) (=> (is_Tank v_x) (< (prop_capacity v_x) 5))))\n"]

    it "turns declared parents into implications" $
        theoryDecls (buildTheory tank) `shouldContain`
            "(assert (forall ((x Entity)) (=> (is_Tank x) (is_Vessel x))))"

    it "reports axioms it cannot translate" $ do
        let reg = load "(def-concept A) (definedIn \"a\" \"b\")"
        map snd (theorySkipped (buildTheory reg)) `shouldBe` ["unsupported predicate definedIn/2"]

    it "produces SMT that z3 accepts" $ do
        let smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory tank) ++ "(check-sat)\n"
        (_, out, _) <- readProcessWithExitCode "z3" ["-in"] smt
        out `shouldSatisfy` ("sat" `isPrefixOf`)

    describe "binary property relations and boolean predicates (#58)" $ do
        it "translates binary def-property with concept range into relation predicate" $ do
            let reg = load $ unlines
                    [ "(def-concept Device)"
                    , "(def-concept Sensor)"
                    , "(def-property connects_to Device Sensor)"
                    , "(forall (d s) (implies (connects_to d s) (Device d)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_d Entity)) (forall ((v_s Entity)) (=> (rel_connects_to v_d v_s) (is_Device v_d)))))\n"]
            theoryDecls th `shouldContain` "(declare-fun rel_connects_to (Entity Entity) Bool)\n"

        it "translates boolean literal comparisons (eq prop True/False)" $ do
            let reg = load $ unlines
                    [ "(def-concept Node)"
                    , "(def-property is_valid Node Boolean)"
                    , "(forall (x) (implies (Node x) (eq is_valid True)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_x Entity)) (=> (is_Node v_x) (= (prop_is_valid v_x) true))))\n"]

        it "translates 0-ary boolean predicates (is_active)" $ do
            let reg = load $ unlines
                    [ "(def-concept Service)"
                    , "(def-property is_active Service Boolean)"
                    , "(forall (x) (implies (Service x) (is_active)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_x Entity)) (=> (is_Service v_x) (prop_is_active v_x))))\n"]

    describe "FOL Language Completeness & SMT Theory expansion" $ do
        it "translates variable-variable equality (= x y) and inequality (!= x y)" $ do
            let reg = load $ unlines
                    [ "(def-concept Node)"
                    , "(forall (x y) (implies (and (Node x) (Node y)) (= x y)))"
                    , "(forall (x y) (implies (and (Node x) (Node y)) (!= x y)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                [ "(assert (forall ((v_x Entity)) (forall ((v_y Entity)) (=> (and (is_Node v_x) (is_Node v_y)) (= v_x v_y)))))\n"
                , "(assert (forall ((v_x Entity)) (forall ((v_y Entity)) (=> (and (is_Node v_x) (is_Node v_y)) (not (= v_x v_y))))))\n"
                ]

        it "translates multi-arity relations (n >= 3) to n-ary SMT predicates" $ do
            let reg = load $ unlines
                    [ "(def-concept Agent)"
                    , "(def-concept Region)"
                    , "(def-concept Time)"
                    , "(def-relation occupies Agent Region Time)"
                    , "(forall (a r t) (implies (occupies a r t) (Agent a)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-fun rel_occupies (Entity Entity Entity) Bool)\n"
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_a Entity)) (forall ((v_r Entity)) (forall ((v_t Entity)) (=> (rel_occupies v_a v_r v_t) (is_Agent v_a))))))\n"]

        it "translates uninterpreted function application terms in equality" $ do
            let reg = load $ unlines
                    [ "(def-concept Item)"
                    , "(forall (x y) (implies (Item x) (= (parentOf x) y)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-fun parentOf (Entity) Entity)\n"
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_x Entity)) (forall ((v_y Entity)) (=> (is_Item v_x) (= (parentOf v_x) v_y)))))\n"]

        it "translates truth constants top/true and bottom/false" $ do
            let reg = load $ unlines
                    [ "(def-concept Item)"
                    , "(forall (x) (implies (Item x) top))"
                    , "(forall (x) (implies bottom (Item x)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                [ "(assert (forall ((v_x Entity)) (=> (is_Item v_x) true)))\n"
                , "(assert (forall ((v_x Entity)) (=> false (is_Item v_x))))\n"
                ]

        it "translates typed quantifiers with concept sort as guarded" $ do
            let reg = load $ unlines
                    [ "(def-concept Device)"
                    , "(forall ((d Device)) (exists ((n Int)) (= d d)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_d Entity)) (=> (is_Device v_d) (exists ((v_n Int)) (= v_d v_d)))))\n"]

        it "translates concept-sorted existential with guard" $ do
            let reg = load $ unlines
                    [ "(def-concept Sensor)"
                    , "(def-concept Device)"
                    , "(forall ((d Device)) (exists ((s Sensor)) (= d d)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_d Entity)) (=> (is_Device v_d) (exists ((v_s Entity)) (and (is_Sensor v_s) (= v_d v_d))))))\n"]

        it "passes non-concept sorts through to SMT directly" $ do
            let reg = load $ unlines
                    [ "(def-concept Item)"
                    , "(forall ((x Item)) (exists ((n Integer)) (= x x)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_x Entity)) (=> (is_Item v_x) (exists ((v_n Int)) (= v_x v_x)))))\n"]


        it "translates user-defined unary predicates" $ do
            let reg = load $ unlines
                    [ "(def-concept Item)"
                    , "(forall (x) (implies (Item x) (Hazardous x)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-fun up_Hazardous (Entity) Bool)\n"
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_x Entity)) (=> (is_Item v_x) (up_Hazardous v_x))))\n"]

        it "translates user-defined binary predicates" $ do
            let reg = load $ unlines
                    [ "(def-concept Item)"
                    , "(forall (x y) (implies (Item x) (AdjacentTo x y)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-fun up_AdjacentTo (Entity Entity) Bool)\n"

    describe "user-defined predicate soundness (v1.5.1 review)" $ do
        let solverAccepts prover reg = do
                let args = if prover == "z3" then ["-in"] else ["--lang=smt2", "--produce-models"]
                (_, out, err) <- readProcessWithExitCode prover args (emitSMTForConsistency reg)
                takeWhile (/= '\n') out `shouldSatisfy` (`elem` ["sat", "unknown"])
                (out ++ err) `shouldNotContain` "(error"

        it "does not treat a unary use of a data property as a user predicate" $ do
            let reg = load $ unlines
                    [ "(def-concept Device)"
                    , "(def-property temperature Device Integer)"
                    , "(forall (x) (implies (Device x) (temperature x)))"
                    ]
                th = buildTheory reg
            map snd (theorySkipped th) `shouldBe` ["unsupported predicate temperature/1"]
            solverAccepts "z3" reg

        it "does not treat a unary use of a relation as a user predicate" $ do
            let reg = load $ unlines
                    [ "(def-concept Part)"
                    , "(def-relation partOf Part Part)"
                    , "(forall (x) (implies (Part x) (partOf x)))"
                    ]
                th = buildTheory reg
            map snd (theorySkipped th) `shouldBe` ["unsupported predicate partOf/1"]
            solverAccepts "z3" reg

        it "prefixes user predicates so they cannot clash with built-ins or base declarations" $ do
            let reg = load $ unlines
                    [ "(def-concept Node)"
                    , "(forall (x y) (implies (subClassOf x y) (Node x)))"
                    , "(forall (x y) (implies (distinct x y) (Node y)))"
                    , "(forall (x y) (implies (Node x) (= (f x) y)))"
                    , "(forall (x) (implies (f x) (Node x)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-fun up_subClassOf (Entity Entity) Bool)\n"
            theoryDecls th `shouldContain` "(declare-fun up_distinct (Entity Entity) Bool)\n"
            theoryDecls th `shouldContain` "(declare-fun up_f (Entity) Bool)\n"
            solverAccepts "z3" reg
            solverAccepts "cvc5" reg

        it "rejects non-Entity arguments to user predicates" $ do
            let reg = load $ unlines
                    [ "(def-concept Device)"
                    , "(def-property temperature Device Integer)"
                    , "(forall (x) (implies (Device x) (Hot (temperature x))))"
                    , "(forall (x) (implies (Device x) (Warm (+ x x))))"
                    ]
                th = buildTheory reg
            map snd (theorySkipped th) `shouldBe` ["unsupported predicate Hot/1", "unsupported predicate Warm/1"]
            theoryDecls th `shouldNotContain` "up_Hot"
            solverAccepts "z3" reg

        it "skips a user predicate used with inconsistent arities instead of redeclaring it" $ do
            let reg = load $ unlines
                    [ "(def-concept Cell)"
                    , "(forall (x) (implies (Cell x) (Adj x)))"
                    , "(forall (x y) (implies (Adj x y) (Cell x)))"
                    ]
                th = buildTheory reg
            map snd (theorySkipped th) `shouldBe`
                [ "predicate Adj used with inconsistent arities 1, 2"
                , "predicate Adj used with inconsistent arities 1, 2" ]
            theoryDecls th `shouldNotContain` "Adj"
            solverAccepts "cvc5" reg

        it "rejects non-Entity arguments to registered user predicates during translation" $ do
            let reg = load $ unlines
                    [ "(def-concept Device)"
                    , "(def-property temperature Device Integer)"
                    , "(forall (x) (implies (Device x) (Hot x)))"
                    , "(forall (x) (implies (Device x) (Hot (temperature x))))"
                    ]
                th = buildTheory reg
            map snd (theorySkipped th) `shouldBe` ["argument in user predicate Hot is not Entity-sorted"]
            theoryDecls th `shouldContain` "(declare-fun up_Hot (Entity) Bool)\n"
            solverAccepts "z3" reg

        it "does not misinterpret bound variables as property shorthand" $ do
            let reg = load $ unlines
                    [ "(def-concept Device)"
                    , "(def-property capacity Device Integer)"
                    , "(forall (d capacity) (implies (Device d) (= capacity d)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_d Entity)) (forall ((v_capacity Entity)) (=> (is_Device v_d) (= v_capacity v_d)))))\n"]
            solverAccepts "z3" reg

        it "translates 0-ary user-defined predicates" $ do
            let reg = load $ unlines
                    [ "(def-concept State)"
                    , "(is_ready)"
                    , "(forall (s) (implies (State s) (is_ready)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-fun up_is_ready () Bool)\n"
            theoryAxioms th `shouldContain` ["(assert up_is_ready)\n"]
            theoryAxioms th `shouldContain` ["(assert (forall ((v_s Entity)) (=> (is_State v_s) up_is_ready)))\n"]
            solverAccepts "z3" reg

        it "translates declared individuals into Entity constants" $ do
            let reg = load $ unlines
                    [ "(def-concept Origin)"
                    , "(def-individual origin Origin)"
                    , "(forall (x) (implies (Origin x) (= x origin)))"
                    ]
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-const ind_origin Entity)\n"
            theoryDecls th `shouldContain` "(assert (is_Origin ind_origin))\n"
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_x Entity)) (=> (is_Origin v_x) (= v_x ind_origin))))\n"]
            solverAccepts "z3" reg

        it "skips undeclared free variables as unbound" $ do
            let reg = load $ unlines
                    [ "(def-concept Number)"
                    , "(forall (x) (not (= x undeclared_const)))"
                    ]
                th = buildTheory reg
            map snd (theorySkipped th) `shouldBe` ["unbound variable undeclared_const"]

        it "promotes free variables to individuals when optFreeConstants is enabled" $ do
            let reg = load $ unlines
                    [ "(def-concept Number)"
                    , "(forall (x) (not (= x undeclared_const)))"
                    ]
                th = buildTheoryWithOptions (TheoryOptions { optFreeConstants = True }) reg
            theorySkipped th `shouldBe` []
            theoryDecls th `shouldContain` "(declare-const ind_undeclared_const Entity)\n"
            theoryAxioms th `shouldBe`
                ["(assert (forall ((v_x Entity)) (not (= v_x ind_undeclared_const))))\n"]

    describe "Typed Quantifiers & Connectives" $ do
        it "translates TypedForAll and TypedExists across standard sorts" $ do
            let reg = emptyRegistry
                        { concepts = [("Device", Nothing)]
                        , axioms =
                            [ TypedForAll "x" "Integer" (Eq (Var "x") (Constant "0"))
                            , TypedExists "y" "Float" (Eq (Var "y") (Constant "0.0"))
                            , TypedForAll "d" "Device" (Predicate "Device" [Var "d"])
                            ]
                        }
                th = buildTheory reg
            theoryAxioms th `shouldContain` ["(assert (forall ((v_x Int)) (= v_x 0)))\n"]
            theoryAxioms th `shouldContain` ["(assert (exists ((v_y Real)) (= v_y 0.0)))\n"]
            theoryAxioms th `shouldContain` ["(assert (forall ((v_d Entity)) (=> (is_Device v_d) (is_Device v_d))))\n"]

        it "translates Top, Bottom, and Iff connectives" $ do
            let reg = emptyRegistry
                        { concepts = [("Node", Nothing)]
                        , axioms =
                            [ Top
                            , Bottom
                            , Iff (Predicate "Node" [Var "n"]) Top
                            ]
                        }
                th = buildTheoryWithOptions (TheoryOptions { optFreeConstants = True }) reg
            theoryAxioms th `shouldContain` ["(assert true)\n"]
            theoryAxioms th `shouldContain` ["(assert false)\n"]
            theoryAxioms th `shouldContain` ["(assert (= (is_Node ind_n) true))\n"]

        it "reports errors when property or comparison appears outside any quantifier" $ do
            let reg = emptyRegistry
                        { concepts = [("Asset", Nothing)]
                        , properties = [Property "active" "Asset" PTBoolean, Property "val" "Asset" PTInteger]
                        , axioms =
                            [ Predicate "active" []
                            , Eq (Var "val") (Constant "5")
                            ]
                        }
                th = buildTheory reg
            map snd (theorySkipped th) `shouldContain` ["boolean property active outside any quantifier"]
            map snd (theorySkipped th) `shouldContain` ["comparison on val outside any quantifier"]

        it "translates properties evaluated on individual constants" $ do
            let reg = emptyRegistry
                        { concepts = [("Host", Nothing)]
                        , properties = [Property "is_active" "Host" PTBoolean]
                        , individuals = [("server1", Just "Host")]
                        , axioms = [Predicate "is_active" [Var "server1"]]
                        }
                th = buildTheory reg
            theorySkipped th `shouldBe` []
            theoryAxioms th `shouldBe` ["(assert (prop_is_active ind_server1))\n"]
