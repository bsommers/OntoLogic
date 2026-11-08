{-# LANGUAGE OverloadedStrings #-}
module LSP
    ( runLSPServer
    , handleLSPRequest
    , handleLSPRequestIO
    , LSPState(..)
    , initialLSPState
    , encodeMessage
    , readMessage
    , applyRangeChange
    , extractJsonRange
    , extractNewDocumentText
    , computeSemanticTokens
    , formatLogicDocument
    , findSymbolOccurrences
    , getHoverInfo
    ) where

import System.IO (Handle, hFlush, stdout, stdin, hSetBinaryMode, hIsEOF)
import System.Directory (doesFileExist)
import Control.Concurrent (forkIO, killThread)
import Control.Concurrent.MVar (newMVar, readMVar, takeMVar, putMVar, modifyMVar, modifyMVar_)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Encoding.Error as TEE
import qualified Data.Map.Strict as Map
import Text.Megaparsec (parse, errorBundlePretty, ParseErrorBundle(..), errorOffset, reachOffset, PosState(..), SourcePos(..), unPos)
import qualified Data.List.NonEmpty as NE
import Data.Void (Void)
import System.FilePath (takeDirectory)
import Loader (stdlibSearchPaths, loadImportFrom)
import Data.List (isPrefixOf, isInfixOf)
import Data.Char (isAlphaNum, isSpace, isHexDigit, chr, isUpper, isDigit)

import OntoLogic
import Parser (parseRegistry, parseRegistryWithSource)
import Linter (lintRegistryFindings, lintRegistryFindingsWithSource, LintFinding(..))
import IR (compileRegistry, irClasses, compClassName, compParentClass, compProperties, compPropName, compPropType, compConstraints, CompiledProperty, compCardinality, compDefaultValue)
import Solver (checkConsistencyWith, explainUnsatWith, extractModel, Prover(AutoProver), UnsatExplanation(..))

data LSPState = LSPState
    { lspDocs :: Map.Map String String            -- URI -> Content
    , lspRegistries :: Map.Map String Registry    -- URI -> Parsed Registry
    , lspImportFiles :: Map.Map String [FilePath] -- URI -> files its imports resolved to
    } deriving (Show, Eq)

initialLSPState :: LSPState
initialLSPState = LSPState Map.empty Map.empty Map.empty

-- | Frame one message. Content-Length is the UTF-8 byte count, as the protocol
--   requires; counting characters desynchronises the stream on any non-ASCII content.
encodeMessage :: String -> BS.ByteString
encodeMessage body =
    let bytes = TE.encodeUtf8 (T.pack body)
    in BC.pack ("Content-Length: " ++ show (BS.length bytes) ++ "\r\n\r\n") <> bytes

-- | Read one framed message; Nothing at end of input or on a truncated body.
readMessage :: Handle -> IO (Maybe String)
readMessage h = do
    mLen <- readHeaders Nothing
    case mLen of
        Nothing -> return Nothing
        Just n -> do
            body <- BS.hGet h n
            return $ if BS.length body < n
                then Nothing
                else Just (T.unpack (TE.decodeUtf8With TEE.lenientDecode body))
  where
    readHeaders acc = do
        eof <- hIsEOF h
        if eof
            then return Nothing
            else do
                line <- BC.filter (/= '\r') <$> BS.hGetLine h
                if BS.null line
                    then maybe (readHeaders Nothing) (return . Just) acc
                    else readHeaders (contentLength line `orElse` acc)
    contentLength line =
        case BS.stripPrefix (BC.pack "Content-Length:") line of
            Just rest -> fst <$> BC.readInt (BC.dropWhile isSpace rest)
            Nothing   -> Nothing
    orElse new old = maybe old Just new

-- | Start the stdio JSON-RPC LSP Server Loop with async worker and client cancellation.
runLSPServer :: IO ()
runLSPServer = do
    hSetBinaryMode stdin True
    hSetBinaryMode stdout True
    stateVar <- newMVar initialLSPState
    jobsVar <- newMVar Map.empty

    let send body = do
            BS.hPut stdout (encodeMessage body)
            hFlush stdout

    let loop = do
            msg <- readMessage stdin
            case msg of
                Nothing -> return ()
                Just body
                    | extractJsonString "method" body == "exit" -> return ()
                    | extractJsonString "method" body == "$/cancelRequest" -> do
                        let cancelId = extractJsonId body
                        mJob <- modifyMVar jobsVar (\jobs ->
                            case Map.lookup cancelId jobs of
                                Just tid -> return (Map.delete cancelId jobs, Just tid)
                                Nothing  -> return (jobs, Nothing)
                            )
                        case mJob of
                            Just tid -> do
                                killThread tid
                                send $ "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId cancelId ++ ",\"error\":{\"code\":-32800,\"message\":\"Request cancelled by client\"}}"
                                send $ "{\"jsonrpc\":\"2.0\",\"method\":\"$/progress\",\"params\":{\"token\":" ++ formatId cancelId ++ ",\"value\":{\"kind\":\"end\",\"message\":\"Cancelled\"}}}"
                            Nothing -> return ()
                        loop
                    | extractJsonString "method" body == "workspace/executeCommand" && isAsyncCommand (extractJsonString "command" body) -> do
                        let reqId = extractJsonId body
                            cmd = extractJsonString "command" body
                        send $ "{\"jsonrpc\":\"2.0\",\"method\":\"$/progress\",\"params\":{\"token\":" ++ formatId reqId ++ ",\"value\":{\"kind\":\"begin\",\"title\":\"Running " ++ escapeJson cmd ++ "\",\"cancellable\":true}}}"
                        curState <- readMVar stateVar
                        tid <- forkIO $ do
                            (newState, respOpt, notifs) <- handleLSPRequestIO curState body
                            modifyMVar_ stateVar (\_ -> return newState)
                            mapM_ send notifs
                            send $ "{\"jsonrpc\":\"2.0\",\"method\":\"$/progress\",\"params\":{\"token\":" ++ formatId reqId ++ ",\"value\":{\"kind\":\"end\",\"message\":\"Completed\"}}}"
                            mapM_ send respOpt
                            modifyMVar_ jobsVar (\j -> return (Map.delete reqId j))
                        modifyMVar_ jobsVar (\j -> return (Map.insert reqId tid j))
                        loop
                    | otherwise -> do
                        curState <- takeMVar stateVar
                        (newState, responseOpt, notifs) <- handleLSPRequestIO curState body
                        putMVar stateVar newState
                        mapM_ send notifs
                        mapM_ send responseOpt
                        loop
    loop

-- | Pure LSP Request Handler for Testing and Server Dispatch
handleLSPRequest :: LSPState -> String -> (LSPState, Maybe String, [String])
handleLSPRequest state rawJson =
    let reqId = extractJsonId rawJson
        method = extractJsonString "method" rawJson
    in case method of
        "initialize" ->
            let resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"capabilities\":{" ++
                       "\"textDocumentSync\":2," ++
                       "\"completionProvider\":{\"triggerCharacters\":[\"(\",\" \",\"\\\"\"]}," ++
                       "\"hoverProvider\":true," ++
                       "\"definitionProvider\":true," ++
                       "\"renameProvider\":{\"prepareProvider\":true}," ++
                       "\"documentFormattingProvider\":true," ++
                       "\"semanticTokensProvider\":{\"legend\":" ++ semanticLegendJson ++ ",\"full\":true}," ++
                       "\"codeActionProvider\":true," ++
                       "\"executeCommandProvider\":{\"commands\":[\"ontologic.solve\",\"ontologic.explainUnsat\",\"ontologic.inspectModel\"]}" ++
                       "}}}"
            in (state, Just resp, [])

        "initialized" ->
            (state, Nothing, [])

        "$/cancelRequest" ->
            (state, Nothing, [])

        "textDocument/didOpen" ->
            let uri = extractJsonUri rawJson
                text = extractJsonString "text" rawJson
                (newState, notif) = updateDoc state uri text
            in (newState, Nothing, [notif])

        "textDocument/didChange" ->
            let uri = extractJsonUri rawJson
                oldDoc = Map.findWithDefault "" uri (lspDocs state)
                text = extractNewDocumentText rawJson oldDoc
                (newState, notif) = updateDoc state uri text
            in (newState, Nothing, [notif])

        "textDocument/completion" ->
            let uri = extractJsonUri rawJson
                reg = Map.findWithDefault emptyRegistry uri (lspRegistries state)
                items = getCompletions reg
                resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":[" ++ items ++ "]}"
            in (state, Just resp, [])

        "textDocument/hover" ->
            let uri = extractJsonUri rawJson
                line = extractJsonInt "line" rawJson
                char = extractJsonInt "character" rawJson
                content = Map.findWithDefault "" uri (lspDocs state)
                reg = Map.findWithDefault emptyRegistry uri (lspRegistries state)
                hoverText = getHoverInfo content line char reg
                resp = case hoverText of
                    Just md -> "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"contents\":{\"kind\":\"markdown\",\"value\":\"" ++ escapeJson md ++ "\"}}}"
                    Nothing -> "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":null}"
            in (state, Just resp, [])

        "textDocument/semanticTokens/full" ->
            let uri = extractJsonUri rawJson
                content = Map.findWithDefault "" uri (lspDocs state)
                reg = Map.findWithDefault emptyRegistry uri (lspRegistries state)
                toksData = computeSemanticTokens content reg
                resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"data\":[" ++ intercalateComma (map show toksData) ++ "]}}"
            in (state, Just resp, [])

        "textDocument/rename" ->
            let uri = extractJsonUri rawJson
                line = extractJsonInt "line" rawJson
                char = extractJsonInt "character" rawJson
                newName = extractJsonString "newName" rawJson
                content = Map.findWithDefault "" uri (lspDocs state)
                reg = Map.findWithDefault emptyRegistry uri (lspRegistries state)
                word = getWordAtPosition content line char
            in if null word || isKeyword word
               then let errResp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"error\":{\"code\":-32602,\"message\":\"Cannot rename keyword or empty symbol\"}}"
                    in (state, Just errResp, [])
               else if not (isValidSymbolName newName)
               then let errResp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"error\":{\"code\":-32602,\"message\":\"Invalid new symbol name: '" ++ escapeJson newName ++ "'\"}}"
                    in (state, Just errResp, [])
               else if not (isRenameableSymbol reg content word)
               then let errResp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"error\":{\"code\":-32602,\"message\":\"Symbol '" ++ escapeJson word ++ "' is not a declared concept, property, or relation\"}}"
                    in (state, Just errResp, [])
               else let edits = computeRenameEdits uri content word newName
                        resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"changes\":{\"" ++ escapeJson uri ++ "\":[" ++ intercalateComma edits ++ "]}}}"
                    in (state, Just resp, [])

        "textDocument/prepareRename" ->
            let uri = extractJsonUri rawJson
                line = extractJsonInt "line" rawJson
                char = extractJsonInt "character" rawJson
                content = Map.findWithDefault "" uri (lspDocs state)
                reg = Map.findWithDefault emptyRegistry uri (lspRegistries state)
                word = getWordAtPosition content line char
            in if null word || isKeyword word || not (isRenameableSymbol reg content word)
               then let resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":null}"
                    in (state, Just resp, [])
               else let (sChar, eChar) = getWordCharRange content line char word
                        resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"range\":{\"start\":{\"line\":" ++ show line ++ ",\"character\":" ++ show sChar ++ "},\"end\":{\"line\":" ++ show line ++ ",\"character\":" ++ show eChar ++ "}},\"placeholder\":\"" ++ escapeJson word ++ "\"}}"
                    in (state, Just resp, [])

        "textDocument/formatting" ->
            let uri = extractJsonUri rawJson
                tabSize = extractTabSize rawJson
                content = Map.findWithDefault "" uri (lspDocs state)
            in if null content
               then let resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":[]}"
                    in (state, Just resp, [])
               else let formatted = formatLogicDocument content tabSize
                        totalLines = length (lines content)
                        lastLineLen = if null (lines content) then 0 else length (last (lines content))
                        edit = "{\"range\":{\"start\":{\"line\":0,\"character\":0},\"end\":{\"line\":" ++ show totalLines ++ ",\"character\":" ++ show lastLineLen ++ "}},\"newText\":\"" ++ escapeJson formatted ++ "\"}"
                        resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":[" ++ edit ++ "]}"
                    in (state, Just resp, [])

        "textDocument/definition" ->
            let uri = extractJsonUri rawJson
                line = extractJsonInt "line" rawJson
                char = extractJsonInt "character" rawJson
                content = Map.findWithDefault "" uri (lspDocs state)
                loc = getDefinitionLocation content line char uri
            in (state, Just (definitionResponse reqId loc), [])

        "textDocument/codeAction" ->
            let uri = extractJsonUri rawJson
                actions =
                    [ "{\"title\":\"Verify SMT Consistency (AutoProver)\",\"kind\":\"quickfix\",\"command\":{\"title\":\"Verify SMT Consistency\",\"command\":\"ontologic.solve\",\"arguments\":[\"" ++ escapeJson uri ++ "\"]}}"
                    , "{\"title\":\"Explain SMT Unsatisfiable Core\",\"kind\":\"quickfix\",\"command\":{\"title\":\"Explain UNSAT\",\"command\":\"ontologic.explainUnsat\",\"arguments\":[\"" ++ escapeJson uri ++ "\"]}}"
                    , "{\"title\":\"Inspect SMT Satisfying Model\",\"kind\":\"quickfix\",\"command\":{\"title\":\"Inspect Model\",\"command\":\"ontologic.inspectModel\",\"arguments\":[\"" ++ escapeJson uri ++ "\"]}}"
                    ]
                resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":[" ++ intercalateComma actions ++ "]}"
            in (state, Just resp, [])

        "workspace/executeCommand" ->
            let cmd = extractJsonString "command" rawJson
                resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"status\":\"executed\",\"command\":\"" ++ escapeJson cmd ++ "\"}}"
            in (state, Just resp, [])

        "shutdown" ->
            (state, Just ("{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":null}"), [])

        -- A notification has no id and must not be answered; a request must get a reply,
        -- and silence makes a client wait forever.
        _ | reqId == "null" -> (state, Nothing, [])
          | otherwise ->
            (state, Just ("{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++
                          ",\"error\":{\"code\":-32601,\"message\":\"Method not found: " ++
                          escapeJson method ++ "\"}}"), [])

updateDoc :: LSPState -> String -> String -> (LSPState, String)
updateDoc = updateDocWith emptyRegistry []

-- | Lint the document together with whatever its imports brought in, so a concept
--   defined in an imported file is not reported as undeclared. Problems that belong to
--   the imported files themselves are filtered out: they are not this document's fault.
updateDocWith :: Registry -> [String] -> LSPState -> String -> String -> (LSPState, String)
updateDocWith impReg impErrs state uri content =
    case parse parseRegistryWithSource uri (T.pack content) of
        Left bundle ->
            let (l, c) = parseErrorPosition bundle
                diag = mkDiag l c "ontologic-parser" (errorBundlePretty bundle)
            in ( state { lspDocs = Map.insert uri content (lspDocs state) }
               , publishDiagnostics uri [diag] )
        Right (reg, sourceTbl) ->
            let merged = deduplicateRegistry (reg <> impReg)
                inherited = map lintMessage (lintRegistryFindings impReg)
                own = filter ((`notElem` inherited) . lintMessage) (lintRegistryFindingsWithSource sourceTbl merged)
                place f = case lintPos f of
                    Just pos -> (posLine pos - 1, posCol pos - 1)
                    Nothing  -> case lintSymbol f >>= symbolPosition content of
                        Just (l, c) -> (l, c)
                        Nothing     -> (0, 0)
                diags = [ mkDiag (importLine content e) 0 "ontologic-imports" e | e <- impErrs ] ++
                        [ let (l, c) = place f in mkDiag l c "ontologic-linter" (lintMessage f) | f <- own ]
                newState = state
                    { lspDocs = Map.insert uri content (lspDocs state)
                    , lspRegistries = Map.insert uri merged (lspRegistries state)
                    }
            in (newState, publishDiagnostics uri diags)

mkDiag :: Int -> Int -> String -> String -> String
mkDiag line char source msg =
    "{\"range\":{\"start\":{\"line\":" ++ show line ++ ",\"character\":" ++ show char ++
    "},\"end\":{\"line\":" ++ show line ++ ",\"character\":100}},\"severity\":1,\"source\":\"" ++ source ++
    "\",\"message\":\"" ++ escapeJson msg ++ "\"}"

publishDiagnostics :: String -> [String] -> String
publishDiagnostics uri diags =
    "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/publishDiagnostics\",\"params\":{\"uri\":\"" ++
    escapeJson uri ++ "\",\"diagnostics\":[" ++ intercalateComma diags ++ "]}}"

-- | Line and column of the first parse error, zero-based for LSP.
parseErrorPosition :: ParseErrorBundle T.Text Void -> (Int, Int)
parseErrorPosition bundle =
    let err = NE.head (bundleErrors bundle)
        (_, pst) = reachOffset (errorOffset err) (bundlePosState bundle)
        pos = pstateSourcePos pst
    in (unPos (sourceLine pos) - 1, unPos (sourceColumn pos) - 1)

-- | Line and column of a symbol: its def-* declaration if present, else its first
--   whole-token occurrence. Nothing when the symbol does not appear in this document
--   (it came from an import), and the caller then falls back to (0, 0).
symbolPosition :: String -> Name -> Maybe (Int, Int)
symbolPosition content sym =
    case [ (i, col) | (i, l) <- numbered, definesWord sym l, Just col <- [tokenColumn sym l] ] of
        ((i, c):_) -> Just (i, c)
        [] -> case [ (i, c) | (i, l) <- numbered, Just c <- [tokenColumn sym l] ] of
            ((i, c):_) -> Just (i, c)
            []         -> Nothing
  where
    numbered = zip [0 ..] (lines content)

-- | Column of sym in the line, when it appears as a whole identifier.
tokenColumn :: Name -> String -> Maybe Int
tokenColumn sym l = go 0 l
  where
    go _ [] = Nothing
    go i rest
        | sym `isPrefixOf` rest && boundaryBefore i && boundaryAfter (drop (length sym) rest) = Just i
        | otherwise = go (i + 1) (tail rest)
    boundaryBefore 0 = True
    boundaryBefore i = not (isIdent (l !! (i - 1)))
    boundaryAfter [] = True
    boundaryAfter (c:_) = not (isIdent c)
    isIdent c = isAlphaNum c || c `elem` ("_:-" :: String)

-- | The line of the failing (import "...") form; the message ends with the path.
importLine :: String -> String -> Int
importLine content msg =
    let path = reverse (takeWhile (/= ' ') (reverse msg))
    in case [ i | (i, l) <- zip [0 ..] (lines content), "(import" `isInfixOf` l, path `isInfixOf` l ] of
        (i:_) -> i
        []    -> 0

-- | file:///a/b.logic -> /a/b.logic, with %XX decoded.
uriToPath :: String -> Maybe FilePath
uriToPath uri
    | "file://" `isPrefixOf` uri = Just (decode (drop 7 uri))
    | otherwise = Nothing
  where
    decode ('%':a:b:cs) | all isHexDigit [a, b] = chr (read ("0x" ++ [a, b])) : decode cs
    decode (c:cs) = c : decode cs
    decode [] = []

-- | Registry of everything the document imports, the files used, and any unresolved imports.
loadDocumentImports :: FilePath -> Registry -> IO (Registry, [FilePath], [String])
loadDocumentImports docPath reg = do
    libs <- stdlibSearchPaths
    let dirs = takeDirectory docPath : libs
    results <- mapM (loadImportFrom dirs . importPath) (imports reg)
    return ( mconcat [ r | Right (_, r) <- results ]
           , [ f | Right (f, _) <- results ]
           , [ e | Left e <- results ] )

-- | Server-side entry point: handles the requests that need the filesystem and
--   delegates the rest to the pure handler.
handleLSPRequestIO :: LSPState -> String -> IO (LSPState, Maybe String, [String])
handleLSPRequestIO state raw
    | method `elem` ["textDocument/didOpen", "textDocument/didChange"] =
        let docText = if method == "textDocument/didChange"
                      then extractNewDocumentText raw (Map.findWithDefault "" uri (lspDocs state))
                      else text
        in case (uriToPath uri, parse parseRegistry uri (T.pack docText)) of
            (Just p, Right reg) -> do
                (impReg, impFiles, impErrs) <- loadDocumentImports p reg
                let (st, notif) = updateDocWith impReg impErrs state uri docText
                return (st { lspImportFiles = Map.insert uri impFiles (lspImportFiles st) }, Nothing, [notif])
            _ -> return (handleLSPRequest state raw)
    | method == "textDocument/definition" = do
        let content = Map.findWithDefault "" uri (lspDocs state)
            word = getWordAtPosition content (extractJsonInt "line" raw) (extractJsonInt "character" raw)
        loc <- case findDefinitionLine word (lines content) 0 uri of
            Just l  -> return (Just l)
            Nothing -> searchImports word (Map.findWithDefault [] uri (lspImportFiles state))
        return (state, Just (definitionResponse (extractJsonId raw) loc), [])
    | method `elem` ["textDocument/semanticTokens/full", "textDocument/rename", "textDocument/prepareRename", "textDocument/formatting", "textDocument/hover"] = do
        case Map.lookup uri (lspDocs state) of
            Just _ -> return (handleLSPRequest state raw)
            Nothing -> case uriToPath uri of
                Just p -> do
                    exists <- doesFileExist p
                    if exists
                        then do
                            content <- readFile p
                            let (st, _) = updateDoc state uri content
                            return (handleLSPRequest st raw)
                        else return (handleLSPRequest state raw)
                Nothing -> return (handleLSPRequest state raw)
    | method == "workspace/executeCommand" = do
        let cmd = extractJsonString "command" raw
            reqId = extractJsonId raw
            targetUri = case extractJsonFirstArgString raw of
                "" -> case extractJsonString "uri" raw of
                    "" -> case Map.keys (lspRegistries state) of
                        (u:_) -> u
                        []    -> ""
                    u  -> u
                u  -> u
            reg = Map.findWithDefault emptyRegistry targetUri (lspRegistries state)
        case cmd of
            "ontologic.solve" -> do
                res <- checkConsistencyWith AutoProver reg
                let (status, details) = case res of
                        Sat _        -> ("sat", "Satisfiable (SAT): Consistent Model Found")
                        Unsat        -> ("unsat", "Unsatisfiable (UNSAT): Logical Contradiction Detected")
                        Unknown u    -> ("unknown", u)
                        SolverError e-> ("error", e)
                    resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"status\":\"" ++ status ++ "\",\"details\":\"" ++ escapeJson details ++ "\"}}"
                return (state, Just resp, [])
            "ontologic.explainUnsat" -> do
                res <- explainUnsatWith AutoProver reg
                let (status, coreStr, details) = case res of
                        Left err -> ("error", "[]", err)
                        Right exp1 -> ("unsat", "[" ++ intercalateComma (map (\n -> "\"" ++ escapeJson n ++ "\"") (unsatCoreNames exp1)) ++ "]", unlines (unsatCoreDetails exp1))
                    resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"status\":\"" ++ status ++ "\",\"core\":" ++ coreStr ++ ",\"details\":\"" ++ escapeJson details ++ "\"}}"
                return (state, Just resp, [])
            "ontologic.inspectModel" -> do
                res <- checkConsistencyWith AutoProver reg
                let (status, modelStr) = case res of
                        Sat m        -> ("sat", maybe m id (extractModel res))
                        Unsat        -> ("unsat", "No satisfying model (UNSAT)")
                        Unknown u    -> ("unknown", u)
                        SolverError e-> ("error", e)
                    resp = "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"status\":\"" ++ status ++ "\",\"model\":\"" ++ escapeJson modelStr ++ "\"}}"
                return (state, Just resp, [])
            _ -> return (handleLSPRequest state raw)
    | otherwise = return (handleLSPRequest state raw)
  where
    method = extractJsonString "method" raw
    uri = extractJsonUri raw
    text = extractJsonString "text" raw
    searchImports _ [] = return Nothing
    searchImports word (f:fs) = do
        content <- readFile f
        case findDefinitionLine word (lines content) 0 ("file://" ++ f) of
            Just l  -> return (Just l)
            Nothing -> searchImports word fs

getCompletions :: Registry -> String
getCompletions reg =
    let keywords = ["def-concept", "def-property", "def-relation", "forall", "exists", "implies", "iff", "and", "or", "not", "import", "namespace"]
        types = ["Integer", "Float", "Double", "String", "Boolean"]
        conceptNames = map fst (concepts reg)
        propNames = map propName (properties reg)
        relNames = map relName (relations reg)
        
        kwItems = map (\k -> "{\"label\":\"" ++ k ++ "\",\"kind\":14,\"detail\":\"DSL Keyword\"}") keywords
        typeItems = map (\t -> "{\"label\":\"" ++ t ++ "\",\"kind\":7,\"detail\":\"Property Type\"}") types
        conceptItems = map (\c -> "{\"label\":\"" ++ c ++ "\",\"kind\":7,\"detail\":\"Concept Class\"}") conceptNames
        propItems = map (\p -> "{\"label\":\"" ++ p ++ "\",\"kind\":10,\"detail\":\"Property\"}") propNames
        relItems = map (\r -> "{\"label\":\"" ++ r ++ "\",\"kind\":6,\"detail\":\"Binary Relation\"}") relNames
    in intercalateComma (kwItems ++ typeItems ++ conceptItems ++ propItems ++ relItems)

getHoverInfo :: String -> Int -> Int -> Registry -> Maybe String
getHoverInfo content line char reg =
    let word = getWordAtPosition content line char
        modelIR = compileRegistry reg
        classes = irClasses modelIR
    in case filter (\c -> compClassName c == word) classes of
        (cls:_) ->
            let parentStr = case compParentClass cls of
                    Just p  -> "\n- **Subclass of:** `" ++ p ++ "`"
                    Nothing -> ""
                props = compProperties cls
                propLines = if null props then "" else "\n- **Properties:**\n" ++ unlines (map formatPropHover props)
                docLines = getDocCommentBefore content ("def-concept " ++ word)
                docStr = if null docLines then "" else "\n\n" ++ docLines
            in Just $ "### Concept `" ++ compClassName cls ++ "`" ++ parentStr ++ propLines ++ docStr
        [] -> case filter (\p -> propName p == word) (properties reg) of
            (p:_) ->
                let cardStr = case propCardinality p of
                        CardDefault -> ""
                        c -> "\n- **Cardinality:** `" ++ cardinalityToString c ++ "`"
                    defStr = case propDefault p of
                        Nothing -> ""
                        Just d  -> "\n- **Default:** `" ++ d ++ "`"
                    docLines = getDocCommentBefore content ("def-property " ++ word)
                    docStr = if null docLines then "" else "\n\n" ++ docLines
                in Just $ "### Property `" ++ propName p ++ "`\n- **Domain:** `" ++ domain p ++ "`\n- **Type:** `" ++ show (rangeType p) ++ "`" ++ cardStr ++ defStr ++ docStr
            [] -> case filter (\r -> relName r == word) (relations reg) of
                (r:_) ->
                    let cardStr = case relCardinality r of
                            CardDefault -> ""
                            c -> "\n- **Cardinality:** `" ++ cardinalityToString c ++ "`"
                        sigStr = if length (relSignature r) > 2
                                 then "\n- **Signature:** `" ++ unwords (relSignature r) ++ "`"
                                 else ""
                        docLines = getDocCommentBefore content ("def-relation " ++ word)
                        docStr = if null docLines then "" else "\n\n" ++ docLines
                    in Just $ "### Relation `" ++ relName r ++ "`\n- **Domain:** `" ++ relDomain r ++ "`\n- **Range:** `" ++ relRange r ++ "`" ++ cardStr ++ sigStr ++ docStr
                [] -> getKeywordHover word

getDocCommentBefore :: String -> String -> String
getDocCommentBefore content defPattern =
    let allLines = lines content
    in case [ idx | (idx, l) <- zip [0..] allLines, defPattern `isInfixOf` l ] of
        (defIdx:_) ->
            let preceding = take defIdx allLines
                commentLines = reverse (takeWhile isComment (reverse preceding))
                cleanLines = filter (not . isDividerLine) (map cleanComment commentLines)
            in unlines (filter (not . null) cleanLines)
        [] -> ""
  where
    isComment l = let t = dropWhile isSpace l in ";" `isPrefixOf` t
    cleanComment l =
        let t = dropWhile isSpace l
            noSemicolons = dropWhile (\c -> c == ';' || c == ' ') t
        in dropWhile (== '|') (dropWhile isSpace noSemicolons)

isDividerLine :: String -> Bool
isDividerLine s =
    let t = dropWhile (\c -> c == ';' || c == ' ' || c == '-') s
    in not (null t) && all (`elem` ("=-_*~#" :: String)) t

getKeywordHover :: String -> Maybe String
getKeywordHover "def-concept" = Just "### Keyword `def-concept`\nDeclares an ontological concept (class) in the taxonomy, optionally inheriting from a parent concept.\n\n**Syntax:** `(def-concept <Name> [<Parent>])`"
getKeywordHover "def-property" = Just "### Keyword `def-property`\nDeclares a strongly typed datatype property associated with a domain concept.\n\n**Syntax:** `(def-property <name> <Domain> <Type> [:cardinality <card>] [:default <val>])`"
getKeywordHover "def-relation" = Just "### Keyword `def-relation`\nDeclares an object property or n-ary relation between domain and range concepts.\n\n**Syntax:** `(def-relation <name> <Domain> <Range> ... [:cardinality <card>])`"
getKeywordHover "def-axiom" = Just "### Keyword `def-axiom`\nDeclares a first-order logic axiom or semantic rule, with an optional description string.\n\n**Syntax:** `(def-axiom [\"description\"] <FOL-formula>)`"
getKeywordHover "forall" = Just "### Keyword `forall`\nUniversal quantifier ($\\forall x$). Asserts that the enclosed formula holds for all individuals in the domain.\n\n**Syntax:** `(forall (x) ...)` or `(forall ((x Type)) ...)`"
getKeywordHover "exists" = Just "### Keyword `exists`\nExistential quantifier ($\\exists x$). Asserts that there exists at least one individual satisfying the enclosed formula.\n\n**Syntax:** `(exists (x) ...)` or `(exists ((x Type)) ...)`"
getKeywordHover "implies" = Just "### Keyword `implies`\nMaterial implication ($A \\implies B$). Asserts that if premise $A$ holds, conclusion $B$ must hold."
getKeywordHover "iff" = Just "### Keyword `iff`\nLogical biconditional equivalence ($A \\iff B$). True when both $A$ and $B$ have the same truth value."
getKeywordHover "and" = Just "### Keyword `and`\nLogical conjunction ($A \\land B$). True when all conjoined formulas hold."
getKeywordHover "or" = Just "### Keyword `or`\nLogical disjunction ($A \\lor B$). True when at least one disjoined formula holds."
getKeywordHover "not" = Just "### Keyword `not`\nLogical negation ($\\neg A$). Inverts the truth value of the enclosed formula."
getKeywordHover "import" = Just "### Keyword `import`\nImports ontology declarations from an external `.logic` file.\n\n**Syntax:** `(import \"<path>\")`"
getKeywordHover "namespace" = Just "### Keyword `namespace`\nDeclares a namespace prefix and optional IRI base URI for modular ontologies.\n\n**Syntax:** `(namespace <prefix> [\"<uri>\"])`"
getKeywordHover "top" = Just "### Keyword `top`\nLogical truth constant ($\\top$ / True)."
getKeywordHover "bottom" = Just "### Keyword `bottom`\nLogical absurdity or contradiction ($\\bot$ / False)."
getKeywordHover "eq" = Just "### Operator `eq`\nEquality comparison ($x = y$)."
getKeywordHover "ne" = Just "### Operator `ne`\nInequality comparison ($x \\neq y$)."
getKeywordHover "gt" = Just "### Operator `gt`\nStrict greater-than inequality ($x > y$)."
getKeywordHover "gte" = Just "### Operator `gte`\nGreater-than or equal inequality ($x \\ge y$)."
getKeywordHover "lt" = Just "### Operator `lt`\nStrict less-than inequality ($x < y$)."
getKeywordHover "lte" = Just "### Operator `lte`\nLess-than or equal inequality ($x \\le y$)."
getKeywordHover "Integer" = Just "### Type `Integer`\nSigned integral number (e.g. `42`, `-10`)."
getKeywordHover "Float" = Just "### Type `Float`\nSingle-precision floating-point number (e.g. `3.14`)."
getKeywordHover "Double" = Just "### Type `Double`\nIEEE-754 double-precision floating-point number."
getKeywordHover "String" = Just "### Type `String`\nUTF-8 textual string literal (e.g. `\"abc\"`)."
getKeywordHover "Boolean" = Just "### Type `Boolean`\nTruth value: `True` or `False`."
getKeywordHover _ = Nothing

formatPropHover :: CompiledProperty -> String
formatPropHover p =
    let constraintsStr = case compConstraints p of
            [] -> ""
            cs -> " [" ++ unwords (map formatBound cs) ++ "]"
        cardStr = case compCardinality p of
            CardDefault -> ""
            c -> " (" ++ cardinalityToString c ++ ")"
        defStr = case compDefaultValue p of
            Nothing -> ""
            Just d  -> " = " ++ d
    in "  - `" ++ compPropName p ++ "`: `" ++ show (compPropType p) ++ "`" ++ cardStr ++ constraintsStr ++ defStr

formatBound :: BoundConstraint -> String
formatBound (BoundConstraint op val) = show op ++ " " ++ valueToString val

getDefinitionLocation :: String -> Int -> Int -> String -> Maybe (String, Int, Int)
getDefinitionLocation content line char uri =
    let word = getWordAtPosition content line char
        linesList = lines content
    in if null word
       then Nothing
       else findDefinitionLine word linesList 0 uri

findDefinitionLine :: String -> [String] -> Int -> String -> Maybe (String, Int, Int)
findDefinitionLine _ [] _ _ = Nothing
findDefinitionLine word (l:ls) lineIdx uri
    | definesWord word l = Just (uri, lineIdx, 0)
    | otherwise = findDefinitionLine word ls (lineIdx + 1) uri

-- | True when the line is a def-* form whose declared name is exactly word. Substring
--   matching sent "Tank" to the definition of "TankTruck".
definesWord :: String -> String -> Bool
definesWord word l =
    case words (map (\c -> if c `elem` ("()" :: String) then ' ' else c) l) of
        (kw:name:_) -> kw `elem` ["def-concept", "def-property", "def-relation"] && name == word
        _ -> False

definitionResponse :: String -> Maybe (String, Int, Int) -> String
definitionResponse reqId loc = case loc of
    Just (targetUri, targetLine, targetChar) ->
        "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":{\"uri\":\"" ++ escapeJson targetUri ++
        "\",\"range\":{\"start\":{\"line\":" ++ show targetLine ++ ",\"character\":" ++ show targetChar ++
        "},\"end\":{\"line\":" ++ show targetLine ++ ",\"character\":" ++ show (targetChar + 10) ++ "}}}}"
    Nothing -> "{\"jsonrpc\":\"2.0\",\"id\":" ++ formatId reqId ++ ",\"result\":null}"

getWordAtPosition :: String -> Int -> Int -> String
getWordAtPosition content lineIdx charIdx =
    let allLines = lines content
    in if lineIdx < 0 || lineIdx >= length allLines
       then ""
       else let lineStr = allLines !! lineIdx
                (before, after) = splitAt charIdx lineStr
                wBefore = reverse (takeWhile isIdentChar (reverse before))
                wAfter = takeWhile isIdentChar after
            in wBefore ++ wAfter

-- Helpers for minimal JSON parsing / formatting without heavy dependencies
extractJsonString :: String -> String -> String
extractJsonString key json = case afterKey key json of
    Just ('"':r) -> unescapeJson (extractUntilUnescapedQuote r)
    _            -> ""

-- | The text after "key" : , skipping whitespace on both sides of the colon. The old
--   helpers matched the literal "\"key\":\"" and so missed any pretty-printed JSON.
afterKey :: String -> String -> Maybe String
afterKey key json = go json
  where
    pat = "\"" ++ key ++ "\""
    go s = case findSubstring pat s of
        Nothing -> Nothing
        Just idx ->
            let afterPat = drop (idx + length pat) s
            in case dropWhile isSpace afterPat of
                (':':r) -> Just (dropWhile isSpace r)
                _       -> go afterPat

extractJsonId :: String -> String
extractJsonId json = case afterKey "id" json of
    Just ('"':r) -> "\"" ++ extractUntilUnescapedQuote r ++ "\""
    Just rest@(_:_)
        | "null" `isPrefixOf` rest -> "null"
        | otherwise -> let numStr = takeWhile (`elem` ("0123456789-" :: String)) rest
                       in if null numStr then "null" else numStr
    _ -> "null"

extractJsonInt :: String -> String -> Int
extractJsonInt key json = case afterKey key json of
    Just rest -> case reads (takeWhile (`elem` ("0123456789-" :: String)) rest) of
        [(n, _)] -> n
        _        -> 0
    Nothing -> 0

extractJsonFirstArgString :: String -> String
extractJsonFirstArgString json = case afterKey "arguments" json of
    Just rest ->
        let afterBracket = dropWhile isSpace (dropWhile (/= '[') rest)
        in case afterBracket of
            ('[':r) -> case dropWhile isSpace r of
                ('"':s) -> unescapeJson (extractUntilUnescapedQuote s)
                _       -> ""
            _       -> ""
    Nothing -> ""

extractUntilUnescapedQuote :: String -> String
extractUntilUnescapedQuote [] = []
extractUntilUnescapedQuote ('\\':c:cs) = '\\' : c : extractUntilUnescapedQuote cs
extractUntilUnescapedQuote ('"':_) = []
extractUntilUnescapedQuote (c:cs) = c : extractUntilUnescapedQuote cs

unescapeJson :: String -> String
unescapeJson [] = []
unescapeJson ('\\':'n':cs)  = '\n' : unescapeJson cs
unescapeJson ('\\':'r':cs)  = '\r' : unescapeJson cs
unescapeJson ('\\':'t':cs)  = '\t' : unescapeJson cs
unescapeJson ('\\':'"':cs)  = '"'  : unescapeJson cs
unescapeJson ('\\':'\\':cs) = '\\' : unescapeJson cs
unescapeJson ('\\':'u':a:b:c:d:cs)
    | all isHexDigit [a, b, c, d] = chr (read ("0x" ++ [a, b, c, d])) : unescapeJson cs
unescapeJson (c:cs)         = c    : unescapeJson cs

findSubstring :: String -> String -> Maybe Int
findSubstring pat str = go 0 str
  where
    go _ [] = Nothing
    go idx s@(_:cs)
        | pat `isPrefixOf` s = Just idx
        | otherwise          = go (idx + 1) cs

formatId :: String -> String
formatId "" = "null"
formatId s  = s

escapeJson :: String -> String
escapeJson [] = []
escapeJson ('\\':cs) = "\\\\" ++ escapeJson cs
escapeJson ('"':cs)  = "\\\"" ++ escapeJson cs
escapeJson ('\n':cs) = "\\n" ++ escapeJson cs
escapeJson ('\r':cs) = "\\r" ++ escapeJson cs
escapeJson ('\t':cs) = "\\t" ++ escapeJson cs
escapeJson (c:cs)    = c : escapeJson cs

intercalateComma :: [String] -> String
intercalateComma [] = ""
intercalateComma [x] = x
intercalateComma (x:xs) = x ++ "," ++ intercalateComma xs

-- | Check if an LSP workspace command should run asynchronously in a worker thread.
isAsyncCommand :: String -> Bool
isAsyncCommand cmd = cmd `elem` ["ontologic.solve", "ontologic.explainUnsat", "ontologic.inspectModel"]

-- | Extract document URI from top-level "uri" or nested "textDocument.uri".
extractJsonUri :: String -> String
extractJsonUri raw =
    case extractJsonString "uri" raw of
        "" -> case afterKey "textDocument" raw of
            Just td -> extractJsonString "uri" td
            Nothing -> ""
        u  -> u

-- | Compute character offset from 0-based (line, char) coordinates in a string.
posToOffset :: Int -> Int -> String -> Int
posToOffset targetLine targetChar s = go 0 0 0 s
  where
    targetL = max 0 targetLine
    targetC = max 0 targetChar
    go _ _ off [] = off
    go curL curC off (c:cs)
        | curL == targetL && curC >= targetC = off
        | curL == targetL && c == '\n'       = off
        | c == '\n' = go (curL + 1) 0 (off + 1) cs
        | otherwise = go curL (curC + 1) (off + 1) cs

-- | Apply an incremental range replacement to an existing document buffer.
applyRangeChange :: Int -> Int -> Int -> Int -> String -> String -> String
applyRangeChange sL sC eL eC repl original =
    let sOff = posToOffset sL sC original
        eOff = posToOffset eL eC original
        prefix = take sOff original
        suffix = drop eOff original
    in prefix ++ repl ++ suffix

-- | Extract 0-based start and end line/col coordinates from a JSON "range" object.
extractJsonRange :: String -> Maybe ((Int, Int), (Int, Int))
extractJsonRange json = case afterKey "range" json of
    Nothing -> Nothing
    Just r ->
        let sLine = extractJsonInt "line" r
            sChar = extractJsonInt "character" r
            afterEnd = case findSubstring "\"end\"" r of
                Just idx -> drop idx r
                Nothing  -> ""
            eLine = extractJsonInt "line" afterEnd
            eChar = extractJsonInt "character" afterEnd
        in Just ((sLine, sChar), (eLine, eChar))

-- | Extract full text or compute incremental buffer update from textDocument/didChange payload.
extractNewDocumentText :: String -> String -> String
extractNewDocumentText rawJson oldDoc =
    case extractJsonRange rawJson of
        Just ((sL, sC), (eL, eC)) ->
            let replText = extractJsonString "text" rawJson
            in applyRangeChange sL sC eL eC replText oldDoc
        Nothing ->
            extractJsonString "text" rawJson

-- | Check if character is part of an identifier in OntoLogic DSL.
isIdentChar :: Char -> Bool
isIdentChar c = isAlphaNum c || c `elem` ("_:-" :: String)

-- | Validate whether a word is a DSL keyword or primitive.
isKeyword :: String -> Bool
isKeyword w = w `elem`
    [ "def-concept", "def-property", "def-relation", "def-axiom"
    , "forall", "exists", "implies", "iff", "and", "or", "not"
    , "import", "namespace", "true", "false", "top", "bottom"
    , "eq", "ne", "gt", "gte", "lt", "lte", "=", "!=", ">", ">=", "<", "<="
    , ":cardinality", ":optional", ":default"
    , "Integer", "Float", "Double", "String", "Boolean"
    ]

-- | Validate candidate identifier name for rename operations.
isValidSymbolName :: String -> Bool
isValidSymbolName [] = False
isValidSymbolName (c:cs) =
    not (isDigit c) &&
    not (c `elem` (":-" :: String)) &&
    all isIdentChar (c:cs) &&
    not (isKeyword (c:cs))

-- | Determine if a symbol in a document is a declared entity eligible for rename.
isRenameableSymbol :: Registry -> String -> String -> Bool
isRenameableSymbol reg content sym =
    sym `elem` map fst (concepts reg) ||
    sym `elem` map propName (properties reg) ||
    sym `elem` map relName (relations reg) ||
    any (definesWord sym) (lines content)

-- | Character range (startChar, endChar) of the word under cursor.
getWordCharRange :: String -> Int -> Int -> String -> (Int, Int)
getWordCharRange content lineIdx charIdx word =
    let allLines = lines content
    in if lineIdx < 0 || lineIdx >= length allLines
       then (charIdx, charIdx + length word)
       else let lineStr = allLines !! lineIdx
                (before, _) = splitAt charIdx lineStr
                wBeforeLen = length (takeWhile isIdentChar (reverse before))
                startChar = max 0 (charIdx - wBeforeLen)
            in (startChar, startChar + length word)

-- | Find all occurrences of a symbol as a whole token across a document.
findSymbolOccurrences :: String -> String -> [(Int, Int, Int)]
findSymbolOccurrences content sym =
    [ (lIdx, c, length sym)
    | (lIdx, lineStr) <- zip [0..] (lines content)
    , c <- tokenOccurrencesInLine sym lineStr
    ]

-- | Find column positions of whole-token occurrences on a single line, ignoring comments and strings.
tokenOccurrencesInLine :: String -> String -> [Int]
tokenOccurrencesInLine sym lineStr = go 0 False lineStr
  where
    symLen = length sym
    go _ _ [] = []
    go _ False (';':_) = []
    go col inStr ('\\':_:cs) = go (col + 2) inStr cs
    go col inStr ('\\':[])   = go (col + 1) inStr []
    go col inStr ('"':cs)    = go (col + 1) (not inStr) cs
    go col True (_:cs)       = go (col + 1) True cs
    go col False rest
        | sym `isPrefixOf` rest && boundaryBefore col && boundaryAfter (drop symLen rest) =
            col : go (col + symLen) False (drop symLen rest)
        | otherwise =
            go (col + 1) False (tail rest)

    boundaryBefore 0 = True
    boundaryBefore c = not (isIdentChar (lineStr !! (c - 1)))

    boundaryAfter [] = True
    boundaryAfter (c:_) = not (isIdentChar c)

-- | Compute LSP TextEdit JSON objects to rename all occurrences of a symbol.
computeRenameEdits :: String -> String -> String -> String -> [String]
computeRenameEdits _uri content oldName newName =
    let occurrences = findSymbolOccurrences content oldName
    in map formatEdit occurrences
  where
    formatEdit (l, c, len) =
        "{\"range\":{\"start\":{\"line\":" ++ show l ++ ",\"character\":" ++ show c ++
        "},\"end\":{\"line\":" ++ show l ++ ",\"character\":" ++ show (c + len) ++
        "}},\"newText\":\"" ++ escapeJson newName ++ "\"}"

-- | Extract tab size formatting option with fallback to 2.
extractTabSize :: String -> Int
extractTabSize json =
    case afterKey "options" json of
        Just opts ->
            let ts = extractJsonInt "tabSize" opts
            in if ts <= 0 then 2 else ts
        Nothing ->
            let ts = extractJsonInt "tabSize" json
            in if ts <= 0 then 2 else ts

-- | JSON serialization of LSP Semantic Tokens Legend.
semanticLegendJson :: String
semanticLegendJson =
    "{\"tokenTypes\":[\"keyword\",\"type\",\"class\",\"property\",\"function\",\"variable\",\"string\",\"number\",\"comment\",\"operator\"],\"tokenModifiers\":[]}"

-- | Compute full delta-encoded semantic tokens array for a document.
computeSemanticTokens :: String -> Registry -> [Int]
computeSemanticTokens content reg =
    let rawTokens = concat [ tokenizeLine lIdx l reg | (lIdx, l) <- zip [0..] (lines content) ]
    in encodeSemanticTokens rawTokens

-- | Encode sorted (line, col, len, typeIdx, modMask) tokens into relative delta integers.
encodeSemanticTokens :: [(Int, Int, Int, Int, Int)] -> [Int]
encodeSemanticTokens tokens = go 0 0 tokens
  where
    go _ _ [] = []
    go prevLine prevChar ((l, c, len, tType, tMod) : rest) =
        let deltaLine = l - prevLine
            deltaChar = if deltaLine == 0 then c - prevChar else c
        in deltaLine : deltaChar : len : tType : tMod : go l c rest

-- | Tokenize a single line of OntoLogic source code for semantic highlighting.
tokenizeLine :: Int -> String -> Registry -> [(Int, Int, Int, Int, Int)]
tokenizeLine lIdx lineStr reg = scan "" (zip [0..] lineStr)
  where
    knownConcepts = map fst (concepts reg)
    knownProps = map propName (properties reg)
    knownRels = map relName (relations reg)

    scan _ [] = []
    scan prevW chars@((cIdx, c):cs)
        | isSpace c = scan prevW cs
        | c == ';' =
            [(lIdx, cIdx, length chars, 8, 0)]
        | c == '"' =
            let (litChars, rest) = spanStringLit cs
                strLen = 1 + length litChars
            in (lIdx, cIdx, strLen, 6, 0) : scan prevW rest
        | c == '(' || c == ')' =
            scan prevW cs
        | isDigit c || (c == '-' && case cs of { ((_, d):_) -> isDigit d; [] -> False }) =
            let (numChars, rest) = spanNum chars
                numLen = length numChars
            in (lIdx, cIdx, numLen, 7, 0) : scan prevW rest
        | isIdentChar c =
            let (identChars, rest) = spanIdent chars
                w = map snd identChars
                wLen = length w
                tType = classifyToken w prevW
            in (lIdx, cIdx, wLen, tType, 0) : scan w rest
        | otherwise =
            scan prevW cs

    spanStringLit [] = ([], [])
    spanStringLit (ch1@(_, '\\') : ch2 : rest) =
        let (lit, remChars) = spanStringLit rest
        in (ch1 : ch2 : lit, remChars)
    spanStringLit (ch1@(_, '\\') : []) =
        ([ch1], [])
    spanStringLit (ch@(_, '"') : rest) =
        ([ch], rest)
    spanStringLit (ch : rest) =
        let (lit, remChars) = spanStringLit rest
        in (ch : lit, remChars)

    spanNum [] = ([], [])
    spanNum (ch@(_, x) : rest)
        | isDigit x || x `elem` (".-" :: String) =
            let (num, remChars) = spanNum rest
            in (ch : num, remChars)
        | otherwise = ([], ch : rest)

    spanIdent [] = ([], [])
    spanIdent (ch@(_, x) : rest)
        | isIdentChar x =
            let (ident, remChars) = spanIdent rest
            in (ch : ident, remChars)
        | otherwise = ([], ch : rest)

    classifyToken w prevW
        | w `elem` dslKeywords = 0  -- keyword
        | w `elem` dslTypes = 1     -- type
        | w `elem` dslOperators = 9 -- operator
        | w `elem` knownConcepts = 2 -- class
        | w `elem` knownProps = 3    -- property
        | w `elem` knownRels = 4     -- function
        | prevW == "def-concept" = 2 -- class
        | prevW == "def-property" = 3 -- property
        | prevW == "def-relation" = 4 -- function
        | prevW `elem` ["forall", "exists"] = 5 -- variable
        | not (null w) && isUpper (head w) = 2  -- class
        | otherwise = 5              -- variable

    dslKeywords =
        [ "def-concept", "def-property", "def-relation", "def-axiom"
        , "forall", "exists", "implies", "iff", "and", "or", "not"
        , "import", "namespace", "true", "false", "top", "bottom"
        , ":cardinality", ":optional", ":default"
        ]
    dslTypes = ["Integer", "Float", "Double", "String", "Boolean"]
    dslOperators = ["eq", "ne", "gt", "gte", "lt", "lte", "=", "!=", ">", ">=", "<", "<="]

-- | Code formatting for OntoLogic s-expressions with consistent indentation.
formatLogicDocument :: String -> Int -> String
formatLogicDocument content tabSize =
    let rawLines = lines content
        processed = formatLines tabSize 0 rawLines
        compressed = compressBlankLines processed
    in unlines compressed

compressBlankLines :: [String] -> [String]
compressBlankLines [] = []
compressBlankLines (l:ls)
    | null (dropWhile isSpace l) =
        "" : compressBlankLines (dropWhile (null . dropWhile isSpace) ls)
    | otherwise = l : compressBlankLines ls

formatLines :: Int -> Int -> [String] -> [String]
formatLines _ _ [] = []
formatLines tabSize depth (l:ls) =
    let trimmed = dropWhile isSpace l
    in if null trimmed
       then "" : formatLines tabSize depth ls
       else if isCommentLine trimmed
       then let commentIndent = if isHeaderComment trimmed then 0 else depth * tabSize
                formattedComment = replicate commentIndent ' ' ++ trimmed
            in formattedComment : formatLines tabSize depth ls
       else
           let (codePart, commentPart) = splitLineComment trimmed
               leadingClose = countLeadingClosingParens (dropWhile isSpace codePart)
               lineDepth = max 0 (depth - leadingClose)
               lineIndent = lineDepth * tabSize
               codeNorm = normalizeCodeTokens (trimRight codePart)
               lineContent = if null commentPart
                             then codeNorm
                             else if null codeNorm
                             then commentPart
                             else codeNorm ++ " " ++ commentPart
               fullLine = replicate lineIndent ' ' ++ lineContent
               netParens = countNetParens codePart
               newDepth = max 0 (depth + netParens)
           in fullLine : formatLines tabSize newDepth ls

isCommentLine :: String -> Bool
isCommentLine s = ";" `isPrefixOf` s

isHeaderComment :: String -> Bool
isHeaderComment s =
    ";;" `isPrefixOf` s ||
    ";-" `isPrefixOf` s ||
    "; =" `isPrefixOf` s

countLeadingClosingParens :: String -> Int
countLeadingClosingParens s = length (takeWhile (== ')') s)

countNetParens :: String -> Int
countNetParens str = go 0 False str
  where
    go acc _ [] = acc
    go acc inStr ('\\':_:cs) = go acc inStr cs
    go acc _ ('\\':[])       = acc
    go acc inStr ('"':cs)    = go acc (not inStr) cs
    go acc True (_:cs)       = go acc True cs
    go acc False (';':_)     = acc
    go acc False ('(':cs)    = go (acc + 1) False cs
    go acc False (')':cs)    = go (acc - 1) False cs
    go acc False (_:cs)      = go acc False cs

splitLineComment :: String -> (String, String)
splitLineComment str = go 0 False str
  where
    go _ _ [] = (str, "")
    go idx inStr ('\\':_:cs) = go (idx + 2) inStr cs
    go _ _ ('\\':[])         = (str, "")
    go idx inStr ('"':cs)    = go (idx + 1) (not inStr) cs
    go idx True (_:cs)       = go (idx + 1) True cs
    go idx False (';':_)     = (take idx str, drop idx str)
    go idx False (_:cs)      = go (idx + 1) False cs

trimRight :: String -> String
trimRight = reverse . dropWhile isSpace . reverse

normalizeCodeTokens :: String -> String
normalizeCodeTokens str =
    let toks = lexCodeTokens str
    in assembleTokens toks

lexCodeTokens :: String -> [String]
lexCodeTokens [] = []
lexCodeTokens (c:cs)
    | isSpace c = lexCodeTokens cs
    | c == '('  = "(" : lexCodeTokens cs
    | c == ')'  = ")" : lexCodeTokens cs
    | c == '"'  =
        let (lit, rest) = lexStringLit cs
        in ('"' : lit) : lexCodeTokens rest
    | otherwise =
        let (w, rest) = break (\x -> isSpace x || x == '(' || x == ')') (c:cs)
        in w : lexCodeTokens rest

lexStringLit :: String -> (String, String)
lexStringLit [] = ([], [])
lexStringLit ('\\':c:cs) =
    let (restLit, remaining) = lexStringLit cs
    in ('\\' : c : restLit, remaining)
lexStringLit ('\\':[]) = ("\\", [])
lexStringLit ('"':cs) = ("\"", cs)
lexStringLit (c:cs) =
    let (restLit, remaining) = lexStringLit cs
    in (c : restLit, remaining)

assembleTokens :: [String] -> String
assembleTokens [] = ""
assembleTokens (t:ts) = go t ts
  where
    go cur [] = cur
    go cur (next:rest)
        | next == ")" = go (cur ++ ")") rest
        | cur == "(" || (not (null cur) && last cur == '(') = go (cur ++ next) rest
        | otherwise = go (cur ++ " " ++ next) rest
