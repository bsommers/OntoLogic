module NativeProverSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set

import OntoLogic
    ( FOL(..)
    , Term(..)
    )
import IR.CNF
    ( VarId(..)
    , CNFTerm(..)
    , Literal(..)
    , Clause(..)
    , CNFTheory(..)
    )
import IR.Clausify
    ( clausify
    )
import Prover.Resolution
    ( runResolution
    , defaultConfig
    , ProverResult(..)
    , ProverStatus(..)
    , isRefutable
    )
import Prover.Tableau
    ( runTableau
    , runTableauClauses
    , defaultTableauConfig
    , TableauResult(..)
    , TableauStatus(..)
    , Model(..)
    )

spec :: Spec
spec = describe "TPTP & First-Order Logic Benchmark Suite" $ do

    describe "Aristotelian Syllogisms (Monadic Logic)" $ do

        it "proves Barbara syllogism (All M are P, All S are M |- All S are P)" $ do
            -- Premises:
            --   forall x. Man(x) -> Mortal(x)
            --   forall x. Greek(x) -> Man(x)
            -- Negated Conjecture:
            --   exists x. Greek(x) /\ ~Mortal(x)
            let p1 = ForAll "x" (Implies (Predicate "Man" [Var "x"]) (Predicate "Mortal" [Var "x"]))
                p2 = ForAll "x" (Implies (Predicate "Greek" [Var "x"]) (Predicate "Man" [Var "x"]))
                negGoal = Exists "x" (And (Predicate "Greek" [Var "x"]) (Not (Predicate "Mortal" [Var "x"])))
                clauses = clausify p1 ++ clausify p2 ++ clausify negGoal
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved
            prSteps res `shouldSatisfy` (<= 10)

        it "proves Celarent syllogism (No M are P, All S are M |- No S are P)" $ do
            -- Premises:
            --   forall x. Reptile(x) -> ~WarmBlooded(x)
            --   forall x. Snake(x) -> Reptile(x)
            -- Negated Conjecture:
            --   exists x. Snake(x) /\ WarmBlooded(x)
            let p1 = ForAll "x" (Implies (Predicate "Reptile" [Var "x"]) (Not (Predicate "WarmBlooded" [Var "x"])))
                p2 = ForAll "x" (Implies (Predicate "Snake" [Var "x"]) (Predicate "Reptile" [Var "x"]))
                negGoal = Exists "x" (And (Predicate "Snake" [Var "x"]) (Predicate "WarmBlooded" [Var "x"]))
                clauses = clausify p1 ++ clausify p2 ++ clausify negGoal
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

        it "proves Darii syllogism (All M are P, Some S is M |- Some S is P)" $ do
            -- Premises:
            --   forall x. Rabbit(x) -> Fast(x)
            --   exists x. Pet(x) /\ Rabbit(x)
            -- Negated Conjecture:
            --   forall x. Pet(x) -> ~Fast(x)
            let p1 = ForAll "x" (Implies (Predicate "Rabbit" [Var "x"]) (Predicate "Fast" [Var "x"]))
                p2 = Exists "x" (And (Predicate "Pet" [Var "x"]) (Predicate "Rabbit" [Var "x"]))
                negGoal = ForAll "x" (Implies (Predicate "Pet" [Var "x"]) (Not (Predicate "Fast" [Var "x"])))
                clauses = clausify p1 ++ clausify p2 ++ clausify negGoal
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

        it "proves Ferio syllogism (No M are P, Some S is M |- Some S is not P)" $ do
            -- Premises:
            --   forall x. Homework(x) -> ~Fun(x)
            --   exists x. Task(x) /\ Homework(x)
            -- Negated Conjecture:
            --   forall x. Task(x) -> Fun(x)
            let p1 = ForAll "x" (Implies (Predicate "Homework" [Var "x"]) (Not (Predicate "Fun" [Var "x"])))
                p2 = Exists "x" (And (Predicate "Task" [Var "x"]) (Predicate "Homework" [Var "x"]))
                negGoal = ForAll "x" (Implies (Predicate "Task" [Var "x"]) (Predicate "Fun" [Var "x"]))
                clauses = clausify p1 ++ clausify p2 ++ clausify negGoal
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

    describe "Relational Logic & Transitivity" $ do

        it "proves transitivity chain over 4 nodes: R(a,b) /\\ R(b,c) /\\ R(c,d) |- R(a,d)" $ do
            let trans = ForAll "x" (ForAll "y" (ForAll "z"
                            (Implies (And (Predicate "R" [Var "x", Var "y"])
                                          (Predicate "R" [Var "y", Var "z"]))
                                     (Predicate "R" [Var "x", Var "z"]))))
                f1 = Predicate "R" [Constant "a", Constant "b"]
                f2 = Predicate "R" [Constant "b", Constant "c"]
                f3 = Predicate "R" [Constant "c", Constant "d"]
                negGoal = Not (Predicate "R" [Constant "a", Constant "d"])
                clauses = clausify trans ++ clausify f1 ++ clausify f2 ++ clausify f3 ++ clausify negGoal
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

        it "proves symmetry and transitivity implies reflexivity on non-empty domain" $ do
            -- Symmetry:  forall x y. R(x, y) -> R(y, x)
            -- Trans:     forall x y z. R(x, y) /\ R(y, z) -> R(x, z)
            -- Seriality: forall x. exists y. R(x, y)
            -- Negated:   exists c. ~R(c, c)
            let sym = ForAll "x" (ForAll "y"
                        (Implies (Predicate "R" [Var "x", Var "y"])
                                 (Predicate "R" [Var "y", Var "x"])))
                trans = ForAll "x" (ForAll "y" (ForAll "z"
                            (Implies (And (Predicate "R" [Var "x", Var "y"])
                                          (Predicate "R" [Var "y", Var "z"]))
                                     (Predicate "R" [Var "x", Var "z"]))))
                serial = ForAll "x" (Exists "y" (Predicate "R" [Var "x", Var "y"]))
                negGoal = Exists "c" (Not (Predicate "R" [Var "c", Var "c"]))
                clauses = clausify sym ++ clausify trans ++ clausify serial ++ clausify negGoal
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

    describe "First-Order Logic Challenge Problems" $ do

        it "proves Russell's Barber Paradox refutation via Ordered Resolution" $ do
            -- In a town, the barber shaves all and only those men who do not shave themselves:
            -- forall x. (Shaves(barber, x) <-> ~Shaves(x, x))
            let barberAxiom = ForAll "x"
                    (Iff (Predicate "Shaves" [Constant "barber", Var "x"])
                         (Not (Predicate "Shaves" [Var "x", Var "x"])))
                clauses = clausify barberAxiom
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

        it "proves Russell's Barber Paradox refutation via Clausal Semantic Tableaux" $ do
            let barberAxiom = ForAll "x"
                    (Iff (Predicate "Shaves" [Constant "barber", Var "x"])
                         (Not (Predicate "Shaves" [Var "x", Var "x"])))
                clauses = clausify barberAxiom
                res = runTableauClauses defaultTableauConfig clauses

            trStatus res `shouldBe` ClosedTableau

        it "proves Drinker's Paradox (exists x. Drinks(x) -> forall y. Drinks(y))" $ do
            -- In classical logic, there is someone in the pub such that, if they drink, everyone drinks.
            -- Conjecture: exists x. (Drinks(x) -> forall y. Drinks(y))
            -- Negation:   forall x. (Drinks(x) /\ exists y. ~Drinks(y))
            let drinkerThm = Exists "x" (Implies (Predicate "Drinks" [Var "x"])
                                                 (ForAll "y" (Predicate "Drinks" [Var "y"])))
                negConjecture = Not drinkerThm
                clauses = clausify negConjecture
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

        it "proves Pelletier Problem 18 (exists y forall x. (P(y) -> P(x)))" $ do
            let p18 = Exists "y" (ForAll "x" (Implies (Predicate "P" [Var "y"]) (Predicate "P" [Var "x"])))
                clauses = clausify (Not p18)
                theory = CNFTheory (Set.fromList clauses)
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

    describe "Equational Reasoning via Built-in Equality" $ do

        it "refutes contradictory negative equality via equality resolution" $ do
            -- x != a \/ Q(x) resolved with ~Q(a) refutes to contradiction
            let c1 = Clause (Set.fromList [NeqT (TVar (VarId 1)) (TConst "a"), Pos "Q" [TVar (VarId 1)]])
                c2 = Clause (Set.singleton (Neg "Q" [TConst "a"]))
                theory = CNFTheory (Set.fromList [c1, c2])
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved

        it "refutes contradictory equality facts via semantic tableaux" $ do
            let f1 = Eq (Constant "a") (Constant "b")
                f2 = Predicate "P" [Constant "a"]
                f3 = Not (Predicate "P" [Constant "b"])
                res = runTableau defaultTableauConfig [f1, f2, f3]

            trStatus res `shouldBe` ClosedTableau

    describe "Countermodel Generation on Non-Theorems (Tableaux)" $ do

        it "extracts countermodel for Affirming the Consequent (P -> Q, Q |/- P)" $ do
            -- Theory: (P -> Q) /\ Q /\ ~P
            let f1 = Implies (Predicate "P" []) (Predicate "Q" [])
                f2 = Predicate "Q" []
                f3 = Not (Predicate "P" [])
                res = runTableau defaultTableauConfig [f1, f2, f3]

            trStatus res `shouldBe` OpenTableau
            case trCounterModel res of
                Nothing -> expectationFailure "Expected countermodel"
                Just m  -> do
                    modelTrueLits m `shouldSatisfy` Set.member (Pos "Q" [])
                    modelFalseLits m `shouldSatisfy` Set.member (Neg "P" [])

        it "extracts countermodel for Denying the Antecedent (P -> Q, ~P |/- ~Q)" $ do
            -- Theory: (P -> Q) /\ ~P /\ Q
            let f1 = Implies (Predicate "P" []) (Predicate "Q" [])
                f2 = Not (Predicate "P" [])
                f3 = Predicate "Q" []
                res = runTableau defaultTableauConfig [f1, f2, f3]

            trStatus res `shouldBe` OpenTableau
            case trCounterModel res of
                Nothing -> expectationFailure "Expected countermodel"
                Just m  -> do
                    modelTrueLits m `shouldSatisfy` Set.member (Pos "Q" [])
                    modelFalseLits m `shouldSatisfy` Set.member (Neg "P" [])

        it "saturates without refutation on non-transitive relation" $ do
            -- R(a, b) /\ R(b, c) does NOT entail R(a, c) without transitivity
            let c1 = Clause (Set.singleton (Pos "R" [TConst "a", TConst "b"]))
                c2 = Clause (Set.singleton (Pos "R" [TConst "b", TConst "c"]))
                c3 = Clause (Set.singleton (Neg "R" [TConst "a", TConst "c"]))
                theory = CNFTheory (Set.fromList [c1, c2, c3])
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Saturated
            isRefutable theory `shouldBe` False
