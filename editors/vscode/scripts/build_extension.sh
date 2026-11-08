#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$EXT_DIR"

echo "==> Installing VS Code extension dependencies..."
npm install

echo "==> Compiling TypeScript..."
npm run compile

echo "==> Packaging VSIX extension..."
npx @vscode/vsce package --no-git-tag-version

echo "==> VSIX Package created at $EXT_DIR/ontologic-1.0.0.vsix"
