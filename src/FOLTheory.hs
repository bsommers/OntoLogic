-- | Instance-level SMT-LIB2 encoding of an ontology's first-order axioms.
--
--   concept C       -> (declare-fun is_C (Entity) Bool)
--   def-concept C P -> (assert (forall ((x Entity)) (=> (is_C x) (is_P x))))
--   relation r      -> (declare-fun rel_r (Entity Entity) Bool)
--   property p : T  -> (declare-fun prop_p (Entity) T)
--   user pred P/n   -> (declare-fun up_P (Entity ... Entity) Bool)
--   (op p v) inside a quantifier compares (prop_p <innermost variable>) with v.
--
-- The caller must emit (declare-sort Entity 0) first.
module FOLTheory
    ( Theory(..)
    , TheoryOptions(..)
    , defaultTheoryOptions
    , buildTheory
    , buildTheoryWithOptions
    , buildNamedTheory
    , buildNamedTheoryWithOptions
    , theoryText
    , conceptPred
    , relPred
    , propFun
    , userPred
    , individualConst
    , promoteFreeConstants
    , Env(..)
    , makeEnv
    , makeEnvWithOptions
    , translate
    , extractFuns
    , extractUserPreds
    ) where

import Data.Char (toLower)
import Data.List (intercalate)
import qualified Data.List as L
import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.Containers.ListUtils (nubOrd)
import OntoLogic
import Emitters.SMT (smtNumeral, mapSmtType)

data TheoryOptions = TheoryOptions
    { optFreeConstants :: Bool
    } deriving (Show, Eq)

defaultTheoryOptions :: TheoryOptions
defaultTheoryOptions = TheoryOptions { optFreeConstants = False }

data Theory = Theory
    { theoryDecls   :: String            -- ^ declarations and hierarchy assertions
    , theoryAxioms  :: [String]          -- ^ one (assert ...) line per translated axiom
    , theorySkipped :: [(FOL, String)]   -- ^ axioms not sent to the solver, with the reason
    } deriving (Show, Eq)

data Env = Env
    { envConcepts    :: [Name]
    , envRelations   :: [Name]
    , envProps       :: Map.Map Name PropertyType   -- ^ properties with a single consistent type
    , envRelSigs     :: Map.Map Name [Name]         -- ^ relation signatures
    , envUserPreds   :: Map.Map Name [Int]          -- ^ undeclared predicate symbols and the arities they are used with
    , envIndividuals :: Map.Map Name (Maybe Name)  -- ^ declared individuals and optional concept typing
    }

theoryText :: Theory -> String
theoryText t = theoryDecls t ++ concat (theoryAxioms t)

conceptPred :: Name -> String
conceptPred c = "is_" ++ sanitizeIdent c

relPred :: Name -> String
relPred r = "rel_" ++ sanitizeIdent r

propFun :: Name -> String
propFun p = "prop_" ++ sanitizeIdent p

userPred :: Name -> String
userPred p = "up_" ++ sanitizeIdent p

individualConst :: Name -> String
individualConst i = "ind_" ++ sanitizeIdent i

varName :: Name -> String
varName v = "v_" ++ sanitizeIdent v

freeVarsTerm :: Set.Set Name -> Term -> Set.Set Name
freeVarsTerm bound (Var v)
    | Set.member v bound = Set.empty
    | otherwise          = Set.singleton v
freeVarsTerm _ (Constant _) = Set.empty
freeVarsTerm bound (Apply _ args) = Set.unions (map (freeVarsTerm bound) args)

freeVarsFOL :: Set.Set Name -> FOL -> Set.Set Name
freeVarsFOL bound f = case f of
    ForAll v b        -> freeVarsFOL (Set.insert v bound) b
    Exists v b        -> freeVarsFOL (Set.insert v bound) b
    TypedForAll v _ b -> freeVarsFOL (Set.insert v bound) b
    TypedExists v _ b -> freeVarsFOL (Set.insert v bound) b
    And a b           -> Set.union (freeVarsFOL bound a) (freeVarsFOL bound b)
    Or a b            -> Set.union (freeVarsFOL bound a) (freeVarsFOL bound b)
    Implies a b       -> Set.union (freeVarsFOL bound a) (freeVarsFOL bound b)
    Iff a b           -> Set.union (freeVarsFOL bound a) (freeVarsFOL bound b)
    Not a             -> freeVarsFOL bound a
    Eq t1 t2          -> Set.union (freeVarsTerm bound t1) (freeVarsTerm bound t2)
    Predicate _ args  -> Set.unions (map (freeVarsTerm bound) args)
    Top               -> Set.empty
    Bottom            -> Set.empty

