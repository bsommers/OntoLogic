module Emitters.JsonSchema (emitJsonSchema) where

import OntoLogic
import IR
import Data.List (intercalate)

-- | Emit a W3C / IETF JSON Schema (Draft 2020-12) representation of the ModelIR
emitJsonSchema :: Registry -> String
emitJsonSchema reg =
    let modelIR = compileRegistry reg
        classes = irClasses modelIR
        defs = intercalate ",\n" (map emitClassSchema classes)
    in "{\n" ++
       "  \"$schema\": \"https://json-schema.org/draft/2020-12/schema\",\n" ++
       "  \"$id\": \"https://ontologic.dev/schemas/ontology.json\",\n" ++
       "  \"title\": \"OntoLogic Compiled Schema\",\n" ++
       "  \"type\": \"object\",\n" ++
       "  \"$defs\": {\n" ++
       defs ++ "\n" ++
       "  }\n" ++
       "}\n"

emitClassSchema :: CompiledClass -> String
emitClassSchema cls =
    let cName = sanitizeIdent (compClassName cls)
        props = compProperties cls
        directProps = filter (not . compIsInherited) props
        parent = compParentClass cls
        requiredLine ps =
            let req = [ "\"" ++ sanitizeIdent (compPropName p) ++ "\""
                      | p <- ps
                      , compCardinality p `elem` [CardExactlyOne, CardOneOrMore, CardDefault]
                      ]
            in if null req then "" else ",\n      \"required\": [" ++ intercalate ", " req ++ "]"
    in case parent of
        Nothing ->
            "    \"" ++ cName ++ "\": {\n" ++
            "      \"type\": \"object\",\n" ++
            "      \"title\": \"" ++ compClassName cls ++ "\",\n" ++
            "      \"properties\": {\n" ++
            emitProperties directProps ++ "\n" ++
            "      }" ++ requiredLine directProps ++ "\n" ++
            "    }"
        Just pName ->
            let overriddenProps = filter compIsInherited props
                allClassProps = if null overriddenProps then directProps else directProps ++ overriddenProps
            in "    \"" ++ cName ++ "\": {\n" ++
               "      \"title\": \"" ++ compClassName cls ++ "\",\n" ++
               "      \"allOf\": [\n" ++
               "        { \"$ref\": \"#/$defs/" ++ sanitizeIdent pName ++ "\" },\n" ++
               "        {\n" ++
               "          \"type\": \"object\",\n" ++
               "          \"properties\": {\n" ++
               emitProperties allClassProps ++ "\n" ++
               "          }" ++ requiredLine allClassProps ++ "\n" ++
               "        }\n" ++
               "      ]\n" ++
               "    }"

emitProperties :: [CompiledProperty] -> String
emitProperties [] = ""
emitProperties ps =
    let propEntries = map emitSingleProperty ps
    in intercalate ",\n" propEntries

emitSingleProperty :: CompiledProperty -> String
emitSingleProperty p =
    let pName = sanitizeIdent (compPropName p)
        pType = compPropType p
        constraints = compConstraints p
        defField = case compDefaultValue p of
            Just d  -> ["\"default\": " ++ formatJsonDefault pType d]
            Nothing -> []
        innerFields = propertyTypeFields pType constraints
        fields = case compCardinality p of
            CardZeroOrMore ->
                [ "\"type\": \"array\""
                , "\"items\": {\n" ++ intercalate ",\n" (map ("            " ++) innerFields) ++ "\n          }"
                ] ++ defField
            CardOneOrMore ->
                [ "\"type\": \"array\""
                , "\"minItems\": 1"
                , "\"items\": {\n" ++ intercalate ",\n" (map ("            " ++) innerFields) ++ "\n          }"
                ] ++ defField
            _ ->
                innerFields ++ defField
    in "        \"" ++ pName ++ "\": {\n" ++
       intercalate ",\n" (map ("          " ++) fields) ++ "\n" ++
       "        }"

formatJsonDefault :: PropertyType -> String -> String
formatJsonDefault PTString s = show s
formatJsonDefault PTBoolean "True" = "true"
formatJsonDefault PTBoolean "true" = "true"
formatJsonDefault PTBoolean "False" = "false"
formatJsonDefault PTBoolean "false" = "false"
formatJsonDefault _ val = val

propertyTypeFields :: PropertyType -> [BoundConstraint] -> [String]
propertyTypeFields (PTCustom c) _ =
    [ "\"$ref\": \"#/$defs/" ++ sanitizeIdent c ++ "\"" ]
propertyTypeFields pt constraints =
    let typeField = "\"type\": \"" ++ jsonTypeName pt ++ "\""
        constraintFields = mapConstraintToJsonSchema pt constraints
    in typeField : constraintFields

jsonTypeName :: PropertyType -> String
jsonTypeName PTInteger = "integer"
jsonTypeName PTFloat   = "number"
jsonTypeName PTDouble  = "number"
jsonTypeName PTBoolean = "boolean"
jsonTypeName PTString  = "string"
jsonTypeName (PTCustom _) = "object"

mapConstraintToJsonSchema :: PropertyType -> [BoundConstraint] -> [String]
mapConstraintToJsonSchema pt constraints
    | pt `notElem` [PTInteger, PTFloat, PTDouble] = []
    | otherwise = concatMap mapConstraint constraints
  where
    mapConstraint (BoundConstraint OpGt val)  = ["\"exclusiveMinimum\": " ++ valueToString val]
    mapConstraint (BoundConstraint OpGte val) = ["\"minimum\": " ++ valueToString val]
    mapConstraint (BoundConstraint OpLt val)  = ["\"exclusiveMaximum\": " ++ valueToString val]
    mapConstraint (BoundConstraint OpLte val) = ["\"maximum\": " ++ valueToString val]
    mapConstraint (BoundConstraint OpEq val)  = ["\"const\": " ++ valueToString val]
    mapConstraint _                           = []
