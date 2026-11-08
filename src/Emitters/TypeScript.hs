module Emitters.TypeScript (emitTypeScript) where

import Data.Maybe (fromMaybe)
import OntoLogic
import IR


import Text.Read (readMaybe)

-- | Emit TypeScript interfaces and Zod runtime validation schemas from ModelIR
emitTypeScript :: Registry -> String
emitTypeScript reg =
    let modelIR = compileRegistry reg
        classes = irClasses modelIR
        refs = [ (compClassName c, [ t | p <- compProperties c, PTCustom t <- [compPropType p] ])
               | c <- classes ]
        -- True when a field in `from` pointing at `to` closes a reference cycle, so the
        -- schema's inferred type would depend on itself.
        isCyclic from to = from `elem` reachableFrom refs to
    in "import { z } from \"zod\";\n\n" ++
       concatMap (emitTypeScriptClass isCyclic) classes

-- | Every class reachable from the given one by custom-typed properties, itself included.
reachableFrom :: [(Name, [Name])] -> Name -> [Name]
reachableFrom refs = go []
  where
    go seen n
        | n `elem` seen = seen
        | otherwise     = foldl go (n : seen) (fromMaybe [] (lookup n refs))

emitTypeScriptClass :: (Name -> Name -> Bool) -> CompiledClass -> String
emitTypeScriptClass isCyclic cls =
    let cName = sanitizeIdent (compClassName cls)
        -- Direct properties plus inherited ones the subclass re-bounds: .extend() has to
        -- re-state an inherited property for the narrower bound to reach the schema.
        props = compProperties cls
        fields = concatMap (emitZodField (isCyclic (compClassName cls))) props

        baseSchema = case compParentClass cls of
            Nothing ->
                "export const " ++ cName ++ "Schema = z.object({\n" ++ fields ++ "})"
            Just pName ->
                "export const " ++ cName ++ "Schema = " ++ sanitizeIdent pName ++
                "Schema.extend({\n" ++ fields ++ "})"

        refines = concatMap emitTsRefine (compConditionalAxioms cls)
        schemaDef = baseSchema ++ refines ++ ";\n\n"

        typeAlias = "export type " ++ cName ++ " = z.infer<typeof " ++ cName ++ "Schema>;\n\n"
    in schemaDef ++ typeAlias

emitZodField :: (Name -> Bool) -> CompiledProperty -> String
emitZodField cyclic p =
    let fName = sanitizeIdent (compPropName p)
        baseZType = mapZodType cyclic (compPropType p) (compConstraints p)
        cardZType = case compCardinality p of
            CardZeroOrOne  -> baseZType ++ ".optional()"
            CardZeroOrMore -> "z.array(" ++ baseZType ++ ")"
            CardOneOrMore  -> "z.array(" ++ baseZType ++ ").nonempty()"
            _              -> baseZType
        defZType = case compDefaultValue p of
            Just d  -> cardZType ++ ".default(" ++ formatTsDefault (compPropType p) d ++ ")"
            Nothing -> cardZType
    in "  " ++ fName ++ ": " ++ defZType ++ ",\n"

formatTsDefault :: PropertyType -> String -> String
formatTsDefault PTString s = show s
formatTsDefault PTBoolean "True" = "true"
formatTsDefault PTBoolean "true" = "true"
formatTsDefault PTBoolean "False" = "false"
formatTsDefault PTBoolean "false" = "false"
formatTsDefault _ val = val

mapZodType :: (Name -> Bool) -> PropertyType -> [BoundConstraint] -> String
mapZodType cyclic (PTCustom c) _
    -- Annotating the thunk's return type breaks the self-referential inference that
    -- tsc rejects with TS7022/TS7024; non-cyclic references keep their precise type.
    | cyclic c  = "z.lazy((): z.ZodTypeAny => " ++ sanitizeIdent c ++ "Schema)"
    | otherwise = "z.lazy(() => " ++ sanitizeIdent c ++ "Schema)"
