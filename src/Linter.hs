{-# LANGUAGE PatternSynonyms #-}
module Linter where

import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.Containers.ListUtils (nubOrd)
import OntoLogic
import Text.Read (readMaybe)
import Linter.SAT (checkOntologySAT, DerivationChain(..))

-- | A lint message plus the symbol it is about, and optional source position coordinates
--   for GCC/Rust-style "file:line:col: error: ..." diagnostics.
data LintFinding = LintFinding'
    { lintMessage :: String
    , lintSymbol  :: Maybe Name
    , lintPos     :: Maybe SourcePos
    } deriving (Show, Eq)

pattern LintFinding :: String -> Maybe Name -> LintFinding
pattern LintFinding msg sym <- LintFinding' msg sym _
  where
    LintFinding msg sym = LintFinding' msg sym Nothing

pattern LintFindingWithPos :: String -> Maybe Name -> Maybe SourcePos -> LintFinding
pattern LintFindingWithPos msg sym pos = LintFinding' msg sym pos

{-# COMPLETE LintFinding #-}
{-# COMPLETE LintFindingWithPos #-}

-- | Formatted GCC/Rust-style diagnostic string: "file:line:col: error: <message>"
formatLintFinding :: LintFinding -> String
formatLintFinding f = case lintPos f of
    Just pos -> formatSourcePos pos ++ ": error: " ++ lintMessage f
    Nothing  -> "error: " ++ lintMessage f

-- | Messages only. Kept so every existing caller and expectation is unaffected.
lintRegistry :: Registry -> [String]
lintRegistry = map lintMessage . lintRegistryFindings

-- | Default lint findings without source table
lintRegistryFindings :: Registry -> [LintFinding]
lintRegistryFindings = lintRegistryFindingsWithSource emptySourceTable

-- | Lint registry findings with an explicit SourceTable
lintRegistryFindingsWithSource :: SourceTable -> Registry -> [LintFinding]
lintRegistryFindingsWithSource tbl reg =
    map (resolveFindingPos tbl) $
        checkSymbolIntegrity reg ++
        checkCircularInheritance (Map.fromList $ concepts reg) ++
        checkContradictoryAxioms (axioms reg) ++
        checkGlobalPropertyContradictions reg ++
        checkSemanticSATContradictions reg

-- | GCC / Clang / Rust compiler diagnostic string list.
lintRegistryDiagnostics :: Registry -> [String]
lintRegistryDiagnostics = map formatLintFinding . lintRegistryFindings

-- | GCC / Clang / Rust compiler diagnostic string list with source position coordinates.
lintRegistryDiagnosticsWithSource :: SourceTable -> Registry -> [String]
lintRegistryDiagnosticsWithSource tbl reg = map formatLintFinding (lintRegistryFindingsWithSource tbl reg)

resolveFindingPos :: SourceTable -> LintFinding -> LintFinding
resolveFindingPos tbl (LintFinding' msg sym mPos) =
    case mPos of
        Just _  -> LintFinding' msg sym mPos
        Nothing ->
            let foundPos = sym >>= lookupSourceTable tbl
            in LintFinding' msg sym foundPos

checkSymbolIntegrity :: Registry -> [LintFinding]
checkSymbolIntegrity reg =
    checkDuplicateConcepts (concepts reg) ++
    checkDuplicateProperties (properties reg) ++
    checkDuplicateRelations (relations reg) ++
    checkDuplicateNamespaces (namespaces reg) ++
    checkUndeclaredParents (concepts reg) ++
    checkUndeclaredDomains (concepts reg) (properties reg) ++
    checkUndeclaredRelationEndpoints (concepts reg) (relations reg)

checkDuplicateNamespaces :: [NamespaceDecl] -> [LintFinding]
checkDuplicateNamespaces nsList =
    [ LintFinding ("Duplicate namespace prefix declaration: " ++ p) (Just p)
    | (p, count) <- countOccurrences (map nsPrefix nsList)
    , count > 1
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

checkContradictoryAxioms :: [FOL] -> [LintFinding]
checkContradictoryAxioms axs = concatMap checkAxiomContradiction axs

-- Recursively check an FOL term for contradictions
checkAxiomContradiction :: FOL -> [LintFinding]
checkAxiomContradiction ax =
    let subFormulas = getSubFormulas ax
    in concatMap (checkFormulaContradiction . getConjuncts) subFormulas

-- Flatten any nested logical ANDs
getConjuncts :: FOL -> [FOL]
getConjuncts (And p1 p2) = getConjuncts p1 ++ getConjuncts p2
getConjuncts p = [p]

-- Find logical subformulas where conjuncts are grouped
getSubFormulas :: FOL -> [FOL]
getSubFormulas f = f : case f of
    And p1 p2 -> getSubFormulas p1 ++ getSubFormulas p2
    Or p1 p2 -> getSubFormulas p1 ++ getSubFormulas p2
    Not p -> getSubFormulas p
    Implies p1 p2 -> getSubFormulas p1 ++ getSubFormulas p2
    Iff p1 p2 -> getSubFormulas p1 ++ getSubFormulas p2
    ForAll _ p -> getSubFormulas p
    Exists _ p -> getSubFormulas p
    TypedForAll _ _ p -> getSubFormulas p
    TypedExists _ _ p -> getSubFormulas p
    _ -> []

checkFormulaContradiction :: [FOL] -> [LintFinding]
checkFormulaContradiction conjuncts =
    checkPropositionalContradiction conjuncts ++ checkRangeContradiction conjuncts ++ checkBottomContradiction conjuncts

checkBottomContradiction :: [FOL] -> [LintFinding]
checkBottomContradiction conjuncts =
    [ LintFinding "Axiom contradiction: bottom (false) asserted." Nothing | Bottom `elem` conjuncts ]

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
    let local = getLocalConstraints conceptName (axioms reg)
        allC  = getInheritedConstraints conceptName (concepts reg) (axioms reg)
    in map (\m -> LintFinding m (Just conceptName)) $ nubOrd
        [ "Cross-axiom contradiction on " ++ conceptName ++ "." ++ p1 ++ ": " ++ o1 ++ " " ++ v1 ++ " and " ++ o2 ++ " " ++ v2
        | (p1, o1, v1) <- local
        , (p2, o2, v2) <- allC
        , p1 == p2
        , evalPairContradiction (o1, v1) (o2, v2) || evalPairContradiction (o2, v2) (o1, v1)
        ]

-- | Propositional SAT & Horn resolution contradiction check.
-- Detects transitive implications violating disjointness or unsatisfiable concepts in sub-millisecond pure Haskell.
checkSemanticSATContradictions :: Registry -> [LintFinding]
checkSemanticSATContradictions reg =
    map chainToFinding (checkOntologySAT reg)
  where
    chainToFinding chain = LintFinding (chainFormatted chain) (chainConcept chain)
