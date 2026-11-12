module Solver
    ( SolverResult(..)
    , solverExitCode
    , SubsumptionResult(..)
    , Prover(..)
    , SolverOptions(..)
    , defaultSolverOptions
    , RunFailure(..)
    , classifyOutput
    , runBinary
    , wallClockGraceSeconds
    , parseProver
    , resolveProver
    , proverName
    , runProver
    , runProverWithOptions
    , runProverRaw
    , runProverRawWithOptions
    , runZ3
    , runCVC5
    , runVampire
    , runVampireTPTP
    , checkConsistency
    , checkConsistencyWith
    , checkConsistencyWithOptions
    , proveSubsumption
    , proveSubsumptionWith
    , proveSubsumptionWithOptions
    , findUnsatConcepts
    , findUnsatConceptsWith
    , findUnsatConceptsWithOptions
    , emitSMTForConsistency
    , emitSMTBase
    , untranslatedAxioms
    , backendWithoutArithmetic
    , arithmeticCaveat
    , worst
    , extractModel
    , UnsatExplanation(..)
    , explainUnsat
    , explainUnsatWith
    , explainUnsatWithOptions
    ) where

import OntoLogic
import IR
import qualified Data.Set as Set
import IR.CNF (CNFTerm(..), Literal(..), Clause(..), CNFTheory(..), formatClause, getClauses)
import IR.Clausify (clausifyTheory)
import Prover.Tableau (proveTableauClauses, defaultTableauConfig, TableauConfig(..), TableauResult(..), formatCounterModel)
import Prover.Resolution (proveResolution, defaultConfig, ProverConfig(..), ProverResult(..), ProverStatus(..), DerivationNode(..), Derivation(..), ClauseId(..))
import Emitters.SMT (emitSMTDeclarations)
import Emitters.TPTP (emitTPTP, emitTPTPSubsumption, emitTPTPCoherence)
import FOLTheory (buildTheory, buildNamedTheory, theoryText, theorySkipped, conceptPred)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (findExecutable)
import System.IO.Error (isDoesNotExistError)
import Control.Exception (try, IOException)
import System.Timeout (timeout)
import Data.List (isPrefixOf, isInfixOf)
import Data.Char (toLower)
import Data.Maybe (isNothing)
import qualified Data.Map as Map

-- | Supported automated theorem prover backends
data Prover
    = Z3
    | CVC5
    | Vampire
    | NativeProver
    | AutoProver
    deriving (Show, Eq, Read)

-- | Options for solver execution, including timeouts and memory limits
data SolverOptions = SolverOptions
    { optTimeoutSeconds :: Maybe Int
    , optMemoryLimitMb  :: Maybe Int
    } deriving (Show, Eq)

-- | Default solver options: no explicit timeout or memory limit (defer to prover defaults)
defaultSolverOptions :: SolverOptions
defaultSolverOptions = SolverOptions
    { optTimeoutSeconds = Nothing
    , optMemoryLimitMb  = Nothing
    }

-- | Parse prover string name into a Prover type
parseProver :: String -> Maybe Prover
parseProver s = case map toLower s of
    "z3"        -> Just Z3
    "cvc5"      -> Just CVC5
    "vampire"   -> Just Vampire
    "native"    -> Just NativeProver
    "auto"      -> Just AutoProver
    _           -> Nothing

-- | Human-readable name for the prover
proverName :: Prover -> String
proverName Z3           = "Z3"
proverName CVC5         = "CVC5"
proverName Vampire      = "Vampire"
proverName NativeProver = "Native"
proverName AutoProver   = "Auto (Z3/CVC5/Vampire/Native)"

data RunFailure
    = NotInstalled String   -- ^ executable not found; AutoProver may try the next one
    | SolverFailed String   -- ^ solver ran and failed; report as-is
    deriving (Show, Eq)

