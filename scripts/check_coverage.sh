#!/usr/bin/env bash
# scripts/check_coverage.sh
# Runs the Haskell test suite with HPC coverage enabled and enforces
# that expression coverage does not drop below the baseline threshold.
set -euo pipefail
cd "$(dirname "$0")/.."

THRESHOLD="${COVERAGE_THRESHOLD:-74}"

echo "==> Running test suite with HPC coverage enabled..."
stack test --coverage "$@"

echo "==> Locating HPC artifacts..."
tix="$(find .stack-work/install -name "all.tix" 2>/dev/null | head -n 1 || true)"
if [ -z "$tix" ]; then
  tix="$(find .stack-work/install -name "ontologic-test.tix" 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$tix" ] || [ ! -f "$tix" ]; then
  echo "ERROR: Could not locate .tix file under .stack-work/install" >&2
  exit 1
fi

hpcdir="$(find .stack-work/dist -type d -name "hpc" 2>/dev/null | head -n 1 || true)"
if [ -z "$hpcdir" ] || [ ! -d "$hpcdir" ]; then
  echo "ERROR: Could not locate hpc directory under .stack-work/dist" >&2
  exit 1
fi

echo "==> Generating HPC summary report..."
report="$(stack exec -- hpc report --hpcdir="$hpcdir" "$tix")"
echo "------------------------------------------------------------"
echo "$report"
echo "------------------------------------------------------------"

expr_cov="$(echo "$report" | grep -oE '[0-9]+% expressions used' | grep -oE '[0-9]+' | head -n 1)"
if [ -z "$expr_cov" ]; then
  echo "ERROR: Failed to parse expressions used percentage from hpc report." >&2
  exit 1
fi

if [ "$expr_cov" -lt "$THRESHOLD" ]; then
  echo "FAILURE: Expression coverage ${expr_cov}% is below required threshold ${THRESHOLD}%!" >&2
  exit 1
fi

echo "SUCCESS: Expression coverage ${expr_cov}% meets threshold ${THRESHOLD}%."
