module Main where

import Options.Applicative
import System.Exit (exitFailure, exitWith, ExitCode(..))
import System.IO (hPutStrLn, stderr)
import System.Process (callProcess)
import System.Directory (createDirectoryIfMissing, findExecutable)
import System.FilePath ((</>))
import Control.Exception (try, IOException)
import Control.Monad (when)
import Data.Maybe (isNothing)

import OntoLogic
import IR (compileRegistry, irUnmappedAxioms)
import IR.CNF (formatCNFTheory)
import IR.Clausify (clausifyTheory)
import Loader (loadRegistryWithOptions, ontologicVersion)
import Linter (lintRegistryFindingsWithSource, formatLintFinding, isLintError)
import REPL (runREPL)
import GHC.Clock (getMonotonicTime)
import Solver
    ( checkConsistencyWithOptions
    , findUnsatConceptsWithOptions
    , explainUnsatWithOptions
    , untranslatedAxioms
    , usesSmtTheory
    , clampTimeoutSeconds
    , defaultSolveTimeoutSeconds
    , arithmeticCaveat
    , resolveProver
    , solverExitCode
    , partialVerdict
    , worst
    , extractModel
    , UnsatExplanation(..)
    , SolverOptions(..)
    , Prover(..)
    , proverName
    )
import Targets (lookupTarget, targetHelp, targetEmit, targetLabel, targetName, targetWarnAs, defaultEmitOptions, EmitOptions(..), Neo4jEdition(..), parseNeo4jEdition)
import LSP (runLSPServer)
import FOLTheory (promoteFreeConstants)
import qualified Data.Map as Map

data Args = Args
  { input         :: Maybe String
  , target        :: Maybe String
  , output        :: Maybe String
  , javaPackage   :: Maybe String
  , baseIri       :: Maybe String
  , proverBackend :: Maybe String
  , neo4jEdition  :: Maybe String
  , render        :: Bool
  , replMode      :: Bool
  , cnfMode       :: Bool
  , lspMode       :: Bool
  , solveMode     :: Bool
  , warnUnmapped  :: Bool
  , explainUnsat  :: Bool
  , inspectModel  :: Bool
  , freeConstants :: Bool
  , solveTimeout  :: Maybe Int
  , solveMemory   :: Maybe Int
  , libPaths      :: [String]
  , allowAbsImports :: Bool
  }

argsParser :: ParserInfo Args
argsParser = info (helper <*> versionOpt <*> opts) fullDesc
  where
    opts = Args
      <$> optional (strOption (long "input" <> short 'i' <> help "Path to .logic file"))
      <*> optional (strOption (long "target" <> short 't' <> help targetHelp))
      <*> optional (strOption (long "output" <> short 'o' <> help "Output directory or file"))
      <*> optional (strOption (long "java-package" <> help "Java package for generated models (default: ontologic.generated)"))
      <*> optional (strOption (long "base-iri" <> metavar "IRI" <> help "Base IRI for OWL/SHACL output (default: the ontology's first namespace)"))
      <*> optional (strOption (long "prover" <> short 'p' <> help "Theorem prover backend: z3, cvc5, vampire, native, auto (default: auto)"))
      <*> optional (option neo4jEditionReader (long "neo4j-edition" <> metavar "EDITION" <> help "Neo4j Edition for constraints: community, enterprise (default: enterprise)"))
      <*> switch (long "render" <> help "Render output to image (requires mmdc or d2 CLI installed)")
      <*> switch (long "repl" <> help "Start interactive ontology REPL session")
      <*> switch (long "cnf" <> help "Emit ontology clausal normal form (CNF) theory to stdout")
      <*> switch (long "lsp" <> help "Start Language Server Protocol (LSP) stdio server")
      <*> switch (long "solve" <> help "Run SMT solver consistency and satisfiability check")
      <*> switch (long "warn-unmapped" <> help "Warn about unmapped complex/relational axioms during lint or compilation")
      <*> switch (long "explain-unsat" <> help "Explain UNSAT contradictions via SMT-LIB2 unsatisfiable core extraction")
      <*> switch (long "inspect-model" <> help "Print full SMT model valuation for satisfiable ontologies")
      <*> switch (long "free-constants" <> help "Treat undeclared free variables in axioms as Entity constants")
      <*> optional (option positiveInt (long "solve-timeout" <> short 'T' <> metavar "SECONDS" <> help "Solver time limit in seconds, a positive integer (enforced for Z3, CVC5, Vampire, and Native)"))
      <*> optional (option positiveInt (long "solve-memory" <> metavar "MB" <> help "Solver memory limit in megabytes, a positive integer (Z3 only; ignored with a warning for other provers)"))
      <*> many (strOption (long "lib-path" <> metavar "DIR" <> help "Extra directory searched for imports (repeatable; also $ONTOLOGIC_PATH)"))
      <*> switch (long "allow-absolute-imports" <> help "Permit absolute paths in (import ...) declarations (refused by default)")

    versionOpt = infoOption ("ontologic " ++ ontologicVersion) (long "version" <> help "Show version")

