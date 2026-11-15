module Emitters.Python where

import OntoLogic
import IR
import Data.List (intercalate)
import Text.Read (readMaybe)

emitPython :: Registry -> String
emitPython reg =
    let modelIR = compileRegistry reg
        classes = irClasses modelIR
        hasConditional = any (not . null . compEnforced) classes
        pydanticImport = if hasConditional
                         then "from pydantic import BaseModel, Field, model_validator\n"
                         else "from pydantic import BaseModel, Field\n"
        hasOptional = any (\c -> any (\p -> compCardinality p == CardZeroOrOne) (compProperties c)) classes
        hasList = any (\c -> any (\p -> compCardinality p `elem` [CardZeroOrMore, CardOneOrMore]) (compProperties c)) classes
        typingImport = case (hasOptional, hasList) of
            (True, True)   -> "from typing import Optional, List\n"
            (True, False)  -> "from typing import Optional\n"
            (False, True)  -> "from typing import List\n"
            (False, False) -> ""
        importSection = pydanticImport ++ (if null typingImport then "\n" else typingImport ++ "\n")
    in -- Relations can reference a class declared later in the file (or the class
       -- itself). Before PEP 649 (Python 3.14) annotations are evaluated eagerly,
       -- so such a reference raises NameError at import; the future import defers
       -- it and model_rebuild resolves it once every class exists.
       "from __future__ import annotations\n\n" ++
       importSection ++
       concatMap emitPythonClass classes ++
       concatMap (\c -> sanitizeIdent (compClassName c) ++ ".model_rebuild()\n") classes

emitPythonClass :: CompiledClass -> String
emitPythonClass cls =
    "class " ++ sanitizeIdent (compClassName cls) ++ "(" ++ maybe "BaseModel" sanitizeIdent (compParentClass cls) ++ "):\n" ++
    (if null (compProperties cls) && null (compEnforced cls)
     then "    pass\n\n"
     else concatMap emitFieldWithConstraints (compProperties cls) ++
          emitPythonConditionalValidators (compClassName cls) (compEnforced cls) ++ "\n")

-- | The method name carries the class name: a subclass that reused one name would replace the
--   inherited validator and silently stop enforcing the parent's conditionals.
emitPythonConditionalValidators :: Name -> [ConditionalConstraint] -> String
emitPythonConditionalValidators _ [] = ""
emitPythonConditionalValidators cName axs =
    "\n    @model_validator(mode=\"after\")\n" ++
    "    def validate_conditional_constraints_" ++ sanitizeIdent cName ++ "(self):\n" ++
    concatMap emitSingleValidator axs ++
    "        return self\n"

emitSingleValidator :: ConditionalConstraint -> String
emitSingleValidator ax =
    "        if " ++ guardExpr ++ ":\n" ++
    "            raise ValueError(\"Constraint failed: " ++ escapePy (condDescription ax) ++ "\")\n"
  where
    guardExpr = case condPremise ax of
        Top -> "not (" ++ emitPythonExpr (condConclusion ax) ++ ")"
        pre -> emitPythonExpr pre ++ " and not (" ++ emitPythonExpr (condConclusion ax) ++ ")"

-- | Total on what 'IR.normalizeCondition' produces. Anything else was kept out of the
--   conditional list upstream; reaching it here is a bug, so it fails loudly instead of
--   becoming a check that cannot fail.
emitPythonExpr :: FOL -> String
emitPythonExpr (Predicate op [Var prop, Constant val]) | op `elem` comparisonOps = emitPythonBinary op prop val
emitPythonExpr (Predicate flag []) = "(str(getattr(self, '" ++ sanitizeIdent flag ++ "', None)).lower() == 'true')"
emitPythonExpr (And p1 p2) = "(" ++ emitPythonExpr p1 ++ " and " ++ emitPythonExpr p2 ++ ")"
emitPythonExpr (Or p1 p2)  = "(" ++ emitPythonExpr p1 ++ " or " ++ emitPythonExpr p2 ++ ")"
emitPythonExpr (Not p)     = "not (" ++ emitPythonExpr p ++ ")"
emitPythonExpr Top         = "True"
emitPythonExpr Bottom      = "False"
emitPythonExpr other       = error ("Python emitter: untranslatable conditional " ++ formatFOL other)

