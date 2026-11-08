module GoSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Go (emitGo)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (removeFile, doesFileExist)

spec :: Spec
spec = describe "Go Emitter" $ do
    it "generates basic Go struct with exported fields and JSON tags" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing)]
                , properties = [Property "speed" "Vehicle" PTInteger]
                , axioms = [ForAll "v" (Implies (Predicate "Vehicle" [Var "v"])
                                               (And (Predicate "gte" [Var "speed", Constant "0"])
                                                    (Predicate "lte" [Var "speed", Constant "120"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            goCode = emitGo reg
        goCode `shouldContain` "package models"
        goCode `shouldContain` "type Vehicle struct {"
        goCode `shouldContain` "Speed int64 `json:\"speed,omitempty\"`"
        goCode `shouldContain` "func (m *Vehicle) Validate() []string"
        goCode `shouldContain` "m.Speed < 0"
        goCode `shouldContain` "m.Speed > 120"

    it "handles inheritance via struct embedding" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing), ("Car", Just "Vehicle")]
                , properties = [ Property "speed" "Vehicle" PTInteger
                               , Property "doors" "Car" PTInteger
                               ]
                , axioms = [ ForAll "v" (Implies (Predicate "Vehicle" [Var "v"]) (Predicate "gte" [Var "speed", Constant "0"]))
                           , ForAll "c" (Implies (Predicate "Car" [Var "c"]) (Predicate "gte" [Var "doors", Constant "2"]))
                           ]
                , relations = []
                , namespaces = []
                , imports = []
                }
            goCode = emitGo reg
        goCode `shouldContain` "type Car struct {"
        goCode `shouldContain` "Vehicle"
        goCode `shouldContain` "Doors int64 `json:\"doors,omitempty\"`"
        goCode `shouldContain` "m.Vehicle.Validate()"

    it "emitted Go code passes go vet" $ do
        let reg = emptyRegistry
                { concepts = [("Sensor", Nothing), ("TemperatureSensor", Just "Sensor")]
                , properties = [ Property "reading" "Sensor" PTDouble
                               , Property "calibrationId" "TemperatureSensor" PTString
                               ]
                , axioms = [ForAll "s" (Implies (Predicate "Sensor" [Var "s"])
                                               (And (Predicate "gt" [Var "reading", Constant "-50.0"])
                                                    (Predicate "lt" [Var "reading", Constant "150.0"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            goCode = emitGo reg
            tempFile = "/tmp/ontologic_test_model.go"
        writeFile tempFile goCode
        (exitCode, _, stderr) <- readProcessWithExitCode "go" ["vet", tempFile] ""
        exitCode `shouldBe` ExitSuccess
        stderr `shouldBe` ""
        
        -- Cleanup
        fExists <- doesFileExist tempFile
        if fExists then removeFile tempFile else return ()

    it "emits conditional constraint checks in Validate()" $ do
        let reg = emptyRegistry
                { concepts = [("Oven", Nothing)]
                , properties = [ Property "temperature" "Oven" PTInteger
                               , Property "is_active" "Oven" PTBoolean
                               ]
                , axioms = [ ForAll "o" (Implies (And (Predicate "Oven" [Var "o"])
                                                      (Predicate "eq" [Var "is_active", Constant "True"]))
                                                 (Predicate "gt" [Var "temperature", Constant "100"]))
                           ]
                , relations = []
                , namespaces = []
                , imports = []
                }
            goCode = emitGo reg
        goCode `shouldContain` "if ((m.IsActive == true)) && !((m.Temperature > 100)) {"
        goCode `shouldContain` "allErrors = append(allErrors, \"Axiom violation:"

    it "emits nil checks for optional properties and loops for repeated properties in Validate()" $ do
        let reg = emptyRegistry
                { concepts = [("Server", Nothing)]
                , properties = [ PropertyDef "port" "Server" PTInteger CardZeroOrOne Nothing
                               , PropertyDef "scores" "Server" PTInteger CardZeroOrMore Nothing
                               ]
                , axioms = [ ForAll "s" (Implies (Predicate "Server" [Var "s"])
                                (And (Predicate "gt" [Var "port", Constant "1024"])
                                     (Predicate "gte" [Var "scores", Constant "0"])))
                           ]
                , relations = []
                , namespaces = []
                , imports = []
                }
            goCode = emitGo reg
        goCode `shouldContain` "if m.Port != nil {"
        goCode `shouldContain` "(*m.Port) <= 1024"
        goCode `shouldContain` "for _, item := range m.Scores {"
        goCode `shouldContain` "item < 0"

    it "omits import fmt when no properties have bound constraints" $ do
        let reg = emptyRegistry
                { concepts = [("Tag", Nothing)]
                , properties = [Property "label" "Tag" PTString]
                }
            goCode = emitGo reg
        goCode `shouldNotContain` "import \"fmt\""

    it "handles CardOneOrMore, PTCustom pointer types, and snake_case PascalCase" $ do
        let reg = emptyRegistry
                { concepts = [("Device", Nothing), ("Telemetry", Nothing)]
                , properties = [ PropertyDef "device_serial_number" "Device" PTInteger CardOneOrMore Nothing
                               , Property "telemetry_data" "Device" (PTCustom "Telemetry")
                               ]
                , axioms = [ ForAll "d" (Implies (Predicate "Device" [Var "d"])
                                                 (Predicate "gte" [Var "device_serial_number", Constant "1"]))
                           ]
                }
            goCode = emitGo reg
        goCode `shouldContain` "DeviceSerialNumber []int64 `json:\"device_serial_number,omitempty\"`"
        goCode `shouldContain` "TelemetryData *Telemetry `json:\"telemetry_data,omitempty\"`"
        goCode `shouldContain` "len(m.DeviceSerialNumber) == 0"
        goCode `shouldContain` "device_serial_number must have at least one element"