makeEnv :: Registry -> Env
makeEnv = makeEnvWithOptions defaultTheoryOptions

makeEnvWithOptions :: TheoryOptions -> Registry -> Env
makeEnvWithOptions opts reg =
    let conceptNames = nubOrd (map fst (concepts reg))
        isEntityProperty p = case rangeType p of
            PTCustom _ -> True
            _          -> False
        relProps = [ propName p | p <- properties reg, isEntityProperty p ]
        relNames = nubOrd (map relName (relations reg) ++ relProps)
        declaredSigs = [ (relName r, if null (relSignature r) then [relDomain r, relRange r] else relSignature r) | r <- relations reg ]
        propSigs = [ (propName p, [domain p, "Entity"]) | p <- properties reg, isEntityProperty p ]
        sigMap = Map.fromList (declaredSigs ++ propSigs)
        dataProps = [ p | p <- properties reg, not (isEntityProperty p) ]
        typed = Map.fromListWith (\a b -> if a == b then a else Nothing)
                    [ (propName p, Just (rangeType p)) | p <- dataProps ]
        propNames = map propName (properties reg)
        declaredInds = individuals reg
        freeConstInds = if optFreeConstants opts
            then [ (v, Nothing)
                 | v <- Set.toList (Set.unions (map (freeVarsFOL Set.empty) (axioms reg)))
                 , v `notElem` map fst declaredInds
                 , v `notElem` conceptNames
                 , v `notElem` relNames
                 , v `notElem` propNames
                 ]
            else []
        allInds = Map.fromList (declaredInds ++ freeConstInds)
        userPreds = Map.fromListWith (\a b -> nubOrd (a ++ b))
                        [ (n, [k]) | ax <- axioms reg, (n, k) <- extractUserPredsWith conceptNames relNames propNames ax ]
    in Env conceptNames relNames (Map.mapMaybe id typed) sigMap userPreds allInds

-- | Promote undeclared free variables in axioms to declared individuals
promoteFreeConstants :: Registry -> Registry
promoteFreeConstants reg =
    let env = makeEnv reg
        conceptNames = envConcepts env
        relNames = envRelations env
        propNames = Map.keys (envProps env)
        declaredInds = individuals reg
        freeConstInds =
            [ (v, Nothing)
            | v <- Set.toList (Set.unions (map (freeVarsFOL Set.empty) (axioms reg)))
            , v `notElem` map fst declaredInds
            , v `notElem` conceptNames
            , v `notElem` relNames
            , v `notElem` propNames
            ]
    in reg { individuals = declaredInds ++ freeConstInds }

-- | User predicates used with exactly one arity; the only ones that get declared.
declaredUserPreds :: Env -> [(Name, Int)]
declaredUserPreds env = [ (p, k) | (p, [k]) <- Map.toList (envUserPreds env) ]

userPredDecls :: Env -> String
userPredDecls env = concatMap (\(p, arity) ->
    "(declare-fun " ++ userPred p ++ " (" ++ unwords (replicate arity "Entity") ++ ") Bool)\n"
    ) (declaredUserPreds env)

