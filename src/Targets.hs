module Targets
    ( Target(..)
    , EmitOptions(..)
    , defaultEmitOptions
    , targets
    , lookupTarget
    , targetHelp
    , Neo4jEdition(..)
    , parseNeo4jEdition
    ) where

import Data.List (intercalate)
import OntoLogic
import IR (CommentStyle(..), compileRegistry, formatUnmappedWarning)
import Emitters.Java (emitJavaWithPackage)
import Emitters.Python (emitPython)
import Emitters.Rust (emitRust)
import Emitters.Go (emitGo)
import Emitters.TypeScript (emitTypeScript)
import Emitters.OpenApi (emitOpenApi)
import Emitters.GraphQL (emitGraphQL)
import Emitters.SMT (emitSMT)
import Emitters.Neo4j (emitCypher, emitConstraintsCypherWithEdition, Neo4jEdition(..), parseNeo4jEdition)
import Emitters.Owl (emitOwlWithBase)
import Emitters.JsonSchema (emitJsonSchema)
import Emitters.Shacl (emitShaclWithBase)
import Emitters.Mermaid (emitMermaid)
import Emitters.D2 (emitD2)
import Emitters.Protobuf (emitProtobuf)
import Emitters.Cpp (emitCpp)
import Emitters.Sql (emitSql)
import Emitters.TPTP (emitTPTP)

-- | Options that emitters may consult.
data EmitOptions = EmitOptions
    { optJavaPackage  :: String
    , optBaseIri      :: Maybe String   -- ^ Nothing: derive from the ontology's namespaces
    , optNeo4jEdition :: Neo4jEdition   -- ^ Target Neo4j edition for constraints
    } deriving (Show, Eq)

defaultEmitOptions :: EmitOptions
defaultEmitOptions = EmitOptions
    { optJavaPackage  = "ontologic.generated"
    , optBaseIri      = Nothing
    , optNeo4jEdition = Neo4jEnterprise
    }

-- | One code-generation target, shared by the CLI and the REPL.
data Target = Target
    { targetName    :: String
    , targetAliases :: [String]
    , targetLabel   :: String         -- ^ "Generated <label> in <dir>"
    , targetWarnAs  :: Maybe String   -- ^ report unmapped axioms under this name
    , targetEmit    :: EmitOptions -> Registry -> [(FilePath, String)]  -- ^ (file name, contents)
    }

single :: FilePath -> (Registry -> String) -> EmitOptions -> Registry -> [(FilePath, String)]
single file f _ reg = [(file, f reg)]

-- | Append the unmapped-axiom warning, once, to the target's first file.
withWarning :: CommentStyle -> (EmitOptions -> Registry -> [(FilePath, String)]) -> EmitOptions -> Registry -> [(FilePath, String)]
withWarning style emit o reg = case emit o reg of
    (file, contents) : rest -> (file, contents ++ formatUnmappedWarning style (compileRegistry reg)) : rest
    []                      -> []

-- | Java has one file per class, so the warning goes in package-info.java rather
--   than being repeated in every class.
emitJavaTarget :: EmitOptions -> Registry -> [(FilePath, String)]
emitJavaTarget o reg =
    [ (n ++ ".java", c) | (n, c) <- emitJavaWithPackage (optJavaPackage o) reg ] ++
    case formatUnmappedWarning (LineComment "//") (compileRegistry reg) of
        ""      -> []
        warning -> [("package-info.java", "package " ++ optJavaPackage o ++ ";\n" ++ warning)]

targets :: [Target]
targets =
    [ Target "java" [] "Java models" (Just "Java") emitJavaTarget
    , Target "python" [] "Python models" (Just "Python") (withWarning hash (single "models.py" emitPython))
    , Target "rust" [] "Rust models" (Just "Rust") (withWarning slashes (single "models.rs" emitRust))
    , Target "go" ["golang"] "Go models" (Just "Go") (withWarning slashes (single "models.go" emitGo))
    , Target "ts" ["typescript", "zod"] "TypeScript/Zod models" (Just "TypeScript") (withWarning slashes (single "models.ts" emitTypeScript))
    , Target "openapi" [] "OpenAPI 3.1 schema" (Just "OpenAPI") (withWarning hash (single "openapi.yaml" emitOpenApi))
    , Target "graphql" ["gql"] "GraphQL schema" (Just "GraphQL") (withWarning hash (single "schema.graphql" emitGraphQL))
    , Target "smt" ["smtlib"] "SMT-LIB2 specification" Nothing (withWarning (LineComment ";") (single "spec.smt2" emitSMT))
    , Target "neo4j" [] "Neo4j Cypher" Nothing $ withWarning slashes
        (\o reg ->
            [ ("graph.cypher", emitCypher reg)
            , ("constraints.cypher", emitConstraintsCypherWithEdition (optNeo4jEdition o) reg)
            ])
    , Target "owl" [] "OWL ontology" Nothing $ withWarning XmlComment
        (\o reg -> [("ontology.owl", emitOwlWithBase (resolveBaseIri (optBaseIri o) reg) reg)])
    -- JSON has no comment syntax; unmapped axioms are reported on the CLI only.
    , Target "jsonschema" ["json"] "JSON Schema" (Just "JSON Schema") (single "schema.json" emitJsonSchema)
    , Target "shacl" [] "SHACL shapes" Nothing $ withWarning hash
        (\o reg -> [("shapes.ttl", emitShaclWithBase (resolveBaseIri (optBaseIri o) reg) reg)])
    , Target "mermaid" [] "Mermaid diagram" Nothing (withWarning (LineComment "%%") (single "class_diagram.mmd" emitMermaid))
    , Target "d2" [] "D2 diagram" Nothing (withWarning hash (single "diagram.d2" emitD2))
    , Target "protobuf" ["proto", "proto3"] "Protocol Buffers schema" Nothing (withWarning slashes (single "schema.proto" emitProtobuf))
    , Target "cpp" ["c++"] "C++20 models" (Just "C++") (withWarning slashes (single "models.hpp" emitCpp))
    , Target "sql" ["postgres", "postgresql", "ddl"] "PostgreSQL DDL schema" (Just "SQL") (withWarning dashes (single "schema.sql" emitSql))
    , Target "tptp" ["p", "fof"] "TPTP First-Order Form" (Just "TPTP") (withWarning percent (single "theory.p" emitTPTP))
    ]
  where
    hash = LineComment "#"
    slashes = LineComment "//"
    dashes = LineComment "--"
    percent = LineComment "%"

lookupTarget :: String -> Maybe Target
lookupTarget t =
    case filter (\x -> t == targetName x || t `elem` targetAliases x) targets of
        (x:_) -> Just x
        []    -> Nothing

targetHelp :: String
targetHelp = "Target: " ++ intercalate ", " (map targetName targets ++ ["lint", "solve", "repl", "lsp"])
