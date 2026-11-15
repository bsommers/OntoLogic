module Solver
    ( SolverResult(..)
    , solverExitCode
    , partialVerdict
    , partialMessage
    , SubsumptionResult(..)
    , Prover(..)
    , SolverOptions(..)
    , defaultSolverOptions
    , RunFailure(..)
    , classifyOutput
    , classifyConsistencyOutput
    , classifyVampireOutput
    , vampireArguments
    , parseUnsatCore
    , usesEquality
    , usesSmtTheory
    , clampTimeoutSeconds
    , defaultSolveTimeoutSeconds
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
import Emitters.SMT (emitSMTDeclarationsUnbounded)
import Emitters.TPTP (emitTPTP, emitTPTPSubsumption, emitTPTPCoherence)
import FOLTheory (buildTheory, buildNamedTheory, theoryText, theorySkipped, conceptPred)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import System.Directory (findExecutable)
import System.IO.Error (isDoesNotExistError)
import Control.Exception (try, IOException)
import System.Timeout (timeout)
import Data.List (isPrefixOf, isInfixOf, nub)
import Data.Char (toLower)
import Data.Maybe (isNothing, isJust)
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

-- | Time limit applied when the caller gives none (CLI without -T, REPL, LSP).
defaultSolveTimeoutSeconds :: Int
defaultSolveTimeoutSeconds = 60

-- | Longest limit honoured: one year. Larger values are clamped so the microsecond
--   arithmetic for 'System.Timeout' and the millisecond one for cvc5 and the native
--   prover cannot overflow.
maxTimeoutSeconds :: Int
maxTimeoutSeconds = 31536000

-- | Bring a requested limit into the range every backend handles.
clampTimeoutSeconds :: Int -> Int
clampTimeoutSeconds = max 1 . min maxTimeoutSeconds

-- | The limit in force for a set of options: the clamped request, or the default.
effectiveTimeout :: SolverOptions -> Int
effectiveTimeout = maybe defaultSolveTimeoutSeconds clampTimeoutSeconds . optTimeoutSeconds

-- | Default solver options: a 60 second time limit and no memory limit.
defaultSolverOptions :: SolverOptions
defaultSolverOptions = SolverOptions
    { optTimeoutSeconds = Just defaultSolveTimeoutSeconds
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
-- Fail closed: an SMT-LIB @(error@ line other than a get-model or get-unsat-core refusal that
-- follows a verdict, and any Vampire parse failure, make the whole run a solver failure. The
-- solver carries on after a rejected assertion and answers for the rest, so such a verdict
-- would be about a different theory than the one that was sent.
classifyOutput :: String -> ExitCode -> String -> String -> Either RunFailure String
classifyOutput label code out err
    -- cvc5 --tlimit: "cvc5 interrupted by timeout." on stderr, empty stdout, SIGABRT exit.
    | "interrupted by timeout" `isInfixOf` err = Right (timedOutOutput label)
    | Just why <- vampireFailure out = Left (SolverFailed (label ++ " could not read the problem: " ++ why ++ "\n" ++ trimStart (out ++ err)))
    | Left bad <- smtVerdicts out = Left (SolverFailed (label ++ " reported an error: " ++ bad ++ "\n" ++ trimStart (out ++ err)))
    | any (`isInfixOf` out) ["SZS status", "SZS output"] = Right out
    | any (`elem` ["sat", "unsat", "unknown", "timeout"]) (map trim (lines out)) = Right out
    | code == ExitSuccess = Right out
    | otherwise = Left (SolverFailed (label ++ " failed (" ++ show code ++ "):\n" ++ trimStart (out ++ err)))

trim :: String -> String
trim = reverse . trimStart . reverse . trimStart

-- | A verdict line of an SMT-LIB solver.
data Verdict = VSat | VUnsat | VUnknown
    deriving (Eq, Show)

-- | The verdict lines of SMT-LIB output, in order. Left carries the first error line that is
--   not a refusal of get-model or get-unsat-core right after a verdict. z3 prints @timeout@
--   when -T expires; that is an unknown.
smtVerdicts :: String -> Either String [Verdict]
smtVerdicts = go False . map trim . lines
  where
    go _ [] = Right []
    go afterVerdict (l : ls)
        | Just v <- verdictOf l = (v :) <$> go True ls
        | "(error" `isPrefixOf` l =
            if afterVerdict && benignRefusal l then go True ls else Left l
        | otherwise = go False ls
    verdictOf "sat"     = Just VSat
    verdictOf "unsat"   = Just VUnsat
    verdictOf "unknown" = Just VUnknown
    verdictOf "timeout" = Just VUnknown
    verdictOf _         = Nothing
    benignRefusal l = any (`isInfixOf` map toLower l)
        [ "model is not available", "cannot get model"
        , "unsat core is not available", "cannot get unsat core" ]

-- | Exactly one verdict, or the reason there is not one.
singleVerdict :: String -> Either String Verdict
singleVerdict out = case smtVerdicts out of
    Left bad -> Left ("solver reported an error: " ++ bad)
    Right [v] -> Right v
    Right [] -> Left "solver printed no sat/unsat/unknown verdict"
    Right vs -> Left ("solver printed " ++ show (length vs) ++ " verdicts where one was expected")

-- | Why Vampire could not use the problem, if it could not: a TPTP or SMT-LIB parse failure.
vampireFailure :: String -> Maybe String
vampireFailure out = case [ l | l <- map plain (lines out), bad l ] of
    (l : _) -> Just l
    []      -> Nothing
  where
    plain = dropWhile (`elem` ("% \t\r" :: String))
    bad l = any (`isPrefixOf` l) ["Failed with", "User error", "parse error", "Parsing Error", "Parse error"]

-- | The SZS status words of Vampire output.
szsStatuses :: String -> [String]
szsStatuses out =
    [ w | l <- lines out
        , let l' = dropWhile (`elem` ("% \t" :: String)) l
        , "SZS status " `isPrefixOf` l'
        , (w : _) <- [words (drop (length ("SZS status " :: String)) l')] ]

-- | Vampire's single SZS status, falling back to a plain SMT-LIB verdict (smtcomp mode).
vampireStatus :: String -> Either String String
vampireStatus out
    | Just why <- vampireFailure out = Left ("Vampire could not read the problem: " ++ why ++ "\n" ++ out)
    | otherwise = case nub (szsStatuses out) of
        [w] -> Right w
        []  -> case singleVerdict out of
            Right VSat     -> Right "Satisfiable"
            Right VUnsat   -> Right "Unsatisfiable"
            Right VUnknown -> Right "Unknown"
            Left e         -> Left ("Vampire gave no usable answer (" ++ e ++ "):\n" ++ out)
        ws  -> Left ("Vampire printed conflicting statuses " ++ unwords ws ++ ":\n" ++ out)

-- | Statuses that mean the search ended without an answer.
vampireUnknownStatus :: String -> Bool
vampireUnknownStatus w = w `elem` ["Timeout", "GaveUp", "ResourceOut", "MemoryOut", "Incomplete", "Unknown", "Stopped"]

-- | Verdict on a consistency problem sent to Vampire. Only a status that says the axioms
--   are satisfiable or unsatisfiable is an answer; give-up statuses are unknown, anything
--   else is an error.
classifyVampireOutput :: String -> SolverResult
classifyVampireOutput out = case vampireStatus out of
    Left e -> SolverError e
    Right w
        | w `elem` ["Satisfiable", "CounterSatisfiable"] -> Sat out
        | w `elem` ["Unsatisfiable", "ContradictoryAxioms"] -> Unsat
        | vampireUnknownStatus w -> Unknown out
        | otherwise -> SolverError ("Vampire answered with unexpected status " ++ w ++ ":\n" ++ out)

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
    limited <- timeout ((effectiveTimeout opts + wallClockGraceSeconds) * 1000000) run
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
            [ "-T:" ++ show (effectiveTimeout opts) ] ++
            [ "-memory:" ++ show m | Just m <- [optMemoryLimitMb opts] ]
    in runBinary opts "Z3" "z3" (["-in"] ++ extraArgs)
-- --incremental: the coherence check uses push/pop, which cvc5 refuses without it.
-- --finite-model-find: the FOL theory is quantified, and cvc5 answers "unknown"
-- on satisfiable quantified input without finite model finding.
runProverRawWithOptions opts CVC5 =
    let extraArgs =
            [ "--tlimit=" ++ show (effectiveTimeout opts * 1000) ]
    -- Options must precede the "-" stdin marker: cvc5 ignores anything after it.
    in runBinary opts "CVC5" "cvc5" (["--lang=smt2", "--produce-models", "--produce-unsat-cores", "--incremental", "--finite-model-find"] ++ extraArgs ++ ["-"])
runProverRawWithOptions opts Vampire = \input ->
    runBinary opts "Vampire" "vampire" (vampireArguments opts input) input
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

-- | Command line for Vampire. The input syntax is always named: left to "auto", Vampire
--   retries a TPTP problem it could not parse as SMT-LIB on the already drained stdin,
--   and the empty second read has been answered as satisfiable.
vampireArguments :: SolverOptions -> String -> [String]
vampireArguments opts input
    | isSmt = ["--input_syntax", "smtlib2", "--mode", "smtcomp", "-t", secs, "/dev/stdin"]
    | otherwise = ["--input_syntax", "tptp", "--mode", "casc", "-t", secs, "/dev/stdin"]
  where
    isSmt = any (`isPrefixOf` trimStart input) [";", "(", "set-logic"]
    secs = show (effectiveTimeout opts)

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

-- | Message for a satisfiable answer that covers only part of the theory.
partialMessage :: Int -> String
partialMessage n = "The axioms that were checked are consistent, but " ++ show n
    ++ " axiom(s) could not be checked, so consistency of the whole ontology is unknown."

-- | A satisfiable answer is a verdict on the axioms actually sent. When @n@ axioms were not
--   sent, SAT becomes unknown; UNSAT stands (a contradictory subset contradicts the whole).
partialVerdict :: Int -> SolverResult -> SolverResult
partialVerdict n (Sat _) | n > 0 = Unknown (partialMessage n)
partialVerdict _ r = r

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
checkConsistencyWithOptions opts NativeProver reg
    | usesEquality reg = return (Unknown nativeEqualityMessage)
    | otherwise = do
        let cnf = clausifyTheory reg
        res <- proveResolution (nativeConfig opts) cnf
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
        Right out -> classifyVampireOutput out
checkConsistencyWithOptions opts p reg = do
    let smtCode = emitSMTForConsistency reg
    res <- runProverWithOptions opts p smtCode
    return $ case res of
        Left err -> SolverError err
        Right out -> classifyConsistencyOutput out

-- | Check consistency and satisfiability of the entire ontology registry with specified prover
checkConsistencyWith :: Prover -> Registry -> IO SolverResult
checkConsistencyWith = checkConsistencyWithOptions defaultSolverOptions

-- | Verdict on an SMT-LIB consistency run. Exactly one verdict line is an answer; an error
--   line, no verdict, or several verdicts is a solver error, never SAT.
classifyConsistencyOutput :: String -> SolverResult
classifyConsistencyOutput out = case singleVerdict out of
    Left e       -> SolverError (e ++ ":\n" ++ out)
    Right VSat   -> Sat out
    Right VUnsat -> Unsat
    Right VUnknown -> Unknown out

-- | Check consistency and satisfiability using automatic prover selection
checkConsistency :: Registry -> IO SolverResult
checkConsistency = checkConsistencyWith AutoProver

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) with specified solver options and prover
proveSubsumptionWithOptions :: SolverOptions -> Prover -> Registry -> String -> String -> IO SubsumptionResult
proveSubsumptionWithOptions opts p reg child parent
    | not (null unknown) = return (ProofError ("Unknown concept(s): " ++ unwords unknown))
    | p == NativeProver && usesEquality reg = return (ProofError nativeEqualityMessage)
    | p == NativeProver = do
        let cnf = clausifyTheory reg
            skConst = TConst ("c_subsumption_test_" ++ child)
            negGoalClauses =
                [ Clause (Set.singleton (Pos child [skConst]))
                , Clause (Set.singleton (Neg parent [skConst]))
                ]
            queryCnf = CNFTheory (Set.union (Set.fromList negGoalClauses) (getClauses cnf))
            cfg = nativeConfig opts
        res <- proveResolution cfg queryCnf
        case prStatus res of
            Proved -> return Subsumed
            Saturated -> do
                let tabCfg = defaultTableauConfig { tcMaxDepth = 10, tcMaxSteps = 200, tcTimeoutMs = Just (effectiveTimeout opts * 1000) }
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
            Right out -> case vampireStatus out of
                Left e -> ProofError e
                Right w
                    | w == "Theorem" -> Subsumed
                    | w `elem` ["CounterSatisfiable", "Satisfiable"] -> NotSubsumed out
                    | vampireUnknownStatus w -> ProofError ("Vampire could not decide (" ++ w ++ ")")
                    | otherwise -> ProofError ("Vampire answered with unexpected status " ++ w ++ ":\n" ++ out)
    | p == AutoProver = do
        let smt = "(set-logic ALL)\n(declare-sort Entity 0)\n" ++ theoryText (buildTheory reg) ++
                  "; Negated goal: some " ++ child ++ " is not a " ++ parent ++ "\n" ++
                  "(assert (exists ((x Entity)) (and (" ++ conceptPred child ++ " x) (not (" ++ conceptPred parent ++ " x)))))\n" ++
                  "(check-sat)\n(get-model)\n"
        res <- runProverRawWithOptions opts AutoProver smt
        case res of
            Right out -> return (subsumptionFromSmt out)
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
            Right out -> subsumptionFromSmt out
  where
    unknown = filter (`notElem` map fst (concepts reg)) [child, parent]

-- | Subsumption verdict from an SMT-LIB run of the negated goal: unsat proves it, sat refutes
--   it, anything else is an error.
subsumptionFromSmt :: String -> SubsumptionResult
subsumptionFromSmt out = case singleVerdict out of
    Left e         -> ProofError (e ++ ":\n" ++ out)
    Right VUnsat   -> Subsumed
    Right VSat     -> NotSubsumed out
    Right VUnknown -> ProofError ("Solver answered unknown:\n" ++ out)

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) with specified prover
proveSubsumptionWith :: Prover -> Registry -> String -> String -> IO SubsumptionResult
proveSubsumptionWith = proveSubsumptionWithOptions defaultSolverOptions

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) using AutoProver
proveSubsumption :: Registry -> String -> String -> IO SubsumptionResult
proveSubsumption = proveSubsumptionWith AutoProver

-- | Find all unsatisfiable concepts in one solver run with specified options; Left if the solver could not decide.
findUnsatConceptsWithOptions :: SolverOptions -> Prover -> Registry -> IO (Either String [String])
findUnsatConceptsWithOptions _ NativeProver reg
    | usesEquality reg = return (Left nativeEqualityMessage)
findUnsatConceptsWithOptions opts NativeProver reg = do
    let names = map compClassName (irClasses (compileRegistry reg))
        cnf = clausifyTheory reg
        baseClauses = getClauses cnf
        cfg = nativeConfig opts
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
    -- One deadline for the whole sweep: the limit bounds the call, not each concept.
    swept <- timeout (effectiveTimeout opts * 1000000) (mapM checkConcept names)
    return $ case swept of
        Nothing -> Left "Native prover timed out checking concept coherence"
        Just results -> case sequence results of
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
                Right out -> case vampireStatus out of
                    Right w
                        | w `elem` ["Unsatisfiable", "ContradictoryAxioms"] -> Right (Just c)
                        | w `elem` ["Satisfiable", "CounterSatisfiable"] -> Right Nothing
                    Right w -> Left ("Vampire check inconclusive for concept " ++ c ++ " (" ++ w ++ "):\n" ++ out)
                    Left e -> Left ("Vampire check failed for concept " ++ c ++ ": " ++ e)
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
parseUnsatConceptVerdicts names out = case smtVerdicts out of
    Left bad -> Left ("Solver reported an error, so the per-concept answers cannot be trusted: " ++ bad ++ "\n" ++ out)
    Right verdicts
        | length verdicts /= length names ->
            Left ("Expected " ++ show (length names) ++ " solver answers, got " ++ show (length verdicts) ++ ":\n" ++ out)
        | otherwise -> case [ n | (n, VUnknown) <- zip names verdicts ] of
            []       -> Right [ n | (n, VUnsat) <- zip names verdicts ]
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
    emitSMTDeclarationsUnbounded reg

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

-- | Run SMT with :produce-unsat-cores to identify conflicting axioms with specified options and prover
explainUnsatWithOptions :: SolverOptions -> Prover -> Registry -> IO (Either String UnsatExplanation)
explainUnsatWithOptions _ NativeProver reg
    | usesEquality reg = return (Left nativeEqualityMessage)
explainUnsatWithOptions opts NativeProver reg = do
    let cnf = clausifyTheory reg
        cfg = nativeConfig opts
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
        Saturated -> Left "The theory is satisfiable (saturated without refutation), so there is no unsat core."
        status    -> Left ("Native prover explanation inconclusive: " ++ show status)
explainUnsatWithOptions opts AutoProver reg = do
    let (smtCode, nameMap) = emitSMTForUnsatCore reg
    res <- runProverRawWithOptions opts AutoProver smtCode
    case res of
        Right out -> return (parseUnsatCore out nameMap)
        Left (NotInstalled _) ->
            -- Zero-dependency fallback to NativeProver!
            explainUnsatWithOptions opts NativeProver reg
        Left (SolverFailed err) -> return (Left err)
explainUnsatWithOptions opts p reg = do
    let (smtCode, nameMap) = emitSMTForUnsatCore reg
    res <- runProverWithOptions opts p smtCode
    case res of
        Left err -> return (Left err)
        Right out -> return (parseUnsatCore out nameMap)

-- | Run SMT with :produce-unsat-cores to identify conflicting axioms with specified prover
explainUnsatWith :: Prover -> Registry -> IO (Either String UnsatExplanation)
explainUnsatWith = explainUnsatWithOptions defaultSolverOptions

-- | Read the answer to @(check-sat) (get-unsat-core)@. Only an @unsat@ verdict followed by the
--   core list is a core: a @sat@ answer (with z3's "core is not available" refusal) means the
--   named theory is satisfiable and has no core, and is not an empty core.
parseUnsatCore :: String -> Map.Map String String -> Either String UnsatExplanation
parseUnsatCore out nameMap = case singleVerdict out of
    Left e -> Left ("Could not extract unsat core: " ++ e ++ ":\n" ++ out)
    Right VSat -> Left "The solver found the theory satisfiable, so there is no unsat core."
    Right VUnknown -> Left ("The solver answered unknown, so there is no unsat core:\n" ++ out)
    Right VUnsat ->
        let afterVerdict = unlines (drop 1 (dropWhile ((/= "unsat") . trim) (lines out)))
        in case balancedGroup (dropWhile (/= '(') afterVerdict) of
            Nothing -> Left ("Could not extract unsat core from solver output:\n" ++ out)
            Just inside ->
                let names = words (map (\c -> if c `elem` ("()" :: String) then ' ' else c) inside)
                in Right (UnsatExplanation names [ Map.findWithDefault n n nameMap | n <- names ])

-- | The text inside the first balanced parenthesis group at the start of a string.
balancedGroup :: String -> Maybe String
balancedGroup ('(' : rest) = go (1 :: Int) rest ""
  where
    go _ [] _ = Nothing
    go d (c : cs) acc
        | c == '(' = go (d + 1) cs (c : acc)
        | c == ')' = if d == 1 then Just (reverse acc) else go (d - 1) cs (c : acc)
        | otherwise = go d cs (c : acc)
balancedGroup _ = Nothing

-- | Emit SMT-LIB2 with :produce-unsat-cores and named assertions for tracking contradictions
emitSMTForUnsatCore :: Registry -> (String, Map.Map String String)
emitSMTForUnsatCore = buildNamedTheory

-- | Native prover settings for a set of options.
nativeConfig :: SolverOptions -> ProverConfig
nativeConfig opts = defaultConfig { cfgTimeoutMs = Just (effectiveTimeout opts * 1000) }

-- | The native resolution prover has no equality reasoning: it reads @=@ as an ordinary
--   predicate, so it can saturate (and report SAT) on theories that equality refutes, and
--   it mis-clausifies property comparisons. Any theory that uses equality is unknown to it.
usesEquality :: Registry -> Bool
usesEquality = any hasEq . axioms
  where
    hasEq f = case f of
        Eq _ _            -> True
        Predicate n _     -> n `elem` ["eq", "ne", "="]
        ForAll _ b        -> hasEq b
        Exists _ b        -> hasEq b
        TypedForAll _ _ b -> hasEq b
        TypedExists _ _ b -> hasEq b
        And a b           -> hasEq a || hasEq b
        Or a b            -> hasEq a || hasEq b
        Implies a b       -> hasEq a || hasEq b
        Iff a b           -> hasEq a || hasEq b
        Not a             -> hasEq a
        Top               -> False
        Bottom            -> False

nativeEqualityMessage :: String
nativeEqualityMessage =
    "The native prover has no equality reasoning and this theory uses equality (=, eq or ne), " ++
    "so it cannot answer. Use z3, cvc5 or vampire."

-- | Whether a prover answers from the SMT-LIB theory ('untranslatedAxioms' describes what that
--   theory leaves out). Vampire reads the TPTP encoding and the native prover the clausal one,
--   so the SMT notice does not apply to them. 'AutoProver' sends SMT-LIB to whichever external
--   solver it finds, and uses the native prover only when there is none.
usesSmtTheory :: Prover -> IO Bool
usesSmtTheory Z3           = return True
usesSmtTheory CVC5         = return True
usesSmtTheory Vampire      = return False
usesSmtTheory NativeProver = return False
usesSmtTheory AutoProver   = any isJust <$> mapM findExecutable ["z3", "cvc5", "vampire"]
