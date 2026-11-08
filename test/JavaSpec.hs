module JavaSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Java (emitJava, emitJavaWithPackage)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (createDirectoryIfMissing, removeDirectoryRecursive, getHomeDirectory)
import System.FilePath ((</>))

-- The default Java package changed with #33: the emitter no longer hardcodes a
-- vendor name. Callers that want their own package pass --java-package (CLI),
-- :set java-package (REPL) or emitJavaWithPackage.
spec :: Spec
spec = do
  describe "Java Emitter" $ do
    it "generates separate files for each concept" $ do
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
          files = emitJava reg
      files `shouldBe` 
        [ ("Asset", "package ontologic.generated;\nimport jakarta.validation.constraints.*;\n\npublic class Asset {\n    private String serial_number;\n\n    @NotNull\n    public String getSerial_number() {\n        return this.serial_number;\n    }\n\n    public void setSerial_number(String val) {\n        this.serial_number = val;\n    }\n\n}\n")
        , ("Device", "package ontologic.generated;\nimport jakarta.validation.constraints.*;\n\npublic class Device extends Asset {\n    private String firmware_ver;\n\n    @NotNull\n    public String getFirmware_ver() {\n        return this.firmware_ver;\n    }\n\n    public void setFirmware_ver(String val) {\n        this.firmware_ver = val;\n    }\n\n}\n")
        ]

    it "generates @Min and @Max annotations based on axioms" $ do
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
          files = emitJava reg
      files `shouldBe` 
        [ ("Refrigerator", "package ontologic.generated;\nimport jakarta.validation.constraints.*;\n\npublic class Refrigerator {\n    private Integer temperature;\n\n    @NotNull\n    @Min(1)\n    @Max(4)\n    public Integer getTemperature() {\n        return this.temperature;\n    }\n\n    public void setTemperature(Integer val) {\n        this.temperature = val;\n    }\n\n}\n")
        ]

    it "handles non-integer bounds gracefully in Java Emitter" $ do
      let reg = emptyRegistry
                  { concepts = [("Refrigerator", Nothing)]
                  , axioms = 
                      [ ForAll "r" (Implies (Predicate "Refrigerator" [Var "r"]) 
                                     (And (Predicate "gt" [Var "temperature", Constant "abc"]) 
                                     (And (Predicate "lt" [Var "temperature", Constant "5.5"])
                                     (And (Predicate "gte" [Var "temperature", Constant "xyz"])
                                          (Predicate "lte" [Var "temperature", Constant "8.8"])))))
                      ]
                  , properties = 
                      [ Property "temperature" "Refrigerator" PTInteger
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          files = emitJava reg
      files `shouldBe` 
        [ ("Refrigerator", "package ontologic.generated;\nimport jakarta.validation.constraints.*;\n\npublic class Refrigerator {\n    private Integer temperature;\n\n    @NotNull\n    public Integer getTemperature() {\n        return this.temperature;\n    }\n\n    public void setTemperature(Integer val) {\n        this.temperature = val;\n    }\n\n}\n")
        ]

    it "emits a warning comment if subclass adds constraints to inherited property in Java Emitter" $ do
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
          files = emitJava reg
      files `shouldBe` 
        [ ("Asset", "package ontologic.generated;\nimport jakarta.validation.constraints.*;\n\npublic class Asset {\n    private Integer serial_number;\n\n    @NotNull\n    public Integer getSerial_number() {\n        return this.serial_number;\n    }\n\n    public void setSerial_number(Integer val) {\n        this.serial_number = val;\n    }\n\n}\n")
        , ("Device", "package ontologic.generated;\nimport jakarta.validation.constraints.*;\n\npublic class Device extends Asset {\n    // Overridden inherited property with subclass constraints\n    @Override\n    @NotNull\n    @Max(99)\n    public Integer getSerial_number() {\n        return super.getSerial_number();\n    }\n\n    private String firmware_ver;\n\n    @NotNull\n    public String getFirmware_ver() {\n        return this.firmware_ver;\n    }\n\n    public void setFirmware_ver(String val) {\n        this.firmware_ver = val;\n    }\n\n}\n")
        ]

    it "generates @DecimalMin and @DecimalMax for Double/Float properties" $ do
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
          files = emitJava reg
          (_, code) = head files
      code `shouldContain` "private Double temperature;"
      code `shouldContain` "@DecimalMin(value = \"-20.5\", inclusive = false)"
      code `shouldContain` "@DecimalMax(\"0.0\")"

    it "generates @DecimalMin and @DecimalMax for Float properties" $ do
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
          files = emitJava reg
          (_, code) = head files
      code `shouldContain` "private Float temperature;"
      code `shouldContain` "@DecimalMin(\"-20.5\")"
      code `shouldContain` "@DecimalMax(value = \"0.0\", inclusive = false)"

    it "emitted Java classes compile successfully with javac" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Just "Device"), ("Device", Just "Asset"), ("Asset", Nothing)]
                  , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"]) (Predicate "gt" [Var "reading", Constant "10"]))]
                  , properties = [Property "reading" "Sensor" PTInteger]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          files = emitJava reg
          tmpDir = "/tmp/javac_test"
      createDirectoryIfMissing True tmpDir
      mapM_ (\(name, code) -> writeFile (tmpDir </> name ++ ".java") code) files
      home <- getHomeDirectory
      (_, jarOut, _) <- readProcessWithExitCode "find" [home </> ".gradle" </> "caches", "-name", "jakarta.validation-api-*.jar"] ""
      let jarPath = case lines jarOut of
                      (j:_) -> j
                      [] -> ""
      (exitCode, _, stderr) <- readProcessWithExitCode "javac" ["-cp", jarPath, tmpDir </> "Asset.java", tmpDir </> "Device.java", tmpDir </> "Sensor.java", "-d", tmpDir] ""
      removeDirectoryRecursive tmpDir
      exitCode `shouldBe` ExitSuccess
      stderr `shouldBe` ""

    it "supports custom package name via emitJavaWithPackage" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing)]
                  , axioms = []
                  , properties = [Property "serial_number" "Asset" PTString]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          files = emitJavaWithPackage "com.custom.models" reg
      case files of
        [("Asset", code)] -> code `shouldContain` "package com.custom.models;\n"
        _ -> expectationFailure "Expected single Asset file"

    it "emits @AssertTrue for conditional constraints and compiles with javac" $ do
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
          files = emitJava reg
      case files of
        [("Controller", code)] -> do
          code `shouldContain` "@AssertTrue"
          code `shouldContain` "public boolean isValidConstraint1()"
          let tmpDir = "/tmp/javac_assert_test"
          createDirectoryIfMissing True tmpDir
          writeFile (tmpDir </> "Controller.java") code
          home <- getHomeDirectory
          (_, jarOut, _) <- readProcessWithExitCode "find" [home </> ".gradle" </> "caches", "-name", "jakarta.validation-api-*.jar"] ""
          let jarPath = case lines jarOut of
                          (j:_) -> j
                          [] -> ""
          (exitCode, _, stderr) <- readProcessWithExitCode "javac" ["-cp", jarPath, tmpDir </> "Controller.java", "-d", tmpDir] ""
          removeDirectoryRecursive tmpDir
          exitCode `shouldBe` ExitSuccess
          stderr `shouldBe` ""
        _ -> expectationFailure "Expected single Controller file"

    it "emits inverted comparisons and ne conditions in Java validation constraints" $ do
      let reg = emptyRegistry
                  { concepts = [("Device", Nothing)]
                  , axioms = [ForAll "d" (Implies (And (Predicate "Device" [Var "d"])
                                                       (Predicate "ne" [Var "mode", Constant "standby"]))
                                                  (And (Predicate "gt" [Constant "10", Var "power"])
                                                       (Predicate "ne" [Var "active", Constant "False"])))]
                  , properties =
                      [ Property "power" "Device" PTInteger
                      , Property "mode" "Device" PTString
                      , Property "active" "Device" PTBoolean
                      ]
                  }
          files = emitJava reg
      case files of
        [("Device", code)] -> do
          code `shouldContain` "(this.power != null && this.power < 10)"
          code `shouldContain` "!Objects.equals(this.mode, \"standby\")"
          code `shouldContain` "(!\"False\".equalsIgnoreCase(String.valueOf(this.active)) && !Boolean.FALSE.equals(this.active))"
        _ -> expectationFailure "Expected single Device file"

    it "emits collection cardinalities and exclusive decimal bounds" $ do
      let reg = emptyRegistry
                  { concepts = [("Sensor", Nothing), ("Person", Nothing)]
                  , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"])
                                                  (And (Predicate "gt" [Var "reading", Constant "0.5"])
                                                       (Predicate "lt" [Var "reading", Constant "99.5"])))]
                  , properties =
                      [ PropertyDef "reading" "Sensor" PTDouble CardDefault Nothing
                      , PropertyDef "tags" "Sensor" PTString CardZeroOrMore Nothing
                      , PropertyDef "alerts" "Sensor" PTString CardOneOrMore Nothing
                      , PropertyDef "owner" "Sensor" (PTCustom "Person") CardZeroOrOne Nothing
                      ]
                  }
          files = emitJava reg
      case files of
        [("Person", _), ("Sensor", code)] -> do
          code `shouldContain` "@DecimalMin(value = \"0.5\", inclusive = false)"
          code `shouldContain` "@DecimalMax(value = \"99.5\", inclusive = false)"
          code `shouldContain` "private java.util.List<String> tags;"
          code `shouldContain` "@jakarta.validation.constraints.NotEmpty"
          code `shouldContain` "private java.util.List<String> alerts;"
          code `shouldContain` "private Person owner;"
        _ -> expectationFailure "Expected Sensor and Person files"
