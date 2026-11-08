// Nodes and Hierarchy
MERGE (n:OntologyClass {name: 'Entity'});
MERGE (n:OntologyClass {name: 'Continuant'})
MERGE (p:OntologyClass {name: 'Entity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IndependentContinuant'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MaterialEntity'})
MERGE (p:OntologyClass {name: 'IndependentContinuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Object'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Agent'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Site'})
MERGE (p:OntologyClass {name: 'IndependentContinuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Occurrent'})
MERGE (p:OntologyClass {name: 'Entity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Process'})
MERGE (p:OntologyClass {name: 'Occurrent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Role'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Function'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Quality'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InformationContentEntity'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Guest'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'KitchenStaff'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Chef'})
MERGE (p:OntologyClass {name: 'KitchenStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SousChef'})
MERGE (p:OntologyClass {name: 'Chef'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LineCook'})
MERGE (p:OntologyClass {name: 'KitchenStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Dishwasher'})
MERGE (p:OntologyClass {name: 'KitchenStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FrontOfHouseStaff'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Server'})
MERGE (p:OntologyClass {name: 'FrontOfHouseStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Host'})
MERGE (p:OntologyClass {name: 'FrontOfHouseStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Manager'})
MERGE (p:OntologyClass {name: 'FrontOfHouseStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FoodSafetyOfficer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Restaurant'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DiningRoom'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Kitchen'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Station'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GrillStation'})
MERGE (p:OntologyClass {name: 'Station'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FryStation'})
MERGE (p:OntologyClass {name: 'Station'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SaladStation'})
MERGE (p:OntologyClass {name: 'Station'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PastryStation'})
MERGE (p:OntologyClass {name: 'Station'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AllergenFreeStation'})
MERGE (p:OntologyClass {name: 'Station'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ColdStorage'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WalkInFridge'})
MERGE (p:OntologyClass {name: 'ColdStorage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Freezer'})
MERGE (p:OntologyClass {name: 'ColdStorage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DryStorage'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HotHoldingUnit'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Ingredient'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Meat'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Poultry'})
MERGE (p:OntologyClass {name: 'Meat'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Seafood'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Produce'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Dairy'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Grain'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Egg'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Nut'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Spice'})
MERGE (p:OntologyClass {name: 'Ingredient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Allergen'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PeanutAllergen'})
MERGE (p:OntologyClass {name: 'Allergen'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GlutenAllergen'})
MERGE (p:OntologyClass {name: 'Allergen'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MilkAllergen'})
MERGE (p:OntologyClass {name: 'Allergen'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ShellfishAllergen'})
MERGE (p:OntologyClass {name: 'Allergen'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EggAllergen'})
MERGE (p:OntologyClass {name: 'Allergen'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SesameAllergen'})
MERGE (p:OntologyClass {name: 'Allergen'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MenuItem'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Appetizer'})
MERGE (p:OntologyClass {name: 'MenuItem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MainCourse'})
MERGE (p:OntologyClass {name: 'MenuItem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Dessert'})
MERGE (p:OntologyClass {name: 'MenuItem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Beverage'})
MERGE (p:OntologyClass {name: 'MenuItem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VegetarianItem'})
MERGE (p:OntologyClass {name: 'MenuItem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VeganItem'})
MERGE (p:OntologyClass {name: 'VegetarianItem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Menu'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Recipe'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AllergenLabel'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Order'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DineInOrder'})
MERGE (p:OntologyClass {name: 'Order'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TakeawayOrder'})
MERGE (p:OntologyClass {name: 'Order'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DeliveryOrder'})
MERGE (p:OntologyClass {name: 'Order'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OrderLine'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AllergyNote'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'KitchenTicket'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Payment'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PreparationProcess'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Cooking'})
MERGE (p:OntologyClass {name: 'PreparationProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Chilling'})
MERGE (p:OntologyClass {name: 'PreparationProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HotHolding'})
MERGE (p:OntologyClass {name: 'PreparationProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Reheating'})
MERGE (p:OntologyClass {name: 'PreparationProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Thawing'})
MERGE (p:OntologyClass {name: 'PreparationProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Plating'})
MERGE (p:OntologyClass {name: 'PreparationProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FoodBatch'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TemperatureLog'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CriticalControlPoint'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CorrectiveAction'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HealthInspection'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'MenuItem'})
MERGE (t:OntologyClass {name: 'Ingredient'})
MERGE (s)-[:RELATION {name: 'contains'}]->(t);
MERGE (s:OntologyClass {name: 'Ingredient'})
MERGE (t:OntologyClass {name: 'Allergen'})
MERGE (s)-[:RELATION {name: 'has_allergen'}]->(t);
MERGE (s:OntologyClass {name: 'AllergenLabel'})
MERGE (t:OntologyClass {name: 'Allergen'})
MERGE (s)-[:RELATION {name: 'lists_allergen'}]->(t);
MERGE (s:OntologyClass {name: 'AllergenLabel'})
MERGE (t:OntologyClass {name: 'MenuItem'})
MERGE (s)-[:RELATION {name: 'labels'}]->(t);
MERGE (s:OntologyClass {name: 'MenuItem'})
MERGE (t:OntologyClass {name: 'Menu'})
MERGE (s)-[:RELATION {name: 'appears_on'}]->(t);
MERGE (s:OntologyClass {name: 'MenuItem'})
MERGE (t:OntologyClass {name: 'Station'})
MERGE (s)-[:RELATION {name: 'prepared_by'}]->(t);
MERGE (s:OntologyClass {name: 'Order'})
MERGE (t:OntologyClass {name: 'OrderLine'})
MERGE (s)-[:RELATION {name: 'has_line'}]->(t);
MERGE (s:OntologyClass {name: 'OrderLine'})
MERGE (t:OntologyClass {name: 'MenuItem'})
MERGE (s)-[:RELATION {name: 'orders'}]->(t);
MERGE (s:OntologyClass {name: 'Order'})
MERGE (t:OntologyClass {name: 'Guest'})
MERGE (s)-[:RELATION {name: 'placed_by'}]->(t);
MERGE (s:OntologyClass {name: 'Order'})
MERGE (t:OntologyClass {name: 'Server'})
MERGE (s)-[:RELATION {name: 'served_by'}]->(t);
MERGE (s:OntologyClass {name: 'KitchenStaff'})
MERGE (t:OntologyClass {name: 'Station'})
MERGE (s)-[:RELATION {name: 'works_at'}]->(t);
MERGE (s:OntologyClass {name: 'FoodBatch'})
MERGE (t:OntologyClass {name: 'ColdStorage'})
MERGE (s)-[:RELATION {name: 'stored_in'}]->(t);
MERGE (s:OntologyClass {name: 'FoodBatch'})
MERGE (t:OntologyClass {name: 'Ingredient'})
MERGE (s)-[:RELATION {name: 'batch_of'}]->(t);
MERGE (s:OntologyClass {name: 'TemperatureLog'})
MERGE (t:OntologyClass {name: 'FoodBatch'})
MERGE (s)-[:RELATION {name: 'records'}]->(t);
MERGE (s:OntologyClass {name: 'CriticalControlPoint'})
MERGE (t:OntologyClass {name: 'Station'})
MERGE (s)-[:RELATION {name: 'monitors'}]->(t);
MERGE (s:OntologyClass {name: 'CriticalControlPoint'})
MERGE (t:OntologyClass {name: 'CorrectiveAction'})
MERGE (s)-[:RELATION {name: 'triggers'}]->(t);
MERGE (s:OntologyClass {name: 'MenuItem'})
MERGE (t:OntologyClass {name: 'Recipe'})
MERGE (s)-[:RELATION {name: 'follows'}]->(t);
// Axiom Validations
// Axiom validation: KitchenStaff food_handler_certified eq True
MATCH (n:`KitchenStaff`) WHERE NOT (n.`food_handler_certified` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: WalkInFridge cold_holding_temp_c lte 5
MATCH (n:`WalkInFridge`) WHERE NOT (n.`cold_holding_temp_c` <= 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Freezer freezer_temp_c lte -18
MATCH (n:`Freezer`) WHERE NOT (n.`freezer_temp_c` <= -18) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: HotHoldingUnit hot_holding_temp_c gte 60
MATCH (n:`HotHoldingUnit`) WHERE NOT (n.`hot_holding_temp_c` >= 60) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Poultry poultry_core_temp_c gte 74
MATCH (n:`Poultry`) WHERE NOT (n.`poultry_core_temp_c` >= 74) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Reheating reheat_temp_c gte 74
MATCH (n:`Reheating`) WHERE NOT (n.`reheat_temp_c` >= 74) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall x (not Guest(x) and KitchenStaff(x))
//   forall x (not Ingredient(x) and Allergen(x))
//   forall x (not Dessert(x) and MainCourse(x))
//   forall b (FoodBatch(b) and gt(hours_in_danger_zone, 4) implies is_discarded = True)
//   forall o (Order(o) and has_allergy_flag = True implies is_allergen_free_prepared = True)
//   forall m (MenuItem(m) and is_available = True implies contains_allergen_declared = True)
