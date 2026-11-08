#!/usr/bin/env bash
set -euo pipefail

# OntoLogic Standalone Release Packaging Script
VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null | tr -d 'v' || echo "1.3.0")}"
DIST_DIR="dist"
ARCH="$(uname -m)"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
PACKAGE_NAME="ontologic-v${VERSION}-${OS}-${ARCH}"
TARGET_DIR="${DIST_DIR}/${PACKAGE_NAME}"

echo "🔨 Building OntoLogic binary via Stack..."
stack build --ghc-options="-Wall -Werror -O2"

BIN_PATH="$(stack path --local-install-root)/bin/ontologic-exe"
LSP_BIN_PATH="$(stack path --local-install-root)/bin/ontologic-lsp"
if [ ! -f "$BIN_PATH" ]; then
  echo "❌ Error: Binary not found at $BIN_PATH" >&2
  exit 1
fi

echo "📦 Preparing release bundle in ${TARGET_DIR}..."
rm -rf "${TARGET_DIR}" "${TARGET_DIR}.tar.gz"
mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/ontologic-lib" "${TARGET_DIR}/examples"

cp "$BIN_PATH" "${TARGET_DIR}/bin/ontologic"
chmod +x "${TARGET_DIR}/bin/ontologic"

if [ -f "$LSP_BIN_PATH" ]; then
  cp "$LSP_BIN_PATH" "${TARGET_DIR}/bin/ontologic-lsp"
  chmod +x "${TARGET_DIR}/bin/ontologic-lsp"
fi

if [ -d "editors/vscode" ]; then
  echo "🧩 Packaging VS Code Extension (.vsix)..."
  (cd editors/vscode && npm run compile && npx @vscode/vsce package --no-git-tag-version)
  mkdir -p "${TARGET_DIR}/editors/vscode"
  cp editors/vscode/ontologic-${VERSION}.vsix "${TARGET_DIR}/editors/vscode/"
  cp editors/vscode/ontologic-${VERSION}.vsix "${DIST_DIR}/"
fi

cp ontologic-lib/*.logic "${TARGET_DIR}/ontologic-lib/"
cp examples/*.logic "${TARGET_DIR}/examples/"
cp README.md LICENSE "${TARGET_DIR}/"

echo "🗜️  Archiving release tarball..."
tar -czf "${DIST_DIR}/${PACKAGE_NAME}.tar.gz" -C "${DIST_DIR}" "${PACKAGE_NAME}"

echo "🔑 Generating SHA256 checksum..."
(cd "${DIST_DIR}" && sha256sum "${PACKAGE_NAME}.tar.gz" > "${PACKAGE_NAME}.tar.gz.sha256")

echo "✅ Release package successfully created: ${DIST_DIR}/${PACKAGE_NAME}.tar.gz"

