# Visualization

OntoLogic turns an ontology into diagrams in two text formats, Mermaid and D2, and can call the matching command-line renderer to produce an SVG. The diagrams show concepts, inheritance, typed properties, and relations. The text files work without any extra software; rendering to an image needs `d2` or `mmdc`.

## Prerequisites (optional)

| Tool | Needed for | Install |
|------|-----------|---------|
| D2 CLI | `-t d2 --render` | `curl -fsSL https://d2lang.com/install.sh \| sh -s --` |
| Mermaid CLI | `-t mermaid --render` | `npm install -g @mermaid-js/mermaid-cli` |

Without them, OntoLogic still writes `class_diagram.mmd` and `diagram.d2`, which you can paste into an online Mermaid or D2 editor, or into a Markdown file (GitHub renders ```` ```mermaid ```` blocks).

## Mermaid class diagram

```bash
ontologic-exe -i fleet.logic -t mermaid -o diagrams
```

```text
Generated Mermaid diagram in diagrams
Skipping render (use --render to generate SVG).
```

`diagrams/class_diagram.mmd`:

```text
classDiagram
    class Vehicle["Vehicle"]
    class Truck["Truck"]
    class Car["Car"]
    class Driver["Driver"]
    Vehicle <|-- Truck
    Vehicle <|-- Car
    Vehicle : +String vin
    Vehicle : +Integer speed
    Truck : +Integer max_load
    Driver : +String nickname
    Driver --> Vehicle : drives
```

Inheritance is drawn `Parent <|-- Child`, properties are `+Type name` members, and a relation is an arrow labeled with the relation name. Unmapped axioms are appended as `%%` comments, which Mermaid ignores.

Add `--render` to also write `class_diagram.mmd.svg` next to the source. This calls `mmdc -i <file>.mmd -o <file>.mmd.svg`. If `mmdc` is missing or fails you get a warning and the `.mmd` file is still there:

```text
⚠️  Error: 'mmdc' (Mermaid CLI) not found or failed. Install with 'npm install -g @mermaid-js/mermaid-cli'
```

## D2 diagram

```bash
ontologic-exe -i fleet.logic -t d2 -o diagrams --render
```

```text
success: successfully compiled diagrams/diagram.d2 to diagrams/diagram.d2.svg in 45.912272ms
Generated D2 diagram in diagrams
Rendering to diagrams/diagram.d2.svg using d2...
✅ Rendered SVG successfully.
```

`diagrams/diagram.d2` uses D2's `class` shape:

```text
"Vehicle": { shape: class }
"Truck": { shape: class }
"Truck" -> "Vehicle"
"Vehicle"."speed": Integer
"Driver" -> "Vehicle": drives
```

D2 is a good choice for large ontologies because its layout engines handle nesting and dense graphs well.

## Output summary

| Target | Source file | Rendered file | Contents |
|--------|-------------|---------------|----------|
| `mermaid` | `class_diagram.mmd` | `class_diagram.mmd.svg` | UML-style class diagram: inheritance, typed fields, association arrows |
| `d2` | `diagram.d2` | `diagram.d2.svg` | Class-shaped nodes, inheritance and relation arrows, typed properties |
| `neo4j` | `graph.cypher` | n/a | Graph schema and audit queries for a graph database ([Targets](targets-and-emitters.md#neo4j)) |

The output file names are fixed, so use one `-o` directory per diagram, or move the files after generation. `examples/generate_visuals.sh` does this for every example, and the checked-in `examples/*.mmd`, `*.d2`, and `*.d2.svg` files are its output.

## Working with big ontologies

- Import a library and diagram a subset: write a small `.logic` file that imports only what you need.
- Large standard-library ontologies (for example `ontologic-lib/mitre_attack.logic`) produce very large diagrams; prefer D2 and render to SVG, or split by domain.
- The REPL can print either format without writing a file: `:emit mermaid` or `:emit d2` (see [REPL](repl.md)).

## Troubleshooting

| Symptom | Cause and fix |
|---------|---------------|
| `Skipping render (use --render to generate SVG).` | You did not pass `--render`; this is informational |
| `'mmdc' ... not found or failed` | Mermaid CLI is not installed, not on `PATH`, or cannot run (for example a sandboxed package that cannot read the output directory). Run `mmdc -i class_diagram.mmd -o out.svg` by hand to see its error |
| `'d2' CLI not found or failed` | Install D2; check `d2 --version` |
| Overwritten diagrams | Fixed file names; use separate `-o` directories |

Next: [REPL](repl.md)
