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
    (if null (compConditionalAxioms cls) then "" else "import java.util.Objects;\n") ++
    "\n" ++
    "public class " ++ sanitizeIdent (compClassName cls) ++ maybe "" (\p -> " extends " ++ sanitizeIdent p) (compParentClass cls) ++ " {\n" ++
    concatMap (emitFieldOrGetter (compClassName cls)) (compProperties cls) ++
    concatMap emitJavaConditionalConstraint (zip [1..] (compConditionalAxioms cls)) ++
    "}\n"

emitJavaConditionalConstraint :: (Int, ConditionalConstraint) -> String
emitJavaConditionalConstraint (idx, ax) =
    "    @AssertTrue(message = \"Constraint failed: " ++ escapeJava (condDescription ax) ++ "\")\n" ++
    "    public boolean isValidConstraint" ++ show idx ++ "() {\n" ++
    "        if (" ++ emitJavaExpr (condPremise ax) ++ ") {\n" ++
    "            return " ++ emitJavaExpr (condConclusion ax) ++ ";\n" ++
    "        }\n" ++
    "        return true;\n" ++
    "    }\n\n"

emitJavaExpr :: FOL -> String
emitJavaExpr (Predicate op args)
    | op `elem` ["eq", "ne", "gt", "gte", "lt", "lte"] =
        case args of
            [Var prop, Constant val] -> emitJavaBinary op prop val
            [Constant val, Var prop] -> emitJavaBinary (invertCompOp op) prop val
            _ -> "true"
    | otherwise =
        case args of
            (Var prop:_) -> "(\"True\".equalsIgnoreCase(String.valueOf(this." ++ sanitizeIdent prop ++ ")) || Boolean.TRUE.equals(this." ++ sanitizeIdent prop ++ "))"
            []           -> "(\"True\".equalsIgnoreCase(String.valueOf(this." ++ sanitizeIdent op ++ ")) || Boolean.TRUE.equals(this." ++ sanitizeIdent op ++ "))"
            _            -> "true"
emitJavaExpr (And p1 p2) = "(" ++ emitJavaExpr p1 ++ " && " ++ emitJavaExpr p2 ++ ")"
emitJavaExpr (Or p1 p2)  = "(" ++ emitJavaExpr p1 ++ " || " ++ emitJavaExpr p2 ++ ")"
emitJavaExpr (Not p)     = "!(" ++ emitJavaExpr p ++ ")"
emitJavaExpr _           = "true"

emitJavaBinary :: String -> Name -> String -> String
emitJavaBinary op prop val =
    let fld = "this." ++ sanitizeIdent prop
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
        _     -> "true"

invertCompOp :: String -> String
invertCompOp "gt"  = "lt"
invertCompOp "gte" = "lte"
invertCompOp "lt"  = "gt"
invertCompOp "lte" = "gte"
invertCompOp op    = op

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