-- | Reject 0 and negatives: backends disagree on what they mean (Z3 reads -T:0 as
--   "no limit", System.Timeout reads 0 as "already expired").
neo4jEditionReader :: ReadM String
neo4jEditionReader = eitherReader $ \s -> case parseNeo4jEdition s of
    Just _  -> Right s
    Nothing -> Left ("unknown Neo4j edition '" ++ s ++ "'; expected community or enterprise")

positiveInt :: ReadM Int
positiveInt = eitherReader $ \s -> case reads s of
    [(n, "")] | n > (0 :: Integer) -> Right (fromInteger (min n 2147483647))
    _ -> Left ("expected a positive integer, got '" ++ s ++ "'")

main :: IO ()
main = do
    args <- execParser argsParser
    if lspMode args || target args == Just "lsp"
        then runLSPServer
        else if replMode args || target args == Just "repl"
        then runREPL
        else case input args of
            Nothing -> putStrLn "Error: --input is required (or use --repl / --lsp)" >> exitFailure
            Just inpFile -> do
                loadRes <- loadRegistryWithOptions (allowAbsImports args) (libPaths args) inpFile
                case loadRes of
                    Left err -> do
                        putStrLn err
                        exitFailure
                    Right (rawRegistry, sourceTable) -> do
                        let registry = if freeConstants args
                                       then promoteFreeConstants rawRegistry
                                       else rawRegistry
                            findings = lintRegistryFindingsWithSource sourceTable registry
                            errors = map formatLintFinding (filter isLintError findings)
                            warnings = map formatLintFinding (filter (not . isLintError) findings)
                        mapM_ putStrLn warnings
                        if not (null errors)
                            then mapM_ putStrLn errors >> exitFailure
                            else if cnfMode args
                                 then putStrLn (formatCNFTheory (clausifyTheory registry))
                                 else if solveMode args || target args == Just "solve"
                                 then runSolverCheck (freeConstants args) (explainUnsat args) (inspectModel args) (proverBackend args) (solveTimeout args) (solveMemory args) registry
                                 else case (maybe "lint" id (target args), output args) of
                                     ("lint", _) -> processTarget (warnUnmapped args) sourceTable "lint" "." (javaPackage args) (baseIri args) (neo4jEdition args) (render args) registry
                                     (t, Just out) -> processTarget (warnUnmapped args) sourceTable t out (javaPackage args) (baseIri args) (neo4jEdition args) (render args) registry
                                     (t, Nothing) -> putStrLn ("Error: --output is required for target: " ++ t) >> exitFailure

