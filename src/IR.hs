{-# LANGUAGE DeriveGeneric #-}
module IR where

import GHC.Generics
import Data.Graph (graphFromEdges, topSort)
import qualified Data.Map as Map
import qualified Data.Set as Set
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
        unmapped = filter (isUnmappedAxiom (concepts reg) (relations reg)) (axioms reg)
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
    Map.fromListWith (\new old -> old ++ new)
        [ (prop, [BoundConstraint op val])
        | (prop, opStr, valStr) <- consts
        , Just op <- [parseCompOp opStr]
        , let val = parseValue valStr
        , isNumericValue val
        ]

-- | Identify whether an axiom contains complex/conditional/relational logic unmapped to simple field bounds
isUnmappedAxiom :: [(Name, Maybe Name)] -> [Relation] -> FOL -> Bool
isUnmappedAxiom conceptsList rels ax =
    case ax of
        ForAll var (Implies cond body) ->
            not (isSimpleConceptMembership var conceptsList cond && isSimpleFieldPredicate body)
        TypedForAll var _ (Implies cond body) ->
            not (isSimpleConceptMembership var conceptsList cond && isSimpleFieldPredicate body)
        _ -> not (isKnownRelationAxiom rels ax)
  where
    knownConceptNames = Set.fromList (map fst conceptsList)

    isSimpleConceptMembership var _ (Predicate cName [Var v]) =
        v == var && Set.member cName knownConceptNames
    isSimpleConceptMembership _ _ _ = False

    isSimpleFieldPredicate (Predicate _ [Var _, Constant _]) = True
    isSimpleFieldPredicate (Eq (Var _) (Constant _)) = True
    isSimpleFieldPredicate (And p1 p2) = isSimpleFieldPredicate p1 && isSimpleFieldPredicate p2
    isSimpleFieldPredicate _ = False

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
