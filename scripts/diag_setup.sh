#!/bin/bash
# diag_setup.sh — Quick environment check for Original Zybo development
# Run: ./scripts/diag_setup.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS="${GREEN}PASS${NC}"
FAIL="${RED}FAIL${NC}"
WARN="${YELLOW}WARN${NC}"

echo "========================================"
echo " Zybo Z7-10 Environment Diagnostics"
echo "========================================"
echo ""

# 1. OS
echo -n "[OS]        "
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "$PASS  $PRETTY_NAME (kernel $(uname -r))"
else
    echo -e "$WARN  Could not detect OS"
fi

# 2. Disk space
echo -n "[DISK]      "
AVAIL=$(df -h / --output=avail | tail -1 | tr -d ' ')
echo -e "$PASS  $AVAIL available on /"

# 3. RAM
echo -n "[RAM]       "
TOTAL_RAM=$(free -h | awk '/Mem:/ {print $2}')
echo -e "$PASS  $TOTAL_RAM total"

# 4. Vivado
echo -n "[VIVADO]    "
if command -v vivado &>/dev/null; then
    VER=$(vivado -version 2>/dev/null | head -1)
    echo -e "$PASS  $VER"
else
    # Check common install paths
    FOUND=""
    for p in /tools/Xilinx/Vivado/*/settings64.sh /opt/Xilinx/Vivado/*/settings64.sh /home/*/Xilinx/Vivado/*/settings64.sh; do
        if [ -f "$p" ] 2>/dev/null; then
            FOUND="$p"
            break
        fi
    done
    if [ -n "$FOUND" ]; then
        echo -e "$WARN  Not in PATH, but found: $FOUND"
        echo "              Add to ~/.bashrc:  source $FOUND"
    else
        echo -e "$FAIL  Not installed"
    fi
fi

# 5. Board files
echo -n "[BOARDFILES]"
if command -v vivado &>/dev/null; then
    VIVADO_DIR=$(dirname $(dirname $(which vivado)))
    if ls "$VIVADO_DIR/data/boards/board_files/" 2>/dev/null | grep -q zybo; then
        echo -e " $PASS  Zybo board files found"
    else
        echo -e " $FAIL  Zybo board files NOT found in $VIVADO_DIR/data/boards/board_files/"
    fi
else
    echo -e " ${YELLOW}SKIP${NC}  Vivado not installed yet"
fi

# 6. tmux
echo -n "[TMUX]      "
if command -v tmux &>/dev/null; then
    echo -e "$PASS  $(tmux -V)"
else
    echo -e "$FAIL  Not installed — run: sudo apt install tmux"
fi

# 7. picocom
echo -n "[PICOCOM]   "
if command -v picocom &>/dev/null; then
    VER=$(picocom --help 2>&1 | head -1)
    echo -e "$PASS  $VER"
else
    echo -e "$FAIL  Not installed — run: sudo apt install picocom"
fi

# 8. xpra
echo -n "[XPRA]      "
if command -v xpra &>/dev/null; then
    VER=$(xpra --version 2>&1 | head -1)
    echo -e "$PASS  $VER"
else
    echo -e "$FAIL  Not installed — run: sudo apt install xpra"
fi

# 9. dialout group
echo -n "[DIALOUT]   "
if groups 2>/dev/null | grep -qw dialout; then
    echo -e "$PASS  User is in dialout group"
else
    echo -e "$FAIL  Not in dialout group — run: sudo usermod -aG dialout \$USER  (then re-login)"
fi

# 10. Board USB connection
echo -n "[BOARD USB] "
if lsusb 2>/dev/null | grep -qi "digilent\|0403:6010"; then
    echo -e "$PASS  Zybo detected (FTDI USB)"
else
    echo -e "$FAIL  Zybo not detected — check USB cable and power switch"
fi

# 11. Serial ports
echo -n "[SERIAL]    "
PORTS=$(ls /dev/ttyUSB* 2>/dev/null)
if [ -n "$PORTS" ]; then
    echo -e "$PASS  $(echo $PORTS | tr '\n' ' ')"
    # Check permissions
    for port in $PORTS; do
        if [ -r "$port" ] && [ -w "$port" ]; then
            echo -e "              $port — accessible"
        else
            echo -e "              $port — ${RED}no permission${NC} (re-login after adding dialout group)"
        fi
    done
else
    echo -e "$FAIL  No /dev/ttyUSB* devices found"
fi

# 12. Project structure
echo -n "[PROJECT]   "
PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MISSING=""
for d in src constrs scripts sw ip sim output docs; do
    if [ ! -d "$PROJ_DIR/$d" ]; then
        MISSING="$MISSING $d"
    fi
done
if [ -z "$MISSING" ]; then
    echo -e "$PASS  All directories present"
else
    echo -e "$FAIL  Missing directories:$MISSING"
fi

echo ""
echo "========================================"
echo " Summary"
echo "========================================"

# Count results
echo ""
echo "If any checks show FAIL, fix them before proceeding."
echo "Run this script again after making changes to verify."