runSolverCheck :: Bool -> Bool -> Bool -> Maybe String -> Maybe Int -> Maybe Int -> Registry -> IO ()
runSolverCheck isFreeConsts showExplain showModel maybeP maybeTimeout maybeMem reg =
    case resolveProver maybeP of
        Left msg -> putStrLn msg >> exitFailure
        Right prover -> do
            started <- getMonotonicTime
            let effectiveSeconds = maybe defaultSolveTimeoutSeconds clampTimeoutSeconds maybeTimeout
                solverOpts = SolverOptions
                    { optTimeoutSeconds = Just effectiveSeconds
                    , optMemoryLimitMb  = maybeMem
                    }
            case (maybeMem, prover) of
                (Just _, Z3) -> return ()
                (Just _, AutoProver) -> do
                    z3 <- findExecutable "z3"
                    when (isNothing z3) $
                        hPutStrLn stderr "⚠️  --solve-memory applies only to Z3, which is not on PATH; the backend that runs has no memory limit."
                (Just _, p) -> hPutStrLn stderr ("⚠️  --solve-memory is not supported by " ++ proverName p ++ " and is ignored.")
                (Nothing, _) -> return ()
            if isFreeConsts
                then putStrLn "ℹ️  Free constants mode enabled (--free-constants): undeclared free variables are treated as Entity constants."
                else return ()
            -- The notice describes the SMT-LIB theory: Vampire and the native prover do not read it.
            smtRoute <- usesSmtTheory prover
            let skipped = if smtRoute then untranslatedAxioms reg else []
            -- Consistency: can the axioms be satisfied at all?
            res <- partialVerdict (length skipped) <$> checkConsistencyWithOptions solverOpts prover reg
            case res of
                Sat _ -> do
                    putStrLn "✅ SMT Satisfiable (SAT) — Ontology is logically consistent."
                    if showModel
                        then case extractModel res of
                            Just m  -> putStrLn ("\n📋 SMT Model Valuation:\n" ++ m)
                            Nothing -> return ()
                        else return ()
                Unsat -> do
                    putStrLn "❌ SMT Unsatisfiable (UNSAT) — Logical contradiction detected!"
                    if showExplain
                        then do
                            expRes <- explainUnsatWithOptions solverOpts prover reg
                            case expRes of
                                Left err -> putStrLn ("⚠️  Could not extract unsatisfiable core: " ++ err)
                                Right expl -> do
                                    putStrLn "🔍 Unsatisfiable Core Conflicting Axioms:"
                                    mapM_ (\d -> putStrLn ("   • " ++ d)) (unsatCoreDetails expl)
                        else return ()
                Unknown out -> putStrLn $ "⚠️  SMT Solver Result (unknown): " ++ out
                SolverError err -> putStrLn $ "❌ SMT Solver Error: " ++ err
            -- The axioms the verdict does not cover come right after it.
            if null skipped then return () else do
                putStrLn ("⚠️  " ++ show (length skipped) ++ " axiom(s) were not sent to the solver:")
                mapM_ (\(ax, why) -> putStrLn ("   - " ++ show ax ++ " (" ++ why ++ ")")) skipped

            -- Coherence: which concepts can have no instance at all?
            -- The native prover has no process to kill, so the limit is one budget shared by the
            -- consistency check and the coherence sweep rather than a fresh limit for each.
            elapsed <- subtract started <$> getMonotonicTime
            let sharedBudget = prover == NativeProver || (prover == AutoProver && not smtRoute)
                limit = effectiveSeconds
                remaining = limit - ceiling elapsed
            coh <- if sharedBudget && remaining < 1
                then return (Left "the time limit was used up before the concept check could start")
                else findUnsatConceptsWithOptions
                        (if sharedBudget then solverOpts { optTimeoutSeconds = Just remaining } else solverOpts)
                        prover reg
            coherenceCode <- case coh of
                Left err -> do
                    putStrLn ("⚠️  Concept coherence check could not run: " ++ err)
                    return (ExitFailure 2)
                Right [] -> do
                    putStrLn "✅ All concepts are satisfiable (0 empty concepts)."
                    return ExitSuccess
                Right empties -> do
                    putStrLn ("❌ Unsatisfiable / empty concept(s): " ++ unwords empties)
                    return (ExitFailure 1)
            -- An all-clear from a backend without arithmetic can miss numeric conflicts: say so.
            let allClear = case (res, coh) of
                    (Sat _, _)    -> True
                    (_, Right []) -> True
                    _             -> False
            if allClear
                then arithmeticCaveat prover reg >>= mapM_ (\w -> hPutStrLn stderr ("⚠️  " ++ w))
                else return ()
            exitWith (worst [solverExitCode res, coherenceCode])

