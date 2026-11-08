#!/bin/bash
set -e

# Build the project first
echo "Building OntoLogic..."
stack build

EXAMPLES_DIR="$(dirname "$0")"

echo "Generating visualizations for all examples in $EXAMPLES_DIR..."

for logic_file in "$EXAMPLES_DIR"/*.logic; do
    filename=$(basename -- "$logic_file")
    name="${filename%.*}"
    
    echo "Processing $name..."
    
    # Generate Mermaid
    stack exec ontologic-exe -- --input "$logic_file" --target mermaid --output "$EXAMPLES_DIR" --render || true
    mv "$EXAMPLES_DIR/class_diagram.mmd" "$EXAMPLES_DIR/$name.mmd"
    if [ -f "$EXAMPLES_DIR/class_diagram.mmd.svg" ]; then
        mv "$EXAMPLES_DIR/class_diagram.mmd.svg" "$EXAMPLES_DIR/$name.mmd.svg"
    fi

    # Generate D2
    stack exec ontologic-exe -- --input "$logic_file" --target d2 --output "$EXAMPLES_DIR" --render || true
    mv "$EXAMPLES_DIR/diagram.d2" "$EXAMPLES_DIR/$name.d2"
    if [ -f "$EXAMPLES_DIR/diagram.d2.svg" ]; then
        mv "$EXAMPLES_DIR/diagram.d2.svg" "$EXAMPLES_DIR/$name.d2.svg"
    fi
done

echo "Done! Check $EXAMPLES_DIR for .mmd, .d2, and .svg files."
