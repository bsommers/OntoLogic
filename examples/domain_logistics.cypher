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
MERGE (n:OntologyClass {name: 'Organization'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Shipper'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Consignee'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Carrier'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RoadCarrier'})
MERGE (p:OntologyClass {name: 'Carrier'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'AirCarrier'})
MERGE (p:OntologyClass {name: 'Carrier'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OceanCarrier'})
MERGE (p:OntologyClass {name: 'Carrier'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RailCarrier'})
MERGE (p:OntologyClass {name: 'Carrier'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Supplier'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustomsBroker'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ThirdPartyLogisticsProvider'})
MERGE (p:OntologyClass {name: 'Organization'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Facility'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Warehouse'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DistributionCenter'})
MERGE (p:OntologyClass {name: 'Warehouse'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CrossDock'})
MERGE (p:OntologyClass {name: 'Warehouse'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ColdStore'})
MERGE (p:OntologyClass {name: 'Warehouse'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'HazmatStore'})
MERGE (p:OntologyClass {name: 'Warehouse'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Port'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Airport'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'RailTerminal'})
MERGE (p:OntologyClass {name: 'Facility'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StorageZone'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DockDoor'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StorageLocation'})
MERGE (p:OntologyClass {name: 'Site'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TransportAsset'})
MERGE (p:OntologyClass {name: 'Object'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Vehicle'})
MERGE (p:OntologyClass {name: 'TransportAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Truck'})
MERGE (p:OntologyClass {name: 'Vehicle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReeferTruck'})
MERGE (p:OntologyClass {name: 'Truck'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Van'})
MERGE (p:OntologyClass {name: 'Vehicle'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Aircraft'})
MERGE (p:OntologyClass {name: 'TransportAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Vessel'})
MERGE (p:OntologyClass {name: 'TransportAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Container'})
MERGE (p:OntologyClass {name: 'TransportAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ReeferContainer'})
MERGE (p:OntologyClass {name: 'Container'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pallet'})
MERGE (p:OntologyClass {name: 'TransportAsset'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Person'})
MERGE (p:OntologyClass {name: 'Agent'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Driver'})
MERGE (p:OntologyClass {name: 'Person'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Goods'})
MERGE (p:OntologyClass {name: 'MaterialEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'GeneralCargo'})
MERGE (p:OntologyClass {name: 'Goods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PerishableGoods'})
MERGE (p:OntologyClass {name: 'Goods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FrozenGoods'})
MERGE (p:OntologyClass {name: 'PerishableGoods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ChilledGoods'})
MERGE (p:OntologyClass {name: 'PerishableGoods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pharmaceuticals'})
MERGE (p:OntologyClass {name: 'Goods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DangerousGoods'})
MERGE (p:OntologyClass {name: 'Goods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'FlammableGoods'})
MERGE (p:OntologyClass {name: 'DangerousGoods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CorrosiveGoods'})
MERGE (p:OntologyClass {name: 'DangerousGoods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OversizedGoods'})
MERGE (p:OntologyClass {name: 'Goods'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'StockKeepingUnit'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InventoryRecord'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Lot'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Order'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PurchaseOrder'})
MERGE (p:OntologyClass {name: 'Order'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'SalesOrder'})
MERGE (p:OntologyClass {name: 'Order'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TransferOrder'})
MERGE (p:OntologyClass {name: 'Order'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Shipment'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InboundShipment'})
MERGE (p:OntologyClass {name: 'Shipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'OutboundShipment'})
MERGE (p:OntologyClass {name: 'Shipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ColdChainShipment'})
MERGE (p:OntologyClass {name: 'Shipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'InternationalShipment'})
MERGE (p:OntologyClass {name: 'Shipment'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Leg'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Pickup'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Delivery'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Receiving'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PutAway'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Picking'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Packing'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustomsClearance'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'Exception'})
MERGE (p:OntologyClass {name: 'Process'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'DelayException'})
MERGE (p:OntologyClass {name: 'Exception'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TemperatureExcursion'})
MERGE (p:OntologyClass {name: 'Exception'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ShippingDocument'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'BillOfLading'})
MERGE (p:OntologyClass {name: 'ShippingDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CommercialInvoice'})
MERGE (p:OntologyClass {name: 'ShippingDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'PackingList'})
MERGE (p:OntologyClass {name: 'ShippingDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'CustomsDeclaration'})
MERGE (p:OntologyClass {name: 'ShippingDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'ProofOfDelivery'})
MERGE (p:OntologyClass {name: 'ShippingDocument'})
MERGE (n)-[:SUBCLASS_OF]->(p);
MERGE (n:OntologyClass {name: 'TemperatureLog'})
MERGE (p:OntologyClass {name: 'InformationContentEntity'})
MERGE (n)-[:SUBCLASS_OF]->(p);
// Relationships
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Shipper'})
MERGE (s)-[:RELATION {name: 'shipped_by'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Consignee'})
MERGE (s)-[:RELATION {name: 'consigned_to'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Carrier'})
MERGE (s)-[:RELATION {name: 'carried_by'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Goods'})
MERGE (s)-[:RELATION {name: 'transports'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Leg'})
MERGE (s)-[:RELATION {name: 'has_leg'}]->(t);
MERGE (s:OntologyClass {name: 'Leg'})
MERGE (t:OntologyClass {name: 'TransportAsset'})
MERGE (s)-[:RELATION {name: 'leg_uses'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Facility'})
MERGE (s)-[:RELATION {name: 'originates_at'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Facility'})
MERGE (s)-[:RELATION {name: 'destined_for'}]->(t);
MERGE (s:OntologyClass {name: 'InventoryRecord'})
MERGE (t:OntologyClass {name: 'StorageLocation'})
MERGE (s)-[:RELATION {name: 'stored_in'}]->(t);
MERGE (s:OntologyClass {name: 'InventoryRecord'})
MERGE (t:OntologyClass {name: 'StockKeepingUnit'})
MERGE (s)-[:RELATION {name: 'tracks'}]->(t);
MERGE (s:OntologyClass {name: 'StorageLocation'})
MERGE (t:OntologyClass {name: 'Warehouse'})
MERGE (s)-[:RELATION {name: 'located_in'}]->(t);
MERGE (s:OntologyClass {name: 'StorageZone'})
MERGE (t:OntologyClass {name: 'Warehouse'})
MERGE (s)-[:RELATION {name: 'zone_of'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'Order'})
MERGE (s)-[:RELATION {name: 'fulfils'}]->(t);
MERGE (s:OntologyClass {name: 'Shipment'})
MERGE (t:OntologyClass {name: 'ShippingDocument'})
MERGE (s)-[:RELATION {name: 'documented_by'}]->(t);
MERGE (s:OntologyClass {name: 'ColdChainShipment'})
MERGE (t:OntologyClass {name: 'TemperatureLog'})
MERGE (s)-[:RELATION {name: 'monitored_by'}]->(t);
MERGE (s:OntologyClass {name: 'Vehicle'})
MERGE (t:OntologyClass {name: 'Carrier'})
MERGE (s)-[:RELATION {name: 'operated_by'}]->(t);
MERGE (s:OntologyClass {name: 'Truck'})
MERGE (t:OntologyClass {name: 'Driver'})
MERGE (s)-[:RELATION {name: 'driven_by'}]->(t);
MERGE (s:OntologyClass {name: 'CustomsClearance'})
MERGE (t:OntologyClass {name: 'CustomsBroker'})
MERGE (s)-[:RELATION {name: 'cleared_by'}]->(t);
MERGE (s:OntologyClass {name: 'Goods'})
MERGE (t:OntologyClass {name: 'Warehouse'})
MERGE (s)-[:RELATION {name: 'stored_with'}]->(t);
MERGE (s:OntologyClass {name: 'DangerousGoods'})
MERGE (t:OntologyClass {name: 'Goods'})
MERGE (s)-[:RELATION {name: 'segregated_from'}]->(t);
// Axiom Validations
// Axiom validation: ColdStore cold_store_temp_c lte 8
MATCH (n:`ColdStore`) WHERE NOT (n.`cold_store_temp_c` <= 8) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Vehicle loaded_weight_kg gte 0
MATCH (n:`Vehicle`) WHERE NOT (n.`loaded_weight_kg` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Vehicle loaded_weight_kg lte 44000
MATCH (n:`Vehicle`) WHERE NOT (n.`loaded_weight_kg` <= 44000) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Driver driving_hours_today lte 9
MATCH (n:`Driver`) WHERE NOT (n.`driving_hours_today` <= 9) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: FrozenGoods frozen_goods_temp_c lte -18
MATCH (n:`FrozenGoods`) WHERE NOT (n.`frozen_goods_temp_c` <= -18) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: ChilledGoods chilled_goods_temp_c gte 2
MATCH (n:`ChilledGoods`) WHERE NOT (n.`chilled_goods_temp_c` >= 2) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: ChilledGoods chilled_goods_temp_c lte 8
MATCH (n:`ChilledGoods`) WHERE NOT (n.`chilled_goods_temp_c` <= 8) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Pharmaceuticals pharma_temp_c gte 2
MATCH (n:`Pharmaceuticals`) WHERE NOT (n.`pharma_temp_c` >= 2) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: Pharmaceuticals pharma_temp_c lte 8
MATCH (n:`Pharmaceuticals`) WHERE NOT (n.`pharma_temp_c` <= 8) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: InventoryRecord on_hand_quantity gte 0
MATCH (n:`InventoryRecord`) WHERE NOT (n.`on_hand_quantity` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: InventoryRecord reserved_quantity gte 0
MATCH (n:`InventoryRecord`) WHERE NOT (n.`reserved_quantity` >= 0) RETURN elementId(n) AS invalid_node_id;
// Axiom validation: InternationalShipment has_customs_declaration eq True
MATCH (n:`InternationalShipment`) WHERE NOT (n.`has_customs_declaration` = true) RETURN elementId(n) AS invalid_node_id;

// WARNING: The following axioms could not be mapped to field constraints:
//   forall x (not Shipper(x) and Carrier(x))
//   forall x (not DangerousGoods(x) and GeneralCargo(x))
//   forall x (not InboundShipment(x) and OutboundShipment(x))
//   forall x (not FrozenGoods(x) and ChilledGoods(x))
//   forall x (not HazmatStore(x) and ColdStore(x))
//   forall s (Shipment(s) and is_delivered = True implies has_proof_of_delivery = True)