mapZodType _ PTString _     = "z.string()"
mapZodType _ PTBoolean _    = "z.boolean()"
mapZodType _ PTInteger constraints =
    let base = "z.number().int()"
        bounds = concatMap mapNumericBound constraints
    in base ++ bounds
mapZodType _ PTFloat constraints =
    let base = "z.number()"
        bounds = concatMap mapNumericBound constraints
    in base ++ bounds
mapZodType _ PTDouble constraints =
    let base = "z.number()"
        bounds = concatMap mapNumericBound constraints
    in base ++ bounds

mapNumericBound :: BoundConstraint -> String
mapNumericBound (BoundConstraint OpGt val)  = ".gt(" ++ valueToString val ++ ")"
mapNumericBound (BoundConstraint OpGte val) = ".gte(" ++ valueToString val ++ ")"
mapNumericBound (BoundConstraint OpLt val)  = ".lt(" ++ valueToString val ++ ")"
mapNumericBound (BoundConstraint OpLte val) = ".lte(" ++ valueToString val ++ ")"
mapNumericBound (BoundConstraint OpEq val)  = ".refine((val) => val === " ++ valueToString val ++ ", { message: \"Must equal " ++ valueToString val ++ "\" })"
mapNumericBound _                           = ""

emitTsRefine :: ConditionalConstraint -> String
emitTsRefine ax =
    "\n  .refine((data: any) => {\n" ++
    "    if (" ++ emitTsExpr (condPremise ax) ++ ") {\n" ++
    "      return " ++ emitTsExpr (condConclusion ax) ++ ";\n" ++
    "    }\n" ++
    "    return true;\n" ++
    "  }, { message: \"Axiom violation: " ++ escapeJson (condDescription ax) ++ "\" })"

emitTsExpr :: FOL -> String
emitTsExpr (Predicate op args)
    | op `elem` ["eq", "ne", "gt", "gte", "lt", "lte"] =
        case args of
            [Var prop, Constant val] -> emitTsBinary op prop val
            [Constant val, Var prop] -> emitTsBinary (invertCompOp op) prop val
            _ -> "true"
    | otherwise =
        case args of
            (Var prop:_) -> "Boolean(data." ++ sanitizeIdent prop ++ ")"
            []           -> "Boolean(data." ++ sanitizeIdent op ++ ")"
            _            -> "true"
emitTsExpr (And p1 p2) = "(" ++ emitTsExpr p1 ++ " && " ++ emitTsExpr p2 ++ ")"
emitTsExpr (Or p1 p2)  = "(" ++ emitTsExpr p1 ++ " || " ++ emitTsExpr p2 ++ ")"
emitTsExpr (Not p)     = "!(" ++ emitTsExpr p ++ ")"
emitTsExpr _           = "true"

emitTsBinary :: String -> Name -> String -> String
emitTsBinary op prop val =
    let fld = "data." ++ sanitizeIdent prop
        valExpr = case val of
            "True"  -> "true"
            "False" -> "false"
            v | isNumber v -> v
            v -> "\"" ++ escapeJson v ++ "\""
        tsOp = case op of
            "eq"  -> "==="
            "ne"  -> "!=="
            "gt"  -> ">"
            "gte" -> ">="
            "lt"  -> "<"
            "lte" -> "<="
            _     -> "==="
    in "(" ++ fld ++ " " ++ tsOp ++ " " ++ valExpr ++ ")"

invertCompOp :: String -> String
invertCompOp "gt"  = "lt"
invertCompOp "gte" = "lte"
invertCompOp "lt"  = "gt"
invertCompOp "lte" = "gte"
invertCompOp op    = op

escapeJson :: String -> String
escapeJson = escapeTargetString

isNumber :: String -> Bool
isNumber s = case (readMaybe s :: Maybe Double) of
    Just _  -> True
    Nothing -> False
