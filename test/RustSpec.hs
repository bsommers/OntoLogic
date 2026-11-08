module RustSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Rust (emitRust)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (removeFile, doesFileExist)

spec :: Spec
spec = describe "Rust Emitter" $ do
    it "generates basic Rust struct with derives and fields" $ do
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
            rustCode = emitRust reg
        rustCode `shouldContain` "pub struct Vehicle {"
        rustCode `shouldContain` "pub speed: i64,"
        rustCode `shouldContain` "impl Vehicle {"
        rustCode `shouldContain` "pub fn validate(&self) -> Result<(), Vec<String>>"
        rustCode `shouldContain` "self.speed < 0"
        rustCode `shouldContain` "self.speed > 120"

    it "handles inheritance and validation delegation" $ do
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
            rustCode = emitRust reg
        rustCode `shouldContain` "pub base: Vehicle,"
        rustCode `shouldContain` "pub doors: i64,"
        rustCode `shouldContain` "self.base.validate()"

    it "emitted Rust code compiles successfully with rustc" $ do
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
            rustCode = emitRust reg
            tempFile = "/tmp/ontologic_test_model.rs"
            outFile = "/tmp/libontologic_test_model.rlib"
        writeFile tempFile rustCode
        (exitCode, _, stderr) <- readProcessWithExitCode "rustc" ["--crate-type=lib", tempFile, "-o", outFile] ""
        exitCode `shouldBe` ExitSuccess
        stderr `shouldBe` ""
        
        -- Cleanup
        rExists <- doesFileExist tempFile
        if rExists then removeFile tempFile else return ()
        oExists <- doesFileExist outFile
        if oExists then removeFile outFile else return ()

    it "emits conditional constraint checks and compiles with rustc" $ do
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
            rustCode = emitRust reg
            tempFile = "/tmp/ontologic_test_oven.rs"
            outFile = "/tmp/libontologic_test_oven.rlib"
        rustCode `shouldContain` "if ((self.is_active == true)) && !((self.temperature > 100)) {"
        rustCode `shouldContain` "errors.push(\"Axiom violation:"
        writeFile tempFile rustCode
        (exitCode, _, stderr) <- readProcessWithExitCode "rustc" ["--crate-type=lib", tempFile, "-o", outFile] ""
        exitCode `shouldBe` ExitSuccess
        stderr `shouldBe` ""
        rExists <- doesFileExist tempFile
        if rExists then removeFile tempFile else return ()
        oExists <- doesFileExist outFile
        if oExists then removeFile outFile else return ()

    it "emits Option pattern matching and Vec loops for optional and repeated properties" $ do
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
            rustCode = emitRust reg
        rustCode `shouldContain` "if let Some(val) = &self.port"
        rustCode `shouldContain` "*val <= 1024"
        rustCode `shouldContain` "for item in &self.scores"
        rustCode `shouldContain` "*item < 0"

    it "handles reserved keywords and custom box types" $ do
        let reg = emptyRegistry
                { concepts = [("Device", Nothing), ("Module", Nothing)]
                , properties = [ Property "type" "Device" PTString
                               , Property "fn" "Device" PTInteger
                               , Property "child" "Device" (PTCustom "Module")
                               , PropertyDef "tags" "Device" PTInteger CardOneOrMore Nothing
                               ]
                , axioms = [ ForAll "d" (Implies (Predicate "Device" [Var "d"])
                                                 (Predicate "gte" [Var "tags", Constant "1"]))
                           ]
                }
            rustCode = emitRust reg
        rustCode `shouldContain` "pub r#type: String,"
        rustCode `shouldContain` "pub r#fn: i64,"
        rustCode `shouldContain` "pub child: Option<Box<Module>>,"
        rustCode `shouldContain` "pub tags: Vec<i64>,"
        rustCode `shouldContain` "tags must have at least one element"

    it "handles two-level inheritance base delegation and inverted comparison" $ do
        let reg = emptyRegistry
                { concepts = [("A", Nothing), ("B", Just "A"), ("C", Just "B")]
                , properties = [ Property "val" "A" PTInteger ]
                , axioms = [ ForAll "c" (Implies (Predicate "C" [Var "c"])
                                                 (Predicate "gt" [Var "val", Constant "10"]))
                           ]
                }
            rustCode = emitRust reg
        rustCode `shouldContain` "self.base.base.val"
        rustCode `shouldContain` "self.base.validate()"
