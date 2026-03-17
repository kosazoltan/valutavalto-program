#!/bin/bash
# scripts/build-electron.sh — Teljes Electron build pipeline
# Használat: bash scripts/build-electron.sh
# Windows-on: Git Bash-ben futtatandó

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/frontend-react"
ELECTRON_DIR="$REPO_ROOT/penztar-client"

echo "=== 1/4 Frontend-react build ==="
cd "$FRONTEND_DIR"
npm ci --ignore-scripts
VITE_API_URL="${VITE_API_URL:-https://valutavalto-api.onrender.com/api/v1}" npm run build
echo "✅ Frontend build kész: $FRONTEND_DIR/dist/"

echo "=== 2/4 Frontend dist másolása Electron-ba ==="
rm -rf "$ELECTRON_DIR/dist"
cp -r "$FRONTEND_DIR/dist" "$ELECTRON_DIR/dist"
echo "✅ Dist másolva: $ELECTRON_DIR/dist/"

echo "=== 3/4 Electron main+preload build ==="
cd "$ELECTRON_DIR"
npm ci --ignore-scripts
npx vite build
echo "✅ Electron build kész: $ELECTRON_DIR/dist-electron/"

echo "=== 4/4 Electron package (installer) ==="
npx electron-builder --win
echo "✅ Installer kész: $ELECTRON_DIR/release/"
