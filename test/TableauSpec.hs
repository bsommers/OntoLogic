module TableauSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set

import OntoLogic
    ( FOL(..)
    , Term(..)
    , Registry(..)
    , emptyRegistry
    )
import IR.CNF
    ( VarId(..)
    , CNFTerm(..)
    , Literal(..)
    , Clause(..)
    , CNFTheory(..)
    )
import Prover.Tableau

spec :: Spec
spec = describe "Analytic Semantic Tableaux & Countermodel Engine" $ do

    describe "Smullyan Rule Classification" $ do

        it "classifies conjunction as AlphaRule" $ do
            let f = TFAnd (TFAtom (Pos "P" [])) (TFAtom (Pos "Q" []))
            classifyFormula f `shouldBe` AlphaRule

        it "classifies disjunction as BetaRule" $ do
            let f = TFOr (TFAtom (Pos "P" [])) (TFAtom (Pos "Q" []))
            classifyFormula f `shouldBe` BetaRule

        it "classifies universal quantifier as GammaRule" $ do
            let f = TFForAll (VarId 1) (TFAtom (Pos "P" [TVar (VarId 1)]))
            classifyFormula f `shouldBe` GammaRule

        it "classifies existential quantifier as DeltaRule" $ do
            let f = TFExists (VarId 1) (TFAtom (Pos "P" [TVar (VarId 1)]))
            classifyFormula f `shouldBe` DeltaRule

        it "classifies atomic literal as LiteralRule" $ do
            let f = TFAtom (Pos "P" [TConst "a"])
            classifyFormula f `shouldBe` LiteralRule

    describe "Formula Conversion & Normalization" $ do

        it "converts FOL implication and negations into NNF TableauFormula" $ do
            -- (P -> Q) desugars to (~P \/ Q)
            let fol = Implies (Predicate "P" [Constant "a"]) (Predicate "Q" [Constant "a"])
                tf = folToTableau fol
            case tf of
                TFOr (TFAtom (Neg "P" [TConst "a"])) (TFAtom (Pos "Q" [TConst "a"])) -> True `shouldBe` True
                _ -> expectationFailure ("Unexpected formula structure: " ++ formatTableauFormula tf)

        it "converts CNF Clause with variables into universally quantified disjunction" $ do
            let c = Clause (Set.fromList [Neg "Man" [TVar (VarId 1)], Pos "Mortal" [TVar (VarId 1)]])
                tf = clauseToTableau c
            classifyFormula tf `shouldBe` GammaRule

        it "converts full CNFTheory into list of TableauFormulas" $ do
            let c1 = Clause (Set.singleton (Pos "A" [TConst "x"]))
                c2 = Clause (Set.singleton (Neg "B" [TConst "y"]))
                theory = CNFTheory (Set.fromList [c1, c2])
                tfs = cnfTheoryToTableau theory
            length tfs `shouldBe` 2

    describe "Propositional Tableaux Refutations (UNSAT)" $ do

        it "refutes direct complementary literals" $ do
            let f1 = Predicate "P" [Constant "a"]
                f2 = Not (Predicate "P" [Constant "a"])
                res = runTableau defaultTableauConfig [f1, f2]
            trStatus res `shouldBe` ClosedTableau
            trProof res `shouldSatisfy` maybe False (\p -> tpBranches p >= 1)

        it "refutes disjunctive contradiction across branches (A \\/ B) /\\ ~A /\\ ~B" $ do
            let f1 = Or (Predicate "A" []) (Predicate "B" [])
                f2 = Not (Predicate "A" [])
                f3 = Not (Predicate "B" [])
                res = runTableau defaultTableauConfig [f1, f2, f3]
            trStatus res `shouldBe` ClosedTableau
            case trProof res of
                Nothing -> expectationFailure "Expected proof trace"
                Just p  -> do
                    tpBranches p `shouldSatisfy` (>= 2)
                    length (tpClosures p) `shouldSatisfy` (>= 2)

        it "refutes Modus Ponens denial: (P -> Q) /\\ P /\\ ~Q" $ do
            let f1 = Implies (Predicate "P" []) (Predicate "Q" [])
                f2 = Predicate "P" []
                f3 = Not (Predicate "Q" [])
                res = runTableau defaultTableauConfig [f1, f2, f3]
            trStatus res `shouldBe` ClosedTableau

    describe "Propositional Countermodel Generation (SAT)" $ do

        it "finds open saturated branch and extracts model for (A \\/ B) /\\ ~A" $ do
            let f1 = Or (Predicate "A" []) (Predicate "B" [])
                f2 = Not (Predicate "A" [])
                res = runTableau defaultTableauConfig [f1, f2]
            trStatus res `shouldBe` OpenTableau
            case trCounterModel res of
                Nothing -> expectationFailure "Expected model for open branch"
                Just m  -> do
                    -- In the open branch, B must be true and A must be false
                    Set.member (Pos "B" []) (modelTrueLits m) `shouldBe` True
                    Set.member (Neg "A" []) (modelFalseLits m) `shouldBe` True

        it "formats readable countermodel representation" $ do
            let f = Predicate "Car" [Constant "c1"]
                res = runTableau defaultTableauConfig [f]
            trStatus res `shouldBe` OpenTableau
            case trCounterModel res of
                Nothing -> expectationFailure "Expected countermodel"
                Just m  -> do
                    let formatted = formatCounterModel m
                    formatted `shouldContain` "Countermodel (Open Saturated Branch):"
                    formatted `shouldContain` "Domain: {c1}"
                    formatted `shouldContain` "Car(c1)"

    describe "First-Order Tableaux Refutations" $ do

        it "proves Socrates syllogism: Man(socrates) /\\ (forall x. Man(x) -> Mortal(x)) |- Mortal(socrates)" $ do
            let premise1 = Predicate "Man" [Constant "socrates"]
                premise2 = ForAll "x" (Implies (Predicate "Man" [Var "x"]) (Predicate "Mortal" [Var "x"]))
                negGoal  = Not (Predicate "Mortal" [Constant "socrates"])
                res = runTableau defaultTableauConfig [premise1, premise2, negGoal]
            trStatus res `shouldBe` ClosedTableau
            case trProof res of
                Nothing -> expectationFailure "Expected proof object"
                Just p  -> do
                    let formatted = formatTableauProof p
                    formatted `shouldContain` "Tableau Refutation Proof"
                    formatted `shouldContain` "closed by:"

        it "refutes contradictory clauses via clausal tableau" $ do
            let c1 = Clause (Set.singleton (Pos "Man" [TConst "socrates"]))
                c2 = Clause (Set.fromList [Neg "Man" [TVar (VarId 1)], Pos "Mortal" [TVar (VarId 1)]])
                c3 = Clause (Set.singleton (Neg "Mortal" [TConst "socrates"]))
                res = runTableauClauses defaultTableauConfig [c1, c2, c3]
            trStatus res `shouldBe` ClosedTableau

        it "refutes equality contradiction: a = b /\\ P(a) /\\ ~P(b)" $ do
            let f1 = Eq (Constant "a") (Constant "b")
                f2 = Predicate "P" [Constant "a"]
                f3 = Not (Predicate "P" [Constant "b"])
                res = runTableau defaultTableauConfig [f1, f2, f3]
            trStatus res `shouldBe` ClosedTableau

        it "closes empty clause contradiction immediately" $ do
            let cEmpty = Clause Set.empty
                res = runTableauClauses defaultTableauConfig [cEmpty]
            trStatus res `shouldBe` ClosedTableau

    describe "First-Order Countermodel Extraction" $ do

        it "extracts countermodel when concept subsumption does not hold (Drone vs Car)" $ do
            -- Drone(d1) /\ ~Car(d1) /\ (forall x. ~Drone(x) \/ Aircraft(x))
            let d1 = TConst "d1"
                c1 = Clause (Set.singleton (Pos "Drone" [d1]))
                c2 = Clause (Set.singleton (Neg "Car" [d1]))
                c3 = Clause (Set.fromList [Neg "Drone" [TVar (VarId 1)], Pos "Aircraft" [TVar (VarId 1)]])
                res = runTableauClauses defaultTableauConfig [c1, c2, c3]
            trStatus res `shouldBe` OpenTableau
            case trCounterModel res of
                Nothing -> expectationFailure "Expected countermodel for non-subsumption"
                Just m  -> do
                    Set.member d1 (modelDomain m) `shouldBe` True
                    Set.member (Pos "Drone" [d1]) (modelTrueLits m) `shouldBe` True
                    Set.member (Pos "Aircraft" [d1]) (modelTrueLits m) `shouldBe` True
                    Set.member (Neg "Car" [d1]) (modelFalseLits m) `shouldBe` True

    describe "High-Level Ontology Reasoning" $ do

        let testReg = emptyRegistry
                { concepts =
                    [ ("Vehicle", Nothing)
                    , ("Aircraft", Just "Vehicle")
                    , ("Drone", Just "Aircraft")
                    , ("Car", Just "Vehicle")
                    ]
                }

        it "proves transitive subsumption (Drone <= Vehicle) via Semantic Tableaux" $ do
            res <- proveSubsumptionTableau defaultTableauConfig testReg "Drone" "Vehicle"
            res `shouldBe` Subsumed

        it "disproves non-subsumption (Drone <= Car) and returns a countermodel" $ do
            res <- proveSubsumptionTableau defaultTableauConfig testReg "Drone" "Car"
            case res of
                NotSubsumed modelStr -> do
                    modelStr `shouldContain` "Countermodel"
                    modelStr `shouldContain` "Drone"
                other -> expectationFailure ("Expected NotSubsumed with countermodel but got: " ++ show other)

        it "returns ProofError when concept is undefined" $ do
            res <- proveSubsumptionTableau defaultTableauConfig testReg "Drone" "Spaceship"
            case res of
                ProofError err -> err `shouldContain` "Unknown concept"
                other -> expectationFailure ("Expected ProofError but got: " ++ show other)

        it "verifies consistency of a valid ontology (Sat)" $ do
            res <- checkConsistencyTableau defaultTableauConfig testReg
            case res of
                Sat modelStr -> modelStr `shouldSatisfy` (\s -> not (null s))
                other -> expectationFailure ("Expected Sat but got: " ++ show other)

        it "detects inconsistency in an ontology asserting contradictory concept axioms (Unsat)" $ do
            let brokenReg = testReg
                    { axioms =
                        [ ForAll "x" (Implies (Predicate "Drone" [Var "x"]) (Predicate "Car" [Var "x"]))
                        , ForAll "x" (Not (And (Predicate "Aircraft" [Var "x"]) (Predicate "Car" [Var "x"])))
                        , Exists "x" (Predicate "Drone" [Var "x"])
                        ]
                    }
            res <- checkConsistencyTableau defaultTableauConfig brokenReg
            res `shouldBe` Unsat

    describe "Search Limits & Timeout Protection" $ do

        it "terminates cleanly with StepLimitExceeded when step budget is 1 on compound formula" $ do
            let cfg = defaultTableauConfig { tcMaxSteps = 1 }
                f1 = Or (Predicate "A" []) (Predicate "B" [])
                f2 = Or (Predicate "C" []) (Predicate "D" [])
                res = runTableau cfg [f1, f2]
            trStatus res `shouldBe` StepLimitExceeded

        it "terminates within timeout budget when tcTimeoutMs is set" $ do
            let cfg = defaultTableauConfig { tcTimeoutMs = Just 50 }
                f1 = Predicate "P" [Constant "a"]
            res <- proveTableau cfg [f1]
            trStatus res `shouldBe` OpenTableau

        it "terminates with DepthLimitExceeded when branch depth exceeds tcMaxDepth" $ do
            let cfg = defaultTableauConfig { tcMaxDepth = 0 }
                f1 = Or (Predicate "A" []) (Predicate "B" [])
                res = runTableau cfg [f1]
            trStatus res `shouldBe` DepthLimitExceeded

        it "proves and refutes clauses directly via proveTableauClauses" $ do
            let cEmpty = Clause Set.empty
            res <- proveTableauClauses defaultTableauConfig [cEmpty]
            trStatus res `shouldBe` ClosedTableau

        it "formats tableau formulas into mathematical strings" $ do
            let f = TFForAll (VarId 1) (TFExists (VarId 2) (TFAnd (TFAtom (Pos "P" [TVar (VarId 1)])) (TFAtom (Neg "Q" [TVar (VarId 2)]))))
                formatted = formatTableauFormula f
            formatted `shouldContain` "forall v1."
            formatted `shouldContain` "exists v2."
            formatted `shouldContain` "/\\"
