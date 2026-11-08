module Neo4jSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.Neo4j (emitCypher, emitConstraintsCypher, emitConstraintsCypherWithEdition, Neo4jEdition(..), cypherLabel, escapeCypherString)
import Data.Text (pack)
import Text.Megaparsec (parse, errorBundlePretty)
import Parser (parseRegistry)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

-- The expectations below changed with #26: every statement is now terminated with a
-- semicolon (without it the server reads the next MERGE as a continuation and rejects
-- the re-bound `n`), and labels and property keys are backticked so a namespaced name
-- stays a single token.
spec :: Spec
spec = do
  describe "Neo4j Emitter" $ do
    it "generates basic Cypher nodes and subclasses" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = []
                  , properties = 
                      [ Property "serial_number" "Asset" PTString
                      , Property "firmware_ver" "Device" PTString
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitCypher reg
          constraints = emitConstraintsCypher reg
      content `shouldBe` 
        "// Nodes and Hierarchy\n\
        \MERGE (n:OntologyClass {name: 'Asset'});\n\
        \MERGE (n:OntologyClass {name: 'Device'})\n\
        \MERGE (p:OntologyClass {name: 'Asset'})\n\
        \MERGE (n)-[:SUBCLASS_OF]->(p);\n"
      constraints `shouldBe`
        "// Property Existence Constraints (requires Neo4j Enterprise Edition)\n\
        \CREATE CONSTRAINT IF NOT EXISTS FOR (n:`Asset`) REQUIRE n.`serial_number` IS NOT NULL;\n\
        \CREATE CONSTRAINT IF NOT EXISTS FOR (n:`Device`) REQUIRE n.`firmware_ver` IS NOT NULL;\n"

    it "generates Cypher audit checks based on axioms" $ do
      let reg = emptyRegistry
                  { concepts = [("Refrigerator", Nothing), ("Controller", Nothing)]
                  , axioms = 
                      [ ForAll "r" (Implies (Predicate "Refrigerator" [Var "r"]) (Predicate "lt" [Var "temperature", Constant "5"]))
                      , ForAll "c" (Implies (And (Predicate "Controller" [Var "c"]) (Predicate "is_active" [])) (Predicate "eq" [Var "safety_status", Constant "False"]))
                      ]
                  , properties = 
                      [ Property "temperature" "Refrigerator" PTInteger
                      , Property "safety_status" "Controller" PTBoolean
                      ]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitCypher reg
          constraints = emitConstraintsCypher reg
      content `shouldBe` 
        "// Nodes and Hierarchy\n\
        \MERGE (n:OntologyClass {name: 'Refrigerator'});\n\
        \MERGE (n:OntologyClass {name: 'Controller'});\n\
        \// Axiom Validations\n\
        \// Axiom validation: Refrigerator temperature lt 5\n\
        \MATCH (n:`Refrigerator`) WHERE NOT (n.`temperature` < 5) RETURN elementId(n) AS invalid_node_id;\n"
      constraints `shouldBe`
        "// Property Existence Constraints (requires Neo4j Enterprise Edition)\n\
        \CREATE CONSTRAINT IF NOT EXISTS FOR (n:`Refrigerator`) REQUIRE n.`temperature` IS NOT NULL;\n\
        \CREATE CONSTRAINT IF NOT EXISTS FOR (n:`Controller`) REQUIRE n.`safety_status` IS NOT NULL;\n"
      -- The Controller axiom has a conjunctive antecedent, (and (Controller c) (is_active)),
      -- so it constrains only *active* controllers. Emitting an audit over all :Controller
      -- nodes would flag every inactive one as invalid, so it is reported unmapped instead (#19).

    it "generates OntologyClass taxonomy nodes and modern elementId audits" $ do
      let reg = emptyRegistry
                  { concepts = [("Asset", Nothing), ("Device", Just "Asset")]
                  , axioms = [ForAll "d" (Implies (Predicate "Device" [Var "d"]) (Predicate "gt" [Var "connections", Constant "0"]))]
                  , properties = [Property "connections" "Device" PTInteger]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitCypher reg
          constraints = emitConstraintsCypher reg
      content `shouldContain` "MERGE (n:OntologyClass {name: 'Asset'})"
      content `shouldContain` "MERGE (n:OntologyClass {name: 'Device'})"
      content `shouldContain` "MERGE (p:OntologyClass {name: 'Asset'})"
      content `shouldContain` "MERGE (n)-[:SUBCLASS_OF]->(p)"
      content `shouldContain` "RETURN elementId(n) AS invalid_node_id;"
      content `shouldNotContain` "CREATE CONSTRAINT"
      constraints `shouldContain` "CREATE CONSTRAINT IF NOT EXISTS FOR (n:`Device`) REQUIRE n.`connections` IS NOT NULL;"

    it "escapes single quotes and backslashes in node names and string property values" $ do
      let reg = emptyRegistry
                  { concepts = [("User's Device", Nothing)]
                  , axioms = [ForAll "u" (Implies (Predicate "User's Device" [Var "u"]) (Predicate "eq" [Var "mode", Constant "it's fast"]))]
                  , properties = [Property "mode" "User's Device" PTString]
                  , relations = []
                  , imports = []
                  , namespaces = []
                  }
          content = emitCypher reg
      content `shouldContain` "MERGE (n:OntologyClass {name: 'User\\'s Device'})"
      content `shouldContain` "n.`mode` = 'it\\'s fast'"

  describe "loadable Cypher (#26, #48)" $ do
    let reg = load "(def-concept bfo:Entity) (def-concept bfo:Process bfo:Entity) (def-property dur bfo:Process Integer)"
        cypher = emitCypher reg
        constraints = emitConstraintsCypher reg
    -- An unterminated MERGE makes neo4j read the following MERGE as a continuation
    -- of the same statement, which then re-binds `n` and is rejected.
    it "terminates a node statement before the next one begins" $
      cypher `shouldNotContain` "'})\nMERGE (n:OntologyClass"
    it "terminates the subclass statement" $
      cypher `shouldContain` "MERGE (n)-[:SUBCLASS_OF]->(p);\n"
    it "moves existence constraints out of graph.cypher into constraints.cypher (#48)" $ do
      cypher `shouldNotContain` "CREATE CONSTRAINT"
      constraints `shouldContain` "FOR (n:`bfo:Process`) REQUIRE n.`dur` IS NOT NULL;"
    it "backticks namespaced labels in audit queries" $ do
      let bounded = load "(def-concept bfo:Process) (def-property dur bfo:Process Integer) (forall (x) (implies (bfo:Process x) (gt dur 5)))"
      emitCypher bounded `shouldContain` "MATCH (n:`bfo:Process`) WHERE NOT (n.`dur` > 5)"

    it "omits existence constraints for optional and collection properties" $ do
      let optReg = load "(def-concept Device) (def-property req Device String :cardinality 1..1) (def-property opt Device String :optional True) (def-property tags Device String :cardinality 0..*)"
          cs = emitConstraintsCypher optReg
      cs `shouldContain` "REQUIRE n.`req` IS NOT NULL;"
      cs `shouldNotContain` "REQUIRE n.`opt` IS NOT NULL;"
      cs `shouldNotContain` "REQUIRE n.`tags` IS NOT NULL;"

    it "comments out IS NOT NULL constraints in Community edition" $ do
      let devReg = load "(def-concept Device) (def-property req Device String)"
          csComm = emitConstraintsCypherWithEdition Neo4jCommunity devReg
          csEnt = emitConstraintsCypherWithEdition Neo4jEnterprise devReg
      csComm `shouldContain` "// Property Existence Constraints (commented out for Neo4j Community Edition"
      csComm `shouldContain` "// CREATE CONSTRAINT IF NOT EXISTS FOR (n:`Device`) REQUIRE n.`req` IS NOT NULL;"
      csEnt `shouldContain` "CREATE CONSTRAINT IF NOT EXISTS FOR (n:`Device`) REQUIRE n.`req` IS NOT NULL;"

  describe "Identifier and String Sanitization" $ do
    it "doubles backticks in Cypher labels and property names" $ do
      cypherLabel "simple" `shouldBe` "`simple`"
      cypherLabel "bfo:Process" `shouldBe` "`bfo:Process`"
      cypherLabel "weird`label" `shouldBe` "`weird``label`"
      cypherLabel "a`b`c" `shouldBe` "`a``b``c`"

    it "escapes single quotes and backslashes in Cypher string literals" $ do
      escapeCypherString "plain text" `shouldBe` "plain text"
      escapeCypherString "it's working" `shouldBe` "it\\'s working"
      escapeCypherString "path\\to\\file" `shouldBe` "path\\\\to\\\\file"
      escapeCypherString "escaped\\'and\\'slashed" `shouldBe` "escaped\\\\\\'and\\\\\\'slashed"
