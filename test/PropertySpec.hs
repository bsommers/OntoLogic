{-# LANGUAGE ScopedTypeVariables #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module PropertySpec (spec) where

import Test.Hspec
import Test.QuickCheck
import OntoLogic
import IR (compileRegistry, irClasses, compClassName)
import Linter (evalPairContradiction)
import Data.List (elemIndex)

-- Arbitrary instances for property-based generation
instance Arbitrary PropertyType where
  arbitrary = elements [PTInteger, PTFloat, PTDouble, PTBoolean, PTString]

instance Arbitrary CompOp where
  arbitrary = elements [OpEq, OpNe, OpGt, OpGte, OpLt, OpLte]

spec :: Spec
spec = do
  describe "QuickCheck Property-Based Tests" $ do
    it "roundtrips standard PropertyType through String conversion" $ property $
      \pt -> parsePropertyType (propertyTypeToString pt) == pt

    it "roundtrips CompOp through String conversion" $ property $
      \op -> parseCompOp (compOpToString op) == Just op

    it "roundtrips Integer values through parseValue and valueToString" $ property $
      \n -> parseValue (show (n :: Integer)) == VInt n && valueToString (VInt n) == show n

    it "evalPairContradiction correctly flags (gt v1) and (lt v2) when v1 >= v2" $ property $
      \(v1 :: Double) (v2 :: Double) ->
        let expected = v1 >= v2
        in evalPairContradiction ("gt", show v1) ("lt", show v2) == expected

    it "evalPairContradiction correctly flags (gte v1) and (lte v2) when v1 > v2" $ property $
      \(v1 :: Double) (v2 :: Double) ->
        let expected = v1 > v2
        in evalPairContradiction ("gte", show v1) ("lte", show v2) == expected

    it "evalPairContradiction correctly flags (eq v1) and (eq v2) when v1 /= v2" $ property $
      \(v1 :: Double) (v2 :: Double) ->
        let expected = v1 /= v2
        in evalPairContradiction ("eq", show v1) ("eq", show v2) == expected

    it "guarantees base classes precede subclasses in compiled ModelIR" $ do
      -- Test linear chain of 5 inherited concepts
      let reg = emptyRegistry
                  { concepts = [("E", Just "D"), ("D", Just "C"), ("C", Just "B"), ("B", Just "A"), ("A", Nothing)]
                  , axioms = []
                  , properties = []
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          modelIR = compileRegistry reg
          compiledClasses = irClasses modelIR
          names = map compClassName compiledClasses
      
      let posOf n = elemIndex n names
      posOf "A" < posOf "B" `shouldBe` True
      posOf "B" < posOf "C" `shouldBe` True
      posOf "C" < posOf "D" `shouldBe` True
      posOf "D" < posOf "E" `shouldBe` True
