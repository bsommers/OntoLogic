{-# LANGUAGE DeriveGeneric #-}
module IR where

import GHC.Generics
import Data.Graph (graphFromEdges, topSort)
import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.List (maximumBy, minimumBy, nub, find)
import Text.Read (readMaybe)
import Data.Ord (comparing)
import OntoLogic

-- | Compiled representation of a single property attached to a class
data CompiledProperty = CompiledProperty
    { compPropName     :: Name
    , compPropType     :: PropertyType
    , compConstraints  :: [BoundConstraint]
    , compIsInherited  :: Bool
    , compOriginClass  :: Name
    , compCardinality  :: Cardinality
    , compDefaultValue :: Maybe String
    } deriving (Show, Eq, Generic)

-- | Compiled representation of a class and its resolved properties
data CompiledClass = CompiledClass
    { compClassName         :: Name
    , compParentClass       :: Maybe Name
    , compProperties        :: [CompiledProperty]
    , compConditionalAxioms :: [ConditionalConstraint]
      -- ^ Conditionals as written (SQL reads relations between properties from these).
    , compEnforced          :: [ConditionalConstraint]
      -- ^ What the application-tier emitters (Python, Java, Rust, Go, TypeScript, SHACL) check:
      --   the conditionals every translator can state exactly, normalised, plus simple rules
      --   no field bound carries (string and Boolean equality, disequality) with an empty
      --   premise. Everything else is only in 'irUnmappedAxioms'.
    } deriving (Show, Eq, Generic)

-- | Compiled representation of a relationship connecting two classes
data CompiledRelation = CompiledRelation
    { compRelName        :: Name
    , compRelDomain      :: Name
    , compRelRange       :: Name
    , compRelAxioms      :: [FOL]
    , compRelCardinality :: Cardinality
    } deriving (Show, Eq, Generic)

-- | Intermediate Representation for the entire ontology model
data ModelIR = ModelIR
    { irClasses        :: [CompiledClass]     -- Topologically sorted (base classes first)
    , irRelations      :: [CompiledRelation]  -- Relationships between classes
    , irUnmappedAxioms :: [FOL]               -- Complex, relational, or conditional axioms
    } deriving (Show, Eq, Generic)

-- | Compile a parsed Registry into the typed ModelIR
compileRegistry :: Registry -> ModelIR
compileRegistry reg =
    let sortedConcepts = topologicalSortConcepts (concepts reg)
        classes = map (compileClass (concepts reg) (axioms reg) (properties reg) (relations reg)) sortedConcepts
        compiledRels = map (compileRelation (axioms reg)) (relations reg)
        unmapped = filter (isUnmappedAxiom reg) (axioms reg)
    in ModelIR
        { irClasses = classes
        , irRelations = compiledRels
        , irUnmappedAxioms = unmapped
        }

-- | Topologically sort concepts so parents precede children
topologicalSortConcepts :: [(Name, Maybe Name)] -> [(Name, Maybe Name)]
topologicalSortConcepts conceptList =
    let edges = [ (c, fst c, maybe [] (\p -> [p]) (snd c)) | c <- conceptList ]
        (graph, nodeFromVertex, _) = graphFromEdges edges
        sortedVertices = reverse (topSort graph)
    in map (\v -> let (c, _, _) = nodeFromVertex v in c) sortedVertices

-- | Compile a single concept into its CompiledClass representation
compileClass :: [(Name, Maybe Name)] -> [FOL] -> [Property] -> [Relation] -> (Name, Maybe Name) -> CompiledClass
compileClass conceptsList axs allProps allRels (name, parent) =
    let localMap       = groupConstraints (getLocalConstraints name axs)
        mergedMap      = groupConstraints (getInheritedConstraints name conceptsList axs)
        look = visibleProperty conceptsList allProps name
        -- A conditional an emitter would have to guess at (an undeclared property, a type that
        -- does not fit, a shape no translator reads) is not handed to any emitter. It stays in
        -- 'irUnmappedAxioms', so it is reported instead of turning into a check that cannot fail.
        enforced =
            [ c { condPremise = pre, condConclusion = con }
            | c <- getLocalConditionalConstraints name axs
            , Just pre <- [normalizeCondition look (condPremise c)]
            , Just con <- [normalizeCondition look (condConclusion c)]
            ]
            ++ residualRequirements look (getLocalConstraints name axs)
        conditionalAxs = getLocalConditionalConstraints name axs

        -- Preserves original definition order from allProps
        resolvedProps = concatMap (resolveProperty name conceptsList localMap mergedMap) allProps
        resolvedRelProps = [ CompiledProperty
                               { compPropName = relName r
                               , compPropType = PTCustom (relRange r)
                               , compConstraints = []
                               , compIsInherited = False
                               , compOriginClass = relDomain r
                               , compCardinality = relCardinality r
                               , compDefaultValue = Nothing
                               }
                           | r <- allRels
                           , relDomain r == name
                           ]
    in CompiledClass
        { compClassName = name
        , compParentClass = parent
        , compProperties = resolvedProps ++ resolvedRelProps
        , compConditionalAxioms = conditionalAxs
        , compEnforced = enforced
        }

compileRelation :: [FOL] -> Relation -> CompiledRelation
compileRelation axs rel =
    let relAxioms = filter (matchesRelationAxiom (relName rel)) axs
    in CompiledRelation
        { compRelName = relName rel
        , compRelDomain = relDomain rel
        , compRelRange = relRange rel
        , compRelAxioms = relAxioms
        , compRelCardinality = relCardinality rel
        }

matchesRelationAxiom :: Name -> FOL -> Bool
matchesRelationAxiom rName (ForAll _ body) = matchesRelationAxiom rName body
matchesRelationAxiom rName (Exists _ body) = matchesRelationAxiom rName body
matchesRelationAxiom rName (TypedForAll _ _ body) = matchesRelationAxiom rName body
matchesRelationAxiom rName (TypedExists _ _ body) = matchesRelationAxiom rName body
matchesRelationAxiom rName (Implies _ body) = matchesRelationAxiom rName body
matchesRelationAxiom rName (Predicate p _) = p == rName
matchesRelationAxiom rName (And p1 p2) = matchesRelationAxiom rName p1 || matchesRelationAxiom rName p2
matchesRelationAxiom rName (Or p1 p2) = matchesRelationAxiom rName p1 || matchesRelationAxiom rName p2
matchesRelationAxiom rName (Not p) = matchesRelationAxiom rName p
matchesRelationAxiom _ _ = False

-- | localMap decides whether a subclass re-declares an inherited property (it adds its own bound);
-- mergedMap supplies the bounds that apply (own + ancestors).
resolveProperty :: Name -> [(Name, Maybe Name)] -> Map.Map Name [BoundConstraint] -> Map.Map Name [BoundConstraint] -> Property -> [CompiledProperty]
resolveProperty name conceptsList localMap mergedMap p
    -- Direct property belonging to this concept
    | domain p == name =
        [ CompiledProperty
            { compPropName = propName p
            , compPropType = rangeType p
            , compConstraints = Map.findWithDefault [] (propName p) mergedMap
            , compIsInherited = False
            , compOriginClass = domain p
            , compCardinality = propCardinality p
            , compDefaultValue = propDefault p
            }
        ]
    -- Inherited property specialized with subclass constraints
    | isInherited name p conceptsList && Map.member (propName p) localMap && rangeType p `elem` [PTInteger, PTFloat, PTDouble] =
        [ CompiledProperty
            { compPropName = propName p
            , compPropType = rangeType p
            , compConstraints = Map.findWithDefault [] (propName p) mergedMap
            , compIsInherited = True
            , compOriginClass = domain p
            , compCardinality = propCardinality p
            , compDefaultValue = propDefault p
            }
        ]
    | otherwise = []

-- | Group raw (prop, op, val) string triples into typed BoundConstraint records preserving order
groupConstraints :: [(Name, String, String)] -> Map.Map Name [BoundConstraint]
groupConstraints consts =
    Map.map tightenBounds $ Map.fromListWith (\new old -> old ++ new)
        [ (prop, [BoundConstraint op val])
        | (prop, opStr, valStr) <- consts
        , Just op <- [parseCompOp opStr]
        , let val = parseValue valStr
        , isNumericValue val
        ]

-- | The property called @pname@ as seen from a class: declared on it or on an ancestor.
visibleProperty :: [(Name, Maybe Name)] -> [Property] -> Name -> Name -> Maybe Property
visibleProperty conceptsList props cls pname =
    find (\p -> propName p == pname && domain p `elem` (cls : getAncestors cls conceptsList)) props

-- | Conditionals are checked in generated code only when every atom is one a translator can
--   state exactly: a comparison of a declared, scalar property with a constant of a fitting
--   type, or a declared Boolean property used as a flag. The result is normalised so that all
--   emitters see one shape: @Predicate op [Var property, Constant value]@ (never @Eq@, never
--   the constant on the left) and @Predicate flag []@. 'Nothing' means: do not emit, report.
normalizeCondition :: (Name -> Maybe Property) -> FOL -> Maybe FOL
normalizeCondition look = go
  where
    go Top = Just Top
    go Bottom = Just Bottom
    go (And a b) = And <$> go a <*> go b
    go (Or a b) = Or <$> go a <*> go b
    go (Not a) = Not <$> go a
    go (Implies a b) = Or <$> (Not <$> go a) <*> go b
    go (Eq (Var p) (Constant v)) = atom "eq" p v
    go (Eq (Constant v) (Var p)) = atom "eq" p v
    go (Predicate op [Var p, Constant v]) | op `elem` comparisonOps = atom op p v
    go (Predicate op [Constant v, Var p]) | op `elem` comparisonOps = atom (flipOp op) p v
    go (Predicate n []) = flag n
    go (Predicate n [Var v]) = maybe (flag v) Just (flag n)
    go _ = Nothing

    atom op p v = do
        prop <- look p
        if scalar (propCardinality prop) && atomFits (rangeType prop) op v
            then Just (Predicate op [Var p, Constant v])
            else Nothing

    flag n = do
        prop <- look n
        if scalar (propCardinality prop) && rangeType prop == PTBoolean
            then Just (Predicate n [])
            else Nothing

    scalar c = c `elem` [CardDefault, CardExactlyOne, CardZeroOrOne]

comparisonOps :: [String]
comparisonOps = ["eq", "ne", "gt", "gte", "lt", "lte"]

-- | Whether comparing a property of this type with the constant using the operator is meaningful.
atomFits :: PropertyType -> String -> String -> Bool
atomFits ty op v = case ty of
    PTInteger -> numeric
    PTFloat   -> numeric
    PTDouble  -> numeric
    PTBoolean -> op `elem` ["eq", "ne"] && v `elem` ["True", "true", "False", "false"]
    PTString  -> op `elem` ["eq", "ne"] && not numeric
    PTCustom _ -> False
  where
    numeric = (readMaybe v :: Maybe Double) /= Nothing

-- | A simple rule @(C x) => op(property, value)@ that no field bound can carry (a string or
--   Boolean value, equality, disequality) is still enforceable as a requirement with an empty
--   premise, provided the property is declared on C or an ancestor and the value fits its type.
residualRequirements :: (Name -> Maybe Property) -> [(Name, String, String)] -> [ConditionalConstraint]
residualRequirements look triples =
    [ ConditionalConstraint Top atom' ("require " ++ formatFOL atom')
    | (p, op, v) <- triples
    , not (isFieldBound look (p, op, v))
    , Just atom' <- [normalizeCondition look (Predicate op [Var p, Constant v])]
    ]

