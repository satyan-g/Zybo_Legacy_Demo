#!/bin/bash
# build_hw.sh — Build hardware for a project
# Usage: bash scripts/build_hw.sh 05_axi_gpio

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "$1" ]; then
    echo "Usage: bash scripts/build_hw.sh <project>"
    echo "Example: bash scripts/build_hw.sh 05_axi_gpio"
    echo ""
    echo "Available projects:"
    ls -d "$SCRIPT_DIR"/[0-9]*/ 2>/dev/null | xargs -I{} basename {}
    exit 1
fi

PROJ="$1"
TCL_SCRIPT="$SCRIPT_DIR/$PROJ/build_hw.tcl"

if [ ! -f "$TCL_SCRIPT" ]; then
    echo "ERROR: $TCL_SCRIPT not found"
    exit 1
fi

LOG_DIR="$LPU_ROOT/output/$PROJ"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build_hw.log"

echo ">>> Building HW: $PROJ"
echo ">>> Script: $TCL_SCRIPT"
echo ">>> Log: $LOG_FILE"

vivado -mode batch -nojournal -nolog -source "$TCL_SCRIPT" 2>&1 | tee "$LOG_FILE"
