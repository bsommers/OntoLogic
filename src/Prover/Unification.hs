module Prover.Unification
    ( Subst
    , emptySubst
    , applySubstTerm
    , applySubstLit
    , applySubstClause
    , composeSubst
    , occursIn
    , unifyTerms
    , unifyTermLists
    , unifyLiterals
    , unifyComplementary
    , matchTerm
    , matchLiteral
    , subsumes
    , maxVarId
    , shiftClauseVars
    , standardizeApart
    ) where

import qualified Data.Map as Map
import qualified Data.Set as Set

import IR.CNF

-- | Substitution mapping variable IDs to first-order terms
type Subst = Map.Map VarId CNFTerm

-- | The identity / empty substitution
emptySubst :: Subst
emptySubst = Map.empty

-- | Apply a substitution to a CNFTerm
applySubstTerm :: Subst -> CNFTerm -> CNFTerm
applySubstTerm s (TVar v) =
    case Map.lookup v s of
        Just (TVar v') | v' == v -> TVar v
        Just t                   -> applySubstTerm s t
        Nothing                  -> TVar v
applySubstTerm _ (TConst c) = TConst c
applySubstTerm s (TFunc f args) = TFunc f (map (applySubstTerm s) args)
applySubstTerm s (TSkolem sk args) = TSkolem sk (map (applySubstTerm s) args)

-- | Apply a substitution to a Literal
applySubstLit :: Subst -> Literal -> Literal
applySubstLit s (Neg p args) = Neg p (map (applySubstTerm s) args)
applySubstLit s (Pos p args) = Pos p (map (applySubstTerm s) args)
applySubstLit s (EqT t1 t2)  = EqT (applySubstTerm s t1) (applySubstTerm s t2)
applySubstLit s (NeqT t1 t2) = NeqT (applySubstTerm s t1) (applySubstTerm s t2)

-- | Apply a substitution to a Clause
applySubstClause :: Subst -> Clause -> Clause
applySubstClause s (Clause lits) = Clause (Set.map (applySubstLit s) lits)

-- | Compose two substitutions: (t (composeSubst s1 s2)) == ((t s1) s2)
composeSubst :: Subst -> Subst -> Subst
composeSubst s1 s2 =
    let s1' = Map.map (applySubstTerm s2) s1
        s2' = Map.filterWithKey (\k _ -> not (Map.member k s1)) s2
        merged = Map.union s1' s2'
    in Map.filterWithKey (\k v -> v /= TVar k) merged

-- | Occurs-check: True if VarId occurs anywhere inside CNFTerm
occursIn :: VarId -> CNFTerm -> Bool
occursIn v (TVar v')       = v == v'
occursIn _ (TConst _)     = False
occursIn v (TFunc _ args) = any (occursIn v) args
occursIn v (TSkolem _ args) = any (occursIn v) args

-- | Find the Most General Unifier (MGU) of two CNFTerms with occurs-check
unifyTerms :: CNFTerm -> CNFTerm -> Maybe Subst
unifyTerms (TVar v1) (TVar v2)
    | v1 == v2  = Just emptySubst
    | otherwise = Just (Map.singleton v1 (TVar v2))
unifyTerms (TVar v) t
    | occursIn v t = Nothing
    | otherwise    = Just (Map.singleton v t)
unifyTerms t (TVar v)
    | occursIn v t = Nothing
    | otherwise    = Just (Map.singleton v t)
unifyTerms (TConst c1) (TConst c2)
    | c1 == c2  = Just emptySubst
    | otherwise = Nothing
unifyTerms (TFunc f1 args1) (TFunc f2 args2)
    | f1 == f2 && length args1 == length args2 = unifyTermLists args1 args2
    | otherwise = Nothing
unifyTerms (TSkolem s1 args1) (TSkolem s2 args2)
    | s1 == s2 && length args1 == length args2 = unifyTermLists args1 args2
    | otherwise = Nothing
unifyTerms _ _ = Nothing

-- | Unify two lists of terms pairwise under accumulated substitutions
unifyTermLists :: [CNFTerm] -> [CNFTerm] -> Maybe Subst
unifyTermLists [] [] = Just emptySubst
unifyTermLists (t1:ts1) (t2:ts2) = do
    s1 <- unifyTerms t1 t2
    s2 <- unifyTermLists (map (applySubstTerm s1) ts1) (map (applySubstTerm s1) ts2)
    return (composeSubst s1 s2)
unifyTermLists _ _ = Nothing

-- | Unify two literals having identical predicate symbol and polarity
unifyLiterals :: Literal -> Literal -> Maybe Subst
unifyLiterals (Pos p1 args1) (Pos p2 args2)
    | p1 == p2 && length args1 == length args2 = unifyTermLists args1 args2
unifyLiterals (Neg p1 args1) (Neg p2 args2)
    | p1 == p2 && length args1 == length args2 = unifyTermLists args1 args2
unifyLiterals (EqT a1 b1) (EqT a2 b2) =
    case unifyTermLists [a1, b1] [a2, b2] of
        Just s  -> Just s
        Nothing -> unifyTermLists [a1, b1] [b2, a2]
unifyLiterals (NeqT a1 b1) (NeqT a2 b2) =
    case unifyTermLists [a1, b1] [a2, b2] of
        Just s  -> Just s
        Nothing -> unifyTermLists [a1, b1] [b2, a2]
unifyLiterals _ _ = Nothing

-- | Unify two complementary literals (L1 and ~L2) for binary resolution
unifyComplementary :: Literal -> Literal -> Maybe Subst
unifyComplementary l1 l2 = unifyLiterals l1 (negateLiteral l2)

-- | One-way matching: find subst σ such that (applySubstTerm σ pattern) == target
matchTerm :: Subst -> CNFTerm -> CNFTerm -> Maybe Subst
matchTerm s (TVar v) target =
    case Map.lookup v s of
        Just bound -> if bound == target then Just s else Nothing
        Nothing    -> Just (Map.insert v target s)
matchTerm s (TConst c1) (TConst c2)
    | c1 == c2  = Just s
    | otherwise = Nothing
matchTerm s (TFunc f1 args1) (TFunc f2 args2)
    | f1 == f2 && length args1 == length args2 = matchTermLists s args1 args2
    | otherwise = Nothing
matchTerm s (TSkolem sk1 args1) (TSkolem sk2 args2)
    | sk1 == sk2 && length args1 == length args2 = matchTermLists s args1 args2
    | otherwise = Nothing
matchTerm _ _ _ = Nothing

matchTermLists :: Subst -> [CNFTerm] -> [CNFTerm] -> Maybe Subst
matchTermLists s [] [] = Just s
matchTermLists s (p:ps) (t:ts) = do
    s' <- matchTerm s p t
    matchTermLists s' ps ts
matchTermLists _ _ _ = Nothing

-- | One-way matching for literals
matchLiteral :: Subst -> Literal -> Literal -> Maybe Subst
matchLiteral s (Pos p1 args1) (Pos p2 args2)
    | p1 == p2 && length args1 == length args2 = matchTermLists s args1 args2
matchLiteral s (Neg p1 args1) (Neg p2 args2)
    | p1 == p2 && length args1 == length args2 = matchTermLists s args1 args2
matchLiteral s (EqT a1 b1) (EqT a2 b2) =
    case matchTermLists s [a1, b1] [a2, b2] of
        Just s' -> Just s'
        Nothing -> matchTermLists s [a1, b1] [b2, a2]
matchLiteral s (NeqT a1 b1) (NeqT a2 b2) =
    case matchTermLists s [a1, b1] [a2, b2] of
        Just s' -> Just s'
        Nothing -> matchTermLists s [a1, b1] [b2, a2]
matchLiteral _ _ _ = Nothing

-- | Clause subsumption: returns True if there exists σ such that (C σ) ⊆ D
subsumes :: Clause -> Clause -> Bool
subsumes (Clause cLits) (Clause dLits)
    | Set.null cLits = True
    | Set.size cLits > Set.size dLits = False
    | otherwise = matchClause (Set.toList cLits) emptySubst
  where
    targetLits = Set.toList dLits

    matchClause :: [Literal] -> Subst -> Bool
    matchClause [] _ = True
    matchClause (l:ls) s =
        any (\target -> case matchLiteral s l target of
                            Just s' -> matchClause ls s'
                            Nothing -> False)
            targetLits

-- | Find the maximum VarId in a clause
maxVarId :: Clause -> Int
maxVarId (Clause lits) = foldr (\lit acc -> max acc (litMaxVar lit)) 0 lits
  where
    litMaxVar (Pos _ args)   = foldr (\t acc -> max acc (termMaxVar t)) 0 args
    litMaxVar (Neg _ args)   = foldr (\t acc -> max acc (termMaxVar t)) 0 args
    litMaxVar (EqT t1 t2)    = max (termMaxVar t1) (termMaxVar t2)
    litMaxVar (NeqT t1 t2)   = max (termMaxVar t1) (termMaxVar t2)

    termMaxVar (TVar (VarId i))   = i
    termMaxVar (TConst _)         = 0
    termMaxVar (TFunc _ args)     = foldr (\t acc -> max acc (termMaxVar t)) 0 args
    termMaxVar (TSkolem _ args)   = foldr (\t acc -> max acc (termMaxVar t)) 0 args

-- | Shift all VarId in a clause by an offset
shiftClauseVars :: Int -> Clause -> Clause
shiftClauseVars offset (Clause lits) =
    Clause (Set.map shiftLit lits)
  where
    shiftLit (Pos p args)  = Pos p (map shiftTerm args)
    shiftLit (Neg p args)  = Neg p (map shiftTerm args)
    shiftLit (EqT t1 t2)   = EqT (shiftTerm t1) (shiftTerm t2)
    shiftLit (NeqT t1 t2)  = NeqT (shiftTerm t1) (shiftTerm t2)

    shiftTerm (TVar (VarId i))     = TVar (VarId (i + offset))
    shiftTerm (TConst c)           = TConst c
    shiftTerm (TFunc f args)       = TFunc f (map shiftTerm args)
    shiftTerm (TSkolem sk args)    = TSkolem sk (map shiftTerm args)

-- | Ensure two clauses have disjoint variable sets by offsetting the second
standardizeApart :: Clause -> Clause -> (Clause, Clause)
standardizeApart c1 c2 =
    let m1 = maxVarId c1
    in (c1, shiftClauseVars m1 c2)
