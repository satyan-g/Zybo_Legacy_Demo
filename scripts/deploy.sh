#!/bin/bash
# deploy.sh — Program FPGA and run app on board
# Usage: ./scripts/deploy.sh <project>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "$1" ]; then
    echo "Usage: ./scripts/deploy.sh <project>"
    echo "Example: ./scripts/deploy.sh 05_axi_gpio"
    echo ""
    echo "Available projects:"
    ls -d "$LPU_ROOT"/src/[0-9]*/ 2>/dev/null | xargs -I{} basename {}
    exit 1
fi

PROJ="$1"
TCL_SCRIPT="$LPU_ROOT/src/$PROJ/run.tcl"

if [ ! -f "$TCL_SCRIPT" ]; then
    echo "ERROR: $TCL_SCRIPT not found"
    exit 1
fi

OUT_DIR="$LPU_ROOT/output/$PROJ"

echo ">>> Deploying: $PROJ"
echo ">>> Make sure serial console is open: bash scripts/console.sh"
echo ""

"$XSCT" "$TCL_SCRIPT" "$OUT_DIR" 2>&1
