{-# LANGUAGE PatternSynonyms #-}
module Linter where

import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.Containers.ListUtils (nubOrd)
import OntoLogic
import Text.Read (readMaybe)
import Linter.SAT (checkOntologySAT, DerivationChain(..))

-- | How serious a finding is. Errors fail the run; warnings are reported and the run continues.
data Severity = SevError | SevWarning
    deriving (Show, Eq, Ord)

-- | A lint message plus the symbol it is about, and optional source position coordinates
--   for GCC/Rust-style "file:line:col: error: ..." diagnostics.
data LintFinding = LintFinding'
    { lintMessage  :: String
    , lintSymbol   :: Maybe Name
    , lintPos      :: Maybe SourcePos
    , lintSeverity :: Severity
    } deriving (Show, Eq)

pattern LintFinding :: String -> Maybe Name -> LintFinding
pattern LintFinding msg sym <- LintFinding' msg sym _ _
  where
    LintFinding msg sym = LintFinding' msg sym Nothing SevError

pattern LintFindingWithPos :: String -> Maybe Name -> Maybe SourcePos -> LintFinding
pattern LintFindingWithPos msg sym pos <- LintFinding' msg sym pos _
  where
    LintFindingWithPos msg sym pos = LintFinding' msg sym pos SevError

{-# COMPLETE LintFinding #-}
{-# COMPLETE LintFindingWithPos #-}

-- | A finding that is reported but does not fail the run.
lintWarning :: String -> Maybe Name -> LintFinding
lintWarning msg sym = LintFinding' msg sym Nothing SevWarning

isLintError :: LintFinding -> Bool
isLintError f = lintSeverity f == SevError

-- | Formatted GCC/Rust-style diagnostic string: "file:line:col: error: <message>"
formatLintFinding :: LintFinding -> String
formatLintFinding f = case lintPos f of
    Just pos -> formatSourcePos pos ++ ": " ++ word ++ ": " ++ lintMessage f
    Nothing  -> word ++ ": " ++ lintMessage f
  where word = if isLintError f then "error" else "warning"

-- | Messages only. Kept so every existing caller and expectation is unaffected.
lintRegistry :: Registry -> [String]
lintRegistry = map lintMessage . lintRegistryFindings

-- | Messages of the findings that fail the run.
lintRegistryErrors :: Registry -> [LintFinding]
lintRegistryErrors = filter isLintError . lintRegistryFindings

-- | Default lint findings without source table
lintRegistryFindings :: Registry -> [LintFinding]
lintRegistryFindings = lintRegistryFindingsWithSource emptySourceTable

-- | Lint registry findings with an explicit SourceTable
lintRegistryFindingsWithSource :: SourceTable -> Registry -> [LintFinding]
lintRegistryFindingsWithSource tbl reg =
    map (resolveFindingPos tbl) $
        checkSymbolIntegrity reg ++
        checkCircularInheritance (Map.fromList $ concepts reg) ++
        checkContradictoryAxioms (map fst (concepts reg)) (axioms reg) ++
        checkUndeclaredAxiomSymbols reg ++
        checkGlobalPropertyContradictions reg ++
        checkSemanticSATContradictions reg

-- | GCC / Clang / Rust compiler diagnostic string list.
lintRegistryDiagnostics :: Registry -> [String]
lintRegistryDiagnostics = map formatLintFinding . lintRegistryFindings

-- | GCC / Clang / Rust compiler diagnostic string list with source position coordinates.
lintRegistryDiagnosticsWithSource :: SourceTable -> Registry -> [String]
lintRegistryDiagnosticsWithSource tbl reg = map formatLintFinding (lintRegistryFindingsWithSource tbl reg)

resolveFindingPos :: SourceTable -> LintFinding -> LintFinding
resolveFindingPos tbl (LintFinding' msg sym mPos sev) =
    case mPos of
        Just _  -> LintFinding' msg sym mPos sev
        Nothing ->
            let foundPos = sym >>= lookupSourceTable tbl
            in LintFinding' msg sym foundPos sev

checkSymbolIntegrity :: Registry -> [LintFinding]
checkSymbolIntegrity reg =
    checkDuplicateConcepts (concepts reg) ++
    checkDuplicateProperties (properties reg) ++
    checkDuplicateRelations (relations reg) ++
    checkDuplicateNamespaces (namespaces reg) ++
    checkUndeclaredParents (concepts reg) ++
    checkUndeclaredDomains (concepts reg) (properties reg) ++
    checkUndeclaredPropertyTypes (concepts reg) (properties reg) ++
    checkUndeclaredRelationEndpoints (concepts reg) (relations reg)

checkDuplicateNamespaces :: [NamespaceDecl] -> [LintFinding]
checkDuplicateNamespaces nsList =
    -- The same prefix bound to the same URI twice is harmless; two URIs is a clash.
    [ LintFinding ("Duplicate namespace prefix declaration: " ++ p) (Just p)
    | (p, uris) <- Map.toList (Map.fromListWith Set.union [ (nsPrefix n, Set.singleton (nsUri n)) | n <- nsList ])
    , Set.size uris > 1
    ]

checkDuplicateConcepts :: [(Name, Maybe Name)] -> [LintFinding]
checkDuplicateConcepts cList =
    [ LintFinding ("Duplicate concept definition: " ++ name) (Just name)
    | (name, count) <- countOccurrences (map fst cList)
    , count > 1
    ]

checkDuplicateProperties :: [Property] -> [LintFinding]
checkDuplicateProperties pList =
    [ LintFinding ("Duplicate property definition: " ++ p ++ " on concept " ++ d) (Just p)
    | ((p, d), count) <- countOccurrences [ (propName prop, domain prop) | prop <- pList ]
    , count > 1
    ]

checkDuplicateRelations :: [Relation] -> [LintFinding]
checkDuplicateRelations rList =
    [ LintFinding ("Duplicate relation definition: " ++ r ++ " from " ++ d ++ " to " ++ rng) (Just r)
    | ((r, d, rng), count) <- countOccurrences [ (relName rel, relDomain rel, relRange rel) | rel <- rList ]
    , count > 1
    ]

checkUndeclaredParents :: [(Name, Maybe Name)] -> [LintFinding]
checkUndeclaredParents cList =
    let knownConcepts = Set.fromList (map fst cList)
    -- The child is the symbol: its declaration is the line carrying the error.
    in [ LintFinding ("Undeclared parent concept: " ++ parent ++ " referenced by " ++ name) (Just name)
       | (name, Just parent) <- cList
       , not (Set.member parent knownConcepts)
       ]

checkUndeclaredDomains :: [(Name, Maybe Name)] -> [Property] -> [LintFinding]
checkUndeclaredDomains cList pList =
    let knownConcepts = Set.fromList (map fst cList)
    in [ LintFinding ("Undeclared domain concept: " ++ domain p ++ " in property " ++ propName p) (Just (propName p))
       | p <- pList
       , not (Set.member (domain p) knownConcepts)
       ]

-- | A property range must be a built-in type or a declared concept.
checkUndeclaredPropertyTypes :: [(Name, Maybe Name)] -> [Property] -> [LintFinding]
checkUndeclaredPropertyTypes cList pList =
    let knownConcepts = Set.fromList (map fst cList)
    in [ LintFinding ("Undeclared property type: " ++ t ++ " in property " ++ propName p) (Just (propName p))
       | p <- pList
       , PTCustom t <- [rangeType p]
       , not (Set.member t knownConcepts)
       ]

checkUndeclaredRelationEndpoints :: [(Name, Maybe Name)] -> [Relation] -> [LintFinding]
checkUndeclaredRelationEndpoints cList rList =
    let knownConcepts = Set.fromList (map fst cList)
    in concat
        [ [ LintFinding ("Undeclared domain concept: " ++ relDomain r ++ " in relation " ++ relName r) (Just (relName r))
          | not (Set.member (relDomain r) knownConcepts)
          ] ++
          [ LintFinding ("Undeclared range concept: " ++ relRange r ++ " in relation " ++ relName r) (Just (relName r))
          | not (Set.member (relRange r) knownConcepts)
          ]
        | r <- rList
        ]

countOccurrences :: Ord a => [a] -> [(a, Int)]
countOccurrences xs = Map.toList (Map.fromListWith (+) [ (x, 1) | x <- xs ])

checkCircularInheritance :: Map.Map Name (Maybe Name) -> [LintFinding]
checkCircularInheritance conceptMap = 
    concatMap (findCycle [] Set.empty) (Map.keys conceptMap)
  where
    findCycle path visited node
      | node `elem` path = [LintFinding ("Circular inheritance: " ++ show (node : path)) (Just node)]
      | Set.member node visited = []
      | otherwise = case Map.lookup node conceptMap of
          Nothing -> [] -- Node not found in map
          Just Nothing -> [] -- No parent
          Just (Just parent) -> findCycle (node : path) (Set.insert node visited) parent

-- | Contradictions inside one axiom. Only the conjuncts that hold unconditionally are
--   examined: the axiom itself, through untyped quantifiers and typed ones whose sort is
--   not a concept. Anything under an implication, a disjunction, a negation or a
--   concept-guarded binder holds only conditionally (the guard may be empty), so a clash
--   there does not make the theory unsatisfiable.
checkContradictoryAxioms :: [Name] -> [FOL] -> [LintFinding]
checkContradictoryAxioms cs axs = concatMap (checkFormulaContradiction . getConjuncts . unconditional cs) axs

unconditional :: [Name] -> FOL -> FOL
unconditional cs = go
  where
    go (ForAll _ f)  = go f
    go (Exists _ f)  = go f
    go (TypedForAll _ s f) | s `notElem` cs = go f
    go (TypedExists _ s f) | s `notElem` cs = go f
    go f = f

-- Flatten any nested logical ANDs
getConjuncts :: FOL -> [FOL]
getConjuncts (And p1 p2) = getConjuncts p1 ++ getConjuncts p2
getConjuncts p = [p]

checkFormulaContradiction :: [FOL] -> [LintFinding]
checkFormulaContradiction conjuncts =
    checkPropositionalContradiction conjuncts ++ checkRangeContradiction conjuncts ++ checkBottomContradiction conjuncts

checkBottomContradiction :: [FOL] -> [LintFinding]
checkBottomContradiction conjuncts =
    [ LintFinding "Axiom contradiction: bottom (false) asserted." Nothing | any (`elem` [Bottom, Not Top]) conjuncts ]

checkPropositionalContradiction :: [FOL] -> [LintFinding]
checkPropositionalContradiction conjuncts =
    -- A formula, not a named symbol: nothing reliable to point at.
    [ LintFinding ("Axiom contradiction: " ++ show p ++ " and its negation both exist.") Nothing
    | p <- conjuncts, Not p `elem` conjuncts
    ]

checkRangeContradiction :: [FOL] -> [LintFinding]
checkRangeContradiction conjuncts =
    let preds = [ (op, prop, val) | Predicate op [Var prop, Constant val] <- conjuncts ]
             ++ [ ("eq", prop, val) | Eq (Var prop) (Constant val) <- conjuncts ]
             ++ [ ("eq", prop, val) | Eq (Constant val) (Var prop) <- conjuncts ]
        grouped = Map.fromListWith (++) [ (prop, [(op, val)]) | (op, prop, val) <- preds ]
    in concatMap checkPropConstraints (Map.toList grouped)

checkPropConstraints :: (String, [(String, String)]) -> [LintFinding]
checkPropConstraints (prop, cs) =
    [ LintFinding ("Property contradiction on " ++ prop ++ ": " ++ op1 ++ " " ++ val1 ++ " and " ++ op2 ++ " " ++ val2) (Just prop)
    | (op1, val1) <- cs
    , (op2, val2) <- cs
    , evalPairContradiction (op1, val1) (op2, val2)
    ]

-- | Shared pairwise contradiction evaluation between two comparison constraints
evalPairContradiction :: (String, String) -> (String, String) -> Bool
evalPairContradiction (op1, val1) (op2, val2) =
    case (op1, op2) of
        ("eq", "ne") | val1 == val2 -> True
        ("ne", "eq") | val1 == val2 -> True
        _ ->
            case (readMaybe val1 :: Maybe Double, readMaybe val2 :: Maybe Double) of
                (Just v1, Just v2) ->
                    case (op1, op2) of
                        ("eq", "eq")   -> v1 /= v2
                        ("eq", "ne")   -> v1 == v2
                        ("ne", "eq")   -> v1 == v2
                        ("eq", "lt")   -> v1 >= v2
                        ("eq", "lte")  -> v1 > v2
                        ("eq", "gt")   -> v1 <= v2
                        ("eq", "gte")  -> v1 < v2
                        ("gt", "lt")   -> v1 >= v2
                        ("gte", "lt")  -> v1 >= v2
                        ("gt", "lte")  -> v1 >= v2
                        ("gte", "lte") -> v1 > v2
                        _              -> False
                _ -> False

checkGlobalPropertyContradictions :: Registry -> [LintFinding]
checkGlobalPropertyContradictions reg =
    concatMap (checkConceptAxioms reg) (map fst (concepts reg))

-- | Contradictions between a concept's own bounds and the bounds it has or inherits.
checkConceptAxioms :: Registry -> Name -> [LintFinding]
checkConceptAxioms reg conceptName =
    let local = guardedConstraints reg conceptName
        allC  = concatMap (guardedConstraints reg) (conceptName : getAncestors conceptName (concepts reg))
    in map (\m -> LintFinding m (Just conceptName)) $ nubOrd
        [ "Cross-axiom contradiction on " ++ conceptName ++ "." ++ p1 ++ ": " ++ o1 ++ " " ++ v1 ++ " and " ++ o2 ++ " " ++ v2
        | (p1, o1, v1) <- local
        , (p2, o2, v2) <- allC
        , p1 == p2
        , evalPairContradiction (o1, v1) (o2, v2) || evalPairContradiction (o2, v2) (o1, v1)
        ]

-- | Bounds that an axiom places on a concept, read only where the binder guard is no narrower
--   than the concept: (forall ((x Adult)) (implies (Member x) ...)) binds Adult-and-Member
--   members, not every Member, so it yields nothing for Member.
guardedConstraints :: Registry -> Name -> [(Name, String, String)]
guardedConstraints reg conceptName = concatMap (extract []) (axioms reg)
  where
    cs = map fst (concepts reg)
    wideEnough s = s == conceptName || s `elem` getAncestors conceptName (concepts reg) || s `notElem` cs
    extract bound (ForAll v body) = extract (v : bound) body
    extract bound (TypedForAll v s body)
        | wideEnough s = extract (v : bound) body
        | otherwise    = []
    extract bound (Implies (Predicate name [Var x]) body)
        | name == conceptName && x `elem` bound = simple body
    extract _ _ = []
    simple (Predicate op [Var prop, Constant val]) = [(prop, op, val)]
    simple (Eq (Var prop) (Constant val)) = [(prop, "eq", val)]
    simple (And p1 p2) = simple p1 ++ simple p2
    simple _ = []

-- | Names an axiom uses that nothing declares. A warning: the axiom may still be satisfiable.
checkUndeclaredAxiomSymbols :: Registry -> [LintFinding]
checkUndeclaredAxiomSymbols reg =
    [ lintWarning ("Undeclared " ++ kind ++ " in axiom: " ++ n) (Just n)
    | (kind, n) <- nubOrd (concatMap (symbolsOf []) (axioms reg))
    , not (Set.member n declared)
    ]
  where
    declared = Set.fromList $
        map fst (concepts reg) ++ map propName (properties reg) ++ map relName (relations reg)
        ++ map fst (individuals reg) ++ comparisons
    comparisons = ["gt", "gte", "lt", "lte", "eq", "ne"]
    symbolsOf bound f = case f of
        Predicate op [Var prop, _] | op `elem` comparisons -> [ ("property", prop) | prop `notElem` bound ]
        Predicate p _ -> [("predicate", p)]
        And a b -> symbolsOf bound a ++ symbolsOf bound b
        Or a b -> symbolsOf bound a ++ symbolsOf bound b
        Implies a b -> symbolsOf bound a ++ symbolsOf bound b
        Iff a b -> symbolsOf bound a ++ symbolsOf bound b
        Not a -> symbolsOf bound a
        ForAll v a -> symbolsOf (v : bound) a
        Exists v a -> symbolsOf (v : bound) a
        TypedForAll v _ a -> symbolsOf (v : bound) a
        TypedExists v _ a -> symbolsOf (v : bound) a
        Eq (Var prop) (Constant _) -> [ ("property", prop) | prop `notElem` bound ]
        _ -> []

-- | Propositional SAT & Horn resolution contradiction check.
-- Detects transitive implications violating disjointness or unsatisfiable concepts in sub-millisecond pure Haskell.
checkSemanticSATContradictions :: Registry -> [LintFinding]
checkSemanticSATContradictions reg =
    map chainToFinding (checkOntologySAT reg)
  where
    chainToFinding chain = lintWarning (chainFormatted chain) (chainConcept chain)