failureMessage :: RunFailure -> String
failureMessage (NotInstalled m) = m
failureMessage (SolverFailed m) = m

trimStart :: String -> String
trimStart = dropWhile (`elem` (" \t\r\n" :: String))

-- | Decide whether a finished solver run produced a usable answer.
-- A leading sat/unsat/unknown verdict is kept even with a non-zero exit (e.g. get-model after unsat).
classifyOutput :: String -> ExitCode -> String -> String -> Either RunFailure String
classifyOutput label code out err
    -- cvc5 --tlimit: "cvc5 interrupted by timeout." on stderr, empty stdout, SIGABRT exit.
    | "interrupted by timeout" `isInfixOf` err = Right (timedOutOutput label)
    | any (`isPrefixOf` trimmed) ["sat", "unsat", "unknown"] = Right out
    | any (`isInfixOf` out) ["SZS status", "SZS output"] = Right out
    | any (`elem` ["sat", "unsat", "unknown"]) (map trimStart (lines out)) = Right out
    | code == ExitSuccess && not ("(error" `isInfixOf` out) = Right out
    | otherwise = Left (SolverFailed (label ++ " failed (" ++ show code ++ "):\n" ++ trimStart (out ++ err)))
  where
    trimmed = trimStart out

-- | A run that hit its time limit, phrased as an SMT "unknown" verdict so every
--   caller classifies it as Unknown (exit 2) rather than a solver failure.
timedOutOutput :: String -> String
timedOutOutput label = "unknown\n; " ++ label ++ " exceeded the solver time limit\n"

-- | Extra seconds past --solve-timeout before the child process is killed. The
--   solver's own limit normally fires first and gives a cleaner answer; the
--   wall-clock limit is the backstop that applies identically to every backend.
wallClockGraceSeconds :: Int
wallClockGraceSeconds = 2

runBinary :: SolverOptions -> String -> FilePath -> [String] -> String -> IO (Either RunFailure String)
runBinary opts label exe args smtInput = do
    -- readProcessWithExitCode terminates the child when interrupted by timeout.
    let run = try (readProcessWithExitCode exe args smtInput) :: IO (Either IOException (ExitCode, String, String))
    limited <- case optTimeoutSeconds opts of
        Nothing -> Just <$> run
        Just s  -> timeout ((s + wallClockGraceSeconds) * 1000000) run
    return $ case limited of
      Nothing -> Right (timedOutOutput label)
      Just result -> case result of
        Left ex
            | isDoesNotExistError ex ->
                Left (NotInstalled ("Failed to execute " ++ label ++ " solver: " ++ show ex ++ "\nEnsure '" ++ exe ++ "' is installed and available in PATH."))
            | otherwise -> Left (SolverFailed ("Failed to execute " ++ label ++ " solver: " ++ show ex))
        Right (code, out, err) -> classifyOutput label code out err

runProverRawWithOptions :: SolverOptions -> Prover -> String -> IO (Either RunFailure String)
runProverRawWithOptions opts Z3 =
    let extraArgs =
            [ "-T:" ++ show s | Just s <- [optTimeoutSeconds opts] ] ++
            [ "-memory:" ++ show m | Just m <- [optMemoryLimitMb opts] ]
    in runBinary opts "Z3" "z3" (["-in"] ++ extraArgs)
-- --incremental: the coherence check uses push/pop, which cvc5 refuses without it.
-- --finite-model-find: the FOL theory is quantified, and cvc5 answers "unknown"
-- on satisfiable quantified input without finite model finding.
runProverRawWithOptions opts CVC5 =
    let extraArgs =
            [ "--tlimit=" ++ show (s * 1000) | Just s <- [optTimeoutSeconds opts] ]
    -- Options must precede the "-" stdin marker: cvc5 ignores anything after it.
    in runBinary opts "CVC5" "cvc5" (["--lang=smt2", "--produce-models", "--produce-unsat-cores", "--incremental", "--finite-model-find"] ++ extraArgs ++ ["-"])
