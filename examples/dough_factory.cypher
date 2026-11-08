// Nodes and Hierarchy
MERGE (n:OntologyClass {name: 'Asset'});
MERGE (n:OntologyClass {name: 'Machine'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sensor'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Mixer'})
MERGE (p:OntologyClass {name: 'Machine'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Oven'})
MERGE (p:OntologyClass {name: 'Machine'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProofingChamber'})
MERGE (p:OntologyClass {name: 'Machine'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CuttingMachine'})
MERGE (p:OntologyClass {name: 'Machine'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BaggingMachine'})
MERGE (p:OntologyClass {name: 'Machine'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PackagingMachine'})
MERGE (p:OntologyClass {name: 'Machine'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Refrigerator'})
MERGE (p:OntologyClass {name: 'Machine'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Camera'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SecurityCamera'})
MERGE (p:OntologyClass {name: 'Camera'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Axiom Validations
// Axiom validation: ProofingChamber humidity gte 60
MATCH (n:`ProofingChamber`) WHERE NOT (n.`humidity` >= 60) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: ProofingChamber humidity lte 90
MATCH (n:`ProofingChamber`) WHERE NOT (n.`humidity` <= 90) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Refrigerator temperature lt 5
MATCH (n:`Refrigerator`) WHERE NOT (n.`temperature` < 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SecurityCamera is_recording eq True
MATCH (n:`SecurityCamera`) WHERE NOT (n.`is_recording` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall o (Oven(o) and is_active() implies gt(temperature, 100))
//   forall m (Mixer(m) and is_active() implies gt(rpm, 0))
