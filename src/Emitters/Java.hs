module Emitters.Java where

import OntoLogic
import IR
import Data.Char (toUpper)
import Text.Read (readMaybe)

emitJava :: Registry -> [(String, String)]
emitJava = emitJavaWithPackage "ontologic.generated"

emitJavaWithPackage :: String -> Registry -> [(String, String)]
emitJavaWithPackage pkg reg =
    let modelIR = compileRegistry reg
    in map (\cls -> (sanitizeIdent (compClassName cls), emitJavaClass pkg cls)) (irClasses modelIR)

emitJavaClass :: String -> CompiledClass -> String
emitJavaClass pkg cls =
    "package " ++ pkg ++ ";\n" ++
    "import jakarta.validation.constraints.*;\n" ++
    (if null (compEnforced cls) then "" else "import java.util.Objects;\n") ++
    "\n" ++
    "public class " ++ sanitizeIdent (compClassName cls) ++ maybe "" (\p -> " extends " ++ sanitizeIdent p) (compParentClass cls) ++ " {\n" ++
    concatMap (emitFieldOrGetter (compClassName cls)) (compProperties cls) ++
    concatMap (emitJavaConditionalConstraint (compClassName cls)) (zip [1..] (compEnforced cls)) ++
    "}\n"

-- | The method name carries the class name: a subclass that reused "isValidConstraint1" would
--   override the inherited method and the parent's conditionals would stop being checked.
emitJavaConditionalConstraint :: Name -> (Int, ConditionalConstraint) -> String
emitJavaConditionalConstraint cName (idx, ax) =
    "    @AssertTrue(message = \"Constraint failed: " ++ escapeJava (condDescription ax) ++ "\")\n" ++
    "    public boolean isValidConstraint_" ++ sanitizeIdent cName ++ "_" ++ show idx ++ "() {\n" ++
    (case condPremise ax of
        Top -> "        return " ++ emitJavaExpr (condConclusion ax) ++ ";\n"
        pre -> "        if (" ++ emitJavaExpr pre ++ ") {\n" ++
               "            return " ++ emitJavaExpr (condConclusion ax) ++ ";\n" ++
               "        }\n" ++
               "        return true;\n") ++
    "    }\n\n"

-- | Total on what 'IR.normalizeCondition' produces; anything else was kept out upstream and
--   fails loudly here instead of becoming a check that cannot fail. Fields are read through
--   their getters: a property declared on an ancestor is private to the ancestor.
emitJavaExpr :: FOL -> String
emitJavaExpr (Predicate op [Var prop, Constant val]) | op `elem` comparisonOps = emitJavaBinary op prop val
emitJavaExpr (Predicate flag []) =
    let fld = javaGetter flag
    in "(\"True\".equalsIgnoreCase(String.valueOf(" ++ fld ++ ")) || Boolean.TRUE.equals(" ++ fld ++ "))"
emitJavaExpr (And p1 p2) = "(" ++ emitJavaExpr p1 ++ " && " ++ emitJavaExpr p2 ++ ")"
emitJavaExpr (Or p1 p2)  = "(" ++ emitJavaExpr p1 ++ " || " ++ emitJavaExpr p2 ++ ")"
emitJavaExpr (Not p)     = "!(" ++ emitJavaExpr p ++ ")"
emitJavaExpr Top         = "true"
emitJavaExpr Bottom      = "false"
emitJavaExpr other       = error ("Java emitter: untranslatable conditional " ++ formatFOL other)

javaGetter :: Name -> String
javaGetter prop = "this.get" ++ capitalize (sanitizeIdent prop) ++ "()"

emitJavaBinary :: String -> Name -> String -> String
emitJavaBinary op prop val =
    let fld = javaGetter prop
    in case op of
        "eq" | val `elem` ["True", "true"]   -> "(\"True\".equalsIgnoreCase(String.valueOf(" ++ fld ++ ")) || Boolean.TRUE.equals(" ++ fld ++ "))"
             | val `elem` ["False", "false"] -> "(\"False\".equalsIgnoreCase(String.valueOf(" ++ fld ++ ")) || Boolean.FALSE.equals(" ++ fld ++ "))"
             | isNumber val                  -> "(" ++ fld ++ " != null && " ++ fld ++ " == " ++ val ++ ")"
             | otherwise                     -> "Objects.equals(" ++ fld ++ ", \"" ++ escapeJava val ++ "\")"
        "ne" | val `elem` ["True", "true"]   -> "(!\"True\".equalsIgnoreCase(String.valueOf(" ++ fld ++ ")) && !Boolean.TRUE.equals(" ++ fld ++ "))"
             | val `elem` ["False", "false"] -> "(!\"False\".equalsIgnoreCase(String.valueOf(" ++ fld ++ ")) && !Boolean.FALSE.equals(" ++ fld ++ "))"
             | isNumber val                  -> "(" ++ fld ++ " == null || " ++ fld ++ " != " ++ val ++ ")"
             | otherwise                     -> "!Objects.equals(" ++ fld ++ ", \"" ++ escapeJava val ++ "\")"
        "gt"  -> "(" ++ fld ++ " != null && " ++ fld ++ " > " ++ val ++ ")"
        "gte" -> "(" ++ fld ++ " != null && " ++ fld ++ " >= " ++ val ++ ")"
        "lt"  -> "(" ++ fld ++ " != null && " ++ fld ++ " < " ++ val ++ ")"
        "lte" -> "(" ++ fld ++ " != null && " ++ fld ++ " <= " ++ val ++ ")"
        _     -> error ("Java emitter: unknown comparison " ++ op)

