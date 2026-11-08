{-# LANGUAGE OverloadedStrings #-}
module Parser where

import Text.Megaparsec hiding (SourcePos)
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Text (Text)
import Data.Void
import Control.Monad (when)
import Data.List (isPrefixOf)
import qualified Data.Map as Map
import OntoLogic

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 
             (L.skipLineComment ";" <|> L.skipLineComment "//") 
             (L.skipBlockComment "/*" "*/" <|> L.skipBlockComment "#|" "|#")

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

identChar :: Parser Char
identChar = alphaNumChar <|> oneOf ("_:-./+*'" :: String)

-- | A reserved word that is not the prefix of a longer identifier.
keyword :: Text -> Parser Text
keyword w = lexeme (try (string w <* notFollowedBy (identChar <|> char '=')))

parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

-- | Get current Megaparsec source coordinate converted to OntoLogic SourcePos
getPos :: Parser SourcePos
getPos = do
    sp <- getSourcePos
    return $ SourcePos
        (sourceName sp)
        (unPos (sourceLine sp))
        (unPos (sourceColumn sp))

-- | Parser with AST source position table
parseRegistryWithSource :: Parser (Registry, SourceTable)
parseRegistryWithSource = do
    sc
    items <- many parseItem
    eof
    let reg = foldr addItem emptyRegistry items
        tbl = foldr addItemSource emptySourceTable items
    return (reg, tbl)

-- | Main Parser Entry returning Registry
parseRegistry :: Parser Registry
parseRegistry = fst <$> parseRegistryWithSource

data Item = IConcept SourcePos Name (Maybe Name)
          | IProperty SourcePos Property
          | IRelation SourcePos Relation
          | IImport SourcePos ImportDecl
          | INamespace SourcePos NamespaceDecl
          | IAxiom SourcePos FOL
          | IIndividual SourcePos Name (Maybe Name)

parseItem :: Parser Item
parseItem = parens (
        parseDefConcept <|>
        parseDefProperty <|>
        parseDefRelation <|>
        parseDefIndividual <|>
        parseImport <|>
        parseNamespace <|>
        parseDefAxiom <|>
        parseBareAxiom
    )

parseBareAxiom :: Parser Item
parseBareAxiom = do
    pos <- getPos
    fol <- parseFOL
    return $ IAxiom pos fol

parseDefAxiom :: Parser Item
parseDefAxiom = do
    _ <- keyword "def-axiom"
    pos <- getPos
    _ <- optional (try stringLiteral)
    fol <- parens parseFOL <|> parseFOL
    return $ IAxiom pos fol

parseImport :: Parser Item
parseImport = do
    _ <- keyword "import"
    pos <- getPos
    path <- stringLiteral
    return $ IImport pos (ImportDecl path)

parseNamespace :: Parser Item
parseNamespace = do
    _ <- keyword "namespace"
    pos <- getPos
    prefix <- identifier
    uri <- optional (try stringLiteral <|> identifier)
    return $ INamespace pos (NamespaceDecl prefix uri)

parseDefConcept :: Parser Item
parseDefConcept = do
    _ <- keyword "def-concept"
    pos <- getPos
    name <- identifier
    parent <- optional identifier
    return $ IConcept pos name parent

parseDefIndividual :: Parser Item
parseDefIndividual = do
    _ <- keyword "def-individual"
    pos <- getPos
    name <- identifier
    concept <- optional identifier
    return $ IIndividual pos name concept

cardString :: Parser String
cardString = lexeme (some (alphaNumChar <|> char '.' <|> char '*' <|> char '-'))

parsePropOption :: Parser (Maybe Cardinality, Maybe String)
parsePropOption = try parseCard <|> try parseOpt <|> parseDef
  where
    parseCard = do
        _ <- lexeme (string ":cardinality")
        s <- cardString
        case parseCardinality s of
            Just c  -> return (Just c, Nothing)
            Nothing -> fail ("Invalid cardinality '" ++ s ++ "', expected 0..1, 1..1, 0..*, 1..*")
    parseOpt = do
        _ <- lexeme (string ":optional")
        val <- identifier
        case val of
            "True"  -> return (Just CardZeroOrOne, Nothing)
            "true"  -> return (Just CardZeroOrOne, Nothing)
            "False" -> return (Just CardExactlyOne, Nothing)
            "false" -> return (Just CardExactlyOne, Nothing)
            _       -> fail ("Expected True or False for :optional, got: " ++ val)
    parseDef = do
        _ <- lexeme (string ":default")
        d <- try stringLiteral <|> identifier <|> cardString
        return (Nothing, Just d)

parseRelOption :: Parser (Maybe Cardinality)
parseRelOption = do
    _ <- lexeme (string ":cardinality")
    s <- cardString
    case parseCardinality s of
        Just c  -> return (Just c)
        Nothing -> fail ("Invalid cardinality '" ++ s ++ "', expected 0..1, 1..1, 0..*, 1..*")

parseDefProperty :: Parser Item
parseDefProperty = do
    _ <- keyword "def-property"
    pos <- getPos
    name <- identifier
    dom <- identifier
    rngStr <- identifier
    let rng = parsePropertyType rngStr
    opts <- many parsePropOption
    let card = case [c | (Just c, _) <- opts] of
                 (c:_) -> c
                 []    -> CardDefault
        defVal = case [d | (_, Just d) <- opts] of
                   (d:_) -> Just d
                   []    -> Nothing
    return $ IProperty pos (PropertyDef name dom rng card defVal)

parseDefRelation :: Parser Item
parseDefRelation = do
    _ <- keyword "def-relation"
    pos <- getPos
    name <- identifier
    dom <- identifier
    rng <- identifier
    rest <- many identifier
    opts <- many parseRelOption
    let card = case [c | Just c <- opts] of
                 (c:_) -> c
                 []    -> CardDefault
        sig = dom : rng : rest
    return $ IRelation pos (RelationDef name dom rng card sig)

parseFOL :: Parser FOL
parseFOL = 
    parens parseFOL <|>
    parseForAll <|>
    parseExists <|>
    parseImplies <|>
    parseIff <|>
    parseAnd <|>
    parseOr <|>
    parseNot <|>
    try parseEq <|>
    try parseNe <|>
    try parseTop <|>
    try parseBottom <|>
    parsePredicate

parseTop :: Parser FOL
parseTop = do
    _ <- keyword "true" <|> keyword "True" <|> keyword "top" <|> keyword "Top"
    return Top

parseBottom :: Parser FOL
parseBottom = do
    _ <- keyword "false" <|> keyword "False" <|> keyword "bottom" <|> keyword "Bottom"
    return Bottom

parseEq :: Parser FOL
parseEq = do
    _ <- keyword "=" <|> keyword "eq"
    t1 <- parseTerm
    t2 <- parseTerm
    return $ Eq t1 t2

parseNe :: Parser FOL
parseNe = do
    _ <- keyword "!="
    t1 <- parseTerm
    t2 <- parseTerm
    return $ Not (Eq t1 t2)

parseVarBinding :: Parser (String, Maybe String)
parseVarBinding =
    try (parens $ do
        v <- identifier
        s <- identifier
        return (v, Just s))
    <|> ((\v -> (v, Nothing)) <$> identifier)

subFOL :: Parser FOL
subFOL = parens parseFOL <|> try parseTop <|> try parseBottom

parseForAll :: Parser FOL
parseForAll = do
    _ <- keyword "forall"
    varsOrTyped <- parens (some parseVarBinding)
    body <- subFOL
    return $ foldr wrapQuant body varsOrTyped
  where
    wrapQuant (v, Nothing) acc   = ForAll v acc
    wrapQuant (v, Just sort) acc = TypedForAll v sort acc

parseExists :: Parser FOL
parseExists = do
    _ <- keyword "exists"
    varsOrTyped <- parens (some parseVarBinding)
    body <- subFOL
    return $ foldr wrapQuant body varsOrTyped
  where
    wrapQuant (v, Nothing) acc   = Exists v acc
    wrapQuant (v, Just sort) acc = TypedExists v sort acc

parseImplies :: Parser FOL
parseImplies = do
    _ <- keyword "implies" <|> keyword "if"
    p <- subFOL
    q <- subFOL
    return $ Implies p q

parseIff :: Parser FOL
parseIff = do
    _ <- keyword "iff"
    p <- subFOL
    q <- subFOL
    return $ Iff p q

parseAnd :: Parser FOL
parseAnd = do
    _ <- keyword "and"
    fs <- many subFOL
    return $ case fs of
        []     -> Top
        [p]    -> p
        (p:ps) -> foldr1 And (p:ps)

parseOr :: Parser FOL
parseOr = do
    _ <- keyword "or"
    fs <- many subFOL
    return $ case fs of
        []     -> Bottom
        [p]    -> p
        (p:ps) -> foldr1 Or (p:ps)

parseNot :: Parser FOL
parseNot = do
    _ <- keyword "not"
    p <- subFOL
    return $ Not p

reservedWords :: [String]
reservedWords = ["forall", "exists", "implies", "if", "iff", "and", "or", "not", "import", "namespace", "def-individual", "=", "!="]

parsePredicate :: Parser FOL
parsePredicate = do
    o <- getOffset
    op <- identifier
    when ("def-" `isPrefixOf` op || op `elem` reservedWords) $ do
        setOffset o
        fail ("unknown form '" ++ op ++ "'")
    args <- many parseTerm
    return $ Predicate op args

parseTerm :: Parser Term
parseTerm = (Constant <$> try stringLiteral) 
        <|> (try (Constant . show <$> (L.signed sc L.float :: Parser Double)))
        <|> (try (Constant . show <$> (L.signed sc L.decimal :: Parser Integer)))
        <|> (try (keyword "True" >> pure (Constant "True")))
        <|> (try (keyword "False" >> pure (Constant "False")))
        <|> (try (keyword "true" >> pure (Constant "True")))
        <|> (try (keyword "false" >> pure (Constant "False")))
        <|> try parseApplyTerm
        <|> (Var <$> identifier)

parseApplyTerm :: Parser Term
parseApplyTerm = parens $ do
    o <- getOffset
    fn <- identifier
    when (fn `elem` reservedWords) $ do
        setOffset o
        fail ("reserved word '" ++ fn ++ "' cannot be used as function name")
    args <- many parseTerm
    return $ Apply fn args

identifier :: Parser String
identifier = lexeme (try specialSymbol <|> standardIdent)
  where
    standardIdent = (:) <$> (letterChar <|> char '_') <*> many identChar
    specialSymbol = some (oneOf ("+*/<>=!&|'~" :: String))

stringLiteral :: Parser String
stringLiteral = lexeme (char '"' >> manyTill L.charLiteral (char '"'))

addItem :: Item -> Registry -> Registry
addItem (IConcept _ n p) r     = r { concepts = (n, p) : concepts r }
addItem (IProperty _ prop) r   = r { properties = prop : properties r }
addItem (IRelation _ rel) r    = r { relations = rel : relations r }
addItem (IImport _ imp) r      = r { imports = imp : imports r }
addItem (INamespace _ ns) r    = r { namespaces = ns : namespaces r }
addItem (IAxiom _ a) r         = r { axioms = a : axioms r }
addItem (IIndividual _ n c) r  = r { individuals = (n, c) : individuals r }

addItemSource :: Item -> SourceTable -> SourceTable
addItemSource (IConcept pos n _) tbl =
    Map.insert ("concept:" ++ n) pos $ Map.insert n pos tbl
addItemSource (IProperty pos prop) tbl =
    Map.insert ("property:" ++ propName prop ++ ":" ++ domain prop) pos
    $ Map.insert ("property:" ++ propName prop) pos
    $ Map.insert (propName prop) pos tbl
addItemSource (IRelation pos rel) tbl =
    Map.insert ("relation:" ++ relName rel) pos
    $ Map.insert (relName rel) pos tbl
addItemSource (IImport pos imp) tbl =
    Map.insert ("import:" ++ importPath imp) pos tbl
addItemSource (INamespace pos ns) tbl =
    Map.insert ("namespace:" ++ nsPrefix ns) pos
    $ Map.insert (nsPrefix ns) pos tbl
addItemSource (IAxiom pos a) tbl =
    Map.insert ("axiom:" ++ show a) pos tbl
addItemSource (IIndividual pos n _) tbl =
    Map.insert ("individual:" ++ n) pos $ Map.insert n pos tbl
