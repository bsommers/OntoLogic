module IR.Clausify
    ( clausify
    , clausifyTheory
    , desugarFOL
    , toNNF
    , clausifyFOL
    ) where

import qualified Data.Map as Map
import qualified Data.Set as Set

import OntoLogic (Name, FOL(..), Term(..), Registry(..), RelationDef(..), PropertyDef(..), disjointBoundPairs)
import IR.CNF

-- | State tracking variable renaming and Skolem constant/function generation
data ClausifyState = ClausifyState
    { nextVarId    :: Int
    , nextSkolemId :: Int
    } deriving (Show, Eq)

newtype ClausifyM a = ClausifyM { unClausifyM :: ClausifyState -> (a, ClausifyState) }

instance Functor ClausifyM where
    fmap f (ClausifyM m) = ClausifyM $ \s ->
        let (a, s') = m s in (f a, s')

instance Applicative ClausifyM where
    pure a = ClausifyM $ \s -> (a, s)
    ClausifyM mf <*> ClausifyM ma = ClausifyM $ \s ->
        let (f, s1) = mf s
            (a, s2) = ma s1
        in (f a, s2)

instance Monad ClausifyM where
    ClausifyM m >>= f = ClausifyM $ \s ->
        let (a, s1) = m s
            ClausifyM m' = f a
        in m' s1

getState :: ClausifyM ClausifyState
getState = ClausifyM $ \s -> (s, s)

putState :: ClausifyState -> ClausifyM ()
putState s = ClausifyM $ \_ -> ((), s)

-- | Run a computation in the ClausifyM state monad
runClausifyM :: ClausifyM a -> a
runClausifyM action = fst (unClausifyM action (ClausifyState 1 1))

freshVar :: ClausifyM VarId
freshVar = do
    s <- getState
    let v = VarId (nextVarId s)
    putState s { nextVarId = nextVarId s + 1 }
    return v

freshSkolem :: ClausifyM SkolemId
freshSkolem = do
    s <- getState
    let sk = SkolemId (nextSkolemId s)
    putState s { nextSkolemId = nextSkolemId s + 1 }
    return sk

-- | Step 1: Desugar high-level FOL constructs (iff, implies, typed quantifiers)
desugarFOL :: FOL -> FOL
desugarFOL (Iff p q) =
    let dp = desugarFOL p
        dq = desugarFOL q
    in And (Or (Not dp) dq) (Or (Not dq) dp)
desugarFOL (Implies p q) =
    Or (Not (desugarFOL p)) (desugarFOL q)
desugarFOL (TypedForAll v sort body) =
    desugarFOL (ForAll v (Implies (Predicate sort [Var v]) body))
desugarFOL (TypedExists v sort body) =
    desugarFOL (Exists v (And (Predicate sort [Var v]) body))
desugarFOL (And p q)    = And (desugarFOL p) (desugarFOL q)
desugarFOL (Or p q)     = Or (desugarFOL p) (desugarFOL q)
desugarFOL (Not p)      = Not (desugarFOL p)
desugarFOL (ForAll v p) = ForAll v (desugarFOL p)
desugarFOL (Exists v p) = Exists v (desugarFOL p)
desugarFOL other        = other

-- | Step 2: Push negations inward to form Negation Normal Form (NNF)
toNNF :: FOL -> FOL
toNNF (Not (Not p))       = toNNF p
toNNF (Not (And p q))     = Or (toNNF (Not p)) (toNNF (Not q))
toNNF (Not (Or p q))      = And (toNNF (Not p)) (toNNF (Not q))
toNNF (Not (ForAll v p))  = Exists v (toNNF (Not p))
toNNF (Not (Exists v p))  = ForAll v (toNNF (Not p))
toNNF (And p q)           = And (toNNF p) (toNNF q)
toNNF (Or p q)            = Or (toNNF p) (toNNF q)
toNNF (ForAll v p)        = ForAll v (toNNF p)
toNNF (Exists v p)        = Exists v (toNNF p)
toNNF other               = other

-- | Step 3 & 4: Standardize variables apart and Skolemize existentials
-- Active universally quantified variables are tracked to supply arguments to Skolem functions.
data FOL'
    = PAnd FOL' FOL'
    | POr FOL' FOL'
    | PLit Literal
    deriving (Show, Eq)

