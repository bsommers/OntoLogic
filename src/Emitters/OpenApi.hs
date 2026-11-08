module Emitters.OpenApi (emitOpenApi) where

import OntoLogic
import IR


-- | Emit OpenAPI 3.1 Components & Schemas in YAML format from ModelIR
emitOpenApi :: Registry -> String
emitOpenApi reg =
    let modelIR = compileRegistry reg
        classes = irClasses modelIR
        schemas = concatMap emitOpenApiSchema classes
    in "openapi: 3.1.0\n" ++
       "info:\n" ++
       "  title: OntoLogic Compiled API Specification\n" ++
       "  version: 1.0.0\n" ++
       "components:\n" ++
       "  schemas:\n" ++
       schemas

emitOpenApiSchema :: CompiledClass -> String
emitOpenApiSchema cls =
    let cName = sanitizeIdent (compClassName cls)
        parent = compParentClass cls
        directProps = filter (not . compIsInherited) (compProperties cls)
        requiredBlock indent ps =
            let req = [ indent ++ "- " ++ sanitizeIdent (compPropName p) ++ "\n"
                      | p <- ps
                      , compCardinality p `elem` [CardExactlyOne, CardOneOrMore, CardDefault]
                      ]
            in if null req then "" else indent ++ "required:\n" ++ concat req
    in case parent of
        Nothing ->
            "    " ++ cName ++ ":\n" ++
            "      type: object\n" ++
            "      title: " ++ compClassName cls ++ "\n" ++
            requiredBlock "      " directProps ++
            propsBlock "      " directProps
        Just pName ->
            let overriddenProps = filter compIsInherited (compProperties cls)
                allProps = if null overriddenProps then directProps else directProps ++ overriddenProps
            in "    " ++ cName ++ ":\n" ++
               "      title: " ++ compClassName cls ++ "\n" ++
               "      allOf:\n" ++
               "        - $ref: '#/components/schemas/" ++ sanitizeIdent pName ++ "'\n" ++
               "        - type: object\n" ++
               requiredBlock "          " allProps ++
               propsBlock "          " allProps

-- | A bare `properties:` key parses as null, which is not a valid schema; a concept
--   with no fields needs an explicit empty mapping.
propsBlock :: String -> [CompiledProperty] -> String
propsBlock indent ps
    | null ps   = indent ++ "properties: {}\n"
    | otherwise = indent ++ "properties:\n" ++ concatMap emitOpenApiField ps

emitOpenApiField :: CompiledProperty -> String
emitOpenApiField p =
    let fName = sanitizeIdent (compPropName p)
        pType = compPropType p
        constraints = compConstraints p
        defLine indent = case compDefaultValue p of
            Just d  -> indent ++ "default: " ++ formatOpenApiDefault pType d ++ "\n"
            Nothing -> ""
        typeLines indent = case pType of
            PTCustom c -> indent ++ "$ref: '#/components/schemas/" ++ sanitizeIdent c ++ "'\n"
            _          -> indent ++ "type: " ++ openApiTypeName pType ++ "\n" ++
                          concatMap (emitOpenApiConstraint indent) constraints
    in case compCardinality p of
        CardZeroOrMore ->
            "        " ++ fName ++ ":\n" ++
            "          type: array\n" ++
            defLine "          " ++
            "          items:\n" ++
            typeLines "            "
        CardOneOrMore ->
            "        " ++ fName ++ ":\n" ++
            "          type: array\n" ++
            "          minItems: 1\n" ++
            defLine "          " ++
            "          items:\n" ++
            typeLines "            "
        _ ->
            "        " ++ fName ++ ":\n" ++
            defLine "          " ++
            typeLines "          "

formatOpenApiDefault :: PropertyType -> String -> String
formatOpenApiDefault PTString s = show s
formatOpenApiDefault PTBoolean "True" = "true"
formatOpenApiDefault PTBoolean "true" = "true"
formatOpenApiDefault PTBoolean "False" = "false"
formatOpenApiDefault PTBoolean "false" = "false"
formatOpenApiDefault _ val = val

openApiTypeName :: PropertyType -> String
openApiTypeName PTInteger = "integer"
openApiTypeName PTFloat   = "number"
openApiTypeName PTDouble  = "number"
openApiTypeName PTBoolean = "boolean"
openApiTypeName PTString  = "string"
openApiTypeName (PTCustom _) = "object"

emitOpenApiConstraint :: String -> BoundConstraint -> String
emitOpenApiConstraint indent (BoundConstraint OpGt val)  = indent ++ "exclusiveMinimum: " ++ valueToString val ++ "\n"
emitOpenApiConstraint indent (BoundConstraint OpGte val) = indent ++ "minimum: " ++ valueToString val ++ "\n"
emitOpenApiConstraint indent (BoundConstraint OpLt val)  = indent ++ "exclusiveMaximum: " ++ valueToString val ++ "\n"
emitOpenApiConstraint indent (BoundConstraint OpLte val) = indent ++ "maximum: " ++ valueToString val ++ "\n"
emitOpenApiConstraint indent (BoundConstraint OpEq val)  = indent ++ "const: " ++ valueToString val ++ "\n"
emitOpenApiConstraint _ _                                = ""
