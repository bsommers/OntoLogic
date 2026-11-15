{-# LANGUAGE OverloadedStrings #-}
module Loader 
    ( loadRegistryWithImports
    , loadRegistryWithLibPaths
    , loadRegistryWithImportsFromSearchPaths
    , loadRegistryWithImportsAndSource
    , loadRegistryWithLibPathsAndSource
    , loadRegistryWithImportsFromSearchPathsAndSource
    , stdlibSearchPaths
    , resolveImports
    , resolveImportsWithSource
    , findImportFile
    , loadImportFrom
    , loadRegistryWithOptions
    , ontologicVersion
    ) where

import qualified Data.Text.IO as TIO
import qualified Data.Map as Map
import Text.Megaparsec (parse, errorBundlePretty)
import System.FilePath ((</>), takeDirectory, isAbsolute, normalise, takeExtension)
import System.Directory (doesFileExist, doesDirectoryExist, canonicalizePath)
import System.Environment (lookupEnv, getExecutablePath)
import System.FilePath (splitSearchPath)
import Control.Monad (filterM)
import Paths_ontologic (getDataDir, version)
import Data.Version (showVersion)
import qualified Data.Set as Set
import Data.List (intercalate)

import OntoLogic
import Parser (parseRegistryWithSource)

-- | Standard-library directories that exist, highest priority first.
stdlibSearchPaths :: IO [FilePath]
stdlibSearchPaths = do
    envPaths <- maybe [] splitSearchPath <$> lookupEnv "ONTOLOGIC_PATH"
    exeDir <- takeDirectory <$> getExecutablePath
    dataDir <- getDataDir
    filterM doesDirectoryExist $
        envPaths ++
        [ exeDir </> ".." </> "ontologic-lib"   -- release layout: bin/ontologic + ontologic-lib/
        , exeDir </> "ontologic-lib"
        , dataDir </> "ontologic-lib"            -- cabal/stack install
        , "ontologic-lib"                        -- running from a source checkout
        , "."                                    -- last: CWD-relative paths still work, but cannot shadow the stdlib
        ]


-- | Package version, taken from the cabal package so it cannot drift.
ontologicVersion :: String
ontologicVersion = showVersion version

-- | Load with extra search paths; the Bool permits absolute import paths
--   (the --allow-absolute-imports flag).
loadRegistryWithOptions :: Bool -> [FilePath] -> FilePath -> IO (Either String (Registry, SourceTable))
loadRegistryWithOptions allowAbs extra rootFile = do
    defaults <- stdlibSearchPaths
    loadWith allowAbs (extra ++ defaults) rootFile

-- | Load a .logic file and its transitive imports returning (Registry, SourceTable).
loadRegistryWithImportsAndSource :: FilePath -> IO (Either String (Registry, SourceTable))
loadRegistryWithImportsAndSource = loadRegistryWithLibPathsAndSource []

-- | Load with extra search paths returning (Registry, SourceTable).
loadRegistryWithLibPathsAndSource :: [FilePath] -> FilePath -> IO (Either String (Registry, SourceTable))
loadRegistryWithLibPathsAndSource extra rootFile = do
    defaults <- stdlibSearchPaths
    loadRegistryWithImportsFromSearchPathsAndSource (extra ++ defaults) rootFile

-- | Load with explicit search paths returning (Registry, SourceTable).
loadRegistryWithImportsFromSearchPathsAndSource :: [FilePath] -> FilePath -> IO (Either String (Registry, SourceTable))
loadRegistryWithImportsFromSearchPathsAndSource = loadWith False

loadWith :: Bool -> [FilePath] -> FilePath -> IO (Either String (Registry, SourceTable))
loadWith allowAbs searchPaths rootFile = do
    exists <- doesFileExist rootFile
    if not exists
    then return $ Left ("File not found: " ++ rootFile)
    else do
        canonRoot <- canonicalizePath rootFile
        resolveImportsWithSource' allowAbs searchPaths canonRoot

-- | Load a .logic file and its transitive imports using the default library paths.
loadRegistryWithImports :: FilePath -> IO (Either String Registry)
loadRegistryWithImports = fmap (fmap fst) . loadRegistryWithImportsAndSource

-- | Like 'loadRegistryWithImports', searching the given directories before the defaults.
loadRegistryWithLibPaths :: [FilePath] -> FilePath -> IO (Either String Registry)
loadRegistryWithLibPaths extra rootFile = fmap (fmap fst) (loadRegistryWithLibPathsAndSource extra rootFile)

-- | Load with additional search paths (e.g. standard library directories)
loadRegistryWithImportsFromSearchPaths :: [FilePath] -> FilePath -> IO (Either String Registry)
loadRegistryWithImportsFromSearchPaths searchPaths rootFile =
    fmap (fmap fst) (loadRegistryWithImportsFromSearchPathsAndSource searchPaths rootFile)

-- | Locate one import by name in the given directories, in order.
findImportFile :: [FilePath] -> FilePath -> IO (Either String FilePath)
findImportFile = findImportFile' False

-- | Imports must name a .logic file, so an import can never be used to read
--   arbitrary files. Absolute paths are refused unless explicitly allowed.
findImportFile' :: Bool -> [FilePath] -> FilePath -> IO (Either String FilePath)
findImportFile' _ _ rawPath | takeExtension rawPath /= ".logic" =
    return $ Left ("Import must name a .logic file: " ++ rawPath)
findImportFile' False _ rawPath | isAbsolute rawPath =
    return $ Left ("Absolute import paths are not allowed (use --allow-absolute-imports): " ++ rawPath)
findImportFile' _ _ rawPath | isAbsolute rawPath = do
    exists <- doesFileExist rawPath
    if exists
    then return $ Right (normalise rawPath)
    else return $ Left ("Import not found: " ++ rawPath)
findImportFile' _ [] rawPath = return $ Left ("Import not found: " ++ rawPath)
findImportFile' allowAbs (dir:dirs) rawPath = do
    let candidate = dir </> rawPath
    exists <- doesFileExist candidate
    if exists
    then return $ Right (normalise candidate)
    else findImportFile' allowAbs dirs rawPath

-- | Resolve one import by name and load it with its own transitive imports.
--   The language server needs the resolved path as well as the registry.
loadImportFrom :: [FilePath] -> FilePath -> IO (Either String (FilePath, Registry))
loadImportFrom dirs rawPath = do
    found <- findImportFile dirs rawPath
    case found of
        Left err -> return (Left err)
        Right p -> do
            canon <- canonicalizePath p
            reg <- resolveImports dirs canon
            return (fmap (\r -> (canon, r)) reg)

-- | Internal recursive import resolver returning Registry
resolveImports :: [FilePath] -> FilePath -> IO (Either String Registry)
resolveImports searchPaths rootCanonPath = fmap (fmap fst) (resolveImportsWithSource searchPaths rootCanonPath)

-- | Internal recursive import resolver returning Registry and SourceTable
resolveImportsWithSource :: [FilePath] -> FilePath -> IO (Either String (Registry, SourceTable))
resolveImportsWithSource = resolveImportsWithSource' False

resolveImportsWithSource' :: Bool -> [FilePath] -> FilePath -> IO (Either String (Registry, SourceTable))
resolveImportsWithSource' allowAbs searchPaths rootCanonPath = do
    res <- go Set.empty [] rootCanonPath
    case res of
        Left err -> return $ Left err
        Right (_, reg, tbl) -> return $ Right (deduplicateRegistry reg, tbl)
  where
    go :: Set.Set FilePath -> [FilePath] -> FilePath -> IO (Either String (Set.Set FilePath, Registry, SourceTable))
    go finished visiting currentPath
        -- Cycle detection: file is currently in the active traversal stack
        | currentPath `elem` visiting =
            let cycleChain = reverse (currentPath : visiting)
            in return $ Left ("Circular import dependency detected: " ++ intercalate " -> " cycleChain)
        -- Diamond import: file has already been fully processed
        | Set.member currentPath finished = return $ Right (finished, emptyRegistry, emptySourceTable)
        | otherwise = do
            fileContent <- TIO.readFile currentPath
            case parse parseRegistryWithSource currentPath fileContent of
                Left err -> return $ Left ("Parse error in " ++ currentPath ++ ":\n" ++ errorBundlePretty err)
                Right (directReg, directTbl) -> do
                    let currentDir = takeDirectory currentPath
                        allSearchPaths = currentDir : searchPaths
                        importDecls = imports directReg
                    
                    -- Process each import recursively
                    subRes <- foldMImport allSearchPaths finished (currentPath : visiting) directReg directTbl importDecls
                    case subRes of
                        Left err -> return $ Left err
                        Right (newFinished, mergedReg, mergedTbl) ->
                            return $ Right (Set.insert currentPath newFinished, mergedReg, mergedTbl)

    foldMImport :: [FilePath] -> Set.Set FilePath -> [FilePath] -> Registry -> SourceTable -> [ImportDecl] -> IO (Either String (Set.Set FilePath, Registry, SourceTable))
    foldMImport _ finished _ accReg accTbl [] = return $ Right (finished, accReg, accTbl)
    foldMImport searchDirs finished visiting accReg accTbl (imp:rest) = do
        foundPathRes <- findImportFile' allowAbs searchDirs (importPath imp)
        case foundPathRes of
            Left err -> return $ Left err
            Right targetPath -> do
                canonTarget <- canonicalizePath targetPath
                subRes <- go finished visiting canonTarget
                case subRes of
                    Left err -> return $ Left err
                    Right (newFinished, subReg, subTbl) ->
                        let merged = mergeRegistries accReg subReg
                            mergedTbl = Map.union accTbl subTbl
                        in foldMImport searchDirs newFinished visiting merged mergedTbl rest