convertTerm :: Map.Map Name CNFTerm -> Term -> CNFTerm
convertTerm env (Var n) =
    Map.findWithDefault (TConst n) n env
convertTerm _ (Constant c) = TConst c
convertTerm env (Apply f args) = TFunc f (map (convertTerm env) args)

skolemizeFormula :: Map.Map Name CNFTerm -> [CNFTerm] -> FOL -> ClausifyM FOL'
skolemizeFormula env univs (ForAll v body) = do
    vId <- freshVar
    let termVar = TVar vId
        env' = Map.insert v termVar env
    skolemizeFormula env' (termVar : univs) body

skolemizeFormula env univs (Exists v body) = do
    skId <- freshSkolem
    let skTerm = TSkolem skId (reverse univs)
        env' = Map.insert v skTerm env
    skolemizeFormula env' univs body

skolemizeFormula env univs (And p q) = do
    p' <- skolemizeFormula env univs p
    q' <- skolemizeFormula env univs q
    return (PAnd p' q')

skolemizeFormula env univs (Or p q) = do
    p' <- skolemizeFormula env univs p
    q' <- skolemizeFormula env univs q
    return (POr p' q')

skolemizeFormula env _ (Predicate p args) =
    return (PLit (Pos p (map (convertTerm env) args)))

skolemizeFormula env _ (Not (Predicate p args)) =
    return (PLit (Neg p (map (convertTerm env) args)))

skolemizeFormula env _ (Eq t1 t2) =
    return (PLit (EqT (convertTerm env t1) (convertTerm env t2)))

skolemizeFormula env _ (Not (Eq t1 t2)) =
    return (PLit (NeqT (convertTerm env t1) (convertTerm env t2)))

skolemizeFormula _ _ Top =
    return (PLit (Pos "$true" []))

skolemizeFormula _ _ Bottom =
    return (PLit (Neg "$true" []))

skolemizeFormula env univs other =
    skolemizeFormula env univs (toNNF (desugarFOL other))

-- | Step 6: Distribute disjunction over conjunction to produce a list of clauses
distribute :: FOL' -> [Clause]
distribute (PLit (Pos "$true" [])) = [] -- Empty clause list represents trivially true
distribute (PLit (Neg "$true" [])) = [Clause Set.empty] -- Empty clause represents contradiction (False)
distribute (PLit lit) = [Clause (Set.singleton lit)]
distribute (PAnd p q) = distribute p ++ distribute q
distribute (POr p q) =
    let cp = distribute p
        cq = distribute q
    in [ Clause (Set.union (getLiterals c1) (getLiterals c2))
       | c1 <- cp
       , c2 <- cq
       ]

-- | Collect free variables in a Term
termFreeVars :: Term -> Set.Set Name
termFreeVars (Var v)        = Set.singleton v
termFreeVars (Constant _)   = Set.empty
termFreeVars (Apply _ args) = Set.unions (map termFreeVars args)

-- | Collect free variables in a FOL formula
freeVars :: FOL -> Set.Set Name
freeVars (Predicate _ args)  = Set.unions (map termFreeVars args)
freeVars (Eq t1 t2)          = Set.union (termFreeVars t1) (termFreeVars t2)
freeVars (And p q)           = Set.union (freeVars p) (freeVars q)
freeVars (Or p q)            = Set.union (freeVars p) (freeVars q)
freeVars (Not p)             = freeVars p
freeVars (Implies p q)       = Set.union (freeVars p) (freeVars q)
freeVars (Iff p q)           = Set.union (freeVars p) (freeVars q)
freeVars (ForAll v p)        = Set.delete v (freeVars p)
freeVars (Exists v p)        = Set.delete v (freeVars p)
freeVars (TypedForAll v _ p) = Set.delete v (freeVars p)
freeVars (TypedExists v _ p) = Set.delete v (freeVars p)
freeVars Top                 = Set.empty
freeVars Bottom              = Set.empty

-- | Implicit universal closure: bind all free variables with ForAll
universalClosure :: FOL -> FOL
universalClosure fol =
    foldr ForAll fol (Set.toAscList (freeVars fol))

