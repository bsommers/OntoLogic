module Emitters.Shacl (emitShacl, emitShaclWithBase) where

import OntoLogic
import IR
import Data.List (intercalate)
import Data.Maybe (isJust)
import Text.Read (readMaybe)

-- | Emit W3C SHACL Shapes (Turtle format) from Registry and ModelIR
emitShacl :: Registry -> String
emitShacl reg = emitShaclWithBase (resolveBaseIri Nothing reg) reg

emitShaclWithBase :: String -> Registry -> String
emitShaclWithBase base reg =
    let modelIR = compileRegistry reg
        prefixes = emitPrefixes base (namespaces reg)
        fmt = formatIri (namespaces reg) base
        shapes = concatMap (emitNodeShape fmt) (irClasses modelIR)
    in prefixes ++ "\n" ++ shapes

emitPrefixes :: String -> [NamespaceDecl] -> String
emitPrefixes base customNs =
    "@prefix sh: <http://www.w3.org/ns/shacl#> .\n" ++
    "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n" ++
    "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n" ++
    "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n" ++
    "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n" ++
    "@prefix ont: <" ++ base ++ "#> .\n" ++
    concatMap emitCustomPrefix customNs
  where
    -- Only namespaces that declared a URI. "prefix#" is a relative IRI, and nothing
    -- refers to such a prefix any more: formatIri writes those names out absolutely.
    emitCustomPrefix ns = case nsUri ns of
        Just u  -> "@prefix " ++ nsPrefix ns ++ ": <" ++ u ++ "> .\n"
        Nothing -> ""

emitNodeShape :: (Name -> String) -> CompiledClass -> String
emitNodeShape fmt cls =
    let cName = compClassName cls
        shapeIri = "ont:" ++ sanitizeIdent cName ++ "Shape"
        targetIri = fmt cName
        props = compProperties cls
        propShapes = map (emitPropertyShape fmt) props
        condShapes = map (emitConditionalShape fmt) (compConditionalAxioms cls)
        allShapes = propShapes ++ condShapes
        propBlock = if null allShapes
                    then "    sh:targetClass " ++ targetIri ++ " .\n\n"
                    else "    sh:targetClass " ++ targetIri ++ " ;\n" ++
                         intercalate " ;\n" allShapes ++ " .\n\n"
    in shapeIri ++ "\n" ++
       "    a sh:NodeShape ;\n" ++
       propBlock

emitPropertyShape :: (Name -> String) -> CompiledProperty -> String
emitPropertyShape fmt p =
    let pName = compPropName p
        pType = compPropType p
        constraints = compConstraints p
        pathLine = "        sh:path " ++ fmt pName ++ " ;"
        typeLine = case pType of
                     PTCustom c -> "        sh:class " ++ fmt c ++ " ;"
                     _          -> "        sh:datatype " ++ shaclDatatype pType ++ " ;"
        cardLines = case compCardinality p of
                      CardZeroOrOne  -> ["sh:maxCount 1 ;"]
                      CardOneOrMore  -> ["sh:minCount 1 ;"]
                      CardExactlyOne -> ["sh:minCount 1 ;", "sh:maxCount 1 ;"]
                      _              -> []
        constraintLines = mapConstraintToShacl pType constraints
        allLines = pathLine : typeLine : map ("        " ++) (cardLines ++ constraintLines)
        body = intercalate "\n" (init allLines) ++ "\n" ++ (stripTrailingSemicolon (last allLines))
    in "    sh:property [\n" ++ body ++ "\n    ]"

-- | A Turtle term for a declared name, resolving to the same IRI as 'resolveIri'
--   (and so as the OWL output). A declared prefix keeps its readable prefixed form,
--   which Turtle expands identically. An undeclared prefix used to be written as-is
--   with no @prefix line for it, which is not Turtle at all; it is now written out
--   as an absolute IRI.
formatIri :: [NamespaceDecl] -> String -> Name -> String
formatIri nss base name =
    case break (== ':') name of
        (pfx, ':':_) | isJust (namespaceUri pfx nss) -> name
                     | otherwise -> "<" ++ resolveIri nss base name ++ ">"
        _ -> "ont:" ++ name

shaclDatatype :: PropertyType -> String
shaclDatatype PTInteger = "xsd:integer"
shaclDatatype PTFloat   = "xsd:float"
shaclDatatype PTDouble  = "xsd:double"
shaclDatatype PTBoolean = "xsd:boolean"
shaclDatatype PTString  = "xsd:string"
shaclDatatype (PTCustom c) = "ont:" ++ c

