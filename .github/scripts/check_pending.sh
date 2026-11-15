#!/usr/bin/env bash
# Fail when the Hspec log reports pending examples other than the optional mermaid (mmdc) and docker-based neo4j ones.
# Usage: check_pending.sh <hspec-log>
set -euo pipefail
log="${1:?usage: check_pending.sh <hspec-log>}"

summary="$(grep -E '[0-9]+ examples?, [0-9]+ failures?' "$log" | tail -n 1 || true)"
if [ -z "$summary" ]; then
  echo "ERROR: no Hspec summary line found in $log" >&2
  exit 1
fi
echo "Hspec summary: $summary"

total="$(echo "$summary" | grep -oE '[0-9]+ pending' | grep -oE '[0-9]+' || echo 0)"
if [ "$total" -eq 0 ]; then
  echo "No pending examples."
  exit 0
fi

# Pending items are listed as "  N) description" under a "Pending:" heading, followed by
# a "# PENDING: reason" line. Keep the numbered description lines of that section.
pending="$(awk '/^Pending:/{p=1;next} /^(Failures:|Finished in)/{p=0} p && /^ +[0-9]+\) /{print}' "$log")"
unexpected="$(echo "$pending" | grep -v 'mermaid' | grep -v 'real neo4j' | grep -v '^$' || true)"
if [ -n "$unexpected" ] || [ -z "$pending" ]; then
  echo "ERROR: $total pending example(s); only the optional mermaid (mmdc) and docker-based neo4j examples may be pending:" >&2
  echo "${unexpected:-$pending (could not list them; see the log)}" >&2
  exit 1
fi
echo "Only the optional mermaid and neo4j examples are pending."
