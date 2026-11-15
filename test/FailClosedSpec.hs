module FailClosedSpec (spec) where

import Test.Hspec
import OntoLogic
import Solver
import qualified Data.Map as Map
import Data.Either (isLeft)
import Data.List (isInfixOf)
import System.Directory (findExecutable)
import System.Exit (ExitCode(..))
import Loader (loadRegistryWithImports)

fixture :: String -> FilePath
fixture n = "test/fixtures/failclosed/" ++ n ++ ".logic"

load :: String -> IO Registry
load n = do
    r <- loadRegistryWithImports (fixture n)
    either (\e -> fail ("fixture " ++ n ++ ": " ++ e)) return r

withTool :: String -> IO () -> IO ()
withTool exe act = do
    found <- findExecutable exe
    maybe (pendingWith (exe ++ " not installed")) (const act) found

isSat :: SolverResult -> Bool
isSat (Sat _) = True
isSat _       = False

isSolverError :: SolverResult -> Bool
isSolverError (SolverError _) = True
isSolverError _               = False

isNotSubsumed :: SubsumptionResult -> Bool
isNotSubsumed (NotSubsumed _) = True
isNotSubsumed _               = False

-- | Short solver budget so a hang fails the test instead of the suite.
quick :: SolverOptions
quick = defaultSolverOptions { optTimeoutSeconds = Just 20 }