runProverRawWithOptions opts Vampire = \input ->
    let isSmt = any (`isPrefixOf` trimStart input) [";", "(", "set-logic"]
        timeoutSec = maybe "10" show (optTimeoutSeconds opts)
        args = if isSmt
               then ["--input_syntax", "smtlib2", "--mode", "smtcomp"] ++
                    maybe [] (\s -> ["-t", show s]) (optTimeoutSeconds opts) ++
                    ["/dev/stdin"]
               else ["--mode", "casc", "-t", timeoutSec, "/dev/stdin"]
    in runBinary opts "Vampire" "vampire" args input
runProverRawWithOptions _ NativeProver = \_ ->
    return (Left (SolverFailed "NativeProver operates on in-memory AST/CNF. Use checkConsistency, proveSubsumption, or findUnsatConcepts."))
runProverRawWithOptions opts AutoProver = \smtInput -> tryEach smtInput [Z3, CVC5, Vampire]
  where
    -- Fall through only when a solver is not installed; a real failure is reported.
    tryEach _ [] = return (Left (NotInstalled "No compatible SMT solver found in PATH (tried z3, cvc5, vampire). Please install Z3 or CVC5."))
    tryEach smtIn (p:ps) = do
        r <- runProverRawWithOptions opts p smtIn
        case r of
            Left (NotInstalled _) -> tryEach smtIn ps
            other -> return other

-- | Run raw SMT-LIB2 or TPTP code through the selected prover backend
runProverRaw :: Prover -> String -> IO (Either RunFailure String)
runProverRaw = runProverRawWithOptions defaultSolverOptions

-- | Run raw SMT-LIB2 or TPTP code through the selected prover backend with options
runProverWithOptions :: SolverOptions -> Prover -> String -> IO (Either String String)
runProverWithOptions opts p smtInput = either (Left . failureMessage) Right <$> runProverRawWithOptions opts p smtInput

-- | Run raw SMT-LIB2 code through the selected SMT solver backend
runProver :: Prover -> String -> IO (Either String String)
runProver = runProverWithOptions defaultSolverOptions

-- | Parse a --prover value; Nothing means the default (auto).
resolveProver :: Maybe String -> Either String Prover
resolveProver Nothing = Right AutoProver
resolveProver (Just s) =
    maybe (Left ("Unknown prover '" ++ s ++ "'. Valid options: z3, cvc5, vampire, native, auto")) Right (parseProver s)

-- | CLI exit code for a consistency result: 0 = SAT, 1 = UNSAT or error, 2 = unknown.
solverExitCode :: SolverResult -> ExitCode
solverExitCode (Sat _)         = ExitSuccess
solverExitCode Unsat           = ExitFailure 1
solverExitCode (SolverError _) = ExitFailure 1
solverExitCode (Unknown _)     = ExitFailure 2

-- | The most severe of several exit codes: failure beats unknown beats success.
worst :: [ExitCode] -> ExitCode
worst codes
    | ExitFailure 1 `elem` codes = ExitFailure 1
    | ExitFailure 2 `elem` codes = ExitFailure 2
    | otherwise = ExitSuccess

-- | Axioms the SMT encoding leaves out, with the reason.
untranslatedAxioms :: Registry -> [(FOL, String)]
untranslatedAxioms = theorySkipped . buildTheory

-- | The backend that answers for this prover, when that backend has no arithmetic and so reads
--   ordering comparisons as uninterpreted predicates: the native prover, and Vampire on the
--   TPTP encoding. 'AutoProver' reaches the native prover only when no external solver is on
--   PATH; otherwise it sends SMT-LIB, where comparisons keep their arithmetic meaning.
backendWithoutArithmetic :: Prover -> IO (Maybe Prover)
backendWithoutArithmetic NativeProver = return (Just NativeProver)
backendWithoutArithmetic Vampire      = return (Just Vampire)
backendWithoutArithmetic AutoProver   = do
    found <- mapM findExecutable ["z3", "cvc5", "vampire"]
    return (if all isNothing found then Just NativeProver else Nothing)
