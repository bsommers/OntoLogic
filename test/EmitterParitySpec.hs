-- | v1.8.4 emitter parity: a rule in the source is either enforced by the generated code or
--   reported as unmapped. It never becomes a check that cannot fail and never disappears
--   without a warning. Where python3 (with pydantic), rustc, go or javac are installed the
--   generated output is compiled and RUN against valid and invalid instances.
module EmitterParitySpec (spec) where

import Test.Hspec
import Control.Monad (forM_, when)
import Data.List (isInfixOf, intercalate)
import Data.Text (pack)
import System.Directory (createDirectoryIfMissing, removeDirectoryRecursive, doesDirectoryExist, findExecutable, getHomeDirectory)
import System.Exit (ExitCode(..))
import System.FilePath ((</>))
import System.Process (readProcessWithExitCode)
import Text.Megaparsec (parse, errorBundlePretty)
import OntoLogic
import Parser (parseRegistry)
import IR
import Emitters.Python (emitPython)
import Emitters.Java (emitJava)
import Emitters.Rust (emitRust)
import Emitters.Go (emitGo)
import Emitters.TypeScript (emitTypeScript)
import Emitters.Shacl (emitShacl)
import Emitters.TPTP (emitTPTP)

load :: String -> Registry
load src = either (error . errorBundlePretty) id (parse parseRegistry "t" (pack src))

-- | Five rules that used to vanish or turn into a vacuous check.
paritySrc :: String
paritySrc = unlines
    [ "(def-concept Account)"
    , "(def-concept LockedAccount Account)"
    , "(def-property state Account String)"
    , "(def-property enabled Account Boolean)"
    , "(def-property balance Account Integer)"
    , "(def-property is_active Account Boolean)"
    , "(def-property pressure Account Integer)"
    , "(forall (a) (implies (LockedAccount a) (eq state \"locked\")))"
    , "(forall (a) (implies (LockedAccount a) (eq enabled False)))"
    , "(forall (a) (implies (Account a) (gte balanse 0)))"
    , "(forall (a) (implies (Account a) (ne balance 13)))"
    , "(forall (a) (implies (and (Account a) (eq is_active True)) (gt pressure 1)))"
    ]

-- | Expected verdict (True = valid) for the eight probe instances used by every runner:
--   A1 balance 13, A2 plain valid, A3 active with pressure 1, A4 active with pressure 2,
--   L1 locked account with state "open", L2 locked with enabled true, L3 valid locked,
--   L4 valid locked but active with pressure 0 (an inherited conditional).
expectedVerdicts :: [Bool]
expectedVerdicts = [False, True, False, True, False, False, True, False]

workDir :: String -> IO FilePath
workDir name = do
    let d = ".test-tmp" </> ("parity_" ++ name)
    exists <- doesDirectoryExist d
    when exists (removeDirectoryRecursive d)
    createDirectoryIfMissing True d
    return d

verdicts :: String -> [Bool]
verdicts out = [ l == "ok" | l <- lines out, l `elem` ["ok", "err"] ]

