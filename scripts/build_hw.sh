#!/bin/bash
# build_hw.sh — Build hardware for a project
# Usage: ./scripts/build_hw.sh [--clean] <project>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

CLEAN=0
if [ "$1" = "--clean" ]; then
    CLEAN=1
    shift
fi

if [ -z "$1" ]; then
    echo "Usage: ./scripts/build_hw.sh [--clean] <project>"
    echo "Example: ./scripts/build_hw.sh 05_axi_gpio"
    echo ""
    echo "Available projects:"
    ls -d "$LPU_ROOT"/src/[0-9]*/ 2>/dev/null | xargs -I{} basename {}
    exit 1
fi

PROJ="$1"
TCL_SCRIPT="$LPU_ROOT/src/$PROJ/hw/build.tcl"

if [ ! -f "$TCL_SCRIPT" ]; then
    echo "ERROR: $TCL_SCRIPT not found"
    exit 1
fi

OUT_DIR="$LPU_ROOT/output/$PROJ/hw"

if [ "$CLEAN" = "1" ] && [ -d "$OUT_DIR" ]; then
    echo ">>> Cleaning: $OUT_DIR"
    rm -rf "$OUT_DIR"
fi

mkdir -p "$OUT_DIR"
LOG_FILE="$OUT_DIR/build_hw.log"

echo ">>> Building HW: $PROJ"
echo ">>> Output: $OUT_DIR"
echo ">>> Log: $LOG_FILE"

vivado -mode batch -nojournal -nolog -source "$TCL_SCRIPT" -tclargs "$OUT_DIR" 2>&1 | tee "$LOG_FILE"
