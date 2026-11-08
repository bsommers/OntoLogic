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
MERGE (n:OntologyClass {name: 'Facility'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Cleanroom'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Bay'})
MERGE (p:OntologyClass {name: 'Cleanroom'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LithographyBay'})
MERGE (p:OntologyClass {name: 'Bay'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EtchBay'})
MERGE (p:OntologyClass {name: 'Bay'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DiffusionBay'})
MERGE (p:OntologyClass {name: 'Bay'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThinFilmBay'})
MERGE (p:OntologyClass {name: 'Bay'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MetrologyBay'})
MERGE (p:OntologyClass {name: 'Bay'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChemicalMechanicalPolishBay'})
MERGE (p:OntologyClass {name: 'Bay'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ISOClass'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ISOClass3'})
MERGE (p:OntologyClass {name: 'ISOClass'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ISOClass5'})
MERGE (p:OntologyClass {name: 'ISOClass'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ISOClass7'})
MERGE (p:OntologyClass {name: 'ISOClass'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Wafer'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProductWafer'})
MERGE (p:OntologyClass {name: 'Wafer'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MonitorWafer'})
MERGE (p:OntologyClass {name: 'Wafer'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DummyWafer'})
MERGE (p:OntologyClass {name: 'Wafer'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Lot'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProductionLot'})
MERGE (p:OntologyClass {name: 'Lot'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EngineeringLot'})
MERGE (p:OntologyClass {name: 'Lot'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HotLot'})
MERGE (p:OntologyClass {name: 'ProductionLot'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Foup'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Reticle'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Die'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GoodDie'})
MERGE (p:OntologyClass {name: 'Die'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ScrapDie'})
MERGE (p:OntologyClass {name: 'Die'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessChemical'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Photoresist'})
MERGE (p:OntologyClass {name: 'ProcessChemical'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessGas'})
MERGE (p:OntologyClass {name: 'ProcessChemical'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Slurry'})
MERGE (p:OntologyClass {name: 'ProcessChemical'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tool'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessTool'})
MERGE (p:OntologyClass {name: 'Tool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Stepper'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Scanner'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CoaterDeveloper'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PlasmaEtcher'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DiffusionFurnace'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CvdChamber'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PvdChamber'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IonImplanter'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CmpPolisher'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WetBench'})
MERGE (p:OntologyClass {name: 'ProcessTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MetrologyTool'})
MERGE (p:OntologyClass {name: 'Tool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CriticalDimensionSem'})
MERGE (p:OntologyClass {name: 'MetrologyTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OpticalOverlayTool'})
MERGE (p:OntologyClass {name: 'MetrologyTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FilmThicknessGauge'})
MERGE (p:OntologyClass {name: 'MetrologyTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InspectionTool'})
MERGE (p:OntologyClass {name: 'Tool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BrightFieldInspector'})
MERGE (p:OntologyClass {name: 'InspectionTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DarkFieldInspector'})
MERGE (p:OntologyClass {name: 'InspectionTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DefectReviewSem'})
MERGE (p:OntologyClass {name: 'InspectionTool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WaferProber'})
MERGE (p:OntologyClass {name: 'Tool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AutomatedMaterialHandling'})
MERGE (p:OntologyClass {name: 'Tool'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessStep'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Photolithography'})
MERGE (p:OntologyClass {name: 'ProcessStep'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Etch'})
MERGE (p:OntologyClass {name: 'ProcessStep'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Deposition'})
MERGE (p:OntologyClass {name: 'ProcessStep'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Implantation'})
MERGE (p:OntologyClass {name: 'ProcessStep'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Diffusion'})
MERGE (p:OntologyClass {name: 'ProcessStep'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Planarization'})
MERGE (p:OntologyClass {name: 'ProcessStep'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WetClean'})
MERGE (p:OntologyClass {name: 'ProcessStep'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MetrologyStep'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InspectionStep'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ElectricalTest'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Rework'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessFlow'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Layer'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Recipe'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'QualifiedRecipe'})
MERGE (p:OntologyClass {name: 'Recipe'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RecipeParameter'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlPlan'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Measurement'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CriticalDimensionMeasurement'})
MERGE (p:OntologyClass {name: 'Measurement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OverlayMeasurement'})
MERGE (p:OntologyClass {name: 'Measurement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThicknessMeasurement'})
MERGE (p:OntologyClass {name: 'Measurement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Defect'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ParticleDefect'})
MERGE (p:OntologyClass {name: 'Defect'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ScratchDefect'})
MERGE (p:OntologyClass {name: 'Defect'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PatternDefect'})
MERGE (p:OntologyClass {name: 'Defect'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'KillerDefect'})
MERGE (p:OntologyClass {name: 'Defect'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WaferMap'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'YieldReport'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SpcChart'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OutOfControlEvent'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HoldOrder'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessEngineerRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EquipmentTechnicianRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'YieldEngineerRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OperatorRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Lot'})
MERGE (t:OntologyClass {name: 'Wafer'})
MERGE (s)-[:RELATION {name: 'contains_wafer'}]->(t);
MERGE (s:OntologyClass {name: 'Lot'})
MERGE (t:OntologyClass {name: 'Foup'})
MERGE (s)-[:RELATION {name: 'carried_in'}]->(t);
MERGE (s:OntologyClass {name: 'Tool'})
MERGE (t:OntologyClass {name: 'Bay'})
MERGE (s)-[:RELATION {name: 'located_in'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessStep'})
MERGE (t:OntologyClass {name: 'Lot'})
MERGE (s)-[:RELATION {name: 'processes_lot'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessStep'})
MERGE (t:OntologyClass {name: 'Tool'})
MERGE (s)-[:RELATION {name: 'performed_on'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessStep'})
MERGE (t:OntologyClass {name: 'Recipe'})
MERGE (s)-[:RELATION {name: 'uses_recipe'}]->(t);
MERGE (s:OntologyClass {name: 'Recipe'})
MERGE (t:OntologyClass {name: 'RecipeParameter'})
MERGE (s)-[:RELATION {name: 'has_parameter'}]->(t);
MERGE (s:OntologyClass {name: 'Photolithography'})
MERGE (t:OntologyClass {name: 'Reticle'})
MERGE (s)-[:RELATION {name: 'uses_reticle'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessStep'})
MERGE (t:OntologyClass {name: 'Layer'})
MERGE (s)-[:RELATION {name: 'forms_layer'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessStep'})
MERGE (t:OntologyClass {name: 'ProcessStep'})
MERGE (s)-[:RELATION {name: 'follows'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessStep'})
MERGE (t:OntologyClass {name: 'ProcessFlow'})
MERGE (s)-[:RELATION {name: 'part_of_flow'}]->(t);
MERGE (s:OntologyClass {name: 'MetrologyStep'})
MERGE (t:OntologyClass {name: 'Lot'})
MERGE (s)-[:RELATION {name: 'measures'}]->(t);
MERGE (s:OntologyClass {name: 'MetrologyStep'})
MERGE (t:OntologyClass {name: 'MetrologyTool'})
MERGE (s)-[:RELATION {name: 'measured_on'}]->(t);
MERGE (s:OntologyClass {name: 'MetrologyStep'})
MERGE (t:OntologyClass {name: 'Measurement'})
MERGE (s)-[:RELATION {name: 'produces'}]->(t);
MERGE (s:OntologyClass {name: 'InspectionStep'})
MERGE (t:OntologyClass {name: 'Wafer'})
MERGE (s)-[:RELATION {name: 'inspects'}]->(t);
MERGE (s:OntologyClass {name: 'InspectionStep'})
MERGE (t:OntologyClass {name: 'Defect'})
MERGE (s)-[:RELATION {name: 'detects'}]->(t);
MERGE (s:OntologyClass {name: 'Defect'})
MERGE (t:OntologyClass {name: 'Wafer'})
MERGE (s)-[:RELATION {name: 'found_on'}]->(t);
MERGE (s:OntologyClass {name: 'HoldOrder'})
MERGE (t:OntologyClass {name: 'Lot'})
MERGE (s)-[:RELATION {name: 'hold_for'}]->(t);
MERGE (s:OntologyClass {name: 'HoldOrder'})
MERGE (t:OntologyClass {name: 'OutOfControlEvent'})
MERGE (s)-[:RELATION {name: 'triggered_by'}]->(t);
MERGE (s:OntologyClass {name: 'YieldReport'})
MERGE (t:OntologyClass {name: 'Lot'})
MERGE (s)-[:RELATION {name: 'summarises'}]->(t);
MERGE (s:OntologyClass {name: 'WaferMap'})
MERGE (t:OntologyClass {name: 'Wafer'})
MERGE (s)-[:RELATION {name: 'maps'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessStep'})
MERGE (t:OntologyClass {name: 'ControlPlan'})
MERGE (s)-[:RELATION {name: 'governed_by'}]->(t);
// Axiom Validations
// Axiom validation: LithographyBay iso_class_number lte 5
MATCH (n:`LithographyBay`) WHERE NOT (n.`iso_class_number` <= 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Wafer wafer_diameter_mm gte 100
MATCH (n:`Wafer`) WHERE NOT (n.`wafer_diameter_mm` >= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Wafer wafer_diameter_mm lte 450
MATCH (n:`Wafer`) WHERE NOT (n.`wafer_diameter_mm` <= 450) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Wafer die_yield_pct gte 0
MATCH (n:`Wafer`) WHERE NOT (n.`die_yield_pct` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Wafer die_yield_pct lte 100
MATCH (n:`Wafer`) WHERE NOT (n.`die_yield_pct` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Lot wafer_count gte 1
MATCH (n:`Lot`) WHERE NOT (n.`wafer_count` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Lot wafer_count lte 25
MATCH (n:`Lot`) WHERE NOT (n.`wafer_count` <= 25) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Lot rework_count lte 2
MATCH (n:`Lot`) WHERE NOT (n.`rework_count` <= 2) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: ProcessTool is_qualified eq True
MATCH (n:`ProcessTool`) WHERE NOT (n.`is_qualified` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: QualifiedRecipe is_released eq True
MATCH (n:`QualifiedRecipe`) WHERE NOT (n.`is_released` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: KillerDefect is_killer eq True
MATCH (n:`KillerDefect`) WHERE NOT (n.`is_killer` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall s (ProcessStep(s) implies exists r (Recipe(r) and uses_recipe(s, r)))
//   forall p (Photolithography(p) implies exists r (Reticle(r) and uses_reticle(p, r)))
//   forall h (HoldOrder(h) implies exists l (Lot(l) and hold_for(h, l)))
//   forall w (ProductWafer(w) implies not DummyWafer(w))
//   forall t (ProcessTool(t) implies not MetrologyTool(t))