backendWithoutArithmetic _            = return Nothing

-- | Caveat for an all-clear answer (SAT, every concept satisfiable, not subsumed) from a backend
--   without arithmetic, on a theory that uses ordering comparisons. Such an answer can be wrong
--   where the conflict needs arithmetic, so callers show this next to it. UNSAT needs no caveat:
--   the background axioms given to these backends hold for every number.
arithmeticCaveat :: Prover -> Registry -> IO (Maybe String)
arithmeticCaveat p reg
    | usesOrderingComparison reg = fmap caveat <$> backendWithoutArithmetic p
    | otherwise = return Nothing
  where
    caveat backend =
        who backend ++ " checks this theory without arithmetic: it catches numeric bounds that " ++
        "directly exclude each other, but can miss conflicts that need arithmetic. " ++
        "Confirm this answer with z3 or cvc5."
    who NativeProver = "The native prover"
    who other        = proverName other

-- | Run raw SMT-LIB2 code through the Z3 solver via standard input
runZ3 :: String -> IO (Either String String)
runZ3 = runProver Z3

-- | Run raw SMT-LIB2 code through the CVC5 solver via standard input
runCVC5 :: String -> IO (Either String String)
runCVC5 = runProver CVC5

-- | Run raw SMT-LIB2 code through the Vampire prover via standard input
runVampire :: String -> IO (Either String String)
runVampire = runProver Vampire

-- | Run raw TPTP FOF problem through the Vampire prover
runVampireTPTP :: String -> IO (Either String String)
runVampireTPTP = runProver Vampire

-- | Check consistency and satisfiability of the entire ontology registry with specified solver options and prover
checkConsistencyWithOptions :: SolverOptions -> Prover -> Registry -> IO SolverResult
checkConsistencyWithOptions opts NativeProver reg = do
    let cnf = clausifyTheory reg
        cfg = case optTimeoutSeconds opts of
            Just s  -> defaultConfig { cfgTimeoutMs = Just (s * 1000) }
            Nothing -> defaultConfig
    res <- proveResolution cfg cnf
    return $ case prStatus res of
        Proved    -> Unsat
        Saturated -> Sat "Satisfiable (clausal theory saturated without refutation)"
        Timeout     -> Unknown "Native resolution prover timed out"
        StepLimit   -> Unknown "Native resolution prover step limit exceeded"
        ClauseLimit -> Unknown "Native resolution prover clause limit exceeded"
checkConsistencyWithOptions opts AutoProver reg = do
    let smtCode = emitSMTForConsistency reg
    res <- runProverRawWithOptions opts AutoProver smtCode
    case res of
        Right out -> return $ classifyConsistencyOutput out
        Left (NotInstalled _) ->
            -- Zero-dependency fallback to NativeProver!
            checkConsistencyWithOptions opts NativeProver reg
        Left (SolverFailed err) -> return (SolverError err)
checkConsistencyWithOptions opts Vampire reg = do
    let tptp = emitTPTP reg
    res <- runProverWithOptions opts Vampire tptp
    return $ case res of
        Left err -> SolverError err
        Right out
            | any (`isInfixOf` out) ["SZS status Satisfiable", "SZS status CounterSatisfiable"] || any (== "sat") (map trimStart (lines out)) -> Sat out
            | "SZS status Unsatisfiable" `isInfixOf` out || any (== "unsat") (map trimStart (lines out)) -> Unsat
            | "SZS status Timeout" `isInfixOf` out || any (== "unknown") (map trimStart (lines out)) -> Unknown out
            | otherwise -> SolverError out
