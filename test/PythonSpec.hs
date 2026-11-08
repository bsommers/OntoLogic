module PythonSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf)
import OntoLogic
import Emitters.Python (emitPython)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

spec :: Spec
spec = do
  -- The exact-match expectations below changed with #25. The old strings encoded two
  -- bugs: `from typing import Optional, List` was never used, and without deferred
  -- annotations a property whose type is a class declared later in the file raised
  -- NameError on import (Python < 3.14; PEP 649 masks it on 3.14+). The emitter now
  -- writes `from __future__ import annotations` and a model_rebuild() call per class.
  describe "Python Emitter" $ do
    it "generates Pydantic classes with fields" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = []
                  , properties = 
                      [ Property "serial_number" "Asset" PTString
                      , Property "firmware_ver" "Device" PTString
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitPython reg
      content `shouldBe` 
        "from __future__ import annotations\n\n\
        \from pydantic import BaseModel, Field\n\n\
        \class Asset(BaseModel):\n\
        \    serial_number: str\n\n\
        \class Device(Asset):\n\
        \    firmware_ver: str\n\n\
        \Asset.model_rebuild()\n\
        \Device.model_rebuild()\n"

    it "generates Pydantic Field range arguments based on axioms" $ do
      let reg = emptyRegistry
                  { concepts = [("Refrigerator", Nothing)]
                  , axioms = 
                      [ ForAll "r" (Implies (Predicate "Refrigerator" [Var "r"]) (And (Predicate "gt" [Var "temperature", Constant "0"]) (Predicate "lt" [Var "temperature", Constant "5"])))
                      ]
                  , properties = 
                      [ Property "temperature" "Refrigerator" PTInteger
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitPython reg
      content `shouldBe` 
        "from __future__ import annotations\n\n\
        \from pydantic import BaseModel, Field\n\n\
        \class Refrigerator(BaseModel):\n\
        \    temperature: int = Field(gt=0, lt=5)\n\n\
        \Refrigerator.model_rebuild()\n"

    it "ignores range arguments for non-Integer properties and non-numeric bounds" $ do
      let reg = emptyRegistry
                  { concepts = [("Robot", Nothing)]
                  , axioms = 
                      [ ForAll "r" (Implies (Predicate "Robot" [Var "r"])
                                     (And (Predicate "gt" [Var "active_level", Constant "5"])
                                     (And (Predicate "lt" [Var "name", Constant "100"])
                                          (Predicate "gt" [Var "active_level", Constant "abc"]))))
                      ]
                  , properties = 
                      [ Property "active_level" "Robot" PTInteger
                      , Property "name" "Robot" PTString
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitPython reg
      content `shouldBe` 
        "from __future__ import annotations\n\n\
        \from pydantic import BaseModel, Field\n\n\
        \class Robot(BaseModel):\n\
        \    active_level: int = Field(gt=5)\n\
        \    name: str\n\n\
        \Robot.model_rebuild()\n"

    it "emits a warning comment if subclass adds constraints to inherited property in Python Emitter" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = 
                      [ ForAll "d" (Implies (Predicate "Device" [Var "d"]) (Predicate "lt" [Var "serial_number", Constant "100"]))
                      ]
                  , properties = 
                      [ Property "serial_number" "Asset" PTInteger
                      , Property "firmware_ver" "Device" PTString
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitPython reg
      content `shouldBe` 
        "from __future__ import annotations\n\n\
        \from pydantic import BaseModel, Field\n\n\
        \class Asset(BaseModel):\n\
        \    serial_number: int\n\n\
        \class Device(Asset):\n\
        \    # Overridden inherited property with subclass constraints\n\
        \    serial_number: int = Field(lt=100)\n\
        \    firmware_ver: str\n\n\
        \Asset.model_rebuild()\n\
        \Device.model_rebuild()\n"

    it "emits classes in topological order so base classes precede subclasses" $ do
      -- Child "Sensor" appears before parent "Device", which appears before parent "Asset"
      let reg = emptyRegistry
                  { concepts = [("Sensor", Just "Device"), ("Device", Just "Asset"), ("Asset", Nothing)]
                  , axioms = []
                  , properties = []
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitPython reg
          posAsset = head [i | (i, s) <- zip [(0 :: Int)..] (lines content), "class Asset" `isInfixOf` s]
          posDevice = head [i | (i, s) <- zip [(0 :: Int)..] (lines content), "class Device" `isInfixOf` s]
          posSensor = head [i | (i, s) <- zip [(0 :: Int)..] (lines content), "class Sensor" `isInfixOf` s]
      posAsset < posDevice `shouldBe` True
      posDevice < posSensor `shouldBe` True

    it "generates range bounds for Float properties" $ do
      let reg = emptyRegistry
                  { concepts = [("Freezer", Nothing)]
                  , axioms = [ForAll "f" (Implies (Predicate "Freezer" [Var "f"])
                                (And (Predicate "gte" [Var "temperature", Constant "-20.5"])
                                     (Predicate "lt" [Var "temperature", Constant "0.0"])))]
                  , properties = [Property "temperature" "Freezer" PTFloat]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          code = emitPython reg
      code `shouldContain` "temperature: float = Field(ge=-20.5, lt=0.0)"
 
    it "generates range bounds for Double properties" $ do
      let reg = emptyRegistry
                  { concepts = [("Freezer", Nothing)]
                  , axioms = [ForAll "f" (Implies (Predicate "Freezer" [Var "f"])
                                (And (Predicate "gt" [Var "temperature", Constant "-20.5"])
                                     (Predicate "lte" [Var "temperature", Constant "0.0"])))]
                  , properties = [Property "temperature" "Freezer" PTDouble]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          code = emitPython reg
      code `shouldContain` "temperature: float = Field(gt=-20.5, le=0.0)"

    it "emitted Python code passes python3 ast.parse syntax check" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Just "Device"), ("Device", Just "Asset"), ("Asset", Nothing)]
                  , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "temp", Constant "25.0"]))]
                  , properties = [Property "temp" "Sensor" PTFloat]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          code = emitPython reg
      (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", "import ast, sys; ast.parse(sys.stdin.read())"] code
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""

    it "emitted Python model enforces range constraints at runtime via Pydantic" $ do
      let reg = emptyRegistry
                  { concepts = [("Oven", Nothing)]
                  , axioms = [ForAll "o" (Implies (Predicate "Oven" [Var "o"]) 
                                (And (Predicate "gt" [Var "temperature", Constant "100"])
                                     (Predicate "lt" [Var "temperature", Constant "250"])))]
                  , properties = [Property "temperature" "Oven" PTInteger]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          code = emitPython reg
          script = 
            code ++ "\n" ++
            "import sys\n" ++
            "from pydantic import ValidationError\n" ++
            "# Valid should succeed\n" ++
            "o1 = Oven(temperature=150)\n" ++
            "assert o1.temperature == 150\n" ++
            "# Invalid (< 100) should raise ValidationError\n" ++
            "try:\n" ++
            "    Oven(temperature=50)\n" ++
            "    sys.exit(1)\n" ++
            "except ValidationError:\n" ++
            "    pass\n" ++
            "# Invalid (> 250) should raise ValidationError\n" ++
            "try:\n" ++
            "    Oven(temperature=300)\n" ++
            "    sys.exit(1)\n" ++
            "except ValidationError:\n" ++
            "    pass\n"
      (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", script] ""
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""

    it "emitted Python model enforces conditional constraints via @model_validator" $ do
      let reg = emptyRegistry
                  { concepts = [("Controller", Nothing)]
                  , axioms = [ForAll "c" (Implies (And (Predicate "Controller" [Var "c"])
                                                       (Predicate "eq" [Var "safety_status", Constant "False"]))
                                                  (Predicate "eq" [Var "active", Constant "False"]))]
                  , properties = [Property "safety_status" "Controller" PTString, Property "active" "Controller" PTBoolean]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          code = emitPython reg
          script = 
            code ++ "\n" ++
            "import sys\n" ++
            "from pydantic import ValidationError\n" ++
            "# Valid: safety_status True and active True\n" ++
            "c1 = Controller(safety_status='True', active=True)\n" ++
            "assert c1.active is True\n" ++
            "# Valid: safety_status False and active False\n" ++
            "c2 = Controller(safety_status='False', active=False)\n" ++
            "assert c2.active is False\n" ++
            "# Invalid: safety_status False and active True should fail\n" ++
            "try:\n" ++
            "    Controller(safety_status='False', active=True)\n" ++
            "    sys.exit(1)\n" ++
            "except ValidationError:\n" ++
            "    pass\n"
      (exitCode, _, stderr) <- readProcessWithExitCode "python3" ["-c", script] ""
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""

    it "emits compound boolean expressions (Or, Not, ne) in conditional validators" $ do
      let reg = emptyRegistry
                  { concepts = [("Device", Nothing)]
                  , axioms =
                      [ ForAll "d"
                          (Implies
                            (And (Predicate "Device" [Var "d"])
                                 (Or (Predicate "eq" [Var "mode", Constant "manual"])
                                     (Not (Predicate "ne" [Var "status", Constant "ready"]))))
                            (Predicate "lt" [Constant "10", Var "power"]))
                      ]
                  , properties =
                      [ Property "mode" "Device" PTString
                      , Property "status" "Device" PTString
                      , Property "power" "Device" PTInteger
                      ]
                  }
          code = emitPython reg
      code `shouldContain` "@model_validator(mode=\"after\")"
      code `shouldContain` "((self.mode == \"manual\") or not ((self.status != \"ready\")))"
      code `shouldContain` "(self.power is not None and self.power > 10)"

    it "emits cardinalities, collections, and defaults accurately" $ do
      let reg = emptyRegistry
                  { concepts = [("Machine", Nothing)]
                  , properties =
                      [ PropertyDef "opt_id" "Machine" PTInteger CardZeroOrOne Nothing
                      , PropertyDef "bounded_opt" "Machine" PTInteger CardZeroOrOne Nothing
                      , PropertyDef "tags" "Machine" PTString CardZeroOrMore Nothing
                      , PropertyDef "req_tags" "Machine" PTString CardOneOrMore Nothing
                      , PropertyDef "name_def" "Machine" PTString CardDefault (Just "default-machine")
                      , PropertyDef "flag_def" "Machine" PTBoolean CardDefault (Just "True")
                      ]
                  , axioms = [ForAll "m" (Implies (Predicate "Machine" [Var "m"]) (Predicate "gt" [Var "bounded_opt", Constant "0"]))]
                  }
          code = emitPython reg
      code `shouldContain` "from typing import Optional, List"
      code `shouldContain` "opt_id: Optional[int] = None"
      code `shouldContain` "bounded_opt: Optional[int] = Field(default=None, gt=0)"
      code `shouldContain` "tags: List[str] = Field(default_factory=list)"
      code `shouldContain` "req_tags: List[str] = Field(min_length=1)"
      code `shouldContain` "name_def: str = \"default-machine\""
      code `shouldContain` "flag_def: bool = True"




