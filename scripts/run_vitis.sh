#!/bin/bash
# run_vitis.sh — Run a Vitis Python script with environment set up
# Usage: bash scripts/run_vitis.sh scripts/02_hello/build_sw.py

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "$1" ]; then
    echo "Usage: bash scripts/run_vitis.sh <python_script>"
    exit 1
fi

PY_SCRIPT="$1"
shift

echo ">>> Running: vitis -s $PY_SCRIPT"
vitis -s "$PY_SCRIPT" "$@"
