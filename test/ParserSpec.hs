{-# LANGUAGE OverloadedStrings #-}
module ParserSpec (spec) where

import Test.Hspec
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseFOL, parseTerm, parseRegistry, parseRegistryWithSource)
import Control.Monad (forM_)
import qualified Data.Text as T
import Linter (lintRegistry)

spec :: Spec
spec = do
  describe "FOL Parser" $ do
    it "parses constants" $ do
      parse parseTerm "" "\"hello\"" `shouldBe` Right (Constant "hello")

    it "parses numeric literals as strings" $ do
      parse parseTerm "" "123" `shouldBe` Right (Constant "123")
      parse parseTerm "" "45.67" `shouldBe` Right (Constant "45.67")

    it "parses signed negative numbers" $ do
      parse parseTerm "" "-42" `shouldBe` Right (Constant "-42")
      parse parseTerm "" "-15.5" `shouldBe` Right (Constant "-15.5")

    it "parses variables" $ do
      parse parseTerm "" "x" `shouldBe` Right (Var "x")

    it "parses predicates" $ do
      parse parseFOL "" "IsRobot x" `shouldBe` 
        Right (Predicate "IsRobot" [Var "x"])

    it "parses nested logic (AND)" $ do
      parse parseFOL "" "and (A x) (B y)" `shouldBe`
        Right (And (Predicate "A" [Var "x"]) (Predicate "B" [Var "y"]))

    it "parses quantifiers (ForAll)" $ do
      parse parseFOL "" "forall (x) (P x)" `shouldBe`
        Right (ForAll "x" (Predicate "P" [Var "x"]))

    it "parses equality and inequality" $ do
      parse parseFOL "" "(= x y)" `shouldBe` Right (Eq (Var "x") (Var "y"))
      parse parseFOL "" "(!= x y)" `shouldBe` Right (Not (Eq (Var "x") (Var "y")))

    it "parses truth constants top and bottom" $ do
      parse parseFOL "" "top" `shouldBe` Right Top
      parse parseFOL "" "true" `shouldBe` Right Top
      parse parseFOL "" "bottom" `shouldBe` Right Bottom
      parse parseFOL "" "false" `shouldBe` Right Bottom

    it "parses typed quantifiers" $ do
      parse parseFOL "" "forall ((x Device)) (P x)" `shouldBe`
        Right (TypedForAll "x" "Device" (Predicate "P" [Var "x"]))
      parse parseFOL "" "exists ((x Device)) (P x)" `shouldBe`
        Right (TypedExists "x" "Device" (Predicate "P" [Var "x"]))

    it "parses function application terms" $ do
      parse parseFOL "" "(= (parentOf x) y)" `shouldBe`
        Right (Eq (Apply "parentOf" [Var "x"]) (Var "y"))

    it "parses nested function application equality" $ do
      parse parseFOL "" "(= (f (g x)) y)" `shouldBe`
        Right (Eq (Apply "f" [Apply "g" [Var "x"]]) (Var "y"))

    it "ignores C-style and Lisp-style block comments and line comments" $ do
      let input = "/* C block */ // C line\n; Lisp line\n#| Scheme block |# (def-concept Robot)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> concepts reg `shouldContain` [("Robot", Nothing)]

    it "parses identifiers with arithmetic and punctuation symbols" $ do
      parse parseTerm "" "+" `shouldBe` Right (Var "+")
      parse parseTerm "" "a.b/c*d" `shouldBe` Right (Var "a.b/c*d")
      parse parseFOL "" "(+ x 1)" `shouldBe` Right (Predicate "+" [Var "x", Constant "1"])

    it "prevents keyword prefix matching on extended identifiers" $ do
      parse parseFOL "" "(android x)" `shouldBe` Right (Predicate "android" [Var "x"])
      parse parseFOL "" "(if-then x)" `shouldBe` Right (Predicate "if-then" [Var "x"])
      parse parseFOL "" "(forall-devices x)" `shouldBe` Right (Predicate "forall-devices" [Var "x"])

  describe "Registry Parser" $ do
    it "parses a multi-arity relation (n >= 3)" $ do
      let input = "(def-relation occupies Agent Region Time)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> do
          let rel = head (relations reg)
          relName rel `shouldBe` "occupies"
          relSignature rel `shouldBe` ["Agent", "Region", "Time"]
    it "parses a simple concept" $ do
      let input = "(def-concept Robot)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> concepts reg `shouldContain` [("Robot", Nothing)]

    it "parses a concept with parent" $ do
      let input = "(def-concept Robot Machine)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> concepts reg `shouldContain` [("Robot", Just "Machine")]

    it "parses a declared individual without concept" $ do
      let input = "(def-individual zero)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> individuals reg `shouldContain` [("zero", Nothing)]

    it "parses a declared individual with concept" $ do
      let input = "(def-individual zero Number)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> individuals reg `shouldContain` [("zero", Just "Number")]
    
    it "parses a property" $ do
      let input = "(def-property is_active Machine Boolean)"
      case parse parseRegistry "" input of
        Left err -> expectationFailure (errorBundlePretty err)
        Right reg -> do
            let prop = head (properties reg)
            propName prop `shouldBe` "is_active"
            domain prop `shouldBe` "Machine"
            rangeType prop `shouldBe` PTBoolean

    it "detects circular inheritance cycles" $ do
      let cyclicReg = emptyRegistry { concepts = [("A", Just "B"), ("B", Just "A")] }
      lintRegistry cyclicReg `shouldContain` ["Circular inheritance: [\"A\",\"B\",\"A\"]"]

    it "extracts local constraints for a concept" $ do
      let axiomsList =
            [ ForAll "r" (Implies (Predicate "Refrigerator" [Var "r"]) 
                           (And (Predicate "gt" [Var "temperature", Constant "0"]) 
                                (Predicate "lt" [Var "temperature", Constant "5"])))
            ]
      getLocalConstraints "Refrigerator" axiomsList `shouldBe` [("temperature", "gt", "0"), ("temperature", "lt", "5")]

  describe "Linter validations" $ do
    it "detects propositional contradictions (P and Not P)" $ do
      let p = Predicate "IsActive" [Var "x"]
          contradictoryReg = emptyRegistry { axioms = [And p (Not p)] }
      lintRegistry contradictoryReg `shouldContain` ["Axiom contradiction: Predicate \"IsActive\" [Var \"x\"] and its negation both exist."]

    it "detects range contradictions (gt x 50 and lt x 0)" $ do
      let axiom = And (Predicate "gt" [Var "temp", Constant "50"]) (Predicate "lt" [Var "temp", Constant "0"])
          contradictoryReg = emptyRegistry { axioms = [axiom] }
      lintRegistry contradictoryReg `shouldContain` ["Property contradiction on temp: gt 50 and lt 0"]

    it "detects undeclared parent concepts" $ do
      let reg = emptyRegistry { concepts = [("Sensor", Just "NonExistentParent")] }
      lintRegistry reg `shouldContain` ["Undeclared parent concept: NonExistentParent referenced by Sensor"]

    it "detects undeclared property domain concepts" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Nothing)]
                  , properties = [Property "temp" "UnknownConcept" PTInteger]
                  }
      lintRegistry reg `shouldContain` ["Undeclared domain concept: UnknownConcept in property temp"]

    it "detects duplicate concept definitions" $ do
      let reg = emptyRegistry { concepts = [("Asset", Nothing), ("Asset", Nothing)] }
      lintRegistry reg `shouldContain` ["Duplicate concept definition: Asset"]

    it "detects duplicate property definitions on the same concept" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing)]
                  , properties =
                      [ Property "serial" "Asset" PTString
                      , Property "serial" "Asset" PTInteger
                      ]
                  }
      lintRegistry reg `shouldContain` ["Duplicate property definition: serial on concept Asset"]

    it "detects contradictions across multiple separate axioms on the same concept" $ do
      let axiomsList =
            [ ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "temp", Constant "100"]))
            , ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "lt" [Var "temp", Constant "50"]))
            ]
          reg = emptyRegistry
                  { concepts = [("Sensor", Nothing)]
                  , axioms = axiomsList
                  , properties = [Property "temp" "Sensor" PTInteger]
                  }
      lintRegistry reg `shouldContain` ["Cross-axiom contradiction on Sensor.temp: gt 100 and lt 50"]

    it "allows non-contradictory separate axioms on the same concept" $ do
      let axiomsList =
            [ ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "temp", Constant "0"]))
            , ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "lt" [Var "temp", Constant "100"]))
            ]
          reg = emptyRegistry
                  { concepts = [("Sensor", Nothing)]
                  , axioms = axiomsList
                  , properties = [Property "temp" "Sensor" PTInteger]
                  }
      lintRegistry reg `shouldBe` []

    it "does not falsely report cross-axiom contradictions across different concepts" $ do
      let axiomsList =
            [ ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "temp", Constant "100"]))
            , ForAll "a" (Implies (Predicate "Actuator" [Var "a"]) (Predicate "lt" [Var "temp", Constant "50"]))
            ]
          reg = emptyRegistry
                  { concepts = [("Sensor", Nothing), ("Actuator", Nothing)]
                  , axioms = axiomsList
                  , properties =
                      [ Property "temp" "Sensor" PTInteger
                      , Property "temp" "Actuator" PTInteger
                      ]
                  }
      lintRegistry reg `shouldBe` []

  describe "keyword boundaries (#20)" $
    forM_ ["orderedBy", "origin", "notifies", "android", "iffy", "impliesX", "forallX", "existsIn"] $ \name ->
      it ("parses a predicate named " ++ name) $ do
        let src = T.pack ("(forall (x) (implies (Order x) (" ++ name ++ " x x)))")
        case parse parseRegistry "t" src of
          Left err -> expectationFailure (errorBundlePretty err)
          Right reg -> axioms reg `shouldBe`
            [ForAll "x" (Implies (Predicate "Order" [Var "x"]) (Predicate name [Var "x", Var "x"]))]

  describe "malformed definitions (#23)" $ do
    let bad = [ ("(def-concpt Typo)", "def-concpt")
              , ("(def-property capacity Tank)", "def-property")
              , ("(def-relation ownedBy Tank)", "def-relation")
              ]
    forM_ bad $ \(src, needle) ->
      it ("rejects " ++ src) $
        case parse parseRegistry "t" (T.pack ("(def-concept Tank)\n" ++ src)) of
          Left err -> errorBundlePretty err `shouldContain` "2:"
          Right reg -> expectationFailure ("parsed as " ++ show (axioms reg) ++ " (" ++ needle ++ ")")
    it "still parses a valid axiom" $
      parse parseRegistry "t" (T.pack "(forall (x) (implies (Tank x) (gt capacity 1)))") `shouldSatisfy` either (const False) (const True)

  describe "AST Source Positions (Option 3)" $ do
    it "records precise 1-based source coordinates in SourceTable" $ do
      let src = T.pack $ unlines
            [ "(namespace test \"http://example.com/test#\")"
            , "(def-concept Device)"
            , "(def-property ip Device String)"
            , "(def-relation links Device Device)"
            ]
      case parse parseRegistryWithSource "test.logic" src of
        Left err -> expectationFailure (errorBundlePretty err)
        Right (_, tbl) -> do
          lookupSourceTable tbl "Device" `shouldBe` Just (SourcePos "test.logic" 2 14)
          lookupSourceTable tbl "ip" `shouldBe` Just (SourcePos "test.logic" 3 15)
          lookupSourceTable tbl "links" `shouldBe` Just (SourcePos "test.logic" 4 15)
          lookupSourceTable tbl "test" `shouldBe` Just (SourcePos "test.logic" 1 12)

  describe "CLIF Interop Parser Sugar (v1.8.0 Phase 1)" $ do
    it "desugars n-ary conjunction to right-nested binary And" $ do
      parse parseFOL "" "and (A x) (B y) (C z)" `shouldBe`
        Right (And (Predicate "A" [Var "x"]) (And (Predicate "B" [Var "y"]) (Predicate "C" [Var "z"])))

    it "desugars unary conjunction to its inner formula" $ do
      parse parseFOL "" "and (A x)" `shouldBe`
        Right (Predicate "A" [Var "x"])

    it "desugars empty conjunction to Top" $ do
      parse parseFOL "" "and" `shouldBe` Right Top

    it "desugars n-ary disjunction to right-nested binary Or" $ do
      parse parseFOL "" "or (A x) (B y) (C z)" `shouldBe`
        Right (Or (Predicate "A" [Var "x"]) (Or (Predicate "B" [Var "y"]) (Predicate "C" [Var "z"])))

    it "desugars unary disjunction to its inner formula" $ do
      parse parseFOL "" "or (A x)" `shouldBe`
        Right (Predicate "A" [Var "x"])

    it "desugars empty disjunction to Bottom" $ do
      parse parseFOL "" "or" `shouldBe` Right Bottom

    it "parses if as an alias for implies" $ do
      parse parseFOL "" "if (P x) (Q x)" `shouldBe`
        Right (Implies (Predicate "P" [Var "x"]) (Predicate "Q" [Var "x"]))

    it "rejects if as a predicate name" $ do
      parse parseFOL "" "(if x)" `shouldSatisfy` either (const True) (const False)

    it "parses zero-arity function application terms (f)" $ do
      parse parseFOL "" "(= (origin) x)" `shouldBe`
        Right (Eq (Apply "origin" []) (Var "x"))

    it "still parses negated parenthesized atom (not (p))" $ do
      parse parseFOL "" "(not (P x))" `shouldBe`
        Right (Not (Predicate "P" [Var "x"]))
