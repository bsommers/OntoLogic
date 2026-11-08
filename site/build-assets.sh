#!/usr/bin/env bash
# Copy example D2 diagrams into the site: examples/<name>.d2.svg -> site/assets/diagrams/<name>.svg
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/../examples"
dst="$here/assets/diagrams"
mkdir -p "$dst"
n=0
for f in "$src"/*.d2.svg; do
  [ -e "$f" ] || continue
  base="$(basename "$f" .d2.svg)"
  cp "$f" "$dst/$base.svg"
  n=$((n+1))
done
echo "copied $n diagram(s) to site/assets/diagrams"
