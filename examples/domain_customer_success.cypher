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
MERGE (n:OntologyClass {name: 'Occurrent'})
MERGE (p:OntologyClass {name: 'Entity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Process'})
MERGE (p:OntologyClass {name: 'Occurrent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Role'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Quality'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InformationContentEntity'})
MERGE (p:OntologyClass {name: 'Continuant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Organization'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Account'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EnterpriseAccount'})
MERGE (p:OntologyClass {name: 'Account'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MidMarketAccount'})
MERGE (p:OntologyClass {name: 'Account'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SmallBusinessAccount'})
MERGE (p:OntologyClass {name: 'Account'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustomerContact'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ExecutiveSponsor'})
MERGE (p:OntologyClass {name: 'CustomerContact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Champion'})
MERGE (p:OntologyClass {name: 'CustomerContact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Administrator'})
MERGE (p:OntologyClass {name: 'CustomerContact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EndUser'})
MERGE (p:OntologyClass {name: 'CustomerContact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Detractor'})
MERGE (p:OntologyClass {name: 'CustomerContact'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VendorStaff'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustomerSuccessManager'})
MERGE (p:OntologyClass {name: 'VendorStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SolutionsEngineer'})
MERGE (p:OntologyClass {name: 'VendorStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AccountExecutive'})
MERGE (p:OntologyClass {name: 'VendorStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SupportLiaison'})
MERGE (p:OntologyClass {name: 'VendorStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SuccessTeam'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LifecycleStage'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProspectStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OnboardingStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AdoptionStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ExpansionStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RenewalStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChurnedStage'})
MERGE (p:OntologyClass {name: 'LifecycleStage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OnboardingProcess'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Kickoff'})
MERGE (p:OntologyClass {name: 'OnboardingProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataMigration'})
MERGE (p:OntologyClass {name: 'OnboardingProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IntegrationSetup'})
MERGE (p:OntologyClass {name: 'OnboardingProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'UserTraining'})
MERGE (p:OntologyClass {name: 'OnboardingProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GoLive'})
MERGE (p:OntologyClass {name: 'OnboardingProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OnboardingPlan'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Milestone'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SuccessPlan'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SuccessGoal'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HealthScore'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HealthyScore'})
MERGE (p:OntologyClass {name: 'HealthScore'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NeutralScore'})
MERGE (p:OntologyClass {name: 'HealthScore'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AtRiskScore'})
MERGE (p:OntologyClass {name: 'HealthScore'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HealthSignal'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'UsageSignal'})
MERGE (p:OntologyClass {name: 'HealthSignal'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SupportSignal'})
MERGE (p:OntologyClass {name: 'HealthSignal'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SentimentSignal'})
MERGE (p:OntologyClass {name: 'HealthSignal'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FinancialSignal'})
MERGE (p:OntologyClass {name: 'HealthSignal'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChurnRisk'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HighChurnRisk'})
MERGE (p:OntologyClass {name: 'ChurnRisk'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LowChurnRisk'})
MERGE (p:OntologyClass {name: 'ChurnRisk'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RiskAlert'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SaveCampaign'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Contract'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Subscription'})
MERGE (p:OntologyClass {name: 'Contract'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Renewal'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AutoRenewal'})
MERGE (p:OntologyClass {name: 'Renewal'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NegotiatedRenewal'})
MERGE (p:OntologyClass {name: 'Renewal'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Expansion'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Upsell'})
MERGE (p:OntologyClass {name: 'Expansion'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CrossSell'})
MERGE (p:OntologyClass {name: 'Expansion'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Churn'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VoluntaryChurn'})
MERGE (p:OntologyClass {name: 'Churn'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InvoluntaryChurn'})
MERGE (p:OntologyClass {name: 'Churn'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Invoice'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BusinessReview'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ExecutiveBusinessReview'})
MERGE (p:OntologyClass {name: 'BusinessReview'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'QuarterlyBusinessReview'})
MERGE (p:OntologyClass {name: 'BusinessReview'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReviewDeck'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ActionItem'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NPSSurvey'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'CustomerSuccessManager'})
MERGE (s)-[:RELATION {name: 'managed_by'}]->(t);
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'CustomerContact'})
MERGE (s)-[:RELATION {name: 'has_contact'}]->(t);
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'ExecutiveSponsor'})
MERGE (s)-[:RELATION {name: 'sponsored_by'}]->(t);
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'LifecycleStage'})
MERGE (s)-[:RELATION {name: 'in_stage'}]->(t);
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'Contract'})
MERGE (s)-[:RELATION {name: 'holds_contract'}]->(t);
MERGE (s:OntologyClass {name: 'Renewal'})
MERGE (t:OntologyClass {name: 'Contract'})
MERGE (s)-[:RELATION {name: 'renews'}]->(t);
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'OnboardingPlan'})
MERGE (s)-[:RELATION {name: 'onboarded_via'}]->(t);
MERGE (s:OntologyClass {name: 'OnboardingPlan'})
MERGE (t:OntologyClass {name: 'Milestone'})
MERGE (s)-[:RELATION {name: 'contains_milestone'}]->(t);
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'HealthScore'})
MERGE (s)-[:RELATION {name: 'scored_as'}]->(t);
MERGE (s:OntologyClass {name: 'HealthScore'})
MERGE (t:OntologyClass {name: 'HealthSignal'})
MERGE (s)-[:RELATION {name: 'derived_from'}]->(t);
MERGE (s:OntologyClass {name: 'RiskAlert'})
MERGE (t:OntologyClass {name: 'Account'})
MERGE (s)-[:RELATION {name: 'raises'}]->(t);
MERGE (s:OntologyClass {name: 'Account'})
MERGE (t:OntologyClass {name: 'BusinessReview'})
MERGE (s)-[:RELATION {name: 'reviewed_in'}]->(t);
MERGE (s:OntologyClass {name: 'BusinessReview'})
MERGE (t:OntologyClass {name: 'ActionItem'})
MERGE (s)-[:RELATION {name: 'produces'}]->(t);
MERGE (s:OntologyClass {name: 'SaveCampaign'})
MERGE (t:OntologyClass {name: 'Account'})
MERGE (s)-[:RELATION {name: 'targets'}]->(t);
MERGE (s:OntologyClass {name: 'CustomerSuccessManager'})
MERGE (t:OntologyClass {name: 'SuccessTeam'})
MERGE (s)-[:RELATION {name: 'member_of'}]->(t);
MERGE (s:OntologyClass {name: 'Expansion'})
MERGE (t:OntologyClass {name: 'Account'})
MERGE (s)-[:RELATION {name: 'expands'}]->(t);
// Axiom Validations
// Axiom validation: Account health_score gte 0
MATCH (n:`Account`) WHERE NOT (n.`health_score` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Account health_score lte 100
MATCH (n:`Account`) WHERE NOT (n.`health_score` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: EnterpriseAccount has_executive_sponsor eq True
MATCH (n:`EnterpriseAccount`) WHERE NOT (n.`has_executive_sponsor` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: CustomerSuccessManager portfolio_size lte 60
MATCH (n:`CustomerSuccessManager`) WHERE NOT (n.`portfolio_size` <= 60) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Renewal discount_percent gte 0
MATCH (n:`Renewal`) WHERE NOT (n.`discount_percent` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Renewal discount_percent lte 30
MATCH (n:`Renewal`) WHERE NOT (n.`discount_percent` <= 30) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: NPSSurvey nps_score gte 0
MATCH (n:`NPSSurvey`) WHERE NOT (n.`nps_score` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: NPSSurvey nps_score lte 10
MATCH (n:`NPSSurvey`) WHERE NOT (n.`nps_score` <= 10) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall x (not CustomerContact(x) and VendorStaff(x))
//   forall x (not EnterpriseAccount(x) and SmallBusinessAccount(x))
//   forall x (not HealthyScore(x) and AtRiskScore(x))
//   forall x (not ChurnedStage(x) and RenewalStage(x))
//   forall x (not VoluntaryChurn(x) and InvoluntaryChurn(x))
//   forall a (Account(a) and lt(health_score, 40) implies is_at_risk = True)
//   forall a (Account(a) and is_at_risk = True implies has_success_plan = True)
