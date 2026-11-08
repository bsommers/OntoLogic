# Targets and emitters

Each `-t <target>` compiles the checked ontology into one or more files in the `-o` directory. All emitters read the same intermediate model, so the same concept becomes a Java class, a Pydantic model, a SQL table, an OWL class, and so on. This page says what each target writes, how it maps concepts, properties, relations, and bounds, and shows a real snippet. All snippets come from `fleet.logic` in the [Quickstart](quickstart.md).

## How the model maps

| Ontology element | Typical output |
|------------------|----------------|
| `def-concept C [P]` | a class, message, table, shape, or node type; `P` becomes inheritance, `allOf`, `extends`, an FK, or a subclass edge |
| `def-property p C T` | a typed field; `:cardinality 0..1` or `:optional True` makes it optional; `0..*` or `1..*` makes it a list |
| `def-relation r A B` | a list-valued field, a junction table, a graph edge, or an object property, depending on the target |
| Axiom `forall x. C(x) implies (gte p 0 ...)` | a field constraint (`>=`, `>`, `<=`, `<`, and for some targets equality) on `p` for `C` and its subclasses |
| Any other axiom | unmapped: reported as a warning, and written as a comment in the output where the format has comments |

Type mapping: `Integer` becomes the target's 64-bit integer (`int`, `i64`, `int64_t`, `Int` or `integer`); `Float`/`Double` become floating point; `Boolean`, `String` map to the native types; a custom type is a reference to a concept.

Constraints are only *enforced* by targets that have a validation notion (Java Jakarta Validation, Pydantic, Zod, Rust/Go/C++ `validate()`, SQL `CHECK`, JSON Schema, OpenAPI, SHACL). The `smt`, `tptp`, `owl`, and diagram targets describe the model rather than enforce it. Background: [../dev/design/constraints_and_patterned.md](../dev/design/constraints_and_patterned.md).

## Application code

### `java`

One `<Class>.java` per concept, in the package given by `--java-package` (default `ontologic.generated`). Fields are private with getters and setters; bounds become Jakarta Validation annotations (`@NotNull`, `@Min`, `@Max`); subclasses use `extends`. If any axiom is unmapped, a `package-info.java` carries the warning (so it is not repeated in each class).

```java
public class Vehicle {
    private Integer speed;

    @NotNull
    @Min(0)
    @Max(130)
    public Integer getSpeed() { return this.speed; }
```

Files: `Vehicle.java`, `Truck.java`, `Car.java`, `Driver.java`, `package-info.java`.

### `python`

`models.py`: Pydantic v2 `BaseModel` classes with `Field(ge=..., le=...)`, `Optional[...]`, `List[...]`, and `model_rebuild()` calls at the end.

```python
class Vehicle(BaseModel):
    vin: str
    speed: int = Field(ge=0, le=130)

class Truck(Vehicle):
    max_load: Optional[int] = Field(default=None, ge=0)
```

### `ts` (aliases `typescript`, `zod`)

`models.ts`: Zod schemas plus inferred types; subclasses use `.extend(...)`.

```ts
export const VehicleSchema = z.object({
  vin: z.string(),
  speed: z.number().int().gte(0).lte(130),
});
export type Vehicle = z.infer<typeof VehicleSchema>;
```

### `rust`

`models.rs`: structs with `Option<T>` / `Vec<T>` fields and an `impl` with `validate() -> Result<(), Vec<String>>`. Subclasses embed the parent as `base` and call its `validate`.

### `go` (alias `golang`)

`models.go`: structs with `json` tags (optional fields are pointers), the parent embedded for inheritance, and `Validate() []string` methods.

### `cpp` (alias `c++`)

`models.hpp`: a header-only C++20 file in `namespace ontologic` with `std::optional`, `std::vector`, `std::shared_ptr`, and virtual `validate()` methods that return error strings.

## API and data contracts

### `openapi`

`openapi.yaml`: OpenAPI 3.1 `components/schemas`, one schema per concept (`required`, `minimum`, `maximum`, `allOf` with a `$ref` for subclasses).

```yaml
    Vehicle:
      type: object
      required:
      - vin
      - speed
      properties:
        vin:
          type: string
        speed:
          type: integer
          minimum: 0
          maximum: 130
```

### `graphql` (alias `gql`)

`schema.graphql`: object types (subclass types repeat the inherited fields), non-null `!` for required fields, and a `Query` type with one list field per concept.

### `jsonschema` (alias `json`)

