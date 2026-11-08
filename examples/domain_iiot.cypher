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
MERGE (n:OntologyClass {name: 'Asset'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RotatingAsset'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Motor'})
MERGE (p:OntologyClass {name: 'RotatingAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pump'})
MERGE (p:OntologyClass {name: 'RotatingAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Compressor'})
MERGE (p:OntologyClass {name: 'RotatingAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Fan'})
MERGE (p:OntologyClass {name: 'RotatingAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Gearbox'})
MERGE (p:OntologyClass {name: 'RotatingAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StaticAsset'})
MERGE (p:OntologyClass {name: 'Asset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HeatExchanger'})
MERGE (p:OntologyClass {name: 'StaticAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Tank'})
MERGE (p:OntologyClass {name: 'StaticAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pipeline'})
MERGE (p:OntologyClass {name: 'StaticAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Component'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Bearing'})
MERGE (p:OntologyClass {name: 'Component'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Seal'})
MERGE (p:OntologyClass {name: 'Component'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Impeller'})
MERGE (p:OntologyClass {name: 'Component'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sensor'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VibrationSensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TemperatureSensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PressureSensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CurrentSensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AcousticSensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OilQualitySensor'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EdgeGateway'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProtocolBridge'})
MERGE (p:OntologyClass {name: 'EdgeGateway'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EdgeAnalyticsNode'})
MERGE (p:OntologyClass {name: 'EdgeGateway'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PlcController'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MessageBroker'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MqttBroker'})
MERGE (p:OntologyClass {name: 'MessageBroker'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OpcUaServer'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CloudPlatform'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TimeSeriesStore'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NetworkLink'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CellularLink'})
MERGE (p:OntologyClass {name: 'NetworkLink'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EthernetLink'})
MERGE (p:OntologyClass {name: 'NetworkLink'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WirelessMeshLink'})
MERGE (p:OntologyClass {name: 'NetworkLink'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TelemetryMessage'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MqttMessage'})
MERGE (p:OntologyClass {name: 'TelemetryMessage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OpcUaDataChange'})
MERGE (p:OntologyClass {name: 'TelemetryMessage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Topic'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NodeId'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PayloadSchema'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Measurement'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Waveform'})
MERGE (p:OntologyClass {name: 'Measurement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ScalarReading'})
MERGE (p:OntologyClass {name: 'Measurement'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HealthIndicator'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FeatureVector'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AnomalyModel'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RemainingUsefulLifeEstimate'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Alert'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConditionAlert'})
MERGE (p:OntologyClass {name: 'Alert'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConnectivityAlert'})
MERGE (p:OntologyClass {name: 'Alert'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WorkOrder'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PredictiveWorkOrder'})
MERGE (p:OntologyClass {name: 'WorkOrder'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CorrectiveWorkOrder'})
MERGE (p:OntologyClass {name: 'WorkOrder'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Certificate'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Telemetry'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sampling'})
MERGE (p:OntologyClass {name: 'Telemetry'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Publication'})
MERGE (p:OntologyClass {name: 'Telemetry'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StoreAndForward'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InferenceRun'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Degradation'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MaintenanceActivity'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InspectionActivity'})
MERGE (p:OntologyClass {name: 'MaintenanceActivity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RepairActivity'})
MERGE (p:OntologyClass {name: 'MaintenanceActivity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReliabilityEngineerRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MaintenanceTechnicianRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataEngineerRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Sensor'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'monitors'}]->(t);
MERGE (s:OntologyClass {name: 'Sensor'})
MERGE (t:OntologyClass {name: 'Component'})
MERGE (s)-[:RELATION {name: 'attached_to'}]->(t);
MERGE (s:OntologyClass {name: 'Component'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'part_of'}]->(t);
MERGE (s:OntologyClass {name: 'EdgeGateway'})
MERGE (t:OntologyClass {name: 'Sensor'})
MERGE (s)-[:RELATION {name: 'collects_from'}]->(t);
MERGE (s:OntologyClass {name: 'EdgeGateway'})
MERGE (t:OntologyClass {name: 'MessageBroker'})
MERGE (s)-[:RELATION {name: 'publishes_to'}]->(t);
MERGE (s:OntologyClass {name: 'OpcUaServer'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'exposes'}]->(t);
MERGE (s:OntologyClass {name: 'MessageBroker'})
MERGE (t:OntologyClass {name: 'CloudPlatform'})
MERGE (s)-[:RELATION {name: 'reports_to'}]->(t);
MERGE (s:OntologyClass {name: 'TelemetryMessage'})
MERGE (t:OntologyClass {name: 'Sensor'})
MERGE (s)-[:RELATION {name: 'emitted_by'}]->(t);
MERGE (s:OntologyClass {name: 'TelemetryMessage'})
MERGE (t:OntologyClass {name: 'Topic'})
MERGE (s)-[:RELATION {name: 'published_on'}]->(t);
MERGE (s:OntologyClass {name: 'TelemetryMessage'})
MERGE (t:OntologyClass {name: 'PayloadSchema'})
MERGE (s)-[:RELATION {name: 'conforms_to'}]->(t);
MERGE (s:OntologyClass {name: 'FeatureVector'})
MERGE (t:OntologyClass {name: 'Measurement'})
MERGE (s)-[:RELATION {name: 'derived_from'}]->(t);
MERGE (s:OntologyClass {name: 'HealthIndicator'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'scores'}]->(t);
MERGE (s:OntologyClass {name: 'RemainingUsefulLifeEstimate'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'predicts'}]->(t);
MERGE (s:OntologyClass {name: 'Alert'})
MERGE (t:OntologyClass {name: 'WorkOrder'})
MERGE (s)-[:RELATION {name: 'triggers'}]->(t);
MERGE (s:OntologyClass {name: 'Alert'})
MERGE (t:OntologyClass {name: 'Asset'})
MERGE (s)-[:RELATION {name: 'raised_for'}]->(t);
MERGE (s:OntologyClass {name: 'WorkOrder'})
MERGE (t:OntologyClass {name: 'MaintenanceTechnicianRole'})
MERGE (s)-[:RELATION {name: 'assigned_to'}]->(t);
MERGE (s:OntologyClass {name: 'EdgeGateway'})
MERGE (t:OntologyClass {name: 'Certificate'})
MERGE (s)-[:RELATION {name: 'authenticated_with'}]->(t);
MERGE (s:OntologyClass {name: 'EdgeGateway'})
MERGE (t:OntologyClass {name: 'NetworkLink'})
MERGE (s)-[:RELATION {name: 'uplink'}]->(t);
// Axiom Validations
// Axiom validation: Sensor sampling_rate_hz gt 0
MATCH (n:`Sensor`) WHERE NOT (n.`sampling_rate_hz` > 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: EdgeGateway buffered_msgs gte 0
MATCH (n:`EdgeGateway`) WHERE NOT (n.`buffered_msgs` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: EdgeGateway buffered_msgs lte 1000000
MATCH (n:`EdgeGateway`) WHERE NOT (n.`buffered_msgs` <= 1000000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: TelemetryMessage is_encrypted_in_transit eq True
MATCH (n:`TelemetryMessage`) WHERE NOT (n.`is_encrypted_in_transit` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: MqttMessage qos_level gte 0
MATCH (n:`MqttMessage`) WHERE NOT (n.`qos_level` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: MqttMessage qos_level lte 2
MATCH (n:`MqttMessage`) WHERE NOT (n.`qos_level` <= 2) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Measurement quality_code gte 0
MATCH (n:`Measurement`) WHERE NOT (n.`quality_code` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Measurement quality_code lte 3
MATCH (n:`Measurement`) WHERE NOT (n.`quality_code` <= 3) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: HealthIndicator health_score gte 0
MATCH (n:`HealthIndicator`) WHERE NOT (n.`health_score` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: HealthIndicator health_score lte 100
MATCH (n:`HealthIndicator`) WHERE NOT (n.`health_score` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: RemainingUsefulLifeEstimate rul_hours gte 0
MATCH (n:`RemainingUsefulLifeEstimate`) WHERE NOT (n.`rul_hours` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: RemainingUsefulLifeEstimate confidence_pct gte 0
MATCH (n:`RemainingUsefulLifeEstimate`) WHERE NOT (n.`confidence_pct` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: RemainingUsefulLifeEstimate confidence_pct lte 100
MATCH (n:`RemainingUsefulLifeEstimate`) WHERE NOT (n.`confidence_pct` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Alert alert_severity gte 1
MATCH (n:`Alert`) WHERE NOT (n.`alert_severity` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Alert alert_severity lte 5
MATCH (n:`Alert`) WHERE NOT (n.`alert_severity` <= 5) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall a (ConditionAlert(a) implies exists x (Asset(x) and raised_for(a, x)))
//   forall w (PredictiveWorkOrder(w) implies exists a (Alert(a) and triggers(a, w)))
//   forall g (EdgeGateway(g) implies exists c (Certificate(c) and authenticated_with(g, c)))
//   forall g (EdgeGateway(g) implies not Sensor(g))