commonDecls :: Env -> [(Name, Int)] -> String
commonDecls env funs =
    concatMap (\c -> "(declare-fun " ++ conceptPred c ++ " (Entity) Bool)\n") (envConcepts env) ++
    concatMap (\r ->
        let sig = Map.findWithDefault ["Entity", "Entity"] r (envRelSigs env)
            sorts = map (const "Entity") sig
        in "(declare-fun " ++ relPred r ++ " (" ++ unwords sorts ++ ") Bool)\n"
    ) (envRelations env) ++
    concatMap (\(p, t) -> "(declare-fun " ++ propFun p ++ " (Entity) " ++ mapSmtType t ++ ")\n") (Map.toList (envProps env)) ++
    concatMap (\(f, arity) ->
        if f `elem` arithmeticFuns
        then ""
        else "(declare-fun " ++ sanitizeIdent f ++ " (" ++ unwords (replicate arity "Entity") ++ ") Entity)\n"
    ) funs ++
    userPredDecls env ++
    concatMap (\(ind, _) -> "(declare-const " ++ individualConst ind ++ " Entity)\n") (Map.toList (envIndividuals env))

buildTheory :: Registry -> Theory
buildTheory = buildTheoryWithOptions defaultTheoryOptions

buildTheoryWithOptions :: TheoryOptions -> Registry -> Theory
buildTheoryWithOptions opts reg =
    let env = makeEnvWithOptions opts reg
        conceptNames = envConcepts env
        funs = nubOrd (concatMap extractFuns (axioms reg))
        decls =
            commonDecls env funs ++
            concat [ "(assert (forall ((x Entity)) (=> (" ++ conceptPred c ++ " x) (" ++ conceptPred p ++ " x))))\n"
                   | (c, Just p) <- nubOrd (concepts reg), p `elem` conceptNames ] ++
            concat [ "(assert (" ++ conceptPred c ++ " " ++ individualConst ind ++ "))\n"
                   | (ind, Just c) <- Map.toList (envIndividuals env), c `elem` conceptNames ]
        results = [ (ax, translate env [] ax) | ax <- axioms reg ]
    in Theory
        { theoryDecls = decls
        , theoryAxioms = [ "(assert " ++ s ++ ")\n" | (_, Right s) <- results ]
        , theorySkipped = [ (ax, e) | (ax, Left e) <- results ]
        }

buildNamedTheory :: Registry -> (String, Map.Map String String)
buildNamedTheory = buildNamedTheoryWithOptions defaultTheoryOptions

buildNamedTheoryWithOptions :: TheoryOptions -> Registry -> (String, Map.Map String String)
buildNamedTheoryWithOptions opts reg =
    let env = makeEnvWithOptions opts reg
        conceptNames = envConcepts env
        funs = nubOrd (concatMap extractFuns (axioms reg))
        decls =
            "(set-option :produce-unsat-cores true)\n" ++
            "(set-logic ALL)\n" ++
            "(declare-sort Entity 0)\n" ++
            commonDecls env funs
        hierPairs = [ (c, p) | (c, Just p) <- nubOrd (concepts reg), p `elem` conceptNames ]
        hierEntries = [ ( "hier_" ++ sanitizeIdent c ++ "_" ++ sanitizeIdent p
                        , "(assert (! (forall ((x Entity)) (=> (" ++ conceptPred c ++ " x) (" ++ conceptPred p ++ " x))) :named hier_" ++ sanitizeIdent c ++ "_" ++ sanitizeIdent p ++ "))\n"
                        , "Subclass hierarchy: " ++ c ++ " ⊑ " ++ p
                        )
                      | (c, p) <- hierPairs
                      ]
        indEntries = [ ( "ind_" ++ sanitizeIdent ind ++ "_type"
                       , "(assert (! (" ++ conceptPred c ++ " " ++ individualConst ind ++ ") :named ind_" ++ sanitizeIdent ind ++ "_type))\n"
                       , "Individual typing: " ++ ind ++ " : " ++ c
                       )
                     | (ind, Just c) <- Map.toList (envIndividuals env), c `elem` conceptNames
                     ]
        axResults = [ (ax, translate env [] ax) | ax <- axioms reg ]
        axEntries = [ ( "ax_" ++ show idx
                      , "(assert (! " ++ s ++ " :named ax_" ++ show idx ++ "))\n"
                      , "Axiom #" ++ show idx ++ ": " ++ formatFOL ax
                      )
                    | (idx, (ax, Right s)) <- zip ([1..] :: [Int]) axResults
                    ]
        namedAsserts = concat [ stmt | (_, stmt, _) <- hierEntries ++ indEntries ++ axEntries ]
        nameMap = Map.fromList [ (name, desc) | (name, _, desc) <- hierEntries ++ indEntries ++ axEntries ]
        smt = decls ++ namedAsserts ++ "(check-sat)\n(get-unsat-core)\n"
    in (smt, nameMap)