-- | Whether a simple rule is carried by the numeric bound of a declared numeric property.
isFieldBound :: (Name -> Maybe Property) -> (Name, String, String) -> Bool
isFieldBound look (p, op, v) =
    op `elem` ["gt", "gte", "lt", "lte"]
    && (readMaybe v :: Maybe Double) /= Nothing
    && maybe False (\prop -> rangeType prop `elem` [PTInteger, PTFloat, PTDouble]) (look p)

-- | Find the declaration of a property as seen from a compiled class: the class itself or the
--   nearest ancestor that declares it. Returns the declaring class and the number of
--   inheritance steps between the two.
findDeclaredProperty :: [CompiledClass] -> CompiledClass -> Name -> Maybe (CompiledClass, Int, CompiledProperty)
findDeclaredProperty classes = go (0 :: Int) (length classes + 1)
  where
    go depth fuel cls pname
        | fuel <= 0 = Nothing
        | otherwise = case [ p | p <- compProperties cls, compPropName p == pname, not (compIsInherited p) ] of
            (p : _) -> Just (cls, depth, p)
            [] -> do
                parentName <- compParentClass cls
                parent <- find ((== parentName) . compClassName) classes
                go (depth + 1) (fuel - 1) parent pname

-- | Identify whether an axiom is not carried exactly by a field bound or a relation, so that
--   some target may have to drop or approximate it. Only a numeric ordering bound on a
--   declared numeric property of the concept (or an ancestor) counts as carried.
isUnmappedAxiom :: Registry -> FOL -> Bool
isUnmappedAxiom reg ax =
    case ax of
        ForAll var (Implies cond body) -> not (carried var cond body)
        TypedForAll var _ (Implies cond body) -> not (carried var cond body)
        _ -> not (isKnownRelationAxiom (relations reg) ax)
  where
    conceptsList = concepts reg
    knownConceptNames = Set.fromList (map fst conceptsList)

    carried var (Predicate cName [Var v]) body =
        v == var && Set.member cName knownConceptNames
        && all (\t -> isFieldBound (visibleProperty conceptsList (properties reg) cName) t) (atoms body)
        && not (null (atoms body)) && simpleBody body
    carried _ _ _ = False

    atoms (Predicate op [Var p, Constant c]) = [(p, op, c)]
    atoms (And p1 p2) = atoms p1 ++ atoms p2
    atoms _ = []

    simpleBody (Predicate _ [Var _, Constant _]) = True
    simpleBody (And p1 p2) = simpleBody p1 && simpleBody p2
    simpleBody _ = False

