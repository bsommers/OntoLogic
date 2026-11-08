module REPLSpec (spec) where

import Test.Hspec
import REPL
import OntoLogic
import Solver (Prover(..))
import Control.Exception (bracket_)
import System.Timeout (timeout)
import Data.Maybe (isJust)
import System.Environment (lookupEnv, setEnv, unsetEnv)
import Targets (optBaseIri)

spec :: Spec
spec = describe "Interactive REPL Engine" $ do
    it "handles :help command" $ do
        (_, out) <- evalREPLCommand initialREPLState ":help"
        out `shouldContain` "Available REPL Commands:"
        out `shouldContain` ":load"
        out `shouldContain` ":emit"
        out `shouldContain` ":lint"
        out `shouldContain` ":ir"

    it "handles :show on empty state" $ do
        (_, out) <- evalREPLCommand initialREPLState ":show"
        out `shouldContain` "Active Registry State:"
        out `shouldContain` "Concepts:   0"

    it "allows defining concepts and properties interactively" $ do
        (s1, out1) <- evalREPLCommand initialREPLState "(def-concept Robot)"
        out1 `shouldContain` "Added to registry."
        length (concepts (replRegistry s1)) `shouldBe` 1

        (s2, out2) <- evalREPLCommand s1 "(def-property batteryLevel Robot Integer)"
        out2 `shouldContain` "Added to registry."
        length (properties (replRegistry s2)) `shouldBe` 1

        (_, outShow) <- evalREPLCommand s2 ":show"
        outShow `shouldContain` "Robot"
        outShow `shouldContain` "batteryLevel"

    it "runs :lint and :ir on interactive state" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Server)"
        (s2, _) <- evalREPLCommand s1 "(def-property cpu Server Integer)"
        
        (_, lintOut) <- evalREPLCommand s2 ":lint"
        lintOut `shouldContain` "Semantic Linting Passed"

        (_, irOut) <- evalREPLCommand s2 ":ir"
        irOut `shouldContain` "Compiled ModelIR:"
        irOut `shouldContain` "Server"

    it "emits multiple target formats from REPL state" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Node)"
        (s2, _) <- evalREPLCommand s1 "(def-property ip Node String)"

        (_, tsOut) <- evalREPLCommand s2 ":emit ts"
        tsOut `shouldContain` "NodeSchema = z.object({"
        tsOut `shouldContain` "ip: z.string()"

        (_, openapiOut) <- evalREPLCommand s2 ":emit openapi"
        openapiOut `shouldContain` "openapi: 3.1.0"
        openapiOut `shouldContain` "Node:"

        (_, gqlOut) <- evalREPLCommand s2 ":emit graphql"
        gqlOut `shouldContain` "type Node {"
        gqlOut `shouldContain` "ip: String!"

        (_, smtOut) <- evalREPLCommand s2 ":emit smt"
        smtOut `shouldContain` "(declare-const Node Entity)"

    it "loads external ontology file and resets state on :clear" $ do
        (loadedState, loadOut) <- evalREPLCommand initialREPLState ":load examples/smart_factory.logic"
        loadOut `shouldContain` "Loaded examples/smart_factory.logic"
        length (concepts (replRegistry loadedState)) `shouldSatisfy` (> 0)

        (clearedState, clearOut) <- evalREPLCommand loadedState ":clear"
        clearOut `shouldContain` "Session registry cleared."
        length (concepts (replRegistry clearedState)) `shouldBe` 0

    it "runs Z3 solver consistency check (:solve) from REPL" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Device)"
        (s2, _) <- evalREPLCommand s1 "(def-property battery Device Integer)"
        (_, solveOut) <- evalREPLCommand s2 ":solve"
        solveOut `shouldContain` "SMT Satisfiable (SAT)"

    it "runs taxonomic subsumption proof (:prove) from REPL" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Vehicle)"
        (s2, _) <- evalREPLCommand s1 "(def-concept Car Vehicle)"
        (_, proveOut) <- evalREPLCommand s2 ":prove Car Vehicle"
        proveOut `shouldContain` "Theorem Proved"
        proveOut `shouldContain` "Car"
        proveOut `shouldContain` "Vehicle"

    it "runs concept unsatisfiability check (:unsat) from REPL" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept NormalDevice)"
        (_, unsatOut) <- evalREPLCommand s1 ":unsat"
        unsatOut `shouldContain` "All concepts are satisfiable"

    it "inspects and switches SMT prover backends with :prover" $ do
        (_, pOut1) <- evalREPLCommand initialREPLState ":prover"
        pOut1 `shouldContain` "Active SMT Prover: Auto (Z3/CVC5/Vampire/Native)"

        (s2, pOut2) <- evalREPLCommand initialREPLState ":prover cvc5"
        pOut2 `shouldContain` "SMT Prover switched to: CVC5"
        replProver s2 `shouldBe` CVC5

        (s3, pOut3) <- evalREPLCommand s2 ":prover z3"
        pOut3 `shouldContain` "SMT Prover switched to: Z3"
        replProver s3 `shouldBe` Z3

        (s4, pOut4) <- evalREPLCommand s3 ":prover native"
        pOut4 `shouldContain` "SMT Prover switched to: Native"
        replProver s4 `shouldBe` NativeProver

        (_, pOutErr) <- evalREPLCommand s4 ":prover not-a-prover"
        pOutErr `shouldContain` "Unknown prover backend 'not-a-prover'"

    it "displays Clausal Normal Form with :cnf" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Animal) (def-concept Dog Animal)"
        (_, cnfOut) <- evalREPLCommand s1 ":cnf"
        cnfOut `shouldContain` "Clausal Normal Form (CNF) Theory:"
        cnfOut `shouldContain` "Dog"
        cnfOut `shouldContain` "Animal"

    it ":unsat reports an error, not success, when explicit solver is not installed (#16)" $ do
        (s0, _) <- evalREPLCommand initialREPLState ":prover z3"
        (s1, _) <- evalREPLCommand s0 "(def-concept Robot)"
        (_, out) <- withPath "/nonexistent" (evalREPLCommand s1 ":unsat")
        out `shouldContain` "SMT Solver Error"
        out `shouldNotContain` "All concepts are satisfiable"

    it ":unsat seamlessly falls back to native prover when AutoProver has no external solvers" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Robot)"
        (_, out) <- withPath "/nonexistent" (evalREPLCommand s1 ":unsat")
        out `shouldContain` "All concepts are satisfiable"

    it ":emit responds for a registry with an inheritance cycle (#21)" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept A B) (def-concept B A) (def-concept C) (def-property w C Integer)"
        r <- timeout 3000000 (evalREPLCommand s1 ":emit python" >>= \(_, o) -> return $! length o)
        r `shouldSatisfy` isJust

    it "sets the Java package for :emit java (#33)" $ do
      (s1, _) <- evalREPLCommand initialREPLState "(def-concept Robot)"
      (s2, out) <- evalREPLCommand s1 ":set java-package com.acme.models"
      out `shouldContain` "java-package"
      (_, java) <- evalREPLCommand s2 ":emit java"
      java `shouldContain` "package com.acme.models;"

    it "inspects satisfying valuation model with :model" $ do
      (s1, _) <- evalREPLCommand initialREPLState "(def-concept Sensor)"
      (s2, _) <- evalREPLCommand s1 "(def-property reading Sensor Integer)"
      (_, modelOut) <- evalREPLCommand s2 ":model"
      modelOut `shouldContain` "SMT Satisfiable (SAT)"

    it "explains SAT and UNSAT ontologies with :explain" $ do
      (s1, _) <- evalREPLCommand initialREPLState "(def-concept Normal)"
      (_, satExplain) <- evalREPLCommand s1 ":explain"
      satExplain `shouldContain` "SMT Satisfiable (SAT)"

      -- Introduce contradiction: r and not r with existing instances
      (s2, _) <- evalREPLCommand s1 "(def-concept Target)"
      (s3, _) <- evalREPLCommand s2 "(def-relation r Normal Target)"
      (s4, _) <- evalREPLCommand s3 "(forall (x) (forall (y) (implies (and (Normal x) (Target y)) (r x y))))"
      (s5, _) <- evalREPLCommand s4 "(forall (x) (forall (y) (implies (and (Normal x) (Target y)) (not (r x y)))))"
      (s6, _) <- evalREPLCommand s5 "(exists (x) (Normal x))"
      (s7, _) <- evalREPLCommand s6 "(exists (y) (Target y))"
      (_, unsatExplain) <- evalREPLCommand s7 ":explain"
      unsatExplain `shouldContain` "SMT Unsatisfiable (UNSAT)"
      unsatExplain `shouldContain` "Minimal Unsat Core Identified"

    it "handles command aliases and emit error handling" $ do
      (_, helpOut) <- evalREPLCommand initialREPLState ":?"
      helpOut `shouldContain` "Available REPL Commands:"

      (s1, _) <- evalREPLCommand initialREPLState "(def-concept A)"
      (_, checkOut) <- evalREPLCommand s1 ":check"
      checkOut `shouldContain` "SMT Satisfiable (SAT)"

      (_, coreOut) <- evalREPLCommand s1 ":unsat-core"
      coreOut `shouldContain` "SMT Satisfiable (SAT)"

      (_, inspOut) <- evalREPLCommand s1 ":inspect-model"
      inspOut `shouldContain` "SMT Satisfiable (SAT)"

      (_, errEmit) <- evalREPLCommand s1 ":emit nonexistent-target"
      errEmit `shouldContain` "Unknown emit target: nonexistent-target"

      (_, errProve) <- evalREPLCommand s1 ":prove OnlyOneArg"
      errProve `shouldContain` "Usage: :prove <ConceptA> <ConceptB>"

      (_, errLoad) <- evalREPLCommand s1 ":load does_not_exist.logic"
      errLoad `shouldContain` "Error loading does_not_exist.logic"

      (s2, setOut) <- evalREPLCommand s1 ":set base-iri http://ontology.org/test"
      setOut `shouldContain` "base-iri set to http://ontology.org/test"
      optBaseIri (replEmitOptions s2) `shouldBe` Just "http://ontology.org/test"

      (_, setErr) <- evalREPLCommand s1 ":set invalid-key-and-val"
      setErr `shouldContain` "Usage: :set java-package <pkg> | :set base-iri <iri>"

      (_, parseErr) <- evalREPLCommand s1 "(def-concept Invalid (unclosed"
      parseErr `shouldContain` "Parse Error:"

withPath :: String -> IO a -> IO a
withPath p act = do
    old <- lookupEnv "PATH"
    bracket_ (setEnv "PATH" p) (maybe (unsetEnv "PATH") (setEnv "PATH") old) act