processTarget :: Bool -> SourceTable -> String -> String -> Maybe String -> Maybe String -> Maybe String -> Bool -> Registry -> IO ()
processTarget showWarn tbl "lint" _ _ _ _ _ reg = do
    if showWarn
        then warnUnmappedAxioms tbl "target models" reg
        else return ()
    putStrLn "✅ Logic Validated successfully."
processTarget showWarn tbl t out jPkg bIri nEd doRender reg =
    case lookupTarget t of
        Nothing -> putStrLn ("Unknown target: " ++ t) >> exitFailure
        Just tgt -> do
            createDirectoryIfMissing True out
            let warnLabel = if showWarn
                            then Just (maybe (targetName tgt) id (targetWarnAs tgt))
                            else targetWarnAs tgt
            mapM_ (\lbl -> warnUnmappedAxioms tbl lbl reg) warnLabel
            let edition = case nEd of
                    Just s  -> maybe Neo4jEnterprise id (parseNeo4jEdition s)
                    Nothing -> Neo4jEnterprise
                opts = defaultEmitOptions
                    { optJavaPackage = maybe (optJavaPackage defaultEmitOptions) id jPkg
                    , optBaseIri = bIri
                    , optNeo4jEdition = edition
                    }
                files = targetEmit tgt opts reg
            mapM_ (\(name, content) -> writeFile (out </> name) content) files
            putStrLn ("Generated " ++ targetLabel tgt ++ " in " ++ out)
            case (targetName tgt, files) of
                ("mermaid", [(name, _)]) -> renderIf (renderMermaid (out </> name))
                ("d2", [(name, _)])      -> renderIf (renderD2 (out </> name))
                _                        -> return ()
  where
    renderIf act = if doRender then act else putStrLn "Skipping render (use --render to generate SVG)."

warnUnmappedAxioms :: SourceTable -> String -> Registry -> IO ()
warnUnmappedAxioms tbl label reg = do
    let modelIR = compileRegistry reg
        unmapped = irUnmappedAxioms modelIR
    if null unmapped
        then return ()
        else do
            putStrLn $ "⚠️  Warning: " ++ show (length unmapped) ++ " complex / conditional axiom(s) could not be mapped to " ++ label ++ " field constraints:"
            mapM_ (\ax -> do
                let mPos = Map.lookup ("axiom:" ++ show ax) tbl
                    posPrefix = case mPos of
                        Just p  -> formatSourcePos p ++ ": warning: [WUnmappedAxiom] "
                        Nothing -> "   - "
                putStrLn $ posPrefix ++ formatFOL ax
                ) unmapped

-- Helpers for rendering
renderMermaid :: String -> IO ()
renderMermaid src = do
    let svg = src ++ ".svg"
    putStrLn $ "Rendering to " ++ svg ++ " using mmdc..."
    result <- try (callProcess "mmdc" ["-i", src, "-o", svg]) :: IO (Either IOException ())
    case result of
        Left _ -> putStrLn "⚠️  Error: 'mmdc' (Mermaid CLI) not found or failed. Install with 'npm install -g @mermaid-js/mermaid-cli'"
        Right _ -> putStrLn "✅ Rendered SVG successfully."

renderD2 :: String -> IO ()
renderD2 src = do
    let svg = src ++ ".svg"
    putStrLn $ "Rendering to " ++ svg ++ " using d2..."
    result <- try (callProcess "d2" [src, svg]) :: IO (Either IOException ())
    case result of
        Left _ -> putStrLn "⚠️  Error: 'd2' CLI not found or failed. Install from https://d2lang.com"
        Right _ -> putStrLn "✅ Rendered SVG successfully."
