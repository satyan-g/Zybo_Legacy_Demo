#!/bin/bash
# run_xsct.sh — Run an XSCT TCL script with environment set up
# Usage: bash scripts/run_xsct.sh scripts/02_hello/run.tcl

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "$1" ]; then
    echo "Usage: bash scripts/run_xsct.sh <tcl_script>"
    exit 1
fi

TCL_SCRIPT="$1"
shift

echo ">>> Running: xsct $TCL_SCRIPT"
"$XSCT" "$TCL_SCRIPT" "$@"