`schema.json`: JSON Schema draft 2020-12 with one entry per concept in `$defs`, `allOf` + `$ref` for subclasses, `minimum`/`maximum`, and `required`. JSON has no comments, so unmapped axioms are reported on the console only.

### `protobuf` (aliases `proto`, `proto3`)

`schema.proto`: `proto3` messages in a package named after the first namespace prefix, lower-cased (`package fleet;`; `ontologic` if none is declared), with `optional` and `repeated` fields and native scalar types. Inheritance is shown as a comment, and bounds are not expressed.

```proto
message Driver {
    optional string nickname = 1;
    repeated Vehicle drives = 2;
}
```

### `sql` (aliases `postgres`, `postgresql`, `ddl`)

`schema.sql`: PostgreSQL DDL. One table per concept with a `TEXT` primary key `id`; subclass tables reference the parent with `ON DELETE CASCADE`; bounds become named `CHECK` constraints; relations become junction tables `rel_<name>`.

```sql
CREATE TABLE IF NOT EXISTS "Truck" (
    "id" TEXT PRIMARY KEY REFERENCES "Vehicle"("id") ON DELETE CASCADE,
    "max_load" INTEGER,
    CONSTRAINT "chk_Truck_max_load" CHECK ("max_load" >= 0)
);
```

## Knowledge graphs

### `owl`

`ontology.owl`: RDF/XML with `owl:Class`, `rdfs:subClassOf`, `owl:DatatypeProperty` (with domain and XSD range), and `owl:ObjectProperty`. The base IRI is the first namespace's IRI, or `--base-iri`.

```xml
<owl:Class rdf:about="http://example.org/fleet#Truck"><rdfs:subClassOf rdf:resource="http://example.org/fleet#Vehicle"/></owl:Class>
```

### `shacl`

`shapes.ttl`: Turtle with a `sh:NodeShape` per concept (`sh:targetClass`), `sh:datatype`, `sh:minCount`/`sh:maxCount` from cardinality, and `sh:minInclusive`/`sh:maxInclusive` from bounds. Same `--base-iri` rules as OWL.

```turtle
ont:VehicleShape
    a sh:NodeShape ;
    sh:targetClass ont:Vehicle ;
    sh:property [ sh:path ont:speed ; sh:datatype xsd:integer ;
                  sh:minInclusive 0 ; sh:maxInclusive 130 ] .
```

### `neo4j`

Two files. `graph.cypher` creates `OntologyClass` nodes, `SUBCLASS_OF` and `RELATION` edges, and one audit query per bound that returns the ids of violating nodes. `constraints.cypher` holds property-existence constraints, which need Neo4j Enterprise; `--neo4j-edition community` writes them commented out.

```cypher
// Axiom validation: Vehicle speed gte 0
MATCH (n:`Vehicle`) WHERE NOT (n.`speed` >= 0) RETURN elementId(n) AS invalid_node_id;
```

## Prover input

### `smt`

`spec.smt2`: SMT-LIB2 with an `Entity` sort, one constant per concept, `subClassOf` facts, per-property functions with bound assertions, and a trailing `(check-sat)` and `(get-model)`. Feed it to any SMT solver (`z3 spec.smt2`). This is a declarative export; the in-process `--solve` uses a richer first-order encoding (see [Axioms and reasoning](axioms-and-reasoning.md)), so verdicts can differ.

### `tptp`

`theory.p`: TPTP first-order form (`fof(...)` axioms with `is_<Concept>`, `rel_<name>`, `prop_<name>`, and `cmp_<op>` symbols) for Vampire, E, and other ATPs.

```text
fof(subclass_Truck_Vehicle, axiom, (! [X] : (is_Truck(X) => is_Vehicle(X)))).
```

## Diagrams

`mermaid` writes `class_diagram.mmd`; `d2` writes `diagram.d2`. Both accept `--render`. See [Visualization](visualization.md).

## Unmapped axioms

An axiom that is not of the "concept implies property comparisons" shape (disjointness, existentials, relational rules) cannot become a field constraint. Targets with `Unmapped by default = yes` in the [CLI reference](cli-reference.md#targets) print

```text
⚠️  Warning: 1 complex / conditional axiom(s) could not be mapped to Python field constraints:
fleet.logic:17:2: warning: [WUnmappedAxiom] forall v (Truck(v) implies not Car(v))
```

and append the same list as a comment to the first (or, for Java, a `package-info.java`) output file. Use `--warn-unmapped` to get the warning for the remaining targets. Such axioms are still verified by `--solve`; they are just not enforced by the generated artifact, so enforce them in application code or with SHACL/OWL tooling.

Next: [Visualization](visualization.md)