checkConsistencyWithOptions opts p reg = do
    let smtCode = emitSMTForConsistency reg
    res <- runProverWithOptions opts p smtCode
    return $ case res of
        Left err -> SolverError err
        Right out -> classifyConsistencyOutput out

-- | Check consistency and satisfiability of the entire ontology registry with specified prover
checkConsistencyWith :: Prover -> Registry -> IO SolverResult
checkConsistencyWith = checkConsistencyWithOptions defaultSolverOptions

classifyConsistencyOutput :: String -> SolverResult
classifyConsistencyOutput out =
    let trimmed = trimStart out
    in if "sat" `isPrefixOf` trimmed || any (== "sat") (map trimStart (lines out))
       then Sat out
       else if "unsat" `isPrefixOf` trimmed || any (== "unsat") (map trimStart (lines out))
       then Unsat
       else Unknown out

-- | Check consistency and satisfiability using automatic prover selection
checkConsistency :: Registry -> IO SolverResult
checkConsistency = checkConsistencyWith AutoProver

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) with specified solver options and prover
proveSubsumptionWithOptions :: SolverOptions -> Prover -> Registry -> String -> String -> IO SubsumptionResult
proveSubsumptionWithOptions opts p reg child parent
    | not (null unknown) = return (ProofError ("Unknown concept(s): " ++ unwords unknown))
    | p == NativeProver = do
        let cnf = clausifyTheory reg
            skConst = TConst ("c_subsumption_test_" ++ child)
            negGoalClauses =
                [ Clause (Set.singleton (Pos child [skConst]))
                , Clause (Set.singleton (Neg parent [skConst]))
                ]
            queryCnf = CNFTheory (Set.union (Set.fromList negGoalClauses) (getClauses cnf))
            cfg = case optTimeoutSeconds opts of
                Just s  -> defaultConfig { cfgTimeoutMs = Just (s * 1000) }
                Nothing -> defaultConfig
        res <- proveResolution cfg queryCnf
        case prStatus res of
            Proved -> return Subsumed
            Saturated -> do
                let tabCfg = case optTimeoutSeconds opts of
                        Just s  -> defaultTableauConfig { tcMaxDepth = 10, tcMaxSteps = 200, tcTimeoutMs = Just (s * 1000) }
                        Nothing -> defaultTableauConfig { tcMaxDepth = 10, tcMaxSteps = 200 }
                tabRes <- proveTableauClauses tabCfg negGoalClauses
                return $ case trCounterModel tabRes of
                    Just m  -> NotSubsumed (formatCounterModel m)
                    Nothing -> NotSubsumed ("Countermodel (saturated): " ++ child ++ " does not imply " ++ parent)
            Timeout     -> return (ProofError "Native resolution prover timed out")
            StepLimit   -> return (ProofError "Native resolution prover step limit exceeded")
            ClauseLimit -> return (ProofError "Native resolution prover clause limit exceeded")
    | p == Vampire = do
        let tptp = emitTPTPSubsumption reg child parent
        res <- runProverWithOptions opts Vampire tptp
        return $ case res of
            Left err -> ProofError err
            Right out
                | "SZS status Theorem" `isInfixOf` out -> Subsumed
                | any (`isInfixOf` out) ["SZS status CounterSatisfiable", "SZS status Satisfiable"] -> NotSubsumed out
                | "SZS status Timeout" `isInfixOf` out -> ProofError "Vampire proof timed out"
                | otherwise -> ProofError out
    | p == AutoProver = do
        let smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory reg) ++
                  "; Negated goal: some " ++ child ++ " is not a " ++ parent ++ "\n" ++
                  "(assert (exists ((x Entity)) (and (" ++ conceptPred child ++ " x) (not (" ++ conceptPred parent ++ " x)))))\n" ++
                  "(check-sat)\n(get-model)\n"
        res <- runProverRawWithOptions opts AutoProver smt
        case res of
            Right out
                | "unsat" `isPrefixOf` trimStart out || any (== "unsat") (map trimStart (lines out)) -> return Subsumed
                | "sat" `isPrefixOf` trimStart out || any (== "sat") (map trimStart (lines out))     -> return (NotSubsumed out)
                | otherwise                                                                          -> return (ProofError out)
            Left (NotInstalled _) ->
                -- Zero-dependency fallback to NativeProver!
                proveSubsumptionWithOptions opts NativeProver reg child parent
            Left (SolverFailed err) -> return (ProofError err)
    | otherwise = do
        let smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory reg) ++
                  "; Negated goal: some " ++ child ++ " is not a " ++ parent ++ "\n" ++
                  "(assert (exists ((x Entity)) (and (" ++ conceptPred child ++ " x) (not (" ++ conceptPred parent ++ " x)))))\n" ++
                  "(check-sat)\n(get-model)\n"
        res <- runProverWithOptions opts p smt
        return $ case res of
            Left err -> ProofError err
            Right out
                | "unsat" `isPrefixOf` trimStart out || any (== "unsat") (map trimStart (lines out)) -> Subsumed
                | "sat" `isPrefixOf` trimStart out || any (== "sat") (map trimStart (lines out))     -> NotSubsumed out
                | otherwise                          -> ProofError out
  where
    unknown = filter (`notElem` map fst (concepts reg)) [child, parent]

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) with specified prover
proveSubsumptionWith :: Prover -> Registry -> String -> String -> IO SubsumptionResult
proveSubsumptionWith = proveSubsumptionWithOptions defaultSolverOptions

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) using AutoProver
proveSubsumption :: Registry -> String -> String -> IO SubsumptionResult
proveSubsumption = proveSubsumptionWith AutoProver

