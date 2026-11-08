{-# LANGUAGE DeriveGeneric #-}
module IR.CNF
    ( VarId(..)
    , SkolemId(..)
    , CNFTerm(..)
    , Literal(..)
    , Clause(..)
    , CNFTheory(..)
    , litPredicate
    , litArgs
    , negateLiteral
    , isTautology
    , isEmptyClause
    , canonicalizeClause
    , formatCNFTerm
    , formatLiteral
    , formatClause
    , formatCNFTheory
    ) where

import GHC.Generics (Generic)
import Data.List (intercalate)
import qualified Data.Map as Map
import qualified Data.Set as Set
import OntoLogic (Name)

-- | Unique variable identifier in clausal form
newtype VarId = VarId Int
    deriving (Show, Eq, Ord, Generic)

-- | Unique Skolem function or constant identifier
newtype SkolemId = SkolemId Int
    deriving (Show, Eq, Ord, Generic)

-- | First-Order Terms in Canonical Clausal Normal Form
data CNFTerm
    = TVar VarId              -- ^ Clausal variable (implicitly universally quantified)
    | TConst Name             -- ^ Domain constant
    | TFunc Name [CNFTerm]    -- ^ Uninterpreted function application
    | TSkolem SkolemId [CNFTerm] -- ^ Skolem function with arity matching universal scope
    deriving (Show, Eq, Ord, Generic)

-- | First-Order Literals: atomic predicate applications or equalities
data Literal
    = Neg Name [CNFTerm]      -- ^ Negated predicate literal: ~P(t1, ..., tn)
    | Pos Name [CNFTerm]      -- ^ Positive predicate literal: P(t1, ..., tn)
    | EqT CNFTerm CNFTerm     -- ^ Equality literal: t1 = t2
    | NeqT CNFTerm CNFTerm    -- ^ Inequality literal: t1 != t2
    deriving (Show, Eq, Ord, Generic)

-- | A Clause is a disjunction of literals: L1 \/ L2 \/ ... \/ Ln
newtype Clause = Clause { getLiterals :: Set.Set Literal }
    deriving (Show, Eq, Ord, Generic)

-- | A CNF Theory is a conjunction of clauses: C1 /\ C2 /\ ... /\ Cm
newtype CNFTheory = CNFTheory { getClauses :: Set.Set Clause }
    deriving (Show, Eq, Ord, Generic)

-- | Extract predicate name from a literal, if applicable
litPredicate :: Literal -> Maybe Name
litPredicate (Pos p _) = Just p
litPredicate (Neg p _) = Just p
litPredicate _         = Nothing

-- | Extract argument terms from a literal
litArgs :: Literal -> [CNFTerm]
litArgs (Pos _ args)   = args
litArgs (Neg _ args)   = args
litArgs (EqT t1 t2)    = [t1, t2]
litArgs (NeqT t1 t2)   = [t1, t2]

-- | Complementary negation of a literal
negateLiteral :: Literal -> Literal
negateLiteral (Pos p args)  = Neg p args
negateLiteral (Neg p args)  = Pos p args
negateLiteral (EqT t1 t2)   = NeqT t1 t2
negateLiteral (NeqT t1 t2)  = EqT t1 t2

-- | True if a clause is trivially valid (contains P and ~P, or t = t)
isTautology :: Clause -> Bool
isTautology (Clause lits) =
    any isReflexiveEq lits || any (\l -> Set.member (negateLiteral l) lits) lits
  where
    isReflexiveEq (EqT t1 t2) = t1 == t2
    isReflexiveEq _           = False

-- | True if a clause is the empty clause (box / false)
isEmptyClause :: Clause -> Bool
isEmptyClause (Clause lits) = Set.null lits

-- | Canonicalize variable names in a Clause so variables are numbered 1, 2, ...
-- in deterministic first-seen order.
canonicalizeClause :: Clause -> Clause
canonicalizeClause (Clause lits) =
    let sortedLits = Set.toAscList lits
        allVars = nubOrd (concatMap litVars sortedLits)
        varMap = Map.fromList (zip allVars (map VarId [1..]))
    in Clause (Set.map (renameLit varMap) lits)
  where
    nubOrd xs = go Set.empty xs
      where
        go _ [] = []
        go seen (y:ys)
            | Set.member y seen = go seen ys
            | otherwise         = y : go (Set.insert y seen) ys
    litVars (Neg _ args)   = concatMap termVars args
    litVars (Pos _ args)   = concatMap termVars args
    litVars (EqT t1 t2)    = termVars t1 ++ termVars t2
    litVars (NeqT t1 t2)   = termVars t1 ++ termVars t2

    termVars (TVar v)       = [v]
    termVars (TConst _)     = []
    termVars (TFunc _ args) = concatMap termVars args
    termVars (TSkolem _ args) = concatMap termVars args

    renameLit vMap (Neg p args)  = Neg p (map (renameTerm vMap) args)
    renameLit vMap (Pos p args)  = Pos p (map (renameTerm vMap) args)
    renameLit vMap (EqT t1 t2)   = EqT (renameTerm vMap t1) (renameTerm vMap t2)
    renameLit vMap (NeqT t1 t2)  = NeqT (renameTerm vMap t1) (renameTerm vMap t2)

    renameTerm vMap (TVar v)         = TVar (Map.findWithDefault v v vMap)
    renameTerm _    (TConst c)       = TConst c
    renameTerm vMap (TFunc f args)   = TFunc f (map (renameTerm vMap) args)
    renameTerm vMap (TSkolem s args) = TSkolem s (map (renameTerm vMap) args)

-- | Render a CNFTerm to human-readable string
formatCNFTerm :: CNFTerm -> String
formatCNFTerm (TVar (VarId i))     = "X" ++ show i
formatCNFTerm (TConst c)           = c
formatCNFTerm (TFunc f args)       = f ++ "(" ++ intercalate ", " (map formatCNFTerm args) ++ ")"
formatCNFTerm (TSkolem (SkolemId s) []) = "sk" ++ show s
formatCNFTerm (TSkolem (SkolemId s) args) =
    "sk" ++ show s ++ "(" ++ intercalate ", " (map formatCNFTerm args) ++ ")"

-- | Render a Literal to human-readable string
formatLiteral :: Literal -> String
formatLiteral (Pos p [])   = p
formatLiteral (Pos p args) = p ++ "(" ++ intercalate ", " (map formatCNFTerm args) ++ ")"
formatLiteral (Neg p [])   = "~" ++ p
formatLiteral (Neg p args) = "~" ++ p ++ "(" ++ intercalate ", " (map formatCNFTerm args) ++ ")"
formatLiteral (EqT t1 t2)  = formatCNFTerm t1 ++ " = " ++ formatCNFTerm t2
formatLiteral (NeqT t1 t2) = formatCNFTerm t1 ++ " != " ++ formatCNFTerm t2

-- | Render a Clause to human-readable string
formatClause :: Clause -> String
formatClause (Clause lits)
    | Set.null lits = "[ ]"
    | otherwise     = intercalate " | " (map formatLiteral (Set.toList lits))

-- | Render an entire CNF Theory to human-readable string
formatCNFTheory :: CNFTheory -> String
formatCNFTheory (CNFTheory cls)
    | Set.null cls = "True"
    | otherwise    = unlines (map formatClause (Set.toList cls))
