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
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Customer'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EnterpriseCustomer'})
MERGE (p:OntologyClass {name: 'Customer'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConsumerCustomer'})
MERGE (p:OntologyClass {name: 'Customer'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SupportStaff'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SupportAgent'})
MERGE (p:OntologyClass {name: 'SupportStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SeniorAgent'})
MERGE (p:OntologyClass {name: 'SupportAgent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TeamLead'})
MERGE (p:OntologyClass {name: 'SupportStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'KnowledgeAuthor'})
MERGE (p:OntologyClass {name: 'SupportStaff'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Bot'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SupportTeam'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TierOneTeam'})
MERGE (p:OntologyClass {name: 'SupportTeam'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TierTwoTeam'})
MERGE (p:OntologyClass {name: 'SupportTeam'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EngineeringTeam'})
MERGE (p:OntologyClass {name: 'SupportTeam'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Ticket'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Incident'})
MERGE (p:OntologyClass {name: 'Ticket'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ServiceRequest'})
MERGE (p:OntologyClass {name: 'Ticket'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Question'})
MERGE (p:OntologyClass {name: 'Ticket'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Complaint'})
MERGE (p:OntologyClass {name: 'Ticket'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Problem'})
MERGE (p:OntologyClass {name: 'Ticket'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TicketComment'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InternalNote'})
MERGE (p:OntologyClass {name: 'TicketComment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PublicReply'})
MERGE (p:OntologyClass {name: 'TicketComment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Resolution'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Attachment'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SatisfactionSurvey'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Priority'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CriticalPriority'})
MERGE (p:OntologyClass {name: 'Priority'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HighPriority'})
MERGE (p:OntologyClass {name: 'Priority'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NormalPriority'})
MERGE (p:OntologyClass {name: 'Priority'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LowPriority'})
MERGE (p:OntologyClass {name: 'Priority'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TicketStatus'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OpenStatus'})
MERGE (p:OntologyClass {name: 'TicketStatus'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PendingStatus'})
MERGE (p:OntologyClass {name: 'TicketStatus'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SolvedStatus'})
MERGE (p:OntologyClass {name: 'TicketStatus'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ClosedStatus'})
MERGE (p:OntologyClass {name: 'TicketStatus'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Channel'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EmailChannel'})
MERGE (p:OntologyClass {name: 'Channel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PhoneChannel'})
MERGE (p:OntologyClass {name: 'Channel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChatChannel'})
MERGE (p:OntologyClass {name: 'Channel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SocialChannel'})
MERGE (p:OntologyClass {name: 'Channel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PortalChannel'})
MERGE (p:OntologyClass {name: 'Channel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Queue'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GeneralQueue'})
MERGE (p:OntologyClass {name: 'Queue'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BillingQueue'})
MERGE (p:OntologyClass {name: 'Queue'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TechnicalQueue'})
MERGE (p:OntologyClass {name: 'Queue'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PriorityQueue'})
MERGE (p:OntologyClass {name: 'Queue'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ServiceLevelAgreement'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PremiumSLA'})
MERGE (p:OntologyClass {name: 'ServiceLevelAgreement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StandardSLA'})
MERGE (p:OntologyClass {name: 'ServiceLevelAgreement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SLABreach'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Escalation'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ManagerEscalation'})
MERGE (p:OntologyClass {name: 'Escalation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EngineeringEscalation'})
MERGE (p:OntologyClass {name: 'Escalation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Assignment'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Handover'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'KnowledgeArticle'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FAQArticle'})
MERGE (p:OntologyClass {name: 'KnowledgeArticle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TroubleshootingGuide'})
MERGE (p:OntologyClass {name: 'KnowledgeArticle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InternalRunbook'})
MERGE (p:OntologyClass {name: 'KnowledgeArticle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ArticleVersion'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MacroTemplate'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'Customer'})
MERGE (s)-[:RELATION {name: 'raised_by'}]->(t);
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'Channel'})
MERGE (s)-[:RELATION {name: 'received_via'}]->(t);
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'SupportAgent'})
MERGE (s)-[:RELATION {name: 'assigned_to'}]->(t);
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'Queue'})
MERGE (s)-[:RELATION {name: 'held_in'}]->(t);
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'ServiceLevelAgreement'})
MERGE (s)-[:RELATION {name: 'governed_by'}]->(t);
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'Priority'})
MERGE (s)-[:RELATION {name: 'has_priority'}]->(t);
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'TicketStatus'})
MERGE (s)-[:RELATION {name: 'has_status'}]->(t);
MERGE (s:OntologyClass {name: 'Escalation'})
MERGE (t:OntologyClass {name: 'Ticket'})
MERGE (s)-[:RELATION {name: 'escalates'}]->(t);
MERGE (s:OntologyClass {name: 'Escalation'})
MERGE (t:OntologyClass {name: 'SupportTeam'})
MERGE (s)-[:RELATION {name: 'escalated_to'}]->(t);
MERGE (s:OntologyClass {name: 'Ticket'})
MERGE (t:OntologyClass {name: 'Resolution'})
MERGE (s)-[:RELATION {name: 'resolved_with'}]->(t);
MERGE (s:OntologyClass {name: 'Resolution'})
MERGE (t:OntologyClass {name: 'KnowledgeArticle'})
MERGE (s)-[:RELATION {name: 'cites'}]->(t);
MERGE (s:OntologyClass {name: 'TicketComment'})
MERGE (t:OntologyClass {name: 'Ticket'})
MERGE (s)-[:RELATION {name: 'commented_on'}]->(t);
MERGE (s:OntologyClass {name: 'SupportAgent'})
MERGE (t:OntologyClass {name: 'SupportTeam'})
MERGE (s)-[:RELATION {name: 'member_of'}]->(t);
MERGE (s:OntologyClass {name: 'SupportTeam'})
MERGE (t:OntologyClass {name: 'Queue'})
MERGE (s)-[:RELATION {name: 'staffs'}]->(t);
MERGE (s:OntologyClass {name: 'ServiceLevelAgreement'})
MERGE (t:OntologyClass {name: 'Customer'})
MERGE (s)-[:RELATION {name: 'covers_customer'}]->(t);
MERGE (s:OntologyClass {name: 'SatisfactionSurvey'})
MERGE (t:OntologyClass {name: 'Ticket'})
MERGE (s)-[:RELATION {name: 'rates'}]->(t);
MERGE (s:OntologyClass {name: 'KnowledgeArticle'})
MERGE (t:OntologyClass {name: 'KnowledgeAuthor'})
MERGE (s)-[:RELATION {name: 'authored_by'}]->(t);
// Axiom Validations
// Axiom validation: SupportAgent max_concurrent_chats lte 5
MATCH (n:`SupportAgent`) WHERE NOT (n.`max_concurrent_chats` <= 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SatisfactionSurvey csat_score gte 1
MATCH (n:`SatisfactionSurvey`) WHERE NOT (n.`csat_score` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SatisfactionSurvey csat_score lte 5
MATCH (n:`SatisfactionSurvey`) WHERE NOT (n.`csat_score` <= 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: PremiumSLA response_target_minutes lte 60
MATCH (n:`PremiumSLA`) WHERE NOT (n.`response_target_minutes` <= 60) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: StandardSLA response_target_minutes lte 1440
MATCH (n:`StandardSLA`) WHERE NOT (n.`response_target_minutes` <= 1440) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: InternalRunbook is_internal_only eq True
MATCH (n:`InternalRunbook`) WHERE NOT (n.`is_internal_only` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall x (not Customer(x) and SupportStaff(x))
//   forall x (not Bot(x) and SupportStaff(x))
//   forall x (not Ticket(x) and KnowledgeArticle(x))
//   forall x (not CriticalPriority(x) and LowPriority(x))
//   forall x (not OpenStatus(x) and ClosedStatus(x))
//   forall t (Ticket(t) and is_breached = True implies is_escalated = True)
//   forall t (Ticket(t) and gt(reopen_count, 3) implies is_escalated = True)
