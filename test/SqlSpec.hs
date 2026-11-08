{-# LANGUAGE OverloadedStrings #-}
module SqlSpec (spec) where

import Test.Hspec
import Parser (parseRegistry)
import Text.Megaparsec (parse, errorBundlePretty)
import qualified Data.Text as T
import System.Directory (findExecutable)
import System.Process (readProcessWithExitCode)
import System.Exit (ExitCode(..))
import OntoLogic
import Emitters.Sql (emitSql, sqlIdent, escapeSqlString)
import Targets (lookupTarget, targetEmit, defaultEmitOptions)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (T.pack src))

spec :: Spec
spec = describe "PostgreSQL / ANSI SQL DDL Emitter" $ do
    let ontologySrc = unlines
          [ "(def-concept Device)"
          , "(def-property serial_number Device String :cardinality 1..1)"
          , "(def-property firmware_version Device String :default \"1.0.0\")"
          , "(def-concept Robot Device)"
          , "(def-property is_active Robot Boolean :default True)"
          , "(def-property battery_level Robot Integer :cardinality 1..1)"
          , "(def-property temp_opt Robot Float :optional True)"
          , "(def-property sensor_readings Robot Double :cardinality 0..*)"
          , "(def-property tags Robot String :cardinality 1..*)"
          , "(def-relation manages Robot Device)"
          , "(forall (r) (implies (Robot r) (and (gte battery_level 0) (lte battery_level 100))))"
          , "(forall (r) (implies (Robot r) (implies (eq is_active True) (gt battery_level 10))))"
          ]
        reg = load ontologySrc

    it "emits table creation with primary key and foreign key inheritance" $ do
        let sql = emitSql reg
        sql `shouldContain` "CREATE TABLE IF NOT EXISTS \"Device\" ("
        sql `shouldContain` "\"id\" TEXT PRIMARY KEY"
        sql `shouldContain` "CREATE TABLE IF NOT EXISTS \"Robot\" ("
        sql `shouldContain` "\"id\" TEXT PRIMARY KEY REFERENCES \"Device\"(\"id\") ON DELETE CASCADE"

    it "emits columns with accurate SQL types, nullability, and defaults" $ do
        let sql = emitSql reg
        sql `shouldContain` "\"serial_number\" TEXT NOT NULL"
        sql `shouldContain` "\"firmware_version\" TEXT DEFAULT '1.0.0' NOT NULL"
        sql `shouldContain` "\"is_active\" BOOLEAN DEFAULT TRUE NOT NULL"
        sql `shouldContain` "\"battery_level\" INTEGER NOT NULL"
        sql `shouldContain` "\"temp_opt\" DOUBLE PRECISION"
        sql `shouldNotContain` "\"temp_opt\" DOUBLE PRECISION NOT NULL"
        sql `shouldContain` "\"sensor_readings\" DOUBLE PRECISION[]"
        sql `shouldContain` "\"tags\" TEXT[] NOT NULL"

    it "emits property bound check constraints" $ do
        let sql = emitSql reg
        sql `shouldContain` "CONSTRAINT \"chk_Robot_battery_level\" CHECK (\"battery_level\" >= 0 AND \"battery_level\" <= 100)"

    it "emits conditional axiom check constraints" $ do
        let sql = emitSql reg
        sql `shouldContain` "CONSTRAINT \"chk_Robot_cond1\" CHECK (NOT (\"is_active\" = TRUE) OR (\"battery_level\" > 10))"

    it "emits junction tables for relations with foreign keys and compound primary keys" $ do
        let sql = emitSql reg
        sql `shouldContain` "CREATE TABLE IF NOT EXISTS \"rel_manages\" ("
        sql `shouldContain` "\"source_id\" TEXT NOT NULL REFERENCES \"Robot\"(\"id\") ON DELETE CASCADE"
        sql `shouldContain` "\"target_id\" TEXT NOT NULL REFERENCES \"Device\"(\"id\") ON DELETE CASCADE"
        sql `shouldContain` "PRIMARY KEY (\"source_id\", \"target_id\")"

    it "executes cleanly in sqlite3 without syntax errors" $ do
        mSqlite <- findExecutable "sqlite3"
        case mSqlite of
            Nothing -> pendingWith "sqlite3 not installed"
            Just sqlite -> do
                let sql = emitSql reg
                (code, out, err) <- readProcessWithExitCode sqlite [":memory:"] sql
                (code, err ++ out) `shouldBe` (ExitSuccess, "")

    it "includes unmapped axiom warnings formatted with SQL comments (--)" $ do
        let unmappedSrc = unlines
              [ "(def-concept A)"
              , "(def-concept B)"
              , "(forall (x y) (or (A x) (B y)))"
              ]
            unmappedReg = load unmappedSrc
            target = maybe (error "sql target not found") id (lookupTarget "sql")
            files = targetEmit target defaultEmitOptions unmappedReg
            sql = concatMap snd files
        sql `shouldContain` "-- WARNING: The following axioms could not be mapped to field constraints:"
        sql `shouldContain` "--   forall x (forall y (A(x) or B(y)))"

    describe "SQL Identifier and String Sanitization" $ do
        it "escapes identifiers and special characters" $ do
            sqlIdent "simple" `shouldBe` "\"simple\""
            sqlIdent "bfo:Process" `shouldBe` "\"bfo_Process\""
            sqlIdent "a.b-c:d" `shouldBe` "\"a_b_c_d\""
            sqlIdent "quote\"name" `shouldBe` "\"quote\"\"name\""

        it "escapes single quotes in string values" $ do
            escapeSqlString "plain" `shouldBe` "plain"
            escapeSqlString "O'Connor" `shouldBe` "O''Connor"
            escapeSqlString "''test''" `shouldBe` "''''test''''"

        it "emits properly sanitized and quoted tables for namespaced concepts" $ do
            let nsSrc = unlines
                  [ "(def-concept bfo:Entity)"
                  , "(def-property core-id bfo:Entity String :default \"val's\")"
                  ]
                nsReg = load nsSrc
                nsSql = emitSql nsReg
            nsSql `shouldContain` "CREATE TABLE IF NOT EXISTS \"bfo_Entity\""
            nsSql `shouldContain` "\"core_id\" TEXT DEFAULT 'val''s' NOT NULL"

        it "emits foreign key columns for PTCustom and handles Top/Bottom expressions" $ do
            let customSrc = unlines
                  [ "(def-concept Organization)"
                  , "(def-concept Employee)"
                  , "(def-property company Employee Organization)"
                  , "(def-property prev_companies Employee Organization :cardinality 0..*)"
                  , "(def-property rank Employee Integer)"
                  , "(def-property min_rank Employee Integer)"
                  , "(forall (e) (implies (Employee e) (ne rank 0)))"
                  , "(forall (e) (implies (Employee e) (implies (gte rank 1) (eq rank min_rank))))"
                  ]
                customReg = load customSrc
                customSql = emitSql customReg
            customSql `shouldContain` "\"company\" TEXT REFERENCES \"Organization\"(\"id\") ON DELETE SET NULL"
            customSql `shouldContain` "\"prev_companies\" TEXT[]"
            customSql `shouldContain` "\"rank\" <> 0"
            customSql `shouldContain` "\"rank\" = \"min_rank\""
