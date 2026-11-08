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
MERGE (n:OntologyClass {name: 'Patient'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PediatricPatient'})
MERGE (p:OntologyClass {name: 'Patient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GeriatricPatient'})
MERGE (p:OntologyClass {name: 'Patient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PregnantPatient'})
MERGE (p:OntologyClass {name: 'Patient'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Clinician'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Physician'})
MERGE (p:OntologyClass {name: 'Clinician'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Surgeon'})
MERGE (p:OntologyClass {name: 'Physician'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Nurse'})
MERGE (p:OntologyClass {name: 'Clinician'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pharmacist'})
MERGE (p:OntologyClass {name: 'Clinician'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Therapist'})
MERGE (p:OntologyClass {name: 'Clinician'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PrescriberRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AttendingRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CareTeam'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Facility'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Hospital'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Clinic'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Ward'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IntensiveCareUnit'})
MERGE (p:OntologyClass {name: 'Ward'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OperatingTheatre'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pharmacy'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Encounter'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InpatientAdmission'})
MERGE (p:OntologyClass {name: 'Encounter'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OutpatientVisit'})
MERGE (p:OntologyClass {name: 'Encounter'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EmergencyVisit'})
MERGE (p:OntologyClass {name: 'Encounter'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TelehealthVisit'})
MERGE (p:OntologyClass {name: 'Encounter'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Procedure'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SurgicalProcedure'})
MERGE (p:OntologyClass {name: 'Procedure'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Administration'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Discharge'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Condition'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Diagnosis'})
MERGE (p:OntologyClass {name: 'Condition'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChronicCondition'})
MERGE (p:OntologyClass {name: 'Diagnosis'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AcuteCondition'})
MERGE (p:OntologyClass {name: 'Diagnosis'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Allergy'})
MERGE (p:OntologyClass {name: 'Condition'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DrugAllergy'})
MERGE (p:OntologyClass {name: 'Allergy'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FoodAllergy'})
MERGE (p:OntologyClass {name: 'Allergy'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Contraindication'})
MERGE (p:OntologyClass {name: 'Condition'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VitalSign'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Observation'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LabResult'})
MERGE (p:OntologyClass {name: 'Observation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ImagingResult'})
MERGE (p:OntologyClass {name: 'Observation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DischargeSummary'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ClinicalNote'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EscalationRecord'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ClinicalOrder'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MedicationOrder'})
MERGE (p:OntologyClass {name: 'ClinicalOrder'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlledSubstanceOrder'})
MERGE (p:OntologyClass {name: 'MedicationOrder'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LabOrder'})
MERGE (p:OntologyClass {name: 'ClinicalOrder'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ImagingOrder'})
MERGE (p:OntologyClass {name: 'ClinicalOrder'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReferralOrder'})
MERGE (p:OntologyClass {name: 'ClinicalOrder'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Medication'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Antibiotic'})
MERGE (p:OntologyClass {name: 'Medication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PenicillinAntibiotic'})
MERGE (p:OntologyClass {name: 'Antibiotic'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Anticoagulant'})
MERGE (p:OntologyClass {name: 'Medication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Analgesic'})
MERGE (p:OntologyClass {name: 'Medication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Opioid'})
MERGE (p:OntologyClass {name: 'Analgesic'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NSAID'})
MERGE (p:OntologyClass {name: 'Analgesic'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ACEInhibitor'})
MERGE (p:OntologyClass {name: 'Medication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ActiveIngredient'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Patient'})
MERGE (t:OntologyClass {name: 'Clinician'})
MERGE (s)-[:RELATION {name: 'treated_by'}]->(t);
MERGE (s:OntologyClass {name: 'Clinician'})
MERGE (t:OntologyClass {name: 'Encounter'})
MERGE (s)-[:RELATION {name: 'attends'}]->(t);
MERGE (s:OntologyClass {name: 'Patient'})
MERGE (t:OntologyClass {name: 'Encounter'})
MERGE (s)-[:RELATION {name: 'subject_of'}]->(t);
MERGE (s:OntologyClass {name: 'Patient'})
MERGE (t:OntologyClass {name: 'Diagnosis'})
MERGE (s)-[:RELATION {name: 'diagnosed_with'}]->(t);
MERGE (s:OntologyClass {name: 'Patient'})
MERGE (t:OntologyClass {name: 'Allergy'})
MERGE (s)-[:RELATION {name: 'has_allergy'}]->(t);
MERGE (s:OntologyClass {name: 'Clinician'})
MERGE (t:OntologyClass {name: 'MedicationOrder'})
MERGE (s)-[:RELATION {name: 'prescribes'}]->(t);
MERGE (s:OntologyClass {name: 'MedicationOrder'})
MERGE (t:OntologyClass {name: 'Medication'})
MERGE (s)-[:RELATION {name: 'orders_medication'}]->(t);
MERGE (s:OntologyClass {name: 'MedicationOrder'})
MERGE (t:OntologyClass {name: 'Patient'})
MERGE (s)-[:RELATION {name: 'received_by'}]->(t);
MERGE (s:OntologyClass {name: 'Contraindication'})
MERGE (t:OntologyClass {name: 'Medication'})
MERGE (s)-[:RELATION {name: 'contraindicates'}]->(t);
MERGE (s:OntologyClass {name: 'Allergy'})
MERGE (t:OntologyClass {name: 'Medication'})
MERGE (s)-[:RELATION {name: 'triggers_allergy'}]->(t);
MERGE (s:OntologyClass {name: 'Medication'})
MERGE (t:OntologyClass {name: 'ActiveIngredient'})
MERGE (s)-[:RELATION {name: 'has_ingredient'}]->(t);
MERGE (s:OntologyClass {name: 'Clinician'})
MERGE (t:OntologyClass {name: 'CareTeam'})
MERGE (s)-[:RELATION {name: 'member_of'}]->(t);
MERGE (s:OntologyClass {name: 'Encounter'})
MERGE (t:OntologyClass {name: 'Facility'})
MERGE (s)-[:RELATION {name: 'located_in'}]->(t);
MERGE (s:OntologyClass {name: 'LabResult'})
MERGE (t:OntologyClass {name: 'LabOrder'})
MERGE (s)-[:RELATION {name: 'results_from'}]->(t);
// Axiom Validations
// Axiom validation: Patient oxygen_saturation gte 0
MATCH (n:`Patient`) WHERE NOT (n.`oxygen_saturation` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Patient oxygen_saturation lte 100
MATCH (n:`Patient`) WHERE NOT (n.`oxygen_saturation` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Patient heart_rate gte 0
MATCH (n:`Patient`) WHERE NOT (n.`heart_rate` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Patient heart_rate lte 300
MATCH (n:`Patient`) WHERE NOT (n.`heart_rate` <= 300) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Physician is_licensed_prescriber eq True
MATCH (n:`Physician`) WHERE NOT (n.`is_licensed_prescriber` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: EmergencyVisit triage_level gte 1
MATCH (n:`EmergencyVisit`) WHERE NOT (n.`triage_level` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: EmergencyVisit triage_level lte 5
MATCH (n:`EmergencyVisit`) WHERE NOT (n.`triage_level` <= 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Discharge has_summary eq True
MATCH (n:`Discharge`) WHERE NOT (n.`has_summary` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: MedicationOrder is_signed eq True
MATCH (n:`MedicationOrder`) WHERE NOT (n.`is_signed` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: ControlledSubstanceOrder dose_mg gt 0
MATCH (n:`ControlledSubstanceOrder`) WHERE NOT (n.`dose_mg` > 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: ControlledSubstanceOrder dose_mg lte 200
MATCH (n:`ControlledSubstanceOrder`) WHERE NOT (n.`dose_mg` <= 200) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall x (not Patient(x) and Clinician(x))
//   forall x (not ClinicalOrder(x) and Observation(x))
//   forall x (not Medication(x) and ActiveIngredient(x))
//   forall p (forall a (forall m (forall o (has_allergy(p, a) and triggers_allergy(a, m) and orders_medication(o, m) implies not received_by(o, p)))))
//   forall p (Patient(p) and lt(oxygen_saturation, 90) implies exists e (EscalationRecord(e)))
