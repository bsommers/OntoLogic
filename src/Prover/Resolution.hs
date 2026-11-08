{-# LANGUAGE DeriveGeneric #-}
module Prover.Resolution
    ( ClauseId(..)
    , Derivation(..)
    , DerivationNode(..)
    , ProverConfig(..)
    , defaultConfig
    , ProverStatus(..)
    , ProverResult(..)
    , ProofTrace
    , clauseWeight
    , resolveClauses
    , factorClause
    , equalityResolveClause
    , runResolution
    , proveResolution
    , isRefutable
    , formatProofTrace
    ) where

import Control.Exception (evaluate)
import Data.List (intercalate)
import qualified Data.Map as Map
import qualified Data.Set as Set
import GHC.Generics (Generic)
import System.Timeout (timeout)

import IR.CNF
import Prover.Unification

-- | Unique identifier for a clause in the derivation graph
newtype ClauseId = ClauseId Int
    deriving (Show, Eq, Ord, Generic)

-- | Derivation rule and parent references justifying a clause
data Derivation
    = InputAxiom
    | ResolveStep !ClauseId !ClauseId
    | FactorStep !ClauseId
    | EqualityResolveStep !ClauseId
    deriving (Show, Eq, Generic)

-- | A node in the derivation DAG containing clause and provenance
data DerivationNode = DerivationNode
    { dnId     :: !ClauseId
    , dnClause :: !Clause
    , dnRule   :: !Derivation
    } deriving (Show, Eq, Generic)

-- | Step-by-step refutation derivation trace
type ProofTrace = [DerivationNode]

-- | Prover search limits and configuration
data ProverConfig = ProverConfig
    { cfgMaxSteps   :: !Int         -- ^ Maximum given-clause iterations
    , cfgMaxClauses :: !Int         -- ^ Maximum retained clauses before stopping
    , cfgTimeoutMs  :: !(Maybe Int) -- ^ Optional wall-clock timeout in milliseconds
    } deriving (Show, Eq, Generic)

-- | Default robust configuration for interactive and batch reasoning
defaultConfig :: ProverConfig
defaultConfig = ProverConfig
    { cfgMaxSteps   = 2000
    , cfgMaxClauses = 10000
    , cfgTimeoutMs  = Just 5000
    }

-- | Outcome status of resolution saturation
data ProverStatus
    = Proved       -- ^ Refutation found (empty clause derived, theory is UNSAT)
    | Saturated    -- ^ Unprocessed queue exhausted without contradiction (theory is SAT)
    | StepLimit    -- ^ Iteration step limit exceeded
    | ClauseLimit  -- ^ Retained clause budget exceeded
    | Timeout      -- ^ Wall-clock execution timeout fired
    deriving (Show, Eq, Generic)

-- | Overall proof search result
data ProverResult = ProverResult
    { prStatus      :: !ProverStatus
    , prSteps       :: !Int
    , prClausesGen  :: !Int
    , prProofTrace  :: !(Maybe ProofTrace)
    , prEmptyClause :: !(Maybe ClauseId)
    } deriving (Show, Eq, Generic)

-- | Syntactic symbol-weight heuristic for clause ordering in the DISCOUNT queue
clauseWeight :: Clause -> Int
clauseWeight (Clause lits) = foldr (\lit acc -> acc + litWeight lit) 0 lits
  where
    litWeight (Pos _ args)  = 1 + sum (map termWeight args)
    litWeight (Neg _ args)  = 1 + sum (map termWeight args)
    litWeight (EqT t1 t2)   = 1 + termWeight t1 + termWeight t2
    litWeight (NeqT t1 t2)  = 1 + termWeight t1 + termWeight t2

    termWeight (TVar _)         = 1
    termWeight (TConst _)       = 1
    termWeight (TFunc _ args)   = 1 + sum (map termWeight args)
    termWeight (TSkolem _ args) = 1 + sum (map termWeight args)

-- | Ordered wrapper for priority queue selection in the given-clause loop
data QueuedNode = QueuedNode
    { qnWeight :: !Int
    , qnId     :: !ClauseId
    , qnNode   :: !DerivationNode
    } deriving (Eq, Show)

instance Ord QueuedNode where
    compare (QueuedNode w1 (ClauseId id1) _) (QueuedNode w2 (ClauseId id2) _) =
        compare w1 w2 <> compare id1 id2

-- | First-Order Binary Resolution rule:
-- Given clauses C1 and C2, standardize apart their variables and resolve any
-- complementary literal pair (L1, ~L2) whose MGU exists.
resolveClauses :: DerivationNode -> DerivationNode -> [(Clause, Derivation)]
resolveClauses n1 n2 =
    let (c1Std, c2Std) = standardizeApart (dnClause n1) (dnClause n2)
        lits1 = Set.toList (getLiterals c1Std)
        lits2 = Set.toList (getLiterals c2Std)
        id1 = dnId n1
        id2 = dnId n2
        resolvents =
            [ (resolvent, ResolveStep id1 id2)
            | l1 <- lits1
            , l2 <- lits2
            , Just subst <- [unifyComplementary l1 l2]
            , let rem1 = Set.delete l1 (getLiterals c1Std)
            , let rem2 = Set.delete l2 (getLiterals c2Std)
            , let resolvedLits = Set.map (applySubstLit subst) (Set.union rem1 rem2)
            , let resolvent = canonicalizeClause (Clause resolvedLits)
            , not (isTautology resolvent)
            ]
    in nubClauses resolvents

-- | First-Order Positive / General Factoring rule:
-- Unifies any two distinct literals in a clause that share the same polarity and predicate,
-- producing a contracted factor clause. Essential for resolution refutation completeness.
factorClause :: DerivationNode -> [(Clause, Derivation)]
factorClause node =
    let c = dnClause node
        cid = dnId node
        lits = Set.toList (getLiterals c)
        factors =
            [ (factored, FactorStep cid)
            | (i, l1) <- zip [(0 :: Int)..] lits
            , (j, l2) <- zip [(0 :: Int)..] lits
            , i < j
            , Just subst <- [unifyLiterals l1 l2]
            , let remLits = Set.delete l2 (getLiterals c)
            , let factoredLits = Set.map (applySubstLit subst) remLits
            , let factored = canonicalizeClause (Clause factoredLits)
            , not (isTautology factored)
            , factored /= c
            ]
    in nubClauses factors

-- | First-Order Equality Resolution rule:
-- Eliminates negative equality literals of the form (t1 != t2) if t1 and t2 can be unified.
equalityResolveClause :: DerivationNode -> [(Clause, Derivation)]
equalityResolveClause node =
    let c = dnClause node
        cid = dnId node
        lits = Set.toList (getLiterals c)
        resolvents =
            [ (resClause, EqualityResolveStep cid)
            | l@(NeqT t1 t2) <- lits
            , Just subst <- [unifyTerms t1 t2]
            , let remLits = Set.delete l (getLiterals c)
            , let resLits = Set.map (applySubstLit subst) remLits
            , let resClause = canonicalizeClause (Clause resLits)
            , not (isTautology resClause)
            ]
    in nubClauses resolvents

-- | Helper to deduplicate clauses produced by inference rules
nubClauses :: [(Clause, Derivation)] -> [(Clause, Derivation)]
nubClauses xs = go Set.empty xs
  where
    go _ [] = []
    go seen ((c, d):rest)
        | Set.member c seen = go seen rest
        | otherwise         = (c, d) : go (Set.insert c seen) rest

-- | Internal mutable search state of the DISCOUNT given-clause loop
data ProverState = ProverState
    { psNextId      :: !Int
    , psUnprocessed :: !(Set.Set QueuedNode)
    , psProcessed   :: !(Map.Map ClauseId DerivationNode)
    , psClauses     :: !(Map.Map ClauseId DerivationNode)
    , psClauseIndex :: !(Set.Set Clause)
    , psSteps       :: !Int
    }

-- | Pure Given-Clause (DISCOUNT loop) saturation engine
runResolution :: ProverConfig -> CNFTheory -> ProverResult
runResolution cfg theory =
    let initialClauses = Set.toList (getClauses theory)
        (initialState, mEmpty) = initProverState initialClauses
    in case mEmpty of
        Just emptyNode ->
            ProverResult
                { prStatus      = Proved
                , prSteps       = 0
                , prClausesGen  = psNextId initialState - 1
                , prProofTrace  = Just [emptyNode]
                , prEmptyClause = Just (dnId emptyNode)
                }
        Nothing -> saturationLoop cfg initialState

-- | Initialize prover state from input axioms
initProverState :: [Clause] -> (ProverState, Maybe DerivationNode)
initProverState clauses = go 1 Set.empty Map.empty Set.empty Set.empty clauses
  where
    go nextId unproc clausesMap clauseIdx _seen [] =
        ( ProverState
            { psNextId      = nextId
            , psUnprocessed = unproc
            , psProcessed   = Map.empty
            , psClauses     = clausesMap
            , psClauseIndex = clauseIdx
            , psSteps       = 0
            }
        , Nothing
        )
    go nextId unproc clausesMap clauseIdx seen (c:cs) =
        let cNorm = canonicalizeClause c
        in if isEmptyClause cNorm
            then
                let cid = ClauseId nextId
                    node = DerivationNode cid cNorm InputAxiom
                in ( ProverState
                        { psNextId      = nextId + 1
                        , psUnprocessed = unproc
                        , psProcessed   = Map.empty
                        , psClauses     = Map.insert cid node clausesMap
                        , psClauseIndex = Set.insert cNorm clauseIdx
                        , psSteps       = 0
                        }
                   , Just node
                   )
            else if isTautology cNorm || Set.member cNorm seen
                then go nextId unproc clausesMap clauseIdx seen cs
                else
                    let cid = ClauseId nextId
                        node = DerivationNode cid cNorm InputAxiom
                        qn = QueuedNode (clauseWeight cNorm) cid node
                    in go (nextId + 1)
                          (Set.insert qn unproc)
                          (Map.insert cid node clausesMap)
                          (Set.insert cNorm clauseIdx)
                          (Set.insert cNorm seen)
                          cs

-- | Main saturation loop iterating over the lightest given clause
saturationLoop :: ProverConfig -> ProverState -> ProverResult
saturationLoop cfg st
    | psSteps st >= cfgMaxSteps cfg =
        ProverResult
            { prStatus      = StepLimit
            , prSteps       = psSteps st
            , prClausesGen  = psNextId st - 1
            , prProofTrace  = Nothing
            , prEmptyClause = Nothing
            }
    | psNextId st >= cfgMaxClauses cfg =
        ProverResult
            { prStatus      = ClauseLimit
            , prSteps       = psSteps st
            , prClausesGen  = psNextId st - 1
            , prProofTrace  = Nothing
            , prEmptyClause = Nothing
            }
    | Set.null (psUnprocessed st) =
        ProverResult
            { prStatus      = Saturated
            , prSteps       = psSteps st
            , prClausesGen  = psNextId st - 1
            , prProofTrace  = Nothing
            , prEmptyClause = Nothing
            }
    | otherwise =
        let (QueuedNode _ givenId givenNode, remUnproc) = Set.deleteFindMin (psUnprocessed st)
            givenClause = dnClause givenNode
        in if isEmptyClause givenClause
            then
                let trace = extractProofTrace givenId (psClauses st)
                in ProverResult
                    { prStatus      = Proved
                    , prSteps       = psSteps st + 1
                    , prClausesGen  = psNextId st - 1
                    , prProofTrace  = Just trace
                    , prEmptyClause = Just givenId
                    }
            else
                -- Forward Subsumption: discard given clause if already subsumed by a processed clause
                if any (\p -> subsumes (dnClause p) givenClause) (Map.elems (psProcessed st))
                    then saturationLoop cfg st { psUnprocessed = remUnproc, psSteps = psSteps st + 1 }
                    else
                        -- Backward Subsumption: prune unprocessed clauses subsumed by the given clause
                        let prunedUnproc = Set.filter
                                (\qn -> not (subsumes givenClause (dnClause (qnNode qn)) && givenClause /= dnClause (qnNode qn)))
                                remUnproc
                            -- Generate resolvents and factors against processed clauses
                            procList = Map.elems (psProcessed st)
                            newDerivations =
                                concatMap (\p -> resolveClauses givenNode p ++ resolveClauses p givenNode) procList
                                ++ resolveClauses givenNode givenNode
                                ++ factorClause givenNode
                                ++ equalityResolveClause givenNode
                            -- Incorporate candidate clauses into prover state
                            (st', mEmpty) = incorporateCandidates st
                                { psUnprocessed = prunedUnproc
                                , psProcessed   = Map.insert givenId givenNode (psProcessed st)
                                , psSteps       = psSteps st + 1
                                }
                                newDerivations
                        in case mEmpty of
                            Just (emptyId, emptyNode) ->
                                let allClauses = Map.insert emptyId emptyNode (psClauses st')
                                    trace = extractProofTrace emptyId allClauses
                                in ProverResult
                                    { prStatus      = Proved
                                    , prSteps       = psSteps st'
                                    , prClausesGen  = psNextId st' - 1
                                    , prProofTrace  = Just trace
                                    , prEmptyClause = Just emptyId
                                    }
                            Nothing -> saturationLoop cfg st'

-- | Incorporate newly derived candidate clauses into the search state
incorporateCandidates :: ProverState -> [(Clause, Derivation)] -> (ProverState, Maybe (ClauseId, DerivationNode))
incorporateCandidates st candidates = go (psNextId st) (psUnprocessed st) (psClauses st) (psClauseIndex st) candidates
  where
    go nextId unproc allClauses clauseIdx [] =
        ( st { psNextId = nextId, psUnprocessed = unproc, psClauses = allClauses, psClauseIndex = clauseIdx }
        , Nothing
        )
    go nextId unproc allClauses clauseIdx ((c, deriv):rest) =
        let cNorm = canonicalizeClause c
        in if isTautology cNorm
            then go nextId unproc allClauses clauseIdx rest
            else if Set.member cNorm clauseIdx
                then go nextId unproc allClauses clauseIdx rest
                else if any (\p -> subsumes (dnClause p) cNorm) (Map.elems (psProcessed st))
                    then go nextId unproc allClauses clauseIdx rest
                    else if isEmptyClause cNorm
                        then
                            let cid = ClauseId nextId
                                node = DerivationNode cid cNorm deriv
                            in ( st { psNextId      = nextId + 1
                                    , psUnprocessed = unproc
                                    , psClauses     = Map.insert cid node allClauses
                                    , psClauseIndex = Set.insert cNorm clauseIdx
                                    }
                               , Just (cid, node)
                               )
                        else
                            let cid = ClauseId nextId
                                node = DerivationNode cid cNorm deriv
                                qn = QueuedNode (clauseWeight cNorm) cid node
                            in go (nextId + 1)
                                  (Set.insert qn unproc)
                                  (Map.insert cid node allClauses)
                                  (Set.insert cNorm clauseIdx)
                                  rest

-- | Extract the minimal ancestor derivation DAG from empty clause back to axioms
extractProofTrace :: ClauseId -> Map.Map ClauseId DerivationNode -> ProofTrace
extractProofTrace targetId allNodes =
    let needed = collectAncestors (Set.singleton targetId) [targetId]
    in [ n | (cid, n) <- Map.toAscList allNodes, Set.member cid needed ]
  where
    collectAncestors visited [] = visited
    collectAncestors visited (curr:rest) =
        case Map.lookup curr allNodes of
            Nothing -> collectAncestors visited rest
            Just (DerivationNode _ _ rule) ->
                let parents = case rule of
                        InputAxiom                 -> []
                        ResolveStep p1 p2          -> [p1, p2]
                        FactorStep p               -> [p]
                        EqualityResolveStep p      -> [p]
                    newParents = filter (\p -> not (Set.member p visited)) parents
                    visited' = foldr Set.insert visited newParents
                in collectAncestors visited' (newParents ++ rest)

-- | Format a step-by-step refutation proof trace
formatProofTrace :: ProofTrace -> String
formatProofTrace nodes = intercalate "\n" (map formatNode nodes)
  where
    formatNode (DerivationNode (ClauseId cid) cl rule) =
        let clStr = if isEmptyClause cl then "[]" else formatClause cl
            ruleStr = case rule of
                InputAxiom                 -> "[Input Axiom]"
                ResolveStep (ClauseId p1) (ClauseId p2) ->
                    "[Resolution " ++ show p1 ++ ", " ++ show p2 ++ "]"
                FactorStep (ClauseId p)    ->
                    "[Factor " ++ show p ++ "]"
                EqualityResolveStep (ClauseId p) ->
                    "[Equality Resolution " ++ show p ++ "]"
            prefix = show cid ++ "."
            paddedPrefix = prefix ++ replicate (max 1 (5 - length prefix)) ' '
            paddedClause = clStr ++ replicate (max 1 (45 - length clStr)) ' '
        in paddedPrefix ++ paddedClause ++ ruleStr

-- | Top-level solver execution wrapping the saturation engine with timeout protection
proveResolution :: ProverConfig -> CNFTheory -> IO ProverResult
proveResolution cfg theory =
    case cfgTimeoutMs cfg of
        Nothing -> do
            let res = runResolution cfg theory
            evaluate (forceProverResult res)
        Just ms -> do
            let us = ms * 1000
            mRes <- timeout us (evaluate (forceProverResult (runResolution cfg theory)))
            case mRes of
                Just res -> return res
                Nothing  -> return ProverResult
                    { prStatus      = Timeout
                    , prSteps       = 0
                    , prClausesGen  = 0
                    , prProofTrace  = Nothing
                    , prEmptyClause = Nothing
                    }

-- | Force critical fields of ProverResult to WHNF for timeout evaluation
forceProverResult :: ProverResult -> ProverResult
forceProverResult res =
    prStatus res `seq` prSteps res `seq` prClausesGen res `seq` res

-- | Convenience helper returning True if the theory is refutable (UNSAT)
isRefutable :: CNFTheory -> Bool
isRefutable theory = prStatus (runResolution defaultConfig theory) == Proved