isKnownRelationAxiom :: [Relation] -> FOL -> Bool
isKnownRelationAxiom knownRels (Predicate rName args) =
    any (\r -> relName r == rName && length args >= 2) knownRels
isKnownRelationAxiom _ _ = False
-- | How a target writes comments.
data CommentStyle
    = LineComment String   -- ^ a line prefix such as "//", "#", "--", ";" or "%%"
    | XmlComment           -- ^ a single <!-- ... --> block
    deriving (Show, Eq)

-- | Format unmapped axioms as comment lines for target output.
--   A formatted axiom can span several lines (a string constant may hold a
--   newline), so every line gets its own prefix.
formatUnmappedComments :: String -> ModelIR -> String
formatUnmappedComments prefix = formatUnmappedWarning (LineComment prefix)

formatUnmappedWarning :: CommentStyle -> ModelIR -> String
formatUnmappedWarning style ir
    | null (irUnmappedAxioms ir) = ""
    | otherwise = case style of
        LineComment prefix -> "\n" ++ concatMap (\l -> prefix ++ " " ++ l ++ "\n") body
        XmlComment -> "<!--\n" ++ concatMap (\l -> "  " ++ xmlSafe l ++ "\n") body ++ "-->\n"
  where
    body = header : [ "  " ++ l | ax <- irUnmappedAxioms ir, l <- splitLines (formatFOL ax) ]
    header = "WARNING: The following axioms could not be mapped to field constraints:"
    splitLines = lines . filter (/= '\r')
    -- "--" may not appear inside an XML comment.
    xmlSafe ('-' : '-' : rest) = "- " ++ xmlSafe ('-' : rest)
    xmlSafe (c : rest)         = c : xmlSafe rest
    xmlSafe []                 = []

