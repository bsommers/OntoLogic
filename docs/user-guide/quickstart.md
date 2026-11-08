# Quickstart

In about ten minutes you will write a small fleet ontology, lint it, ask a solver whether it is consistent, break it on purpose to see a contradiction reported, emit TypeScript, SQL, and OpenAPI from it, and draw a diagram. You need a built `ontologic-exe` (see [Installation](installation.md)); Z3 or CVC5 is recommended but not required.

## 1. Write the ontology

Create `fleet.logic`. Comments start with `;` (or `//`).

```lisp
;; fleet.logic - a small vehicle-fleet ontology
(namespace fleet "http://example.org/fleet#")

(def-concept Vehicle)
(def-concept Truck Vehicle)
(def-concept Car Vehicle)
(def-concept Driver)

(def-property vin Vehicle String :cardinality 1..1)
(def-property speed Vehicle Integer)
(def-property max_load Truck Integer :optional True)
(def-property nickname Driver String :optional True)

(def-relation drives Driver Vehicle :cardinality 0..*)

;; Trucks and cars are disjoint
(forall (v) (implies (Truck v) (not (Car v))))

;; Speed is bounded for every vehicle
(forall (v) (implies (Vehicle v) (and (gte speed 0) (lte speed 130))))

;; Trucks have a non-negative load limit
(forall (t) (implies (Truck t) (gte max_load 0)))
```

`(def-concept Truck Vehicle)` makes Truck a subclass of Vehicle. Properties are typed attributes of one concept; relations link two concepts. The `forall` forms are axioms. Full syntax: [Language reference](language-reference.md).

## 2. Lint

```bash
stack exec ontologic-exe -- -i fleet.logic -t lint
```

```text
✅ Logic Validated successfully.
```

The linter checks symbols, duplicates, inheritance cycles, and obvious contradictions. Try breaking it: make `Hybrid` a subclass of `Truck` that is also a `Car`.

```lisp
(def-concept Hybrid Truck)
(forall (h) (implies (Hybrid h) (Car h)))
```

```text
bad.logic:4:14: error: Semantic contradiction: Concept Hybrid implies both Truck and Car, but Truck is disjoint with Car.
```

The message has `file:line:col: error:` format, the exit code is 1, and (because the linter runs first) nothing else is attempted. In the real output the file path is printed in full.

## 3. Solve

```bash
stack exec ontologic-exe -- -i fleet.logic -t solve
```

```text
✅ SMT Satisfiable (SAT) — Ontology is logically consistent.
✅ All concepts are satisfiable (0 empty concepts).
```

Two checks ran: the axioms can be satisfied together (consistency), and every concept can have an instance (coherence). Exit code 0 means both passed. To see a failure, state a contradiction the linter cannot spot syntactically:

```lisp
(def-concept Account)
(def-concept Frozen Account)
(def-property balance Account Integer)
(def-axiom "min-balance" (forall (a) (implies (Account a) (gte balance 100))))
(def-axiom "some-low"    (exists (a) (and (Account a) (lt balance 50))))
```

```bash
stack exec ontologic-exe -- -i unsat.logic -t solve --explain-unsat
```

```text
❌ SMT Unsatisfiable (UNSAT) — Logical contradiction detected!
🔍 Unsatisfiable Core Conflicting Axioms:
   • Axiom #1: forall a (Account(a) implies gte(balance, 100))
   • Axiom #2: exists a (Account(a) and lt(balance, 50))
❌ Unsatisfiable / empty concept(s): Account Frozen
```

The exit code is 1. More in [Axioms and reasoning](axioms-and-reasoning.md).

## 4. Emit code and schemas

Every target except `lint`/`solve`/`repl`/`lsp` needs `-o` (an output directory, created if missing).

```bash
stack exec ontologic-exe -- -i fleet.logic -t ts  -o out/ts
stack exec ontologic-exe -- -i fleet.logic -t sql -o out/sql
stack exec ontologic-exe -- -i fleet.logic -t openapi -o out/openapi
```

```text
⚠️  Warning: 1 complex / conditional axiom(s) could not be mapped to TypeScript field constraints:
fleet.logic:17:2: warning: [WUnmappedAxiom] forall v (Truck(v) implies not Car(v))
Generated TypeScript/Zod models in out/ts
```

The warning is expected: the disjointness axiom is logic, not a field bound, so no field constraint can express it. It is recorded as a comment at the end of the generated file. Field bounds were mapped:

```ts
// out/ts/models.ts
export const VehicleSchema = z.object({
  vin: z.string(),
  speed: z.number().int().gte(0).lte(130),
});
export const TruckSchema = VehicleSchema.extend({
  max_load: z.number().int().optional(),
});
```

```sql
-- out/sql/schema.sql
CREATE TABLE IF NOT EXISTS "Vehicle" (
    "id" TEXT PRIMARY KEY,
    "vin" TEXT NOT NULL,
    "speed" INTEGER NOT NULL,
    CONSTRAINT "chk_Vehicle_speed" CHECK ("speed" >= 0 AND "speed" <= 130)
);
```

All targets are listed in [Targets and emitters](targets-and-emitters.md).

## 5. Visualize

```bash
stack exec ontologic-exe -- -i fleet.logic -t mermaid -o out/diagrams
stack exec ontologic-exe -- -i fleet.logic -t d2 -o out/diagrams --render
```

```text
Generated D2 diagram in out/diagrams
Rendering to out/diagrams/diagram.d2.svg using d2...
✅ Rendered SVG successfully.
```

`class_diagram.mmd` holds a Mermaid class diagram (paste it into any Mermaid viewer); `diagram.d2` and `diagram.d2.svg` are the D2 version. See [Visualization](visualization.md).

## 6. Explore interactively

```bash
stack exec ontologic-exe -- --repl
```

```text
ontologic> :load fleet.logic
✅ Loaded fleet.logic (4 concepts, 0 lint errors).
ontologic> :prove Truck Vehicle
✅ Theorem Proved via Z3: 'Truck' ⊑ 'Vehicle' (Every instance of Truck is necessarily a Vehicle).
```

See [REPL](repl.md).

Next: [Language reference](language-reference.md) | [CLI reference](cli-reference.md)
