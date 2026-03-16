#!/bin/bash
# deploy.sh — Program FPGA and run app on board
# Usage: bash scripts/deploy.sh 05_axi_gpio

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "$1" ]; then
    echo "Usage: bash scripts/deploy.sh <project>"
    echo "Example: bash scripts/deploy.sh 05_axi_gpio"
    echo ""
    echo "Available projects:"
    ls -d "$SCRIPT_DIR"/[0-9]*/ 2>/dev/null | xargs -I{} basename {}
    exit 1
fi

PROJ="$1"
TCL_SCRIPT="$SCRIPT_DIR/$PROJ/run.tcl"

if [ ! -f "$TCL_SCRIPT" ]; then
    echo "ERROR: $TCL_SCRIPT not found"
    exit 1
fi

echo ">>> Deploying: $PROJ"
echo ">>> Make sure serial console is open: bash scripts/console.sh"
echo ""

"$XSCT" "$TCL_SCRIPT" 2>&1