extractFuns :: FOL -> [(Name, Int)]
extractFuns f = case f of
    ForAll _ b -> extractFuns b
    Exists _ b -> extractFuns b
    TypedForAll _ _ b -> extractFuns b
    TypedExists _ _ b -> extractFuns b
    And a b -> extractFuns a ++ extractFuns b
    Or a b -> extractFuns a ++ extractFuns b
    Not a -> extractFuns a
    Implies a b -> extractFuns a ++ extractFuns b
    Iff a b -> extractFuns a ++ extractFuns b
    Eq t1 t2 -> extractTermFuns t1 ++ extractTermFuns t2
    Predicate _ args -> concatMap extractTermFuns args
    _ -> []

extractTermFuns :: Term -> [(Name, Int)]
extractTermFuns (Apply f args) = (f, length args) : concatMap extractTermFuns args
extractTermFuns _ = []

-- | Extract user-defined predicate symbols (with arity) from an axiom, given the
--   registry's concept, relation and property names.
extractUserPreds :: Env -> FOL -> [(Name, Int)]
extractUserPreds env = extractUserPredsWith (envConcepts env) (envRelations env) (Map.keys (envProps env))

extractUserPredsWith :: [Name] -> [Name] -> [Name] -> FOL -> [(Name, Int)]
extractUserPredsWith cs rs ps = go
  where
    go f = case f of
        ForAll _ b -> go b
        Exists _ b -> go b
        TypedForAll _ _ b -> go b
        TypedExists _ _ b -> go b
        And a b -> go a ++ go b
        Or a b -> go a ++ go b
        Not a -> go a
        Implies a b -> go a ++ go b
        Iff a b -> go a ++ go b
        Predicate name args
            | isUserPredShape cs rs ps name args -> [(name, length args)]
        _ -> []

-- | A predicate application is a user predicate when its name is not otherwise
--   interpreted and every argument is an Entity-sorted term.
isUserPredShape :: [Name] -> [Name] -> [Name] -> Name -> [Term] -> Bool
isUserPredShape cs rs ps name args =
    name `notElem` cs
    && name `notElem` rs
    && name `notElem` ps
    && isNothingOp name
    && name `notElem` ["eq", "ne"]
    && all entityTerm args
  where
    isNothingOp n = case parseCompOp n of
        Nothing -> True
        Just _  -> False
    entityTerm (Var _) = True
    entityTerm (Constant _) = False
    entityTerm (Apply fn subArgs) =
        fn `notElem` ps && fn `notElem` arithmeticFuns && all entityTerm subArgs

arithmeticFuns :: [Name]
arithmeticFuns = ["+", "-", "*", "/", "abs"]

