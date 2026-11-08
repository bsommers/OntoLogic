{-# LANGUAGE OverloadedStrings #-}
module CppSpec (spec) where

import Test.Hspec
import Parser (parseRegistry)
import Text.Megaparsec (parse)
import qualified Data.Text as T
import Emitters.Cpp (emitCpp)
import System.Directory (findExecutable, getTemporaryDirectory)
import System.FilePath ((</>))
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))

spec :: Spec
spec = describe "C++20 Model Emitter" $ do
    let logicSource = T.pack $ unlines
          [ "(def-concept Device)"
          , "(def-property serial_number Device String :cardinality 1..1)"
          , "(def-property firmware_version Device String :default \"1.0.0\")"
          , "(def-property sub_device Device Device :optional True)"
          , "(def-concept Robot Device)"
          , "(def-property battery_level Robot Integer :cardinality 1..1)"
          , "(def-property temp_opt Robot Float :optional True)"
          , "(def-property sensor_readings Robot Double :cardinality 0..*)"
          , "(def-property tasks Robot String :cardinality 1..*)"
          , "(forall (r) (implies (Robot r) (and (gte battery_level 0) (lte battery_level 100))))"
          ]

    it "emits C++20 structs with types, inheritance, and forward declarations" $ do
      case parse parseRegistry "cpp_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let cpp = emitCpp reg
          cpp `shouldContain` "#pragma once"
          cpp `shouldContain` "#include <memory>"
          cpp `shouldContain` "namespace ontologic {"
          cpp `shouldContain` "struct Device;"
          cpp `shouldContain` "struct Robot;"
          cpp `shouldContain` "struct Device {"
          cpp `shouldContain` "std::string serial_number;"
          cpp `shouldContain` "std::string firmware_version = \"1.0.0\";"
          cpp `shouldContain` "std::shared_ptr<Device> sub_device = nullptr;"
          cpp `shouldContain` "struct Robot : public Device {"
          cpp `shouldContain` "int64_t battery_level;"
          cpp `shouldContain` "std::optional<float> temp_opt = std::nullopt;"
          cpp `shouldContain` "std::vector<double> sensor_readings = {};"
          cpp `shouldContain` "std::vector<std::string> tasks = {};"

    it "generates C++ validation methods with bounds and cardinality checks" $ do
      case parse parseRegistry "cpp_test.logic" logicSource of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let cpp = emitCpp reg
          cpp `shouldContain` "virtual std::vector<std::string> validate() const"
          cpp `shouldContain` "Device::validate()"
          cpp `shouldContain` "tasks.empty()"
          cpp `shouldContain` "battery_level >= 0"
          cpp `shouldContain` "battery_level <= 100"

    it "compiles emitted C++ code cleanly with g++ -std=c++20" $ do
      mGpp <- findExecutable "g++"
      case mGpp of
        Nothing -> pendingWith "g++ not found in PATH"
        Just gpp -> do
          case parse parseRegistry "cpp_test.logic" logicSource of
            Left err -> expectationFailure (show err)
            Right reg -> do
              let cppCode = emitCpp reg
              tmpDir <- getTemporaryDirectory
              let srcFile = tmpDir </> "ontologic_test_model.hpp"
                  cppFile = tmpDir </> "ontologic_test_main.cpp"
              writeFile srcFile cppCode
              writeFile cppFile $ unlines
                [ "#include \"" ++ srcFile ++ "\""
                , "int main() {"
                , "    ontologic::Robot robot;"
                , "    robot.serial_number = \"SN-12345\";"
                , "    robot.firmware_version = \"1.0.0\";"
                , "    robot.battery_level = 95;"
                , "    robot.tasks.push_back(\"inspect\");"
                , "    robot.sub_device = std::make_shared<ontologic::Device>();"
                , "    robot.sub_device->serial_number = \"SUB-01\";"
                , "    auto errs = robot.validate();"
                , "    return errs.empty() ? 0 : 1;"
                , "}"
                ]
              (code, _stdoutStr, stderrStr) <- readProcessWithExitCode gpp ["-std=c++20", "-c", cppFile, "-o", tmpDir </> "test.o"] ""
              code `shouldBe` ExitSuccess
              stderrStr `shouldBe` ""

    it "emits custom null check and optional/repeated bound constraint checks" $ do
      let src = unlines
            [ "(def-concept Engine)"
            , "(def-concept Car)"
            , "(def-property engine Car Engine :cardinality 1..1)"
            , "(def-property opt_speed Car Integer :cardinality 0..1)"
            , "(def-property historical_speeds Car Integer :cardinality 0..*)"
            , "(def-property is_running Car Boolean :default True)"
            , "(forall (c) (implies (Car c) (and (gt opt_speed 0) (gte historical_speeds 0))))"
            ]
      case parse parseRegistry "car.logic" (T.pack src) of
        Left err -> expectationFailure (show err)
        Right reg -> do
          let cpp = emitCpp reg
          cpp `shouldContain` "if (!engine) {"
          cpp `shouldContain` "Field 'engine' must not be null"
          cpp `shouldContain` "opt_speed.has_value()"
          cpp `shouldContain` "!(*opt_speed > 0)"
          cpp `shouldContain` "for (const auto& item : historical_speeds)"
          cpp `shouldContain` "!(item >= 0)"
          cpp `shouldContain` "bool is_running = true;"