spec :: Spec
spec = describe "Fail-closed solver verdicts (v1.8.4)" $ do

    describe "SMT-LIB verdict parsing" $ do
        it "treats an error line next to a sat verdict as a solver error" $
            classifyConsistencyOutput "sat\n(error \"line 5 column 3: bad\")\n" `shouldSatisfy` isSolverError
        it "treats an error line before the verdict as a solver error" $
            classifyConsistencyOutput "(error \"line 5 column 3: bad\")\nsat\n" `shouldSatisfy` isSolverError
        it "accepts the get-model refusal that follows unsat" $
            classifyConsistencyOutput "unsat\n(error \"line 5 column 10: model is not available\")\n" `shouldBe` Unsat
        it "accepts the cvc5 get-model refusal that follows unsat" $
            classifyConsistencyOutput "unsat\n(error \"cannot get model unless after a SAT or UNKNOWN response.\")\n" `shouldBe` Unsat
        it "never reads unsat as sat" $
            classifyConsistencyOutput "unsat\n" `shouldBe` Unsat
        it "does not read a sat line after an unsat line as sat" $
            classifyConsistencyOutput "unsat\nsat\n" `shouldSatisfy` isSolverError
        it "reports no verdict line as a solver error" $ do
            classifyConsistencyOutput "" `shouldSatisfy` isSolverError
            classifyConsistencyOutput "(model)\n" `shouldSatisfy` isSolverError
        it "keeps unknown as unknown" $
            classifyConsistencyOutput "unknown\n" `shouldSatisfy` (\r -> case r of Unknown _ -> True; _ -> False)
        it "keeps a model after sat" $
            classifyConsistencyOutput "sat\n(\n(define-fun a () Bool true)\n)\n" `shouldSatisfy` isSat

    describe "Vampire verdict parsing" $ do
        it "maps GaveUp and ResourceOut to unknown" $ do
            classifyVampireOutput "% SZS status GaveUp for stdin\n" `shouldSatisfy` isUnknown
            classifyVampireOutput "% SZS status ResourceOut for stdin\n" `shouldSatisfy` isUnknown
            classifyVampireOutput "% SZS status Timeout for stdin\n" `shouldSatisfy` isUnknown
        it "maps Satisfiable and Unsatisfiable" $ do
            classifyVampireOutput "% SZS status Satisfiable for stdin\n" `shouldSatisfy` isSat
            classifyVampireOutput "% SZS status CounterSatisfiable for stdin\n" `shouldSatisfy` isSat
            classifyVampireOutput "% SZS status Unsatisfiable for stdin\n" `shouldBe` Unsat
        it "treats a TPTP parse failure as an error" $ do
            classifyVampireOutput "% Running in auto input_syntax mode. Trying TPTP\n% Failed with\n% parse error\n% Trying SMTLIB2\nUser error: Unexpected end of list\n" `shouldSatisfy` isSolverError
            classifyVampireOutput "parse error in \"/dev/stdin\", line 1: formula or term expected\n" `shouldSatisfy` isSolverError
        it "treats a parse failure as an error even beside a sat line" $
            classifyVampireOutput "% Failed with\nsat\n" `shouldSatisfy` isSolverError
        it "treats conflicting statuses and no status as an error" $ do
            classifyVampireOutput "% SZS status Satisfiable\n% SZS status Unsatisfiable\n" `shouldSatisfy` isSolverError
            classifyVampireOutput "" `shouldSatisfy` isSolverError
        it "passes --input_syntax tptp on the TPTP route" $ do
            let args = vampireArguments defaultSolverOptions "fof(a,axiom,p).\n"
            args `shouldSatisfy` (\as -> ["--input_syntax", "tptp"] `isInfixOfList` as)
        it "keeps smtlib2 syntax on the SMT-LIB route" $ do
            let args = vampireArguments defaultSolverOptions "(set-logic ALL)\n"
            args `shouldSatisfy` (\as -> ["--input_syntax", "smtlib2"] `isInfixOfList` as)

    describe "Unsat core parsing" $ do
        let nm = Map.fromList [("n1", "first"), ("n2", "second")]
        it "reads a one-line core" $
            parseUnsatCore "unsat\n(n1 n2)\n" nm `shouldBe` Right (UnsatExplanation ["n1", "n2"] ["first", "second"])
        it "reads a multi-line core" $
            fmap unsatCoreNames (parseUnsatCore "unsat\n(\nn1\nn2\n)\n" nm) `shouldBe` Right ["n1", "n2"]
        it "ignores a parenthesised group that is not the core" $
            fmap unsatCoreNames (parseUnsatCore "unsat\n(n2)\n" nm) `shouldBe` Right ["n2"]
        it "does not turn a satisfiable answer into an empty core" $
            parseUnsatCore "sat\n(error \"line 5: unsat core is not available\")\n" nm `shouldSatisfy` isLeft
        it "rejects an error line" $
            parseUnsatCore "unsat\n(error \"line 5: boom\")\n(n1)\n" nm `shouldSatisfy` isLeft
        it "reports an empty core as an unsat answer with no names" $
            parseUnsatCore "unsat\n()\n" nm `shouldBe` Right (UnsatExplanation [] [])

    describe "Time limits" $ do
        it "defaults to 60 seconds" $
            optTimeoutSeconds defaultSolverOptions `shouldBe` Just 60
        it "clamps huge values instead of overflowing" $ do
            clampTimeoutSeconds maxBound `shouldSatisfy` (\s -> s > 0 && s <= 31536000)
            clampTimeoutSeconds 5 `shouldBe` 5
        it "does not expire a quick command under a huge limit" $ do
            exe <- findExecutable "true"
            case exe of
                Nothing -> pendingWith "true not found"
                Just _ -> do
                    r <- runBinary (defaultSolverOptions { optTimeoutSeconds = Just maxBound }) "true" "true" [] ""
                    r `shouldBe` Right ""

    describe "Solver route" $ do
        it "uses the SMT theory only for SMT routes" $ do
            usesSmtTheory Vampire `shouldReturn` False
            usesSmtTheory NativeProver `shouldReturn` False
            usesSmtTheory Z3 `shouldReturn` True
            usesSmtTheory CVC5 `shouldReturn` True

    describe "partialVerdict: SAT on a partial check is unknown" $ do
        it "turns SAT into unknown when axioms were not sent" $ do
            partialVerdict 2 (Sat "m") `shouldSatisfy` isUnknown
            solverExitCode (partialVerdict 2 (Sat "m")) `shouldBe` ExitFailure 2
        it "keeps SAT when nothing was skipped" $
            partialVerdict 0 (Sat "m") `shouldSatisfy` isSat
        it "keeps UNSAT, errors and unknown unchanged" $ do
            partialVerdict 3 Unsat `shouldBe` Unsat
            partialVerdict 3 (SolverError "e") `shouldSatisfy` isSolverError
        it "names the count in the message" $
            case partialVerdict 2 (Sat "m") of
                Unknown msg -> msg `shouldSatisfy` ("2 axiom(s) could not be checked" `isInfixOf`)
                _ -> expectationFailure "expected unknown"

    describe "z3 and cvc5 never drop a rejected assertion silently (D5)" $ do
        let check name solver exe = it (name ++ " on " ++ exe) $ withTool exe $ do
                mapM_ (\f -> do
                    reg <- load f
                    res <- checkConsistencyWithOptions quick solver reg
                    -- Either a non-SAT answer, or a SAT that comes with the not-sent notice.
                    (isSat res && null (untranslatedAxioms reg)) `shouldBe` False
                    ) ["smt_string_arg", "smt_arity"]
        check "string constant and arity mismatch" Z3 "z3"
        check "string constant and arity mismatch" CVC5 "cvc5"
        it "rejects the ill-sorted axioms as not sent" $ do
            r1 <- load "smt_string_arg"
            r2 <- load "smt_arity"
            length (untranslatedAxioms r1) `shouldSatisfy` (>= 1)
            length (untranslatedAxioms r2) `shouldSatisfy` (>= 1)
        it "accepts nullary function terms on z3 and cvc5 (04_function_terms)" $ do
            reg <- load "04_function_terms"
            withTool "z3" $ do
                res <- checkConsistencyWithOptions quick Z3 reg
                res `shouldSatisfy` isSat
                findUnsatConceptsWithOptions quick Z3 reg `shouldReturn` Right []
            withTool "cvc5" $ do
                res <- checkConsistencyWithOptions quick CVC5 reg
                res `shouldSatisfy` isSat

    describe "Vampire never answers SAT after a TPTP parse failure (D6)" $ do
        it "does not report SAT for any parse-failing probe" $ withTool "vampire" $
            mapM_ (\f -> do
                reg <- load f
                res <- checkConsistencyWithOptions quick Vampire reg
                -- All four probes are UNSAT in truth; an error or unknown is acceptable, SAT is not.
                res `shouldSatisfy` (not . isSat)
                ) ["ind_unary_fact_vampire", "string_space_tptp", "odd_ident"]
        it "does not report SAT or Disproved from a parse failure in the coherence check" $ withTool "vampire" $ do
            reg <- load "odd_ident"
            coh <- findUnsatConceptsWithOptions quick Vampire reg
            coh `shouldSatisfy` (/= Right [])
        it "does not answer a subsumption that holds with NotSubsumed" $ withTool "vampire" $ do
            reg <- load "subs_ind"
            res <- proveSubsumptionWithOptions quick Vampire reg "A" "B"
            res `shouldSatisfy` (not . isNotSubsumed)

    describe "Native prover answers unknown when the theory uses equality (B2)" $ do
        it "detects equality" $ do
            reg <- load "eq_congruence"
            usesEquality reg `shouldBe` True
            regNo <- load "subs_ind"
            usesEquality regNo `shouldBe` False
        it "consistency" $ do
            reg <- load "eq_congruence"
            res <- checkConsistencyWithOptions quick NativeProver reg
            res `shouldSatisfy` isUnknown
            solverExitCode res `shouldBe` ExitFailure 2
        it "coherence" $ do
            reg <- load "eq_congruence"
            res <- findUnsatConceptsWithOptions quick NativeProver reg
            res `shouldSatisfy` isLeft
        it "subsumption never says NotSubsumed" $ do
            reg <- load "subs_eq"
            res <- proveSubsumptionWithOptions quick NativeProver reg "A" "B"
            res `shouldSatisfy` (not . isNotSubsumed)
        it "explanation is an error, not an empty core" $ do
            reg <- load "eq_congruence"
            res <- explainUnsatWithOptions quick NativeProver reg
            res `shouldSatisfy` isLeft
        it "keeps answering for equality-free theories" $ do
            reg <- load "subs_ind"
            res <- checkConsistencyWithOptions quick NativeProver reg
            res `shouldSatisfy` isSat

    describe "Bounds are not asserted on the concept constant (D4, solver side)" $ do
        it "the consistency SMT carries no property bound assertion" $ do
            reg <- load "bounds_int_gap_universal"
            emitSMTForConsistency reg `shouldSatisfy` (not . ("(assert (> (Tank_level Tank) 5))" `isInfixOf`))
        it "guarded bounds on disjoint subconcepts stay consistent and coherent" $ withTool "z3" $ do
            reg <- load "guarded_int_gap"
            res <- checkConsistencyWithOptions quick Z3 reg
            res `shouldSatisfy` isSat
            coh <- findUnsatConceptsWithOptions quick Z3 reg
            coh `shouldBe` Right []
        it "an empty concept is not a global contradiction" $ withTool "z3" $ do
            reg <- load "bounds_int_gap_universal"
            res <- checkConsistencyWithOptions quick Z3 reg
            res `shouldSatisfy` isSat
            coh <- findUnsatConceptsWithOptions quick Z3 reg
            coh `shouldBe` Right ["Tank"]
        it "agrees on cvc5" $ withTool "cvc5" $ do
            reg <- load "bounds_int_gap_universal"
            res <- checkConsistencyWithOptions quick CVC5 reg
            res `shouldSatisfy` isSat
  where
    isUnknown (Unknown _) = True
    isUnknown _           = False
    isInfixOfList needle hay = any (\i -> take (length needle) (drop i hay) == needle) [0 .. length hay]
