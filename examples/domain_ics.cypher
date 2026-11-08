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
MERGE (n:OntologyClass {name: 'PurdueLevel'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Level0Process'})
MERGE (p:OntologyClass {name: 'PurdueLevel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Level1BasicControl'})
MERGE (p:OntologyClass {name: 'PurdueLevel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Level2Supervisory'})
MERGE (p:OntologyClass {name: 'PurdueLevel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Level3SiteOperations'})
MERGE (p:OntologyClass {name: 'PurdueLevel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Level35Dmz'})
MERGE (p:OntologyClass {name: 'PurdueLevel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Level4Enterprise'})
MERGE (p:OntologyClass {name: 'PurdueLevel'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PlantArea'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessUnit'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlZone'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyZone'})
MERGE (p:OntologyClass {name: 'ControlZone'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FieldDevice'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Sensor'})
MERGE (p:OntologyClass {name: 'FieldDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PressureTransmitter'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TemperatureTransmitter'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LevelTransmitter'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FlowTransmitter'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GasDetector'})
MERGE (p:OntologyClass {name: 'Sensor'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Actuator'})
MERGE (p:OntologyClass {name: 'FieldDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlValve'})
MERGE (p:OntologyClass {name: 'Actuator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ShutdownValve'})
MERGE (p:OntologyClass {name: 'Actuator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MotorStarter'})
MERGE (p:OntologyClass {name: 'Actuator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VariableFrequencyDrive'})
MERGE (p:OntologyClass {name: 'Actuator'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EmergencyStopButton'})
MERGE (p:OntologyClass {name: 'FieldDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Controller'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Plc'})
MERGE (p:OntologyClass {name: 'Controller'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Rtu'})
MERGE (p:OntologyClass {name: 'Controller'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Dcs'})
MERGE (p:OntologyClass {name: 'Controller'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyController'})
MERGE (p:OntologyClass {name: 'Controller'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IoModule'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'IndustrialNetwork'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FieldbusSegment'})
MERGE (p:OntologyClass {name: 'IndustrialNetwork'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlNetwork'})
MERGE (p:OntologyClass {name: 'IndustrialNetwork'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FirewallConduit'})
MERGE (p:OntologyClass {name: 'IndustrialNetwork'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Workstation'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ScadaServer'})
MERGE (p:OntologyClass {name: 'Workstation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HmiStation'})
MERGE (p:OntologyClass {name: 'Workstation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EngineeringWorkstation'})
MERGE (p:OntologyClass {name: 'Workstation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Historian'})
MERGE (p:OntologyClass {name: 'Workstation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlProgram'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LadderLogicProgram'})
MERGE (p:OntologyClass {name: 'ControlProgram'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyProgram'})
MERGE (p:OntologyClass {name: 'ControlProgram'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlLoop'})
MERGE (p:OntologyClass {name: 'Function'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PidLoop'})
MERGE (p:OntologyClass {name: 'ControlLoop'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyInstrumentedFunction'})
MERGE (p:OntologyClass {name: 'Function'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Interlock'})
MERGE (p:OntologyClass {name: 'SafetyInstrumentedFunction'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PermissiveInterlock'})
MERGE (p:OntologyClass {name: 'Interlock'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProtectiveInterlock'})
MERGE (p:OntologyClass {name: 'Interlock'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'EmergencyShutdown'})
MERGE (p:OntologyClass {name: 'SafetyInstrumentedFunction'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyInstrumentedSystem'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Setpoint'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessVariable'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AlarmLimit'})
MERGE (p:OntologyClass {name: 'Quality'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Alarm'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AdvisoryAlarm'})
MERGE (p:OntologyClass {name: 'Alarm'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StandardAlarm'})
MERGE (p:OntologyClass {name: 'Alarm'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CriticalAlarm'})
MERGE (p:OntologyClass {name: 'Alarm'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Bypass'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ScanCycle'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProcessTrip'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProofTest'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FirmwareChange'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OperatorRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ShiftSupervisorRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ControlsEngineerRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SafetyAuthorityRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Controller'})
MERGE (t:OntologyClass {name: 'FieldDevice'})
MERGE (s)-[:RELATION {name: 'controls'}]->(t);
MERGE (s:OntologyClass {name: 'Controller'})
MERGE (t:OntologyClass {name: 'Sensor'})
MERGE (s)-[:RELATION {name: 'reads_from'}]->(t);
MERGE (s:OntologyClass {name: 'ScadaServer'})
MERGE (t:OntologyClass {name: 'Controller'})
MERGE (s)-[:RELATION {name: 'supervises'}]->(t);
MERGE (s:OntologyClass {name: 'HmiStation'})
MERGE (t:OntologyClass {name: 'ScadaServer'})
MERGE (s)-[:RELATION {name: 'displays_on'}]->(t);
MERGE (s:OntologyClass {name: 'Controller'})
MERGE (t:OntologyClass {name: 'PurdueLevel'})
MERGE (s)-[:RELATION {name: 'resides_at_level'}]->(t);
MERGE (s:OntologyClass {name: 'Controller'})
MERGE (t:OntologyClass {name: 'IndustrialNetwork'})
MERGE (s)-[:RELATION {name: 'connected_to'}]->(t);
MERGE (s:OntologyClass {name: 'ShutdownValve'})
MERGE (t:OntologyClass {name: 'ProcessUnit'})
MERGE (s)-[:RELATION {name: 'protects'}]->(t);
MERGE (s:OntologyClass {name: 'Interlock'})
MERGE (t:OntologyClass {name: 'ProcessTrip'})
MERGE (s)-[:RELATION {name: 'initiates'}]->(t);
MERGE (s:OntologyClass {name: 'Sensor'})
MERGE (t:OntologyClass {name: 'Alarm'})
MERGE (s)-[:RELATION {name: 'raises'}]->(t);
MERGE (s:OntologyClass {name: 'Alarm'})
MERGE (t:OntologyClass {name: 'OperatorRole'})
MERGE (s)-[:RELATION {name: 'acknowledged_by'}]->(t);
MERGE (s:OntologyClass {name: 'Bypass'})
MERGE (t:OntologyClass {name: 'Interlock'})
MERGE (s)-[:RELATION {name: 'bypasses'}]->(t);
MERGE (s:OntologyClass {name: 'Bypass'})
MERGE (t:OntologyClass {name: 'SafetyAuthorityRole'})
MERGE (s)-[:RELATION {name: 'authorised_by'}]->(t);
MERGE (s:OntologyClass {name: 'Plc'})
MERGE (t:OntologyClass {name: 'ControlProgram'})
MERGE (s)-[:RELATION {name: 'executes'}]->(t);
MERGE (s:OntologyClass {name: 'FieldDevice'})
MERGE (t:OntologyClass {name: 'ProcessUnit'})
MERGE (s)-[:RELATION {name: 'located_in'}]->(t);
// Axiom Validations
// Axiom validation: Controller is_internet_facing eq False
MATCH (n:`Controller`) WHERE NOT (n.`is_internet_facing` = false) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Plc scan_time_ms gt 0
MATCH (n:`Plc`) WHERE NOT (n.`scan_time_ms` > 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Plc scan_time_ms lt 500
MATCH (n:`Plc`) WHERE NOT (n.`scan_time_ms` < 500) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SafetyInstrumentedFunction sil_level gte 1
MATCH (n:`SafetyInstrumentedFunction`) WHERE NOT (n.`sil_level` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SafetyInstrumentedFunction sil_level lte 4
MATCH (n:`SafetyInstrumentedFunction`) WHERE NOT (n.`sil_level` <= 4) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Setpoint setpoint_value gte 0
MATCH (n:`Setpoint`) WHERE NOT (n.`setpoint_value` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Setpoint setpoint_value lte 10000
MATCH (n:`Setpoint`) WHERE NOT (n.`setpoint_value` <= 10000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Alarm alarm_priority gte 1
MATCH (n:`Alarm`) WHERE NOT (n.`alarm_priority` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Alarm alarm_priority lte 3
MATCH (n:`Alarm`) WHERE NOT (n.`alarm_priority` <= 3) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: CriticalAlarm requires_acknowledgement eq True
MATCH (n:`CriticalAlarm`) WHERE NOT (n.`requires_acknowledgement` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Bypass bypass_duration_hours gt 0
MATCH (n:`Bypass`) WHERE NOT (n.`bypass_duration_hours` > 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Bypass bypass_duration_hours lte 8
MATCH (n:`Bypass`) WHERE NOT (n.`bypass_duration_hours` <= 8) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: FirmwareChange firmware_signed eq True
MATCH (n:`FirmwareChange`) WHERE NOT (n.`firmware_signed` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall c (SafetyController(c) implies not Plc(c))
//   forall b (Bypass(b) implies exists r (SafetyAuthorityRole(r) and authorised_by(b, r)))
//   forall t (ProcessTrip(t) and is_tripped = True implies exists i (Interlock(i) and initiates(i, t)))
//   forall x (Alarm(x) implies not Interlock(x))
