module EcosystemSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf, isPrefixOf)
import OntoLogic
import Loader (loadRegistryWithImports)
import Solver (checkConsistencyWith, Prover(AutoProver))

-- `Right reg <-` in a do block trips -Wincomplete-uni-patterns under -Werror.
loadEcosystem :: IO Registry
loadEcosystem = do
    loaded <- loadRegistryWithImports "ontologic-lib/ecosystem.logic"
    case loaded of
        Left err  -> error ("could not load ecosystem.logic: " ++ err)
        Right reg -> return reg

spec :: Spec
spec = describe "ecosystem.logic models symbols as data (#35)" $ do
    it "declares only the class layer" $ do
        reg <- loadEcosystem
        let own = [ c | (c, _) <- concepts reg, "sys:" `isPrefixOf` c ]
        length own `shouldSatisfy` (< 20)

    it "keeps a relation for symbol provenance" $ do
        reg <- loadEcosystem
        map relName (relations reg) `shouldContain` ["sys:definedIn"]

    it "has one instance per symbol in the data file, with a repository" $ do
        ttl <- readFile "test/fixtures/ecosystem_symbols.ttl"
        let symbols = length (filter ("a sys:CodeSymbol" `isInfixOf`) (lines ttl))
            provenance = length (filter ("sys:definedIn" `isInfixOf`) (lines ttl))
        symbols `shouldSatisfy` (> 0)
        provenance `shouldBe` symbols

    it "reports the same count in the file header as it contains" $ do
        ttl <- readFile "test/fixtures/ecosystem_symbols.ttl"
        let symbols = length (filter ("a sys:CodeSymbol" `isInfixOf`) (lines ttl))
            header = [ w | l <- lines ttl, "# symbols:" `isPrefixOf` l
                         , w <- words l, not (null w), all (`elem` "0123456789") w ]
        header `shouldBe` [show symbols]

    describe "morphisms-bfo-ext-domains plant topology alignment" $ do
        let plantPath = "examples/bfo_morphisms_plant.logic"

        it "loads, lints, and validates taxonomy hierarchy" $ do
            loaded <- loadRegistryWithImports plantPath
            case loaded of
                Left err  -> expectationFailure err
                Right reg -> do
                    lookup "CriticalBoiler" (concepts reg) `shouldBe` Just (Just "Boiler")
                    lookup "Boiler" (concepts reg) `shouldBe` Just (Just "PlantEquipment")
                    lookup "PlantEquipment" (concepts reg) `shouldBe` Just (Just "PlantEntity")
                    lookup "PlantEntity" (concepts reg) `shouldBe` Just (Just "MaterialEntity")
                    let rNames = map relName (relations reg)
                    mapM_ (\r -> rNames `shouldSatisfy` elem r) ["is_fed_by", "feeds_critical", "measures"]

        it "verifies SMT satisfiability without empty concepts" $ do
            loaded <- loadRegistryWithImports plantPath
            case loaded of
                Left err  -> expectationFailure err
                Right reg -> do
                    res <- checkConsistencyWith AutoProver reg
                    case res of
                        Sat _ -> return ()
                        other -> expectationFailure $ "Expected Sat but got: " ++ show other
