# Domain Examples Gallery

Complete, runnable models grouped by sector. Each links to its `.logic` source
and the D2 diagram rendered from it. Start with the foundations if you want to
see the upper-ontology pattern; start with your own sector if you want a template.

- [Industrial and OT](#industrial-and-ot) | [IoT](#iot) | [Security](#security) |
  [Software and engineering](#software-and-engineering) |
  [Science, research and health](#science-research-and-health) |
  [Customer and business](#customer-and-business) |
  [Food, logistics and agriculture](#food-logistics-and-agriculture) |
  [Foundations](#foundations)
- [Run an example](#run-an-example)
- [How the domain_* examples are verified](#how-the-domain_-examples-are-verified)

Examples are sources to adapt, not fixed products. For reusable building blocks
(BFO, CCO, ATT&CK, NIST and others) see the [standard library](../standard-library.md).

## Industrial and OT

Plants, control systems and factories.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`domain_ics`](../../examples/domain_ics.logic) | Industrial control systems: PLCs, SCADA/HMI, Purdue-model levels, safety instrumented systems, setpoints, alarms and interlocks. | [diagram](../../examples/domain_ics.d2.svg) |
| [`domain_iiot`](../../examples/domain_iiot.logic) | Industrial IoT: edge gateways, MQTT / OPC UA telemetry and asset condition monitoring. | [diagram](../../examples/domain_iiot.d2.svg) |
| [`domain_mining`](../../examples/domain_mining.logic) | Mining operations: equipment, processes and safety, on a condensed BFO layer. | [diagram](../../examples/domain_mining.d2.svg) |
| [`domain_semiconductor_fab`](../../examples/domain_semiconductor_fab.logic) | Semiconductor wafer fab: lots, wafers, process steps, tools, recipes and cleanroom classes. | [diagram](../../examples/domain_semiconductor_fab.d2.svg) |
| [`domain_aerospace`](../../examples/domain_aerospace.logic) | Aerospace: aircraft, components, certification, maintenance checks, flight operations and crews. | [diagram](../../examples/domain_aerospace.d2.svg) |
| [`smart_factory`](../../examples/smart_factory.logic) | Smart factory taxonomy with bounded sensor properties and axioms. | [diagram](../../examples/smart_factory.d2.svg) |
| [`dough_factory`](../../examples/dough_factory.logic) | Food-plant production line: processing and monitoring equipment. | [diagram](../../examples/dough_factory.d2.svg) |
| [`car_manufacturer`](../../examples/car_manufacturer.logic) | Vehicle manufacturing: taxonomy, properties and axioms. | [diagram](../../examples/car_manufacturer.d2.svg) |
| [`smart_grid_relational`](../../examples/smart_grid_relational.logic) | Smart-grid topology using relations between grid elements. | none yet |

## IoT

Connected devices and messaging.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`domain_iot_smart_home`](../../examples/domain_iot_smart_home.logic) | Consumer smart home: devices, hubs, rooms, automations and firmware updates. | [diagram](../../examples/domain_iot_smart_home.d2.svg) |
| [`mqtt_operational`](../../examples/mqtt_operational.logic) | MQTT-centered operational domain: design, sell and operate layout. | [diagram](../../examples/mqtt_operational.d2.svg) |
| [`mqtt_ecosystem_unified`](../../examples/mqtt_ecosystem_unified.logic) | Unified MQTT ecosystem on a full BFO upper level. | [diagram](../../examples/mqtt_ecosystem_unified.d2.svg) |

## Security

Threats, trust and operations.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`domain_cybersecurity_soc`](../../examples/domain_cybersecurity_soc.logic) | Security operations: assets, vulnerabilities, detections, alerts, incidents and analysts. | [diagram](../../examples/domain_cybersecurity_soc.d2.svg) |
| [`domain_security_trust`](../../examples/domain_security_trust.logic) | Digital trust and security: security artifacts, roles and trust relations. | [diagram](../../examples/domain_security_trust.d2.svg) |
| [`security_policy`](../../examples/security_policy.logic) | Network security policy: untrusted nodes may not reach the admin panel. | [diagram](../../examples/security_policy.d2.svg) |

## Software and engineering

Building and running software and systems.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`domain_software_delivery`](../../examples/domain_software_delivery.logic) | Software delivery: repositories, commits, pull requests, reviews, builds, tests, releases and production incidents. | [diagram](../../examples/domain_software_delivery.d2.svg) |
| [`domain_systems_engineering`](../../examples/domain_systems_engineering.logic) | Systems engineering: requirements, system elements, interfaces, verification, change requests and traceability. | [diagram](../../examples/domain_systems_engineering.d2.svg) |
| [`domain_cloud_datacenter`](../../examples/domain_cloud_datacenter.logic) | Cloud and datacenter: physical and virtual infrastructure and software services. | [diagram](../../examples/domain_cloud_datacenter.d2.svg) |

## Science, research and health

Laboratories, research and clinical care.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`domain_science_lab`](../../examples/domain_science_lab.logic) | Laboratory science: samples, specimens, instruments, calibration, protocols, experiments and custody. | [diagram](../../examples/domain_science_lab.d2.svg) |
| [`domain_research_projects`](../../examples/domain_research_projects.logic) | Research projects: funding, investigators, institutions, studies, datasets and publications. | [diagram](../../examples/domain_research_projects.d2.svg) |
| [`domain_clinical_medicine`](../../examples/domain_clinical_medicine.logic) | Clinical medicine: patients, encounters, clinicians, diagnoses, orders and medications. | [diagram](../../examples/domain_clinical_medicine.d2.svg) |

## Customer and business

Service and success operations.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`domain_customer_service`](../../examples/domain_customer_service.logic) | Customer service: tickets, agents, queues and service levels. | [diagram](../../examples/domain_customer_service.d2.svg) |
| [`domain_customer_success`](../../examples/domain_customer_success.logic) | Customer success: accounts, health scores, renewals and playbooks. | [diagram](../../examples/domain_customer_success.d2.svg) |

## Food, logistics and agriculture

Supply chains from farm to table.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`domain_food_service`](../../examples/domain_food_service.logic) | Food service: kitchens, menus, orders, allergens and safety temperatures. | [diagram](../../examples/domain_food_service.d2.svg) |
| [`domain_logistics`](../../examples/domain_logistics.logic) | Logistics: shipments, carriers, warehouses and routes. | [diagram](../../examples/domain_logistics.d2.svg) |
| [`domain_agriculture`](../../examples/domain_agriculture.logic) | Agriculture: fields, crops, equipment and seasonal operations. | [diagram](../../examples/domain_agriculture.d2.svg) |

## Foundations

Upper-ontology examples that other models build on.

| Example | What it models | Diagram |
| :--- | :--- | :--- |
| [`bfo_energy`](../../examples/bfo_energy.logic) | BFO applied to energy generation and distribution. | [diagram](../../examples/bfo_energy.d2.svg) |
| [`bfo_manufacturing`](../../examples/bfo_manufacturing.logic) | BFO applied to manufacturing. | [diagram](../../examples/bfo_manufacturing.d2.svg) |
| [`bfo_morphisms_plant`](../../examples/bfo_morphisms_plant.logic) | BFO with specifically dependent continuants in a plant setting. | [diagram](../../examples/bfo_morphisms_plant.d2.svg) |
| [`bfo_unified`](../../examples/bfo_unified.logic) | Unified BFO model combining the above. | [diagram](../../examples/bfo_unified.d2.svg) |

## Run an example

From the repository root (replace `ontologic` with `stack exec ontologic-exe --`
if you have not installed the binary):

```bash
# Validate
ontologic -i examples/domain_ics.logic -t lint

# Prove consistency and coherence
ontologic -i examples/domain_ics.logic --solve

# Generate code or schemas
ontologic -i examples/domain_ics.logic -t python -o out/ics
ontologic -i examples/domain_ics.logic -t sql    -o out/ics

# Re-render the diagram
ontologic -i examples/domain_ics.logic -t d2 -o out/ics --render
```

To regenerate all example diagrams and Cypher files, use
[`examples/generate_visuals.sh`](../../examples/generate_visuals.sh) (needs `d2`
and `mmdc` on your `PATH`).

## How the domain_* examples are verified

Every `domain_*` example has two companions under
[`test/fixtures/domains/`](../../test/fixtures/domains/):

- `<name>.expect`: the concept, relation and property names that must exist in
  the parsed registry.
- `<name>_conflict.logic`: a deliberately contradictory variant of the model, which the
  solver must report as unsatisfiable.

[`test/DomainExamplesSpec.hs`](../../test/DomainExamplesSpec.hs) checks each
example against its `.expect` file and each `_conflict.logic` with Z3 or CVC5
(the conflict checks need integer-bound reasoning the native prover lacks). A domain example cannot silently break without that spec
failing. The older BFO, factory and MQTT examples are exercised by
[`test/ExamplesSpec.hs`](../../test/ExamplesSpec.hs).