mapConstraintToShacl :: PropertyType -> [BoundConstraint] -> [String]
mapConstraintToShacl pt constraints
    | pt `notElem` [PTInteger, PTFloat, PTDouble] = []
    | otherwise = concatMap mapConstraint constraints
  where
    mapConstraint (BoundConstraint OpGt val)  = ["sh:minExclusive " ++ valueToString val ++ " ;"]
    mapConstraint (BoundConstraint OpGte val) = ["sh:minInclusive " ++ valueToString val ++ " ;"]
    mapConstraint (BoundConstraint OpLt val)  = ["sh:maxExclusive " ++ valueToString val ++ " ;"]
    mapConstraint (BoundConstraint OpLte val) = ["sh:maxInclusive " ++ valueToString val ++ " ;"]
    mapConstraint (BoundConstraint OpEq val)  = ["sh:hasValue " ++ valueToString val ++ " ;"]
    mapConstraint _                           = []

stripTrailingSemicolon :: String -> String
stripTrailingSemicolon s =
    let rev = reverse s
        dropped = dropWhile (\c -> c == ' ' || c == ';') rev
    in reverse dropped

emitConditionalShape :: (Name -> String) -> ConditionalConstraint -> String
emitConditionalShape fmt ax =
    "    sh:or (\n" ++
    "        [\n" ++
    "            sh:not [\n" ++
    emitShaclShapePattern fmt (condPremise ax) ++
    "            ]\n" ++
    "        ]\n" ++
    "        [\n" ++
    emitShaclShapePattern fmt (condConclusion ax) ++
    "        ]\n" ++
    "    )"

emitShaclShapePattern :: (Name -> String) -> FOL -> String
emitShaclShapePattern fmt (Predicate op args)
    | op `elem` ["eq", "ne", "gt", "gte", "lt", "lte"] =
        case args of
            [Var prop, Constant val] -> emitShaclPropBound fmt op prop val
            [Constant val, Var prop] -> emitShaclPropBound fmt (invertCompOp op) prop val
            _ -> ""
    | otherwise =
        case args of
            (Var prop:_) ->
                "            sh:property [\n" ++
                "                sh:path " ++ fmt prop ++ " ;\n" ++
                "                sh:hasValue true ;\n" ++
                "            ] ;\n"
            [] ->
                "            sh:property [\n" ++
                "                sh:path " ++ fmt op ++ " ;\n" ++
                "                sh:hasValue true ;\n" ++
                "            ] ;\n"
            _ -> ""
emitShaclShapePattern fmt (And p1 p2) =
    emitShaclShapePattern fmt p1 ++ emitShaclShapePattern fmt p2
emitShaclShapePattern fmt (Or p1 p2) =
    "            sh:or (\n" ++
    "                [ " ++ emitShaclShapePattern fmt p1 ++ " ]\n" ++
    "                [ " ++ emitShaclShapePattern fmt p2 ++ " ]\n" ++
    "            ) ;\n"
emitShaclShapePattern fmt (Not p) =
    "            sh:not [\n" ++ emitShaclShapePattern fmt p ++ "            ] ;\n"
emitShaclShapePattern _ _ = ""

emitShaclPropBound :: (Name -> String) -> String -> Name -> String -> String
emitShaclPropBound fmt op prop val =
    let pathLine = "                sh:path " ++ fmt prop ++ " ;\n"
        boundLine = case op of
            "gt"  -> "                sh:minExclusive " ++ val ++ " ;\n"
            "gte" -> "                sh:minInclusive " ++ val ++ " ;\n"
            "lt"  -> "                sh:maxExclusive " ++ val ++ " ;\n"
            "lte" -> "                sh:maxInclusive " ++ val ++ " ;\n"
            "eq"  | val `elem` ["True", "true"]   -> "                sh:hasValue true ;\n"
                  | val `elem` ["False", "false"] -> "                sh:hasValue false ;\n"
                  | isNumber val                  -> "                sh:hasValue " ++ val ++ " ;\n"
                  | otherwise                     -> "                sh:hasValue \"" ++ val ++ "\" ;\n"
            "ne"  -> "                sh:not [ sh:hasValue " ++ val ++ " ] ;\n"
            _     -> ""
    in "            sh:property [\n" ++ pathLine ++ boundLine ++ "            ] ;\n"

invertCompOp :: String -> String
invertCompOp "gt"  = "lt"
invertCompOp "gte" = "lte"
invertCompOp "lt"  = "gt"
invertCompOp "lte" = "gte"
invertCompOp op    = op

isNumber :: String -> Bool
isNumber s = case (readMaybe s :: Maybe Double) of
    Just _  -> True
    Nothing -> False
