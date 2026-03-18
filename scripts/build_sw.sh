#!/bin/bash
# build_sw.sh — Build software for a project
# Usage: ./scripts/build_sw.sh [--clean] <project>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

CLEAN=0
if [ "$1" = "--clean" ]; then
    CLEAN=1
    shift
fi

if [ -z "$1" ]; then
    echo "Usage: ./scripts/build_sw.sh [--clean] <project>"
    echo "Example: ./scripts/build_sw.sh 05_axi_gpio"
    echo ""
    echo "Available projects:"
    ls -d "$LPU_ROOT"/src/[0-9]*/ 2>/dev/null | xargs -I{} basename {}
    exit 1
fi

PROJ="$1"

if [ ! -d "$LPU_ROOT/src/$PROJ/sw" ]; then
    echo ">>> $PROJ is PL-only — no software to build"
    exit 0
fi

PY_SCRIPT="$LPU_ROOT/src/$PROJ/sw/build.py"
TCL_SCRIPT="$LPU_ROOT/src/$PROJ/sw/build.tcl"

BASE_DIR="$LPU_ROOT/output/$PROJ"
SW_OUT_DIR="$BASE_DIR/sw"

if [ "$CLEAN" = "1" ] && [ -d "$SW_OUT_DIR" ]; then
    echo ">>> Cleaning: $SW_OUT_DIR"
    rm -rf "$SW_OUT_DIR"
fi

mkdir -p "$SW_OUT_DIR"
LOG_FILE="$SW_OUT_DIR/build_sw.log"

export BUILD_OUT_DIR="$BASE_DIR"

if [ -f "$PY_SCRIPT" ]; then
    echo ">>> Building SW: $PROJ (Vitis Python API)"
    echo ">>> Output: $SW_OUT_DIR"
    echo ">>> Log: $LOG_FILE"
    "$SCRIPT_DIR/run_vitis.sh" "$PY_SCRIPT" 2>&1 | tee "$LOG_FILE"
elif [ -f "$TCL_SCRIPT" ]; then
    echo ">>> Building SW: $PROJ (XSCT TCL)"
    echo ">>> Output: $SW_OUT_DIR"
    echo ">>> Log: $LOG_FILE"
    "$XSCT" "$TCL_SCRIPT" 2>&1 | tee "$LOG_FILE"
else
    echo "ERROR: No build_sw.py or build_sw.tcl found in $LPU_ROOT/src/$PROJ/sw/"
    exit 1
fi
