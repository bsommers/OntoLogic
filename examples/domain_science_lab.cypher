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
MERGE (n:OntologyClass {name: 'Sample'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BiologicalSample'})
MERGE (p:OntologyClass {name: 'Sample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BloodSample'})
MERGE (p:OntologyClass {name: 'BiologicalSample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TissueSample'})
MERGE (p:OntologyClass {name: 'BiologicalSample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CellCulture'})
MERGE (p:OntologyClass {name: 'BiologicalSample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EnvironmentalSample'})
MERGE (p:OntologyClass {name: 'Sample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WaterSample'})
MERGE (p:OntologyClass {name: 'EnvironmentalSample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SoilSample'})
MERGE (p:OntologyClass {name: 'EnvironmentalSample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChemicalSample'})
MERGE (p:OntologyClass {name: 'Sample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Aliquot'})
MERGE (p:OntologyClass {name: 'Sample'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReferenceMaterial'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CertifiedReferenceMaterial'})
MERGE (p:OntologyClass {name: 'ReferenceMaterial'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Reagent'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Solvent'})
MERGE (p:OntologyClass {name: 'Reagent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Buffer'})
MERGE (p:OntologyClass {name: 'Reagent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Container'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SampleVial'})
MERGE (p:OntologyClass {name: 'Container'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StorageUnit'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Freezer'})
MERGE (p:OntologyClass {name: 'StorageUnit'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ColdRoom'})
MERGE (p:OntologyClass {name: 'StorageUnit'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Incubator'})
MERGE (p:OntologyClass {name: 'StorageUnit'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Instrument'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Spectrometer'})
MERGE (p:OntologyClass {name: 'Instrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MassSpectrometer'})
MERGE (p:OntologyClass {name: 'Spectrometer'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Chromatograph'})
MERGE (p:OntologyClass {name: 'Instrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Microscope'})
MERGE (p:OntologyClass {name: 'Instrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Centrifuge'})
MERGE (p:OntologyClass {name: 'Instrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AnalyticalBalance'})
MERGE (p:OntologyClass {name: 'Instrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PCRThermocycler'})
MERGE (p:OntologyClass {name: 'Instrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sensor'})
MERGE (p:OntologyClass {name: 'Instrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TemperatureProbe'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Laboratory'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CleanRoom'})
MERGE (p:OntologyClass {name: 'Laboratory'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BiosafetyLab'})
MERGE (p:OntologyClass {name: 'Laboratory'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LabTechnician'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PrincipalScientist'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'QualityManager'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustodyHolder'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Analyst'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Protocol'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StandardOperatingProcedure'})
MERGE (p:OntologyClass {name: 'Protocol'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AnalyticalMethod'})
MERGE (p:OntologyClass {name: 'Protocol'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CalibrationCertificate'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Measurement'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RawMeasurement'})
MERGE (p:OntologyClass {name: 'Measurement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DerivedMeasurement'})
MERGE (p:OntologyClass {name: 'Measurement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DatasetRecord'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LabNotebookEntry'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustodyRecord'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyDataSheet'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Deviation'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LabProcess'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Experiment'})
MERGE (p:OntologyClass {name: 'LabProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlExperiment'})
MERGE (p:OntologyClass {name: 'Experiment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Replicate'})
MERGE (p:OntologyClass {name: 'Experiment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SamplePreparation'})
MERGE (p:OntologyClass {name: 'LabProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Extraction'})
MERGE (p:OntologyClass {name: 'SamplePreparation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Dilution'})
MERGE (p:OntologyClass {name: 'SamplePreparation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Calibration'})
MERGE (p:OntologyClass {name: 'LabProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MeasurementProcess'})
MERGE (p:OntologyClass {name: 'LabProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustodyTransfer'})
MERGE (p:OntologyClass {name: 'LabProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Disposal'})
MERGE (p:OntologyClass {name: 'LabProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'QualityAudit'})
MERGE (p:OntologyClass {name: 'LabProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Aliquot'})
MERGE (t:OntologyClass {name: 'Sample'})
MERGE (s)-[:RELATION {name: 'derived_from'}]->(t);
MERGE (s:OntologyClass {name: 'Sample'})
MERGE (t:OntologyClass {name: 'StorageUnit'})
MERGE (s)-[:RELATION {name: 'stored_in'}]->(t);
MERGE (s:OntologyClass {name: 'Sample'})
MERGE (t:OntologyClass {name: 'Container'})
MERGE (s)-[:RELATION {name: 'held_in'}]->(t);
MERGE (s:OntologyClass {name: 'Measurement'})
MERGE (t:OntologyClass {name: 'Instrument'})
MERGE (s)-[:RELATION {name: 'measured_by'}]->(t);
MERGE (s:OntologyClass {name: 'Measurement'})
MERGE (t:OntologyClass {name: 'Sample'})
MERGE (s)-[:RELATION {name: 'measures'}]->(t);
MERGE (s:OntologyClass {name: 'MeasurementProcess'})
MERGE (t:OntologyClass {name: 'Laboratory'})
MERGE (s)-[:RELATION {name: 'performed_in'}]->(t);
MERGE (s:OntologyClass {name: 'Experiment'})
MERGE (t:OntologyClass {name: 'Protocol'})
MERGE (s)-[:RELATION {name: 'follows_protocol'}]->(t);
MERGE (s:OntologyClass {name: 'Experiment'})
MERGE (t:OntologyClass {name: 'Sample'})
MERGE (s)-[:RELATION {name: 'uses_sample'}]->(t);
MERGE (s:OntologyClass {name: 'Experiment'})
MERGE (t:OntologyClass {name: 'Instrument'})
MERGE (s)-[:RELATION {name: 'uses_instrument'}]->(t);
MERGE (s:OntologyClass {name: 'Experiment'})
MERGE (t:OntologyClass {name: 'Measurement'})
MERGE (s)-[:RELATION {name: 'produces_measurement'}]->(t);
MERGE (s:OntologyClass {name: 'Instrument'})
MERGE (t:OntologyClass {name: 'CalibrationCertificate'})
MERGE (s)-[:RELATION {name: 'calibrated_by'}]->(t);
MERGE (s:OntologyClass {name: 'Calibration'})
MERGE (t:OntologyClass {name: 'Instrument'})
MERGE (s)-[:RELATION {name: 'calibration_of'}]->(t);
MERGE (s:OntologyClass {name: 'Calibration'})
MERGE (t:OntologyClass {name: 'ReferenceMaterial'})
MERGE (s)-[:RELATION {name: 'uses_reference'}]->(t);
MERGE (s:OntologyClass {name: 'CustodyRecord'})
MERGE (t:OntologyClass {name: 'Sample'})
MERGE (s)-[:RELATION {name: 'custody_of'}]->(t);
MERGE (s:OntologyClass {name: 'CustodyTransfer'})
MERGE (t:OntologyClass {name: 'Person'})
MERGE (s)-[:RELATION {name: 'released_by'}]->(t);
MERGE (s:OntologyClass {name: 'CustodyTransfer'})
MERGE (t:OntologyClass {name: 'Person'})
MERGE (s)-[:RELATION {name: 'received_by'}]->(t);
MERGE (s:OntologyClass {name: 'CustodyTransfer'})
MERGE (t:OntologyClass {name: 'Sample'})
MERGE (s)-[:RELATION {name: 'transfers'}]->(t);
MERGE (s:OntologyClass {name: 'CustodyTransfer'})
MERGE (t:OntologyClass {name: 'CustodyRecord'})
MERGE (s)-[:RELATION {name: 'recorded_in'}]->(t);
MERGE (s:OntologyClass {name: 'LabProcess'})
MERGE (t:OntologyClass {name: 'Person'})
MERGE (s)-[:RELATION {name: 'performed_by'}]->(t);
MERGE (s:OntologyClass {name: 'Experiment'})
MERGE (t:OntologyClass {name: 'LabNotebookEntry'})
MERGE (s)-[:RELATION {name: 'documented_in'}]->(t);
MERGE (s:OntologyClass {name: 'Deviation'})
MERGE (t:OntologyClass {name: 'Protocol'})
MERGE (s)-[:RELATION {name: 'deviates_from'}]->(t);
MERGE (s:OntologyClass {name: 'Sample'})
MERGE (t:OntologyClass {name: 'SafetyDataSheet'})
MERGE (s)-[:RELATION {name: 'handled_under'}]->(t);
// Axiom Validations
// Axiom validation: BiologicalSample storage_temp_c gte -196
MATCH (n:`BiologicalSample`) WHERE NOT (n.`storage_temp_c` >= -196) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: BiologicalSample storage_temp_c lte 40
MATCH (n:`BiologicalSample`) WHERE NOT (n.`storage_temp_c` <= 40) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Measurement uncertainty_percent gte 0
MATCH (n:`Measurement`) WHERE NOT (n.`uncertainty_percent` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Measurement uncertainty_percent lte 100
MATCH (n:`Measurement`) WHERE NOT (n.`uncertainty_percent` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: CustodyRecord custody_gap eq False
MATCH (n:`CustodyRecord`) WHERE NOT (n.`custody_gap` = false) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall m (forall i (Measurement(m) and measured_by(m, i) implies calibration_valid = True))
//   forall i (Instrument(i) and gt(days_since_calibration, 365) implies calibration_valid = False)
//   forall e (forall p (Experiment(e) and follows_protocol(e, p) implies protocol_approved = True))
//   forall t (CustodyTransfer(t) implies exists r (recorded_in(t, r)))
//   forall s (Sample(s) and is_biohazard = True implies exists d (handled_under(s, d)))
//   forall e (Experiment(e) and experiment_complete = True implies gte(replicate_count, 3))
//   forall e (forall s (Experiment(e) and uses_sample(e, s) implies is_expired = False))
//   forall s (Sample(s) and is_disposed = True implies volume_ml = 0)
//   forall x (not Sample(x) and Instrument(x))
//   forall x (not Measurement(x) and Protocol(x))