spec :: Spec
spec = describe "Emitter parity (v1.8.4)" $ do
    let reg = load paritySrc
        unmappedText = concatMap formatFOL (irUnmappedAxioms (compileRegistry reg))

    describe "unmapped reporting" $ do
        it "lists string equality, Boolean equality, ne and the undeclared-property bound" $ do
            unmappedText `shouldSatisfy` ("state" `isInfixOf`)
            unmappedText `shouldSatisfy` ("enabled" `isInfixOf`)
            unmappedText `shouldSatisfy` ("balanse" `isInfixOf`)
            unmappedText `shouldSatisfy` ("ne(balance" `isInfixOf`)

        it "does not list a numeric bound on a declared numeric property" $ do
            let ok = load "(def-concept A)\n(def-property n A Integer)\n(forall (a) (implies (A a) (gte n 0)))"
            irUnmappedAxioms (compileRegistry ok) `shouldBe` []

    describe "no translator falls back to true" $ do
        it "Python/Java/Go/Rust/TypeScript never emit a constant-true premise" $ do
            emitPython reg `shouldSatisfy` (not . ("if True and" `isInfixOf`) )
            forM_ (emitJava reg) $ \(_, c) -> c `shouldSatisfy` (not . ("if (true)" `isInfixOf`))
            emitGo reg `shouldSatisfy` (not . ("if (true) &&" `isInfixOf`))
            emitRust reg `shouldSatisfy` (not . ("if (true) &&" `isInfixOf`))
            emitTypeScript reg `shouldSatisfy` (not . ("if (true)" `isInfixOf`))

        it "enforces the eq conditional in TypeScript and SHACL" $ do
            emitTypeScript reg `shouldSatisfy` ("data.is_active === true" `isInfixOf`)
            emitTypeScript reg `shouldSatisfy` ("data.state === \"locked\"" `isInfixOf`)
            emitTypeScript reg `shouldSatisfy` ("data.balance !== 13" `isInfixOf`)
            let shacl = emitShacl reg
            shacl `shouldSatisfy` ("sh:path ont:is_active" `isInfixOf`)
            shacl `shouldSatisfy` ("sh:hasValue true" `isInfixOf`)
            shacl `shouldSatisfy` ("sh:hasValue \"locked\"" `isInfixOf`)

        it "keeps an untranslatable conditional out of the generated code" $ do
            let r = load $ unlines
                    [ "(def-concept P)", "(def-property a P Integer)"
                    , "(forall (p) (implies (and (P p) (eq typo_flag True)) (gt a 1)))" ]
            emitPython r `shouldSatisfy` (not . ("typo_flag" `isInfixOf`))
            irUnmappedAxioms (compileRegistry r) `shouldSatisfy` (not . null)

    describe "a declared relation named like a comparison" $ do
        let relReg = load $ unlines
                [ "(def-concept Widget)"
                , "(def-relation gt Widget Widget)"
                , "(def-relation lt Widget Widget)"
                , "(forall (w) (gt w 5))"
                , "(exists (w) (lt w 3))" ]
        it "is not treated as arithmetic" $ do
            numericBoundLiterals relReg `shouldBe` []
            disjointBoundPairs relReg `shouldBe` []
            emitTPTP relReg `shouldSatisfy` (not . ("cmp_" `isInfixOf`))
            emitTPTP relReg `shouldSatisfy` ("rel_gt(" `isInfixOf`)
        it "still treats undeclared gt/lt as arithmetic" $ do
            let a = load "(def-concept W)\n(def-property n W Integer)\n(forall (w) (implies (W w) (gt n 5)))\n(forall (w) (implies (W w) (lt n 3)))"
            disjointBoundPairs a `shouldSatisfy` (not . null)

    describe "generated code, executed" $ do
        it "Python (pydantic) rejects exactly the invalid instances" $ do
            py <- findExecutable "python3"
            case py of
                Nothing -> pendingWith "python3 not installed"
                Just p -> do
                    (probe, _, _) <- readProcessWithExitCode p ["-c", "import pydantic"] ""
                    if probe /= ExitSuccess then pendingWith "pydantic not installed" else do
                        d <- workDir "python"
                        writeFile (d </> "models.py") (emitPython reg)
                        writeFile (d </> "run.py") $ unlines
                            [ "from models import *"
                            , "def t(f):"
                            , "    try:"
                            , "        f(); print('ok')"
                            , "    except Exception:"
                            , "        print('err')"
                            , "A = dict(state='s', enabled=True, balance=1, is_active=False, pressure=0)"
                            , "t(lambda: Account(**{**A, 'balance': 13}))"
                            , "t(lambda: Account(**A))"
                            , "t(lambda: Account(**{**A, 'is_active': True, 'pressure': 1}))"
                            , "t(lambda: Account(**{**A, 'is_active': True, 'pressure': 2}))"
                            , "t(lambda: LockedAccount(**{**A, 'state': 'open', 'enabled': False}))"
                            , "t(lambda: LockedAccount(**{**A, 'state': 'locked', 'enabled': True}))"
                            , "t(lambda: LockedAccount(**{**A, 'state': 'locked', 'enabled': False}))"
                            , "t(lambda: LockedAccount(**{**A, 'state': 'locked', 'enabled': False, 'is_active': True, 'pressure': 0}))"
                            ]
                        (ec, out, err) <- readProcessWithExitCode p ["-c", "import sys; sys.path.insert(0, '" ++ d ++ "'); exec(open('" ++ (d </> "run.py") ++ "').read())"] ""
                        (ec, err) `shouldBe` (ExitSuccess, "")
                        verdicts out `shouldBe` expectedVerdicts

        it "Rust compiles and rejects exactly the invalid instances" $ do
            rc <- findExecutable "rustc"
            case rc of
                Nothing -> pendingWith "rustc not installed"
                Just r -> do
                    d <- workDir "rust"
                    let acct s e b a p = "Account { state: \"" ++ s ++ "\".to_string(), enabled: " ++ e ++ ", balance: " ++ show (b :: Int) ++ ", is_active: " ++ a ++ ", pressure: " ++ show (p :: Int) ++ " }"
                        locked s e a p = "LockedAccount { base: " ++ acct s e 1 a p ++ " }"
                        line v = "    println!(\"{}\", if (" ++ v ++ ").validate().is_ok() { \"ok\" } else { \"err\" });"
                        mainFn = unlines $ ["fn main() {"] ++ map line
                            [ acct "s" "true" 13 "false" 0, acct "s" "true" 1 "false" 0
                            , acct "s" "true" 1 "true" 1, acct "s" "true" 1 "true" 2
                            , locked "open" "false" "false" 0, locked "locked" "true" "false" 0
                            , locked "locked" "false" "false" 0, locked "locked" "false" "true" 0
                            ] ++ ["}"]
                    writeFile (d </> "main.rs") (emitRust reg ++ "\n" ++ mainFn)
                    (ec, _, err) <- readProcessWithExitCode r [d </> "main.rs", "-o", d </> "prog"] ""
                    (ec, takeWhile (/= '\n') (if ec == ExitSuccess then "" else err), err) `shouldBe` (ExitSuccess, "", "")
                    (_, out, _) <- readProcessWithExitCode (d </> "prog") [] ""
                    verdicts out `shouldBe` expectedVerdicts

        it "Go compiles and rejects exactly the invalid instances" $ do
            gc <- findExecutable "go"
            case gc of
                Nothing -> pendingWith "go not installed"
                Just g -> do
                    d <- workDir "go"
                    let code = unlines (map (\l -> if l == "package models" then "package main" else l) (lines (emitGo reg)))
                        acct s e b a p = "Account{State: \"" ++ s ++ "\", Enabled: " ++ e ++ ", Balance: " ++ show (b :: Int) ++ ", IsActive: " ++ a ++ ", Pressure: " ++ show (p :: Int) ++ "}"
                        locked s e a p = "LockedAccount{Account: " ++ acct s e 1 a p ++ "}"
                        line v = "    if len((&" ++ v ++ ").Validate()) == 0 { println(\"ok\") } else { println(\"err\") }"
                        mainFn = unlines $ ["func main() {"] ++ map line
                            [ acct "s" "true" 13 "false" 0, acct "s" "true" 1 "false" 0
                            , acct "s" "true" 1 "true" 1, acct "s" "true" 1 "true" 2
                            , locked "open" "false" "false" 0, locked "locked" "true" "false" 0
                            , locked "locked" "false" "false" 0, locked "locked" "false" "true" 0
                            ] ++ ["}"]
                    writeFile (d </> "models.go") code
                    writeFile (d </> "main.go") ("package main\n\n" ++ mainFn)
                    (ec, out, err) <- readProcessWithExitCode g ["run", d </> "models.go", d </> "main.go"] ""
                    -- println writes to stderr
                    (ec, out) `shouldBe` (ExitSuccess, "")
                    verdicts err `shouldBe` expectedVerdicts

        it "Java compiles and rejects exactly the invalid instances" $ do
            jc <- findExecutable "javac"
            home <- getHomeDirectory
            (_, jarOut, _) <- readProcessWithExitCode "find" [home </> ".gradle" </> "caches", "-name", "jakarta.validation-api-*.jar"] ""
            case (jc, lines jarOut) of
                (Nothing, _) -> pendingWith "javac not installed"
                (_, []) -> pendingWith "jakarta.validation-api jar not found"
                (Just javac, jar : _) -> do
                    d <- workDir "java"
                    forM_ (emitJava reg) $ \(n, c) -> writeFile (d </> n ++ ".java") c
                    let mk cls s e a p = "mk(new " ++ cls ++ "(), \"" ++ s ++ "\", " ++ e ++ ", 1, " ++ a ++ ", " ++ show (p :: Int) ++ ")"
                        cases =
                            [ "bal(" ++ mk "Account" "s" "true" "false" 0 ++ ", 13)"
                            , mk "Account" "s" "true" "false" 0
                            , mk "Account" "s" "true" "true" 1
                            , mk "Account" "s" "true" "true" 2
                            , mk "LockedAccount" "open" "false" "false" 0
                            , mk "LockedAccount" "locked" "true" "false" 0
                            , mk "LockedAccount" "locked" "false" "false" 0
                            , mk "LockedAccount" "locked" "false" "true" 0
                            ]
                        mainSrc = unlines
                            [ "import ontologic.generated.*;"
                            , "import java.lang.reflect.Method;"
                            , "public class Main {"
                            , "  static Account mk(Account a, String s, boolean e, int b, boolean act, int p) {"
                            , "    a.setState(s); a.setEnabled(e); a.setBalance(b); a.setIs_active(act); a.setPressure(p); return a; }"
                            , "  static Account bal(Account a, int b) { a.setBalance(b); return a; }"
                            , "  static boolean valid(Object o) throws Exception {"
                            , "    for (Method m : o.getClass().getMethods())"
                            , "      if (m.getName().startsWith(\"isValid\") && m.getParameterCount() == 0 && !((Boolean) m.invoke(o))) return false;"
                            , "    return true; }"
                            , "  public static void main(String[] x) throws Exception {"
                            , "    Object[] all = new Object[] { " ++ intercalate ", " cases ++ " };"
                            , "    for (Object o : all) System.out.println(valid(o) ? \"ok\" : \"err\");"
                            , "  }"
                            , "}"
                            ]
                    writeFile (d </> "Main.java") mainSrc
                    let srcs = [ d </> n ++ ".java" | (n, _) <- emitJava reg ] ++ [d </> "Main.java"]
                    (ec, _, err) <- readProcessWithExitCode javac (["-cp", jar, "-d", d] ++ srcs) ""
                    (ec, err) `shouldBe` (ExitSuccess, "")
                    (_, out, _) <- readProcessWithExitCode "java" ["-cp", d ++ ":" ++ jar, "-ea", "Main"] ""
                    verdicts out `shouldBe` expectedVerdicts

    describe "conditionals on inherited properties compile (shipped examples)" $
        forM_ ["examples/bfo_energy.logic", "examples/domain_systems_engineering.logic"] $ \path ->
            it ("Rust output for " ++ path ++ " compiles") $ do
                rc <- findExecutable "rustc"
                case rc of
                    Nothing -> pendingWith "rustc not installed"
                    Just r -> do
                        src <- readFile path
                        d <- workDir "corpus_rust"
                        writeFile (d </> "models.rs") (emitRust (load src))
                        (ec, _, err) <- readProcessWithExitCode r ["--crate-type", "lib", "-A", "warnings", d </> "models.rs", "--out-dir", d] ""
                        (ec, err) `shouldBe` (ExitSuccess, "")
