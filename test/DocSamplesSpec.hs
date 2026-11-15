{-# LANGUAGE OverloadedStrings #-}
-- | Every complete ontology sample in the user-facing docs must parse.
module DocSamplesSpec (spec) where

import Test.Hspec
import Text.Megaparsec (parse, errorBundlePretty)
import System.Directory (listDirectory, doesFileExist)
import System.FilePath ((</>), takeExtension)
import Data.Char (isSpace, toLower)
import Data.List (isPrefixOf, isInfixOf, sort)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Encoding.Error as TEE
import qualified Data.ByteString as BS

import Parser (parseRegistry)

data Sample = Sample { sFile :: FilePath, sStart :: Int, sEnd :: Int, sBody :: String }

-- | Samples known broken until the docs stream fixes them: (file, line).
knownBroken :: [(FilePath, Int)]
knownBroken = []

docFiles :: IO [FilePath]
docFiles = do
    guide <- sort . filter ((== ".md") . takeExtension) <$> listDirectory "docs/user-guide"
    let fs = ["README.md", "docs/using.md", "docs/standard-library.md"] ++ map ("docs/user-guide" </>) guide
    filterM' doesFileExist fs
  where filterM' p = fmap concat . mapM (\x -> (\b -> [x | b]) <$> p x)

-- | Fenced blocks as (language tag, first body line number, body lines).
fences :: [String] -> [(String, Int, [String])]
fences = go 1
  where
    go _ [] = []
    go n (l:ls)
        | "```" `isPrefixOf` dropWhile isSpace l =
            let lang = map toLower (trim (drop 3 (dropWhile isSpace l)))
                (body, rest) = break (isPrefixOf "```" . dropWhile isSpace) ls
            in (lang, n, body) : go (n + length body + 2) (drop 1 rest)
        | otherwise = go (n + 1) ls

trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

firstCode :: [String] -> String
firstCode ls = case filter (\l -> not (null (trim l)) && not (";" `isPrefixOf` trim l)) ls of
    (l:_) -> trim l
    []    -> ""

looksLikeLogic :: String -> [String] -> Bool
looksLikeLogic lang body
    | lang `elem` ["lisp", "logic", "ontologic", "scheme", "clojure"] = True
    | null lang = "(" `isPrefixOf` firstCode body && any (`isInfixOf` unwords body) ["(def-", "(namespace", "(import", "(axiom"]
    | otherwise = False

isTemplate :: [String] -> Bool
isTemplate body = any (\l -> "[" `isInfixOf` l || "..." `isInfixOf` l) body

samplesOf :: FilePath -> IO [Sample]
samplesOf f = do
    ls <- lines . T.unpack . TE.decodeUtf8With TEE.lenientDecode <$> BS.readFile f
    return [ Sample f n (n + length body) (unlines body)
           | (lang, n, body) <- fences ls, looksLikeLogic lang body, not (isTemplate body) ]

spec :: Spec
spec = describe "Documentation samples" $ do
    samples <- runIO (docFiles >>= fmap concat . mapM samplesOf)
    it "finds samples to check" $ length samples `shouldSatisfy` (> 10)
    mapM_ check samples
  where
    check s =
        let label = sFile s ++ ":" ++ show (sStart s)
            broken = any (\(f, n) -> f == sFile s && n >= sStart s - 1 && n <= sEnd s + 1) knownBroken
            result = parse parseRegistry label (T.pack (sBody s))
        in it ("parses " ++ label) $ case result of
            Right _ -> return ()
            Left err | broken -> pendingWith ("known broken until docs are fixed: " ++ label)
                     | otherwise -> expectationFailure (errorBundlePretty err)
