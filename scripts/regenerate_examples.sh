#!/usr/bin/env bash
# Regenerate the checked-in examples/*.cypher, *.mmd and *.d2 from examples/*.logic.
#
# Only files that are already checked in are rewritten: not every example carries all
# three outputs, and this script is for refreshing them after an emitter change, not
# for adding new artifacts. The .d2.svg files need the d2 CLI (examples/generate_visuals.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

regenerated=0
for f in examples/*.logic; do
  base="$(basename "$f" .logic)"
  for spec in "neo4j:graph.cypher:cypher" "mermaid:class_diagram.mmd:mmd" "d2:diagram.d2:d2"; do
    target="${spec%%:*}"
    rest="${spec#*:}"
    produced="${rest%%:*}"
    ext="${rest##*:}"
    dest="examples/$base.$ext"
    [ -f "$dest" ] || continue
    stack exec ontologic-exe -- -i "$f" -t "$target" -o "$tmp" >/dev/null
    cp "$tmp/$produced" "$dest"
    regenerated=$((regenerated + 1))
  done
done

echo "Regenerated $regenerated file(s) from $(ls examples/*.logic | wc -l) example(s)."
echo "Review with: git diff examples/"
