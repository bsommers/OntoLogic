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
MERGE (n:OntologyClass {name: 'Farm'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Field'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ArableField'})
MERGE (p:OntologyClass {name: 'Field'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pasture'})
MERGE (p:OntologyClass {name: 'Field'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Orchard'})
MERGE (p:OntologyClass {name: 'Field'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Greenhouse'})
MERGE (p:OntologyClass {name: 'Field'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Paddock'})
MERGE (p:OntologyClass {name: 'Field'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Barn'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MilkingParlour'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GrainSilo'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WaterSource'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Borehole'})
MERGE (p:OntologyClass {name: 'WaterSource'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Reservoir'})
MERGE (p:OntologyClass {name: 'WaterSource'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Farmer'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FarmHand'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Agronomist'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Veterinarian'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Inspector'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Plant'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Crop'})
MERGE (p:OntologyClass {name: 'Plant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CerealCrop'})
MERGE (p:OntologyClass {name: 'Crop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Wheat'})
MERGE (p:OntologyClass {name: 'CerealCrop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Maize'})
MERGE (p:OntologyClass {name: 'CerealCrop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Barley'})
MERGE (p:OntologyClass {name: 'CerealCrop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LegumeCrop'})
MERGE (p:OntologyClass {name: 'Crop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Soybean'})
MERGE (p:OntologyClass {name: 'LegumeCrop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VegetableCrop'})
MERGE (p:OntologyClass {name: 'Crop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tomato'})
MERGE (p:OntologyClass {name: 'VegetableCrop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FruitCrop'})
MERGE (p:OntologyClass {name: 'Crop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Apple'})
MERGE (p:OntologyClass {name: 'FruitCrop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CoverCrop'})
MERGE (p:OntologyClass {name: 'Crop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Weed'})
MERGE (p:OntologyClass {name: 'Plant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pest'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CropDisease'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Animal'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Livestock'})
MERGE (p:OntologyClass {name: 'Animal'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Cattle'})
MERGE (p:OntologyClass {name: 'Livestock'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DairyCow'})
MERGE (p:OntologyClass {name: 'Cattle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BeefCattle'})
MERGE (p:OntologyClass {name: 'Cattle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sheep'})
MERGE (p:OntologyClass {name: 'Livestock'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pig'})
MERGE (p:OntologyClass {name: 'Livestock'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Poultry'})
MERGE (p:OntologyClass {name: 'Livestock'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Herd'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Flock'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Feed'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VeterinaryTreatment'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Vaccination'})
MERGE (p:OntologyClass {name: 'VeterinaryTreatment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AntibioticTreatment'})
MERGE (p:OntologyClass {name: 'VeterinaryTreatment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Quarantine'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IrrigationSystem'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DripIrrigation'})
MERGE (p:OntologyClass {name: 'IrrigationSystem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PivotIrrigation'})
MERGE (p:OntologyClass {name: 'IrrigationSystem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sprinkler'})
MERGE (p:OntologyClass {name: 'IrrigationSystem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pump'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Valve'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sensor'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SoilSensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MoistureSensor'})
MERGE (p:OntologyClass {name: 'SoilSensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PhSensor'})
MERGE (p:OntologyClass {name: 'SoilSensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NitrogenSensor'})
MERGE (p:OntologyClass {name: 'SoilSensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WeatherStation'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SensorReading'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Soil'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Fertilizer'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pesticide'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FarmOperation'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Planting'})
MERGE (p:OntologyClass {name: 'FarmOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Irrigating'})
MERGE (p:OntologyClass {name: 'FarmOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Fertilizing'})
MERGE (p:OntologyClass {name: 'FarmOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Spraying'})
MERGE (p:OntologyClass {name: 'FarmOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Harvesting'})
MERGE (p:OntologyClass {name: 'FarmOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Milking'})
MERGE (p:OntologyClass {name: 'FarmOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Grazing'})
MERGE (p:OntologyClass {name: 'FarmOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Harvest'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GrainHarvest'})
MERGE (p:OntologyClass {name: 'Harvest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FruitHarvest'})
MERGE (p:OntologyClass {name: 'Harvest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HarvestLot'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FieldRecord'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Farmer'})
MERGE (t:OntologyClass {name: 'Farm'})
MERGE (s)-[:RELATION {name: 'owns'}]->(t);
MERGE (s:OntologyClass {name: 'Field'})
MERGE (t:OntologyClass {name: 'Farm'})
MERGE (s)-[:RELATION {name: 'part_of'}]->(t);
MERGE (s:OntologyClass {name: 'Field'})
MERGE (t:OntologyClass {name: 'Crop'})
MERGE (s)-[:RELATION {name: 'planted_with'}]->(t);
MERGE (s:OntologyClass {name: 'IrrigationSystem'})
MERGE (t:OntologyClass {name: 'Field'})
MERGE (s)-[:RELATION {name: 'irrigates'}]->(t);
MERGE (s:OntologyClass {name: 'IrrigationSystem'})
MERGE (t:OntologyClass {name: 'WaterSource'})
MERGE (s)-[:RELATION {name: 'supplied_by'}]->(t);
MERGE (s:OntologyClass {name: 'IrrigationSystem'})
MERGE (t:OntologyClass {name: 'Pump'})
MERGE (s)-[:RELATION {name: 'powered_by'}]->(t);
MERGE (s:OntologyClass {name: 'Valve'})
MERGE (t:OntologyClass {name: 'IrrigationSystem'})
MERGE (s)-[:RELATION {name: 'controls'}]->(t);
MERGE (s:OntologyClass {name: 'SoilSensor'})
MERGE (t:OntologyClass {name: 'Field'})
MERGE (s)-[:RELATION {name: 'installed_in'}]->(t);
MERGE (s:OntologyClass {name: 'SensorReading'})
MERGE (t:OntologyClass {name: 'SoilSensor'})
MERGE (s)-[:RELATION {name: 'measures'}]->(t);
MERGE (s:OntologyClass {name: 'Herd'})
MERGE (t:OntologyClass {name: 'Paddock'})
MERGE (s)-[:RELATION {name: 'grazes'}]->(t);
MERGE (s:OntologyClass {name: 'Livestock'})
MERGE (t:OntologyClass {name: 'Herd'})
MERGE (s)-[:RELATION {name: 'member_of'}]->(t);
MERGE (s:OntologyClass {name: 'Livestock'})
MERGE (t:OntologyClass {name: 'Feed'})
MERGE (s)-[:RELATION {name: 'fed_with'}]->(t);
MERGE (s:OntologyClass {name: 'Livestock'})
MERGE (t:OntologyClass {name: 'VeterinaryTreatment'})
MERGE (s)-[:RELATION {name: 'treated_with'}]->(t);
MERGE (s:OntologyClass {name: 'VeterinaryTreatment'})
MERGE (t:OntologyClass {name: 'Veterinarian'})
MERGE (s)-[:RELATION {name: 'administered_by'}]->(t);
MERGE (s:OntologyClass {name: 'Harvest'})
MERGE (t:OntologyClass {name: 'Field'})
MERGE (s)-[:RELATION {name: 'harvested_from'}]->(t);
MERGE (s:OntologyClass {name: 'Harvest'})
MERGE (t:OntologyClass {name: 'HarvestLot'})
MERGE (s)-[:RELATION {name: 'yields'}]->(t);
MERGE (s:OntologyClass {name: 'Field'})
MERGE (t:OntologyClass {name: 'Agronomist'})
MERGE (s)-[:RELATION {name: 'advised_by'}]->(t);
MERGE (s:OntologyClass {name: 'Pest'})
MERGE (t:OntologyClass {name: 'Crop'})
MERGE (s)-[:RELATION {name: 'threatens'}]->(t);
MERGE (s:OntologyClass {name: 'CropDisease'})
MERGE (t:OntologyClass {name: 'Crop'})
MERGE (s)-[:RELATION {name: 'affects'}]->(t);
MERGE (s:OntologyClass {name: 'Fertilizer'})
MERGE (t:OntologyClass {name: 'Field'})
MERGE (s)-[:RELATION {name: 'applied_to'}]->(t);
MERGE (s:OntologyClass {name: 'Livestock'})
MERGE (t:OntologyClass {name: 'Barn'})
MERGE (s)-[:RELATION {name: 'housed_in'}]->(t);
// Axiom Validations
// Axiom validation: Paddock stocking_density lte 40
MATCH (n:`Paddock`) WHERE NOT (n.`stocking_density` <= 40) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Reservoir tank_level_percent gte 0
MATCH (n:`Reservoir`) WHERE NOT (n.`tank_level_percent` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Reservoir tank_level_percent lte 100
MATCH (n:`Reservoir`) WHERE NOT (n.`tank_level_percent` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: AntibioticTreatment withdrawal_days gte 7
MATCH (n:`AntibioticTreatment`) WHERE NOT (n.`withdrawal_days` >= 7) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: MoistureSensor soil_moisture_percent gte 0
MATCH (n:`MoistureSensor`) WHERE NOT (n.`soil_moisture_percent` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: MoistureSensor soil_moisture_percent lte 100
MATCH (n:`MoistureSensor`) WHERE NOT (n.`soil_moisture_percent` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: PhSensor soil_ph gte 3
MATCH (n:`PhSensor`) WHERE NOT (n.`soil_ph` >= 3) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: PhSensor soil_ph lte 10
MATCH (n:`PhSensor`) WHERE NOT (n.`soil_ph` <= 10) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: HarvestLot has_traceability_lot eq True
MATCH (n:`HarvestLot`) WHERE NOT (n.`has_traceability_lot` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall x (not Crop(x) and Livestock(x))
//   forall x (not Crop(x) and Weed(x))
//   forall x (not Fertilizer(x) and Pesticide(x))
//   forall x (not Farmer(x) and Inspector(x))
//   forall s (MoistureSensor(s) and lt(soil_moisture_percent, 20) implies exists i (IrrigationSystem(i)))
//   forall a (Livestock(a) and in_quarantine = True implies sold_for_slaughter = False)
//   forall s (Spraying(s) and pesticide_applied = True implies gte(days_before_harvest, 14))