-- | Find all unsatisfiable concepts in one solver run with specified options; Left if the solver could not decide.
findUnsatConceptsWithOptions :: SolverOptions -> Prover -> Registry -> IO (Either String [String])
findUnsatConceptsWithOptions opts NativeProver reg = do
    let names = map compClassName (irClasses (compileRegistry reg))
        cnf = clausifyTheory reg
        baseClauses = getClauses cnf
        cfg = case optTimeoutSeconds opts of
            Just s  -> defaultConfig { cfgTimeoutMs = Just (s * 1000) }
            Nothing -> defaultConfig
        checkConcept c = do
            let skConst = TConst ("c_coherence_test_" ++ c)
                conceptClause = Clause (Set.singleton (Pos c [skConst]))
                queryCnf = CNFTheory (Set.insert conceptClause baseClauses)
            res <- proveResolution cfg queryCnf
            return $ case prStatus res of
                Proved    -> Right (Just c)
                Saturated -> Right Nothing
                Timeout     -> Left ("Native prover timeout for concept " ++ c)
                StepLimit   -> Left ("Native prover step limit exceeded for concept " ++ c)
                ClauseLimit -> Left ("Native prover clause limit exceeded for concept " ++ c)
    results <- mapM checkConcept names
    return $ case sequence results of
        Left err -> Left err
        Right matches -> Right [ c | Just c <- matches ]
findUnsatConceptsWithOptions opts AutoProver reg = do
    let names = map compClassName (irClasses (compileRegistry reg))
        check c = "(push 1)\n(assert (exists ((x Entity)) (" ++ conceptPred c ++ " x)))\n(check-sat)\n(pop 1)\n"
        smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory reg) ++ concatMap check names
    res <- runProverRawWithOptions opts AutoProver smt
    case res of
        Right out -> return $ parseUnsatConceptVerdicts names out
        Left (NotInstalled _) ->
            -- Zero-dependency fallback to NativeProver!
            findUnsatConceptsWithOptions opts NativeProver reg
        Left (SolverFailed err) -> return (Left err)
