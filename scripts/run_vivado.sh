#!/bin/bash
# run_vivado.sh — Run a Vivado TCL script with environment set up
# Usage: bash scripts/run_vivado.sh scripts/01_blink/build.tcl

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "$1" ]; then
    echo "Usage: bash scripts/run_vivado.sh <tcl_script>"
    exit 1
fi

TCL_SCRIPT="$1"
shift

# Derive log path from script name
LOG_DIR="$LPU_ROOT/output/$(basename "$(dirname "$TCL_SCRIPT")")"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(basename "$TCL_SCRIPT" .tcl).log"

echo ">>> Running: vivado -mode batch -source $TCL_SCRIPT"
echo ">>> Log: $LOG_FILE"

vivado -mode batch -nojournal -nolog -source "$TCL_SCRIPT" "$@" 2>&1 | tee "$LOG_FILE"
