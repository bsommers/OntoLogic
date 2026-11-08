module Emitters.D2 where

import OntoLogic
import Data.List (intercalate)

emitD2 :: Registry -> String
emitD2 reg =
    intercalate "\n" (
        map emitClass (concepts reg) ++
        map emitRelation (concepts reg) ++
        map emitPropertyReference (properties reg) ++
        map emitAssociation (relations reg)
       )

-- | A D2 key, quoted so ':' is not read as a key/value separator.
d2Key :: String -> String
d2Key s = "\"" ++ concatMap (\c -> if c == '"' then "\\\"" else [c]) s ++ "\""

-- Emit class definition: "Name": { shape: class }
emitClass :: (Name, Maybe Name) -> String
emitClass (name, _) = d2Key name ++ ": { shape: class }"

-- Emit inheritance: Child -> Parent
emitRelation :: (Name, Maybe Name) -> String
emitRelation (name, Just parent) = d2Key name ++ " -> " ++ d2Key parent
emitRelation _ = ""

-- Emit attributes: "Concept"."propName": Type
emitPropertyReference :: Property -> String
emitPropertyReference p = d2Key (domain p) ++ "." ++ d2Key (propName p) ++ ": " ++ propertyTypeToString (rangeType p)

-- Emit relationship: "Domain" -> "Range": relation_name
emitAssociation :: Relation -> String
emitAssociation r = d2Key (relDomain r) ++ " -> " ++ d2Key (relRange r) ++ ": " ++ relName r
