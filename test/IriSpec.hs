-- | OWL and SHACL must name the same resources (#49). Checked by resolving both
--   documents with a real RDF parser, not by matching substrings: the broken output
--   was well-formed XML and parsed cleanly, it just named the wrong things.
module IriSpec (spec) where

import Test.Hspec
import Data.List (sort)
import Data.Text (pack)
import System.Directory (createDirectoryIfMissing, getTemporaryDirectory)
import System.Exit (ExitCode(..))
import System.FilePath ((</>))
import System.Process (readProcessWithExitCode)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import Emitters.Owl (emitOwl)
import Emitters.Shacl (emitShacl)
import CompileSpec (skipOrFail)

load :: String -> Registry
load = either (error . errorBundlePretty) id . parse parseRegistry "t" . pack

resolver :: String
resolver = unlines
    [ "import sys, rdflib"
    , "from rdflib.namespace import RDF, OWL"
    , "SH = rdflib.Namespace('http://www.w3.org/ns/shacl#')"
    , "g = rdflib.Graph(); g.parse(sys.argv[1], format='xml')"
    , "s = rdflib.Graph(); s.parse(sys.argv[2], format='turtle')"
    , "for c in sorted(str(x) for x in g.subjects(RDF.type, OWL.Class)): print('OWL', c)"
    , "for c in sorted(str(x) for x in s.objects(None, SH.targetClass)): print('SHACL', c)"
    ]

-- | Class IRIs each serialisation actually declares, as a real parser sees them.
resolvedIris :: Registry -> IO ([String], [String])
resolvedIris reg = do
    dir <- (</> "ontologic-iri") <$> getTemporaryDirectory
    createDirectoryIfMissing True dir
    let owlFile = dir </> "ontology.owl"
        ttlFile = dir </> "shapes.ttl"
    writeFile owlFile (emitOwl reg)
    writeFile ttlFile (emitShacl reg)
    (code, out, err) <- readProcessWithExitCode "python3" ["-c", resolver, owlFile, ttlFile] ""
    if code /= ExitSuccess
        then do
            expectationFailure ("could not resolve the emitted RDF: " ++ take 400 (out ++ err))
            return ([], [])
        else return ( sort [ i | l <- lines out, ("OWL", i) <- [splitTag l] ]
                    , sort [ i | l <- lines out, ("SHACL", i) <- [splitTag l] ] )
  where
    splitTag l = case words l of
        (tag:rest) -> (tag, unwords rest)
        []         -> ("", "")

haveRdflib :: IO Bool
haveRdflib = do
    (code, _, _) <- readProcessWithExitCode "python3" ["-c", "import rdflib"] ""
    return (code == ExitSuccess)

withRdflib :: (() -> IO ()) -> IO ()
withRdflib act = do
    ok <- haveRdflib
    if ok then act () else skipOrFail "rdflib not installed"

spec :: Spec
spec = describe "OWL and SHACL name the same resources (#49)" $ do
    it "resolves a prefixed concept into its declared namespace" $ withRdflib $ \_ -> do
        let reg = load "(namespace bfo \"http://purl.obolibrary.org/obo/BFO_\") (def-concept bfo:Entity)"
        (owl, shacl) <- resolvedIris reg
        owl `shouldBe` ["http://purl.obolibrary.org/obo/BFO_Entity"]
        shacl `shouldBe` owl

    it "does not repeat the namespace in the local name" $ withRdflib $ \_ -> do
        let reg = load "(namespace bfo \"http://purl.obolibrary.org/obo/BFO_\") (def-concept bfo:Entity)"
        (owl, _) <- resolvedIris reg
        owl `shouldNotContain` ["http://purl.obolibrary.org/obo/BFO_#bfo:Entity"]

    it "agrees on every class of a real standard-library ontology" $ withRdflib $ \_ -> do
        let reg = load $ unlines
                [ "(namespace bfo \"http://purl.obolibrary.org/obo/BFO_\")"
                , "(def-concept bfo:Entity)"
                , "(def-concept bfo:Continuant bfo:Entity)"
                , "(def-concept bfo:Process bfo:Entity)"
                , "(def-property bfo:identifier bfo:Entity String)"
                , "(def-relation bfo:part_of bfo:Continuant bfo:Entity)"
                ]
        (owl, shacl) <- resolvedIris reg
        owl `shouldBe` shacl
        length owl `shouldBe` 3

    it "keeps an unprefixed concept under the base IRI" $ withRdflib $ \_ -> do
        (owl, shacl) <- resolvedIris (load "(def-concept Plain)")
        owl `shouldBe` ["http://example.org/ontologic#Plain"]
        shacl `shouldBe` owl

    it "emits parseable output for an undeclared prefix" $ withRdflib $ \_ -> do
        -- An undeclared prefix used to emit `foo:Bar` with no @prefix, which is not Turtle.
        (owl, shacl) <- resolvedIris (load "(def-concept foo:Bar)")
        owl `shouldBe` shacl
        length owl `shouldBe` 1
