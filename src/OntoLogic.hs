{-# LANGUAGE DeriveGeneric, OverloadedStrings, PatternSynonyms #-}
module OntoLogic where

import GHC.Generics
import Data.Hashable
import Text.Read (readMaybe)
import Data.List (intercalate)
import qualified Data.Set as Set
import Data.Containers.ListUtils (nubOrd)
import qualified Data.Map as Map
import Control.Applicative ((<|>))

type Name = String

-- | Strongly typed property data types
data PropertyType
    = PTInteger
    | PTFloat
    | PTDouble
    | PTBoolean
    | PTString
    | PTCustom Name
    deriving (Show, Eq, Ord, Generic)

instance Hashable PropertyType

parsePropertyType :: String -> PropertyType
parsePropertyType "Integer" = PTInteger
parsePropertyType "Float"   = PTFloat
parsePropertyType "Double"  = PTDouble
parsePropertyType "Boolean" = PTBoolean
parsePropertyType "String"  = PTString
parsePropertyType other     = PTCustom other

propertyTypeToString :: PropertyType -> String
propertyTypeToString PTInteger   = "Integer"
propertyTypeToString PTFloat     = "Float"
propertyTypeToString PTDouble    = "Double"
propertyTypeToString PTBoolean   = "Boolean"
propertyTypeToString PTString    = "String"
propertyTypeToString (PTCustom n) = n

-- | Comparison operators
data CompOp
    = OpEq
    | OpNe
    | OpGt
    | OpGte
    | OpLt
    | OpLte
    deriving (Show, Eq, Ord, Generic)

instance Hashable CompOp

parseCompOp :: String -> Maybe CompOp
parseCompOp "eq"  = Just OpEq
parseCompOp "ne"  = Just OpNe
parseCompOp "gt"  = Just OpGt
parseCompOp "gte" = Just OpGte
parseCompOp "lt"  = Just OpLt
parseCompOp "lte" = Just OpLte
parseCompOp _     = Nothing

compOpToString :: CompOp -> String
compOpToString OpEq  = "eq"
compOpToString OpNe  = "ne"
compOpToString OpGt  = "gt"
compOpToString OpGte = "gte"
compOpToString OpLt  = "lt"
compOpToString OpLte = "lte"

-- | Strongly typed scalar values
data Value
    = VInt Integer
    | VDouble Double
    | VString String
    | VBool Bool
    deriving (Show, Eq, Ord, Generic)

instance Hashable Value

parseValue :: String -> Value
parseValue "True"  = VBool True
parseValue "False" = VBool False
parseValue "true"  = VBool True
parseValue "false" = VBool False
parseValue str =
    case (readMaybe str :: Maybe Integer) of
        Just n -> VInt n
        Nothing ->
            case (readMaybe str :: Maybe Double) of
                Just d  -> VDouble d
                Nothing -> VString str

valueToString :: Value -> String
valueToString (VInt n)    = show n
valueToString (VDouble d) = show d
valueToString (VString s) = s
valueToString (VBool b)   = if b then "True" else "False"

valueToDouble :: Value -> Maybe Double
valueToDouble (VInt n)    = Just (fromIntegral n)
valueToDouble (VDouble d) = Just d
valueToDouble _           = Nothing

isNumericValue :: Value -> Bool
isNumericValue (VInt _)    = True
isNumericValue (VDouble _) = True
isNumericValue _           = False

-- | Bound constraint for numerical and range validations
data BoundConstraint = BoundConstraint
    { constraintOp    :: CompOp
    , constraintValue :: Value
    } deriving (Show, Eq, Ord, Generic)

instance Hashable BoundConstraint

data FOL = Predicate Name [Term]
         | And FOL FOL
         | Or FOL FOL
         | Not FOL
         | Implies FOL FOL
         | Iff FOL FOL
         | ForAll Name FOL
         | Exists Name FOL
         | Top
         | Bottom
         | Eq Term Term
         | TypedForAll Name Name FOL
         | TypedExists Name Name FOL
         deriving (Show, Eq, Ord, Generic)

data Term = Var Name
          | Constant String
          | Apply Name [Term]
          deriving (Show, Eq, Ord, Generic)

instance Hashable FOL
instance Hashable Term

-- | Multi-premise or conditional constraint (e.g. if safety_status == False then active == False)
data ConditionalConstraint = ConditionalConstraint
    { condPremise     :: FOL
    , condConclusion  :: FOL
    , condDescription :: String
    } deriving (Show, Eq, Ord, Generic)

instance Hashable ConditionalConstraint

-- | Cardinality and multiplicity constraints for properties and relations
data Cardinality
    = CardDefault          -- ^ Unspecified / default (1..1 for properties, 0..* for relations)
    | CardExactlyOne       -- ^ 1..1
    | CardZeroOrOne        -- ^ 0..1 (optional scalar)
    | CardZeroOrMore       -- ^ 0..* (collection)
    | CardOneOrMore        -- ^ 1..* (non-empty collection)
    deriving (Show, Eq, Ord, Generic)

instance Hashable Cardinality

-- | Outcome of solver consistency / satisfiability checks
data SolverResult
    = Sat String
    | Unsat
    | Unknown String
    | SolverError String
    deriving (Show, Eq, Generic)

instance Hashable SolverResult

-- | Outcome of concept subsumption theorem proving
data SubsumptionResult
    = Subsumed
    | NotSubsumed String
    | ProofError String
    deriving (Show, Eq, Generic)

instance Hashable SubsumptionResult

parseCardinality :: String -> Maybe Cardinality
parseCardinality "1..1"     = Just CardExactlyOne
parseCardinality "1"        = Just CardExactlyOne
parseCardinality "0..1"     = Just CardZeroOrOne
parseCardinality "optional" = Just CardZeroOrOne
parseCardinality "0..*"     = Just CardZeroOrMore
parseCardinality "0..n"     = Just CardZeroOrMore
parseCardinality "*"        = Just CardZeroOrMore
parseCardinality "1..*"     = Just CardOneOrMore
parseCardinality "1..n"     = Just CardOneOrMore
parseCardinality _          = Nothing

cardinalityToString :: Cardinality -> String
cardinalityToString CardDefault    = "default"
cardinalityToString CardExactlyOne = "1..1"
cardinalityToString CardZeroOrOne  = "0..1"
cardinalityToString CardZeroOrMore = "0..*"
cardinalityToString CardOneOrMore  = "1..*"

data RelationDef = RelationDef
    { relName        :: Name
    , relDomain      :: Name
    , relRange       :: Name
    , relCardinality :: Cardinality
    , relSignature   :: [Name]
    } deriving (Show, Eq, Ord, Generic)

instance Hashable RelationDef

type Relation = RelationDef

pattern Relation :: Name -> Name -> Name -> RelationDef
pattern Relation n d r <- RelationDef n d r _ _
  where
    Relation n d r = RelationDef n d r CardDefault [d, r]

{-# COMPLETE Relation #-}

-- | Import declaration for external .logic modules
data ImportDecl = ImportDecl
    { importPath :: FilePath
    } deriving (Show, Eq, Ord, Generic)

instance Hashable ImportDecl

-- | Namespace declaration for module prefixing
-- | The URI a namespace prefix expands to, when it is declared with one.
namespaceUri :: String -> [NamespaceDecl] -> Maybe String
namespaceUri pfx nss = lookup pfx [ (nsPrefix n, u) | n <- nss, Just u <- [nsUri n] ]

-- | Absolute IRI for a declared name.
--
--   A @prefix:Local@ name whose prefix is declared resolves into that namespace by
--   plain concatenation, which is exactly how Turtle expands a prefixed name. Matching
--   Turtle here is what makes the OWL and SHACL output name the same resources: before
--   this, OWL put the whole @bfo:Entity@ in the fragment of its own base and produced
--   @.../BFO_#bfo:Entity@, which overlapped with SHACL's @.../BFO_Entity@ not at all.
--
--   Anything else -- no prefix, or a prefix nobody declared -- lands in the document's
--   own base, where it is at least unambiguous.
resolveIri :: [NamespaceDecl] -> String -> Name -> String
resolveIri nss base name =
    case break (== ':') name of
        (pfx, ':':local) | Just uri <- namespaceUri pfx nss -> uri ++ local
        _ -> base ++ "#" ++ name

-- | Neutral base IRI used when the ontology declares no namespace URI. Nothing in the
--   language ties output to a particular organisation, so the fallback must not either.
defaultBaseIri :: String
defaultBaseIri = "http://example.org/ontologic"

-- | Base IRI for RDF output: the override, else the first declared namespace URI,
--   else 'defaultBaseIri'. A trailing '#' or '/' is stripped so callers can append
--   their own separator.
resolveBaseIri :: Maybe String -> Registry -> String
resolveBaseIri (Just iri) _ = stripTrailingSep iri
resolveBaseIri Nothing reg =
    case [ u | NamespaceDecl _ (Just u) <- namespaces reg ] of
        (u:_) -> stripTrailingSep u
        []    -> defaultBaseIri

stripTrailingSep :: String -> String
stripTrailingSep = reverse . dropWhile (`elem` ("#/" :: String)) . reverse

data NamespaceDecl = NamespaceDecl
    { nsPrefix :: String
    , nsUri    :: Maybe String
    } deriving (Show, Eq, Ord, Generic)

instance Hashable NamespaceDecl

-- | Source file coordinate annotations (1-based line and column, GCC/Rust style)
data SourcePos = SourcePos
    { posFile :: FilePath
    , posLine :: Int
    , posCol  :: Int
    } deriving (Show, Eq, Ord, Generic)

instance Hashable SourcePos

-- | GCC / Clang / Rust compiler diagnostic format: "file:line:col"
formatSourcePos :: SourcePos -> String
formatSourcePos (SourcePos f l c) = f ++ ":" ++ show l ++ ":" ++ show c

type SourceTable = Map.Map String SourcePos

emptySourceTable :: SourceTable
emptySourceTable = Map.empty

lookupSourceTable :: SourceTable -> String -> Maybe SourcePos
lookupSourceTable tbl sym =
    Map.lookup ("concept:" ++ sym) tbl <|>
    Map.lookup ("property:" ++ sym) tbl <|>
    Map.lookup ("relation:" ++ sym) tbl <|>
    Map.lookup ("individual:" ++ sym) tbl <|>
    Map.lookup ("namespace:" ++ sym) tbl <|>
    Map.lookup sym tbl

data Registry = Registry 
    { concepts    :: [(Name, Maybe Name)]
    , axioms      :: [FOL]
    , properties  :: [Property]
    , relations   :: [Relation]
    , imports     :: [ImportDecl]
    , namespaces  :: [NamespaceDecl]
    , individuals :: [(Name, Maybe Name)]
    } deriving (Show, Eq, Generic)

emptyRegistry :: Registry
emptyRegistry = Registry [] [] [] [] [] [] []

mergeRegistries :: Registry -> Registry -> Registry
mergeRegistries r1 r2 = Registry
    { concepts    = concepts r1 ++ concepts r2
    , axioms      = axioms r1 ++ axioms r2
    , properties  = properties r1 ++ properties r2
    , relations   = relations r1 ++ relations r2
    , imports     = imports r1 ++ imports r2
    , namespaces  = namespaces r1 ++ namespaces r2
    , individuals = individuals r1 ++ individuals r2
    }

instance Semigroup Registry where
    (<>) = mergeRegistries

instance Monoid Registry where
    mempty = emptyRegistry

-- | Drop repeated entries; for namespaces keep the last declaration of each prefix.
deduplicateRegistry :: Registry -> Registry
deduplicateRegistry reg = Registry
    { concepts    = nubOrd (concepts reg)
    , axioms      = nubOrd (axioms reg)
    , properties  = nubOrd (properties reg)
    , relations   = nubOrd (relations reg)
    , imports     = nubOrd (imports reg)
    , namespaces  = nubByPrefix (namespaces reg)
    , individuals = nubOrd (individuals reg)
    }
  where
    nubByPrefix = foldr (\n acc -> if any (\x -> nsPrefix x == nsPrefix n) acc then acc else n : acc) []

data PropertyDef = PropertyDef 
    { propName        :: Name
    , domain          :: Name
    , rangeType       :: PropertyType
    , propCardinality :: Cardinality
    , propDefault     :: Maybe String
    } deriving (Show, Eq, Ord, Generic)

instance Hashable PropertyDef

type Property = PropertyDef

pattern Property :: Name -> Name -> PropertyType -> PropertyDef
pattern Property n d r <- PropertyDef n d r _ _
  where
    Property n d r = PropertyDef n d r CardDefault Nothing

{-# COMPLETE Property #-}

getLocalConstraints :: Name -> [FOL] -> [(Name, String, String)]
getLocalConstraints conceptName = concatMap (extract [])
  where
    -- Only (forall (v) (implies (C v) body)) with C == conceptName and v bound yields bounds;
    -- conjunctive antecedents apply to a subset and stay in irUnmappedAxioms.
    extract bound (ForAll v body) = extract (v : bound) body
    extract bound (TypedForAll v _ body) = extract (v : bound) body
    extract bound (Implies (Predicate name [Var x]) body)
        | name == conceptName && x `elem` bound = extractSimplePredicates body
    extract _ _ = []

    extractSimplePredicates (Predicate op [Var prop, Constant val]) = [(prop, op, val)]
    extractSimplePredicates (Eq (Var prop) (Constant val)) = [(prop, "eq", val)]
    extractSimplePredicates (And p1 p2) = extractSimplePredicates p1 ++ extractSimplePredicates p2
    extractSimplePredicates _ = []

-- | Bounds that apply to a concept: its own, then each ancestor's, nearest first.
getInheritedConstraints :: Name -> [(Name, Maybe Name)] -> [FOL] -> [(Name, String, String)]
getInheritedConstraints conceptName conceptsList axs =
    concatMap (`getLocalConstraints` axs) (conceptName : getAncestors conceptName conceptsList)

isInherited :: Name -> Property -> [(Name, Maybe Name)] -> Bool
isInherited name p conceptsList =
    domain p `elem` getAncestors name conceptsList

-- | Parents, grandparents, ... of a concept, nearest first. Stops at a cycle.
getAncestors :: Name -> [(Name, Maybe Name)] -> [Name]
getAncestors name conceptsList = go (Set.singleton name) name
  where
    go seen n = case lookup n conceptsList of
        Just (Just parent) | not (Set.member parent seen) -> parent : go (Set.insert parent seen) parent
        _ -> []

-- | Sanitize qualified/namespaced identifiers for target languages (Java, Python, Mermaid)
sanitizeIdent :: String -> String
sanitizeIdent = map (\c -> if c `elem` [':', '-', '.'] then '_' else c)

-- | Escape string constants and descriptions for target code generation
escapeTargetString :: String -> String
escapeTargetString [] = []
escapeTargetString ('\\':cs) = "\\\\" ++ escapeTargetString cs
escapeTargetString ('"':cs)  = "\\\"" ++ escapeTargetString cs
escapeTargetString ('\n':cs) = "\\n" ++ escapeTargetString cs
escapeTargetString ('\r':cs) = "\\r" ++ escapeTargetString cs
escapeTargetString ('\t':cs) = "\\t" ++ escapeTargetString cs
escapeTargetString (c:cs)    = c : escapeTargetString cs

-- | Extract multi-premise or conditional constraints where conceptName is the subject.
getLocalConditionalConstraints :: Name -> [FOL] -> [ConditionalConstraint]
getLocalConditionalConstraints conceptName = concatMap (extract [])
  where
    extract bound (ForAll v body) = extract (v : bound) body
    extract bound (TypedForAll v _ body) = extract (v : bound) body
    -- Pattern 1: (forall (x) (implies (C x) (implies premise conclusion)))
    extract bound (Implies (Predicate name [Var x]) (Implies premise conclusion))
        | name == conceptName && x `elem` bound =
            [ConditionalConstraint premise conclusion (formatConditional premise conclusion)]
    -- Pattern 2: (forall (x) (implies (and ... (C x) ...) conclusion))
    extract bound (Implies ant conclusion) =
        let conjuncts = flattenAnd ant
            isTargetConcept (Predicate name [Var x]) = name == conceptName && x `elem` bound
            isTargetConcept _ = False
        in case filter isTargetConcept conjuncts of
            [_] ->
                let remaining = filter (not . isTargetConcept) conjuncts
                in if null remaining
                   then []
                   else let premise = foldr1 And remaining
                        in [ConditionalConstraint premise conclusion (formatConditional premise conclusion)]
            _ -> []
    extract _ _ = []

flattenAnd :: FOL -> [FOL]
flattenAnd (And p q) = flattenAnd p ++ flattenAnd q
flattenAnd p = [p]

formatFOL :: FOL -> String
formatFOL (Predicate op args) = op ++ "(" ++ intercalate ", " (map formatTerm args) ++ ")"
formatFOL (And p1 p2) = formatFOL p1 ++ " and " ++ formatFOL p2
formatFOL (Or p1 p2)  = formatFOL p1 ++ " or " ++ formatFOL p2
formatFOL (Not p)     = "not " ++ formatFOL p
formatFOL (Implies p1 p2) = formatFOL p1 ++ " implies " ++ formatFOL p2
formatFOL (Iff p1 p2) = formatFOL p1 ++ " iff " ++ formatFOL p2
formatFOL (ForAll v p) = "forall " ++ v ++ " (" ++ formatFOL p ++ ")"
formatFOL (Exists v p) = "exists " ++ v ++ " (" ++ formatFOL p ++ ")"
formatFOL Top = "true"
formatFOL Bottom = "false"
formatFOL (Eq t1 t2) = formatTerm t1 ++ " = " ++ formatTerm t2
formatFOL (TypedForAll v s p) = "forall (" ++ v ++ " : " ++ s ++ ") (" ++ formatFOL p ++ ")"
formatFOL (TypedExists v s p) = "exists (" ++ v ++ " : " ++ s ++ ") (" ++ formatFOL p ++ ")"

formatTerm :: Term -> String
formatTerm (Var v) = v
formatTerm (Constant c) = c
formatTerm (Apply f args) = f ++ "(" ++ intercalate ", " (map formatTerm args) ++ ")"

formatConditional :: FOL -> FOL -> String
formatConditional p c = "if " ++ formatFOL p ++ " then " ++ formatFOL c



