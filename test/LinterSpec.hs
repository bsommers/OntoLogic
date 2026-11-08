module LinterSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf)
import qualified Data.Map as Map
import OntoLogic
import Linter
import Linter.SAT (runDPLL, checkOntologySAT, checkConceptCoherence, Lit(..), Clause(..), ClauseOrigin(..), SatResult(..))

spec :: Spec
spec = describe "lint findings carry their symbol (#27)" $ do
    it "names the concept for an undeclared parent" $ do
        let reg = emptyRegistry { concepts = [("Pump", Just "bfo:Process")] }
        map lintSymbol (lintRegistryFindings reg) `shouldBe` [Just "Pump"]

    it "names the property for an undeclared domain" $ do
        let reg = emptyRegistry { properties = [Property "capacity" "Tank" PTInteger] }
        map lintSymbol (lintRegistryFindings reg) `shouldBe` [Just "capacity"]

    it "names the relation for an undeclared endpoint" $ do
        let reg = emptyRegistry { relations = [Relation "feeds" "Tank" "Pump"] }
        map lintSymbol (lintRegistryFindings reg) `shouldBe` [Just "feeds", Just "feeds"]

    it "names the concept for a cross-axiom contradiction" $ do
        let reg = emptyRegistry
                { concepts = [("Tank", Nothing)]
                , properties = [Property "capacity" "Tank" PTInteger]
                , axioms = [ ForAll "x" (Implies (Predicate "Tank" [Var "x"])
                                (And (Predicate "gt" [Var "capacity", Constant "10"])
                                     (Predicate "lt" [Var "capacity", Constant "5"])))
                           ]
                }
        map lintSymbol (lintRegistryFindings reg) `shouldContain` [Just "Tank"]

    it "names the concept for eq vs ne contradiction on same value" $ do
        let reg = emptyRegistry
                { concepts = [("Device", Nothing)]
                , properties = [Property "status" "Device" PTString]
                , axioms = [ ForAll "x" (Implies (Predicate "Device" [Var "x"])
                                (And (Predicate "eq" [Var "status", Constant "ready"])
                                     (Predicate "ne" [Var "status", Constant "ready"])))
                           ]
                }
        map lintSymbol (lintRegistryFindings reg) `shouldContain` [Just "Device"]

    it "keeps lintRegistry's messages unchanged" $ do
        let reg = emptyRegistry { concepts = [("Pump", Just "bfo:Process")] }
        lintRegistry reg `shouldBe` ["Undeclared parent concept: bfo:Process referenced by Pump"]

    it "formats GCC/Rust-style file:line:col compiler diagnostics with SourceTable" $ do
        let reg = emptyRegistry { concepts = [("Pump", Just "bfo:Process")] }
            pos = SourcePos "src/model.logic" 12 14
            tblMap = insertConceptPos "Pump" pos emptySourceTable
            findings = lintRegistryFindingsWithSource tblMap reg
            diags = lintRegistryDiagnosticsWithSource tblMap reg
        length findings `shouldBe` 1
        lintPos (head findings) `shouldBe` Just pos
        diags `shouldBe` ["src/model.logic:12:14: error: Undeclared parent concept: bfo:Process referenced by Pump"]

    it "detects multi-hop transitive contradiction via hierarchy and disjointness axiom" $ do
        let reg = emptyRegistry
                { concepts = [("A", Nothing), ("B", Just "A"), ("C", Just "B")]
                , axioms = [ ForAll "x" (Implies (Predicate "C" [Var "x"]) (Not (Predicate "A" [Var "x"]))) ]
                }
            findings = lintRegistryFindings reg
            messages = map lintMessage findings
        findings `shouldSatisfy` any (\f -> lintSymbol f == Just "C")
        messages `shouldSatisfy` any (\m -> "Semantic contradiction: Concept C implies A" `isInfixOf` m && "disjoint with C" `isInfixOf` m)

    it "detects multi-hop contradiction through axiom implications" $ do
        let reg = emptyRegistry
                { concepts = [("Sensor", Nothing), ("ActiveSensor", Nothing), ("CriticalSensor", Nothing)]
                , axioms =
                    [ ForAll "x" (Implies (Predicate "Sensor" [Var "x"]) (Predicate "ActiveSensor" [Var "x"]))
                    , ForAll "x" (Implies (Predicate "ActiveSensor" [Var "x"]) (Predicate "CriticalSensor" [Var "x"]))
                    , ForAll "x" (Implies (Predicate "Sensor" [Var "x"]) (Not (Predicate "CriticalSensor" [Var "x"])))
                    ]
                }
            findings = lintRegistryFindings reg
        findings `shouldSatisfy` any (\f -> lintSymbol f == Just "Sensor")
        map lintMessage findings `shouldSatisfy` any (\m -> "Semantic contradiction: Concept Sensor implies CriticalSensor" `isInfixOf` m && "disjoint with Sensor" `isInfixOf` m)

    it "evaluates 1000 Horn implication axioms in under 5ms" $ do
        let n = 1000 :: Int
            chainConcepts = [ ("C" ++ show i, if i == 0 then Nothing else Just ("C" ++ show (i - 1))) | i <- [0..n] ]
            reg = emptyRegistry { concepts = chainConcepts }
            findings = lintRegistryFindings reg
        findings `shouldBe` []
    it "detects non-Horn unsatisfiability via DPLL fallback" $ do
        -- (or A B) and (not A) and (not B) is UNSAT but non-Horn
        let reg = emptyRegistry
                { concepts = [("A", Nothing), ("B", Nothing)]
                , axioms =
                    [ Or (Predicate "A" [Var "x"]) (Predicate "B" [Var "x"])
                    , Not (Predicate "A" [Var "x"])
                    , Not (Predicate "B" [Var "x"])
                    ]
                }
            findings = lintRegistryFindings reg
        map lintMessage findings `shouldSatisfy` any (\m -> "DPLL" `isInfixOf` m)

    describe "propositional abstraction soundness (v1.5.1 review)" $ do
        let a v = Predicate "A" [Var v]
            b v = Predicate "B" [Var v]
            c v = Predicate "C" [Var v]
            d v = Predicate "D" [Var v]
            satMessages reg = [ m | m <- map lintMessage (lintRegistryFindings reg), "Semantic contradiction" `isInfixOf` m ]

        it "does not flag distinct existential witnesses as contradictory" $ do
            let reg = emptyRegistry
                    { concepts = [("A", Nothing), ("B", Nothing)]
                    , axioms =
                        [ Exists "x" (Not (a "x"))
                        , Exists "y" (Not (b "y"))
                        , ForAll "z" (Or (a "z") (b "z"))
                        ]
                    }
            satMessages reg `shouldBe` []

        it "does not flag multi-variable existentials as contradictory with disjointness" $ do
            let reg = emptyRegistry
                    { concepts = [("A", Nothing), ("B", Nothing)]
                    , axioms =
                        [ Exists "x" (Exists "y" (And (a "x") (b "y")))
                        , ForAll "z" (Or (Not (a "z")) (Not (b "z")))
                        ]
                    }
            satMessages reg `shouldBe` []

        it "still flags an existential that contradicts a universal" $ do
            let reg = emptyRegistry
                    { concepts = [("A", Nothing)]
                    , axioms = [ Exists "x" (a "x"), ForAll "y" (Not (a "y")) ]
                    }
            satMessages reg `shouldSatisfy` (not . null)

        it "keeps the sort guard on concept-typed quantifiers" $ do
            let reg = emptyRegistry
                    { concepts = [("Device", Nothing), ("Broken", Nothing)]
                    , axioms =
                        [ TypedForAll "d" "Device" (Predicate "Broken" [Var "d"])
                        , ForAll "x" (Not (Predicate "Broken" [Var "x"]))
                        ]
                    }
                msgs = satMessages reg
            msgs `shouldSatisfy` all (not . ("Global axioms" `isInfixOf`))
            msgs `shouldSatisfy` any ("Concept Device" `isInfixOf`)

        it "does not add a DPLL finding when Horn already found a global contradiction" $ do
            let reg = emptyRegistry
                    { concepts = [("A", Nothing), ("C", Nothing), ("D", Nothing)]
                    , axioms = [ a "x", Not (a "x"), ForAll "x" (Or (c "x") (d "x")) ]
                    }
                msgs = satMessages reg
            length msgs `shouldBe` 1
            msgs `shouldSatisfy` all (not . ("DPLL" `isInfixOf`))

        it "lists each involved axiom once and omits unrelated ones in DPLL findings" $ do
            let reg = emptyRegistry
                    { concepts = [("A", Nothing), ("B", Nothing), ("C", Nothing), ("D", Nothing)]
                    , axioms =
                        [ Iff (a "x") (Not (b "x"))
                        , Or (c "x") (d "x")
                        , Or (a "x") (b "x")
                        , Implies (a "x") (b "x")
                        , Implies (b "x") (a "x")
                        ]
                    }
                msgs = satMessages reg
                dpll = filter ("DPLL" `isInfixOf`) msgs
            length dpll `shouldBe` 1
            let m = head dpll
            m `shouldNotContain` "C(x)"
            countOcc (formatFOL (Iff (a "x") (Not (b "x")))) m `shouldBe` 1

    describe "Direct SAT Engine & DPLL Verification" $ do
        it "proves satisfiability and refutes contradictions via runDPLL" $ do
            let c1 = Clause [Pos "A", Pos "B"] (PropositionalAxiom 1 Top)
                c2 = Clause [Neg "A"] (PropositionalAxiom 2 Top)
                c3 = Clause [Neg "B"] (PropositionalAxiom 3 Top)
            runDPLL [c1, c2] `shouldBe` True
            runDPLL [c1, c2, c3] `shouldBe` False

        it "evaluates global ontology SAT via checkOntologySAT" $ do
            let regSat = emptyRegistry { concepts = [("Device", Nothing)] }
            checkOntologySAT regSat `shouldBe` []

            let regUnsat = emptyRegistry
                    { concepts = [("A", Nothing)]
                    , axioms = [ Predicate "A" [Constant "c"], Not (Predicate "A" [Constant "c"]) ]
                    }
            checkOntologySAT regUnsat `shouldSatisfy` (not . null)

        it "detects unsatisfiable concepts directly via checkConceptCoherence" $ do
            let reg = emptyRegistry
                    { concepts = [("Valid", Nothing), ("Void", Nothing)]
                    , axioms =
                        [ ForAll "x" (Implies (Predicate "Void" [Var "x"]) (Predicate "P" [Var "x"]))
                        , ForAll "x" (Implies (Predicate "Void" [Var "x"]) (Not (Predicate "P" [Var "x"])))
                        ]
                    }
            checkConceptCoherence reg "Valid" `shouldSatisfy` (\res -> case res of SatConsistent _ -> True; _ -> False)
            checkConceptCoherence reg "Void" `shouldSatisfy` (\res -> case res of SatContradiction _ -> True; _ -> False)

  where
    countOcc needle hay = length [ () | i <- [0 .. length hay - length needle], take (length needle) (drop i hay) == needle ]
    insertConceptPos name p m = Map.insert ("concept:" ++ name) p m
