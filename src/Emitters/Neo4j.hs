module Emitters.Neo4j
    ( emitCypher
    , emitConstraintsCypher
    , emitConstraintsCypherWithEdition
    , Neo4jEdition(..)
    , parseNeo4jEdition
    , emitConstraint
    , emitNode
    , emitRelation
    , cypherLabel
    , escapeCypherString
    ) where

import OntoLogic
import Data.Char (toLower)

data Neo4jEdition
    = Neo4jCommunity
    | Neo4jEnterprise
    deriving (Show, Eq, Read)

parseNeo4jEdition :: String -> Maybe Neo4jEdition
parseNeo4jEdition s = case map toLower s of
    "community"  -> Just Neo4jCommunity
    "enterprise" -> Just Neo4jEnterprise
    _            -> Nothing

emitCypher :: Registry -> String
emitCypher reg = 
    "// Nodes and Hierarchy\n" ++
       concatMap emitNode (concepts reg) ++
       (if null (relations reg) then "" else "// Relationships\n" ++ concatMap emitRelation (relations reg)) ++
       (if null auditQueries then "" else "// Axiom Validations\n" ++ auditQueries)
  where
    auditQueries = concatMap (emitAuditQueries reg) (concepts reg)

-- | Emit property existence constraints.
-- These require Neo4j Enterprise Edition; Community Edition rejects them (#48).
-- Emitted to a separate constraints.cypher file so graph.cypher loads cleanly on Community.
emitConstraintsCypher :: Registry -> String
emitConstraintsCypher = emitConstraintsCypherWithEdition Neo4jEnterprise

-- | Emit property existence constraints with specified Neo4j edition support.
-- In Community mode, constraints are commented out to allow clean import.
emitConstraintsCypherWithEdition :: Neo4jEdition -> Registry -> String
emitConstraintsCypherWithEdition Neo4jEnterprise reg =
    "// Property Existence Constraints (requires Neo4j Enterprise Edition)\n" ++
    concatMap emitConstraint (filter isRequiredProp (properties reg))
  where
    isRequiredProp p = propCardinality p `notElem` [CardZeroOrOne, CardZeroOrMore]
emitConstraintsCypherWithEdition Neo4jCommunity reg =
    let required = filter isRequiredProp (properties reg)
    in "// Property Existence Constraints (commented out for Neo4j Community Edition; use --neo4j-edition enterprise to enable)\n" ++
       concatMap (\p -> "// " ++ emitConstraint p) required
  where
    isRequiredProp p = propCardinality p `notElem` [CardZeroOrOne, CardZeroOrMore]

-- | A Cypher label or property key, backticked so a namespaced name stays one token.
cypherLabel :: String -> String
cypherLabel s = "`" ++ concatMap (\c -> if c == '`' then "``" else [c]) s ++ "`"

-- Each statement is terminated: without the semicolon the next MERGE reads as a
-- continuation of this one and re-binds `n`, which the server rejects.
emitNode :: (Name, Maybe Name) -> String
emitNode (name, parent) =
    case parent of
        Nothing ->
            "MERGE (n:OntologyClass {name: '" ++ escapeCypherString name ++ "'});\n"
        Just p ->
            "MERGE (n:OntologyClass {name: '" ++ escapeCypherString name ++ "'})\n" ++
            "MERGE (p:OntologyClass {name: '" ++ escapeCypherString p ++ "'})\n" ++
            "MERGE (n)-[:SUBCLASS_OF]->(p);\n"

emitRelation :: Relation -> String
emitRelation rel =
    "MERGE (s:OntologyClass {name: '" ++ escapeCypherString (relDomain rel) ++ "'})\n" ++
    "MERGE (t:OntologyClass {name: '" ++ escapeCypherString (relRange rel) ++ "'})\n" ++
    "MERGE (s)-[:RELATION {name: '" ++ escapeCypherString (relName rel) ++ "'}]->(t);\n"

escapeCypherString :: String -> String
escapeCypherString [] = []
escapeCypherString ('\'':cs) = "\\'" ++ escapeCypherString cs
escapeCypherString ('\\':cs) = "\\\\" ++ escapeCypherString cs
escapeCypherString (c:cs) = c : escapeCypherString cs

emitConstraint :: Property -> String
emitConstraint p = 
    "CREATE CONSTRAINT IF NOT EXISTS FOR (n:" ++ cypherLabel (domain p) ++ ") REQUIRE n." ++ cypherLabel (propName p) ++ " IS NOT NULL;\n"

emitAuditQueries :: Registry -> (Name, Maybe Name) -> String
emitAuditQueries reg (conceptName, _) =
    let consts = getLocalConstraints conceptName (axioms reg)
    in concatMap (emitAuditQuery reg conceptName) consts

emitAuditQuery :: Registry -> Name -> (String, String, String) -> String
emitAuditQuery reg conceptName (prop, op, val) =
    let cypherOp = mapCypherOp op
        cypherVal = formatCypherValue reg prop val
    in "// Axiom validation: " ++ conceptName ++ " " ++ prop ++ " " ++ op ++ " " ++ val ++ "\n" ++
       "MATCH (n:" ++ cypherLabel conceptName ++ ") WHERE NOT (n." ++ cypherLabel prop ++ " " ++ cypherOp ++ " " ++ cypherVal ++ ") RETURN elementId(n) AS invalid_node_id;\n"

mapCypherOp :: String -> String
mapCypherOp "gt"  = ">"
mapCypherOp "gte" = ">="
mapCypherOp "lt"  = "<"
mapCypherOp "lte" = "<="
mapCypherOp "eq"  = "="
mapCypherOp op    = op

formatCypherValue :: Registry -> String -> String -> String
formatCypherValue reg prop val =
    case findProperty prop (properties reg) of
        Just p ->
            case rangeType p of
                PTBoolean -> if val == "True" then "true" else if val == "False" then "false" else val
                PTString  -> "'" ++ escapeCypherString val ++ "'"
                _         -> val
        Nothing -> val

findProperty :: String -> [Property] -> Maybe Property
findProperty name props =
    case filter (\p -> propName p == name) props of
        (p:_) -> Just p
        []    -> Nothing
