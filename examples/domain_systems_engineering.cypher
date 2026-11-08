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
MERGE (n:OntologyClass {name: 'InformationContentEntity'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Requirement'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StakeholderNeed'})
MERGE (p:OntologyClass {name: 'Requirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SystemRequirement'})
MERGE (p:OntologyClass {name: 'Requirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FunctionalRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PerformanceRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InterfaceRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SecurityRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReliabilityRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConstraintRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DerivedRequirement'})
MERGE (p:OntologyClass {name: 'SystemRequirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ComponentRequirement'})
MERGE (p:OntologyClass {name: 'Requirement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AcceptanceCriterion'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SystemElement'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'System'})
MERGE (p:OntologyClass {name: 'SystemElement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Subsystem'})
MERGE (p:OntologyClass {name: 'SystemElement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Assembly'})
MERGE (p:OntologyClass {name: 'SystemElement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Component'})
MERGE (p:OntologyClass {name: 'SystemElement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HardwareComponent'})
MERGE (p:OntologyClass {name: 'Component'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SoftwareComponent'})
MERGE (p:OntologyClass {name: 'Component'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'COTSComponent'})
MERGE (p:OntologyClass {name: 'Component'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Interface'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ElectricalInterface'})
MERGE (p:OntologyClass {name: 'Interface'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MechanicalInterface'})
MERGE (p:OntologyClass {name: 'Interface'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataInterface'})
MERGE (p:OntologyClass {name: 'Interface'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Port'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DesignArtifact'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ArchitectureModel'})
MERGE (p:OntologyClass {name: 'DesignArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InterfaceControlDocument'})
MERGE (p:OntologyClass {name: 'DesignArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Specification'})
MERGE (p:OntologyClass {name: 'DesignArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Baseline'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FunctionalBaseline'})
MERGE (p:OntologyClass {name: 'Baseline'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AllocatedBaseline'})
MERGE (p:OntologyClass {name: 'Baseline'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProductBaseline'})
MERGE (p:OntologyClass {name: 'Baseline'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VerificationActivity'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Inspection'})
MERGE (p:OntologyClass {name: 'VerificationActivity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Analysis'})
MERGE (p:OntologyClass {name: 'VerificationActivity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Demonstration'})
MERGE (p:OntologyClass {name: 'VerificationActivity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Test'})
MERGE (p:OntologyClass {name: 'VerificationActivity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'UnitTest'})
MERGE (p:OntologyClass {name: 'Test'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IntegrationTest'})
MERGE (p:OntologyClass {name: 'Test'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SystemQualificationTest'})
MERGE (p:OntologyClass {name: 'Test'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ValidationActivity'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VerificationEvidence'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TestProcedure'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TestResult'})
MERGE (p:OntologyClass {name: 'VerificationEvidence'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Nonconformance'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChangeRequest'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EngineeringChangeProposal'})
MERGE (p:OntologyClass {name: 'ChangeRequest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WaiverRequest'})
MERGE (p:OntologyClass {name: 'ChangeRequest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChangeBoard'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChangeImpactAssessment'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChangeImplementation'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Stakeholder'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SystemsEngineer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RequirementOwner'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VerificationEngineer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConfigurationManager'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LifecycleStage'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConceptStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DevelopmentStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProductionStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DesignReview'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TraceabilityLink'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Requirement'})
MERGE (t:OntologyClass {name: 'Requirement'})
MERGE (s)-[:RELATION {name: 'derives_from'}]->(t);
MERGE (s:OntologyClass {name: 'SystemElement'})
MERGE (t:OntologyClass {name: 'Requirement'})
MERGE (s)-[:RELATION {name: 'satisfies'}]->(t);
MERGE (s:OntologyClass {name: 'Requirement'})
MERGE (t:OntologyClass {name: 'SystemElement'})
MERGE (s)-[:RELATION {name: 'allocated_to'}]->(t);
MERGE (s:OntologyClass {name: 'Requirement'})
MERGE (t:OntologyClass {name: 'VerificationActivity'})
MERGE (s)-[:RELATION {name: 'verified_by'}]->(t);
MERGE (s:OntologyClass {name: 'VerificationActivity'})
MERGE (t:OntologyClass {name: 'VerificationEvidence'})
MERGE (s)-[:RELATION {name: 'produces_evidence'}]->(t);
MERGE (s:OntologyClass {name: 'VerificationActivity'})
MERGE (t:OntologyClass {name: 'TestProcedure'})
MERGE (s)-[:RELATION {name: 'uses_procedure'}]->(t);
MERGE (s:OntologyClass {name: 'SystemElement'})
MERGE (t:OntologyClass {name: 'SystemElement'})
MERGE (s)-[:RELATION {name: 'part_of'}]->(t);
MERGE (s:OntologyClass {name: 'Interface'})
MERGE (t:OntologyClass {name: 'Port'})
MERGE (s)-[:RELATION {name: 'connects'}]->(t);
MERGE (s:OntologyClass {name: 'SystemElement'})
MERGE (t:OntologyClass {name: 'Port'})
MERGE (s)-[:RELATION {name: 'exposes'}]->(t);
MERGE (s:OntologyClass {name: 'Interface'})
MERGE (t:OntologyClass {name: 'InterfaceControlDocument'})
MERGE (s)-[:RELATION {name: 'defined_in'}]->(t);
MERGE (s:OntologyClass {name: 'InterfaceRequirement'})
MERGE (t:OntologyClass {name: 'Interface'})
MERGE (s)-[:RELATION {name: 'specifies_interface'}]->(t);
MERGE (s:OntologyClass {name: 'Requirement'})
MERGE (t:OntologyClass {name: 'RequirementOwner'})
MERGE (s)-[:RELATION {name: 'owned_by'}]->(t);
MERGE (s:OntologyClass {name: 'ChangeRequest'})
MERGE (t:OntologyClass {name: 'Requirement'})
MERGE (s)-[:RELATION {name: 'modifies'}]->(t);
MERGE (s:OntologyClass {name: 'ChangeRequest'})
MERGE (t:OntologyClass {name: 'DesignArtifact'})
MERGE (s)-[:RELATION {name: 'modifies_design'}]->(t);
MERGE (s:OntologyClass {name: 'ChangeRequest'})
MERGE (t:OntologyClass {name: 'ChangeImpactAssessment'})
MERGE (s)-[:RELATION {name: 'assessed_by'}]->(t);
MERGE (s:OntologyClass {name: 'ChangeRequest'})
MERGE (t:OntologyClass {name: 'ChangeBoard'})
MERGE (s)-[:RELATION {name: 'decided_by'}]->(t);
MERGE (s:OntologyClass {name: 'TraceabilityLink'})
MERGE (t:OntologyClass {name: 'Requirement'})
MERGE (s)-[:RELATION {name: 'traces_from'}]->(t);
MERGE (s:OntologyClass {name: 'TraceabilityLink'})
MERGE (t:OntologyClass {name: 'SystemElement'})
MERGE (s)-[:RELATION {name: 'traces_to'}]->(t);
MERGE (s:OntologyClass {name: 'Requirement'})
MERGE (t:OntologyClass {name: 'DesignReview'})
MERGE (s)-[:RELATION {name: 'reviewed_in'}]->(t);
MERGE (s:OntologyClass {name: 'Nonconformance'})
MERGE (t:OntologyClass {name: 'VerificationActivity'})
MERGE (s)-[:RELATION {name: 'raised_by'}]->(t);
// Axiom Validations
// Axiom validation: Requirement req_priority gte 1
MATCH (n:`Requirement`) WHERE NOT (n.`req_priority` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Requirement req_priority lte 5
MATCH (n:`Requirement`) WHERE NOT (n.`req_priority` <= 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SafetyRequirement safety_integrity_level gte 1
MATCH (n:`SafetyRequirement`) WHERE NOT (n.`safety_integrity_level` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SafetyRequirement safety_integrity_level lte 4
MATCH (n:`SafetyRequirement`) WHERE NOT (n.`safety_integrity_level` <= 4) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SystemElement mass_kg gte 0
MATCH (n:`SystemElement`) WHERE NOT (n.`mass_kg` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SystemElement mass_kg lte 1000000
MATCH (n:`SystemElement`) WHERE NOT (n.`mass_kg` <= 1000000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Component tech_readiness_level gte 1
MATCH (n:`Component`) WHERE NOT (n.`tech_readiness_level` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Component tech_readiness_level lte 9
MATCH (n:`Component`) WHERE NOT (n.`tech_readiness_level` <= 9) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall r (Requirement(r) and is_approved = True implies is_allocated = True)
//   forall r (Requirement(r) and is_approved = True implies is_testable = True)
//   forall r (Requirement(r) and is_verified = True implies exists v (verified_by(r, v)))
//   forall r (SafetyRequirement(r) and is_approved = True implies hazard_analysis_done = True)
//   forall c (forall d (ChangeRequest(c) and modifies_design(c, d) implies change_approved = True))
//   forall c (ChangeRequest(c) and change_approved = True implies impact_assessed = True)
//   forall i (Interface(i) implies exists p (connects(i, p)))
//   forall x (not Requirement(x) and SystemElement(x))
//   forall x (not VerificationActivity(x) and ChangeImplementation(x))