-- | Transform a single FOL formula into a set of simplified Clauses
clausifyFOL :: FOL -> ClausifyM [Clause]
clausifyFOL fol = do
    let closed = universalClosure fol
        desugared = desugarFOL closed
        nnf = toNNF desugared
    fol' <- skolemizeFormula Map.empty [] nnf
    let rawClauses = distribute fol'
        cleanClauses = map canonicalizeClause (filter (not . isTautology) rawClauses)
    return cleanClauses

-- | Pure entrypoint to clausify a single FOL formula
clausify :: FOL -> [Clause]
clausify fol = runClausifyM (clausifyFOL fol)

-- | Convert an entire ontology Registry into a unified CNFTheory
clausifyTheory :: Registry -> CNFTheory
clausifyTheory reg = runClausifyM $ do
    -- 1. Concepts subtyping axioms: Sub(x) -> Super(x)
    let taxonomyAxioms =
          [ ForAll "x" (Implies (Predicate sub [Var "x"]) (Predicate super [Var "x"]))
          | (sub, Just super) <- concepts reg
          ]

    -- 2. Relation domain and range axioms
    let relationDomainAxioms =
          [ ForAll "x" (ForAll "y" (Implies (Predicate (relName r) [Var "x", Var "y"])
                                            (Predicate (relDomain r) [Var "x"])))
          | r <- relations reg
          ]
    let relationRangeAxioms =
          [ ForAll "x" (ForAll "y" (Implies (Predicate (relName r) [Var "x", Var "y"])
                                            (Predicate (relRange r) [Var "y"])))
          | r <- relations reg
          ]

    -- 3. Explicit logical axioms from registry
    let propNames = map propName (properties reg)
        regAxioms = map (bindPropertyTerms propNames []) (axioms reg)
    -- 4. Arithmetic background: comparison predicates are uninterpreted here, so state which
    --    numeric bounds exclude each other (see 'disjointBoundPairs').
    let arithAxioms =
          [ ForAll "t" (Not (And (Predicate op1 [Var "t", Constant a]) (Predicate op2 [Var "t", Constant b])))
          | ((op1, a), (op2, b)) <- disjointBoundPairs (axioms reg)
          ]
    let allAxioms = taxonomyAxioms ++ relationDomainAxioms ++ relationRangeAxioms ++ regAxioms ++ arithAxioms
    clauseLists <- mapM clausifyFOL allAxioms
    let flatClauses = concat clauseLists
        uniqueNonTautologyClauses = Set.fromList (map canonicalizeClause (filter (not . isTautology) flatClauses))
    return (CNFTheory uniqueNonTautologyClauses)

-- | In @(gte pressure 100)@ the property name is written bare. Read it as the property of the
--   innermost quantified variable, @prop_pressure(p)@, as the SMT and TPTP backends do. Left
--   alone it would be closed as a fresh universal variable, making every entity share one value.
bindPropertyTerms :: [Name] -> [Name] -> FOL -> FOL
bindPropertyTerms props bound f = case f of
    Predicate op [Var p, Constant c] | isBound op p -> Predicate op [propTerm p, Constant c]
    Predicate op [Constant c, Var p] | isBound op p -> Predicate op [Constant c, propTerm p]
    And a b -> And (rec a) (rec b)
    Or a b -> Or (rec a) (rec b)
    Implies a b -> Implies (rec a) (rec b)
    Iff a b -> Iff (rec a) (rec b)
    Not a -> Not (rec a)
    ForAll v b -> ForAll v (bindPropertyTerms props (v : bound) b)
    Exists v b -> Exists v (bindPropertyTerms props (v : bound) b)
    TypedForAll v s b -> TypedForAll v s (bindPropertyTerms props (v : bound) b)
    TypedExists v s b -> TypedExists v s (bindPropertyTerms props (v : bound) b)
    other -> other
  where
    rec = bindPropertyTerms props bound
    isBound op p = op `elem` ["gt", "gte", "lt", "lte"] && p `elem` props && p `notElem` bound
    propTerm p = case bound of
        (subject : _) -> Apply ("prop_" ++ p) [Var subject]
        []            -> Apply ("prop_" ++ p) []
