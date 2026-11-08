module Emitters.Owl where

import OntoLogic

emitOwl :: Registry -> String
emitOwl reg = emitOwlWithBase (resolveBaseIri Nothing reg) reg

emitOwlWithBase :: String -> Registry -> String
emitOwlWithBase base reg =
    let iri = resolveIri (namespaces reg) base
    in xmlHeader base (namespaces reg) ++
       ontologyHeader base ++
       concatMap (emitClass iri) (concepts reg) ++
       concatMap (emitProperty iri) (properties reg) ++
       concatMap (emitRelation iri) (relations reg) ++
       xmlFooter

xmlHeader :: String -> [NamespaceDecl] -> String
xmlHeader base customNs =
    "<?xml version=\"1.0\"?>\n" ++
    "<rdf:RDF xmlns=\"" ++ base ++ "#\"\n" ++
    "         xml:base=\"" ++ base ++ "\"\n" ++
    "         xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n" ++
    "         xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\"\n" ++
    "         xmlns:owl=\"http://www.w3.org/2002/07/owl#\"" ++
    -- Only namespaces that declared a URI: "prefix#" is a relative IRI and would make
    -- the document's identifiers depend on where it happens to be served from.
    concatMap (\ns -> maybe "" (\u -> "\n         xmlns:" ++ nsPrefix ns ++ "=\"" ++ escapeXml u ++ "\"") (nsUri ns)) customNs ++ ">\n"

ontologyHeader :: String -> String
ontologyHeader base = "    <owl:Ontology rdf:about=\"" ++ escapeXml base ++ "\"/>\n"

xmlFooter :: String
xmlFooter = "</rdf:RDF>\n"

-- | Absolute IRIs throughout: a relative "#Name" can only ever refer into this
--   document's own base, so it cannot express a concept that belongs to an imported
--   namespace.
emitClass :: (Name -> String) -> (Name, Maybe Name) -> String
emitClass iri (name, Nothing) =
    "    <owl:Class rdf:about=\"" ++ escapeXml (iri name) ++ "\"/>\n"
emitClass iri (name, Just parent) =
    "    <owl:Class rdf:about=\"" ++ escapeXml (iri name) ++ "\"><rdfs:subClassOf rdf:resource=\"" ++
    escapeXml (iri parent) ++ "\"/></owl:Class>\n"

emitProperty :: (Name -> String) -> Property -> String
emitProperty iri p =
    "    <owl:DatatypeProperty rdf:about=\"" ++ escapeXml (iri (propName p)) ++ "\">\n" ++
    "        <rdfs:domain rdf:resource=\"" ++ escapeXml (iri (domain p)) ++ "\"/>\n" ++
    "        <rdfs:range rdf:resource=\"" ++ escapeXml (rangeIri (rangeType p)) ++ "\"/>\n" ++
    "    </owl:DatatypeProperty>\n"
  where
    rangeIri PTInteger    = "http://www.w3.org/2001/XMLSchema#integer"
    rangeIri PTFloat      = "http://www.w3.org/2001/XMLSchema#float"
    rangeIri PTDouble     = "http://www.w3.org/2001/XMLSchema#double"
    rangeIri PTBoolean    = "http://www.w3.org/2001/XMLSchema#boolean"
    rangeIri PTString     = "http://www.w3.org/2001/XMLSchema#string"
    rangeIri (PTCustom c) = iri c

emitRelation :: (Name -> String) -> Relation -> String
emitRelation iri r =
    "    <owl:ObjectProperty rdf:about=\"" ++ escapeXml (iri (relName r)) ++ "\">\n" ++
    "        <rdfs:domain rdf:resource=\"" ++ escapeXml (iri (relDomain r)) ++ "\"/>\n" ++
    "        <rdfs:range rdf:resource=\"" ++ escapeXml (iri (relRange r)) ++ "\"/>\n" ++
    "    </owl:ObjectProperty>\n"

-- | An IRI can legally contain '&', which would otherwise start an XML entity.
escapeXml :: String -> String
escapeXml = concatMap esc
  where
    esc '&' = "&amp;"
    esc '<' = "&lt;"
    esc '>' = "&gt;"
    esc '"' = "&quot;"
    esc c   = [c]
