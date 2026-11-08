module UnificationSpec (spec) where

import Test.Hspec
import qualified Data.Map as Map
import qualified Data.Set as Set
import IR.CNF
import Prover.Unification

spec :: Spec
spec = describe "First-Order Unification Engine (Prover.Unification)" $ do

    describe "Occurs-Check Soundness" $ do
        it "fails unification when variable occurs directly in term (X1 = f(X1))" $ do
            let t1 = TVar (VarId 1)
                t2 = TFunc "f" [TVar (VarId 1)]
            unifyTerms t1 t2 `shouldBe` Nothing
            unifyTerms t2 t1 `shouldBe` Nothing

        it "fails unification when variable occurs deeply nested (X1 = h(a, g(f(X1))))" $ do
            let t1 = TVar (VarId 1)
                t2 = TFunc "h" [TConst "a", TFunc "g" [TFunc "f" [TVar (VarId 1)]]]
            unifyTerms t1 t2 `shouldBe` Nothing

        it "succeeds when variable does not occur in compound term" $ do
            let t1 = TVar (VarId 1)
                t2 = TFunc "f" [TVar (VarId 2)]
            unifyTerms t1 t2 `shouldBe` Just (Map.singleton (VarId 1) (TFunc "f" [TVar (VarId 2)]))

    describe "Robinson Most General Unifier (MGU)" $ do
        it "unifies variable to variable as empty or single binding" $ do
            unifyTerms (TVar (VarId 1)) (TVar (VarId 1)) `shouldBe` Just emptySubst
            unifyTerms (TVar (VarId 1)) (TVar (VarId 2)) `shouldBe` Just (Map.singleton (VarId 1) (TVar (VarId 2)))

        it "unifies variable to constant" $ do
            unifyTerms (TVar (VarId 1)) (TConst "alpha") `shouldBe` Just (Map.singleton (VarId 1) (TConst "alpha"))

        it "unifies compound terms with cross-variable dependencies: f(X1, a) = f(b, X2)" $ do
            let t1 = TFunc "f" [TVar (VarId 1), TConst "a"]
                t2 = TFunc "f" [TConst "b", TVar (VarId 2)]
            case unifyTerms t1 t2 of
                Just subst -> do
                    applySubstTerm subst t1 `shouldBe` TFunc "f" [TConst "b", TConst "a"]
                    applySubstTerm subst t2 `shouldBe` TFunc "f" [TConst "b", TConst "a"]
                Nothing -> expectationFailure "Expected unification to succeed"

        it "fails on conflicting constant symbols" $ do
            unifyTerms (TConst "alpha") (TConst "beta") `shouldBe` Nothing

        it "fails on function symbol or arity mismatch" $ do
            unifyTerms (TFunc "f" [TConst "a"]) (TFunc "g" [TConst "a"]) `shouldBe` Nothing
            unifyTerms (TFunc "f" [TConst "a"]) (TFunc "f" [TConst "a", TConst "b"]) `shouldBe` Nothing

    describe "Literal & Complementary Unification" $ do
        it "unifies identical predicates with unifying argument lists" $ do
            let l1 = Pos "Device" [TVar (VarId 1)]
                l2 = Pos "Device" [TConst "sensor_1"]
            unifyLiterals l1 l2 `shouldBe` Just (Map.singleton (VarId 1) (TConst "sensor_1"))

        it "fails literal unification when polarities differ" $ do
            let l1 = Pos "Device" [TVar (VarId 1)]
                l2 = Neg "Device" [TConst "sensor_1"]
            unifyLiterals l1 l2 `shouldBe` Nothing

        it "succeeds on complementary literals: P(X1) and ~P(sensor_1)" $ do
            let l1 = Pos "Device" [TVar (VarId 1)]
                l2 = Neg "Device" [TConst "sensor_1"]
            unifyComplementary l1 l2 `shouldBe` Just (Map.singleton (VarId 1) (TConst "sensor_1"))

        it "fails complementary unification when predicates differ" $ do
            let l1 = Pos "Device" [TVar (VarId 1)]
                l2 = Neg "Sensor" [TVar (VarId 1)]
            unifyComplementary l1 l2 `shouldBe` Nothing

    describe "Substitution Composition" $ do
        it "correctly composes substitutions (σ1 ∘ σ2)" $ do
            let s1 = Map.singleton (VarId 1) (TVar (VarId 2))
                s2 = Map.singleton (VarId 2) (TConst "target")
                composed = composeSubst s1 s2
            applySubstTerm composed (TVar (VarId 1)) `shouldBe` TConst "target"
            applySubstTerm composed (TVar (VarId 2)) `shouldBe` TConst "target"

    describe "Clause Subsumption (C ⊆_σ D)" $ do
        it "empty clause subsumes any clause" $ do
            let emptyClause = Clause Set.empty
                c2 = Clause (Set.singleton (Pos "A" []))
            subsumes emptyClause c2 `shouldBe` True
            subsumes c2 emptyClause `shouldBe` False

        it "unit clause P(X) subsumes P(a) | Q(b)" $ do
            let c1 = Clause (Set.singleton (Pos "P" [TVar (VarId 1)]))
                c2 = Clause (Set.fromList [Pos "P" [TConst "a"], Pos "Q" [TConst "b"]])
            subsumes c1 c2 `shouldBe` True
            subsumes c2 c1 `shouldBe` False

        it "subsumption respects variable co-reference: P(X, X) subsumes P(a, a) but not P(a, b)" $ do
            let cGeneral = Clause (Set.singleton (Pos "P" [TVar (VarId 1), TVar (VarId 1)]))
                cMatch   = Clause (Set.singleton (Pos "P" [TConst "a", TConst "a"]))
                cNoMatch = Clause (Set.singleton (Pos "P" [TConst "a", TConst "b"]))
            subsumes cGeneral cMatch `shouldBe` True
            subsumes cGeneral cNoMatch `shouldBe` False

    describe "Standardize Apart" $ do
        it "shifts variable IDs in the second clause so variables do not overlap" $ do
            let c1 = Clause (Set.singleton (Pos "P" [TVar (VarId 1), TVar (VarId 2)]))
                c2 = Clause (Set.singleton (Neg "P" [TVar (VarId 1)]))
                (c1', c2') = standardizeApart c1 c2
            c1' `shouldBe` c1
            getLiterals c2' `shouldBe` Set.singleton (Neg "P" [TVar (VarId 3)])
