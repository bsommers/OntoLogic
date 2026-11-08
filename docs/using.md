# OntoLogic: User Guide

This guide describes how to write `.logic` syntax, compile logic files, build target libraries, and render visual diagrams.

---

## ✍️ Writing `.logic` Files

A `.logic` file defines the taxonomy classes, properties, and constraints.

### 1. Concepts (Taxonomy)
Concepts define classes of objects in your environment. You can specify a parent class to represent inheritance.
```lisp
(def-concept Asset)
(def-concept Device Asset)
(def-concept Sensor Device)
```

### 2. Properties
Properties map concepts to value types (Integer, Boolean, String).
```lisp
(def-property serial_number Asset String)
(def-property temperature Sensor Integer)
(def-property is_active Sensor Boolean)
```

### 3. Axioms (Constraints)
Axioms enforce logical assertions and ranges on concepts:
```lisp
; Active sensors must have a temperature greater than 0
(forall (s)
    (implies (and (Sensor s) (is_active)) (gt temperature 0)))
```

---

## 💻 CLI Compiler Usage

Build the compiler first:
```bash
stack build
```

Run the compiler executable using:
```bash
stack exec ontologic-exe -- -i <input_file> -t <target> -o <output_path>
```

### CLI Options
- `-i, --input PATH`: Path to the input `.logic` file.
- `-t, --target TARGET`: Target output format. Supported targets:
  - `java`: Generates separate Java class files with Jakarta validations.
  - `python`: Generates a `models.py` Pydantic schema file.
  - `neo4j`: Generates a Cypher script to build node hierarchies and audit queries.
  - `owl`: Generates a Web Ontology Language (OWL) XML schema.
  - `mermaid`: Generates a Mermaid class diagram markup file (`.mmd`).
  - `d2`: Generates a D2 diagram markup file (`.d2`).
  - `lint`: Runs linter validation checks only.
- `-o, --output PATH`: Target directory or file path for the output.
- `--render`: Converts Mermaid or D2 diagram files to SVG images (requires CLI tools installed).

---

## 🎨 Visualizing Diagrams

To render SVG/PNG diagrams automatically from the compiler, install the following CLI tools:

### Mermaid CLI (`mmdc`)
```bash
npm install -g @mermaid-js/mermaid-cli
```
Generate and render class diagram:
```bash
stack exec ontologic-exe -- -i examples/smart_factory.logic -t mermaid -o . --render
# Generates class_diagram.mmd and class_diagram.mmd.svg
```

### D2 Lang CLI (`d2`)
```bash
curl -fsSL https://d2lang.com/install.sh | sh -s --
```
Generate and render structural nesting diagram:
```bash
stack exec ontologic-exe -- -i examples/smart_factory.logic -t d2 -o . --render
# Generates diagram.d2 and diagram.d2.svg
```

---

## 📦 Integrating with Gradle & Docker

### Gradle Integration
The root project has Gradle tasks configured to run compile-time checks:
- **`./gradlew lintOntology`**: Runs the static cycle linter on your logic file.
- **`./gradlew generateJavaModels`**: Generates Java class structures directly into the `models-java` codebase.

### Docker Setup
To start the Neo4j database and Python verification server:
```bash
docker-compose up
```
This runs Neo4j on ports `7474` (web UI) and `7687` (bolt connection) and mounts Python Pydantic models for edge service validation.