findUnsatConceptsWithOptions opts Vampire reg = do
    let names = map compClassName (irClasses (compileRegistry reg))
        checkConcept c = do
            let tptp = emitTPTPCoherence reg c
            res <- runProverWithOptions opts Vampire tptp
            return $ case res of
                Left err -> Left err
                Right out
                    | "SZS status Unsatisfiable" `isInfixOf` out -> Right (Just c)
                    | any (`isInfixOf` out) ["SZS status Satisfiable", "SZS status CounterSatisfiable"] -> Right Nothing
                    | otherwise -> Left ("Vampire check inconclusive for concept " ++ c ++ ":\n" ++ out)
    results <- mapM checkConcept names
    return $ case sequence results of
        Left err -> Left err
        Right matches -> Right [ c | Just c <- matches ]
findUnsatConceptsWithOptions opts p reg = do
    let names = map compClassName (irClasses (compileRegistry reg))
        check c = "(push 1)\n(assert (exists ((x Entity)) (" ++ conceptPred c ++ " x)))\n(check-sat)\n(pop 1)\n"
        smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory reg) ++ concatMap check names
    res <- runProverWithOptions opts p smt
    return $ case res of
        Left err -> Left err
        Right out -> parseUnsatConceptVerdicts names out

-- | Find all unsatisfiable concepts in one solver run; Left if the solver could not decide.
findUnsatConceptsWith :: Prover -> Registry -> IO (Either String [String])
findUnsatConceptsWith = findUnsatConceptsWithOptions defaultSolverOptions

parseUnsatConceptVerdicts :: [String] -> String -> Either String [String]
parseUnsatConceptVerdicts names out =
    let verdicts = filter (`elem` ["sat", "unsat", "unknown"]) (map (filter (`notElem` (" \t\r" :: String))) (lines out))
    in if length verdicts /= length names
       then Left ("Expected " ++ show (length names) ++ " solver answers, got " ++ show (length verdicts) ++ ":\n" ++ out)
       else case [ n | (n, "unknown") <- zip names verdicts ] of
           []       -> Right [ n | (n, "unsat") <- zip names verdicts ]
           unknowns -> Left ("Solver answered unknown for: " ++ unwords unknowns)

-- | Find all unsatisfiable (logically empty/contradictory) concepts using AutoProver
findUnsatConcepts :: Registry -> IO (Either String [String])
findUnsatConcepts = findUnsatConceptsWith AutoProver

-- | Emit SMT-LIB2 for consistency checking
-- Non-emptiness is NOT asserted here; that is the coherence check (findUnsatConceptsWith).
emitSMTForConsistency :: Registry -> String
emitSMTForConsistency reg =
    emitSMTBase reg ++
    "; First-order theory\n" ++ theoryText (buildTheory reg) ++
    "(check-sat)\n(get-model)\n"

-- | Emit base SMT declarations without check-sat
emitSMTBase :: Registry -> String
emitSMTBase reg =
    "; SMT-LIB2 Base Declarations generated by OntoLogic Solver\n" ++
    "(set-logic ALL)\n\n" ++
    emitSMTDeclarations reg

-- | Extract model valuation s-expression from a Sat result
extractModel :: SolverResult -> Maybe String
extractModel (Sat out) =
    let lns = lines out
    in if "SZS output start Definitions and Model Updates." `isInfixOf` out
       then
           let modelLines = takeWhile (/= "% SZS output end Definitions and Model Updates.")
                          . drop 1
                          . dropWhile (/= "% SZS output start Definitions and Model Updates.")
                          $ lns
           in Just (unlines modelLines)
       else case dropWhile (/= "sat") (map trimStart lns) of
           ("sat":rest) -> Just (unlines rest)
           _            -> Just out
extractModel _ = Nothing

-- | Result of an unsatisfiable core explanation
data UnsatExplanation = UnsatExplanation
    { unsatCoreNames   :: [String]
    , unsatCoreDetails :: [String]
    } deriving (Show, Eq)