emitPythonBinary :: String -> Name -> String -> String
emitPythonBinary op prop val =
    let fld = "self." ++ sanitizeIdent prop
    in case op of
        "eq" | val `elem` ["True", "true"]   -> "(str(getattr(self, '" ++ sanitizeIdent prop ++ "', None)).lower() == 'true')"
             | val `elem` ["False", "false"] -> "(str(getattr(self, '" ++ sanitizeIdent prop ++ "', None)).lower() == 'false')"
             | isNumber val                  -> "(" ++ fld ++ " is not None and " ++ fld ++ " == " ++ val ++ ")"
             | otherwise                     -> "(" ++ fld ++ " == \"" ++ escapePy val ++ "\")"
        "ne" | val `elem` ["True", "true"]   -> "(str(getattr(self, '" ++ sanitizeIdent prop ++ "', None)).lower() != 'true')"
             | val `elem` ["False", "false"] -> "(str(getattr(self, '" ++ sanitizeIdent prop ++ "', None)).lower() != 'false')"
             | isNumber val                  -> "(" ++ fld ++ " is None or " ++ fld ++ " != " ++ val ++ ")"
             | otherwise                     -> "(" ++ fld ++ " != \"" ++ escapePy val ++ "\")"
        "gt"  -> "(" ++ fld ++ " is not None and " ++ fld ++ " > " ++ val ++ ")"
        "gte" -> "(" ++ fld ++ " is not None and " ++ fld ++ " >= " ++ val ++ ")"
        "lt"  -> "(" ++ fld ++ " is not None and " ++ fld ++ " < " ++ val ++ ")"
        "lte" -> "(" ++ fld ++ " is not None and " ++ fld ++ " <= " ++ val ++ ")"
        _     -> error ("Python emitter: unknown comparison " ++ op)

escapePy :: String -> String
escapePy = escapeTargetString

isNumber :: String -> Bool
isNumber s = case (readMaybe s :: Maybe Double) of
    Just _  -> True
    Nothing -> False

emitFieldWithConstraints :: CompiledProperty -> String
emitFieldWithConstraints p =
    let baseType = mapPythonType (compPropType p)
        fieldArgs = mapConstraintToPydantic (compPropType p) (compConstraints p)
        comment = if compIsInherited p
                  then "    # Overridden inherited property with subclass constraints\n"
                  else ""
        fName = sanitizeIdent (compPropName p)
    in comment ++ case compCardinality p of
        CardZeroOrOne ->
            let fieldStr = if null fieldArgs then "None" else "Field(default=None, " ++ fieldArgs ++ ")"
            in "    " ++ fName ++ ": Optional[" ++ baseType ++ "] = " ++ fieldStr ++ "\n"
        CardZeroOrMore ->
            "    " ++ fName ++ ": List[" ++ baseType ++ "] = Field(default_factory=list)\n"
        CardOneOrMore ->
            "    " ++ fName ++ ": List[" ++ baseType ++ "] = Field(min_length=1)\n"
        _ ->
            case compDefaultValue p of
                Just d ->
                    let defStr = formatPyDefault (compPropType p) d
                        fieldStr = if null fieldArgs then defStr else "Field(default=" ++ defStr ++ ", " ++ fieldArgs ++ ")"
                    in "    " ++ fName ++ ": " ++ baseType ++ " = " ++ fieldStr ++ "\n"
                Nothing ->
                    let fieldStr = if null fieldArgs then "" else " = Field(" ++ fieldArgs ++ ")"
                    in "    " ++ fName ++ ": " ++ baseType ++ fieldStr ++ "\n"

formatPyDefault :: PropertyType -> String -> String
formatPyDefault PTString s = show s
formatPyDefault PTBoolean "true" = "True"
formatPyDefault PTBoolean "True" = "True"
formatPyDefault PTBoolean "false" = "False"
formatPyDefault PTBoolean "False" = "False"
formatPyDefault _ val = val

mapConstraintToPydantic :: PropertyType -> [BoundConstraint] -> String
mapConstraintToPydantic pType constraints = 
    if not (pType `elem` [PTInteger, PTFloat, PTDouble])
    then ""
    else let args = filter (not . null) (map mapOpt constraints)
          in intercalate ", " args
  where
    mapOpt (BoundConstraint OpGt val)  = "gt=" ++ valueToString val
    mapOpt (BoundConstraint OpGte val) = "ge=" ++ valueToString val
    mapOpt (BoundConstraint OpLt val)  = "lt=" ++ valueToString val
    mapOpt (BoundConstraint OpLte val) = "le=" ++ valueToString val
    mapOpt _ = ""

mapPythonType :: PropertyType -> String
mapPythonType PTInteger    = "int"
mapPythonType PTFloat      = "float"
mapPythonType PTDouble     = "float"
mapPythonType PTBoolean    = "bool"
mapPythonType PTString     = "str"
mapPythonType (PTCustom c) = sanitizeIdent c
