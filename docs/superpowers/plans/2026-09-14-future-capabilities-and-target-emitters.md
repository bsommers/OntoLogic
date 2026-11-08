# Future Capabilities & Target Emitters Master Plan

**Document:** `docs/superpowers/plans/2026-09-14-future-capabilities-and-target-emitters.md`  
**Date:** 2026-09-14  
**Status:** Queued / Future Roadmap  
**Scope:** Design and implementation specifications for SPARQL 1.1, Protobuf v3 / gRPC, SQL DDL relational schema generation, and WebAssembly (WASM) browser interactive studio.

---

## I. Feature 1: W3C SPARQL 1.1 Query & Graph Protocol Emitter (`-t sparql`)

### 1.1 Motivation & Purpose
While OntoLogic generates W3C OWL XML (`-t owl`) and SHACL Shapes (`-t shacl`), enterprise graph databases (Apache Jena, GraphDB, Blazegraph, Amazon Neptune) execute SPARQL 1.1 for taxonomy traversal, property verification, and constraint compliance auditing.

### 1.2 Design Specification
- **Module:** `src/Emitters/Sparql.hs`
- **CLI Target:** `-t sparql`
- **Output:** `queries.rq` (or partitioned `.rq` files)
- **REPL Command:** `:emit sparql`
- **Query Types Emitted:**
  1. **Taxonomy Verification (`ASK` Queries):**
     ```sparql
     PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
     PREFIX bfo: <http://purl.obolibrary.org/obo/bfo.owl#>
     
     # Check if SubClass is transitively a subclass of ParentClass
     ASK {
       ?sub rdfs:subClassOf* bfo:MaterialEntity .
     }
     ```
  2. **Instance & Property Bound Auditing (`SELECT` Queries):**
     ```sparql
     PREFIX ont: <http://example.com/ontology#>
     
     # Find all RoboticArm instances violating payload bounds [1, 500]
     SELECT ?arm ?payload WHERE {
       ?arm a ont:RoboticArm ;
            ont:maxPayload ?payload .
       FILTER (?payload < 1 || ?payload > 500)
     }
     ```
  3. **Relational Association Mapping (`CONSTRUCT` Queries):**
     ```sparql
     PREFIX ont: <http://example.com/ontology#>
     
     CONSTRUCT {
       ?sensor ont:monitors ?device .
     } WHERE {
       ?sensor a ont:Sensor ;
               ont:targetDevice ?device .
     }
     ```

### 1.3 Testing & Verification
- `test/SparqlSpec.hs`: Verify correct SPARQL prefix declarations, `ASK`/`SELECT` query generation, filter clause bounds, and integration across all 12 example models.

---

## II. Feature 2: Protocol Buffers (Protobuf v3) & gRPC Service Emitter (`-t proto`)

### 2.1 Motivation & Purpose
To enable zero-overhead microservice serialization and cross-language contract enforcement, OntoLogic should emit clean Protocol Buffers v3 `.proto` definitions complete with validation annotations.

### 2.2 Design Specification
- **Module:** `src/Emitters/Protobuf.hs`
- **CLI Target:** `-t proto` / `-t protobuf`
- **Output:** `models.proto`
- **REPL Command:** `:emit proto`
- **Type Mappings:**
  | OntoLogic DSL | Protobuf v3 Type |
  | :--- | :--- |
  | `Integer` | `int64` (or `int32`) |
  | `Float` | `float` |
  | `Double` | `double` |
  | `String` | `string` |
  | `Boolean` | `bool` |
  | `DateTime` | `google.protobuf.Timestamp` |
  | `URI` | `string` |
  | Concept Ref | `string` (ID) or nested message |

- **Validation Rules (`buf.validate` / `PGV`):**
  ```protobuf
  syntax = "proto3";
  package com.ontologic.generated;

  import "buf/validate/validate.proto";

  message RoboticArm {
    string id = 1;
    int32 max_payload = 2 [(buf.validate.field).int32 = {gte: 1, lte: 500}];
  }

  service RoboticArmService {
    rpc GetRoboticArm(GetRoboticArmRequest) returns (RoboticArm);
    rpc ValidateRoboticArm(RoboticArm) returns (ValidationResponse);
  }
  ```

