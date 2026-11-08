module IRSpec (spec) where

import Test.Hspec
import OntoLogic
import IR
import System.Timeout (timeout)
import Control.Exception (evaluate)
import Data.Maybe (isJust)

spec :: Spec
spec = do
  describe "Model Intermediate Representation (IR)" $ do
    it "topologically sorts classes so base classes precede derived classes" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Just "Device"), ("Device", Just "Asset"), ("Asset", Nothing)]
                  , axioms = []
                  , properties = []
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          modelIR = compileRegistry reg
          classNames = map compClassName (irClasses modelIR)
      classNames `shouldBe` ["Asset", "Device", "Sensor"]

    it "resolves direct and constrained inherited properties on classes" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = 
                      [ ForAll "d" (Implies (Predicate "Device" [Var "d"]) 
                                     (Predicate "lt" [Var "serial_number", Constant "100"]))
                      ]
                  , properties = 
                      [ Property "serial_number" "Asset" PTInteger
                      , Property "firmware_ver" "Device" PTString
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          modelIR = compileRegistry reg
          classes = irClasses modelIR
          assetClass = head (filter (\c -> compClassName c == "Asset") classes)
          deviceClass = head (filter (\c -> compClassName c == "Device") classes)
      
      map compPropName (compProperties assetClass) `shouldBe` ["serial_number"]
      compIsInherited (head (compProperties assetClass)) `shouldBe` False

      map compPropName (compProperties deviceClass) `shouldBe` ["serial_number", "firmware_ver"]
      let inheritedSerial = head (filter (\p -> compPropName p == "serial_number") (compProperties deviceClass))
      compIsInherited inheritedSerial `shouldBe` True
      compConstraints inheritedSerial `shouldBe` [BoundConstraint OpLt (VInt 100)]

    it "detects and preserves conditional / complex axioms in irUnmappedAxioms" $ do
      let conditionalAxiom = 
            ForAll "s" (Implies (And (Predicate "Sensor" [Var "s"]) (Predicate "is_active" [Var "s"]))
                                (Predicate "gt" [Var "temperature", Constant "50"]))
          simpleAxiom =
            ForAll "s" (Implies (Predicate "Sensor" [Var "s"])
                                (Predicate "lt" [Var "temperature", Constant "100"]))
          reg = emptyRegistry
                  { concepts = [("Sensor", Nothing)]
                  , axioms = [conditionalAxiom, simpleAxiom]
                  , properties = [Property "temperature" "Sensor" PTInteger]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          modelIR = compileRegistry reg
      irUnmappedAxioms modelIR `shouldBe` [conditionalAxiom]

  describe "cyclic inheritance (#21)" $ do
    -- Registry fields: concepts, axioms, properties, relations, imports, namespaces
    let cyclic = emptyRegistry
          { concepts = [("A", Just "B"), ("B", Just "A"), ("C", Nothing)]
          , properties = [Property "w" "C" PTInteger]
          }
    it "getAncestors terminates on a cycle" $
      getAncestors "A" (concepts cyclic) `shouldBe` ["B"]
    it "compileRegistry terminates on a cycle" $ do
      r <- timeout 2000000 (evaluate (length (show (compileRegistry cyclic))))
      r `shouldSatisfy` isJust