translate :: Env -> [Name] -> FOL -> Either String String
translate env bound f = case f of
    ForAll v b  -> quant "forall" v "Entity" b
    Exists v b  -> quant "exists" v "Entity" b
    TypedForAll v sort b
        | sort `elem` envConcepts env ->
            (\s -> "(forall ((" ++ varName v ++ " Entity)) (=> (" ++ conceptPred sort ++ " " ++ varName v ++ ") " ++ s ++ "))") <$> translate env (v : bound) b
        | otherwise -> quant "forall" v (resolveSort sort) b
    TypedExists v sort b
        | sort `elem` envConcepts env ->
            (\s -> "(exists ((" ++ varName v ++ " Entity)) (and (" ++ conceptPred sort ++ " " ++ varName v ++ ") " ++ s ++ "))") <$> translate env (v : bound) b
        | otherwise -> quant "exists" v (resolveSort sort) b
    Top         -> Right "true"
    Bottom      -> Right "false"
    Eq (Var prop) term
        | Map.member prop (envProps env), prop `notElem` bound, Just val <- termVal term -> case bound of
            [] -> Left ("comparison on " ++ prop ++ " outside any quantifier")
            (subject : _) -> comparison OpEq subject prop val
    Eq term (Var prop)
        | Map.member prop (envProps env), prop `notElem` bound, Just val <- termVal term -> case bound of
            [] -> Left ("comparison on " ++ prop ++ " outside any quantifier")
            (subject : _) -> comparison OpEq subject prop val
    Eq t1 t2    -> do
        s1 <- translateTerm t1
        s2 <- translateTerm t2
        Right ("(= " ++ s1 ++ " " ++ s2 ++ ")")
    And a b     -> bin "and" a b
    Or a b      -> bin "or" a b
    Implies a b -> bin "=>" a b
    Iff a b     -> bin "=" a b
    Not a       -> (\s -> "(not " ++ s ++ ")") <$> translate env bound a
    Predicate name args -> predicate name args
  where
    resolveSort s
        | s `elem` ["Entity", "Int", "Real", "Bool", "String"] = s
        | s `elem` ["Integer"] = "Int"
        | s `elem` ["Float", "Double"] = "Real"
        | otherwise = "Entity"

    quant q v sort b = (\s -> "(" ++ q ++ " ((" ++ varName v ++ " " ++ sort ++ ")) " ++ s ++ ")") <$> translate env (v : bound) b
    bin op a b = (\x y -> "(" ++ op ++ " " ++ x ++ " " ++ y ++ ")") <$> translate env bound a <*> translate env bound b

    translateTerm (Var v)
        | v `elem` bound = Right (varName v)
        | Map.member v (envIndividuals env) = Right (individualConst v)
        | otherwise      = Left ("unbound variable " ++ v)
    translateTerm (Constant c) =
        case parseValue c of
            VInt i    -> Right (show i)
            VDouble d -> Right (show d)
            VBool b   -> Right (if b then "true" else "false")
            VString s -> Right (show s)
    translateTerm (Apply fn args)
        | Map.member fn (envProps env) = do
            argStrs <- mapM translateTerm args
            Right ("(" ++ propFun fn ++ " " ++ unwords argStrs ++ ")")
        | otherwise = do
            argStrs <- mapM translateTerm args
            Right ("(" ++ sanitizeIdent fn ++ " " ++ unwords argStrs ++ ")")

    predicate name []
        | Just PTBoolean <- Map.lookup name (envProps env) = case bound of
            [] -> Left ("boolean property " ++ name ++ " outside any quantifier")
            (subject : _) -> Right ("(" ++ propFun name ++ " " ++ varName subject ++ ")")

    predicate name [Var v]
        | name `elem` envConcepts env && v `elem` bound =
            Right ("(" ++ conceptPred name ++ " " ++ varName v ++ ")")
        | name `elem` envConcepts env && Map.member v (envIndividuals env) =
            Right ("(" ++ conceptPred name ++ " " ++ individualConst v ++ ")")
        | Just PTBoolean <- Map.lookup name (envProps env), v `elem` bound =
            Right ("(" ++ propFun name ++ " " ++ varName v ++ ")")
        | Just PTBoolean <- Map.lookup name (envProps env), Map.member v (envIndividuals env) =
            Right ("(" ++ propFun name ++ " " ++ individualConst v ++ ")")
    predicate name [t]
        | name `elem` envConcepts env, isTermBoundOrConstant t = do
            tStr <- translateTerm t
            Right ("(" ++ conceptPred name ++ " " ++ tStr ++ ")")
        | Just PTBoolean <- Map.lookup name (envProps env), isTermBoundOrConstant t = do
            tStr <- translateTerm t
            Right ("(" ++ propFun name ++ " " ++ tStr ++ ")")

    predicate "eq" [t1, t2]
        | not (isPropTerm t1) = do
            s1 <- translateTerm t1
            s2 <- translateTerm t2
            Right ("(= " ++ s1 ++ " " ++ s2 ++ ")")
    predicate "ne" [t1, t2]
        | not (isPropTerm t1) = do
            s1 <- translateTerm t1
            s2 <- translateTerm t2
            Right ("(not (= " ++ s1 ++ " " ++ s2 ++ "))")

    predicate name args
        | name `elem` envRelations env, length args >= 2, all isTermBoundOrConstant args = do
            argStrs <- mapM translateTerm args
            Right ("(" ++ relPred name ++ " " ++ unwords argStrs ++ ")")

    predicate opStr [Var prop, term]
        | prop `notElem` bound, Just op <- parseCompOp opStr, Just val <- termVal term = case bound of
            [] -> Left ("comparison on " ++ prop ++ " outside any quantifier")
            (subject : _) -> comparison op subject prop val

    predicate opStr [Var subj, Var prop, term]
        | Just op <- parseCompOp opStr, Just val <- termVal term, subj `elem` bound =
            comparison op subj prop val

    -- User-defined predicate fallback (declared by userPredDecls)
    predicate name args
        | Just arities <- Map.lookup name (envUserPreds env), length args `elem` arities =
            case arities of
                [_] | not (all termVarsBound args) ->
                    Left ("unbound variable in predicate " ++ name)
                [_] | not (all isBoundEntityTerm args) ->
                    Left ("argument in user predicate " ++ name ++ " is not Entity-sorted")
                [_] -> do
                    argStrs <- mapM translateTerm args
                    if null argStrs
                        then Right (userPred name)
                        else Right ("(" ++ userPred name ++ " " ++ unwords argStrs ++ ")")
                _ -> Left ("predicate " ++ name ++ " used with inconsistent arities " ++ intercalate ", " (map show (L.sort arities)))

    predicate name args = Left ("unsupported predicate " ++ name ++ "/" ++ show (length args))

    isPropTerm (Var p) = Map.member p (envProps env)
    isPropTerm _ = False

    isTermBoundOrConstant (Var v) = v `elem` bound || Map.member v (envIndividuals env)
    isTermBoundOrConstant (Constant _) = True
    isTermBoundOrConstant (Apply _ subArgs) = all isTermBoundOrConstant subArgs

    termVarsBound (Var v) = v `elem` bound || Map.member v (envIndividuals env)
    termVarsBound (Constant _) = True
    termVarsBound (Apply _ subArgs) = all termVarsBound subArgs

    isBoundEntityTerm (Var v) = v `elem` bound || Map.member v (envIndividuals env)
    isBoundEntityTerm (Constant _) = False
    isBoundEntityTerm (Apply fn subArgs) =
        not (Map.member fn (envProps env))
        && fn `notElem` arithmeticFuns
        && all isBoundEntityTerm subArgs

    termVal (Constant v) = Just v
    termVal (Var v) | map toLower v `elem` ["true", "false"] = Just v
    termVal _ = Nothing

    comparison op subject prop val = case Map.lookup prop (envProps env) of
        Nothing -> Left ("unknown or ambiguously typed property " ++ prop)
        Just pType
            | op `notElem` [OpEq, OpNe] && pType `notElem` numeric ->
                Left ("ordering comparison on non-numeric property " ++ prop)
            | otherwise -> do
                lit <- literal pType (parseValue val)
                let app = "(" ++ propFun prop ++ " " ++ varName subject ++ ")"
                Right $ case op of
                    OpEq  -> "(= " ++ app ++ " " ++ lit ++ ")"
                    OpNe  -> "(not (= " ++ app ++ " " ++ lit ++ "))"
                    OpGt  -> "(> " ++ app ++ " " ++ lit ++ ")"
                    OpGte -> "(>= " ++ app ++ " " ++ lit ++ ")"
                    OpLt  -> "(< " ++ app ++ " " ++ lit ++ ")"
                    OpLte -> "(<= " ++ app ++ " " ++ lit ++ ")"

    numeric = [PTInteger, PTFloat, PTDouble]

    literal pType v = case (pType, v) of
        (PTBoolean, VBool b) -> Right (if b then "true" else "false")
        (PTString, _)        -> Right (show (valueToString v))
        _ | pType `elem` numeric && isNumericValue v -> Right (smtNumeral pType v)
          | otherwise -> Left ("value " ++ valueToString v ++ " does not fit " ++ propertyTypeToString pType)
