module ClifInteropSpec (spec) where

import Test.Hspec
import OntoLogic
import Parser (parseRegistry)
import FOLTheory (buildTheory, theorySkipped)
import Solver (checkConsistencyWith, Prover(..))
import Text.Megaparsec (parse, errorBundlePretty)
import qualified Data.Text.IO as TIO

spec :: Spec
spec = describe "CLIF Interop Conformance Suite (v1.8.0)" $ do
    let fixtureFiles =
            [ "01_equality_and_constants.logic"
            , "02_nary_connectives.logic"
            , "03_conditional_implication.logic"
            , "04_function_terms.logic"
            , "05_comments_and_lexical.logic"
            , "06_extended_identifiers.logic"
            , "07_syllogism.logic"
            , "08_zero_arity_predicates.logic"
            , "09_quantified_coherence.logic"
            , "10_inconsistent_individual.logic"
            ]
        loadFixture name = do
            content <- TIO.readFile ("test/fixtures/clif-interop/" ++ name)
            case parse parseRegistry name content of
                Left err  -> expectationFailure ("Failed to parse " ++ name ++ ": " ++ errorBundlePretty err) >> return emptyRegistry
                Right reg -> return reg

    describe "Fixture Parsing and AST Construction" $ do
        it "parses all 10 CLIF interop fixtures without errors" $ do
            mapM_ (\name -> do
                reg <- loadFixture name
                concepts reg `shouldSatisfy` (not . null)
                ) fixtureFiles

    describe "FOL Theory Generation & Translation Coverage" $ do
        it "translates all axioms across all 10 fixtures with zero skipped axioms" $ do
            mapM_ (\name -> do
                reg <- loadFixture name
                let th = buildTheory reg
                theorySkipped th `shouldBe` []
                ) fixtureFiles

    describe "SMT Consistency & Automated Reasoning via Z3" $ do
        it "verifies consistent fixtures 01 through 09 are Satisfiable (SAT)" $ do
            mapM_ (\name -> do
                reg <- loadFixture name
                res <- checkConsistencyWith Z3 reg
                case res of
                    Sat _ -> return ()
                    other -> expectationFailure (name ++ " expected Sat, got: " ++ show other)
                ) (take 9 fixtureFiles)

        it "detects Unsatisfiability (UNSAT) for inconsistent fixture 10" $ do
            reg10 <- loadFixture "10_inconsistent_individual.logic"
            res <- checkConsistencyWith Z3 reg10
            res `shouldBe` Unsat

    describe "Theorem Proving & Deductive Syllogism" $ do
        it "deduces Socrates is Mortal from fixture 07 by refuting negated conjecture via Z3" $ do
            reg7 <- loadFixture "07_syllogism.logic"
            -- Assert negated conjecture: not (Mortal socrates)
            let negatedGoal = Not (Predicate "Mortal" [Var "socrates"])
                refutationOntology = reg7 { axioms = negatedGoal : axioms reg7 }
            res <- checkConsistencyWith Z3 refutationOntology
            res `shouldBe` Unsat

        it "proves consistency of fixture 01 and 08 via CVC5" $ do
            reg1 <- loadFixture "01_equality_and_constants.logic"
            res1 <- checkConsistencyWith CVC5 reg1
            case res1 of
                Sat _ -> return ()
                other -> expectationFailure ("01 expected Sat via CVC5, got: " ++ show other)
            reg8 <- loadFixture "08_zero_arity_predicates.logic"
            res8 <- checkConsistencyWith CVC5 reg8
            case res8 of
                Sat _ -> return ()
                other -> expectationFailure ("08 expected Sat via CVC5, got: " ++ show other)
