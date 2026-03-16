#!/bin/bash
# build_sw.sh — Build software for a project
# Usage: bash scripts/build_sw.sh 05_axi_gpio
#
# Detects whether to use Vitis Python API (.py) or XSCT (.tcl):
#   - If build_sw.py exists, runs: vitis -s <script.py>
#   - If build_sw.tcl exists, runs: xsct <script.tcl>
#   - Prefers .py over .tcl if both exist

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "$1" ]; then
    echo "Usage: bash scripts/build_sw.sh <project>"
    echo "Example: bash scripts/build_sw.sh 05_axi_gpio"
    echo ""
    echo "Available projects:"
    ls -d "$SCRIPT_DIR"/[0-9]*/ 2>/dev/null | xargs -I{} basename {}
    exit 1
fi

PROJ="$1"
PY_SCRIPT="$SCRIPT_DIR/$PROJ/build_sw.py"
TCL_SCRIPT="$SCRIPT_DIR/$PROJ/build_sw.tcl"

LOG_DIR="$LPU_ROOT/output/$PROJ"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/build_sw.log"

if [ -f "$PY_SCRIPT" ]; then
    # Vitis Python API (preferred)
    echo ">>> Building SW: $PROJ (Vitis Python API)"
    echo ">>> Script: $PY_SCRIPT"
    echo ">>> Log: $LOG_FILE"
    "$SCRIPT_DIR/run_vitis.sh" "$PY_SCRIPT" 2>&1 | tee "$LOG_FILE"
elif [ -f "$TCL_SCRIPT" ]; then
    # Legacy XSCT TCL
    echo ">>> Building SW: $PROJ (XSCT TCL)"
    echo ">>> Script: $TCL_SCRIPT"
    echo ">>> Log: $LOG_FILE"
    "$XSCT" "$TCL_SCRIPT" 2>&1 | tee "$LOG_FILE"
else
    echo "ERROR: No build_sw.py or build_sw.tcl found in $SCRIPT_DIR/$PROJ/"
    exit 1
fi
