module LSPSpec (spec) where

import Test.Hspec
import LSP
import OntoLogic (emptyRegistry)
import Parser (parseRegistry)
import Text.Megaparsec (parse)
import System.Timeout (timeout)
import Control.Exception (evaluate)
import Data.Maybe (isJust)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Map.Strict as Map
import Data.List (isInfixOf)
import System.IO (openBinaryFile, hClose, IOMode(ReadMode))
import System.Directory (getTemporaryDirectory, createDirectoryIfMissing)
import System.FilePath ((</>))

spec :: Spec
spec = describe "Language Server Protocol (LSP) Engine" $ do
    it "handles 'initialize' request and advertises capabilities" $ do
        let initReq = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}"
            (_, respOpt, _) = handleLSPRequest initialLSPState initReq
        case respOpt of
            Nothing -> expectationFailure "Expected initialize response"
            Just resp -> do
                resp `shouldContain` "\"textDocumentSync\":2"
                resp `shouldContain` "\"completionProvider\""
                resp `shouldContain` "\"hoverProvider\":true"
                resp `shouldContain` "\"definitionProvider\":true"
                resp `shouldContain` "\"semanticTokensProvider\""
                resp `shouldContain` "\"renameProvider\""
                resp `shouldContain` "\"documentFormattingProvider\":true"

    it "publishes empty diagnostics for valid .logic documents" $ do
        let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///test.logic\",\"text\":\"(def-concept Server)\\n(def-property hostname Server String)\\n\"}}"
            (_, _, notifs) = handleLSPRequest initialLSPState openReq
        length notifs `shouldBe` 1
        let notif = head notifs
        notif `shouldContain` "\"diagnostics\":[]"
        notif `shouldContain` "textDocument/publishDiagnostics"

    it "publishes error diagnostics for syntax parse errors" $ do
        let badReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///bad.logic\",\"text\":\"(def-concept Server (unclosed\"}}"
            (_, _, notifs) = handleLSPRequest initialLSPState badReq
        length notifs `shouldBe` 1
        let notif = head notifs
        notif `shouldContain` "\"severity\":1"
        notif `shouldContain` "ontologic-parser"

    it "publishes error diagnostics for semantic linter errors" $ do
        let circularReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///circ.logic\",\"text\":\"(def-concept A B)\\n(def-concept B A)\\n\"}}"
            (_, _, notifs) = handleLSPRequest initialLSPState circularReq
        length notifs `shouldBe` 1
        let notif = head notifs
        notif `shouldContain` "\"severity\":1"
        notif `shouldContain` "Circular inheritance"

    it "provides completions for keywords, types, and active concepts" $ do
        let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///doc.logic\",\"text\":\"(def-concept Asset)\\n(def-concept Vehicle Asset)\\n\"}}"
            (s1, _, _) = handleLSPRequest initialLSPState openReq
            compReq = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"textDocument/completion\",\"params\":{\"uri\":\"file:///doc.logic\",\"line\":2,\"character\":5}}"
            (_, respOpt, _) = handleLSPRequest s1 compReq
        case respOpt of
            Nothing -> expectationFailure "Expected completion response"
            Just resp -> do
                resp `shouldContain` "def-concept"
                resp `shouldContain` "def-property"
                resp `shouldContain` "def-relation"
                resp `shouldContain` "Integer"
                resp `shouldContain` "Vehicle"
                resp `shouldContain` "Asset"

    it "provides Markdown hover documentation for concepts" $ do
        let content = "(def-concept Asset)\n(def-concept Server Asset)\n(def-property cpu Server Integer)\n"
            openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///hover.logic\",\"text\":\"" ++ content ++ "\"}}"
            (s1, _, _) = handleLSPRequest initialLSPState openReq
            hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"textDocument/hover\",\"params\":{\"uri\":\"file:///hover.logic\",\"line\":1,\"character\":14}}"
            (_, respOpt, _) = handleLSPRequest s1 hoverReq
        case respOpt of
            Nothing -> expectationFailure "Expected hover response"
            Just resp -> do
                resp `shouldContain` "### Concept `Server`"
                resp `shouldContain` "Subclass of"
                resp `shouldContain` "Asset"

    it "resolves jump-to-definition location for symbols" $ do
        let content = "(def-concept Node)\n(def-property ip Node String)\n"
            openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///def.logic\",\"text\":\"" ++ content ++ "\"}}"
            (s1, _, _) = handleLSPRequest initialLSPState openReq
            defReq = "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"textDocument/definition\",\"params\":{\"uri\":\"file:///def.logic\",\"line\":1,\"character\":18}}"
            (_, respOpt, _) = handleLSPRequest s1 defReq
        case respOpt of
            Nothing -> expectationFailure "Expected definition response"
            Just resp -> do
                resp `shouldContain` "file:///def.logic"
                resp `shouldContain` "\"line\":0"

    it "answers hover on a document with an inheritance cycle (#21)" $ do
        let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///c.logic\",\"text\":\"(def-concept A B)\\n(def-concept B A)\\n(def-concept C)\\n(def-property w C Integer)\\n\"}}"
            (s1, _, _) = handleLSPRequest initialLSPState openReq
            hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"textDocument/hover\",\"params\":{\"textDocument\":{\"uri\":\"file:///c.logic\"},\"position\":{\"line\":0,\"character\":13}}}"
        r <- timeout 3000000 (evaluate (length (show (handleLSPRequest s1 hoverReq))))
        r `shouldSatisfy` isJust

    describe "message framing (#22)" $ do
      it "counts Content-Length in UTF-8 bytes" $ do
        let body = "{\"note\":\"caf\233 \8849\"}"
            framed = encodeMessage body
            headerLen = read (takeWhile (/= '\r') (drop (length "Content-Length: ") (BC.unpack framed))) :: Int
        -- the byte count, not the character count
        headerLen `shouldBe` BS.length (TE.encodeUtf8 (T.pack body))
        headerLen `shouldSatisfy` (> length body)

      it "reads two consecutive messages with multi-byte content" $ do
        dir <- getTemporaryDirectory
        let f = dir </> "ontologic-lsp-frames.bin"
            m1 = "{\"method\":\"a\",\"text\":\"caf\233 \8849\"}"
            m2 = "{\"method\":\"b\"}"
        BS.writeFile f (encodeMessage m1 <> encodeMessage m2)
        h <- openBinaryFile f ReadMode
        r1 <- readMessage h
        r2 <- readMessage h
        r3 <- readMessage h
        hClose h
        (r1, r2, r3) `shouldBe` (Just m1, Just m2, Nothing)

      it "parses JSON with a space after the colon" $ do
        let req = "{\"jsonrpc\": \"2.0\", \"id\": 7, \"method\": \"initialize\", \"params\": {}}"
            (_, respOpt, _) = handleLSPRequest initialLSPState req
        fmap (\r -> "\"id\":7" `isInfixOf` r) respOpt `shouldBe` Just True

      it "answers an unknown request with a method-not-found error" $ do
        let req = "{\"jsonrpc\":\"2.0\",\"id\":9,\"method\":\"textDocument/unknownTestRequest\",\"params\":{}}"
            (_, respOpt, _) = handleLSPRequest initialLSPState req
        fmap (\r -> "-32601" `isInfixOf` r) respOpt `shouldBe` Just True

      it "stays silent for an unknown notification" $ do
        let notif = "{\"jsonrpc\":\"2.0\",\"method\":\"$/setTrace\",\"params\":{}}"
            (_, respOpt, _) = handleLSPRequest initialLSPState notif
        respOpt `shouldBe` Nothing

    describe "imports and positions (#27)" $ do
      it "publishes no diagnostics for a document importing the standard library" $ do
        tmp <- (</> "ontologic-lsp-27") <$> getTemporaryDirectory
        createDirectoryIfMissing True tmp
        let uri = "file://" ++ tmp </> "pump.logic"
            req = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"" ++ uri ++ "\",\"text\":\"(import \\\"bfo_2020.logic\\\")\\n(def-concept Pump bfo:Process)\\n\"}}"
        (_, _, notifs) <- handleLSPRequestIO initialLSPState req
        head notifs `shouldContain` "\"diagnostics\":[]"

      it "reports a parse error at its real line" $ do
        let req = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///p.logic\",\"text\":\"(def-concept A)\\n(def-concept B (oops\\n\"}}"
        (_, _, notifs) <- handleLSPRequestIO initialLSPState req
        head notifs `shouldContain` "\"line\":1"

      it "resolves go-to-definition on a whole identifier" $ do
        let text = "(def-concept TankTruck)\\n(def-concept Tank)\\n"
            openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///d.logic\",\"text\":\"" ++ text ++ "\"}}"
        (st, _, _) <- handleLSPRequestIO initialLSPState openReq
        let defReq = "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"textDocument/definition\",\"params\":{\"textDocument\":{\"uri\":\"file:///d.logic\"},\"position\":{\"line\":1,\"character\":14}}}"
        (_, respOpt, _) <- handleLSPRequestIO st defReq
        fmap (\r -> "\"line\":1" `isInfixOf` r) respOpt `shouldBe` Just True

      it "points a lint diagnostic at the offending declaration" $ do
        let text = "(def-concept Asset)\n(def-concept Device Asset)\n(def-concept Pump bfo:Process)\n"
            req = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///l.logic\",\"text\":\"" ++ escapeForJson text ++ "\"}}"
        (_, _, notifs) <- handleLSPRequestIO initialLSPState req
        head notifs `shouldContain` "\"line\":2"
        head notifs `shouldContain` "\"character\":13"   -- column of "Pump"

    describe "Code Actions, SMT Commands & Hover Enhancements" $ do
      it "provides SMT code actions for document" $ do
        let req = "{\"jsonrpc\":\"2.0\",\"id\":12,\"method\":\"textDocument/codeAction\",\"params\":{\"textDocument\":{\"uri\":\"file:///test.logic\"}}}"
            (_, respOpt, _) = handleLSPRequest initialLSPState req
        case respOpt of
            Nothing -> expectationFailure "Expected codeAction response"
            Just resp -> do
                resp `shouldContain` "ontologic.solve"
                resp `shouldContain` "ontologic.explainUnsat"
                resp `shouldContain` "ontologic.inspectModel"

      it "executes ontologic.solve via workspace/executeCommand" $ do
        let docText = "(def-concept Device)\\n(def-property serial_number Device String)\\n"
            openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///cmd.logic\",\"text\":\"" ++ docText ++ "\"}}"
        (st, _, _) <- handleLSPRequestIO initialLSPState openReq
        let cmdReq = "{\"jsonrpc\":\"2.0\",\"id\":13,\"method\":\"workspace/executeCommand\",\"params\":{\"command\":\"ontologic.solve\",\"uri\":\"file:///cmd.logic\"}}"
        (_, respOpt, _) <- handleLSPRequestIO st cmdReq
        case respOpt of
            Nothing -> expectationFailure "Expected executeCommand response"
            Just resp -> resp `shouldContain` "\"status\":\"sat\""

      it "executes ontologic.solve via workspace/executeCommand with standard arguments array" $ do
        let docText = "(def-concept Widget)\\n(def-property weight Widget Float)\\n"
            openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///args.logic\",\"text\":\"" ++ docText ++ "\"}}"
        (st, _, _) <- handleLSPRequestIO initialLSPState openReq
        let cmdReq = "{\"jsonrpc\":\"2.0\",\"id\":131,\"method\":\"workspace/executeCommand\",\"params\":{\"command\":\"ontologic.solve\",\"arguments\":[\"file:///args.logic\"]}}"
        (_, respOpt, _) <- handleLSPRequestIO st cmdReq
        case respOpt of
            Nothing -> expectationFailure "Expected executeCommand response"
            Just resp -> resp `shouldContain` "\"status\":\"sat\""

      it "displays property cardinality and defaults in hover" $ do
        let docText = "(def-concept Device)\\n(def-property serial Device String :cardinality 1..1)\\n(def-property desc Device String :cardinality 0..1 :default \\\"none\\\")\\n"
            openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///h_card.logic\",\"text\":\"" ++ docText ++ "\"}}"
        (st, _, _) <- handleLSPRequestIO initialLSPState openReq
        let hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":14,\"method\":\"textDocument/hover\",\"params\":{\"uri\":\"file:///h_card.logic\",\"line\":0,\"character\":14}}"
        (_, respOpt, _) <- handleLSPRequestIO st hoverReq
        case respOpt of
            Nothing -> expectationFailure "Expected hover response"
            Just resp -> do
                resp `shouldContain` "1..1"
                resp `shouldContain` "0..1"
                resp `shouldContain` "none"

    describe "Incremental Document Sync & SMT Cancellation" $ do
        it "applies incremental range change correctly" $ do
            let initial = "(def-concept Device)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///inc.logic\",\"text\":\"" ++ initial ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                changeReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didChange\",\"params\":{\"uri\":\"file:///inc.logic\",\"contentChanges\":[{\"range\":{\"start\":{\"line\":0,\"character\":13},\"end\":{\"line\":0,\"character\":19}},\"text\":\"Robot\"}]}}"
                (s2, _, _) = handleLSPRequest s1 changeReq
                compReq = "{\"jsonrpc\":\"2.0\",\"id\":20,\"method\":\"textDocument/completion\",\"params\":{\"uri\":\"file:///inc.logic\",\"line\":0,\"character\":5}}"
                (_, respOpt, _) = handleLSPRequest s2 compReq
            case respOpt of
                Nothing -> expectationFailure "Expected completion response after incremental change"
                Just resp -> do
                    resp `shouldContain` "Robot"
                    resp `shouldNotContain` "\"Device\""

        it "publishes embedded SAT semantic contradiction diagnostics" $ do
            let satDoc = "(def-concept A)\\n(def-concept B A)\\n(def-concept C B)\\n(forall (x) (implies (C x) (not (A x))))\\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///sat.logic\",\"text\":\"" ++ satDoc ++ "\"}}"
                (_, _, notifs) = handleLSPRequest initialLSPState openReq
            length notifs `shouldBe` 1
            let notif = head notifs
            notif `shouldContain` "Semantic contradiction: Concept C implies A"
            notif `shouldContain` "ontologic-linter"

        it "handles client cancellation request $/cancelRequest cleanly" $ do
            let cancelReq = "{\"jsonrpc\":\"2.0\",\"method\":\"$/cancelRequest\",\"params\":{\"id\":999}}"
                (s1, respOpt, notifs) = handleLSPRequest initialLSPState cancelReq
            respOpt `shouldBe` Nothing
            notifs `shouldBe` []
            s1 `shouldBe` initialLSPState

        it "applies multiple sequential range changes correctly" $ do
            let original = "hello world"
                -- Replace "hello" (0:0-0:5) with "hi"
                change1 = applyRangeChange 0 0 0 5 "hi" original
                -- Replace "world" now at 0:3-0:8 in "hi world"
                change2 = applyRangeChange 0 3 0 8 "earth" change1
            change1 `shouldBe` "hi world"
            change2 `shouldBe` "hi earth"

        it "handles multi-line range replacement" $ do
            let original = "line1\nline2\nline3\n"
                -- Replace line2 entirely (1:0-2:0)
                result = applyRangeChange 1 0 2 0 "replaced\n" original
            result `shouldBe` "line1\nreplaced\nline3\n"

        it "handles insertion at position (same start and end)" $ do
            let original = "abc"
                result = applyRangeChange 0 1 0 1 "XY" original
            result `shouldBe` "aXYbc"

    describe "Semantic Tokens (textDocument/semanticTokens/full)" $ do
        it "emits delta-encoded semantic tokens for keywords, types, concepts, properties, and comments" $ do
            let doc = "; Model\n(def-concept Server)\n(def-property ip Server String)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///tokens.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                tokReq = "{\"jsonrpc\":\"2.0\",\"id\":21,\"method\":\"textDocument/semanticTokens/full\",\"params\":{\"textDocument\":{\"uri\":\"file:///tokens.logic\"}}}"
                (_, respOpt, _) = handleLSPRequest s1 tokReq
            case respOpt of
                Nothing -> expectationFailure "Expected semantic tokens response"
                Just resp -> do
                    resp `shouldContain` "\"data\":["
                    resp `shouldNotContain` "\"data\":[]"

        it "tokenizes axioms with quantifiers, operators, and literals" $ do
            let doc = "(forall (x) (implies (eq is_valid True) (Mitigation x)))"
                toks = computeSemanticTokens doc emptyRegistry
            length toks `shouldSatisfy` (> 0)
            (length toks `mod` 5) `shouldBe` 0

    describe "Enhanced Hover Documentation" $ do
        it "provides keyword hover for DSL keywords" $ do
            let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///h.logic\",\"text\":\"(def-concept Asset)\\n\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":31,\"method\":\"textDocument/hover\",\"params\":{\"uri\":\"file:///h.logic\",\"line\":0,\"character\":4}}"
                (_, respOpt, _) = handleLSPRequest s1 hoverReq
            case respOpt of
                Nothing -> expectationFailure "Expected keyword hover"
                Just resp -> do
                    resp `shouldContain` "Keyword `def-concept`"
                    resp `shouldContain` "Syntax:"

        it "provides primitive type hover" $ do
            let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///htype.logic\",\"text\":\"(def-property count Node Integer)\\n\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":32,\"method\":\"textDocument/hover\",\"params\":{\"uri\":\"file:///htype.logic\",\"line\":0,\"character\":26}}"
                (_, respOpt, _) = handleLSPRequest s1 hoverReq
            case respOpt of
                Nothing -> expectationFailure "Expected type hover"
                Just resp -> resp `shouldContain` "Type `Integer`"

        it "extracts preceding doc-comments in concept hover" $ do
            let doc = ";; Primary Server Entity\n;; Represents compute workload host\n(def-concept Server)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///hdoc.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":33,\"method\":\"textDocument/hover\",\"params\":{\"uri\":\"file:///hdoc.logic\",\"line\":2,\"character\":14}}"
                (_, respOpt, _) = handleLSPRequest s1 hoverReq
            case respOpt of
                Nothing -> expectationFailure "Expected concept hover with docstrings"
                Just resp -> do
                    resp `shouldContain` "Concept `Server`"
                    resp `shouldContain` "Primary Server Entity"
                    resp `shouldContain` "Represents compute workload host"

    describe "Rename Refactoring (textDocument/rename & prepareRename)" $ do
        it "prepares rename on a declared concept" $ do
            let doc = "(def-concept Asset)\n(def-concept Server Asset)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///rn.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                prepReq = "{\"jsonrpc\":\"2.0\",\"id\":41,\"method\":\"textDocument/prepareRename\",\"params\":{\"textDocument\":{\"uri\":\"file:///rn.logic\"},\"position\":{\"line\":0,\"character\":14}}}"
                (_, respOpt, _) = handleLSPRequest s1 prepReq
            case respOpt of
                Nothing -> expectationFailure "Expected prepareRename response"
                Just resp -> do
                    resp `shouldContain` "\"placeholder\":\"Asset\""
                    resp `shouldContain` "\"start\":{\"line\":0,\"character\":13}"
                    resp `shouldContain` "\"end\":{\"line\":0,\"character\":18}"

        it "returns null on prepareRename when cursor is on keyword" $ do
            let doc = "(def-concept Asset)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///rn_kw.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                prepReq = "{\"jsonrpc\":\"2.0\",\"id\":42,\"method\":\"textDocument/prepareRename\",\"params\":{\"textDocument\":{\"uri\":\"file:///rn_kw.logic\"},\"position\":{\"line\":0,\"character\":4}}}"
                (_, respOpt, _) = handleLSPRequest s1 prepReq
            case respOpt of
                Nothing -> expectationFailure "Expected prepareRename response"
                Just resp -> resp `shouldContain` "\"result\":null"

        it "renames concept across declarations, inheritance, and axioms" $ do
            let doc = "(def-concept Asset)\n(def-concept Server Asset)\n(forall (x) (implies (Server x) (Asset x)))\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///rename.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                renameReq = "{\"jsonrpc\":\"2.0\",\"id\":43,\"method\":\"textDocument/rename\",\"params\":{\"textDocument\":{\"uri\":\"file:///rename.logic\"},\"position\":{\"line\":0,\"character\":14},\"newName\":\"Resource\"}}"
                (_, respOpt, _) = handleLSPRequest s1 renameReq
            case respOpt of
                Nothing -> expectationFailure "Expected rename response"
                Just resp -> do
                    resp `shouldContain` "\"changes\""
                    resp `shouldContain` "Resource"
                    let occs = findSymbolOccurrences doc "Asset"
                    length occs `shouldBe` 3

        it "rejects renaming to invalid identifier name" $ do
            let doc = "(def-concept Asset)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///rn_bad.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                renameReq = "{\"jsonrpc\":\"2.0\",\"id\":44,\"method\":\"textDocument/rename\",\"params\":{\"textDocument\":{\"uri\":\"file:///rn_bad.logic\"},\"position\":{\"line\":0,\"character\":14},\"newName\":\"123BadName\"}}"
                (_, respOpt, _) = handleLSPRequest s1 renameReq
            case respOpt of
                Nothing -> expectationFailure "Expected error response"
                Just resp -> do
                    resp `shouldContain` "-32602"
                    resp `shouldContain` "Invalid new symbol name"

    describe "Code Formatting Provider (textDocument/formatting)" $ do
        it "formats irregular whitespace and standardizes s-expression indentation" $ do
            let unformatted = "(def-concept   Server    Asset)\n\n\n(def-property    cpu   Server   Integer)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///fmt.logic\",\"text\":\"" ++ escapeForJson unformatted ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                fmtReq = "{\"jsonrpc\":\"2.0\",\"id\":51,\"method\":\"textDocument/formatting\",\"params\":{\"textDocument\":{\"uri\":\"file:///fmt.logic\"},\"options\":{\"tabSize\":2}}}"
                (_, respOpt, _) = handleLSPRequest s1 fmtReq
            case respOpt of
                Nothing -> expectationFailure "Expected formatting response"
                Just resp -> do
                    resp `shouldContain` "(def-concept Server Asset)"
                    resp `shouldContain` "(def-property cpu Server Integer)"

        it "formats multi-line nested axioms with 2-space indentation" $ do
            let unformatted = "(forall (x)\n(implies (Server x)\n(Asset x)))\n"
                formatted = formatLogicDocument unformatted 2
            formatted `shouldBe` "(forall (x)\n  (implies (Server x)\n    (Asset x)))\n"

        it "preserves comments and string literals during formatting" $ do
            let original = ";; Core Module\n(def-concept Asset) ; Base entity\n(def-axiom \"Rule: check spaces\" (Asset x))\n"
                formatted = formatLogicDocument original 2
            formatted `shouldContain` ";; Core Module"
            formatted `shouldContain` "; Base entity"
            formatted `shouldContain` "\"Rule: check spaces\""

        it "preserves AST equivalence after formatting" $ do
            let input = "(def-concept Server Asset)\n(def-property ip Server String :cardinality 1..1)\n(forall (x) (implies (Server x) (Asset x)))\n"
                formatted = formatLogicDocument input 2
                p1 = parse parseRegistry "orig" (T.pack input)
                p2 = parse parseRegistry "fmt" (T.pack formatted)
            case (p1, p2) of
                (Right r1, Right r2) -> r1 `shouldBe` r2
                _ -> expectationFailure "Failed to parse formatted logic"

    describe "Error Recovery and Robustness" $ do
        it "returns error -32601 for unknown request methods with an id" $ do
            let req = "{\"jsonrpc\":\"2.0\",\"id\":99,\"method\":\"workspace/unknownMethod\",\"params\":{}}"
                (_, respOpt, notifs) = handleLSPRequest initialLSPState req
            notifs `shouldBe` []
            case respOpt of
                Nothing -> expectationFailure "Expected error response for unknown request"
                Just resp -> do
                    resp `shouldContain` "\"id\":99"
                    resp `shouldContain` "\"code\":-32601"
                    resp `shouldContain` "Method not found: workspace/unknownMethod"

        it "silently drops unknown notifications without an id" $ do
            let notif = "{\"jsonrpc\":\"2.0\",\"method\":\"$/unknownNotification\",\"params\":{}}"
                (_, respOpt, notifs) = handleLSPRequest initialLSPState notif
            respOpt `shouldBe` Nothing
            notifs `shouldBe` []

        it "handles 'shutdown' request and returns null result" $ do
            let req = "{\"jsonrpc\":\"2.0\",\"id\":100,\"method\":\"shutdown\"}"
                (_, respOpt, notifs) = handleLSPRequest initialLSPState req
            notifs `shouldBe` []
            case respOpt of
                Nothing -> expectationFailure "Expected shutdown response"
                Just resp -> do
                    resp `shouldContain` "\"id\":100"
                    resp `shouldContain` "\"result\":null"

        it "handles malformed non-JSON payload without id without raising exceptions" $ do
            let malformed = "not valid json at all {{{ ("
                (_, respOpt, notifs) = handleLSPRequest initialLSPState malformed
            respOpt `shouldBe` Nothing
            notifs `shouldBe` []

        it "handles malformed JSON with an id by returning method not found error" $ do
            let malformed = "{\"id\":42, invalid json content here"
                (_, respOpt, notifs) = handleLSPRequest initialLSPState malformed
            notifs `shouldBe` []
            case respOpt of
                Nothing -> expectationFailure "Expected error response for malformed JSON with id"
                Just resp -> do
                    resp `shouldContain` "\"id\":42"
                    resp `shouldContain` "\"code\":-32601"

    describe "Incremental Buffer Changes & Range Calculations" $ do
        it "applies range changes to replace text at specific line and character coordinates" $ do
            let original = "(def-concept Asset)\n(def-property id Asset String)\n"
                modified = applyRangeChange 1 14 1 16 "serial" original
            modified `shouldBe` "(def-concept Asset)\n(def-property serial Asset String)\n"

        it "applies multi-line range replacements" $ do
            let original = "line 1\nline 2\nline 3\n"
                modified = applyRangeChange 0 5 2 4 "REPLACED" original
            modified `shouldBe` "line REPLACED 3\n"

        it "processes textDocument/didChange full replacement and publishes diagnostics" $ do
            let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///inc.logic\",\"text\":\"(def-concept A)\\n\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                changeReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didChange\",\"params\":{\"uri\":\"file:///inc.logic\",\"text\":\"(def-concept A)\\n(def-concept B A)\\n\"}}"
                (s2, _, notifs) = handleLSPRequest s1 changeReq
            length notifs `shouldBe` 1
            let notif = head notifs
            notif `shouldContain` "textDocument/publishDiagnostics"
            notif `shouldContain` "\"diagnostics\":[]"
            Map.member "file:///inc.logic" (lspDocs s2) `shouldBe` True

    describe "Semantic Tokens Full Request Provider" $ do
        it "handles textDocument/semanticTokens/full request" $ do
            let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///tok.logic\",\"text\":\"(def-concept Device)\\n(def-property power Device Integer)\\n\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                tokReq = "{\"jsonrpc\":\"2.0\",\"id\":88,\"method\":\"textDocument/semanticTokens/full\",\"params\":{\"textDocument\":{\"uri\":\"file:///tok.logic\"}}}"
                (_, respOpt, _) = handleLSPRequest s1 tokReq
            case respOpt of
                Nothing -> expectationFailure "Expected semantic tokens response"
                Just resp -> do
                    resp `shouldContain` "\"id\":88"
                    resp `shouldContain` "\"data\":["

    describe "Code Actions & Workspace Commands" $ do
        it "returns SMT solver quickfix actions for textDocument/codeAction" $ do
            let caReq = "{\"jsonrpc\":\"2.0\",\"id\":71,\"method\":\"textDocument/codeAction\",\"params\":{\"textDocument\":{\"uri\":\"file:///test.logic\"}}}"
                (_, respOpt, _) = handleLSPRequest initialLSPState caReq
            case respOpt of
                Nothing -> expectationFailure "Expected codeAction response"
                Just resp -> do
                    resp `shouldContain` "Verify SMT Consistency"
                    resp `shouldContain` "ontologic.solve"
                    resp `shouldContain` "ontologic.explainUnsat"
                    resp `shouldContain` "ontologic.inspectModel"

        it "returns executed status for workspace/executeCommand pure handler" $ do
            let cmdReq = "{\"jsonrpc\":\"2.0\",\"id\":72,\"method\":\"workspace/executeCommand\",\"params\":{\"command\":\"custom.command\"}}"
                (_, respOpt, _) = handleLSPRequest initialLSPState cmdReq
            case respOpt of
                Nothing -> expectationFailure "Expected executeCommand response"
                Just resp -> do
                    resp `shouldContain` "\"status\":\"executed\""
                    resp `shouldContain` "custom.command"

        it "executes ontologic.solve command via handleLSPRequestIO" $ do
            let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///cmd.logic\",\"text\":\"(def-concept Node)\\n\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                solveReq = "{\"jsonrpc\":\"2.0\",\"id\":73,\"method\":\"workspace/executeCommand\",\"command\":\"ontologic.solve\",\"arguments\":[\"file:///cmd.logic\"]}"
            (_, respOpt, _) <- handleLSPRequestIO s1 solveReq
            case respOpt of
                Nothing -> expectationFailure "Expected solve response"
                Just resp -> resp `shouldContain` "\"status\":"

        it "executes ontologic.inspectModel command via handleLSPRequestIO" $ do
            let openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///cmd_model.logic\",\"text\":\"(def-concept Node)\\n\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                inspectReq = "{\"jsonrpc\":\"2.0\",\"id\":74,\"method\":\"workspace/executeCommand\",\"command\":\"ontologic.inspectModel\",\"arguments\":[\"file:///cmd_model.logic\"]}"
            (_, respOpt, _) <- handleLSPRequestIO s1 inspectReq
            case respOpt of
                Nothing -> expectationFailure "Expected inspectModel response"
                Just resp -> resp `shouldContain` "\"status\":"

    describe "Property and Relation Hover Documentation" $ do
        it "provides hover documentation for properties with default and cardinality" $ do
            let doc = ";; Sensor Reading Property\n(def-concept Device)\n(def-property reading Device Float :cardinality 1..1 :default \"0.0\")\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///prop_hover.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":91,\"method\":\"textDocument/hover\",\"params\":{\"uri\":\"file:///prop_hover.logic\",\"line\":2,\"character\":16}}"
                (_, respOpt, _) = handleLSPRequest s1 hoverReq
            case respOpt of
                Nothing -> expectationFailure "Expected property hover"
                Just resp -> do
                    resp `shouldContain` "Property `reading`"
                    resp `shouldContain` "Domain:"
                    resp `shouldContain` "Cardinality:"
                    resp `shouldContain` "Default:"

        it "provides hover documentation for relations with signatures" $ do
            let doc = ";; Connects Device to Controller\n(def-concept Device)\n(def-concept Controller)\n(def-relation connects Device Controller)\n"
                openReq = "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"uri\":\"file:///rel_hover.logic\",\"text\":\"" ++ escapeForJson doc ++ "\"}}"
                (s1, _, _) = handleLSPRequest initialLSPState openReq
                hoverReq = "{\"jsonrpc\":\"2.0\",\"id\":92,\"method\":\"textDocument/hover\",\"params\":{\"uri\":\"file:///rel_hover.logic\",\"line\":3,\"character\":16}}"
                (_, respOpt, _) = handleLSPRequest s1 hoverReq
            case respOpt of
                Nothing -> expectationFailure "Expected relation hover"
                Just resp -> do
                    resp `shouldContain` "Relation `connects`"
                    resp `shouldContain` "Domain:"
                    resp `shouldContain` "Range:"

    describe "Lifecycle Notifications" $ do
        it "silently accepts initialized notification" $ do
            let req = "{\"jsonrpc\":\"2.0\",\"method\":\"initialized\",\"params\":{}}"
                (_, respOpt, notifs) = handleLSPRequest initialLSPState req
            respOpt `shouldBe` Nothing
            notifs `shouldBe` []

        it "silently accepts $/cancelRequest notification" $ do
            let req = "{\"jsonrpc\":\"2.0\",\"method\":\"$/cancelRequest\",\"params\":{\"id\":99}}"
                (_, respOpt, notifs) = handleLSPRequest initialLSPState req
            respOpt `shouldBe` Nothing
            notifs `shouldBe` []

  where
    escapeForJson = concatMap (\c -> case c of '\n' -> "\\n"; '"' -> "\\\""; '\\' -> "\\\\"; other -> [other])
