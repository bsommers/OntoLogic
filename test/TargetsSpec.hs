module TargetsSpec (spec) where

import Test.Hspec
import Control.Monad (forM_)
import Data.List (isInfixOf, isPrefixOf)
import Data.Text (pack)
import System.Exit (ExitCode(..))
import System.Process (readProcessWithExitCode)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import Targets
import REPL (evalREPLCommand, initialREPLState)

spec :: Spec
spec = describe "Shared emit-target table (#34)" $ do
    it "resolves every name and alias" $
        forM_ targets $ \t ->
            forM_ (targetName t : targetAliases t) $ \n ->
                fmap targetName (lookupTarget n) `shouldBe` Just (targetName t)

    -- Target holds a function, so it has no Show instance; compare resolved names.
    it "includes the targets the REPL used to lack" $
        forM_ ["mermaid", "d2", "neo4j", "owl"] $ \n ->
            fmap targetName (lookupTarget n) `shouldBe` Just n

    it "lists every target in the CLI help" $
        forM_ targets $ \t -> targetHelp `shouldContain` targetName t

    it "can emit every target from the REPL" $ do
        (s1, _) <- evalREPLCommand initialREPLState "(def-concept Robot)"
        forM_ targets $ \t -> do
            (_, out) <- evalREPLCommand s1 (":emit " ++ targetName t)
            out `shouldNotContain` "Unknown emit target"

    it "produces at least one file per target" $
        forM_ targets $ \t ->
            targetEmit t defaultEmitOptions (emptyRegistry { concepts = [("A", Nothing)] }) `shouldSatisfy` (not . null)

    it "emits graph.cypher and constraints.cypher for neo4j (#48)" $ do
        case lookupTarget "neo4j" of
            Nothing -> expectationFailure "neo4j target not found"
            Just tgt -> do
                let files = map fst (targetEmit tgt defaultEmitOptions (emptyRegistry { concepts = [("A", Nothing)] }))
                files `shouldBe` ["graph.cypher", "constraints.cypher"]

    it "honors Neo4jEdition in targetEmit options" $ do
        case lookupTarget "neo4j" of
            Nothing -> expectationFailure "neo4j target not found"
            Just tgt -> do
                let reg = (emptyRegistry { concepts = [("A", Nothing)], properties = [Property "p" "A" PTString] })
                    filesComm = targetEmit tgt (defaultEmitOptions { optNeo4jEdition = Neo4jCommunity }) reg
                    filesEnt = targetEmit tgt (defaultEmitOptions { optNeo4jEdition = Neo4jEnterprise }) reg
                lookup "constraints.cypher" filesComm `shouldSatisfy` (\m -> case m of Just c -> "Community Edition" `isInfixOf` c && "// CREATE CONSTRAINT" `isInfixOf` c; Nothing -> False)
                lookup "constraints.cypher" filesEnt `shouldSatisfy` (\m -> case m of Just c -> "Enterprise Edition" `isInfixOf` c && "\nCREATE CONSTRAINT" `isInfixOf` c; Nothing -> False)

    it "parses neo4j edition names case-insensitively" $ do
        parseNeo4jEdition "community" `shouldBe` Just Neo4jCommunity
        parseNeo4jEdition "Enterprise" `shouldBe` Just Neo4jEnterprise
        parseNeo4jEdition "invalid" `shouldBe` Nothing

    describe "unmapped-axiom warnings (v1.5.1 review)" $ do
        let load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))
            -- A disjunction is never mapped to a field constraint; the string constant spans two lines.
            reg = load "(def-concept Doc) (def-property label Doc String) (forall (x) (or (Doc x) (eq label \"a\\nb\")))"
            warning = "WARNING: The following axioms could not be mapped"
            emitFor n = maybe (error n) (\t -> targetEmit t defaultEmitOptions reg) (lookupTarget n)
            count needle hay = length [ () | i <- [0 .. length hay - length needle], needle `isPrefixOf` drop i hay ]

        it "the test axiom really contains a newline" $
            map formatFOL (axioms reg) `shouldSatisfy` any ('\n' `elem`)

        it "every target that supports comments carries the warning exactly once" $
            forM_ (filter (/= "jsonschema") (map targetName targets)) $ \n ->
                (n, sum (map (count warning . snd) (emitFor n))) `shouldBe` (n, 1)

        it "comments every line of a multi-line axiom" $
            forM_ [("python", "#"), ("go", "//"), ("rust", "//"), ("smt", ";"), ("graphql", "#"), ("mermaid", "%%"), ("sql", "--"), ("tptp", "%")] $ \(n, prefix) -> do
                let out = concatMap snd (emitFor n)
                    tailLines = dropWhile (not . (warning `isInfixOf`)) (lines out)
                (n, filter (not . (prefix `isPrefixOf`)) tailLines) `shouldBe` (n, [])

        it "normalizes CRLF without producing empty comment lines" $ do
            let regCRLF = load "(def-concept Doc) (def-property label Doc String) (forall (x) (or (Doc x) (eq label \"a\\r\\nb\")))"
                out = concatMap snd (maybe (error "go") (\t -> targetEmit t defaultEmitOptions regCRLF) (lookupTarget "go"))
                warningLines = dropWhile (not . (warning `isInfixOf`)) (lines out)
            filter (== "// ") warningLines `shouldBe` []

        it "writes the Java warning once, in package-info.java" $ do
            let files = emitFor "java"
            [ f | (f, c) <- files, warning `isInfixOf` c ] `shouldBe` ["package-info.java"]
            lookup "package-info.java" files `shouldSatisfy` maybe False ("package ontologic.generated;" `isInfixOf`)

        it "keeps the Python output parseable" $ do
            (code, _, err) <- readProcessWithExitCode "python3" ["-c", "import ast,sys; ast.parse(sys.stdin.read())"] (concatMap snd (emitFor "python"))
            (code, err) `shouldBe` (ExitSuccess, "")

        it "keeps the SMT output parseable by z3" $ do
            (_, out, _) <- readProcessWithExitCode "z3" ["-in"] (concatMap snd (emitFor "smt"))
            out `shouldNotContain` "error"

        it "keeps the OWL output well-formed XML" $ do
            (code, _, err) <- readProcessWithExitCode "python3" ["-c", "import sys, xml.dom.minidom as m; m.parseString(sys.stdin.read())"] (concatMap snd (emitFor "owl"))
            (code, err) `shouldBe` (ExitSuccess, "")
