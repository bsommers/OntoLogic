module Emitters.Mermaid where

import OntoLogic

emitMermaid :: Registry -> String
emitMermaid reg =
    "classDiagram\n" ++
       concatMap emitClass (concepts reg) ++
       concatMap emitRelation (concepts reg) ++
       concatMap emitProperty (properties reg) ++
       concatMap emitAssociation (relations reg)

-- A ':' in a class id is a mermaid syntax error, so the id is sanitized and the
-- original name moves into the display label.
emitClass :: (Name, Maybe Name) -> String
emitClass (name, _) = "    class " ++ sanitizeIdent name ++ "[\"" ++ name ++ "\"]\n"

-- Emit inheritance: Parent <|-- Child
emitRelation :: (Name, Maybe Name) -> String
emitRelation (name, Just parent) = "    " ++ sanitizeIdent parent ++ " <|-- " ++ sanitizeIdent name ++ "\n"
emitRelation _ = ""

-- Emit attributes: Class : +Type name
-- The attribute name is sanitized too: mermaid has no quoting for it, and a raw ':'
-- makes the parser stop with "Expecting 'NEWLINE', 'EOF', got 'LABEL'".
emitProperty :: Property -> String
emitProperty p = "    " ++ sanitizeIdent (domain p) ++ " : +" ++ propertyTypeToString (rangeType p) ++ " " ++ sanitizeIdent (propName p) ++ "\n"

-- Emit association: Domain --> Range : relation_name
-- The edge label is sanitized for the same reason as the attribute name above.
emitAssociation :: Relation -> String
emitAssociation r = "    " ++ sanitizeIdent (relDomain r) ++ " --> " ++ sanitizeIdent (relRange r) ++ " : " ++ sanitizeIdent (relName r) ++ "\n"
