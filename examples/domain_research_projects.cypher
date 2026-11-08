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
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Organization'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'University'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ResearchInstitute'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FundingAgency'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PublicFunder'})
MERGE (p:OntologyClass {name: 'FundingAgency'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PrivateFoundation'})
MERGE (p:OntologyClass {name: 'FundingAgency'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Publisher'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EthicsCommittee'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Department'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ResearchGroup'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Investigator'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PrincipalInvestigator'})
MERGE (p:OntologyClass {name: 'Investigator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CoInvestigator'})
MERGE (p:OntologyClass {name: 'Investigator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PostdoctoralResearcher'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DoctoralStudent'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ResearchParticipant'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Reviewer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Author'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FundingInstrument'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Grant'})
MERGE (p:OntologyClass {name: 'FundingInstrument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProjectGrant'})
MERGE (p:OntologyClass {name: 'Grant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FellowshipGrant'})
MERGE (p:OntologyClass {name: 'Grant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProposalDocument'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Budget'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BudgetLine'})
MERGE (p:OntologyClass {name: 'Budget'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataManagementPlan'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProgressReport'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FinalReport'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConflictOfInterestDeclaration'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ResearchProject'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Study'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ObservationalStudy'})
MERGE (p:OntologyClass {name: 'Study'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ClinicalTrial'})
MERGE (p:OntologyClass {name: 'Study'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SurveyStudy'})
MERGE (p:OntologyClass {name: 'Study'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ComputationalStudy'})
MERGE (p:OntologyClass {name: 'Study'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HumanSubjectsStudy'})
MERGE (p:OntologyClass {name: 'Study'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Experiment'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Enrolment'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PeerReview'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EthicsReview'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EthicsApproval'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InformedConsent'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StudyProtocol'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PreRegistration'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AdverseEventReport'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Dataset'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RawDataset'})
MERGE (p:OntologyClass {name: 'Dataset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessedDataset'})
MERGE (p:OntologyClass {name: 'Dataset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SensitiveDataset'})
MERGE (p:OntologyClass {name: 'Dataset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OpenDataset'})
MERGE (p:OntologyClass {name: 'Dataset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Metadata'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Codebook'})
MERGE (p:OntologyClass {name: 'Metadata'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Software'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Publication'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'JournalArticle'})
MERGE (p:OntologyClass {name: 'Publication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConferencePaper'})
MERGE (p:OntologyClass {name: 'Publication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Preprint'})
MERGE (p:OntologyClass {name: 'Publication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Thesis'})
MERGE (p:OntologyClass {name: 'Publication'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Citation'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Journal'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Repository'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Grant'})
MERGE (t:OntologyClass {name: 'FundingAgency'})
MERGE (s)-[:RELATION {name: 'awarded_by'}]->(t);
MERGE (s:OntologyClass {name: 'Grant'})
MERGE (t:OntologyClass {name: 'Organization'})
MERGE (s)-[:RELATION {name: 'held_by'}]->(t);
MERGE (s:OntologyClass {name: 'Grant'})
MERGE (t:OntologyClass {name: 'PrincipalInvestigator'})
MERGE (s)-[:RELATION {name: 'led_by'}]->(t);
MERGE (s:OntologyClass {name: 'ResearchProject'})
MERGE (t:OntologyClass {name: 'Grant'})
MERGE (s)-[:RELATION {name: 'funds'}]->(t);
MERGE (s:OntologyClass {name: 'Grant'})
MERGE (t:OntologyClass {name: 'Budget'})
MERGE (s)-[:RELATION {name: 'has_budget'}]->(t);
MERGE (s:OntologyClass {name: 'Budget'})
MERGE (t:OntologyClass {name: 'BudgetLine'})
MERGE (s)-[:RELATION {name: 'includes_line'}]->(t);
MERGE (s:OntologyClass {name: 'ProposalDocument'})
MERGE (t:OntologyClass {name: 'ResearchProject'})
MERGE (s)-[:RELATION {name: 'proposes'}]->(t);
MERGE (s:OntologyClass {name: 'Person'})
MERGE (t:OntologyClass {name: 'Organization'})
MERGE (s)-[:RELATION {name: 'employed_by'}]->(t);
MERGE (s:OntologyClass {name: 'Person'})
MERGE (t:OntologyClass {name: 'ResearchGroup'})
MERGE (s)-[:RELATION {name: 'member_of'}]->(t);
MERGE (s:OntologyClass {name: 'Investigator'})
MERGE (t:OntologyClass {name: 'Study'})
MERGE (s)-[:RELATION {name: 'conducts'}]->(t);
MERGE (s:OntologyClass {name: 'Study'})
MERGE (t:OntologyClass {name: 'ResearchProject'})
MERGE (s)-[:RELATION {name: 'part_of_project'}]->(t);
MERGE (s:OntologyClass {name: 'Study'})
MERGE (t:OntologyClass {name: 'StudyProtocol'})
MERGE (s)-[:RELATION {name: 'governed_by'}]->(t);
MERGE (s:OntologyClass {name: 'Study'})
MERGE (t:OntologyClass {name: 'EthicsApproval'})
MERGE (s)-[:RELATION {name: 'approved_by_ethics'}]->(t);
MERGE (s:OntologyClass {name: 'EthicsApproval'})
MERGE (t:OntologyClass {name: 'EthicsCommittee'})
MERGE (s)-[:RELATION {name: 'issued_by'}]->(t);
MERGE (s:OntologyClass {name: 'Enrolment'})
MERGE (t:OntologyClass {name: 'ResearchParticipant'})
MERGE (s)-[:RELATION {name: 'enrols'}]->(t);
MERGE (s:OntologyClass {name: 'Enrolment'})
MERGE (t:OntologyClass {name: 'Study'})
MERGE (s)-[:RELATION {name: 'enrolment_in'}]->(t);
MERGE (s:OntologyClass {name: 'Enrolment'})
MERGE (t:OntologyClass {name: 'InformedConsent'})
MERGE (s)-[:RELATION {name: 'has_consent'}]->(t);
MERGE (s:OntologyClass {name: 'Study'})
MERGE (t:OntologyClass {name: 'Dataset'})
MERGE (s)-[:RELATION {name: 'generates'}]->(t);
MERGE (s:OntologyClass {name: 'ProcessedDataset'})
MERGE (t:OntologyClass {name: 'RawDataset'})
MERGE (s)-[:RELATION {name: 'derived_from_dataset'}]->(t);
MERGE (s:OntologyClass {name: 'Dataset'})
MERGE (t:OntologyClass {name: 'Metadata'})
MERGE (s)-[:RELATION {name: 'described_by'}]->(t);
MERGE (s:OntologyClass {name: 'Dataset'})
MERGE (t:OntologyClass {name: 'Repository'})
MERGE (s)-[:RELATION {name: 'deposited_in'}]->(t);
MERGE (s:OntologyClass {name: 'ResearchProject'})
MERGE (t:OntologyClass {name: 'DataManagementPlan'})
MERGE (s)-[:RELATION {name: 'governed_by_plan'}]->(t);
MERGE (s:OntologyClass {name: 'Publication'})
MERGE (t:OntologyClass {name: 'Study'})
MERGE (s)-[:RELATION {name: 'reports_on'}]->(t);
MERGE (s:OntologyClass {name: 'Publication'})
MERGE (t:OntologyClass {name: 'Dataset'})
MERGE (s)-[:RELATION {name: 'uses_dataset'}]->(t);
MERGE (s:OntologyClass {name: 'Publication'})
MERGE (t:OntologyClass {name: 'Author'})
MERGE (s)-[:RELATION {name: 'authored_by'}]->(t);
MERGE (s:OntologyClass {name: 'Publication'})
MERGE (t:OntologyClass {name: 'Journal'})
MERGE (s)-[:RELATION {name: 'published_in'}]->(t);
MERGE (s:OntologyClass {name: 'Publication'})
MERGE (t:OntologyClass {name: 'Publication'})
MERGE (s)-[:RELATION {name: 'cites'}]->(t);
MERGE (s:OntologyClass {name: 'Publication'})
MERGE (t:OntologyClass {name: 'Grant'})
MERGE (s)-[:RELATION {name: 'acknowledges'}]->(t);
MERGE (s:OntologyClass {name: 'Publication'})
MERGE (t:OntologyClass {name: 'Reviewer'})
MERGE (s)-[:RELATION {name: 'reviewed_by'}]->(t);
MERGE (s:OntologyClass {name: 'ConflictOfInterestDeclaration'})
MERGE (t:OntologyClass {name: 'Author'})
MERGE (s)-[:RELATION {name: 'declares'}]->(t);
// Axiom Validations
// Axiom validation: Budget budget_total gte 0
MATCH (n:`Budget`) WHERE NOT (n.`budget_total` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Budget budget_total lte 10000000
MATCH (n:`Budget`) WHERE NOT (n.`budget_total` <= 10000000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Study sample_size gt 0
MATCH (n:`Study`) WHERE NOT (n.`sample_size` > 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Study enrolled_count gte 0
MATCH (n:`Study`) WHERE NOT (n.`enrolled_count` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: ClinicalTrial is_preregistered eq True
MATCH (n:`ClinicalTrial`) WHERE NOT (n.`is_preregistered` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Enrolment consent_obtained eq True
MATCH (n:`Enrolment`) WHERE NOT (n.`consent_obtained` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall s (HumanSubjectsStudy(s) and study_started = True implies exists a (approved_by_ethics(s, a)))
//   forall e (Enrolment(e) implies exists c (has_consent(e, c)))
//   forall g (Grant(g) and grant_active = True implies exists b (has_budget(g, b)))
//   forall d (Dataset(d) and data_is_personal = True and data_is_public = True implies data_is_anonymised = True)
//   forall d (Dataset(d) and data_is_public = True implies has_metadata = True)
//   forall p (Publication(p) and is_peer_reviewed = True implies exists r (reviewed_by(p, r)))
//   forall p (Publication(p) and is_peer_reviewed = True implies has_coi_declared = True)
//   forall x (not Study(x) and Publication(x))
//   forall x (not Organization(x) and Person(x))
//   forall x (not RawDataset(x) and ProcessedDataset(x))
