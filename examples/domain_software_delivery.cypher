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
MERGE (n:OntologyClass {name: 'Team'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Developer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Reviewer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CodeOwner'})
MERGE (p:OntologyClass {name: 'Reviewer'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReleaseManager'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OnCallEngineer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IncidentCommander'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SourceArtifact'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Repository'})
MERGE (p:OntologyClass {name: 'SourceArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MonorepoRepository'})
MERGE (p:OntologyClass {name: 'Repository'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Branch'})
MERGE (p:OntologyClass {name: 'SourceArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProtectedBranch'})
MERGE (p:OntologyClass {name: 'Branch'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FeatureBranch'})
MERGE (p:OntologyClass {name: 'Branch'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Commit'})
MERGE (p:OntologyClass {name: 'SourceArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SignedCommit'})
MERGE (p:OntologyClass {name: 'Commit'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MergeCommit'})
MERGE (p:OntologyClass {name: 'Commit'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tag'})
MERGE (p:OntologyClass {name: 'SourceArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CodeChange'})
MERGE (p:OntologyClass {name: 'SourceArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PullRequest'})
MERGE (p:OntologyClass {name: 'CodeChange'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DraftPullRequest'})
MERGE (p:OntologyClass {name: 'PullRequest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MergedPullRequest'})
MERGE (p:OntologyClass {name: 'PullRequest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReviewComment'})
MERGE (p:OntologyClass {name: 'SourceArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BuildArtifact'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ContainerImage'})
MERGE (p:OntologyClass {name: 'BuildArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Package'})
MERGE (p:OntologyClass {name: 'BuildArtifact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SoftwareBillOfMaterials'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Release'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CandidateRelease'})
MERGE (p:OntologyClass {name: 'Release'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StableRelease'})
MERGE (p:OntologyClass {name: 'Release'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HotfixRelease'})
MERGE (p:OntologyClass {name: 'Release'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Changelog'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TestReport'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CoverageReport'})
MERGE (p:OntologyClass {name: 'TestReport'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PostmortemReport'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Environment'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DevelopmentEnvironment'})
MERGE (p:OntologyClass {name: 'Environment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StagingEnvironment'})
MERGE (p:OntologyClass {name: 'Environment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProductionEnvironment'})
MERGE (p:OntologyClass {name: 'Environment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BuildAgent'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Service'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FeatureFlag'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DeliveryProcess'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CodeReview'})
MERGE (p:OntologyClass {name: 'DeliveryProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Build'})
MERGE (p:OntologyClass {name: 'DeliveryProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FailedBuild'})
MERGE (p:OntologyClass {name: 'Build'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TestRun'})
MERGE (p:OntologyClass {name: 'DeliveryProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'UnitTestRun'})
MERGE (p:OntologyClass {name: 'TestRun'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IntegrationTestRun'})
MERGE (p:OntologyClass {name: 'TestRun'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SecurityScan'})
MERGE (p:OntologyClass {name: 'DeliveryProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Deployment'})
MERGE (p:OntologyClass {name: 'DeliveryProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProductionDeployment'})
MERGE (p:OntologyClass {name: 'Deployment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CanaryDeployment'})
MERGE (p:OntologyClass {name: 'ProductionDeployment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Rollback'})
MERGE (p:OntologyClass {name: 'DeliveryProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IncidentResponse'})
MERGE (p:OntologyClass {name: 'DeliveryProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Incident'})
MERGE (p:OntologyClass {name: 'Occurrent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProductionIncident'})
MERGE (p:OntologyClass {name: 'Incident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SecurityIncident'})
MERGE (p:OntologyClass {name: 'Incident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Alert'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Repository'})
MERGE (t:OntologyClass {name: 'Commit'})
MERGE (s)-[:RELATION {name: 'contains_commit'}]->(t);
MERGE (s:OntologyClass {name: 'Commit'})
MERGE (t:OntologyClass {name: 'Person'})
MERGE (s)-[:RELATION {name: 'authored_by'}]->(t);
MERGE (s:OntologyClass {name: 'PullRequest'})
MERGE (t:OntologyClass {name: 'Commit'})
MERGE (s)-[:RELATION {name: 'proposes'}]->(t);
MERGE (s:OntologyClass {name: 'PullRequest'})
MERGE (t:OntologyClass {name: 'Branch'})
MERGE (s)-[:RELATION {name: 'targets_branch'}]->(t);
MERGE (s:OntologyClass {name: 'PullRequest'})
MERGE (t:OntologyClass {name: 'Reviewer'})
MERGE (s)-[:RELATION {name: 'reviewed_by'}]->(t);
MERGE (s:OntologyClass {name: 'CodeReview'})
MERGE (t:OntologyClass {name: 'PullRequest'})
MERGE (s)-[:RELATION {name: 'reviews'}]->(t);
MERGE (s:OntologyClass {name: 'Build'})
MERGE (t:OntologyClass {name: 'Commit'})
MERGE (s)-[:RELATION {name: 'builds_from'}]->(t);
MERGE (s:OntologyClass {name: 'Build'})
MERGE (t:OntologyClass {name: 'BuildArtifact'})
MERGE (s)-[:RELATION {name: 'produces'}]->(t);
MERGE (s:OntologyClass {name: 'TestRun'})
MERGE (t:OntologyClass {name: 'Build'})
MERGE (s)-[:RELATION {name: 'validates'}]->(t);
MERGE (s:OntologyClass {name: 'SecurityScan'})
MERGE (t:OntologyClass {name: 'BuildArtifact'})
MERGE (s)-[:RELATION {name: 'scans'}]->(t);
MERGE (s:OntologyClass {name: 'Release'})
MERGE (t:OntologyClass {name: 'BuildArtifact'})
MERGE (s)-[:RELATION {name: 'packages_artifact'}]->(t);
MERGE (s:OntologyClass {name: 'Release'})
MERGE (t:OntologyClass {name: 'SoftwareBillOfMaterials'})
MERGE (s)-[:RELATION {name: 'has_sbom'}]->(t);
MERGE (s:OntologyClass {name: 'Deployment'})
MERGE (t:OntologyClass {name: 'Release'})
MERGE (s)-[:RELATION {name: 'deploys'}]->(t);
MERGE (s:OntologyClass {name: 'Deployment'})
MERGE (t:OntologyClass {name: 'Environment'})
MERGE (s)-[:RELATION {name: 'deploys_to'}]->(t);
MERGE (s:OntologyClass {name: 'Rollback'})
MERGE (t:OntologyClass {name: 'Deployment'})
MERGE (s)-[:RELATION {name: 'rolls_back'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'Deployment'})
MERGE (s)-[:RELATION {name: 'caused_by'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'IncidentCommander'})
MERGE (s)-[:RELATION {name: 'owned_by'}]->(t);
MERGE (s:OntologyClass {name: 'IncidentResponse'})
MERGE (t:OntologyClass {name: 'Incident'})
MERGE (s)-[:RELATION {name: 'responds_to'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'PostmortemReport'})
MERGE (s)-[:RELATION {name: 'documented_in'}]->(t);
MERGE (s:OntologyClass {name: 'Service'})
MERGE (t:OntologyClass {name: 'Environment'})
MERGE (s)-[:RELATION {name: 'runs_on'}]->(t);
// Axiom Validations
// Axiom validation: PullRequest lines_changed gte 0
MATCH (n:`PullRequest`) WHERE NOT (n.`lines_changed` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: PullRequest lines_changed lte 5000
MATCH (n:`PullRequest`) WHERE NOT (n.`lines_changed` <= 5000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: TestRun tests_failed gte 0
MATCH (n:`TestRun`) WHERE NOT (n.`tests_failed` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: TestRun tests_total gte 0
MATCH (n:`TestRun`) WHERE NOT (n.`tests_total` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Incident incident_severity gte 1
MATCH (n:`Incident`) WHERE NOT (n.`incident_severity` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Incident incident_severity lte 4
MATCH (n:`Incident`) WHERE NOT (n.`incident_severity` <= 4) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall p (PullRequest(p) and is_merged = True implies ci_passed = True)
//   forall p (PullRequest(p) and is_merged = True implies gte(approval_count, 2))
//   forall b (Build(b) and build_succeeded = True implies exists t (TestRun(t)))
//   forall r (Release(r) and is_published = True implies is_signed_off = True)
//   forall d (forall r (Deployment(d) and deploys(d, r) implies Release(r)))
//   forall r (Release(r) and is_signed_off = True implies exists s (has_sbom(r, s)))
//   forall i (Incident(i) and is_resolved = False implies exists c (owned_by(i, c)))
//   forall i (Incident(i) and incident_severity = 1 and is_resolved = True implies has_postmortem = True)
//   forall x (not Commit(x) and Build(x))
//   forall x (not Release(x) and Deployment(x))
