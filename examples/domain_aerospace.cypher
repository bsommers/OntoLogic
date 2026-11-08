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
MERGE (n:OntologyClass {name: 'Aircraft'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FixedWingAircraft'})
MERGE (p:OntologyClass {name: 'Aircraft'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Airliner'})
MERGE (p:OntologyClass {name: 'FixedWingAircraft'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CargoAircraft'})
MERGE (p:OntologyClass {name: 'FixedWingAircraft'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BusinessJet'})
MERGE (p:OntologyClass {name: 'FixedWingAircraft'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Rotorcraft'})
MERGE (p:OntologyClass {name: 'Aircraft'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Helicopter'})
MERGE (p:OntologyClass {name: 'Rotorcraft'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'UnmannedAircraft'})
MERGE (p:OntologyClass {name: 'Aircraft'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AircraftComponent'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Airframe'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Wing'})
MERGE (p:OntologyClass {name: 'Airframe'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Fuselage'})
MERGE (p:OntologyClass {name: 'Airframe'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Empennage'})
MERGE (p:OntologyClass {name: 'Airframe'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Powerplant'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TurbofanEngine'})
MERGE (p:OntologyClass {name: 'Powerplant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Propeller'})
MERGE (p:OntologyClass {name: 'Powerplant'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LandingGear'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FlightControlSurface'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Avionics'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FlightManagementComputer'})
MERGE (p:OntologyClass {name: 'Avionics'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Transponder'})
MERGE (p:OntologyClass {name: 'Avionics'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FuelSystem'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HydraulicSystem'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LifeLimitedPart'})
MERGE (p:OntologyClass {name: 'AircraftComponent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SparePart'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Organization'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PilotInCommand'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FirstOfficer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CertifyingEngineer'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AirworthinessInspector'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Operator'})
MERGE (p:OntologyClass {name: 'Role'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MaintenanceOrganization'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Regulator'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Airport'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Runway'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CertificationDocument'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TypeCertificate'})
MERGE (p:OntologyClass {name: 'CertificationDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AirworthinessCertificate'})
MERGE (p:OntologyClass {name: 'CertificationDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AirworthinessDirective'})
MERGE (p:OntologyClass {name: 'CertificationDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PilotLicense'})
MERGE (p:OntologyClass {name: 'CertificationDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MedicalCertificate'})
MERGE (p:OntologyClass {name: 'CertificationDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MaintenanceRelease'})
MERGE (p:OntologyClass {name: 'CertificationDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MinimumEquipmentList'})
MERGE (p:OntologyClass {name: 'CertificationDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FlightPlan'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TechnicalLogEntry'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Defect'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DeferredDefect'})
MERGE (p:OntologyClass {name: 'Defect'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MaintenanceProcess'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'MaintenanceCheck'})
MERGE (p:OntologyClass {name: 'MaintenanceProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'LineCheck'})
MERGE (p:OntologyClass {name: 'MaintenanceCheck'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ACheck'})
MERGE (p:OntologyClass {name: 'MaintenanceCheck'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CCheck'})
MERGE (p:OntologyClass {name: 'MaintenanceCheck'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HeavyCheck'})
MERGE (p:OntologyClass {name: 'MaintenanceCheck'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ComponentOverhaul'})
MERGE (p:OntologyClass {name: 'MaintenanceProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'NonDestructiveInspection'})
MERGE (p:OntologyClass {name: 'MaintenanceProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DefectRectification'})
MERGE (p:OntologyClass {name: 'MaintenanceProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ComplianceAction'})
MERGE (p:OntologyClass {name: 'MaintenanceProcess'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FlightOperation'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Flight'})
MERGE (p:OntologyClass {name: 'FlightOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CommercialFlight'})
MERGE (p:OntologyClass {name: 'Flight'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FerryFlight'})
MERGE (p:OntologyClass {name: 'Flight'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TestFlight'})
MERGE (p:OntologyClass {name: 'Flight'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Takeoff'})
MERGE (p:OntologyClass {name: 'FlightOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Landing'})
MERGE (p:OntologyClass {name: 'FlightOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Cruise'})
MERGE (p:OntologyClass {name: 'FlightOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PreflightInspection'})
MERGE (p:OntologyClass {name: 'FlightOperation'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Incident'})
MERGE (p:OntologyClass {name: 'Occurrent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RunwayExcursion'})
MERGE (p:OntologyClass {name: 'Incident'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'AircraftComponent'})
MERGE (t:OntologyClass {name: 'Aircraft'})
MERGE (s)-[:RELATION {name: 'installed_on'}]->(t);
MERGE (s:OntologyClass {name: 'Aircraft'})
MERGE (t:OntologyClass {name: 'AirworthinessCertificate'})
MERGE (s)-[:RELATION {name: 'has_certificate'}]->(t);
MERGE (s:OntologyClass {name: 'Aircraft'})
MERGE (t:OntologyClass {name: 'TypeCertificate'})
MERGE (s)-[:RELATION {name: 'type_certified_by'}]->(t);
MERGE (s:OntologyClass {name: 'Aircraft'})
MERGE (t:OntologyClass {name: 'Operator'})
MERGE (s)-[:RELATION {name: 'operated_by'}]->(t);
MERGE (s:OntologyClass {name: 'Aircraft'})
MERGE (t:OntologyClass {name: 'Flight'})
MERGE (s)-[:RELATION {name: 'performs_flight'}]->(t);
MERGE (s:OntologyClass {name: 'Person'})
MERGE (t:OntologyClass {name: 'Flight'})
MERGE (s)-[:RELATION {name: 'commands'}]->(t);
MERGE (s:OntologyClass {name: 'Person'})
MERGE (t:OntologyClass {name: 'PilotLicense'})
MERGE (s)-[:RELATION {name: 'holds_license'}]->(t);
MERGE (s:OntologyClass {name: 'Flight'})
MERGE (t:OntologyClass {name: 'Airport'})
MERGE (s)-[:RELATION {name: 'departs_from'}]->(t);
MERGE (s:OntologyClass {name: 'Flight'})
MERGE (t:OntologyClass {name: 'Airport'})
MERGE (s)-[:RELATION {name: 'arrives_at'}]->(t);
MERGE (s:OntologyClass {name: 'Flight'})
MERGE (t:OntologyClass {name: 'FlightPlan'})
MERGE (s)-[:RELATION {name: 'follows_plan'}]->(t);
MERGE (s:OntologyClass {name: 'MaintenanceCheck'})
MERGE (t:OntologyClass {name: 'Aircraft'})
MERGE (s)-[:RELATION {name: 'inspects'}]->(t);
MERGE (s:OntologyClass {name: 'MaintenanceProcess'})
MERGE (t:OntologyClass {name: 'MaintenanceOrganization'})
MERGE (s)-[:RELATION {name: 'performed_by'}]->(t);
MERGE (s:OntologyClass {name: 'MaintenanceRelease'})
MERGE (t:OntologyClass {name: 'CertifyingEngineer'})
MERGE (s)-[:RELATION {name: 'certified_by'}]->(t);
MERGE (s:OntologyClass {name: 'MaintenanceRelease'})
MERGE (t:OntologyClass {name: 'Aircraft'})
MERGE (s)-[:RELATION {name: 'releases'}]->(t);
MERGE (s:OntologyClass {name: 'AirworthinessDirective'})
MERGE (t:OntologyClass {name: 'Aircraft'})
MERGE (s)-[:RELATION {name: 'applies_to'}]->(t);
MERGE (s:OntologyClass {name: 'Defect'})
MERGE (t:OntologyClass {name: 'AircraftComponent'})
MERGE (s)-[:RELATION {name: 'raised_against'}]->(t);
MERGE (s:OntologyClass {name: 'DefectRectification'})
MERGE (t:OntologyClass {name: 'Defect'})
MERGE (s)-[:RELATION {name: 'rectifies'}]->(t);
MERGE (s:OntologyClass {name: 'CertificationDocument'})
MERGE (t:OntologyClass {name: 'Regulator'})
MERGE (s)-[:RELATION {name: 'issued_by'}]->(t);
MERGE (s:OntologyClass {name: 'Incident'})
MERGE (t:OntologyClass {name: 'Aircraft'})
MERGE (s)-[:RELATION {name: 'involves'}]->(t);
// Axiom Validations
// Axiom validation: LifeLimitedPart flight_cycles gte 0
MATCH (n:`LifeLimitedPart`) WHERE NOT (n.`flight_cycles` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: LifeLimitedPart flight_cycles lte 50000
MATCH (n:`LifeLimitedPart`) WHERE NOT (n.`flight_cycles` <= 50000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Flight takeoff_mass_kg gt 0
MATCH (n:`Flight`) WHERE NOT (n.`takeoff_mass_kg` > 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Flight takeoff_mass_kg lte 600000
MATCH (n:`Flight`) WHERE NOT (n.`takeoff_mass_kg` <= 600000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Flight fuel_reserve_kg gt 0
MATCH (n:`Flight`) WHERE NOT (n.`fuel_reserve_kg` > 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Flight cruise_altitude_ft gte 0
MATCH (n:`Flight`) WHERE NOT (n.`cruise_altitude_ft` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Flight cruise_altitude_ft lte 51000
MATCH (n:`Flight`) WHERE NOT (n.`cruise_altitude_ft` <= 51000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: CommercialFlight crew_size gte 2
MATCH (n:`CommercialFlight`) WHERE NOT (n.`crew_size` >= 2) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall a (Aircraft(a) and is_airworthy = True implies exists c (has_certificate(a, c)))
//   forall a (Aircraft(a) and is_released_to_service = True implies is_airworthy = True)
//   forall a (Aircraft(a) and gt(hours_since_check, 600) implies is_airworthy = False)
//   forall p (forall f (commands(p, f) implies exists l (holds_license(p, l))))
//   forall a (Aircraft(a) and is_airworthy = True implies open_defect_count = 0)
//   forall m (MaintenanceRelease(m) implies exists e (certified_by(m, e)))
//   forall x (not Aircraft(x) and AircraftComponent(x))
//   forall x (not Flight(x) and MaintenanceProcess(x))
