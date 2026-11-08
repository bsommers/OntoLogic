module ResolutionSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import IR.CNF
import Prover.Resolution

spec :: Spec
spec = describe "Native Ordered Resolution Prover Engine" $ do

    describe "Inference Rules" $ do

        it "resolves complementary ground literals into the empty clause" $ do
            let c1 = Clause (Set.singleton (Pos "P" [TConst "a"]))
                c2 = Clause (Set.singleton (Neg "P" [TConst "a"]))
                n1 = DerivationNode (ClauseId 1) c1 InputAxiom
                n2 = DerivationNode (ClauseId 2) c2 InputAxiom
                resolvents = resolveClauses n1 n2
            length resolvents `shouldBe` 1
            let (res, rule) = head resolvents
            isEmptyClause res `shouldBe` True
            rule `shouldBe` ResolveStep (ClauseId 1) (ClauseId 2)

        it "resolves first-order clauses with variable instantiation" $ do
            -- ~P(x) \/ Q(x) resolved with P(a) yields Q(a)
            let c1 = Clause (Set.fromList [Neg "P" [TVar (VarId 1)], Pos "Q" [TVar (VarId 1)]])
                c2 = Clause (Set.singleton (Pos "P" [TConst "a"]))
                n1 = DerivationNode (ClauseId 1) c1 InputAxiom
                n2 = DerivationNode (ClauseId 2) c2 InputAxiom
                resolvents = resolveClauses n1 n2
            length resolvents `shouldBe` 1
            let (res, _) = head resolvents
            getLiterals res `shouldBe` Set.singleton (Pos "Q" [TConst "a"])

        it "resolves multi-literal clauses" $ do
            -- P(x) \/ R(x) resolved with ~P(a) \/ S(b) yields R(a) \/ S(b)
            let c1 = Clause (Set.fromList [Pos "P" [TVar (VarId 1)], Pos "R" [TVar (VarId 1)]])
                c2 = Clause (Set.fromList [Neg "P" [TConst "a"], Pos "S" [TConst "b"]])
                n1 = DerivationNode (ClauseId 1) c1 InputAxiom
                n2 = DerivationNode (ClauseId 2) c2 InputAxiom
                resolvents = resolveClauses n1 n2
            length resolvents `shouldBe` 1
            let (res, _) = head resolvents
            getLiterals res `shouldBe` Set.fromList [Pos "R" [TConst "a"], Pos "S" [TConst "b"]]

        it "prunes resolvents that form tautologies" $ do
            -- P(a) \/ ~Q(b) resolved with ~P(a) \/ Q(b) yields ~Q(b) \/ Q(b) (tautology -> pruned)
            let c1 = Clause (Set.fromList [Pos "P" [TConst "a"], Neg "Q" [TConst "b"]])
                c2 = Clause (Set.fromList [Neg "P" [TConst "a"], Pos "Q" [TConst "b"]])
                n1 = DerivationNode (ClauseId 1) c1 InputAxiom
                n2 = DerivationNode (ClauseId 2) c2 InputAxiom
                resolvents = resolveClauses n1 n2
            resolvents `shouldBe` []

        it "factors literals of identical polarity under unification" $ do
            -- P(x) \/ P(a) factors to P(a)
            let c = Clause (Set.fromList [Pos "P" [TVar (VarId 1)], Pos "P" [TConst "a"]])
                n = DerivationNode (ClauseId 1) c InputAxiom
                factors = factorClause n
            length factors `shouldBe` 1
            let (f, rule) = head factors
            getLiterals f `shouldBe` Set.singleton (Pos "P" [TConst "a"])
            rule `shouldBe` FactorStep (ClauseId 1)

        it "factors multi-argument relations" $ do
            -- R(x, b) \/ R(a, y) factors to R(a, b)
            let c = Clause (Set.fromList
                        [ Pos "R" [TVar (VarId 1), TConst "b"]
                        , Pos "R" [TConst "a", TVar (VarId 2)]
                        ])
                n = DerivationNode (ClauseId 1) c InputAxiom
                factors = factorClause n
            length factors `shouldBe` 1
            let (f, _) = head factors
            getLiterals f `shouldBe` Set.singleton (Pos "R" [TConst "a", TConst "b"])

        it "resolves unifiable negative equality via equality resolution" $ do
            -- x != a \/ Q(x) equality-resolves to Q(a)
            let c = Clause (Set.fromList [NeqT (TVar (VarId 1)) (TConst "a"), Pos "Q" [TVar (VarId 1)]])
                n = DerivationNode (ClauseId 1) c InputAxiom
                resolvents = equalityResolveClause n
            length resolvents `shouldBe` 1
            let (res, rule) = head resolvents
            getLiterals res `shouldBe` Set.singleton (Pos "Q" [TConst "a"])
            rule `shouldBe` EqualityResolveStep (ClauseId 1)

    describe "Given-Clause Saturation Loop & Refutation Proving" $ do

        it "proves Socrates syllogism refutation" $ do
            -- 1. Human(Socrates)
            -- 2. ~Human(x) \/ Mortal(x)
            -- 3. ~Mortal(Socrates)  (negated conjecture)
            let c1 = Clause (Set.singleton (Pos "Human" [TConst "Socrates"]))
                c2 = Clause (Set.fromList [Neg "Human" [TVar (VarId 1)], Pos "Mortal" [TVar (VarId 1)]])
                c3 = Clause (Set.singleton (Neg "Mortal" [TConst "Socrates"]))
                theory = CNFTheory (Set.fromList [c1, c2, c3])
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Proved
            case prProofTrace res of
                Just trace -> do
                    let lastNode = last trace
                    isEmptyClause (dnClause lastNode) `shouldBe` True
                Nothing -> expectationFailure "Expected proof trace, got Nothing"

        it "proves transitivity of concept subsumption A <= B, B <= C |= A <= C" $ do
            -- 1. ~A(x) \/ B(x)
            -- 2. ~B(x) \/ C(x)
            -- 3. A(c)               (from negated conjecture A(c) /\ ~C(c))
            -- 4. ~C(c)
            let c1 = Clause (Set.fromList [Neg "A" [TVar (VarId 1)], Pos "B" [TVar (VarId 1)]])
                c2 = Clause (Set.fromList [Neg "B" [TVar (VarId 1)], Pos "C" [TVar (VarId 1)]])
                c3 = Clause (Set.singleton (Pos "A" [TConst "c"]))
                c4 = Clause (Set.singleton (Neg "C" [TConst "c"]))
                theory = CNFTheory (Set.fromList [c1, c2, c3, c4])

            isRefutable theory `shouldBe` True

        it "proves Barber Paradox refutation requiring factoring" $ do
            -- Barber shaves all and only those who do not shave themselves:
            -- 1. ~Shaves(barber, x) \/ ~Shaves(x, x)
            -- 2.  Shaves(barber, x) \/  Shaves(x, x)
            let c1 = Clause (Set.fromList
                        [ Neg "Shaves" [TConst "barber", TVar (VarId 1)]
                        , Neg "Shaves" [TVar (VarId 1), TVar (VarId 1)]
                        ])
                c2 = Clause (Set.fromList
                        [ Pos "Shaves" [TConst "barber", TVar (VarId 1)]
                        , Pos "Shaves" [TVar (VarId 1), TVar (VarId 1)]
                        ])
                theory = CNFTheory (Set.fromList [c1, c2])

            isRefutable theory `shouldBe` True

        it "saturates and terminates on a consistent, finite theory" $ do
            -- Consistent theory: P(a), Q(b), ~R(c)
            let c1 = Clause (Set.singleton (Pos "P" [TConst "a"]))
                c2 = Clause (Set.singleton (Pos "Q" [TConst "b"]))
                c3 = Clause (Set.singleton (Neg "R" [TConst "c"]))
                theory = CNFTheory (Set.fromList [c1, c2, c3])
                res = runResolution defaultConfig theory

            prStatus res `shouldBe` Saturated
            prProofTrace res `shouldBe` Nothing

        it "terminates cleanly under step limit on infinite generation chains" $ do
            -- P(a) /\ (~P(x) \/ P(f(x))) generates infinite chain P(f^n(a))
            let c1 = Clause (Set.singleton (Pos "P" [TConst "a"]))
                c2 = Clause (Set.fromList
                            [ Neg "P" [TVar (VarId 1)]
                            , Pos "P" [TFunc "f" [TVar (VarId 1)]]
                            ])
                theory = CNFTheory (Set.fromList [c1, c2])
                tightConfig = defaultConfig { cfgMaxSteps = 30 }
                res = runResolution tightConfig theory

            prStatus res `shouldBe` StepLimit

        it "evaluates with timeout protection under proveResolution" $ do
            -- Infinite chain with 1ms timeout
            let c1 = Clause (Set.singleton (Pos "P" [TConst "a"]))
                c2 = Clause (Set.fromList
                            [ Neg "P" [TVar (VarId 1)]
                            , Pos "P" [TFunc "f" [TVar (VarId 1)]]
                            ])
                theory = CNFTheory (Set.fromList [c1, c2])
                timeoutCfg = defaultConfig { cfgMaxSteps = 50000, cfgTimeoutMs = Just 1 }
            res <- proveResolution timeoutCfg theory
            -- Must either time out or stop at limit without hanging
            prStatus res `shouldSatisfy` (`elem` [Timeout, StepLimit])

        it "formats proof trace into human-readable step-by-step output" $ do
            let c1 = Clause (Set.singleton (Pos "A" [TConst "x"]))
                c2 = Clause (Set.singleton (Neg "A" [TConst "x"]))
                n1 = DerivationNode (ClauseId 1) c1 InputAxiom
                n2 = DerivationNode (ClauseId 2) c2 InputAxiom
                n3 = DerivationNode (ClauseId 3) (Clause Set.empty) (ResolveStep (ClauseId 1) (ClauseId 2))
                trace = [n1, n2, n3]
                formatted = formatProofTrace trace

            formatted `shouldContain` "1."
            formatted `shouldContain` "2."
            formatted `shouldContain` "3."
            formatted `shouldContain` "[Input Axiom]"
            formatted `shouldContain` "[Resolution 1, 2]"
            formatted `shouldContain` "[]"

        it "terminates with ClauseLimit when retained clause budget is exceeded" $ do
            let c1 = Clause (Set.singleton (Pos "P" [TConst "a"]))
                c2 = Clause (Set.fromList
                            [ Neg "P" [TVar (VarId 1)]
                            , Pos "P" [TFunc "f" [TVar (VarId 1)]]
                            ])
                theory = CNFTheory (Set.fromList [c1, c2])
                tightConfig = defaultConfig { cfgMaxClauses = 3, cfgMaxSteps = 100 }
                res = runResolution tightConfig theory
            prStatus res `shouldBe` ClauseLimit

        it "computes symbol weight accurately for diverse terms and equality literals" $ do
            let c1 = Clause (Set.fromList
                        [ EqT (TFunc "f" [TConst "a"]) (TSkolem (SkolemId 1) [TVar (VarId 1)])
                        , NeqT (TVar (VarId 2)) (TConst "b")
                        ])
            clauseWeight c1 `shouldSatisfy` (> 0)
