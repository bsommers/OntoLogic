module RegistrySpec (spec) where

import Test.Hspec
import OntoLogic

spec :: Spec
spec = describe "Registry helpers (#34)" $ do
    let a = emptyRegistry { concepts = [("A", Nothing)], namespaces = [NamespaceDecl "x" (Just "http://x/")], individuals = [("i1", Nothing)] }
        b = emptyRegistry { concepts = [("A", Nothing), ("B", Just "A")], namespaces = [NamespaceDecl "x" (Just "http://other/")], individuals = [("i1", Nothing), ("i2", Just "A")] }

    it "merges field by field, left first" $ do
        concepts (a <> b) `shouldBe` [("A", Nothing), ("A", Nothing), ("B", Just "A")]
        individuals (a <> b) `shouldBe` [("i1", Nothing), ("i1", Nothing), ("i2", Just "A")]

    it "has emptyRegistry as identity" $ do
        (a <> mempty) `shouldBe` a
        (mempty <> a) `shouldBe` a

    it "deduplicates entries and keeps the last namespace per prefix (current Loader behavior)" $ do
        let d = deduplicateRegistry (a <> b)
        concepts d `shouldBe` [("A", Nothing), ("B", Just "A")]
        namespaces d `shouldBe` [NamespaceDecl "x" (Just "http://other/")]
        individuals d `shouldBe` [("i1", Nothing), ("i2", Just "A")]
