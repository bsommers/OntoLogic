// Nodes and Hierarchy
MERGE (n:OntologyClass {name: 'Asset'});
MERGE (n:OntologyClass {name: 'Vehicle'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SUV'})
MERGE (p:OntologyClass {name: 'Vehicle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sedan'})
MERGE (p:OntologyClass {name: 'Vehicle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Truck'})
MERGE (p:OntologyClass {name: 'Vehicle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Equipment'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Station'})
MERGE (p:OntologyClass {name: 'Equipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Robot'})
MERGE (p:OntologyClass {name: 'Equipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WeldingRobot'})
MERGE (p:OntologyClass {name: 'Robot'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PaintingRobot'})
MERGE (p:OntologyClass {name: 'Robot'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AssemblyRobot'})
MERGE (p:OntologyClass {name: 'Robot'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Scanner'})
MERGE (p:OntologyClass {name: 'Equipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OpticalScanner'})
MERGE (p:OntologyClass {name: 'Scanner'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LaserScanner'})
MERGE (p:OntologyClass {name: 'Scanner'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BluewristScanner'})
MERGE (p:OntologyClass {name: 'LaserScanner'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetySystem'})
MERGE (p:OntologyClass {name: 'Equipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LightCurtain'})
MERGE (p:OntologyClass {name: 'SafetySystem'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Axiom Validations
// Axiom validation: SUV weld_count gte 5000
MATCH (n:`SUV`) WHERE NOT (n.`weld_count` >= 5000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Sedan weld_count gte 3000
MATCH (n:`Sedan`) WHERE NOT (n.`weld_count` >= 3000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: BluewristScanner scan_resolution_microns lt 50
MATCH (n:`BluewristScanner`) WHERE NOT (n.`scan_resolution_microns` < 50) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall v (Vehicle(v) and is_painted() implies not paint_color = None)
//   forall r (Robot(r) and is_active() implies exists s (LightCurtain(s) and barrier_active = True))
//   forall w (WeldingRobot(w) and gt(temperature, 200) implies is_active = False)
//   forall s (BluewristScanner(s) and defect_detected = True implies forall v (not is_quality_approved = True))