-- | Run SMT with :produce-unsat-cores to identify conflicting axioms with default AutoProver
explainUnsat :: Registry -> IO (Either String UnsatExplanation)
explainUnsat = explainUnsatWith AutoProver

-- | Parse S-expression list of unsat core identifiers from solver output (supporting both Z3 and CVC5)
extractCoreNames :: String -> [String]
extractCoreNames out =
    let ws = words out
    in case dropWhile (/= "unsat") ws of
        ("unsat" : rest) ->
            let body = unwords rest
                inside = takeWhile (/= ')') (dropWhile (/= '(') body)
            in words (filter (`notElem` ("()" :: String)) inside)
        _ -> case [ l | l <- lines (trimStart out), "(" `isPrefixOf` l && not ("(error" `isPrefixOf` l) ] of
            (c:_) -> words (filter (`notElem` ("():\r\n" :: String)) c)
            []    -> []

-- | Run SMT with :produce-unsat-cores to identify conflicting axioms with specified options and prover
explainUnsatWithOptions :: SolverOptions -> Prover -> Registry -> IO (Either String UnsatExplanation)
explainUnsatWithOptions opts NativeProver reg = do
    let cnf = clausifyTheory reg
        cfg = case optTimeoutSeconds opts of
            Just s  -> defaultConfig { cfgTimeoutMs = Just (s * 1000) }
            Nothing -> defaultConfig
    res <- proveResolution cfg cnf
    return $ case prStatus res of
        Proved ->
            case prProofTrace res of
                Just trace ->
                    let inputNodes = [ node | node <- trace, dnRule node == InputAxiom ]
                        names = [ "axiom_" ++ show n | DerivationNode (ClauseId n) _ _ <- inputNodes ]
                        details = [ formatClause (dnClause node) | node <- inputNodes ]
                    in Right (UnsatExplanation names details)
                Nothing -> Right (UnsatExplanation [] [])
        Saturated -> Right (UnsatExplanation [] [])
        status    -> Left ("Native prover explanation inconclusive: " ++ show status)
explainUnsatWithOptions opts AutoProver reg = do
    let (smtCode, nameMap) = emitSMTForUnsatCore reg
    res <- runProverRawWithOptions opts AutoProver smtCode
    case res of
        Right out -> parseUnsatCoreOutput out nameMap
        Left (NotInstalled _) ->
            -- Zero-dependency fallback to NativeProver!
            explainUnsatWithOptions opts NativeProver reg
        Left (SolverFailed err) -> return (Left err)
explainUnsatWithOptions opts p reg = do
    let (smtCode, nameMap) = emitSMTForUnsatCore reg
    res <- runProverWithOptions opts p smtCode
    case res of
        Left err -> return (Left err)
        Right out -> parseUnsatCoreOutput out nameMap

-- | Run SMT with :produce-unsat-cores to identify conflicting axioms with specified prover
explainUnsatWith :: Prover -> Registry -> IO (Either String UnsatExplanation)
explainUnsatWith = explainUnsatWithOptions defaultSolverOptions

parseUnsatCoreOutput :: String -> Map.Map String String -> IO (Either String UnsatExplanation)
parseUnsatCoreOutput out nameMap =
    let trimmed = trimStart out
    in if "sat" `isPrefixOf` trimmed
       then return (Right (UnsatExplanation [] []))
       else
           let names = extractCoreNames out
               details = [ Map.findWithDefault n n nameMap | n <- names ]
           in if null names && "unsat" `isPrefixOf` trimmed
              then return (Right (UnsatExplanation [] []))
              else if null names
              then return (Left ("Could not extract unsat core from solver output:\n" ++ out))
              else return (Right (UnsatExplanation names details))

-- | Emit SMT-LIB2 with :produce-unsat-cores and named assertions for tracking contradictions
emitSMTForUnsatCore :: Registry -> (String, Map.Map String String)
emitSMTForUnsatCore = buildNamedTheory
