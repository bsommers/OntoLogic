{-# LANGUAGE DeriveGeneric #-}
module Prover.Tableau
    ( -- * Core Types
      TableauConfig(..)
    , defaultTableauConfig
    , TableauStatus(..)
    , TableauResult(..)
    , TableauFormula(..)
    , RuleType(..)
    , BranchClosure(..)
    , TableauProof(..)
    , Model(..)
      -- * Formula Construction & Normalization
    , folToTableau
    , clauseToTableau
    , cnfTheoryToTableau
    , classifyFormula
    , formatTableauFormula
      -- * Tableaux Execution
    , runTableau
    , runTableauClauses
    , proveTableau
    , proveTableauClauses
      -- * High-Level Ontology Reasoning
    , SolverResult(..)
    , SubsumptionResult(..)
    , checkConsistencyTableau
    , proveSubsumptionTableau
      -- * Formatting
    , formatTableauProof
    , formatCounterModel
    ) where

import Control.Exception (evaluate)
import Data.List (intercalate, tails, find)
import qualified Data.Map as Map
import qualified Data.Set as Set
import GHC.Generics (Generic)
import System.Timeout (timeout)

import OntoLogic
    ( Name
    , FOL(..)
    , Term(..)
    , Registry(..)
    , SolverResult(..)
    , SubsumptionResult(..)
    )
import IR.CNF
    ( VarId(..)
    , SkolemId(..)
    , CNFTerm(..)
    , Literal(..)
    , Clause(..)
    , CNFTheory(..)
    , litArgs
    , formatCNFTerm
    , formatLiteral
    )
import IR.Clausify (desugarFOL, toNNF, clausifyTheory)
import Prover.Unification
    ( Subst
    , emptySubst
    , applySubstLit
    , composeSubst
    , unifyTerms
    , unifyComplementary
    )

-- | Prover search limits and configuration
data TableauConfig = TableauConfig
    { tcMaxDepth          :: !Int         -- ^ Maximum tableau tree depth
    , tcMaxSteps          :: !Int         -- ^ Maximum rule application steps
    , tcMaxGammaInstances :: !Int         -- ^ Maximum gamma (forall) instantiations per formula
    , tcTimeoutMs         :: !(Maybe Int) -- ^ Optional wall-clock timeout in milliseconds
    } deriving (Show, Eq, Generic)

-- | Default robust configuration for interactive and batch reasoning
defaultTableauConfig :: TableauConfig
defaultTableauConfig = TableauConfig
    { tcMaxDepth          = 30
    , tcMaxSteps          = 2000
    , tcMaxGammaInstances = 3
    , tcTimeoutMs         = Just 5000
    }

-- | First-Order Tableau Formula with explicit quantifier bindings
data TableauFormula
    = TFAtom !Literal
    | TFAnd !TableauFormula !TableauFormula
    | TFOr !TableauFormula !TableauFormula
    | TFForAll !VarId !TableauFormula
    | TFExists !VarId !TableauFormula
    deriving (Show, Eq, Ord, Generic)

-- | Smullyan-style formula classification
data RuleType
    = AlphaRule   -- ^ Non-branching conjunctive rule (A /\ B)
    | BetaRule    -- ^ Branching disjunctive rule (A \/ B)
    | GammaRule   -- ^ Universal quantification (forall x. P(x))
    | DeltaRule   -- ^ Existential quantification (exists x. P(x))
    | LiteralRule -- ^ Atomic literal to be added to branch literals
    deriving (Show, Eq, Generic)

-- | Classify a formula according to Smullyan's analytic tableau rules
classifyFormula :: TableauFormula -> RuleType
classifyFormula (TFAnd _ _)    = AlphaRule
classifyFormula (TFOr _ _)     = BetaRule
classifyFormula (TFForAll _ _) = GammaRule
classifyFormula (TFExists _ _) = DeltaRule
classifyFormula (TFAtom _)     = LiteralRule

-- | Record of a closed branch in the tableau derivation
data BranchClosure = BranchClosure
    { bcBranchId :: !Int
    , bcLit1     :: !Literal
    , bcLit2     :: !Literal
    , bcSubst    :: !Subst
    } deriving (Show, Eq, Generic)

-- | Proof object witnessing refutation of all branches
data TableauProof = TableauProof
    { tpClosures :: ![BranchClosure]
    , tpBranches :: !Int
    , tpSteps    :: !Int
    } deriving (Show, Eq, Generic)

-- | Finite Herbrand interpretation or counterexample valuation
data Model = Model
    { modelDomain     :: !(Set.Set CNFTerm)
    , modelTrueLits   :: !(Set.Set Literal)
    , modelFalseLits  :: !(Set.Set Literal)
    , modelEqualities :: ![(CNFTerm, CNFTerm)]
    } deriving (Show, Eq, Generic)

-- | Outcome status of tableau proof search
data TableauStatus
    = ClosedTableau     -- ^ All branches closed (Theorem Proved / UNSAT)
    | OpenTableau       -- ^ Found open saturated branch (Countermodel extracted / SAT)
    | StepLimitExceeded -- ^ Step budget exhausted
    | DepthLimitExceeded-- ^ Tree depth exceeded
    | TimeoutExceeded   -- ^ Wall-clock execution timeout fired
    deriving (Show, Eq, Generic)

-- | Overall tableau proof search result
data TableauResult = TableauResult
    { trStatus       :: !TableauStatus
    , trSteps        :: !Int
    , trBranches     :: !Int
    , trCounterModel :: !(Maybe Model)
    , trProof        :: !(Maybe TableauProof)
    } deriving (Show, Eq, Generic)

-- ----------------------------------------------------------------------------
-- State Monad for Tableau Search
-- ----------------------------------------------------------------------------

data SearchState = SearchState
    { ssNextVarId    :: !Int
    , ssNextSkolemId :: !Int
    , ssNextBranchId :: !Int
    , ssSteps        :: !Int
    } deriving (Show, Eq)

newtype TableauM a = TableauM { unTableauM :: SearchState -> (a, SearchState) }

instance Functor TableauM where
    fmap f (TableauM m) = TableauM $ \s ->
        let (a, s') = m s in (f a, s')

instance Applicative TableauM where
    pure a = TableauM $ \s -> (a, s)
    TableauM mf <*> TableauM ma = TableauM $ \s ->
        let (f, s1) = mf s
            (a, s2) = ma s1
        in (f a, s2)

instance Monad TableauM where
    TableauM m >>= f = TableauM $ \s ->
        let (a, s1) = m s
            TableauM m' = f a
        in m' s1

getState :: TableauM SearchState
getState = TableauM $ \s -> (s, s)

putState :: SearchState -> TableauM ()
putState s = TableauM $ \_ -> ((), s)

modifyState :: (SearchState -> SearchState) -> TableauM ()
modifyState f = do
    s <- getState
    putState (f s)

freshVarId :: TableauM VarId
freshVarId = do
    s <- getState
    let vid = VarId (ssNextVarId s)
    putState s { ssNextVarId = ssNextVarId s + 1 }
    return vid

freshSkolemId :: TableauM SkolemId
freshSkolemId = do
    s <- getState
    let skid = SkolemId (ssNextSkolemId s)
    putState s { ssNextSkolemId = ssNextSkolemId s + 1 }
    return skid

freshBranchId :: TableauM Int
freshBranchId = do
    s <- getState
    let bid = ssNextBranchId s
    putState s { ssNextBranchId = ssNextBranchId s + 1 }
    return bid

-- ----------------------------------------------------------------------------
-- Substitution & Variable Utilities for Tableau Formulas
-- ----------------------------------------------------------------------------

termVars :: CNFTerm -> [VarId]
termVars (TVar v)         = [v]
termVars (TConst _)       = []
termVars (TFunc _ args)   = concatMap termVars args
termVars (TSkolem _ args) = concatMap termVars args

litVars :: Literal -> [VarId]
litVars (Pos _ args)  = concatMap termVars args
litVars (Neg _ args)  = concatMap termVars args
litVars (EqT t1 t2)   = termVars t1 ++ termVars t2
litVars (NeqT t1 t2)  = termVars t1 ++ termVars t2

applySubstTF :: Subst -> TableauFormula -> TableauFormula
applySubstTF s (TFAtom lit)       = TFAtom (applySubstLit s lit)
applySubstTF s (TFAnd f1 f2)      = TFAnd (applySubstTF s f1) (applySubstTF s f2)
applySubstTF s (TFOr f1 f2)       = TFOr (applySubstTF s f1) (applySubstTF s f2)
applySubstTF s (TFForAll v body)  =
    let s' = Map.delete v s
    in TFForAll v (applySubstTF s' body)
applySubstTF s (TFExists v body)  =
    let s' = Map.delete v s
    in TFExists v (applySubstTF s' body)

tfFreeVars :: TableauFormula -> Set.Set VarId
tfFreeVars (TFAtom lit)       = Set.fromList (litVars lit)
tfFreeVars (TFAnd f1 f2)      = Set.union (tfFreeVars f1) (tfFreeVars f2)
tfFreeVars (TFOr f1 f2)       = Set.union (tfFreeVars f1) (tfFreeVars f2)
tfFreeVars (TFForAll v body)  = Set.delete v (tfFreeVars body)
tfFreeVars (TFExists v body)  = Set.delete v (tfFreeVars body)

instantiateVar :: VarId -> CNFTerm -> TableauFormula -> TableauFormula
instantiateVar target replacement tf =
    let subst = Map.singleton target replacement
    in applySubstTF subst tf

-- ----------------------------------------------------------------------------
-- Conversion from FOL and CNF to Tableau Formulas
-- ----------------------------------------------------------------------------

-- | Convert an arbitrary FOL formula into a TableauFormula
folToTableau :: FOL -> TableauFormula
folToTableau fol =
    let desugared = desugarFOL fol
        nnf = toNNF desugared
        (tf, _) = unTableauM (convertFOL Map.empty nnf) (SearchState 1 1 1 0)
    in tf

convertFOL :: Map.Map Name VarId -> FOL -> TableauM TableauFormula
convertFOL env (ForAll v body) = do
    vid <- freshVarId
    let env' = Map.insert v vid env
    body' <- convertFOL env' body
    return (TFForAll vid body')
convertFOL env (Exists v body) = do
    vid <- freshVarId
    let env' = Map.insert v vid env
    body' <- convertFOL env' body
    return (TFExists vid body')
convertFOL env (And p q) = TFAnd <$> convertFOL env p <*> convertFOL env q
convertFOL env (Or p q)  = TFOr  <$> convertFOL env p <*> convertFOL env q
convertFOL env (Predicate p args) =
    return (TFAtom (Pos p (map (convTerm env) args)))
convertFOL env (Not (Predicate p args)) =
    return (TFAtom (Neg p (map (convTerm env) args)))
convertFOL env (Eq t1 t2) =
    return (TFAtom (EqT (convTerm env t1) (convTerm env t2)))
convertFOL env (Not (Eq t1 t2)) =
    return (TFAtom (NeqT (convTerm env t1) (convTerm env t2)))
convertFOL _ Top =
    return (TFAtom (EqT (TConst "$true") (TConst "$true")))
convertFOL _ Bottom =
    return (TFAtom (NeqT (TConst "$true") (TConst "$true")))
convertFOL env other =
    convertFOL env (toNNF (desugarFOL other))

convTerm :: Map.Map Name VarId -> Term -> CNFTerm
convTerm env (Var n) =
    case Map.lookup n env of
        Just vid -> TVar vid
        Nothing  -> TConst n
convTerm _ (Constant c) = TConst c
convTerm env (Apply f args) = TFunc f (map (convTerm env) args)

-- | Convert a CNF Clause into a TableauFormula (universally quantified disjunction)
clauseToTableau :: Clause -> TableauFormula
clauseToTableau (Clause lits)
    | Set.null lits = TFAtom (NeqT (TConst "$bot") (TConst "$bot"))
    | otherwise     =
        let litList = Set.toList lits
            tf = foldr1 TFOr (map TFAtom litList)
            vars = nubOrd (concatMap litVars litList)
        in foldr TFForAll tf vars
  where
    nubOrd xs = Set.toList (Set.fromList xs)

-- | Convert a full CNFTheory into a list of TableauFormulas
cnfTheoryToTableau :: CNFTheory -> [TableauFormula]
cnfTheoryToTableau (CNFTheory clauses) =
    map clauseToTableau (Set.toList clauses)

-- ----------------------------------------------------------------------------
-- Branch Representation & Closure Checking
-- ----------------------------------------------------------------------------

data Branch = Branch
    { brId          :: !Int
    , brLiterals    :: !(Set.Set Literal)
    , brFormulas    :: ![TableauFormula]
    , brGammaCounts :: !(Map.Map TableauFormula Int)
    , brDepth       :: !Int
    } deriving (Show, Eq)

data BranchOutcome
    = BranchClosed !Subst ![BranchClosure]
    | BranchOpen !Model
    | BranchLimit !TableauStatus
    deriving (Show, Eq)

-- | Apply branch equality rewrites so synonymous terms align
applyBranchEqualities :: Set.Set Literal -> Set.Set Literal
applyBranchEqualities lits =
    let rawEqs = [ (t1, t2) | EqT t1 t2 <- Set.toList lits, t1 /= t2 ]
    in if null rawEqs
       then lits
       else
         let rewriteMap = Map.fromList [ (max t1 t2, min t1 t2) | (t1, t2) <- rawEqs ]
             rewriteTerm t = Map.findWithDefault t t rewriteMap
             rewriteLit (Pos p args) = Pos p (map rewriteTerm args)
             rewriteLit (Neg p args) = Neg p (map rewriteTerm args)
             rewriteLit (EqT t1 t2)  = EqT (rewriteTerm t1) (rewriteTerm t2)
             rewriteLit (NeqT t1 t2) = NeqT (rewriteTerm t1) (rewriteTerm t2)
         in Set.map rewriteLit lits

-- | Find all candidate branch closures under incoming substitution
findClosures :: Subst -> Set.Set Literal -> [BranchClosure]
findClosures s lits =
    let normLits = applyBranchEqualities lits
        litList = map (applySubstLit s) (Set.toList normLits)
    in [ BranchClosure 0 l1 l2 (composeSubst s sigma)
       | (l1:rest) <- tails litList
       , l2 <- rest
       , Just sigma <- [unifyComplementary l1 l2]
       ] ++
       [ BranchClosure 0 l1 l1 (composeSubst s sigma)
       | l1@(NeqT t1 t2) <- litList
       , Just sigma <- [unifyTerms t1 t2]
       ] ++
       [ BranchClosure 0 l1 l1 s
       | l1@(Neg "$true" []) <- litList
       ] ++
       [ BranchClosure 0 l1 l1 s
       | l1@(NeqT (TConst "$bot") (TConst "$bot")) <- litList
       ]

-- | Extract a finite Herbrand model from an open saturated branch
extractModel :: Subst -> Set.Set Literal -> Model
extractModel s lits =
    let groundLits = Set.map (applySubstLit s) lits
        normLits = applyBranchEqualities groundLits
        allTerms = nubOrd [ t | lit <- Set.toList normLits, t <- litArgs lit ]
        freeVarsList = nubOrd (concatMap termVars allTerms)
        defaultSubst = Map.fromList [ (v, TConst ("e" ++ show n)) | v@(VarId n) <- freeVarsList ]
        groundedLits = Set.map (applySubstLit defaultSubst) normLits
        groundedTerms = nubOrd [ t | lit <- Set.toList groundedLits, t <- litArgs lit ]
        domain = if null groundedTerms
                 then Set.singleton (TConst "e0")
                 else Set.fromList groundedTerms
        trueLits = Set.filter isPos groundedLits
        falseLits = Set.filter isNeg groundedLits
        eqs = [ (t1, t2) | EqT t1 t2 <- Set.toList groundedLits, t1 /= t2 ]
    in Model
        { modelDomain     = domain
        , modelTrueLits   = trueLits
        , modelFalseLits  = falseLits
        , modelEqualities = eqs
        }
  where
    isPos (Pos _ _) = True
    isPos _         = False

    isNeg (Neg _ _) = True
    isNeg _         = False

    nubOrd xs = Set.toList (Set.fromList xs)

-- ----------------------------------------------------------------------------
-- Tableau Branch Expansion Engine
-- ----------------------------------------------------------------------------

isTautologicalLit :: Literal -> Bool
isTautologicalLit (EqT t1 t2)     = t1 == t2
isTautologicalLit (Pos "$true" []) = True
isTautologicalLit _               = False

partitionFormulas :: [TableauFormula] -> ([Literal], [TableauFormula])
partitionFormulas [] = ([], [])
partitionFormulas (TFAtom lit : rest) =
    let (lits, compounds) = partitionFormulas rest
    in (lit : lits, compounds)
partitionFormulas (comp : rest) =
    let (lits, compounds) = partitionFormulas rest
    in (lits, comp : compounds)

-- | Recursive branch solver implementing alpha, beta, gamma, and delta rules
solveBranch :: TableauConfig -> Subst -> Branch -> TableauM BranchOutcome
solveBranch config subst branch = do
    st <- getState
    if ssSteps st >= tcMaxSteps config
        then return (BranchLimit StepLimitExceeded)
        else if brDepth branch > tcMaxDepth config
            then return (BranchLimit DepthLimitExceeded)
            else do
                modifyState $ \s -> s { ssSteps = ssSteps s + 1 }
                let (atoms, compounds) = partitionFormulas (brFormulas branch)
                    newLiterals = Set.filter (not . isTautologicalLit) $
                                    Set.union (brLiterals branch) (Set.fromList atoms)
                    closures = findClosures subst newLiterals

                -- Eager Ground Closure: if any closure requires no new variable bindings, close immediately!
                case find (\c -> bcSubst c == subst) closures of
                    Just groundClosure ->
                        return $ BranchClosed subst [groundClosure { bcBranchId = brId branch }]
                    Nothing ->
                        if null compounds
                            then
                                -- Saturated leaf branch
                                case closures of
                                    (c:_) ->
                                        return $ BranchClosed (bcSubst c) [c { bcBranchId = brId branch }]
                                    [] ->
                                        -- Open saturated branch -> Model found!
                                        return $ BranchOpen (extractModel subst newLiterals)
                            else
                                -- Expand next compound formula (Alpha, Delta, Beta, Gamma ordering)
                                expandCompound config subst branch newLiterals compounds

expandCompound :: TableauConfig -> Subst -> Branch -> Set.Set Literal -> [TableauFormula] -> TableauM BranchOutcome
expandCompound config subst branch newLiterals compounds =
    case selectNextFormula compounds of
        (TFAnd f1 f2, rest) -> do
            -- Alpha-rule: Non-branching conjunction
            let nextBranch = branch
                    { brLiterals = newLiterals
                    , brFormulas = f1 : f2 : rest
                    }
            solveBranch config subst nextBranch

        (TFExists v body, rest) -> do
            -- Delta-rule: Non-branching existential (Skolemization)
            skId <- freshSkolemId
            let fvs = Set.toList (tfFreeVars body)
                skTerm = TSkolem skId (map TVar fvs)
                instantiated = instantiateVar v skTerm body
                nextBranch = branch
                    { brLiterals = newLiterals
                    , brFormulas = instantiated : rest
                    }
            solveBranch config subst nextBranch

        (TFOr f1 f2, rest) -> do
            -- Beta-rule: Branching disjunction
            leftId <- freshBranchId
            rightId <- freshBranchId
            let leftBranch = branch
                    { brId       = leftId
                    , brLiterals = newLiterals
                    , brFormulas = f1 : rest
                    , brDepth    = brDepth branch + 1
                    }
                rightBranch = branch
                    { brId       = rightId
                    , brLiterals = newLiterals
                    , brFormulas = f2 : rest
                    , brDepth    = brDepth branch + 1
                    }
            leftRes <- solveBranch config subst leftBranch
            case leftRes of
                BranchOpen model ->
                    -- Left branch open implies disjunction satisfied
                    return (BranchOpen model)
                BranchLimit limit ->
                    return (BranchLimit limit)
                BranchClosed leftSubst leftClosures -> do
                    -- Left closed under leftSubst; check Right branch under leftSubst
                    rightRes <- solveBranch config leftSubst rightBranch
                    case rightRes of
                        BranchClosed rightSubst rightClosures ->
                            return (BranchClosed rightSubst (leftClosures ++ rightClosures))
                        BranchOpen model ->
                            return (BranchOpen model)
                        BranchLimit limit ->
                            return (BranchLimit limit)

        (TFForAll v body, rest) -> do
            -- Gamma-rule: Universal quantification
            let count = Map.findWithDefault 0 (TFForAll v body) (brGammaCounts branch)
            if count >= tcMaxGammaInstances config
                then do
                    -- Reached gamma instance limit for this formula, proceed with remaining formulas
                    let nextBranch = branch
                            { brLiterals = newLiterals
                            , brFormulas = rest
                            }
                    solveBranch config subst nextBranch
                else do
                    vFresh <- freshVarId
                    let instantiated = instantiateVar v (TVar vFresh) body
                        counts' = Map.insert (TFForAll v body) (count + 1) (brGammaCounts branch)
                        nextBranch = branch
                            { brLiterals    = newLiterals
                            , brFormulas    = instantiated : rest ++ [TFForAll v body]
                            , brGammaCounts = counts'
                            }
                    solveBranch config subst nextBranch

        (atom@(TFAtom _), rest) -> do
            let nextBranch = branch
                    { brLiterals = newLiterals
                    , brFormulas = atom : rest
                    }
            solveBranch config subst nextBranch

-- | Alpha-first heuristic: pick Alpha or Delta before Beta, and Beta before Gamma
selectNextFormula :: [TableauFormula] -> (TableauFormula, [TableauFormula])
selectNextFormula fs =
    case find isAlphaOrDelta fs of
        Just target -> (target, filter (/= target) fs)
        Nothing ->
            case find isBeta fs of
                Just target -> (target, filter (/= target) fs)
                Nothing ->
                    case fs of
                        (x:xs) -> (x, xs)
                        []     -> error "selectNextFormula called on empty list"
  where
    isAlphaOrDelta (TFAnd _ _)    = True
    isAlphaOrDelta (TFExists _ _) = True
    isAlphaOrDelta _              = False

    isBeta (TFOr _ _) = True
    isBeta _          = False

-- ----------------------------------------------------------------------------
-- Prover Entrypoints
-- ----------------------------------------------------------------------------

buildResult :: BranchOutcome -> SearchState -> TableauResult
buildResult (BranchClosed _ closures) st =
    TableauResult
        { trStatus       = ClosedTableau
        , trSteps        = ssSteps st
        , trBranches     = ssNextBranchId st
        , trCounterModel = Nothing
        , trProof        = Just (TableauProof closures (ssNextBranchId st) (ssSteps st))
        }
buildResult (BranchOpen model) st =
    TableauResult
        { trStatus       = OpenTableau
        , trSteps        = ssSteps st
        , trBranches     = ssNextBranchId st
        , trCounterModel = Just model
        , trProof        = Nothing
        }
buildResult (BranchLimit status) st =
    TableauResult
        { trStatus       = status
        , trSteps        = ssSteps st
        , trBranches     = ssNextBranchId st
        , trCounterModel = Nothing
        , trProof        = Nothing
        }

-- | Pure tableau proof execution on a set of First-Order Logic formulas
runTableau :: TableauConfig -> [FOL] -> TableauResult
runTableau config formulas =
    let initState = SearchState 1 1 1 0
        (tFormulas, stateAfterConv) = unTableauM (mapM (convertFOL Map.empty) formulas) initState
        initBranch = Branch 1 Set.empty tFormulas Map.empty 0
        (outcome, finalState) = unTableauM (solveBranch config emptySubst initBranch) stateAfterConv
    in buildResult outcome finalState

-- | Pure tableau proof execution on a set of CNF Clauses
runTableauClauses :: TableauConfig -> [Clause] -> TableauResult
runTableauClauses config clauses =
    let initState = SearchState 10000 1 1 0
        tFormulas = map clauseToTableau clauses
        initBranch = Branch 1 Set.empty tFormulas Map.empty 0
        (outcome, finalState) = unTableauM (solveBranch config emptySubst initBranch) initState
    in buildResult outcome finalState

-- | IO tableau proof execution on FOL formulas with wall-clock timeout protection
proveTableau :: TableauConfig -> [FOL] -> IO TableauResult
proveTableau config formulas =
    case tcTimeoutMs config of
        Nothing -> return $! runTableau config formulas
        Just ms -> do
            let microsecs = ms * 1000
            mRes <- timeout microsecs (evaluate (runTableau config formulas))
            case mRes of
                Just res -> return res
                Nothing  -> return $ TableauResult
                    { trStatus       = TimeoutExceeded
                    , trSteps        = 0
                    , trBranches     = 0
                    , trCounterModel = Nothing
                    , trProof        = Nothing
                    }

-- | IO tableau proof execution on CNF clauses with wall-clock timeout protection
proveTableauClauses :: TableauConfig -> [Clause] -> IO TableauResult
proveTableauClauses config clauses =
    case tcTimeoutMs config of
        Nothing -> return $! runTableauClauses config clauses
        Just ms -> do
            let microsecs = ms * 1000
            mRes <- timeout microsecs (evaluate (runTableauClauses config clauses))
            case mRes of
                Just res -> return res
                Nothing  -> return $ TableauResult
                    { trStatus       = TimeoutExceeded
                    , trSteps        = 0
                    , trBranches     = 0
                    , trCounterModel = Nothing
                    , trProof        = Nothing
                    }

-- ----------------------------------------------------------------------------
-- High-Level Ontology Reasoning Interfaces
-- ----------------------------------------------------------------------------

-- | Validate ontology consistency using semantic tableaux
checkConsistencyTableau :: TableauConfig -> Registry -> IO SolverResult
checkConsistencyTableau config reg = do
    let cnf = clausifyTheory reg
        clauses = Set.toList (getClauses cnf)
    res <- proveTableauClauses config clauses
    return $ case trStatus res of
        ClosedTableau      -> Unsat
        OpenTableau        ->
            case trCounterModel res of
                Just m  -> Sat (formatCounterModel m)
                Nothing -> Sat "Satisfiable (open branch saturated)"
        StepLimitExceeded  -> Unknown "Tableau step limit exceeded"
        DepthLimitExceeded -> Unknown "Tableau depth limit exceeded"
        TimeoutExceeded    -> Unknown "Tableau proof timed out"

-- | Prove whether ConceptA is subsumed by ConceptB (A ⊑ B) using semantic tableaux
proveSubsumptionTableau :: TableauConfig -> Registry -> String -> String -> IO SubsumptionResult
proveSubsumptionTableau config reg child parent
    | not (null unknown) = return (ProofError ("Unknown concept(s): " ++ unwords unknown))
    | otherwise = do
        let cnf = clausifyTheory reg
            baseClauses = Set.toList (getClauses cnf)
            skConst = TConst ("c_subsumption_test_" ++ child)
            negGoalClauses =
                [ Clause (Set.singleton (Pos child [skConst]))
                , Clause (Set.singleton (Neg parent [skConst]))
                ]
            allClauses = negGoalClauses ++ baseClauses
        res <- proveTableauClauses config allClauses
        return $ case trStatus res of
            ClosedTableau -> Subsumed
            OpenTableau   ->
                case trCounterModel res of
                    Just m  -> NotSubsumed (formatCounterModel m)
                    Nothing -> NotSubsumed "Counterexample found (open branch saturated)"
            TimeoutExceeded    -> ProofError "Tableau proof timed out"
            StepLimitExceeded  -> ProofError "Tableau step limit exceeded"
            DepthLimitExceeded -> ProofError "Tableau depth limit exceeded"
  where
    unknown = filter (`notElem` map fst (concepts reg)) [child, parent]

-- ----------------------------------------------------------------------------
-- Formatting Functions
-- ----------------------------------------------------------------------------

-- | Format a TableauFormula into a readable mathematical string
formatTableauFormula :: TableauFormula -> String
formatTableauFormula (TFAtom lit)              = formatLiteral lit
formatTableauFormula (TFAnd f1 f2)             = "(" ++ formatTableauFormula f1 ++ " /\\ " ++ formatTableauFormula f2 ++ ")"
formatTableauFormula (TFOr f1 f2)              = "(" ++ formatTableauFormula f1 ++ " \\/ " ++ formatTableauFormula f2 ++ ")"
formatTableauFormula (TFForAll (VarId n) body) = "(forall v" ++ show n ++ ". " ++ formatTableauFormula body ++ ")"
formatTableauFormula (TFExists (VarId n) body) = "(exists v" ++ show n ++ ". " ++ formatTableauFormula body ++ ")"

-- | Format a refutation proof trace
formatTableauProof :: TableauProof -> String
formatTableauProof tp =
    let header = "Tableau Refutation Proof (" ++ show (tpBranches tp) ++ " branch(es) closed in " ++ show (tpSteps tp) ++ " steps):"
        closureLines =
            [ "  Branch " ++ show (bcBranchId c) ++ " closed by: " ++
              formatLiteral (bcLit1 c) ++ " and " ++ formatLiteral (bcLit2 c) ++
              if Map.null (bcSubst c) then "" else " with " ++ showSubst (bcSubst c)
            | c <- tpClosures tp
            ]
    in unlines (header : closureLines)
  where
    showSubst s = "[" ++ intercalate ", " [ "v" ++ show n ++ " -> " ++ formatCNFTerm t | (VarId n, t) <- Map.toList s ] ++ "]"

-- | Format a finite Herbrand countermodel
formatCounterModel :: Model -> String
formatCounterModel m =
    let domainStr = intercalate ", " (map formatCNFTerm (Set.toList (modelDomain m)))
        trueStr = unlines [ "    " ++ formatLiteral lit | lit <- Set.toList (modelTrueLits m) ]
        falseStr = unlines [ "    " ++ formatLiteral lit | lit <- Set.toList (modelFalseLits m) ]
        eqStr = unlines [ "    " ++ formatCNFTerm t1 ++ " = " ++ formatCNFTerm t2 | (t1, t2) <- modelEqualities m ]
    in unlines $ filter (not . null)
        [ "Countermodel (Open Saturated Branch):"
        , "  Domain: {" ++ domainStr ++ "}"
        , if Set.null (modelTrueLits m) then "" else "  True Facts:\n" ++ trueStr
        , if Set.null (modelFalseLits m) then "" else "  False Facts:\n" ++ falseStr
        , if null (modelEqualities m) then "" else "  Equalities:\n" ++ eqStr
        ]