escapeJava :: String -> String
escapeJava = escapeTargetString

isNumber :: String -> Bool
isNumber s = case (readMaybe s :: Maybe Double) of
    Just _  -> True
    Nothing -> False

capitalize :: String -> String
capitalize [] = []
capitalize (x:xs) = toUpper x : xs

emitFieldOrGetter :: Name -> CompiledProperty -> String
emitFieldOrGetter _ p =
    let annotations = if compPropType p `elem` [PTInteger, PTFloat, PTDouble]
                      then concatMap (mapConstraintToAnnotation (compPropType p)) (compConstraints p)
                      else ""
        pName = sanitizeIdent (compPropName p)
        rawType = mapJavaType (compPropType p)
        (pType, notNullAnn) = case compCardinality p of
            CardZeroOrOne  -> (rawType, "")
            CardZeroOrMore -> ("java.util.List<" ++ rawType ++ ">", "")
            CardOneOrMore  -> ("java.util.List<" ++ rawType ++ ">", "    @jakarta.validation.constraints.NotEmpty\n")
            _              -> (rawType, "    @NotNull\n")
    in if not (compIsInherited p)
       then "    private " ++ pType ++ " " ++ pName ++ ";\n\n" ++
            notNullAnn ++ annotations ++ "    public " ++ pType ++ " get" ++ capitalize pName ++ "() {\n" ++
            "        return this." ++ pName ++ ";\n" ++
            "    }\n\n" ++
            "    public void set" ++ capitalize pName ++ "(" ++ pType ++ " val) {\n" ++
            "        this." ++ pName ++ " = val;\n" ++
            "    }\n\n"
       else "    // Overridden inherited property with subclass constraints\n" ++
            "    @Override\n" ++
            notNullAnn ++ annotations ++ "    public " ++ pType ++ " get" ++ capitalize pName ++ "() {\n" ++
            "        return super.get" ++ capitalize pName ++ "();\n" ++
            "    }\n\n"

mapConstraintToAnnotation :: PropertyType -> BoundConstraint -> String
mapConstraintToAnnotation PTInteger (BoundConstraint OpGt (VInt n)) =
    "    @Min(" ++ show (n + 1) ++ ")\n"
mapConstraintToAnnotation PTInteger (BoundConstraint OpGte (VInt n)) =
    "    @Min(" ++ show n ++ ")\n"
mapConstraintToAnnotation PTInteger (BoundConstraint OpLt (VInt n)) =
    "    @Max(" ++ show (n - 1) ++ ")\n"
mapConstraintToAnnotation PTInteger (BoundConstraint OpLte (VInt n)) =
    "    @Max(" ++ show n ++ ")\n"
mapConstraintToAnnotation pType (BoundConstraint OpGt val) | pType `elem` [PTFloat, PTDouble] =
    "    @DecimalMin(value = \"" ++ valueToString val ++ "\", inclusive = false)\n"
mapConstraintToAnnotation pType (BoundConstraint OpGte val) | pType `elem` [PTFloat, PTDouble] =
    "    @DecimalMin(\"" ++ valueToString val ++ "\")\n"
mapConstraintToAnnotation pType (BoundConstraint OpLt val) | pType `elem` [PTFloat, PTDouble] =
    "    @DecimalMax(value = \"" ++ valueToString val ++ "\", inclusive = false)\n"
mapConstraintToAnnotation pType (BoundConstraint OpLte val) | pType `elem` [PTFloat, PTDouble] =
    "    @DecimalMax(\"" ++ valueToString val ++ "\")\n"
mapConstraintToAnnotation _ _ = ""

mapJavaType :: PropertyType -> String
mapJavaType PTInteger = "Integer"
mapJavaType PTFloat   = "Float"
mapJavaType PTDouble  = "Double"
mapJavaType PTBoolean = "boolean"
mapJavaType PTString  = "String"
mapJavaType (PTCustom n) = sanitizeIdent n
