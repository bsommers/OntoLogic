{-# LANGUAGE OverloadedStrings #-}
module REPL (runREPL, evalREPLCommand, REPLState(..), initialREPLState) where

import System.IO (hFlush, stdout, isEOF)
import qualified Data.Text as T
import Text.Megaparsec (parse, errorBundlePretty)
import Data.List (isPrefixOf, intercalate)

import OntoLogic
import Parser (parseRegistry)
import Linter (lintRegistry)
import Loader (loadRegistryWithImports)
import IR (compileRegistry)
import IR.CNF (formatCNFTheory)
import IR.Clausify (clausifyTheory)
import Targets (lookupTarget, targets, targetName, targetEmit, defaultEmitOptions, EmitOptions(..))
import Solver
    ( checkConsistencyWith
    , proveSubsumptionWith
    , findUnsatConceptsWith
    , untranslatedAxioms
    , arithmeticCaveat
    , Prover(..)
    , parseProver
    , proverName
    , extractModel
    , explainUnsatWith
    , UnsatExplanation(..)
    )

data REPLState = REPLState
    { replRegistry :: Registry
    , replLoadedFile :: Maybe FilePath
    , replProver :: Prover
    , replEmitOptions :: EmitOptions
    } deriving (Show, Eq)

initialREPLState :: REPLState
initialREPLState = REPLState emptyRegistry Nothing AutoProver defaultEmitOptions

-- | Main interactive REPL loop
runREPL :: IO ()
runREPL = do
    putStrLn "╔════════════════════════════════════════════════════════════╗"
    putStrLn "║              OntoLogic Interactive REPL v1.0               ║"
    putStrLn "║   Type ':help' for commands or enter DSL expressions       ║"
    putStrLn "╚════════════════════════════════════════════════════════════╝"
    loop initialREPLState
  where
    loop state = do
        putStr "ontologic> "
        hFlush stdout
        eof <- isEOF
        if eof
            then putStrLn "\nGoodbye!"
            else do
                line <- getLine
                case trim line of
                    ":quit" -> putStrLn "Goodbye!"
                    ":q"    -> putStrLn "Goodbye!"
                    "exit"  -> putStrLn "Goodbye!"
                    ""      -> loop state
                    cmd     -> do
                        (newState, output) <- evalREPLCommand state cmd
                        putStrLn output
                        loop newState

-- | Evaluate a single REPL command or expression
evalREPLCommand :: REPLState -> String -> IO (REPLState, String)
evalREPLCommand state input
    | input `elem` [":help", ":?"] =
        return (state, unlines
            [ "Available REPL Commands:"
            , "  :load <file.logic>    Load a .logic file and all its imports"
            , "  :show                 Display active registry concepts, properties, relations"
            , "  :lint                 Run semantic linter checks"
            , "  :prover [name]        Show or set active theorem prover (z3, cvc5, vampire, native, auto)"
            , "  :cnf                  Display active registry in Clausal Normal Form (CNF)"
            , "  :solve / :check       Run theorem prover to check consistency & satisfiability"
            , "  :explain              Extract minimal unsat core explaining contradictions"
            , "  :model                Extract satisfying valuation model assignments"
            , "  :prove <A> <B>        Prove whether concept A is subsumed by concept B (A ⊑ B)"
            , "  :unsat                Detect empty/contradictory concepts using prover"
            , "  :ir                   Display compiled ModelIR representation"
            , "  :emit <target>        Emit code (" ++ intercalate ", " (map targetName targets) ++ ")"
            , "  :set <opt> <value>    Set an emit option (java-package, base-iri)"
            , "  :clear                Reset active session registry"
            , "  :quit / :q            Exit the REPL"
            , "  (def-concept ...)     Add DSL concept, property, relation, or axiom directly"
            ])

    | input == ":prover" =
        return (state, "Active SMT Prover: " ++ proverName (replProver state))

    | ":prover " `isPrefixOf` input =
        let pStr = trim (drop 8 input)
        in case parseProver pStr of
            Just p  -> return (state { replProver = p }, "✅ SMT Prover switched to: " ++ proverName p)
            Nothing -> return (state, "❌ Unknown prover backend '" ++ pStr ++ "'. Valid options: z3, cvc5, vampire, native, auto")

    | input == ":cnf" =
        let cnf = clausifyTheory (replRegistry state)
        in return (state, "Clausal Normal Form (CNF) Theory:\n" ++ formatCNFTheory cnf)

    | input == ":show" =
        let reg = replRegistry state
            report = unlines
                [ "Active Registry State:"
                , "  Concepts:   " ++ show (length (concepts reg)) ++ " -> " ++ show (map fst (concepts reg))
                , "  Properties: " ++ show (length (properties reg)) ++ " -> " ++ show (map propName (properties reg))
                , "  Relations:  " ++ show (length (relations reg)) ++ " -> " ++ show (map relName (relations reg))
                , "  Axioms:     " ++ show (length (axioms reg))
                , "  Prover:     " ++ proverName (replProver state)
                , "  Loaded:     " ++ maybe "<none>" id (replLoadedFile state)
                ]
        in return (state, report)

    | input == ":lint" =
        let errs = lintRegistry (replRegistry state)
        in if null errs
           then return (state, "✅ Semantic Linting Passed (0 errors).")
           else return (state, "❌ Linter Errors:\n" ++ unlines (map ("  - " ++) errs))

    | input == ":ir" =
        let ir = compileRegistry (replRegistry state)
        in return (state, "Compiled ModelIR:\n" ++ show ir)

    | input `elem` [":solve", ":check"] = do
        let skipped = untranslatedAxioms (replRegistry state)
            warning
              | null skipped = ""
              | otherwise = "⚠️  " ++ show (length skipped) ++ " axiom(s) were not sent to the solver:\n"
                            ++ unlines [ "   - " ++ show ax ++ " (" ++ why ++ ")" | (ax, why) <- skipped ]
        res <- checkConsistencyWith (replProver state) (replRegistry state)
        let consistency = case res of
                Sat model -> "✅ SMT Satisfiable (SAT) via " ++ proverName (replProver state) ++ " — Consistent Model Found:\n" ++ model
                Unsat -> "❌ SMT Unsatisfiable (UNSAT) via " ++ proverName (replProver state) ++ " — Logical Contradiction Detected!"
                Unknown out -> "⚠️  SMT Solver Result: " ++ out
                SolverError err -> "❌ SMT Solver Error:\n" ++ err
        -- Coherence is reported separately: a single UNSAT would name no concept.
        coh <- findUnsatConceptsWith (replProver state) (replRegistry state)
        let coherence = case coh of
                Left err -> "⚠️  Concept coherence check could not run: " ++ err
                Right [] -> "✅ All concepts are satisfiable (0 empty concepts)."
                Right empties -> "❌ Unsatisfiable / empty concept(s): " ++ unwords empties
        note <- case (res, coh) of
            (Sat _, _)    -> caveatLine state
            (_, Right []) -> caveatLine state
            _             -> return ""
        return (state, warning ++ consistency ++ "\n" ++ coherence ++ note)

    | input `elem` [":explain", ":unsat-core", ":explain-unsat"] = do
        res <- explainUnsatWith (replProver state) (replRegistry state)
        case res of
            Left err -> return (state, "❌ SMT Explanation Error:\n" ++ err)
            Right explanation ->
                if null (unsatCoreNames explanation)
                then do
                    note <- caveatLine state
                    return (state, "✅ SMT Satisfiable (SAT) — No contradictory axioms or unsat cores detected." ++ note)
                else return (state, unlines
                    [ "❌ SMT Unsatisfiable (UNSAT) — Minimal Unsat Core Identified:"
                    , "  Core Assertions: " ++ unwords (unsatCoreNames explanation)
                    , ""
                    , "Conflicting Axioms Trace:"
                    , unlines (unsatCoreDetails explanation)
                    ])

    | input `elem` [":model", ":inspect-model"] = do
        res <- checkConsistencyWith (replProver state) (replRegistry state)
        case res of
            Sat _ -> do
                note <- caveatLine state
                case extractModel res of
                    Just m  -> return (state, "✅ SMT Satisfiable (SAT) — Extracted Valuation Model:\n" ++ m ++ note)
                    Nothing -> return (state, "✅ SMT Satisfiable (SAT) — Valuation model is empty or implicit." ++ note)
            Unsat -> return (state, "❌ SMT Unsatisfiable (UNSAT) — No satisfying model exists. Run ':explain' to view the unsat core.")
            Unknown out -> return (state, "⚠️  SMT Solver Result Inconclusive: " ++ out)
            SolverError err -> return (state, "❌ SMT Solver Error:\n" ++ err)

    | ":prove " `isPrefixOf` input = do
        let args = words (trim (drop 7 input))
        case args of
            [child, parent] -> do
                res <- proveSubsumptionWith (replProver state) (replRegistry state) child parent
                case res of
                    Subsumed -> return (state, "✅ Theorem Proved via " ++ proverName (replProver state) ++ ": '" ++ child ++ "' ⊑ '" ++ parent ++ "' (Every instance of " ++ child ++ " is necessarily a " ++ parent ++ ").")
                    NotSubsumed model -> do
                        note <- caveatLine state
                        return (state, "❌ Theorem Disproved via " ++ proverName (replProver state) ++ ": '" ++ child ++ "' is NOT subsumed by '" ++ parent ++ "'. Counterexample model:\n" ++ model ++ note)
                    ProofError err -> return (state, "❌ Solver Error in Subsumption Proof:\n" ++ err)
            _ -> return (state, "⚠️  Usage: :prove <ConceptA> <ConceptB>")

    | input == ":unsat" = do
        res <- findUnsatConceptsWith (replProver state) (replRegistry state)
        case res of
            Left err -> return (state, "❌ SMT Solver Error:\n" ++ err)
            Right [] -> do
                note <- caveatLine state
                return (state, "✅ All concepts are satisfiable (0 empty concepts) via " ++ proverName (replProver state) ++ "." ++ note)
            Right unsatList -> return (state, "❌ Unsatisfiable / Contradictory Concepts Found via " ++ proverName (replProver state) ++ ":\n" ++ unlines (map ("  - " ++) unsatList))

    | input == ":clear" =
        return (initialREPLState { replProver = replProver state }, "✨ Session registry cleared.")

    | ":load " `isPrefixOf` input = do
        let path = trim (drop 6 input)
        res <- loadRegistryWithImports path
        case res of
            Left err -> return (state, "❌ Error loading " ++ path ++ ": " ++ err)
            Right reg -> do
                let errs = lintRegistry reg
                    msg = if null errs
                          then "✅ Loaded " ++ path ++ " (" ++ show (length (concepts reg)) ++ " concepts, 0 lint errors)."
                          else "⚠️ Loaded " ++ path ++ " with " ++ show (length errs) ++ " lint warnings."
                return (state { replRegistry = reg, replLoadedFile = Just path }, msg)

    | ":set " `isPrefixOf` input =
        case words (trim (drop 5 input)) of
            ["java-package", pkg] ->
                return ( state { replEmitOptions = (replEmitOptions state) { optJavaPackage = pkg } }
                       , "✅ java-package set to " ++ pkg )
            ["base-iri", iri] ->
                return ( state { replEmitOptions = (replEmitOptions state) { optBaseIri = Just iri } }
                       , "✅ base-iri set to " ++ iri )
            _ -> return (state, "⚠️  Usage: :set java-package <pkg> | :set base-iri <iri>")

    | ":emit " `isPrefixOf` input =
        let target = trim (drop 6 input)
        in case lookupTarget target of
            Nothing  -> return (state, "❌ Unknown emit target: " ++ target ++ ". Valid targets: " ++ intercalate ", " (map targetName targets))
            Just tgt -> return (state, concatMap snd (targetEmit tgt (replEmitOptions state) (replRegistry state)))

    | otherwise = do
        -- Try parsing as DSL S-expression
        case parse parseRegistry "<repl>" (T.pack input) of
            Left err -> return (state, "❌ Parse Error:\n" ++ errorBundlePretty err)
            Right directReg ->
                let merged = mergeRegistries (replRegistry state) directReg
                    errs = lintRegistry merged
                    lintMsg = if null errs then "" else "\n⚠️  Lint warning: " ++ head errs
                in return (state { replRegistry = merged }, "Added to registry." ++ lintMsg)

-- | Extra line for an all-clear answer from a prover without arithmetic; empty when none applies.
caveatLine :: REPLState -> IO String
caveatLine state = maybe "" ("\n⚠️  " ++) <$> arithmeticCaveat (replProver state) (replRegistry state)

trim :: String -> String
trim = f . f
  where f = reverse . dropWhile (`elem` (" \t\r\n" :: String))

