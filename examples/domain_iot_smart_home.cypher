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
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Household'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Resident'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Guest'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Child'})
MERGE (p:OntologyClass {name: 'Resident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Home'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Room'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Bedroom'})
MERGE (p:OntologyClass {name: 'Room'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Kitchen'})
MERGE (p:OntologyClass {name: 'Room'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LivingRoom'})
MERGE (p:OntologyClass {name: 'Room'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Bathroom'})
MERGE (p:OntologyClass {name: 'Room'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Garage'})
MERGE (p:OntologyClass {name: 'Room'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SmartDevice'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Hub'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThreadBorderRouter'})
MERGE (p:OntologyClass {name: 'Hub'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ZigbeeCoordinator'})
MERGE (p:OntologyClass {name: 'Hub'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Light'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Thermostat'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SmartPlug'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DoorLock'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Camera'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DoorbellCamera'})
MERGE (p:OntologyClass {name: 'Camera'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SmartSpeaker'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MotionSensor'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ContactSensor'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SmokeDetector'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LeakSensor'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Oven'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RobotVacuum'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GarageDoorOpener'})
MERGE (p:OntologyClass {name: 'SmartDevice'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Radio'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'WifiRadio'})
MERGE (p:OntologyClass {name: 'Radio'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThreadRadio'})
MERGE (p:OntologyClass {name: 'Radio'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ZigbeeRadio'})
MERGE (p:OntologyClass {name: 'Radio'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BluetoothRadio'})
MERGE (p:OntologyClass {name: 'Radio'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CloudService'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MobileApp'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Automation'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Trigger'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TimeTrigger'})
MERGE (p:OntologyClass {name: 'Trigger'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PresenceTrigger'})
MERGE (p:OntologyClass {name: 'Trigger'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SensorTrigger'})
MERGE (p:OntologyClass {name: 'Trigger'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VoiceTrigger'})
MERGE (p:OntologyClass {name: 'Trigger'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Condition'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Action'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Scene'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AutomationRun'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FirmwareImage'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SecurityPatch'})
MERGE (p:OntologyClass {name: 'FirmwareImage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FeatureRelease'})
MERGE (p:OntologyClass {name: 'FirmwareImage'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FirmwareUpdate'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RollbackEvent'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PersonalData'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'VideoRecording'})
MERGE (p:OntologyClass {name: 'PersonalData'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AudioRecording'})
MERGE (p:OntologyClass {name: 'PersonalData'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PresenceHistory'})
MERGE (p:OntologyClass {name: 'PersonalData'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DeviceUsageLog'})
MERGE (p:OntologyClass {name: 'PersonalData'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Consent'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConsentGrant'})
MERGE (p:OntologyClass {name: 'Consent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ConsentWithdrawal'})
MERGE (p:OntologyClass {name: 'Consent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PrivacyPolicy'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataSharingAgreement'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DataSubjectRequest'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DeletionRequest'})
MERGE (p:OntologyClass {name: 'DataSubjectRequest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ExportRequest'})
MERGE (p:OntologyClass {name: 'DataSubjectRequest'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OwnerRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AdminRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MemberRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GuestAccessRole'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'SmartDevice'})
MERGE (t:OntologyClass {name: 'Hub'})
MERGE (s)-[:RELATION {name: 'paired_with'}]->(t);
MERGE (s:OntologyClass {name: 'SmartDevice'})
MERGE (t:OntologyClass {name: 'Room'})
MERGE (s)-[:RELATION {name: 'located_in'}]->(t);
MERGE (s:OntologyClass {name: 'Room'})
MERGE (t:OntologyClass {name: 'Home'})
MERGE (s)-[:RELATION {name: 'part_of_home'}]->(t);
MERGE (s:OntologyClass {name: 'SmartDevice'})
MERGE (t:OntologyClass {name: 'Radio'})
MERGE (s)-[:RELATION {name: 'uses_radio'}]->(t);
MERGE (s:OntologyClass {name: 'Hub'})
MERGE (t:OntologyClass {name: 'CloudService'})
MERGE (s)-[:RELATION {name: 'syncs_with'}]->(t);
MERGE (s:OntologyClass {name: 'MobileApp'})
MERGE (t:OntologyClass {name: 'Hub'})
MERGE (s)-[:RELATION {name: 'controls_via'}]->(t);
MERGE (s:OntologyClass {name: 'Resident'})
MERGE (t:OntologyClass {name: 'SmartDevice'})
MERGE (s)-[:RELATION {name: 'owns'}]->(t);
MERGE (s:OntologyClass {name: 'Resident'})
MERGE (t:OntologyClass {name: 'Household'})
MERGE (s)-[:RELATION {name: 'member_of'}]->(t);
MERGE (s:OntologyClass {name: 'Trigger'})
MERGE (t:OntologyClass {name: 'Automation'})
MERGE (s)-[:RELATION {name: 'triggers_automation'}]->(t);
MERGE (s:OntologyClass {name: 'Automation'})
MERGE (t:OntologyClass {name: 'Action'})
MERGE (s)-[:RELATION {name: 'performs'}]->(t);
MERGE (s:OntologyClass {name: 'Action'})
MERGE (t:OntologyClass {name: 'SmartDevice'})
MERGE (s)-[:RELATION {name: 'targets'}]->(t);
MERGE (s:OntologyClass {name: 'FirmwareUpdate'})
MERGE (t:OntologyClass {name: 'SmartDevice'})
MERGE (s)-[:RELATION {name: 'applies_to'}]->(t);
MERGE (s:OntologyClass {name: 'FirmwareUpdate'})
MERGE (t:OntologyClass {name: 'FirmwareImage'})
MERGE (s)-[:RELATION {name: 'installs'}]->(t);
MERGE (s:OntologyClass {name: 'PersonalData'})
MERGE (t:OntologyClass {name: 'SmartDevice'})
MERGE (s)-[:RELATION {name: 'captured_by'}]->(t);
MERGE (s:OntologyClass {name: 'PersonalData'})
MERGE (t:OntologyClass {name: 'Person'})
MERGE (s)-[:RELATION {name: 'concerns'}]->(t);
MERGE (s:OntologyClass {name: 'Consent'})
MERGE (t:OntologyClass {name: 'Person'})
MERGE (s)-[:RELATION {name: 'granted_by'}]->(t);
MERGE (s:OntologyClass {name: 'Consent'})
MERGE (t:OntologyClass {name: 'PersonalData'})
MERGE (s)-[:RELATION {name: 'covers'}]->(t);
MERGE (s:OntologyClass {name: 'SmartDevice'})
MERGE (t:OntologyClass {name: 'PrivacyPolicy'})
MERGE (s)-[:RELATION {name: 'governed_by'}]->(t);
// Axiom Validations
// Axiom validation: SmartDevice battery_pct gte 0
MATCH (n:`SmartDevice`) WHERE NOT (n.`battery_pct` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SmartDevice battery_pct lte 100
MATCH (n:`SmartDevice`) WHERE NOT (n.`battery_pct` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: SmartDevice default_password_changed eq True
MATCH (n:`SmartDevice`) WHERE NOT (n.`default_password_changed` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Thermostat target_temp_c gte 5
MATCH (n:`Thermostat`) WHERE NOT (n.`target_temp_c` >= 5) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Thermostat target_temp_c lte 35
MATCH (n:`Thermostat`) WHERE NOT (n.`target_temp_c` <= 35) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Automation runs_unattended eq False
MATCH (n:`Automation`) WHERE NOT (n.`runs_unattended` = false) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: FirmwareImage is_signed eq True
MATCH (n:`FirmwareImage`) WHERE NOT (n.`is_signed` = true) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: FirmwareUpdate rollout_pct gte 0
MATCH (n:`FirmwareUpdate`) WHERE NOT (n.`rollout_pct` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: FirmwareUpdate rollout_pct lte 100
MATCH (n:`FirmwareUpdate`) WHERE NOT (n.`rollout_pct` <= 100) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: PersonalData retention_days gte 1
MATCH (n:`PersonalData`) WHERE NOT (n.`retention_days` >= 1) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: PersonalData retention_days lte 365
MATCH (n:`PersonalData`) WHERE NOT (n.`retention_days` <= 365) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: VideoRecording is_end_to_end_encrypted eq True
MATCH (n:`VideoRecording`) WHERE NOT (n.`is_end_to_end_encrypted` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall p (PersonalData(p) and is_shared_with_third_party = True implies exists c (Consent(c) and covers(c, p)))
//   forall v (VideoRecording(v) implies exists c (ConsentGrant(c) and covers(c, v)))
//   forall s (SmartSpeaker(s) and is_listening = True implies has_hardware_mute = True)
//   forall c (Camera(c) implies not SmartSpeaker(c))
//   forall c (ConsentGrant(c) implies not ConsentWithdrawal(c))