-- | A subclass that restates an inherited bound (or a concept that states two bounds of the
--   same direction) yields several lower or upper bounds for one property. Emitters map each
--   bound to a keyword or annotation that may appear only once (pydantic kwargs, Java @Min,
--   OpenAPI keys), so keep only the tightest bound in each direction. Ties go to the strict
--   operator. Equality and disequality constraints are kept, deduplicated. First-appearance
--   order is preserved.
tightenBounds :: [BoundConstraint] -> [BoundConstraint]
tightenBounds cs = nub (go False False cs)
  where
    lowers = filter (isLower . constraintOp) cs
    uppers = filter (isUpper . constraintOp) cs
    bestLower = maximumBy (comparing (\c -> (numVal c, strictness c))) lowers
    bestUpper = minimumBy (comparing (\c -> (numVal c, negate (strictness c)))) uppers
    go _ _ [] = []
    go seenL seenU (c:rest)
        | isLower (constraintOp c) = if seenL then go seenL seenU rest else bestLower : go True seenU rest
        | isUpper (constraintOp c) = if seenU then go seenL seenU rest else bestUpper : go seenL True rest
        | otherwise                = c : go seenL seenU rest
    isLower op = op `elem` [OpGt, OpGte]
    isUpper op = op `elem` [OpLt, OpLte]
    strictness c = if constraintOp c `elem` [OpGt, OpLt] then 1 else (0 :: Int)
    numVal c = case constraintValue c of
        VInt n    -> fromIntegral n
        VDouble d -> d
        _         -> 0 :: Double
