module Linter.SAT
    ( SatResult(..)
    , DerivationChain(..)
    , Lit(..)
    , Clause(..)
    , ClauseOrigin(..)
    , Rule(..)
    , checkOntologySAT
    , checkConceptCoherence
    , runHornSAT
    , runDPLL
    ) where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.IntMap.Strict as IntMap
import qualified Data.IntSet as IntSet
import Data.List (intercalate, foldl')
import Data.Maybe (mapMaybe)
import OntoLogic

-- | Propositional literal: positive or negative atom.
data Lit = Pos String | Neg String
    deriving (Show, Eq, Ord)

-- | Provenance of a clause or rule for diagnostic explanations.
data ClauseOrigin =
      InheritanceOrigin Name Name       -- ^ child -> parent (def-concept Child Parent)
    | DisjointAxiom Int FOL             -- ^ disjointness axiom (e.g. implies A (not B))
    | SubsumptionAxiom Int FOL          -- ^ implication axiom (e.g. implies A B)
    | PropositionalAxiom Int FOL        -- ^ general clausal axiom
    | HypothesisOrigin Name             -- ^ assumed instance of concept C
    deriving (Show, Eq)

-- | A propositional clause in Conjunctive Normal Form (CNF).
data Clause = Clause
    { clauseLits   :: [Lit]
    , clauseOrigin :: ClauseOrigin
    } deriving (Show, Eq)

-- | A Horn rule: (premises -> head) or (premises -> bot)
data Rule = Rule
    { ruleId       :: Int
    , rulePremises :: [Int]        -- ^ atom IDs in premise (conjunction)
    , ruleHead     :: Maybe Int    -- ^ Just head atom ID, or Nothing for bot (goal/conflict)
    , ruleOrigin   :: ClauseOrigin
    } deriving (Show, Eq)

-- | Result of SAT / Horn consistency check.
data SatResult =
      SatConsistent (Set.Set Name)
    | SatContradiction DerivationChain
    deriving (Show, Eq)

-- | Traceable explanation of a semantic contradiction.
data DerivationChain = DerivationChain
    { chainConcept    :: Maybe Name
    , chainDerived    :: Name
    , chainPath       :: [Name]
    , chainConflict   :: Name
    , chainOrigin     :: ClauseOrigin
    , chainFormatted  :: String
    } deriving (Show, Eq)

-- ----------------------------------------------------------------------------
-- AST to CNF & Horn Rule Conversion
-- ----------------------------------------------------------------------------

-- | Strip the quantifier prefix from a FOL formula, keeping concept-sort guards:
--   (forall ((x C)) f) becomes (implies (C x) f) and (exists ((x C)) f) becomes (and (C x) f).
--   Sorts that are not concepts (Int, String, ...) carry no guard.
stripQuantifiers :: [Name] -> FOL -> FOL
stripQuantifiers cs = go
  where
    go (ForAll _ f)        = go f
    go (Exists _ f)        = go f
    go (TypedForAll v s f)
        | s `elem` cs      = Implies (Predicate s [Var v]) (go f)
        | otherwise        = go f
    go (TypedExists v s f)
        | s `elem` cs      = And (Predicate s [Var v]) (go f)
        | otherwise        = go f
    go f                   = f

-- | Count the existential quantifiers in the formula's outer quantifier prefix.
countExistentials :: FOL -> Int
countExistentials (ForAll _ f)        = countExistentials f
countExistentials (TypedForAll _ _ f) = countExistentials f
countExistentials (Exists _ f)        = 1 + countExistentials f
countExistentials (TypedExists _ _ f) = 1 + countExistentials f
countExistentials _                   = 0

-- | Convert formula to Negation Normal Form (NNF).
toNNF :: FOL -> FOL
toNNF (Not (Not f))            = toNNF f
toNNF (Not (And f1 f2))        = Or (toNNF (Not f1)) (toNNF (Not f2))
toNNF (Not (Or f1 f2))         = And (toNNF (Not f1)) (toNNF (Not f2))
toNNF (Not (Implies f1 f2))    = And (toNNF f1) (toNNF (Not f2))
toNNF (Not (Iff f1 f2))        = Or (And (toNNF f1) (toNNF (Not f2))) (And (toNNF (Not f1)) (toNNF f2))
toNNF (Not Top)                = Bottom
toNNF (Not Bottom)             = Top
toNNF (Implies f1 f2)          = Or (toNNF (Not f1)) (toNNF f2)
toNNF (Iff f1 f2)              = And (toNNF (Implies f1 f2)) (toNNF (Implies f2 f1))
toNNF (And f1 f2)              = And (toNNF f1) (toNNF f2)
toNNF (Or f1 f2)               = Or (toNNF f1) (toNNF f2)
toNNF f                        = f

-- | Extract a propositional literal from an atomic FOL formula.
folToLit :: FOL -> Maybe Lit
folToLit (Predicate p [Var _])        = Just (Pos p)
folToLit (Predicate p [Constant c])   = Just (Pos (p ++ ":" ++ c))
folToLit (Predicate p [])             = Just (Pos p)
folToLit (Not (Predicate p [Var _]))  = Just (Neg p)
folToLit (Not (Predicate p [Constant c])) = Just (Neg (p ++ ":" ++ c))
folToLit (Not (Predicate p []))       = Just (Neg p)
folToLit _                            = Nothing

-- | Convert NNF formula to CNF clauses (list of clauses, each clause a list of Lits).
toCNFClauses :: FOL -> [[Lit]]
toCNFClauses Top    = []
toCNFClauses Bottom = [[]]
toCNFClauses (And f1 f2) = toCNFClauses f1 ++ toCNFClauses f2
toCNFClauses (Or f1 f2)  =
    let c1 = toCNFClauses f1
        c2 = toCNFClauses f2
    in case (c1, c2) of
        ([], _) -> []
        (_, []) -> []
        _       -> [ l1 ++ l2 | l1 <- c1, l2 <- c2 ]
toCNFClauses litFol =
    case folToLit litFol of
        Just lit -> [[lit]]
        Nothing  -> []

-- | Convert a Registry into CNF clauses: the universal clauses (inheritance and
--   universally quantified axioms) and one clause group per existential axiom.
--
--   Collapsing all individuals into one is sound for UNSAT only when at most one
--   existential witness is involved, so each existential group must be checked
--   together with the universal clauses, never with another existential group.
registryToClauses :: Registry -> ([Clause], [[Clause]])
registryToClauses reg = (inheritanceClauses ++ concat universals, existentials)
  where
    conceptNames = map fst (concepts reg)
    inheritanceClauses =
        [ Clause [Neg child, Pos parent] (InheritanceOrigin child parent)
        | (child, Just parent) <- concepts reg
        ]
    indexed = zip [1..] (axioms reg)
    universals   = [ axiomClauses idx ax | (idx, ax) <- indexed, countExistentials ax == 0 ]
    existentials = [ axiomClauses idx ax | (idx, ax) <- indexed, countExistentials ax == 1 ]
    axiomClauses idx ax =
        map (\lits -> Clause lits (classifyOrigin idx ax lits)) (toCNFClauses (toNNF (stripQuantifiers conceptNames ax)))
    classifyOrigin idx ax lits =
        case lits of
            [Neg _, Neg _] -> DisjointAxiom idx ax
            [Neg _, Pos _] -> SubsumptionAxiom idx ax
            _              -> PropositionalAxiom idx ax

-- ----------------------------------------------------------------------------
-- Fast Horn / Unit Resolution Engine (Dowling-Gallier)
-- ----------------------------------------------------------------------------

-- | Atom index mapping for fast integer array/map operations.
data AtomEnv = AtomEnv
    { atomToId :: Map.Map String Int
    , idToAtom :: Map.Map Int String
    } deriving (Show, Eq)

buildAtomEnv :: [Clause] -> AtomEnv
buildAtomEnv clauses = AtomEnv a2i i2a
  where
    atoms = Set.toList $ Set.fromList [ a | c <- clauses, lit <- clauseLits c, let a = litAtom lit ]
    litAtom (Pos a) = a
    litAtom (Neg a) = a
    a2i = Map.fromList (zip atoms [0..])
    i2a = Map.fromList (zip [0..] atoms)

-- | Convert CNF clauses into Horn rules where possible.
-- Clauses with at most 1 positive literal are Horn.
clausesToHornRules :: AtomEnv -> [Clause] -> ([Rule], [Clause])
clausesToHornRules env clauses = foldl' partitionClause ([], []) (zip [0..] clauses)
  where
    partitionClause (horns, nonHorns) (rIdx, c) =
        let (posLits, negLits) = foldr splitLit ([], []) (clauseLits c)
            splitLit (Pos a) (ps, ns) = (a:ps, ns)
            splitLit (Neg a) (ps, ns) = (ps, a:ns)
            lookupId a = Map.findWithDefault (-1) a (atomToId env)
            premIds = map lookupId negLits
        in case posLits of
            [] -> -- Goal clause: negLits -> bot
                let rule = Rule rIdx premIds Nothing (clauseOrigin c)
                in (rule : horns, nonHorns)
            [h] -> -- Definite clause: negLits -> h
                let rule = Rule rIdx premIds (Just (lookupId h)) (clauseOrigin c)
                in (rule : horns, nonHorns)
            _ -> -- Non-Horn clause (disjunction with >= 2 positives)
                (horns, c : nonHorns)

-- | Solve Horn rules under an optional concept hypothesis.
-- Uses linear-time forward chaining with derivation history.
runHornSAT :: AtomEnv -> [Rule] -> Maybe Name -> SatResult
runHornSAT env rules maybeHyp =
    let hypId = maybeHyp >>= \h -> Map.lookup h (atomToId env)
        -- Index: premise atom ID -> [Rule]
        premiseIndex = foldl' (\m r ->
            foldl' (\m' p -> IntMap.insertWith (++) p [r] m') m (rulePremises r)
            ) IntMap.empty rules

        -- Rule premise counters: ruleId -> unsatisfied premises count
        initialCounters = IntMap.fromList [ (ruleId r, length (rulePremises r)) | r <- rules ]

        -- Initial facts queue and derived set
        (initialQueue, initialDerived, initialDeriv) = case hypId of
            Just h -> ([h], IntSet.singleton h, IntMap.singleton h (Rule (-1) [] (Just h) (HypothesisOrigin (maybe "" id maybeHyp)), []))
            Nothing -> ([], IntSet.empty, IntMap.empty)

        -- Add static unit facts (premises = [])
        (initQ, initD, initDeriv, initCounters) =
            foldl' (\(q, d, deriv, cnts) r ->
                if null (rulePremises r)
                then case ruleHead r of
                    Just h ->
                        if IntSet.member h d
                        then (q, d, deriv, cnts)
                        else (h : q, IntSet.insert h d, IntMap.insert h (r, []) deriv, cnts)
                    Nothing -> (q, d, deriv, cnts)
                else (q, d, deriv, cnts)
            ) (initialQueue, initialDerived, initialDeriv, initialCounters) rules

    in solveLoop initQ initD initDeriv initCounters premiseIndex
  where
    lookupAtom i = Map.findWithDefault (show i) i (idToAtom env)

    solveLoop [] derived _ _ _ =
        SatConsistent (Set.fromList [ lookupAtom i | i <- IntSet.toList derived ])

    solveLoop (curr:qRest) derived deriv counters pIndex =
        let triggeredRules = IntMap.findWithDefault [] curr pIndex
            (conflict, newQ, newD, newDeriv, newCounters) =
                foldl' (processRule curr) (Nothing, qRest, derived, deriv, counters) triggeredRules
        in case conflict of
            Just (conflictRule, premList) ->
                SatContradiction (buildDerivationChain env maybeHyp conflictRule premList newDeriv)
            Nothing ->
                solveLoop newQ newD newDeriv newCounters pIndex

    processRule _ (Just c, q, d, drv, cnts) _ = (Just c, q, d, drv, cnts)
    processRule _ (Nothing, q, d, drv, cnts) r =
        let rId = ruleId r
            currentCnt = IntMap.findWithDefault 0 rId cnts
            newCnt = currentCnt - 1
            updatedCnts = IntMap.insert rId newCnt cnts
        in if newCnt == 0
            then case ruleHead r of
                Nothing -> -- Goal clause falsified: all premises true!
                    (Just (r, rulePremises r), q, d, drv, updatedCnts)
                Just h ->
                    if IntSet.member h d
                    then (Nothing, q, d, drv, updatedCnts)
                    else
                        let q' = h : q
                            d' = IntSet.insert h d
                            drv' = IntMap.insert h (r, rulePremises r) drv
                        in (Nothing, q', d', drv', updatedCnts)
            else (Nothing, q, d, drv, updatedCnts)

-- | Construct diagnostic derivation chain from forward chaining history.
buildDerivationChain :: AtomEnv -> Maybe Name -> Rule -> [Int] -> IntMap.IntMap (Rule, [Int]) -> DerivationChain
buildDerivationChain env mHyp r prems derivMap =
    let lookupAtom i = Map.findWithDefault (show i) i (idToAtom env)
        premNames = map lookupAtom prems
        origin = ruleOrigin r

        -- Trace derivation path backward from atom to hypothesis
        traceToHyp start = reverse (go start (Set.singleton start))
          where
            go curr visited
                | Just curr == (mHyp >>= \h -> Map.lookup h (atomToId env)) = [lookupAtom curr]
                | otherwise = case IntMap.lookup curr derivMap of
                    Nothing -> [lookupAtom curr]
                    Just (_, []) -> [lookupAtom curr]
                    Just (_, p:_)
                        | Set.member p visited -> [lookupAtom curr]
                        | otherwise -> lookupAtom curr : go p (Set.insert p visited)

        formatted = case (mHyp, premNames) of
            (Just h, [p1, p2])
                | p1 == h ->
                    let path = traceToHyp (Map.findWithDefault (-1) p2 (atomToId env))
                        viaStr = case filter (/= h) (filter (/= p2) path) of
                            []  -> ""
                            vps -> " (via " ++ intercalate " -> " vps ++ ")"
                    in "Semantic contradiction: Concept " ++ h ++ " implies " ++ p2 ++ viaStr ++ ", but " ++ p2 ++ " is disjoint with " ++ h ++ "."
                | p2 == h ->
                    let path = traceToHyp (Map.findWithDefault (-1) p1 (atomToId env))
                        viaStr = case filter (/= h) (filter (/= p1) path) of
                            []  -> ""
                            vps -> " (via " ++ intercalate " -> " vps ++ ")"
                    in "Semantic contradiction: Concept " ++ h ++ " implies " ++ p1 ++ viaStr ++ ", but " ++ p1 ++ " is disjoint with " ++ h ++ "."
                | otherwise ->
                    "Semantic contradiction: Concept " ++ h ++ " implies both " ++ p1 ++ " and " ++ p2 ++ ", but " ++ p1 ++ " is disjoint with " ++ p2 ++ "."
            (Just h, ps) ->
                "Semantic contradiction: Concept " ++ h ++ " implies contradictory constraints: " ++ intercalate ", " ps ++ "."
            (Nothing, ps) ->
                "Semantic contradiction: Global axioms derive unsatisfiable conflict: " ++ intercalate ", " ps ++ "."

    in DerivationChain
        { chainConcept   = mHyp
        , chainDerived   = case premNames of (x:_) -> x; [] -> ""
        , chainPath      = case prems of (x:_) -> traceToHyp x; [] -> []
        , chainConflict  = case premNames of (_:y:_) -> y; _ -> ""
        , chainOrigin    = origin
        , chainFormatted = formatted
        }

-- ----------------------------------------------------------------------------
-- Pure DPLL Solver for Non-Horn Clauses
-- ----------------------------------------------------------------------------

-- | Complete DPLL propositional satisfiability solver.
runDPLL :: [Clause] -> Bool
runDPLL clauses = dpll (map clauseLits clauses)
  where
    dpll cs
        | null cs = True
        | any null cs = False
        | otherwise =
            case findUnitClause cs of
                Just unitLit ->
                    dpll (simplifyWith unitLit cs)
                Nothing ->
                    let var = chooseVariable cs
                    in dpll (simplifyWith (Pos var) cs) || dpll (simplifyWith (Neg var) cs)

    findUnitClause cs = case [ lit | [lit] <- cs ] of
        (l:_) -> Just l
        []    -> Nothing

    simplifyWith lit cs =
        [ filter (/= oppLit lit) c | c <- cs, lit `notElem` c ]

    oppLit (Pos a) = Neg a
    oppLit (Neg a) = Pos a

    chooseVariable cs = case cs of
        ((Pos a : _):_) -> a
        ((Neg a : _):_) -> a
        _               -> ""

-- ----------------------------------------------------------------------------
-- Public Ontology Verification API
-- ----------------------------------------------------------------------------

-- | Check whether an individual concept is coherent (satisfiable).
--   Only universal clauses apply: an existential witness need not be the concept's instance.
checkConceptCoherence :: Registry -> Name -> SatResult
checkConceptCoherence reg conceptName =
    let (clauses, _) = registryToClauses reg
        env = buildAtomEnv clauses
        (hornRules, _) = clausesToHornRules env clauses
    in runHornSAT env hornRules (Just conceptName)

-- | Run embedded propositional SAT check across all concepts and global axioms in a Registry.
checkOntologySAT :: Registry -> [DerivationChain]
checkOntologySAT reg =
    let (universal, existentials) = registryToClauses reg
        -- Each scenario is sound to check on its own (see registryToClauses).
        scenarios = universal : map (universal ++) existentials
        env = buildAtomEnv (universal ++ concat existentials)
        (universalRules, _) = clausesToHornRules env universal

        -- 1. Check global consistency (no hypothesis), first contradiction wins
        globalContradictions = take 1
            [ chain
            | sc <- scenarios
            , SatContradiction chain <- [runHornSAT env (fst (clausesToHornRules env sc)) Nothing]
            ]

        -- 2. Check each declared concept for coherence
        conceptContradictions =
            if not (null globalContradictions)
            then [] -- Report global contradiction first
            else mapMaybe checkOneConcept (map fst (concepts reg))

        checkOneConcept cName =
            case runHornSAT env universalRules (Just cName) of
                SatContradiction chain -> Just chain
                SatConsistent _        -> Nothing

        -- 3. Horn resolution is complete for Horn clauses, so DPLL only adds
        --    information when Horn found nothing and non-Horn clauses are present.
        dpllContradictions
            | not (null globalContradictions) = []
            | otherwise = take 1
                [ dpllChain (minimalCore sc)
                | sc <- scenarios
                , any (not . isHornClause) sc
                , not (runDPLL sc)
                ]

        dpllChain core = DerivationChain
            { chainConcept   = Nothing
            , chainDerived   = ""
            , chainPath      = []
            , chainConflict  = ""
            , chainOrigin    = PropositionalAxiom 0 Top
            , chainFormatted = "Semantic contradiction: Propositional clauses are jointly unsatisfiable (DPLL). Involved: " ++
                               intercalate ", " (map showOrigin core)
            }

    in globalContradictions ++ conceptContradictions ++ dpllContradictions

-- | Clauses with at most one positive literal are Horn.
isHornClause :: Clause -> Bool
isHornClause c = length [ () | Pos _ <- clauseLits c ] <= 1

-- | Shrink an unsatisfiable clause set to a minimal set of source axioms by
--   deletion: drop each axiom's clauses in turn and keep the drop if still UNSAT.
minimalCore :: [Clause] -> [ClauseOrigin]
minimalCore clauses = map fst (foldl' tryDrop groups groups)
  where
    groups = groupByOrigin clauses
    tryDrop kept g =
        let without = filter ((/= originKey (fst g)) . originKey . fst) kept
        in if not (runDPLL (concatMap snd without)) then without else kept

groupByOrigin :: [Clause] -> [(ClauseOrigin, [Clause])]
groupByOrigin = foldr insertClause []
  where
    insertClause c acc = case break ((== originKey (clauseOrigin c)) . originKey . fst) acc of
        (pre, (o, cs) : post) -> pre ++ (o, c : cs) : post
        (_, [])               -> (clauseOrigin c, [c]) : acc

-- | Identify the source axiom of a clause; one axiom can yield several clauses
--   with different ClauseOrigin constructors.
originKey :: ClauseOrigin -> Either (Name, Name) (Either Int Name)
originKey (InheritanceOrigin c p)  = Left (c, p)
originKey (DisjointAxiom i _)      = Right (Left i)
originKey (SubsumptionAxiom i _)   = Right (Left i)
originKey (PropositionalAxiom i _) = Right (Left i)
originKey (HypothesisOrigin n)     = Right (Right n)

showOrigin :: ClauseOrigin -> String
showOrigin (InheritanceOrigin c p) = c ++ " -> " ++ p
showOrigin (DisjointAxiom _ ax) = formatFOL ax
showOrigin (SubsumptionAxiom _ ax) = formatFOL ax
showOrigin (PropositionalAxiom _ ax) = formatFOL ax
showOrigin (HypothesisOrigin n) = n
