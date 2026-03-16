#!/bin/bash
# env.sh — Source Xilinx tools for this project
# Usage: source scripts/env.sh

export XILINX_BASE="$HOME/Xilinx/Vivado/2024.2"

# Vivado
source "$XILINX_BASE/Vivado/2024.2/settings64.sh"

# Vitis
source "$XILINX_BASE/Vitis/2024.2/settings64.sh"

# Convenience aliases
export XSCT="$XILINX_BASE/Vivado/2024.2/xsct-trim/bin/xsct"
export VITIS_CMD="vitis"

# Project root
export LPU_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
