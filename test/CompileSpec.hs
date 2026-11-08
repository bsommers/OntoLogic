-- | Compiles or type-checks the generated code with the real toolchains (#25).
--
-- Each case skips (rather than fails) when its toolchain is missing, so a
-- partial local environment stays usable; CI installs all of them and the
-- workflow prints their versions, so a silent skip there is visible.
module CompileSpec (spec, skipOrFail) where

import Test.Hspec
import Control.Concurrent (threadDelay)
import Control.Exception (finally)
import Control.Monad (unless, void)
import Data.Char (isSpace)
import Data.List (isInfixOf, isPrefixOf, tails)
import Data.Text (pack)
import System.Directory (findExecutable, createDirectoryIfMissing, getTemporaryDirectory)
import System.Environment (lookupEnv)
import System.Exit (ExitCode(..))
import System.FilePath ((</>))
import System.Process (proc, cwd, readCreateProcessWithExitCode, readProcessWithExitCode)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import Loader (loadRegistryWithImports)
import Emitters.Go (emitGo)
import Emitters.Rust (emitRust)
import Emitters.Python (emitPython)
import Emitters.TypeScript (emitTypeScript)
import Emitters.Neo4j (emitCypher, emitConstraintsCypher)
import Emitters.D2 (emitD2)
import Emitters.Mermaid (emitMermaid)

-- | Three inheritance levels, a bound declared two levels above where it applies,
--   and two relations (one self-referential) so the emitters must handle
--   forward references between generated types.
threeLevel :: Registry
threeLevel = either (error . errorBundlePretty) id . parse parseRegistry "t" . pack $ unlines
    [ "(def-concept Person)"
    , "(def-concept Vessel)"
    , "(def-concept Tank Vessel)"
    , "(def-concept FuelTank Tank)"
    , "(def-property capacity Vessel Integer)"
    , "(forall (x) (implies (FuelTank x) (gt capacity 100)))"
    , "(def-relation ownedBy Vessel Person)"
    , "(def-relation manages Person Person)"
    ]

-- | Skip locally, but fail where every toolchain is meant to be present. CI sets
--   ONTOLOGIC_REQUIRE_TOOLCHAINS, so a vanished toolchain breaks the build instead of
--   quietly turning these guards into no-ops.
skipOrFail :: String -> IO ()
skipOrFail reason = do
    required <- lookupEnv "ONTOLOGIC_REQUIRE_TOOLCHAINS"
    case required of
        Just v | v `notElem` ["", "0"] ->
            expectationFailure ("ONTOLOGIC_REQUIRE_TOOLCHAINS is set but " ++ reason)
        _ -> pendingWith reason

-- | For toolchains CI installs: absent means the guard is not running, which is a failure there.
withTool :: String -> (FilePath -> IO ()) -> IO ()
withTool exe act = findExecutable exe >>= maybe (skipOrFail (exe ++ " not installed")) act

-- | For genuinely optional local tools (a heavyweight renderer, a docker service). These are
--   not installed in CI by design, so they always skip rather than fail when missing.
withOptionalTool :: String -> (FilePath -> IO ()) -> IO ()
withOptionalTool exe act =
    findExecutable exe >>= maybe (pendingWith (exe ++ " not installed (optional)")) act

-- | Run an action against the compose neo4j service. A container this starts is removed
--   afterwards, even if the action fails; one that was already running is left alone.
--   The server takes several seconds to accept connections after `up`, so readiness is
--   polled rather than probed once.
withNeo4j :: FilePath -> IO () -> IO ()
withNeo4j docker act = do
    (_, running, _) <- runIn "." docker ["compose", "ps", "-q", "neo4j"]
    let alreadyUp = not (all isSpace running)
        teardown = unless alreadyUp $
            void (runIn "." docker ["compose", "rm", "--stop", "--force", "neo4j"])
    (upCode, _, upErr) <- runIn "." docker ["compose", "up", "-d", "neo4j"]
    if upCode /= ExitSuccess
        then teardown >> pendingWith ("neo4j service unavailable: " ++ take 200 upErr)
        else flip finally teardown $ do
            ready <- waitFor (60 :: Int)
            case ready of
                Left err -> pendingWith ("neo4j not accepting connections: " ++ take 200 err)
                Right () -> act
  where
    waitFor n = do
        (code, _, err) <- runIn "." docker (cypherShell ++ ["RETURN 1"])
        case code of
            ExitSuccess -> return (Right ())
            _ | n <= 1    -> return (Left err)
              | otherwise -> threadDelay 1000000 >> waitFor (n - 1)

cypherShell :: [String]
cypherShell = words "compose exec -T neo4j cypher-shell -u neo4j -p password"

-- | A scratch dir inside the repo. The snap-packaged mmdc is confined and cannot read
--   /tmp or hidden directories, so the diagram renderers get a working directory here.
localDir :: String -> IO FilePath
localDir name = do
    let dir = ".test-tmp" </> name
    createDirectoryIfMissing True dir
    return dir

tmpDir :: String -> IO FilePath
tmpDir name = do
    base <- getTemporaryDirectory
    let dir = base </> ("ontologic-compile-" ++ name)
    createDirectoryIfMissing True dir
    return dir

-- | Run a command with the working directory set, which readProcessWithExitCode cannot do.
runIn :: FilePath -> FilePath -> [String] -> IO (ExitCode, String, String)
runIn dir exe args = runInWith dir exe args ""

-- | Same as runIn but feeds the process stdin.
runInWith :: FilePath -> FilePath -> [String] -> String -> IO (ExitCode, String, String)
runInWith dir exe args input = readCreateProcessWithExitCode (proc exe args) { cwd = Just dir } input

spec :: Spec
spec = describe "generated code compiles (#25)" $ do
    it "go vet accepts the bfo_2020 Go output" $ withTool "go" $ \go -> do
        loaded <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
        case loaded of
            Left err -> expectationFailure ("could not load bfo_2020: " ++ err)
            Right reg -> do
                dir <- tmpDir "go"
                writeFile (dir </> "go.mod") "module models\n\ngo 1.21\n"
                writeFile (dir </> "models.go") (emitGo reg)
                (code, out, err) <- runIn dir go ["vet", "./..."]
                (code, out ++ err) `shouldBe` (ExitSuccess, "")

    it "go vet accepts output with no constrained property" $ withTool "go" $ \go -> do
        dir <- tmpDir "go-nofmt"
        writeFile (dir </> "go.mod") "module models\n\ngo 1.21\n"
        writeFile (dir </> "models.go") (emitGo threeLevel)
        (code, out, err) <- runIn dir go ["vet", "./..."]
        (code, out ++ err) `shouldBe` (ExitSuccess, "")

    it "go vet accepts conditional constraints with newlines and quotes in description" $ withTool "go" $ \go -> do
        let multilineDesc = either (error . errorBundlePretty) id . parse parseRegistry "t" . pack $ unlines
                [ "(def-concept Order)"
                , "(def-property total Order Integer)"
                , "(def-property status Order String)"
                , "(forall (o) (implies (= (status o) \"pending\\nreview\") (gt total 0)))"
                ]
        dir <- tmpDir "go-multiline"
        writeFile (dir </> "go.mod") "module models\n\ngo 1.21\n"
        writeFile (dir </> "models.go") (emitGo multilineDesc)
        (code, out, err) <- runIn dir go ["vet", "./..."]
        (code, out ++ err) `shouldBe` (ExitSuccess, "")

    it "rustc compiles the three-level Rust output" $ withTool "rustc" $ \rustc -> do
        dir <- tmpDir "rust"
        writeFile (dir </> "models.rs") (emitRust threeLevel)
        (code, _, err) <- readProcessWithExitCode rustc
            ["--crate-type", "lib", "--edition", "2021", "-A", "dead_code"
            , "-o", dir </> "libmodels.rlib", dir </> "models.rs"] ""
        (code, err) `shouldBe` (ExitSuccess, "")

    -- On Python >= 3.14 annotations are lazy (PEP 649), so a forward reference no
    -- longer raises at import and the runtime case below cannot fail on such an
    -- interpreter. These source-level assertions keep the guard effective there.
    it "defers annotations so forward references resolve on any interpreter" $ do
        let out = emitPython threeLevel
        out `shouldStartWith` "from __future__ import annotations\n"
        out `shouldContain` "Person.model_rebuild()\n"
        out `shouldContain` "Vessel.model_rebuild()\n"

    it "python imports the generated module" $ withTool "python3" $ \py -> do
        (havePydantic, _, _) <- readProcessWithExitCode py ["-c", "import pydantic"] ""
        if havePydantic /= ExitSuccess
            then skipOrFail "pydantic not installed"
            else do
                dir <- tmpDir "python"
                writeFile (dir </> "models.py") (emitPython threeLevel)
                (code, _, err) <- readProcessWithExitCode py
                    ["-c", "import sys; sys.path.insert(0, '" ++ dir ++ "'); import models"] ""
                (code, err) `shouldBe` (ExitSuccess, "")

    it "tsc --noEmit accepts the Zod output" $ withTool "npm" $ \npm -> do
        dir <- tmpDir "ts"
        writeFile (dir </> "models.ts") (emitTypeScript threeLevel)
        writeFile (dir </> "package.json") "{\"name\":\"ontologic-ts-check\",\"private\":true,\"version\":\"0.0.0\"}"
        writeFile (dir </> "tsconfig.json") "{\"compilerOptions\":{\"strict\":true,\"target\":\"ES2020\",\"module\":\"ES2020\",\"moduleResolution\":\"node\",\"noEmit\":true}}"
        (instCode, _, instErr) <- runIn dir npm
            ["install", "--silent", "--no-audit", "--no-fund", "zod@3", "typescript@5"]
        if instCode /= ExitSuccess
            then pendingWith ("npm install failed (offline?): " ++ take 200 instErr)
            else do
                (code, out, err) <- runIn dir (dir </> "node_modules" </> ".bin" </> "tsc") ["--noEmit"]
                (code, out ++ err) `shouldBe` (ExitSuccess, "")

    -- Neo4j Community rejects property-existence constraints outright ("requires Neo4j
    -- Enterprise Edition"), so they are emitted to a separate constraints.cypher (#48).
    -- The main graph.cypher now loads cleanly on Community Edition with exit 0.
    it "a real neo4j parses and applies every generated graph statement" $ withOptionalTool "docker" $ \docker ->
        withNeo4j docker $ do
            loaded <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
            case loaded of
                Left err -> expectationFailure ("could not load bfo_2020: " ++ err)
                Right reg -> do
                    (code, out, err) <- runInWith "." docker cypherShell (emitCypher reg)
                    code `shouldBe` ExitSuccess
                    (out ++ err) `shouldNotSatisfy` isInfixOf "Invalid input"
                    (out ++ err) `shouldNotSatisfy` isInfixOf "Property existence constraint requires Neo4j Enterprise Edition"
                    emitConstraintsCypher reg `shouldContain` "CREATE CONSTRAINT IF NOT EXISTS FOR (n:`bfo:Entity`) REQUIRE n.`bfo:identifier` IS NOT NULL;"

    -- Both renderers accept namespaced names only once they are quoted (d2) or moved
    -- into a label (mermaid). d2 is the more dangerous case: it accepts the unquoted
    -- form and silently renders one container instead of every class.
    it "the d2 CLI renders the namespaced output" $ withTool "d2" $ \d2 -> do
        loaded <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
        case loaded of
            Left err -> expectationFailure ("could not load bfo_2020: " ++ err)
            Right reg -> do
                dir <- localDir "d2"
                writeFile (dir </> "diagram.d2") (emitD2 reg)
                (code, _, _) <- runIn dir d2 ["diagram.d2", "out.svg"]
                code `shouldBe` ExitSuccess
                -- d2 reports success either way, so check what it drew: with unquoted
                -- keys the whole ontology collapses into a single container.
                svg <- readFile (dir </> "out.svg")
                let shapes = length (filter (isPrefixOf "class=\"shape\"") (tails svg))
                shapes `shouldSatisfy` (> 10)

    it "the mermaid CLI renders the namespaced output" $ withOptionalTool "mmdc" $ \mmdc -> do
        loaded <- loadRegistryWithImports "ontologic-lib/bfo_2020.logic"
        case loaded of
            Left err -> expectationFailure ("could not load bfo_2020: " ++ err)
            Right reg -> do
                dir <- localDir "mmd"
                writeFile (dir </> "class_diagram.mmd") (emitMermaid reg)
                (code, out, err) <- runIn dir mmdc ["-i", "class_diagram.mmd", "-o", "out.svg"]
                (code, out ++ err) `shouldSatisfy` \(c, o) ->
                    c == ExitSuccess && not ("Parse error" `isInfixOf` o)