### 2.3 Testing & Verification
- `test/ProtobufSpec.hs`: Validate syntax, field numbers assignment, inheritance field flattening, `buf.validate` range rules, and test compilation smoke test via `protoc` (if available).

---

## III. Feature 3: SQL DDL & Relational Schema Emitter (`-t sql` / `-t postgres` / `-t sqlite`)

### 3.1 Motivation & Purpose
Enable relational database schema generation and migration directly from formal ontological specifications.

### 3.2 Design Specification
- **Module:** `src/Emitters/Sql.hs`
- **CLI Target:** `-t sql` / `-t postgres` / `-t sqlite`
- **Output:** `schema.sql`
- **REPL Command:** `:emit sql`
- **Features:**
  1. **Table Definitions with Types & Primary Keys:**
     ```sql
     CREATE TABLE assets (
       id VARCHAR(255) PRIMARY KEY,
       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
     );
     ```
  2. **Table Inheritance / Foreign Key Links:**
     ```sql
     CREATE TABLE robotic_arms (
       id VARCHAR(255) PRIMARY KEY REFERENCES assets(id) ON DELETE CASCADE,
       max_payload INTEGER NOT NULL,
       CONSTRAINT chk_robotic_arms_max_payload CHECK (max_payload >= 1 AND max_payload <= 500)
     );
     ```
  3. **Relational Association Join Tables (`def-relation`):**
     ```sql
     CREATE TABLE rel_sensor_monitors_device (
       sensor_id VARCHAR(255) REFERENCES sensors(id) ON DELETE CASCADE,
       device_id VARCHAR(255) REFERENCES devices(id) ON DELETE CASCADE,
       PRIMARY KEY (sensor_id, device_id)
     );
     ```

### 3.3 Testing & Verification
- `test/SqlSpec.hs`: Validate ANSI/PostgreSQL DDL syntax, primary/foreign key definitions, `CHECK` constraints matching axiom intervals, and execute in-memory SQLite schema verification.

---

## IV. Feature 4: WebAssembly (WASM) Playground & Interactive Studio

### 4.1 Motivation & Purpose
Provide a zero-install, web-based playground for creating, editing, linting, theorem proving, and transpiling OntoLogic models directly in the browser.

### 4.2 Architecture Specification
- **Frontend Stack:** React + Monaco Editor + TailwindCSS.
- **Compilation Options:**
  1. **Option A (WASM / Asterius / GHC-WASM):** Compile the Haskell core engine (`OntoLogic`, `Parser`, `Linter`, `IR`, `Emitters`) to WebAssembly.
  2. **Option B (Lightweight Microservice Backend):** Stdio JSON-RPC proxy running `ontologic-lsp` and `ontologic --solve` over WebSockets / HTTP for full Z3/CVC5 solver access.
- **Playground Features:**
  - Split-pane editor: DSL on the left, multi-target output on the right (tabs for TypeScript, Python, Java, Rust, Go, SMT, SPARQL, SQL, Diagrams).
  - Live Mermaid / D2 SVG diagram rendering in real time.
  - Interactive SMT Satisfiability & Subsumption proof runner.
  - Preloaded standard library dropdown (`BFO 2020`, `MITRE ATT&CK`, `OCSF`, `NIST CSF 2.0`).

---

## V. Execution Phasing

| Phase | Feature | Target Deliverable |
| :--- | :--- | :--- |
| **Phase 1** | SPARQL 1.1 Emitter | `src/Emitters/Sparql.hs`, `test/SparqlSpec.hs`, CLI `-t sparql` |
| **Phase 2** | Protobuf v3 & gRPC Emitter | `src/Emitters/Protobuf.hs`, `test/ProtobufSpec.hs`, CLI `-t proto` |
| **Phase 3** | SQL DDL Schema Emitter | `src/Emitters/Sql.hs`, `test/SqlSpec.hs`, CLI `-t sql` |
| **Phase 4** | Web Studio & Playground | `web/` playground application with Monaco editor and live emitter previews |
