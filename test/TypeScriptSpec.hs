module TypeScriptSpec (spec) where

import Test.Hspec
import OntoLogic
import Emitters.TypeScript (emitTypeScript)

spec :: Spec
spec = describe "TypeScript / Zod Emitter" $ do
    it "generates basic Zod schemas and TypeScript type aliases" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing)]
                , properties = [Property "speed" "Vehicle" PTInteger]
                , axioms = [ForAll "v" (Implies (Predicate "Vehicle" [Var "v"])
                                               (And (Predicate "gte" [Var "speed", Constant "0"])
                                                    (Predicate "lte" [Var "speed", Constant "120"])))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            tsCode = emitTypeScript reg
        tsCode `shouldContain` "import { z } from \"zod\";"
        tsCode `shouldContain` "export const VehicleSchema = z.object({"
        tsCode `shouldContain` "speed: z.number().int().gte(0).lte(120)"
        tsCode `shouldContain` "export type Vehicle = z.infer<typeof VehicleSchema>;"

    it "handles inheritance via Zod .extend() chaining" $ do
        let reg = emptyRegistry
                { concepts = [("Vehicle", Nothing), ("Car", Just "Vehicle")]
                , properties = [ Property "speed" "Vehicle" PTInteger
                               , Property "doors" "Car" PTInteger
                               ]
                , axioms = [ ForAll "v" (Implies (Predicate "Vehicle" [Var "v"]) (Predicate "gte" [Var "speed", Constant "0"]))
                           , ForAll "c" (Implies (Predicate "Car" [Var "c"]) (Predicate "gte" [Var "doors", Constant "2"]))
                           ]
                , relations = []
                , namespaces = []
                , imports = []
                }
            tsCode = emitTypeScript reg
        tsCode `shouldContain` "export const CarSchema = VehicleSchema.extend({"
        tsCode `shouldContain` "doors: z.number().int().gte(2)"
        tsCode `shouldContain` "export type Car = z.infer<typeof CarSchema>;"

    it "keeps an inherited constrained property in the subclass schema (#25)" $ do
        let reg = emptyRegistry
                { concepts = [("Vessel", Nothing), ("Tank", Just "Vessel"), ("FuelTank", Just "Tank")]
                , properties = [Property "capacity" "Vessel" PTInteger]
                , axioms = [ForAll "x" (Implies (Predicate "FuelTank" [Var "x"])
                                               (Predicate "gt" [Var "capacity", Constant "100"]))]
                , relations = []
                , namespaces = []
                , imports = []
                }
            tsCode = emitTypeScript reg
        -- The bound is declared two levels above FuelTank, so the subclass schema has to
        -- re-state the property for .extend() to narrow it.
        tsCode `shouldContain` "export const FuelTankSchema = TankSchema.extend({"
        tsCode `shouldContain` "capacity: z.number().int().gt(100)"

    it "emits .refine() for conditional constraints" $ do
        let reg = emptyRegistry
                { concepts = [("Oven", Nothing)]
                , properties = [ Property "temperature" "Oven" PTInteger
                               , Property "is_active" "Oven" PTBoolean
                               ]
                , axioms = [ ForAll "o" (Implies (And (Predicate "Oven" [Var "o"])
                                                      (Predicate "eq" [Var "is_active", Constant "True"]))
                                                 (Predicate "gt" [Var "temperature", Constant "100"]))
                           ]
                , relations = []
                , namespaces = []
                , imports = []
                }
            tsCode = emitTypeScript reg
        tsCode `shouldContain` ".refine((data: any) => {"
        tsCode `shouldContain` "if ((data.is_active === true)) {"
        tsCode `shouldContain` "return (data.temperature > 100);"
        tsCode `shouldContain` "return true;"

    it "emits z.lazy with ZodTypeAny for cyclic self-references and standard lazy for non-cyclic" $ do
        let reg = emptyRegistry
                { concepts = [("Node", Nothing), ("Leaf", Nothing)]
                , properties = [ Property "parent" "Node" (PTCustom "Node")
                               , Property "leaf" "Node" (PTCustom "Leaf")
                               ]
                }
            tsCode = emitTypeScript reg
        tsCode `shouldContain` "z.lazy((): z.ZodTypeAny => NodeSchema)"
        tsCode `shouldContain` "z.lazy(() => LeafSchema)"

    it "handles array cardinalities, defaults, and OpEq bound refinements" $ do
        let reg = emptyRegistry
                { concepts = [("Config", Nothing)]
                , properties = [ PropertyDef "tags" "Config" PTString CardOneOrMore Nothing
                               , PropertyDef "flag" "Config" PTBoolean CardZeroOrOne (Just "True")
                               , PropertyDef "name" "Config" PTString CardDefault (Just "app")
                               , Property "version" "Config" PTInteger
                               ]
                , axioms = [ ForAll "c" (Implies (Predicate "Config" [Var "c"])
                                                 (Predicate "eq" [Var "version", Constant "2"]))
                           ]
                }
            tsCode = emitTypeScript reg
        tsCode `shouldContain` "tags: z.array(z.string()).nonempty(),"
        tsCode `shouldContain` "flag: z.boolean().optional().default(true),"
        tsCode `shouldContain` "name: z.string().default(\"app\"),"
        tsCode `shouldContain` ".refine((val) => val === 2, { message: \"Must equal 2\" })"
