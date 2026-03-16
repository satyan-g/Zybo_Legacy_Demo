#!/bin/bash
# vivado_check.sh — Verify Vivado install and Zynq-7010 device support
# Run: bash scripts/vivado_check.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VIVADO_SETTINGS="$HOME/Xilinx/Vivado/2024.2/Vivado/2024.2/settings64.sh"
INSTALLER="(download from AMD/Xilinx website)"
TARGET_PART="xc7z010clg400-1"

echo "========================================"
echo " Vivado Install & Device Check"
echo "========================================"
echo ""

# 1. Check Vivado is installed
echo -n "[VIVADO]     "
if [ -f "$VIVADO_SETTINGS" ]; then
    source "$VIVADO_SETTINGS"
    VER=$(vivado -version 2>/dev/null | head -1)
    echo -e "${GREEN}PASS${NC}  $VER"
else
    echo -e "${RED}FAIL${NC}  settings64.sh not found at $VIVADO_SETTINGS"
    echo ""
    echo "  Fix: Run the installer:"
    echo "    $INSTALLER"
    exit 1
fi

# 2. Check Zynq-7010 device support
echo -n "[ZYNQ PARTS] "
PARTS=$(vivado -mode batch -nojournal -nolog -tclargs <<'TCLEOF' 2>/dev/null
foreach p [get_parts *xc7z010*] { puts "FOUND:$p" }
exit
TCLEOF
)
if echo "$PARTS" | grep -q "FOUND:"; then
    echo -e "${GREEN}PASS${NC}  Zynq-7010 parts available:"
    echo "$PARTS" | grep "FOUND:" | sed 's/FOUND:/              /'
else
    echo -e "${RED}FAIL${NC}  No Zynq-7010 parts found"
    echo ""
    echo "  Device files are missing. Re-run the installer to add Zynq-7000 support:"
    echo ""
    echo "    $INSTALLER"
    echo ""
    echo "  During install:"
    echo "    1. It should detect the existing Vivado install"
    echo "    2. Select 'Add Design Tools or Devices' (or modify install)"
    echo "    3. Under device families, CHECK 'Zynq-7000'"
    echo "    4. Complete the install"
    echo ""
    echo "  Then re-run this script to verify."
    exit 1
fi

# 3. Check specific target part
echo -n "[TARGET]     "
if echo "$PARTS" | grep -q "$TARGET_PART"; then
    echo -e "${GREEN}PASS${NC}  $TARGET_PART available"
else
    echo -e "${YELLOW}WARN${NC}  $TARGET_PART not found, but other Zynq-7010 variants exist"
fi

# 4. Check board files
echo -n "[BOARD FILES]"
VIVADO_DIR=$(dirname $(dirname $(which vivado)))
if [ -d "$VIVADO_DIR/data/boards/board_files/zybo-z7-10" ]; then
    echo -e " ${GREEN}PASS${NC}  Zybo Z7-10 board files installed"
else
    echo -e " ${RED}FAIL${NC}  Zybo Z7-10 board files not found"
    echo "  Fix: Run these commands:"
    echo "    git clone https://github.com/Digilent/vivado-boards.git /tmp/vivado-boards"
    echo "    cp -r /tmp/vivado-boards/new/board_files/* $VIVADO_DIR/data/boards/board_files/"
    echo "    rm -rf /tmp/vivado-boards"
fi

# 5. Check cable drivers
echo -n "[DRIVERS]    "
if [ -f /etc/udev/rules.d/52-xilinx-ftdi-usb.rules ]; then
    echo -e "${GREEN}PASS${NC}  Cable drivers installed"
else
    echo -e "${RED}FAIL${NC}  Cable drivers not installed"
    echo "  Fix: sudo $VIVADO_DIR/data/xicom/cable_drivers/lin64/install_script/install_drivers/install_drivers"
fi

# 6. Quick synth test
echo -n "[SYNTH TEST] "
TMPDIR=$(mktemp -d)
cat > "$TMPDIR/test.v" <<'VEOF'
module test (input wire clk, output wire led);
    assign led = 1'b1;
endmodule
VEOF

RESULT=$(vivado -mode batch -nojournal -nolog -source /dev/stdin <<TCLEOF 2>&1
read_verilog $TMPDIR/test.v
synth_design -top test -part $TARGET_PART
exit
TCLEOF
)
rm -rf "$TMPDIR"

if echo "$RESULT" | grep -q "synth_design completed"; then
    echo -e "${GREEN}PASS${NC}  Synthesis works for $TARGET_PART"
else
    echo -e "${RED}FAIL${NC}  Synthesis failed"
    echo "$RESULT" | grep -i "error\|warning" | head -5 | sed 's/^/              /'
fi

echo ""
echo "========================================"
echo " Done"
echo "========================================"
