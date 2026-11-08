module CNFSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import OntoLogic
import IR.CNF
import IR.Clausify

shouldHaveSingleClause :: [Clause] -> (Clause -> Expectation) -> Expectation
shouldHaveSingleClause [c] check = check c
shouldHaveSingleClause cs  _     = expectationFailure ("Expected 1 clause, got: " ++ show (length cs))

spec :: Spec
spec = describe "Canonical Clausal Normal Form (CNF) IR & Normalization" $ do

    describe "Step 1: Desugaring & Step 2: NNF" $ do
        it "desugars implication into disjunction with negation (~P \\/ Q)" $ do
            let fol = Implies (Predicate "Human" [Var "x"]) (Predicate "Mortal" [Var "x"])
                clauses = clausify fol
            shouldHaveSingleClause clauses $ \c ->
                getLiterals c `shouldBe` Set.fromList
                    [ Neg "Human" [TVar (VarId 1)]
                    , Pos "Mortal" [TVar (VarId 1)]
                    ]

        it "pushes negation inwards across conjunctions using De Morgan's Law ~(P /\\ Q) ==> ~P \\/ ~Q" $ do
            let fol = Not (And (Predicate "A" [Var "x"]) (Predicate "B" [Var "x"]))
                clauses = clausify fol
            shouldHaveSingleClause clauses $ \c ->
                getLiterals c `shouldBe` Set.fromList
                    [ Neg "A" [TVar (VarId 1)]
                    , Neg "B" [TVar (VarId 1)]
                    ]

        it "pushes negation inwards across disjunctions ~(P \\/ Q) ==> ~P /\\ ~Q" $ do
            let fol = Not (Or (Predicate "A" [Var "x"]) (Predicate "B" [Var "x"]))
                clauses = clausify fol
            length clauses `shouldBe` 2
            let lits = map (Set.toList . getLiterals) clauses
            lits `shouldContain` [[Neg "A" [TVar (VarId 1)]]]
            lits `shouldContain` [[Neg "B" [TVar (VarId 1)]]]

        it "eliminates double negation ~~P ==> P" $ do
            let fol = Not (Not (Predicate "Active" [Var "x"]))
                clauses = clausify fol
            shouldHaveSingleClause clauses $ \c ->
                getLiterals c `shouldBe` Set.singleton (Pos "Active" [TVar (VarId 1)])

        it "dualizes negated universal quantifier ~(forall x. P(x)) ==> exists x. ~P(x) with Skolem constant" $ do
            let fol = Not (ForAll "x" (Predicate "Safe" [Var "x"]))
                clauses = clausify fol
            shouldHaveSingleClause clauses $ \c ->
                getLiterals c `shouldBe` Set.singleton (Neg "Safe" [TSkolem (SkolemId 1) []])

    describe "Step 4: Skolemization" $ do
        it "skolemizes independent existential quantifier into nullary Skolem constant" $ do
            let fol = Exists "e" (Predicate "Event" [Var "e"])
                clauses = clausify fol
            shouldHaveSingleClause clauses $ \c ->
                getLiterals c `shouldBe` Set.singleton (Pos "Event" [TSkolem (SkolemId 1) []])

        it "skolemizes dependent existential under universal scope into a Skolem function" $ do
            let fol = ForAll "d" (Implies (Predicate "Device" [Var "d"])
                                          (Exists "s" (Predicate "has_sensor" [Var "d", Var "s"])))
                clauses = clausify fol
            shouldHaveSingleClause clauses $ \c ->
                getLiterals c `shouldBe` Set.fromList
                    [ Neg "Device" [TVar (VarId 1)]
                    , Pos "has_sensor" [TVar (VarId 1), TSkolem (SkolemId 1) [TVar (VarId 1)]]
                    ]

    describe "Step 6 & 7: Clausal Distribution and Tautology Pruning" $ do
        it "distributes disjunction over conjunction P \\/ (Q /\\ R) into (P \\/ Q) /\\ (P \\/ R)" $ do
            let fol = Or (Predicate "P" []) (And (Predicate "Q" []) (Predicate "R" []))
                clauses = clausify fol
            length clauses `shouldBe` 2
            let litSets = map getLiterals clauses
            litSets `shouldContain` [Set.fromList [Pos "P" [], Pos "Q" []]]
            litSets `shouldContain` [Set.fromList [Pos "P" [], Pos "R" []]]

        it "prunes tautological clauses containing both A and ~A" $ do
            let fol = Or (Predicate "A" []) (Not (Predicate "A" []))
                clauses = clausify fol
            clauses `shouldBe` []

        it "detects and produces empty clause [ ] for Bottom / contradictory literal" $ do
            let fol = Bottom
                clauses = clausify fol
            shouldHaveSingleClause clauses $ \c ->
                isEmptyClause c `shouldBe` True

    describe "Whole Theory Clausification (clausifyTheory)" $ do
        it "clausifies concepts inheritance into Sub(x) -> Super(x) clauses" $ do
            let reg = emptyRegistry
                        { concepts = [("Drone", Just "Aircraft"), ("Aircraft", Just "Vehicle")]
                        , axioms = []
                        , properties = []
                        , relations = []
                        , imports = []
                        , namespaces = []
                        }
                theory = clausifyTheory reg
                cls = getClauses theory
            Set.size cls `shouldBe` 2
            let strClauses = map formatClause (Set.toList cls)
            strClauses `shouldContain` ["~Aircraft(X1) | Vehicle(X1)"]
            strClauses `shouldContain` ["~Drone(X1) | Aircraft(X1)"]

        it "clausifies binary relations into domain and range implication clauses" $ do
            let reg = emptyRegistry
                        { concepts = [("Device", Nothing), ("Location", Nothing)]
                        , axioms = []
                        , properties = []
                        , relations = [Relation "located_in" "Device" "Location"]
                        , imports = []
                        , namespaces = []
                        }
                theory = clausifyTheory reg
                cls = getClauses theory
            Set.size cls `shouldBe` 2
            let strClauses = map formatClause (Set.toList cls)
            strClauses `shouldContain` ["~located_in(X1, X2) | Device(X1)"]
            strClauses `shouldContain` ["~located_in(X1, X2) | Location(X2)"]
