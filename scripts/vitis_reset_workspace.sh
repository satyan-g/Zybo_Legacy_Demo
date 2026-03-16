#!/bin/bash
# vitis_reset_workspace.sh — Clean Vitis workspace and rebuild
# Usage: ./scripts/vitis_reset_workspace.sh <project>
# Example: ./scripts/vitis_reset_workspace.sh 02_hello

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT="${1:?Usage: $0 <project> (e.g. 02_hello)}"
WS_DIR="$PROJ_ROOT/output/$PROJECT/vitis_workspace"
BUILD_SCRIPT="$PROJ_ROOT/scripts/$PROJECT/build_sw.py"

if [ ! -f "$BUILD_SCRIPT" ]; then
    echo "ERROR: Build script not found: $BUILD_SCRIPT"
    exit 1
fi

echo ">>> Cleaning workspace: $WS_DIR"
rm -rf "$WS_DIR"

echo ">>> Running Vitis build: $BUILD_SCRIPT"
source "$SCRIPT_DIR/env.sh"
vitis -s "$BUILD_SCRIPT"
