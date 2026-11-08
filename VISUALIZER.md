# Logic Visualizer & Architecture Diagramming

OntoLogic includes built-in visualizers that transpile your `.logic` First-Order Logic specifications into standard diagram formats (Mermaid and D2 Lang) and can automatically render them to SVG/PNG images.

---

## 🛠️ Prerequisites

To render images directly from the CLI, install the rendering toolchains:

### 1. Mermaid CLI (`mmdc`)
```bash
npm install -g @mermaid-js/mermaid-cli
```

### 2. D2 CLI
```bash
curl -fsSL https://d2lang.com/install.sh | sh -s --
```

*Note: If these tools are not installed, OntoLogic will still generate the `.mmd` and `.d2` source files for online visualizer editing.*

---

## 💻 CLI Usage

### Generate Mermaid Class Diagram
```bash
# Generate .mmd text file
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t mermaid -o ./diagrams

# Generate .mmd and render to SVG
stack exec ontologic-exe -- -i ontologic-lib/ocsf_schema.logic -t mermaid -o ./diagrams --render
```

### Generate D2 Declarative Diagram
```bash
# Generate .d2 text file
stack exec ontologic-exe -- -i ontologic-lib/mitre_attack.logic -t d2 -o ./diagrams

# Generate .d2 and render to SVG
stack exec ontologic-exe -- -i ontologic-lib/mitre_attack.logic -t d2 -o ./diagrams --render
```

---

## 📊 Supported Diagram Output Formats

| Format | File Extension | Features |
| :--- | :--- | :--- |
| **Mermaid** | `.mmd` / `.svg` | Standard UML Class Diagrams showing inheritance (`<|--`), typed fields, and association arrows (`-->`). |
| **D2** | `.d2` / `.svg` | Modern declarative structural diagrams with container nesting, typed properties, and directed relationship links. |
| **Neo4j** | `.cypher` | Graph database schema and relationship graph queries. |
