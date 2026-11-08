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
MERGE (n:OntologyClass {name: 'Quality'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InformationContentEntity'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Asset'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Endpoint'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Workstation'})
MERGE (p:OntologyClass {name: 'Endpoint'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Server'})
MERGE (p:OntologyClass {name: 'Endpoint'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DomainController'})
MERGE (p:OntologyClass {name: 'Server'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DatabaseServer'})
MERGE (p:OntologyClass {name: 'Server'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MobileDevice'})
MERGE (p:OntologyClass {name: 'Endpoint'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NetworkDevice'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Firewall'})
MERGE (p:OntologyClass {name: 'NetworkDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Router'})
MERGE (p:OntologyClass {name: 'NetworkDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CloudWorkload'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Application'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'UserAccount'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ServiceAccount'})
MERGE (p:OntologyClass {name: 'UserAccount'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PrivilegedAccount'})
MERGE (p:OntologyClass {name: 'UserAccount'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataStore'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BusinessUnit'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Vulnerability'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'KnownExploitedVulnerability'})
MERGE (p:OntologyClass {name: 'Vulnerability'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Weakness'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Misconfiguration'})
MERGE (p:OntologyClass {name: 'Weakness'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Patch'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThreatActor'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CriminalGroup'})
MERGE (p:OntologyClass {name: 'ThreatActor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StateSponsoredGroup'})
MERGE (p:OntologyClass {name: 'ThreatActor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Insider'})
MERGE (p:OntologyClass {name: 'ThreatActor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Technique'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tactic'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Malware'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Ransomware'})
MERGE (p:OntologyClass {name: 'Malware'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThreatIntelFeed'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Indicator'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IpIndicator'})
MERGE (p:OntologyClass {name: 'Indicator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DomainIndicator'})
MERGE (p:OntologyClass {name: 'Indicator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HashIndicator'})
MERGE (p:OntologyClass {name: 'Indicator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sensor'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EdrAgent'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NetworkSensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LogCollector'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SiemPlatform'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DetectionRule'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Alert'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FalsePositiveAlert'})
MERGE (p:OntologyClass {name: 'Alert'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TruePositiveAlert'})
MERGE (p:OntologyClass {name: 'Alert'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LogEvent'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Evidence'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MemoryImage'})
MERGE (p:OntologyClass {name: 'Evidence'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PacketCapture'})
MERGE (p:OntologyClass {name: 'Evidence'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DiskImage'})
MERGE (p:OntologyClass {name: 'Evidence'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Incident'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PhishingIncident'})
MERGE (p:OntologyClass {name: 'Incident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MalwareIncident'})
MERGE (p:OntologyClass {name: 'Incident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataBreachIncident'})
MERGE (p:OntologyClass {name: 'Incident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DenialOfServiceIncident'})
MERGE (p:OntologyClass {name: 'Incident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Severity'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ServiceLevelAgreement'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Playbook'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PlaybookStep'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ContainmentAction'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IsolateHost'})
MERGE (p:OntologyClass {name: 'ContainmentAction'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DisableAccount'})
MERGE (p:OntologyClass {name: 'ContainmentAction'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BlockIndicator'})
MERGE (p:OntologyClass {name: 'ContainmentAction'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Triage'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Investigation'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Eradication'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Recovery'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PostIncidentReview'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Escalation'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Analyst'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tier1Analyst'})
MERGE (p:OntologyClass {name: 'Analyst'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tier2Analyst'})
MERGE (p:OntologyClass {name: 'Analyst'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tier3Analyst'})
MERGE (p:OntologyClass {name: 'Analyst'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IncidentCommander'})
MERGE (p:OntologyClass {name: 'Analyst'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThreatHunter'})
MERGE (p:OntologyClass {name: 'Analyst'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SocManager'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OnCallRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ApproverRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Application'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'runs_on'}]->(t);
MERGE (s:OntologyClass {name: 'Asset'})
MERGE (t:OntologyClass {name: 'BusinessUnit'})
MERGE (s)-[:RELATION {name: 'owned_by'}]->(t);
MERGE (s:OntologyClass {name: 'Asset'})
MERGE (t:OntologyClass {name: 'Vulnerability'})
MERGE (s)-[:RELATION {name: 'affected_by'}]->(t);
MERGE (s:OntologyClass {name: 'Vulnerability'})
MERGE (t:OntologyClass {name: 'Patch'})
MERGE (s)-[:RELATION {name: 'remediated_by'}]->(t);
MERGE (s:OntologyClass {name: 'Technique'})
MERGE (t:OntologyClass {name: 'Vulnerability'})
MERGE (s)-[:RELATION {name: 'exploits'}]->(t);
MERGE (s:OntologyClass {name: 'ThreatActor'})
MERGE (t:OntologyClass {name: 'Technique'})
MERGE (s)-[:RELATION {name: 'uses_technique'}]->(t);
MERGE (s:OntologyClass {name: 'ThreatActor'})
MERGE (t:OntologyClass {name: 'Malware'})
MERGE (s)-[:RELATION {name: 'deploys'}]->(t);
MERGE (s:OntologyClass {name: 'Sensor'})
MERGE (t:OntologyClass {name: 'LogEvent'})
MERGE (s)-[:RELATION {name: 'generates'}]->(t);
MERGE (s:OntologyClass {name: 'LogEvent'})
MERGE (t:OntologyClass {name: 'SiemPlatform'})
MERGE (s)-[:RELATION {name: 'collected_by'}]->(t);
MERGE (s:OntologyClass {name: 'DetectionRule'})
MERGE (t:OntologyClass {name: 'Alert'})
MERGE (s)-[:RELATION {name: 'fires'}]->(t);
MERGE (s:OntologyClass {name: 'Alert'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'concerns_asset'}]->(t);
MERGE (s:OntologyClass {name: 'Alert'})
MERGE (t:OntologyClass {name: 'Indicator'})
MERGE (s)-[:RELATION {name: 'matches'}]->(t);
MERGE (s:OntologyClass {name: 'Alert'})
MERGE (t:OntologyClass {name: 'Incident'})
MERGE (s)-[:RELATION {name: 'escalates_to'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'involves'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'ThreatActor'})
MERGE (s)-[:RELATION {name: 'attributed_to'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'Analyst'})
MERGE (s)-[:RELATION {name: 'assigned_to'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'Playbook'})
MERGE (s)-[:RELATION {name: 'handled_by_playbook'}]->(t);
MERGE (s:OntologyClass {name: 'Playbook'})
MERGE (t:OntologyClass {name: 'PlaybookStep'})
MERGE (s)-[:RELATION {name: 'has_step'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'ContainmentAction'})
MERGE (s)-[:RELATION {name: 'contains'}]->(t);
MERGE (s:OntologyClass {name: 'ContainmentAction'})
MERGE (t:OntologyClass {name: 'Analyst'})
MERGE (s)-[:RELATION {name: 'approved_by'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'Evidence'})
MERGE (s)-[:RELATION {name: 'supported_by'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'ServiceLevelAgreement'})
MERGE (s)-[:RELATION {name: 'bound_by'}]->(t);
MERGE (s:OntologyClass {name: 'Analyst'})
MERGE (t:OntologyClass {name: 'SocManager'})
MERGE (s)-[:RELATION {name: 'reports_to'}]->(t);
// Axiom Validations
// Axiom validation: PrivilegedAccount is_mfa_enabled eq True
MATCH (n:`PrivilegedAccount`) WHERE NOT (n.`is_mfa_enabled` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Vulnerability cvss_score gte 0
MATCH (n:`Vulnerability`) WHERE NOT (n.`cvss_score` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Vulnerability cvss_score lte 100
MATCH (n:`Vulnerability`) WHERE NOT (n.`cvss_score` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Alert alert_confidence gte 0
MATCH (n:`Alert`) WHERE NOT (n.`alert_confidence` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Alert alert_confidence lte 100
MATCH (n:`Alert`) WHERE NOT (n.`alert_confidence` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Evidence chain_of_custody_intact eq True
MATCH (n:`Evidence`) WHERE NOT (n.`chain_of_custody_intact` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Incident incident_severity gte 1
MATCH (n:`Incident`) WHERE NOT (n.`incident_severity` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Incident incident_severity lte 4
MATCH (n:`Incident`) WHERE NOT (n.`incident_severity` <= 4) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Incident minutes_to_acknowledge lte 240
MATCH (n:`Incident`) WHERE NOT (n.`minutes_to_acknowledge` <= 240) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall i (Incident(i) and incident_severity = 4 implies is_escalated = True)
//   forall c (DisableAccount(c) implies exists a (Analyst(a) and approved_by(c, a)))
//   forall c (IsolateHost(c) implies exists a (Analyst(a) and approved_by(c, a)))
//   forall i (Incident(i) implies exists p (Playbook(p) and handled_by_playbook(i, p)))
//   forall i (Incident(i) and is_closed = True implies has_post_incident_review = True)
//   forall a (FalsePositiveAlert(a) implies not TruePositiveAlert(a))
//   forall a (Tier1Analyst(a) implies not Tier3Analyst(a))
