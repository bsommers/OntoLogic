# OntoLogic: Purpose & Motivation

OntoLogic was created to address a critical challenge in modern Internet of Things (IoT) and Industrial IoT (IIOT) environments: **enforcing consistent business and safety rules across heterogeneous platforms at scale.**

---

## 🛑 The Problem: Distributed Logic Drift

In large-scale IoT fleets (such as smart factories, pipelines, or container terminal operations), multiple platforms execute different parts of the same operational process:
1. **Edge Gateways**: Run Java/JVM environments (e.g., Acme broker plugins) to parse and route high-throughput telemetry packets.
2. **Edge Devices**: Run Python scripts on single-board computers (e.g., Raspberry Pi, BeagleBone) to read sensor data and perform local logic checks.
3. **Cloud Analytics / Digital Twins**: Run graph databases like Neo4j to build semantic models of the system and audit historical states.

If a safety rule changes (for example, the maximum threshold for a temperature sensor is reduced from `100°C` to `90°C`), developers must manually update:
*   Java POJO validation rules on the Gateway.
*   Python Pydantic parsing models on the Devices.
*   Cypher queries auditing database records in the Cloud.

This manual process is highly error-prone, leading to **logic drift** where different tiers of the application enforce inconsistent rules, potentially causing silent data corruption, validation bypasses, or safety hazards.

---

## ⚡ The Solution: Logic-as-Code

OntoLogic introduces a **Logic-as-Code** pipeline for IoT architectures. Instead of defining taxonomies and safety rules in multiple codebases, developers define them once in a declarative S-expression syntax.

```
                  ┌──────────────────────────────┐
                  │   Unified .logic Rule File   │
                  │   (Single Source of Truth)   │
                  └──────────────────────────────┘
                                  │
                                  ▼
                        ┌──────────────────┐
                        │  Haskell Linter  │ ──> (Static Cycle/Contradiction Check)
                        └──────────────────┘
                                  │
                                  ▼
                        ┌──────────────────┐
                        │ Compiler Emitters│
                        └──────────────────┘
            ┌─────────────────────┼─────────────────────┐
            ▼                     ▼                     ▼
     ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
     │ Java POJOs  │       │   Python    │       │ Neo4j Graph │
     │  (Gateway)  │       │ (Edge/Apps) │       │   (Cloud)   │
     └─────────────┘       └─────────────┘       └─────────────┘
```

By compiling the logical model from a single source of truth, OntoLogic ensures:
*   **Mathematical Consistency**: All rules are statically checked for cycles and contradictions before compilation.
*   **Zero Drift**: Any change in a rule propagates instantly to Java validation classes, Pydantic models, and Cypher database schema constraints.
*   **Optimized Performance**: Generated artifacts are lightweight, platform-native classes or queries with zero heavy compiler runtime overhead.
